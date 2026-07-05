import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_availability.dart';
import '../../data/models/guide_listing.dart';
import '../../data/repositories/marketplace_repository.dart';

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

  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _noticeOptions = ['2', '6', '12', '24', '48', '72'];

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
      } catch (e) {
        debugPrint('Error fetching availability: $e');
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
          colorScheme: const ColorScheme.dark(
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
          SnackBar(content: Text('🎉 Availability & Schedule Updated!'), backgroundColor: AppTheme.colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving availability: $e'), backgroundColor: AppTheme.colors.redAccent),
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.colors.amber)),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        title: Text(
          'AVAILABILITY & SCHEDULE',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: true,
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionTitle('INSTANT BOOK & NOTICE'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor(context)),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Instant Book Enabled', style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
                      subtitle: Text('Allow tourists to book immediately without manual approval', style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                      value: _instantBookEnabled,
                      activeThumbColor: AppTheme.colors.amber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _instantBookEnabled = val),
                    ),
                    Divider(color: AppTheme.borderColor(context)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Advance Notice Required', style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                              Text('Minimum lead time before tour starts', style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: DropdownButton<String>(
                            value: _advanceNoticeHours,
                            dropdownColor: Theme.of(context).cardColor,
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down, color: AppTheme.colors.amber),
                            items: _noticeOptions.map((e) => DropdownMenuItem(value: e, child: Text('$e hrs', style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (val) => setState(() => _advanceNoticeHours = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildSectionTitle('RECURRING WEEKLY SCHEDULE'),
              const SizedBox(height: 4),
              Text('Toggle working days and customize working hours', style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
              const SizedBox(height: 12),
              ...List.generate(7, (index) {
                final dayIndex = index + 1;
                final dayName = _daysOfWeek[index];
                final slot = _weeklySlots[dayIndex];
                final isWorking = slot != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: isWorking ? 1.0 : 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isWorking ? AppTheme.colors.amber.withValues(alpha: 0.4) : AppTheme.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayName,
                          style: GoogleFonts.outfit(
                            color: isWorking ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Switch(
                        value: isWorking,
                        activeThumbColor: AppTheme.colors.amber,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor(context))),
                            child: Text(slot.startTime, style: GoogleFonts.outfit(color: AppTheme.colors.amber[400], fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-', style: TextStyle(color: AppTheme.textSecondary(context))),
                        ),
                        GestureDetector(
                          onTap: () => _pickTime(dayIndex, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor(context))),
                            child: Text(slot.endTime, style: GoogleFonts.outfit(color: AppTheme.colors.amber[400], fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Text('OFF', style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('BLACKOUT DATES (${_blackoutDates.length})'),
                  TextButton.icon(
                    onPressed: _pickBlackoutDate,
                    icon: Icon(Icons.add_circle_outline, color: AppTheme.colors.amber, size: 18),
                    label: Text('ADD DATE', style: GoogleFonts.outfit(color: AppTheme.colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_blackoutDates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Text('No blackout dates added. You are available according to your schedule.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13)),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _blackoutDates.map((date) {
                    return Chip(
                      backgroundColor: AppTheme.colors.redAccent.withValues(alpha: 0.2),
                      side: BorderSide(color: AppTheme.colors.redAccent.withValues(alpha: 0.5)),
                      label: Text(dateFormat.format(date), style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                      deleteIcon: Icon(Icons.close, size: 16, color: AppTheme.colors.white70),
                      onDeleted: () {
                        setState(() {
                          _blackoutDates.remove(date);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.amber,
                    foregroundColor: AppTheme.colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                  ),
                  child: _isSaving
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.colors.black))
                      : Text('SAVE AVAILABILITY & SCHEDULE 📅', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppTheme.colors.amber[400],
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }
}
