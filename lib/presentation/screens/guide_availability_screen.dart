import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/guide_availability.dart';
import '../../data/models/guide_listing.dart';
import '../../data/repositories/marketplace_repository.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

class GuideAvailabilityScreen extends ConsumerStatefulWidget {
  final GuideListing? listing;
  const GuideAvailabilityScreen({super.key, this.listing});

  @override
  ConsumerState<GuideAvailabilityScreen> createState() => _GuideAvailabilityScreenState();
}

class _GuideAvailabilityScreenState extends ConsumerState<GuideAvailabilityScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late String _listingId;

  // State
  bool _instantBookEnabled = false;
  String _advanceNoticeHours = '24';
  List<DateTime> _blackoutDates = [];
  final Map<int, RecurringSlot?> _weeklySlots = {}; // dayOfWeek (1-7) -> slot or null if off

  final List<String> _noticeOptions = ['2', '6', '12', '24', '48', '72'];

  List<String> _daysOfWeek(AppLocalizations l10n) => [
    l10n.dayMonday, l10n.dayTuesday, l10n.dayWednesday, l10n.dayThursday, l10n.dayFriday, l10n.daySaturday, l10n.daySunday,
  ];

  @override
  void initState() {
    super.initState();
    _initSchedule();
  }

  Future<void> _initSchedule() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    _listingId = uid;

    GuideAvailability? avail;
    if (widget.listing != null && widget.listing!.availability != null) {
      avail = widget.listing!.availability;
    } else {
      try {
        final repo = ref.read(marketplaceRepositoryProvider);
        final listing = await repo.getListing(uid);
        avail = listing?.availability;
      } catch (e, st) {
        SecureLogger.error("Error fetching availability", e, st, "GuideAvailability");
      }
    }

    // Initialize defaults (Mon-Fri 08:00 - 17:00)
    for (int i = 1; i <= 7; i++) {
      if (i <= 5) {
        _weeklySlots[i] = RecurringSlot(dayOfWeek: i, startTime: '08:00', endTime: '17:00');
      } else {
        _weeklySlots[i] = null; // Weekend off by default
      }
    }

    if (avail != null && mounted) {
      _blackoutDates = List.from(avail.blackoutDates);
      _instantBookEnabled = avail.customNotes['instantBookEnabled'] == 'true';
      _advanceNoticeHours = avail.customNotes['advanceNoticeHours'] ?? '24';

      if (avail.recurringSlots.isNotEmpty) {
        for (int i = 1; i <= 7; i++) {
          _weeklySlots[i] = null;
        }
        for (final slot in avail.recurringSlots) {
          _weeklySlots[slot.dayOfWeek] = slot;
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBlackoutDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.colors.amber,
            onPrimary: AppTheme.colors.black,
            surface: AppTheme.colors.primary,
            onSurface: AppTheme.colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (!mounted) return;
    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      if (!_blackoutDates.any((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day)) {
        setState(() {
          _blackoutDates.add(dateOnly);
          _blackoutDates.sort((a, b) => a.compareTo(b));
        });
      }
    }
  }

  Future<void> _pickTime(int dayIndex, bool isStart) async {
    HapticFeedback.lightImpact();
    final currentSlot = _weeklySlots[dayIndex];
    if (currentSlot == null) return;

    final parts = (isStart ? currentSlot.startTime : currentSlot.endTime).split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppTheme.colors.amber, onPrimary: AppTheme.colors.black, surface: AppTheme.colors.primary, onSurface: AppTheme.colors.white),
        ),
        child: child!,
      ),
    );

    if (!mounted) return;
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _weeklySlots[dayIndex] = RecurringSlot(
          dayOfWeek: dayIndex,
          startTime: isStart ? formatted : currentSlot.startTime,
          endTime: !isStart ? formatted : currentSlot.endTime,
        );
      });
    }
  }

  Future<void> _saveAvailability() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final activeSlots = _weeklySlots.values.whereType<RecurringSlot>().toList();
      final customNotes = {
        'instantBookEnabled': _instantBookEnabled ? 'true' : 'false',
        'advanceNoticeHours': _advanceNoticeHours,
      };

      final newAvail = GuideAvailability(
        listingId: _listingId,
        blackoutDates: _blackoutDates,
        recurringSlots: activeSlots,
        isManualUnavailable: false,
        customNotes: customNotes,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateAvailability(_listingId, newAvail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.availabilityScheduleUpdatedMessage, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.colors.greenAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingAvailabilityMessage(e.toString()), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.availabilityScheduleTitle,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Theme.of(context).colorScheme.primary, AppPalette.rustDim],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.whenYoureFreeToGuideTitle,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.touristsOnlySeeOpenSlotsMessage,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.colors.white.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 28),

                  _buildSectionTitle(context, l10n.instantBookNoticeTitle),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(l10n.instantBookLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(l10n.instantBookSubtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                          value: _instantBookEnabled,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _instantBookEnabled = val),
                        ),
                        Divider(color: AppTheme.borderColor(context), height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.advanceNoticeLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(l10n.advanceNoticeSubtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted(context),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: DropdownButton<String>(
                                value: _advanceNoticeHours,
                                dropdownColor: Theme.of(context).colorScheme.surface,
                                underline: const SizedBox(),
                                icon: Icon(Icons.expand_more_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                                items: _noticeOptions.map((e) => DropdownMenuItem(value: e, child: Text(l10n.hoursShortLabel(e), style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _advanceNoticeHours = val!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle(context, l10n.weeklyScheduleTitle),
                  const SizedBox(height: 4),
                  Text(l10n.weeklyScheduleSubtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                  const SizedBox(height: 14),
                  ...List.generate(7, (index) {
                    final dayIndex = index + 1;
                    final dayName = _daysOfWeek(l10n)[index];
                    final slot = _weeklySlots[dayIndex];
                    final isWorking = slot != null;
                    final primary = Theme.of(context).colorScheme.primary;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isWorking ? Theme.of(context).colorScheme.surface : AppTheme.surfaceMuted(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isWorking ? primary.withValues(alpha: 0.3) : AppTheme.borderColor(context)),
                        boxShadow: isWorking
                            ? [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dayName,
                              style: GoogleFonts.outfit(
                                color: isWorking ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: isWorking,
                            activeThumbColor: primary,
                            onChanged: (val) {
                              setState(() {
                                if (val) {
                                  _weeklySlots[dayIndex] = RecurringSlot(dayOfWeek: dayIndex, startTime: '08:00', endTime: '17:00');
                                } else {
                                  _weeklySlots[dayIndex] = null;
                                }
                              });
                            },
                          ),
                          if (isWorking) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _pickTime(dayIndex, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(100)),
                                child: Text(slot.startTime, style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('–', style: TextStyle(color: AppTheme.textSecondary(context))),
                            ),
                            GestureDetector(
                              onTap: () => _pickTime(dayIndex, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(100)),
                                child: Text(slot.endTime, style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            Text(l10n.dayOffLabel, style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, l10n.blackoutDatesTitle + (_blackoutDates.isNotEmpty ? l10n.blackoutDatesCountSuffix(_blackoutDates.length) : '')),
                      TextButton.icon(
                        onPressed: _pickBlackoutDate,
                        icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                        label: Text(l10n.addDateButtonLabel, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_blackoutDates.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        l10n.noBlackoutDatesMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _blackoutDates.map((date) {
                        return Chip(
                          backgroundColor: AppTheme.colors.redAccent.withValues(alpha: 0.1),
                          side: BorderSide(color: AppTheme.colors.redAccent.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          label: Text(dateFormat.format(date), style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 12)),
                          deleteIcon: Icon(Icons.close_rounded, size: 16, color: AppTheme.colors.redAccent),
                          onDeleted: () {
                            setState(() {
                              _blackoutDates.remove(date);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: AppTheme.colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.saveAvailabilityButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppTheme.textPrimary(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}
