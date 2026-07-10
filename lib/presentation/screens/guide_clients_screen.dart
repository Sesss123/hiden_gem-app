import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_request.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/client_note_repository.dart';

class _ClientSummary {
  final String touristId;
  final String displayName;
  final List<BookingRequest> bookings;

  _ClientSummary({required this.touristId, required this.displayName, required this.bookings});

  int get tourCount => bookings.where((b) => b.status == 'completed').length;
  DateTime get lastVisit => bookings.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  double get totalSpent => bookings
      .where((b) => b.status == 'completed')
      .fold(0.0, (sum, b) => sum + (b.guideNetAmount ?? (b.quotedPrice ?? 0.0) * 0.90));
}

/// Client CRM — available to all approved guides (not tier-gated). Derives a
/// client list purely from the guide's own booking history via
/// BookingRepository.getInbox(), grouped by touristId client-side; no new
/// Firestore collection needed for tour history. Guide-authored notes per
/// client are the one thing that needs persistence — see ClientNoteRepository.
class GuideClientsScreen extends ConsumerStatefulWidget {
  const GuideClientsScreen({super.key});

  @override
  ConsumerState<GuideClientsScreen> createState() => _GuideClientsScreenState();
}

class _GuideClientsScreenState extends ConsumerState<GuideClientsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Clients')),
        body: Center(child: Text('Please log in.', style: TextStyle(color: AppTheme.textSecondary(context)))),
      );
    }

    final bookingRepo = ref.watch(bookingRepositoryProvider);

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
          'Clients',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<BookingRequest>>(
          stream: bookingRepo.getInbox(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return _buildEmptyState();
            }

            final byClient = <String, List<BookingRequest>>{};
            for (final b in bookings) {
              byClient.putIfAbsent(b.touristId, () => []).add(b);
            }

            final clients = byClient.entries.map((e) {
              final displayName = e.value
                  .map((b) => b.touristDisplayName)
                  .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null);
              return _ClientSummary(
                touristId: e.key,
                displayName: displayName ?? 'Traveler ${e.key.substring(0, e.key.length > 6 ? 6 : e.key.length)}',
                bookings: e.value,
              );
            }).toList()
              ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              physics: const BouncingScrollPhysics(),
              itemCount: clients.length,
              itemBuilder: (context, index) => _buildClientCard(clients[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No clients yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'Once travelers book your tours, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(_ClientSummary client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ClientDetailScreen(client: client))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.displayName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 4),
                    Text(
                      '${client.tourCount} tour${client.tourCount == 1 ? '' : 's'} completed · Last: ${DateFormat('MMM d, yyyy').format(client.lastVisit)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary(context)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ClientDetailScreen extends ConsumerStatefulWidget {
  final _ClientSummary client;
  const _ClientDetailScreen({required this.client});

  @override
  ConsumerState<_ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<_ClientDetailScreen> {
  final _noteController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final note = await ClientNoteRepository().getNote(uid, widget.client.touristId);
    if (mounted) {
      setState(() {
        _noteController.text = note?.note ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    try {
      await ClientNoteRepository().upsertNote(guideId: uid, touristId: widget.client.touristId, note: _noteController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note saved'), backgroundColor: AppTheme.colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(client.displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(child: _buildStat('Tours', '${client.tourCount}')),
              Expanded(child: _buildStat('Total spent', client.totalSpent > 0 ? 'LKR ${client.totalSpent.toStringAsFixed(0)}' : '—')),
              Expanded(child: _buildStat('Last visit', DateFormat('MMM d').format(client.lastVisit))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Notes', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: _noteController,
                maxLines: 5,
                style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(14),
                  hintText: 'Preferences, allergies, memorable moments...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: Text('Save note', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 28),
          Text('Booking history', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 12),
          ...client.bookings.map((b) => _buildBookingTile(b)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context))),
      ],
    );
  }

  Widget _buildBookingTile(BookingRequest b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d, yyyy').format(b.requestedDate), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                Text('${b.guestCount} guest(s)', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Text(b.status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}
