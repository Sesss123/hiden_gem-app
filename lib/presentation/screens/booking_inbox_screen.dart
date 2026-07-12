import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/booking_request.dart';
import '../../data/models/tour_session.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/tour_session_repository.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../core/services/calendar_sync_service.dart';
import '../../core/notifications/notification_service.dart';
import 'tourist_companion_hub.dart';

class BookingInboxScreen extends ConsumerStatefulWidget {
  const BookingInboxScreen({super.key});

  @override
  ConsumerState<BookingInboxScreen> createState() => _BookingInboxScreenState();
}

class _BookingInboxScreenState extends ConsumerState<BookingInboxScreen> {
  String _selectedFilter = 'pending';
  final List<String> _filters = ['pending', 'accepted', 'session_ready', 'completed', 'declined', 'cancelled', 'all'];
  List<BookingRequest> _latestBookings = [];
  bool _isSyncingCalendar = false;

  @override
  void initState() {
    super.initState();
    // The guide has now seen the inbox — reset the "N new requests" badge
    // on the Profile tab's Bookings tile.
    NotificationService().clearUnreadBookingCount();
  }

  Future<void> _syncToCalendar() async {
    final upcoming = _latestBookings.where((b) => b.status == 'accepted' || b.status == 'session_ready').toList();
    if (upcoming.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No accepted bookings to sync yet.')),
      );
      return;
    }

