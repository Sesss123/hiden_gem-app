import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/booking_request.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepHeader("01", "MISSION DATE"),
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 32),
                    _buildStepHeader("02", "GUEST COUNT"),
                    const SizedBox(height: 16),
                    _buildGuestSelector(),
                    const SizedBox(height: 32),
                    _buildStepHeader("03", "SPECIAL INSTRUCTIONS"),
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 48),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: OracleUI.neonText(
        "BOOK MISSION",
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String label) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E676), width: 1),
          ),
          child: Text(number, style: GoogleFonts.outfit(color: const Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        onDateChanged: (date) => setState(() => _selectedDate = date),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildGuestSelector() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, color: Colors.white),
            onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
          ),
          Text(
            "$_guestCount GUESTS",
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => setState(() => _guestCount++),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      borderRadius: BorderRadius.circular(20),
      child: TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white70),
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "E.g. We are traveling with seniors, need low-walking route...",
          hintStyle: GoogleFonts.inter(color: Colors.white10, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSubmitting 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              "TRANSMIT REQUEST",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final request = BookingRequest(
        bookingId: "", // Will be set by repo
        touristId: user.uid,
        guideId: widget.guideId,
        packageId: widget.packageId,
        requestedDate: _selectedDate,
        guestCount: _guestCount,
        notes: _notesController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(bookingRepositoryProvider).submitRequest(request);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OracleUI.glassContainer(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 64),
            const SizedBox(height: 24),
            OracleUI.neonText(
              "REQUEST SENT",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Your mission request has been transmitted to the guide. You will receive a notification once they respond.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Booking Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
