import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/repositories/incident_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/incident_report.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/services/emergency_translator_service.dart';
import 'emergency_translator_screen.dart';
import 'premium_hub_screen.dart';
import '../../l10n/app_localizations.dart';

class EmergencyKitScreen extends ConsumerStatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  ConsumerState<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends ConsumerState<EmergencyKitScreen> with SingleTickerProviderStateMixin {
  bool _isSendingSOS = false;
  bool _isHolding = false;
  late AnimationController _holdController;
  static const _holdDuration = Duration(seconds: 2, milliseconds: 500);

  // A hardcoded hospital list can only ever cover a handful of cities and
  // will misdirect anyone elsewhere on the island. Nearby medical facilities
  // are instead resolved live via Google Maps, centered on the user's actual
  // GPS position, covering every government and private hospital Maps knows
  // about — see _openNearbyHospitals().
  LocationPermission? _locationPermission;
  bool _checkingLocation = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _holdController = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.heavyImpact();
          setState(() => _isHolding = false);
          _handleSOS();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_isSendingSOS) return;
    HapticFeedback.mediumImpact();
    setState(() => _isHolding = true);
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    _holdController.stop();
    _holdController.reset();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermission = permission;
        _checkingLocation = false;
      });
    }
  }

  /// Opens Google Maps centered on the user's live GPS position searching
  /// for "hospital" — this surfaces every government and private hospital
  /// Maps knows about, wherever in Sri Lanka the user actually is, rather
  /// than a small hardcoded list that only covers a few cities.
  Future<void> _openNearbyHospitals() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      setState(() => _locationPermission = permission);

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        await launchUrl(
          Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital+near+me'),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      // Embedding the live coordinates directly in the query text is the
      // reliable way to location-bias a Maps web search (the `center`
      // parameter only affects the map viewport, not search ranking).
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=hospital+near+${pos.latitude},${pos.longitude}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital+near+me'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _handleSOS() async {
    setState(() => _isSendingSOS = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw l10n.locationPermissionsPermanentlyDeniedMessage;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final profile = UserPreferenceService.getProfile();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      // 1. Actually get help: SMS/call fires first and unconditionally, so a
      // failure in the (secondary) incident logging below can never prevent
      // the real-world emergency contact from going out.
      final String mapLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      final String sosMessage = "EMERGENCY: I need help. My current location is: $mapLink (Sent via AdvanceTravel.me)";

      if (profile.sosContacts.isEmpty) {
        await launchUrl(Uri.parse("tel:119"));
      } else {
        final String separator = Platform.isIOS ? ';' : ',';
        final String contacts = profile.sosContacts.join(separator);
        final Uri smsUri = Uri.parse("sms:$contacts?body=${Uri.encodeComponent(sosMessage)}");
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }

      // 2. Log an automated incident report. Best-effort: if this fails, the
      // SOS itself has already been sent above, so we only log and continue.
      try {
        final incidentRepo = ref.read(incidentRepositoryProvider);
        final incident = IncidentReport(
          incidentId: '', // Generated
          incidentNumber: 'SOS-${DateTime.now().millisecondsSinceEpoch}',
          sessionId: 'GLOBAL',
          guideId: 'GLOBAL',
          touristId: userId,
          reportedBy: userId,
          reportedByRole: profile.role,
          type: 'sos_alert',
          severity: 'critical',
          title: l10n.sosCriticalAlertTitle,
          description: l10n.sosDistressSignalDescription,
          status: 'investigating',
          lat: position.latitude,
          lng: position.longitude,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          timelineEvents: [
            {
              'type': 'sos_triggered',
              'timestamp': DateTime.now().toIso8601String(),
              'description': 'SOS distress signal initiated by user.',
              'location': {'lat': position.latitude, 'lng': position.longitude},
            }
          ],
        );
        await incidentRepo.createIncident(incident);
      } catch (_) {
        // Incident logging is secondary to actually notifying help; swallow.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sosAlertsPreparedLoggedMessage)),
      );

      await _offerEmergencyTranslator();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMessage(e.toString())), backgroundColor: AppTheme.colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSendingSOS = false);
    }
  }

  /// Premium benefit: right after an SOS is logged, offer to open the
  /// Emergency Translator so the tourist can immediately show/play a
  /// Sinhala explanation of their situation to whoever is helping them.
  /// Gated via SecureEntitlements (server-verified), not the raw local
  /// profile flag, matching UsageLimiterService's premium check pattern.
  Future<void> _offerEmergencyTranslator() async {
    if (!mounted) return;
    final isPremium = await SecureEntitlements().verifyPremium();
    if (!mounted) return;

    if (isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyTranslatorScreen(initialType: EmergencySituationType.other)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        icon: Icon(Icons.translate_rounded, color: AppPalette.rust, size: 32),
        title: Text(AppLocalizations.of(context)!.emergencyTranslatorTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        content: Text(
          AppLocalizations.of(context)!.emergencyTranslatorPremiumMessage,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.notNowButton, style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumHubScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.rust, foregroundColor: AppTheme.colors.white),
            child: Text(AppLocalizations.of(context)!.viewPlansButton),
          ),
        ],
      ),
    );
  }

  Future<void> _launchCaller(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // BUG-063: Clamps the text scaling factor to prevent layout overflows on large font settings
    final clampedTextScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.25);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.emergencyTitle,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSOSSection().animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
              SizedBox(height: 32),

              Text(
                AppLocalizations.of(context)!.criticalContactsTitle,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              SizedBox(height: 16),
              _buildContactGrid(),

              SizedBox(height: 32),
              _buildSOSContactManager(),

              SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.medicalFacilitiesNearbyTitle,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              SizedBox(height: 16),
              _buildHospitalsList(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.earth, AppPalette.rustDim],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_moon_rounded, color: AppTheme.colors.white.withValues(alpha: 0.85), size: 16),
              const SizedBox(width: 8),
              Text(
                l10n.emergencyProtocolLabel,
                style: GoogleFonts.inter(
                  color: AppTheme.colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onLongPressStart: (_) => _startHold(),
            onLongPressEnd: (_) => _cancelHold(),
            onLongPressCancel: _cancelHold,
            child: AnimatedBuilder(
              animation: _holdController,
              builder: (context, _) {
                return SizedBox(
                  width: 148,
                  height: 148,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_isHolding)
                        Container(
                          width: 148, height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.colors.white.withValues(alpha: 0.08),
                          ),
                        ).animate(onPlay: (c) => c.repeat()).scale(
                          begin: const Offset(0.72, 0.72), end: const Offset(1, 1),
                          duration: 1800.ms, curve: Curves.easeOut,
                        ).fadeOut(begin: 0.5),
                      SizedBox(
                        width: 148,
                        height: 148,
                        child: CircularProgressIndicator(
                          value: _isHolding ? _holdController.value : 0,
                          strokeWidth: 4,
                          backgroundColor: AppTheme.colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(AppPalette.heroOchre),
                        ),
                      ),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: _isHolding ? AppTheme.errorRed : AppTheme.errorRed.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.errorRed.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 2),
                          ],
                        ),
                        child: Center(
                          child: _isSendingSOS
                            ? SizedBox(
                                width: 26, height: 26,
                                child: CircularProgressIndicator(color: AppTheme.colors.white, strokeWidth: 3),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emergency_share_rounded, color: AppTheme.colors.white, size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.sosLabel,
                                    style: TextStyle(color: AppTheme.colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSendingSOS
                ? l10n.sendingAlertMessage
                : _isHolding
                    ? l10n.keepHoldingToConfirmMessage
                    : l10n.pressHoldTwoSecondsMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.preventsAccidentalTriggersMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactGrid() {
    final l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> contacts = [
      {"name": l10n.contactNamePolice, "phone": "119", "icon": Icons.local_police_rounded, "color": AppPalette.earth},
      {"name": l10n.contactNameAmbulance, "phone": "1990", "icon": Icons.medical_services_rounded, "color": AppPalette.rust},
      {"name": l10n.contactNameTouristPolice, "phone": "0112421451", "icon": Icons.beach_access_rounded, "color": AppPalette.heroOchre},
      {"name": l10n.contactNameFireDept, "phone": "110", "icon": Icons.fire_truck_rounded, "color": AppTheme.errorRed},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // BUG-123 / BUG-143: Compute grid columns based on available width so
        // small phones get 1 column and tablets can fit 3.
        final int columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final color = contact['color'] as Color;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
              ),
              // BUG-083: Ensure minimum 48px tap target by using ConstrainedBox
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _launchCaller(contact['phone'] as String),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(contact['icon'] as IconData, color: color, size: 20),
                        ),
                        const SizedBox(height: 12),
                        // BUG-103: Flexible text prevents overflow at max font scale
                        Flexible(
                          child: Text(
                            contact['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  contact['phone'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.call_rounded, color: color, size: 13),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
          },
        );
      },
    );
  }


  Widget _buildSOSContactManager() {
    final profile = UserPreferenceService.getProfile();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.privateGuardiansTitle,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)
              ),
              IconButton(
                onPressed: _showAddContactDialog,
                icon: Icon(Icons.add_link_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (profile.sosContacts.isEmpty)
            Text(
              l10n.noGuardiansAssignedMessage,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.sosContacts.map((c) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final p = UserPreferenceService.getProfile();
                        p.sosContacts.remove(c);
                        await UserPreferenceService.saveProfile(p);
                        if (!mounted) return;
                        setState(() {});
                      },
                      child: Icon(Icons.close_rounded, color: AppTheme.colors.redAccent, size: 14),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList() {
    final l10n = AppLocalizations.of(context)!;
    final deniedForever = _locationPermission == LocationPermission.deniedForever;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.rust.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.local_hospital_rounded, color: AppPalette.rust, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nearestHospitalTitle,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _checkingLocation
                          ? l10n.checkingLocationAccessMessage
                          : deniedForever
                              ? l10n.locationAccessDeniedGeneralMessage
                              : l10n.hospitalMapsExplanationMessage,
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.near_me_rounded, size: 17),
              label: Text(l10n.findNearestHospitalButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: _openNearbyHospitals,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.rust,
                foregroundColor: AppTheme.colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  void _showAddContactDialog() {
    String phone = "";
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.colors.transparent,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.addGuardianTitle,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context))
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.guardianPhoneNumberHint,
                    hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Builder(
                  builder: (buttonContext) => ElevatedButton(
                    onPressed: () async {
                      if (phone.isNotEmpty) {
                        final p = UserPreferenceService.getProfile();
                        p.sosContacts.add(phone);
                        await UserPreferenceService.saveProfile(p);
                        if (!mounted || !buttonContext.mounted) return;
                        setState(() {});
                        // BUG-11 FIX: Pop the dialog context specifically.
                        // Previously this was popping `context` which might
                        // refer to the outer emergency screen context, causing
                        // the entire screen to pop instead of just the dialog.
                        Navigator.pop(buttonContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(buttonContext).colorScheme.primary,
                      foregroundColor: AppTheme.colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text(AppLocalizations.of(context)!.addGuardianButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
