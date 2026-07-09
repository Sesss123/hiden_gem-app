import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 📊 ExplorerProgressService
///
/// Centralised service that tracks a user's exploration journey across
/// Hidden Gems SL. Calculates overall progress percentage, explorer level
/// title, and per-category progress (sites, AR sessions, badges).
///
/// Data is synced bi-directionally with Firestore:
///   - [recordSiteVisit] → call when user visits a place
///   - [recordArSession] → call after a successful AR session
///   - [recordBadgeEarned] → call when a badge is unlocked
class ExplorerProgressService {
  static final ExplorerProgressService _instance = ExplorerProgressService._internal();
  factory ExplorerProgressService() => _instance;
  ExplorerProgressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Total targets (adjust as content grows) ────────────────────────────────
  static const int totalSites = 85;        // All AR-enabled sites in Sri Lanka
  static const int totalArSessions = 50;   // Encourages repeat AR usage
  static const int totalBadges = 10;       // Total badge count

  // ── Live notifiers (UI reacts to these) ───────────────────────────────────
  final ValueNotifier<int> visitedSites   = ValueNotifier(0);
  final ValueNotifier<int> arSessionCount = ValueNotifier(0);
  final ValueNotifier<int> badgeCount     = ValueNotifier(0);
  final ValueNotifier<Set<String>> visitedSiteIds = ValueNotifier({});
  final ValueNotifier<Set<String>> earnedBadgeIds = ValueNotifier({});
  
  Timer? _debounceTimer;
  final Map<String, dynamic> _pendingFields = {};
  bool _isInitialized = false;

  // ── Init & Sync ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialized) return;
    await syncFromCloud();
    _isInitialized = true;
  }

  Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('user_progress').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final siteIds = Set<String>.from(data['visitedSiteIds'] ?? []);
        visitedSiteIds.value = siteIds;
        visitedSites.value  = siteIds.length;
        arSessionCount.value = data['arSessions'] as int? ?? 0;
        earnedBadgeIds.value = Set<String>.from(data['earnedBadgeIds'] ?? []);
        badgeCount.value    = earnedBadgeIds.value.length;
      }
    } catch (e) {
      debugPrint('[ExplorerProgress] Sync failed: $e');
    }
  }

  // ── Record Events ──────────────────────────────────────────────────────────

  /// Call this when the user visits or checks in at a place.
  Future<void> recordSiteVisit(String siteId) async {
    if (visitedSiteIds.value.contains(siteId)) return; // Already counted

    final updated = Set<String>.from(visitedSiteIds.value)..add(siteId);
    visitedSiteIds.value = updated;
    visitedSites.value = updated.length;
    await _saveToCloud({'visitedSiteIds': updated.toList(), 'visitedCount': updated.length});
    await _checkMilestoneBadges();

    debugPrint('[ExplorerProgress] Site visited: $siteId | Total: ${updated.length}');
  }

  /// Call this after each completed AR session.
  Future<void> recordArSession() async {
    arSessionCount.value++;
    await _saveToCloud({'arSessions': arSessionCount.value});
    await _checkMilestoneBadges();
  }

  /// Call when a badge is newly earned directly (e.g. a future non-milestone
  /// badge type). Milestone badges below are auto-awarded — no need to call
  /// this for those.
  Future<void> recordBadgeEarned(String badgeId) async {
    if (earnedBadgeIds.value.contains(badgeId)) return;
    final updated = Set<String>.from(earnedBadgeIds.value)..add(badgeId);
    earnedBadgeIds.value = updated;
    badgeCount.value = updated.length;
    await _saveToCloud({'earnedBadgeIds': updated.toList(), 'badges': updated.length});
  }

  /// Checks visitedSites/arSessionCount against [ExplorerBadge.milestones]
  /// and auto-awards any badge whose threshold has just been crossed.
  Future<void> _checkMilestoneBadges() async {
    for (final badge in ExplorerBadge.milestones) {
      if (earnedBadgeIds.value.contains(badge.id)) continue;
      final current = badge.type == ExplorerBadgeType.sites ? visitedSites.value : arSessionCount.value;
      if (current >= badge.threshold) {
        await recordBadgeEarned(badge.id);
        debugPrint('[ExplorerProgress] Badge earned: ${badge.title}');
      }
    }
  }

  // ── Progress Calculations ──────────────────────────────────────────────────

  /// Overall weighted progress (0.0 – 1.0)
  /// Weighted: Sites 50%, AR 30%, Badges 20%
  double get overallProgress {
    final sitePct  = (visitedSites.value  / totalSites).clamp(0.0, 1.0);
    final arPct    = (arSessionCount.value / totalArSessions).clamp(0.0, 1.0);
    final badgePct = (badgeCount.value    / totalBadges).clamp(0.0, 1.0);
    return (sitePct * 0.5) + (arPct * 0.3) + (badgePct * 0.2);
  }

  /// Sites progress (0.0 – 1.0)
  double get sitesProgress =>
      (visitedSites.value / totalSites).clamp(0.0, 1.0);

  /// AR sessions progress (0.0 – 1.0)
  double get arProgress =>
      (arSessionCount.value / totalArSessions).clamp(0.0, 1.0);

  /// Badges progress (0.0 – 1.0)
  double get badgesProgress =>
      (badgeCount.value / totalBadges).clamp(0.0, 1.0);

  // ── Explorer Level ─────────────────────────────────────────────────────────

  /// Returns the current explorer level title based on overall progress.
  static ExplorerLevel levelFromProgress(double progress) {
    if (progress < 0.20) return ExplorerLevel.beginner;
    if (progress < 0.50) return ExplorerLevel.discoverer;
    if (progress < 0.80) return ExplorerLevel.hunter;
    return ExplorerLevel.master;
  }

  ExplorerLevel get currentLevel => levelFromProgress(overallProgress);

  // ── Private Helpers ────────────────────────────────────────────────────────

  Future<void> _saveToCloud(Map<String, dynamic> fields) async {
    _pendingFields.addAll(fields);
    
    // Debounce: Wait 2 seconds of silence before pushing to Firestore
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      final user = _auth.currentUser;
      if (user == null || _pendingFields.isEmpty) return;

      final fieldsToSave = Map<String, dynamic>.from(_pendingFields);
      _pendingFields.clear();

      try {
        await _firestore.collection('user_progress').doc(user.uid).set(
          {...fieldsToSave, 'lastUpdated': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        debugPrint('[ExplorerProgress] Batch save successful.');
      } catch (e) {
        debugPrint('[ExplorerProgress] Batch save failed: $e');
        // Restore pending fields on failure for next attempt
        _pendingFields.addAll(fieldsToSave);
      }
    });
  }

  void reset() {
    visitedSites.value = 0;
    arSessionCount.value = 0;
    badgeCount.value = 0;
    visitedSiteIds.value = {};
    earnedBadgeIds.value = {};
    _isInitialized = false;
  }
}

