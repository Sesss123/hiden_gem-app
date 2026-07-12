import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/booking_request.dart';
import '../../data/repositories/package_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  final String guideId;
  final String? packageId;
  const BookingRequestScreen({super.key, required this.guideId, this.packageId});

  @override
  ConsumerState<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _guestCount = 1;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
        title: Text(
          'Request booking',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSectionLabel(context, 'Date'),
            const SizedBox(height: 10),
            _buildDatePicker(context),
            const SizedBox(height: 24),
            _buildSectionLabel(context, 'Guests'),
            const SizedBox(height: 10),
            _buildGuestSelector(context),
            const SizedBox(height: 24),
            _buildSectionLabel(context, 'Special instructions'),
            const SizedBox(height: 10),
            _buildNotesField(context),
            const SizedBox(height: 32),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppPalette.rust,
            onPrimary: AppTheme.colors.white,
            onSurface: AppTheme.textPrimary(context),
          ),
        ),
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: (date) => setState(() => _selectedDate = date),
        ),
      ),
    );
  }

  Widget _buildGuestSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Number of guests', style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textPrimary(context)),
                onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
              ),
              Text(
                '$_guestCount',
                style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w800),
              ),
              // BUG-9 FIX: Cap guest count at 20 to prevent unrealistic bookings.
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: _guestCount >= 20
                        ? AppTheme.textSecondary(context).withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.primary),
                onPressed: _guestCount < 20 ? () => setState(() => _guestCount++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return TextField(
      controller: _notesController,
      maxLines: 4,
      style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        hintText: 'E.g. We are traveling with seniors, need a low-walking route...',
        hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        filled: true,
        fillColor: AppTheme.surfaceMuted(context),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
            : Text('Send request', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      if (widget.guideId.isNotEmpty) {
        final quotaExceeded = await ref.read(bookingRepositoryProvider).checkMonthlyQuota(widget.guideId);
        if (!mounted) return;
        if (quotaExceeded) {
           throw Exception("This guide has reached their maximum booking quota for the month. Please try again next month or select another guide.");
        }
      }

      Map<String, dynamic>? packageSnapshot;
      if (widget.packageId != null && widget.packageId!.isNotEmpty) {
        final package = await ref.read(packageRepositoryProvider).getPackage(widget.packageId!);
        if (!mounted) return;
        packageSnapshot = package?.toJson();
      }

      final request = BookingRequest(
        bookingId: "", // Will be set by repo
        touristId: user.uid,
        touristDisplayName: user.displayName,
        guideId: widget.guideId,
        packageId: widget.packageId,
        packageSnapshot: packageSnapshot,
        requestedDate: _selectedDate,
        guestCount: _guestCount,
        notes: _notesController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(bookingRepositoryProvider).submitRequest(request);

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        // BUG-8 FIX: Strip the raw "Exception: " prefix so users see a
        // clean message instead of Dart's internal exception format.
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppPalette.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppPalette.rust.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: AppPalette.rust, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                "Request sent",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(dialogContext)),
              ),
              const SizedBox(height: 10),
              Text(
                "Your booking request has been sent to the guide. You'll get a notification once they respond.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary(dialogContext), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // BUG-1 FIX: Use dialogContext to close the dialog, then
                    // use the outer `context` (captured before showDialog) to
                    // pop BookingRequestScreen. Using dialogContext for both
                    // previously left the booking screen stuck open because
                    // dialogContext is already invalid after the first pop.
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context);       // Close BookingRequestScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                    foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