    setState(() => _isSyncingCalendar = true);
    try {
      final entries = upcoming.map((b) => CalendarSyncEntry(
        bookingId: b.bookingId,
        title: 'Tour: ${b.touristDisplayName ?? "Traveler"} (${b.guestCount} guests)',
        description: b.notes ?? '',
        start: b.requestedDate,
        end: b.requestedDate.add(const Duration(hours: 4)),
      )).toList();

      final synced = await CalendarSyncService().syncBookings(entries);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $synced booking(s) to your calendar.'), backgroundColor: AppTheme.colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calendar sync failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text("Please log in to view booking requests.", style: TextStyle(color: AppTheme.colors.white))),
      );
    }

    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        title: Text(
          'Bookings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: _isSyncingCalendar
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary(context)))
                : Icon(Icons.calendar_month_outlined, color: AppTheme.textPrimary(context)),
            tooltip: 'Sync to calendar',
            onPressed: _isSyncingCalendar ? null : _syncToCalendar,
          ),
        ],
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<BookingRequest>>(
                  stream: bookingRepo.getInbox(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppTheme.colors.amber));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error loading inbox: ${snapshot.error}", style: TextStyle(color: AppTheme.colors.redAccent)),
                      );
                    }

                    final allRequests = snapshot.data ?? [];
                    // BUG-2 FIX: Don't mutate _latestBookings inside the
                    // StreamBuilder builder — builders are pure functions that
                    // Flutter can call multiple times per frame. Side-effecting
                    // them produces stale data in calendar sync and breaks the
                    // reactive model. Schedule the update for after the frame.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _latestBookings = allRequests);
                      }
                    });
                    final filteredRequests = _selectedFilter == 'all'
                        ? List<BookingRequest>.from(allRequests)
                        : allRequests.where((req) {
                            if (_selectedFilter == 'cancelled') {
                              return req.status.contains('cancelled');
                            }
                            if (_selectedFilter == 'accepted') {
                              return req.status == 'accepted' || req.status == 'session_ready';
                            }
                            return req.status == _selectedFilter;
                          }).toList();

                    // Priority Leads: Pro/Elite guides' flagged bookings surface
                    // first, newest-first within each priority tier (stable sort
                    // preserves the getInbox() createdAt-desc order as tiebreaker).
                    filteredRequests.sort((a, b) {
                      if (a.isPriority != b.isPriority) {
                        return a.isPriority ? -1 : 1;
                      }
                      return 0;
                    });

                    if (filteredRequests.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        return _buildBookingCard(context, filteredRequests[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          String label = _sentenceCase(filter.replaceAll('_', ' '));
          if (filter == 'session_ready') label = 'Ready for tour';

          return OracleUI.glassChip(
            context: context,
            label: label,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedFilter = filter);
            },
          );
        },
      ),
    );
  }

  String _sentenceCase(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1).toLowerCase();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              "No ${_selectedFilter == 'all' ? '' : _selectedFilter.replaceAll('_', ' ')} booking requests.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingRequest request) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final statusColor = _getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: request.isPriority
                ? AppPalette.heroOchre.withValues(alpha: 0.18)
                : AppTheme.colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getStatusIcon(request.status), color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tourist #${request.touristId.length > 6 ? request.touristId.substring(0, 6) : request.touristId}",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          "Requested ${timeFormat.format(request.createdAt)}",
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (request.isPriority) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppPalette.heroOchre.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'PRIORITY',
                          style: GoogleFonts.outfit(color: AppPalette.heroOchre, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _sentenceCase(request.status.replaceAll('_', ' ')),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(Icons.calendar_today_rounded, "Tour Date", dateFormat.format(request.requestedDate)),
                _buildDetailItem(Icons.group_outlined, "Guests", "${request.guestCount} Person(s)"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  Icons.monetization_on_outlined,
                  "Quoted Price",
                  "${request.currency ?? 'USD'} ${request.quotedPrice?.toStringAsFixed(2) ?? 'N/A'}",
                ),
                _buildDetailItem(
                  Icons.account_balance_wallet_outlined,
                  "Your Net Payout",
                  "${request.currency ?? 'USD'} ${request.guideNetAmount?.toStringAsFixed(2) ?? (request.quotedPrice != null ? (request.quotedPrice! * 0.85).toStringAsFixed(2) : 'N/A')}",
                ),
              ],
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? AppTheme.colors.black : AppTheme.colors.grey[200]!).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tour notes / requirements", style: GoogleFonts.inter(fontSize: 10, color: AppTheme.colors.amber[800], fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(request.notes!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary(context))),
                  ],
                ),
              ),
            ],
            if (request.responseNote != null && request.responseNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Your response note: ${request.responseNote}", style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary(context))),
            ],
            if (request.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDecline(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceMuted(context),
                        foregroundColor: AppTheme.colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text("Decline", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _handleAccept(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colors.greenAccent[700],
                        foregroundColor: AppTheme.colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text("Accept", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
            if (request.status == 'session_ready' || request.status == 'accepted') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TouristCompanionHub(
                          sessionId: request.linkedSessionId ?? 'TS_${request.bookingId}',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.play_arrow_rounded, color: AppTheme.colors.white),
                  label: Text("Start / launch tour session", style: GoogleFonts.inter(color: AppTheme.colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.amber[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary(context), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context))),
            Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.colors.orangeAccent;
      case 'accepted':
      case 'session_ready': return AppTheme.colors.green;
      case 'completed': return AppTheme.colors.blueAccent;
      case 'declined':
      case 'cancelled':
      case 'cancelled_by_tourist':
      case 'cancelled_by_guide': return AppTheme.colors.redAccent;
      default: return AppTheme.textSecondary(context);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.access_time_rounded;
      case 'accepted':
      case 'session_ready': return Icons.check_circle_outline_rounded;
      case 'completed': return Icons.verified_outlined;
      case 'declined':
      case 'cancelled':
      case 'cancelled_by_tourist':
      case 'cancelled_by_guide': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  Future<void> _handleAccept(BookingRequest request) async {
    HapticFeedback.mediumImpact();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final sessionRepo = ref.read(tourSessionRepositoryProvider);

      // Security: not a predictable timestamp — an attacker who could guess
      // recent millisecond timestamps could brute-force session IDs. UUID
      // v4 keeps the 'TS_' prefix for readability but is unguessable.
      final sessionId = 'TS_${const Uuid().v4()}';

      // BUG-5 FIX: Fetch the guide's actual GPS location instead of
      // hardcoding Colombo (6.9271, 79.8612). The hardcoded coordinates
      // caused every accepted booking's session to pin its meeting point
      // to Colombo on the Tourist Companion Hub map regardless of where
      // the guide actually is.
      double sessionLat = 6.9271; // Fallback: Colombo
      double sessionLng = 79.8612;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        sessionLat = pos.latitude;
        sessionLng = pos.longitude;
      } catch (_) {
        // GPS unavailable — use Colombo as fallback. The guide can update
        // the meeting point manually from the Tour Dashboard later.
      }

      final session = TourSession(
        sessionId: sessionId,
        guideId: uid,
        touristIds: [request.touristId],
        meetingPointName: 'To be confirmed in chat',
        meetingPointLat: sessionLat,
        meetingPointLng: sessionLng,
        status: 'initial',
        currentPhase: 'assembling',
        sessionCode: (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
        maxTourists: request.guestCount,
        notes: request.notes,
        isReviewEnabled: true,
      );

      await sessionRepo.createSession(session);
      await bookingRepo.respondToRequest(bookingId: request.bookingId, status: 'session_ready', note: 'Booking Accepted! Session ready.', touristId: request.touristId);
      await bookingRepo.updateLinkedSessionId(request.bookingId, sessionId);

      final profile = UserPreferenceService.getProfile();
      profile.currentBatchId = sessionId;
      await UserPreferenceService.saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Booking accepted & Tour Session created!"), backgroundColor: AppTheme.colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error accepting booking: $e"), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleDecline(BookingRequest request) async {
    HapticFeedback.lightImpact();
    final noteController = TextEditingController();
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.colors.redAccent)),
          title: Text("Decline Booking?", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please provide a reason for declining (optional):", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: "e.g. Fully booked on this date / Vehicle maintenance",
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.borderColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary(context)))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.redAccent, foregroundColor: AppTheme.colors.white),
              child: const Text("DECLINE"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        final bookingRepo = ref.read(bookingRepositoryProvider);
        await bookingRepo.respondToRequest(
          bookingId: request.bookingId,
          status: 'declined',
          note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Declined by guide.',
          touristId: request.touristId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking declined."), backgroundColor: AppTheme.colors.redAccent),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error declining booking: $e"), backgroundColor: AppTheme.colors.redAccent),
          );
        }
      }
    } finally {
      noteController.dispose();
    }
  }
}