// ─── Explorer Badges (Milestones) ─────────────────────────────────────────────

enum ExplorerBadgeType { sites, arSessions }

class ExplorerBadge {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final ExplorerBadgeType type;
  final int threshold;

  const ExplorerBadge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.type,
    required this.threshold,
  });

  /// The 10 auto-awarded milestone badges (matches [ExplorerProgressService.totalBadges]).
  static const List<ExplorerBadge> milestones = [
    ExplorerBadge(id: 'first_steps', title: 'First Steps', emoji: '👣',
        description: 'Visit your first site', type: ExplorerBadgeType.sites, threshold: 1),
    ExplorerBadge(id: 'explorer_5', title: 'Explorer', emoji: '🧭',
        description: 'Visit 5 sites', type: ExplorerBadgeType.sites, threshold: 5),
    ExplorerBadge(id: 'wanderer_15', title: 'Wanderer', emoji: '🗺️',
        description: 'Visit 15 sites', type: ExplorerBadgeType.sites, threshold: 15),
    ExplorerBadge(id: 'adventurer_30', title: 'Adventurer', emoji: '🏔️',
        description: 'Visit 30 sites', type: ExplorerBadgeType.sites, threshold: 30),
    ExplorerBadge(id: 'completionist_85', title: 'Completionist', emoji: '👑',
        description: 'Visit every site in Sri Lanka', type: ExplorerBadgeType.sites, threshold: 85),
    ExplorerBadge(id: 'ar_pioneer_1', title: 'AR Pioneer', emoji: '🔭',
        description: 'Complete your first AR session', type: ExplorerBadgeType.arSessions, threshold: 1),
    ExplorerBadge(id: 'ar_enthusiast_5', title: 'AR Enthusiast', emoji: '✨',
        description: 'Complete 5 AR sessions', type: ExplorerBadgeType.arSessions, threshold: 5),
    ExplorerBadge(id: 'ar_master_15', title: 'AR Master', emoji: '🎇',
        description: 'Complete 15 AR sessions', type: ExplorerBadgeType.arSessions, threshold: 15),
    ExplorerBadge(id: 'ar_veteran_30', title: 'AR Veteran', emoji: '🌟',
        description: 'Complete 30 AR sessions', type: ExplorerBadgeType.arSessions, threshold: 30),
    ExplorerBadge(id: 'ar_legend_50', title: 'AR Legend', emoji: '💫',
        description: 'Complete 50 AR sessions', type: ExplorerBadgeType.arSessions, threshold: 50),
  ];
}

// ─── Explorer Level Enum ──────────────────────────────────────────────────────

enum ExplorerLevel {
  beginner(
    title: 'Beginner Explorer',
    emoji: '🌱',
    subtitle: 'Your journey begins...',
    minProgress: 0.0,
    maxProgress: 0.20,
  ),
  discoverer(
    title: 'Site Discoverer',
    emoji: '🧭',
    subtitle: 'You\'re finding hidden gems!',
    minProgress: 0.20,
    maxProgress: 0.50,
  ),
  hunter(
    title: 'Heritage Hunter',
    emoji: '🏛️',
    subtitle: 'Deep in the ancient world',
    minProgress: 0.50,
    maxProgress: 0.80,
  ),
  master(
    title: 'Hidden Gems Master',
    emoji: '👑',
    subtitle: 'Sri Lanka\'s ultimate explorer',
    minProgress: 0.80,
    maxProgress: 1.0,
  );

  final String title;
  final String emoji;
  final String subtitle;
  final double minProgress;
  final double maxProgress;

  const ExplorerLevel({
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.minProgress,
    required this.maxProgress,
  });

  // Progress within THIS level only (0.0 → 1.0 to next level)
  double progressWithinLevel(double overall) {
    final range = maxProgress - minProgress;
    if (range <= 0) return 1.0;
    return ((overall - minProgress) / range).clamp(0.0, 1.0);
  }
}
