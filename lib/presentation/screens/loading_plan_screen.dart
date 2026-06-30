import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/ai_trip_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/trip_plan_model.dart';

import 'results_screen.dart';

class LoadingPlanScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final int days;
  final String startDate;
  final String groupType;
  final String pace;
  final int budgetLkr;
  final String style;
  final String transport;
  final List<String> interests;
  final List<String> mustInclude;
  final List<String> avoid;
  final List<String> constraints;

  const LoadingPlanScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.days,
    required this.startDate,
    required this.groupType,
    required this.pace,
    required this.budgetLkr,
    required this.style,
    required this.transport,
    required this.interests,
    required this.mustInclude,
    required this.avoid,
    required this.constraints,
  });

  @override
  State<LoadingPlanScreen> createState() => _LoadingPlanScreenState();
}

class _LoadingPlanScreenState extends State<LoadingPlanScreen>
    with TickerProviderStateMixin {
  String _statusText = "Consulting HiddenGems.lk Brain...";
  bool _hasError = false;
  bool _isOfflineMode = false;
  String _errorMessage = "";

  final List<String> _progressMessages = [
    "Analyzing Sri Lanka train schedules...",
    "Checking seasonal weather patterns...",
    "Clustering the best hidden gems nearby...",
    "Calculating budget with 10% safety buffer...",
    "Crafting your personalised day plan...",
    "Adding rain-day alternatives (Plan B)...",
    "Finalising tips from local experts...",
  ];

  int _msgIndex = 0;

  // Sri Lanka city coordinate lookup table (Bug C-01 Fix)
  static const Map<String, List<double>> _cityCoordinates = {
    'colombo': [6.9271, 79.8612],
    'galle': [6.0535, 80.2117],
    'kandy': [7.2906, 80.6337],
    'ella': [6.8667, 81.0466],
    'nuwara eliya': [6.9497, 80.7891],
    'jaffna': [9.6615, 80.0255],
    'trincomalee': [8.5873, 81.2152],
    'batticaloa': [7.7102, 81.6924],
    'negombo': [7.2008, 79.8737],
    'anuradhapura': [8.3114, 80.4037],
    'polonnaruwa': [7.9403, 81.0188],
    'sigiriya': [7.9570, 80.7603],
    'dambulla': [7.8742, 80.6511],
    'matara': [5.9549, 80.5550],
    'hambantota': [6.1248, 81.1185],
    'tangalle': [6.0243, 80.7938],
    'mirissa': [5.9483, 80.4578],
    'weligama': [5.9722, 80.4288],
    'hikkaduwa': [6.1395, 80.1058],
    'unawatuna': [6.0174, 80.2489],
    'arugam bay': [6.8418, 81.8312],
    'habarana': [8.0357, 80.7512],
    'pinnawala': [7.3005, 80.3847],
    'ratnapura': [6.6828, 80.3992],
    'kurunegala': [7.4863, 80.3647],
    'bandarawela': [6.8312, 80.9981],
    'badulla': [6.9934, 81.0550],
    'monaragala': [6.8724, 81.3496],
    'ampara': [7.2912, 81.6747],
    'mannar': [8.9810, 79.9044],
    'vavuniya': [8.7514, 80.4971],
    'kataragama': [6.4131, 81.3325],
    'tissamaharama': [6.2803, 81.2906],
    'bentota': [6.4201, 79.9998],
    'beruwala': [6.4789, 79.9829],
    'chilaw': [7.5759, 79.7952],
    'kalpitiya': [8.2255, 79.7619],
    'puttalam': [8.0362, 79.8283],
    'avissawella': [6.9518, 80.2017],
    'hatton': [6.8875, 80.5986],
    'nanu oya': [6.9389, 80.7533],
    'ohiya': [6.8167, 80.8500],
    'bia / airport': [7.1811, 79.8837],
    'katunayake': [7.1706, 79.8797],
  };

  @override
  void initState() {
    super.initState();
    _generate();
    _animateMessages();
  }

  void _animateMessages() async {
    while (_msgIndex < _progressMessages.length - 1 && mounted) {
      await Future.delayed(const Duration(milliseconds: 2800));
      if (mounted) {
        setState(() {
          _msgIndex = (_msgIndex + 1) % _progressMessages.length;
          _statusText = _progressMessages[_msgIndex];
        });
      }
    }
  }

  void _generate() async {
    final cacheKey = TripCacheService.buildCacheKey(
      origin: widget.origin,
      destination: widget.destination,
      days: widget.days,
      budgetLkr: widget.budgetLkr,
      style: widget.style,
      interests: widget.interests,
      transport: widget.transport,
      startDate: widget.startDate,
    );

    final normOrigin = widget.origin.trim().toLowerCase();
    final coords = _cityCoordinates[normOrigin] ?? [6.9271, 79.8612];
    final originLat = coords[0];
    final originLng = coords[1];

    try {
      final TripPlan plan = await AiTripService.generateTrip(
        origin: widget.origin,
        fromLat: originLat,
        fromLng: originLng,
        destination: widget.destination,
        days: widget.days,
        startDate: widget.startDate,
        groupType: widget.groupType,
        pace: widget.pace,
        budgetLkr: widget.budgetLkr,
        style: widget.style,
        interests: widget.interests,
        transportPreference: widget.transport,
        constraints: widget.constraints,
        mustInclude: widget.mustInclude,
        avoid: widget.avoid,
      );

      await TripCacheService.cacheLastPlan(plan, cacheKey);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              plan: plan,
              cacheState: CacheReadResult.fresh,
              cacheKey: cacheKey,
            ),
          ),
        );
      }
    } catch (e) {
      final result = TripCacheService.getLastPlan(cacheKey);
      if (result.hasData && mounted) {
        setState(() => _isOfflineMode = true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                plan: result.plan!,
                cacheState: result.state,
                cacheKey: cacheKey,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _hasError ? _buildErrorState() : _buildManifestingState(),
          ),
        ),
      ),
    );
  }

  Widget _buildManifestingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading Orb (spinning dashed ring)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppPalette.rust.withValues(alpha: 0.2),
                AppPalette.rust.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Use a spinning widget for the dashed ring effect
              const Icon(Icons.sync_rounded, size: 40, color: AppPalette.rust)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 4.seconds),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isOfflineMode ? "OFFLINE RECOVERY" : "MANIFESTING",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
            letterSpacing: 2,
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: AppPalette.rust),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: Text(
            _isOfflineMode ? "Synthesizing Local Memories…" : _statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppPalette.rust,
            ),
          ).animate(key: ValueKey(_statusText)).fadeIn(duration: 600.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_fix_off, size: 60, color: Colors.redAccent),
          const SizedBox(height: 24),
          Text(
            "THE CONNECTION FADED",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _statusText = "Re-Consulting Oracle...";
                });
                _generate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.rust,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("TRY AGAIN", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("REFINE REQUEST", style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
