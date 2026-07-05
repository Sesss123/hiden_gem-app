import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/booking_request.dart';
import '../../data/models/tour_session.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/tour_session_repository.dart';
import '../../data/datasources/user_preference_service.dart';
import 'tourist_companion_hub.dart';

class BookingInboxScreen extends ConsumerStatefulWidget {
  const BookingInboxScreen({super.key});

  @override
  ConsumerState<BookingInboxScreen> createState() => _BookingInboxScreenState();
}

class _BookingInboxScreenState extends ConsumerState<BookingInboxScreen> {
  String _selectedFilter = 'pending';
  final List<String> _filters = ['pending', 'accepted', 'session_ready', 'completed', 'declined', 'cancelled', 'all'];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text("Please log in to view booking requests.", style: TextStyle(color: Colors.white))),
      );
    }

    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'BOOKING INBOX',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
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
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error loading inbox: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
                      );
                    }

                    final allRequests = snapshot.data ?? [];
                    final filteredRequests = _selectedFilter == 'all'
                        ? allRequests
                        : allRequests.where((req) {
                            if (_selectedFilter == 'cancelled') {
                              return req.status.contains('cancelled');
                            }
                            if (_selectedFilter == 'accepted') {
                              return req.status == 'accepted' || req.status == 'session_ready';
                            }
                            return req.status == _selectedFilter;
                          }).toList();

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
          String label = filter.replaceAll('_', ' ').toUpperCase();
          if (filter == 'session_ready') label = 'READY FOR TOUR';

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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getStatusIcon(request.status), color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOURIST #${request.touristId.length > 6 ? request.touristId.substring(0, 6) : request.touristId}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    request.status.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderColor(context)),
            const SizedBox(height: 12),
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
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[200]!).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TOUR NOTES / REQUIREMENTS:", style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber[800], fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                    child: OutlinedButton(
                      onPressed: () => _handleDecline(request),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("DECLINE", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _handleAccept(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text("ACCEPT BOOKING ✓", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: Text("START / LAUNCH TOUR SESSION", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      case 'pending': return Colors.orangeAccent;
      case 'accepted':
      case 'session_ready': return Colors.green;
      case 'completed': return Colors.blueAccent;
      case 'declined':
      case 'cancelled':
      case 'cancelled_by_tourist':
      case 'cancelled_by_guide': return Colors.redAccent;
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

      final sessionId = 'TS_${DateTime.now().millisecondsSinceEpoch}';
      final session = TourSession(
        sessionId: sessionId,
        guideId: uid,
        touristIds: [request.touristId],
        meetingPointName: 'To be confirmed in chat',
        meetingPointLat: 6.9271,
        meetingPointLng: 79.8612,
        status: 'initial',
        currentPhase: 'assembling',
        sessionCode: (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
        maxTourists: request.guestCount,
        notes: request.notes,
        isReviewEnabled: true,
      );

      await sessionRepo.createSession(session);
      await bookingRepo.respondToRequest(bookingId: request.bookingId, status: 'session_ready', note: 'Booking Accepted! Session ready.');
      await bookingRepo.updateLinkedSessionId(request.bookingId, sessionId);

      final profile = UserPreferenceService.getProfile();
      profile.currentBatchId = sessionId;
      await UserPreferenceService.saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Booking accepted & Tour Session created!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error accepting booking: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleDecline(BookingRequest request) async {
    HapticFeedback.lightImpact();
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking declined."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error declining booking: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
