import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_request.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/marketplace_repository.dart';

/// Tourist-facing booking history — lets a tourist see the status of every
/// booking request they've sent (pending / accepted / declined / etc.)
/// without needing a push notification. BookingRepository.getTouristBookings
/// already existed but had zero callers anywhere in the app before this.
class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  List<BookingRequest> _bookings = [];
  final Map<String, String> _guideNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final bookings = await ref.read(bookingRepositoryProvider).getTouristBookings(uid);
    final marketplaceRepo = ref.read(marketplaceRepositoryProvider);

    final guideIds = bookings.map((b) => b.guideId).whereType<String>().toSet();
    for (final guideId in guideIds) {
      final listing = await marketplaceRepo.getListing(guideId);
      if (listing != null) _guideNames[guideId] = listing.displayName;
    }

    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My bookings', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context))),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _bookings.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) => _buildBookingCard(context, _bookings[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No bookings yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'Requests you send to guides will show up here with their status.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingRequest booking) {
    final guideName = _guideNames[booking.guideId] ?? 'Guide';
    final status = _StatusInfo.forStatus(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(guideName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: status.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
                child: Text(status.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: status.color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textSecondary(context)),
              const SizedBox(width: 6),
              Text(DateFormat('MMM d, yyyy').format(booking.requestedDate), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context))),
              const SizedBox(width: 16),
              Icon(Icons.group_rounded, size: 13, color: AppTheme.textSecondary(context)),
              const SizedBox(width: 6),
              Text('${booking.guestCount} guests', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context))),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              booking.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context), fontStyle: FontStyle.italic),
            ),
          ],
          _buildPaymentRow(context, booking),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  /// Shows the quoted price once a guide has accepted, or a "Paid" badge once
  /// payment has cleared.
  ///
  /// In-app checkout via PayHere is built (see lib/data/services/
  /// payment_service.dart + PayHereController.php) but INTENTIONALLY NOT
  /// WIRED HERE — the owner doesn't have a PayHere merchant account yet, so
  /// payment stays off-platform (tourist and guide settle directly, same as
  /// before PayHere existed). isPaid will simply never be true today; the
  /// price is shown for the tourist's reference only.
  ///
  /// To re-enable in-app payment once a PayHere merchant account exists:
  /// restore the "Pay Now" ElevatedButton (see git history / session notes)
  /// calling PaymentService.fetchQuote() + PaymentService.launchCheckout() —
  /// no other code needs to change, the backend flow is already live.
  Widget _buildPaymentRow(BuildContext context, BookingRequest booking) {
    final hasPrice = (booking.status == 'accepted' || booking.status == 'session_ready') &&
        (booking.quotedPrice ?? 0) > 0;
    final isPaid = booking.payoutStatus == 'paid';

    if (!hasPrice && !isPaid) return const SizedBox.shrink();

    final price = booking.quotedPrice ?? 0;
    final currency = booking.currency ?? 'LKR';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            '$currency ${price.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
          ),
          const Spacer(),
          if (isPaid)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.colors.green),
                const SizedBox(width: 6),
                Text('Paid', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.colors.green)),
              ],
            )
          else
            Text(
              'Pay guide directly',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);

  static _StatusInfo forStatus(String status) {
    switch (status) {
      case 'pending':
        return const _StatusInfo('Awaiting response', AppPalette.warning);
      case 'accepted':
        return const _StatusInfo('Accepted', AppPalette.success);
      case 'session_ready':
        return const _StatusInfo('Ready', AppPalette.success);
      case 'declined':
        return const _StatusInfo('Declined', AppPalette.error);
      case 'expired':
        return const _StatusInfo('Expired', AppPalette.textMuted);
      case 'cancelled_by_tourist':
      case 'cancelled_by_guide':
        return const _StatusInfo('Cancelled', AppPalette.textMuted);
      case 'completed':
        return const _StatusInfo('Completed', AppPalette.earth);
      default:
        return const _StatusInfo('Pending', AppPalette.warning);
    }
  }
}
