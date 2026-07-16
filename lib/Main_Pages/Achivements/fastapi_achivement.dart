// ============================================================
//  OptionXi — fastapi_achivement.dart  (v4)
//
//  Changes from v3:
//   • DEV_MODE: set devMode = true to bypass the daily streak
//     cache on the client — fires daily_activity on every
//     initState call (matches DEV_MODE=true on the backend).
//   • Streak UI fix: currentDays now reads from xi_streak_state
//     via a dedicated fetchStreakState() call, so it always
//     reflects the real server value instead of guessing from
//     progressMax of an unlocked achievement.
//   • Toast fix: _doTrack now calls fetchAll() and shows toasts
//     for BOTH newly unlocked achievements AND progress-completed
//     ones that appear in the `unlocked` list from the backend.
//
//  pubspec.yaml additions needed:
//    shared_preferences: ^2.2.0
//    supabase_flutter: ^2.5.0
//    http: ^1.2.0
//    firebase_auth: ^4.0.0
// ============================================================

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:optionxi/Main_Pages/Achivements/achivement_toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

abstract class AchievementConfig {
  static String get apiBase => dotenv.env['ACHIEVEMENT_API_BASE']!;
  static String get apiKey => dotenv.env['ACHIEVEMENT_API_KEY']!;

  /// Set to true during development to bypass the once-per-day streak guard.
  /// MUST match DEV_MODE=true in the backend .env — both must be true together.
  /// Set to false before shipping to production.
  static bool get devMode => dotenv.env['ACHIEVEMENT_DEV_MODE'] == 'true';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum AchievementRarity { common, rare, epic, legendary }

enum AchievementCategory { trading, options, screener, streak, social, special }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String hint;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final String iconKey;
  final String iconSvg; // raw SVG <path d="..."> string from xi_achievements
  final int? progressMax;
  final int sortOrder;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.category,
    required this.rarity,
    required this.xpReward,
    required this.iconKey,
    required this.iconSvg,
    required this.sortOrder,
    this.progressMax,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
  });

  double get progressPercent => (progressMax == null || progressMax == 0)
      ? 0
      : (progress / progressMax!).clamp(0.0, 1.0);

  bool get isNew =>
      isUnlocked &&
      unlockedAt != null &&
      DateTime.now().difference(unlockedAt!).inDays < 3;

  factory Achievement.fromRow(
    Map<String, dynamic> row, {
    bool unlocked = false,
    DateTime? unlockedAt,
    int progress = 0,
  }) =>
      Achievement(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        hint: row['hint'] as String,
        category: AchievementCategory.values.firstWhere(
            (e) => e.name == row['category'],
            orElse: () => AchievementCategory.trading),
        rarity: AchievementRarity.values.firstWhere(
            (e) => e.name == row['rarity'],
            orElse: () => AchievementRarity.common),
        xpReward: (row['xp_reward'] as int?) ?? 0,
        iconKey: row['icon_key'] as String,
        iconSvg: (row['icon_svg'] as String?) ?? '',
        progressMax: row['progress_max'] as int?,
        sortOrder: (row['sort_order'] as int?) ?? 0,
        isUnlocked: unlocked,
        unlockedAt: unlockedAt,
        progress: progress,
      );
}

/// The live streak state read directly from xi_streak_state on Supabase.
class StreakState {
  final int streakDays;
  final DateTime? lastActiveDate;
  final int graceUsed;

  const StreakState({
    this.streakDays = 0,
    this.lastActiveDate,
    this.graceUsed = 0,
  });
}

/// Minimal achievement info returned by the backend alongside event results.
/// Contains everything a toast needs — no fetchAll() required.
class ToastInfo {
  final String id;
  final String title;
  final String description;
  final AchievementRarity rarity;
  final String iconKey;
  final String iconSvg;
  final int xpReward;
  final int?
      progress; // null for unlock toasts; current value for progress toasts
  final int?
      progressMax; // null for unlock toasts; target value for progress toasts

  const ToastInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.iconKey,
    required this.iconSvg,
    required this.xpReward,
    this.progress,
    this.progressMax,
  });

  factory ToastInfo.fromJson(Map<String, dynamic> j) => ToastInfo(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        rarity: AchievementRarity.values.firstWhere(
            (e) => e.name == j['rarity'],
            orElse: () => AchievementRarity.common),
        iconKey: j['icon_key'] as String,
        iconSvg: (j['icon_svg'] as String?) ?? '',
        xpReward: (j['xp_reward'] as int?) ?? 0,
        progress: j['progress'] as int?,
        progressMax: j['progress_max'] as int?,
      );
}

class TrackResult {
  final List<String> unlocked;
  final List<String> progressed;
  final List<ToastInfo> toastData;

  const TrackResult({
    required this.unlocked,
    required this.progressed,
    this.toastData = const [],
  });

  bool get hasUnlocks => unlocked.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAK CACHE
//
//  Prevents the homepage from spamming daily_streak events.
//  In normal mode: fires at most ONCE per calendar day per UID.
//  In devMode: ALWAYS fires (bypasses the date guard entirely).
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCache {
  static const _keyPrefix = 'xi_streak_last_fire_';

  static String _key(String uid) => '$_keyPrefix$uid';

  /// Returns true (and records today) if the event should fire.
  /// In devMode always returns true without touching SharedPreferences.
  static Future<bool> shouldFire(String uid) async {
    // DEV: always fire so each initState increments the streak on the server
    if (AchievementConfig.devMode) return true;

    final prefs = await SharedPreferences.getInstance();
    final key = _key(uid);
    final stored = prefs.getString(key);
    final today = _dateStr(DateTime.now());

    if (stored == today) return false; // already fired today

    await prefs.setString(key, today);
    return true;
  }

  static String _dateStr(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT
// ─────────────────────────────────────────────────────────────────────────────

class AchievementClient {
  AchievementClient._();

  static final _db = Supabase.instance.client;
  static final _auth = FirebaseAuth.instance;

  // ── Internal helpers ───────────────────────────────────────────────────────

  static Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    return await user.getIdToken() ??
        (throw Exception('Could not get ID token'));
  }

  static String _uid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    return uid;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fire an event to the FastAPI backend.
  /// Returns which achievements were unlocked/progressed.
  /// Errors are silently swallowed — tracking must never crash the UI.
  static Future<TrackResult> track(
    String event, {
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      final token = await _idToken();
      final res = await http
          .post(
            Uri.parse('${AchievementConfig.apiBase}/achievements/event'),
            headers: {
              'Content-Type': 'application/json',
              'X-Api-Key': AchievementConfig.apiKey,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'event': event, 'meta': meta}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final rawToast = (body['toast_data'] as List<dynamic>?) ?? [];
        return TrackResult(
          unlocked: List<String>.from(body['unlocked'] ?? []),
          progressed: List<String>.from(body['progressed'] ?? []),
          toastData: rawToast
              .map((e) => ToastInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (_) {
      // Silent — achievements must never block the UI.
    }
    return const TrackResult(unlocked: [], progressed: []);
  }

  /// Fetch all achievements merged with this user's unlock state.
  static Future<List<Achievement>> fetchAll() async {
    final uid = _uid();

    final achRows = await _db
        .from('xi_achievements')
        .select()
        .order('sort_order', ascending: true);

    final userRows =
        await _db.from('xi_user_achievements').select().eq('firebase_uid', uid);

    final Map<String, Map<String, dynamic>> userMap = {
      for (final item in userRows as List<dynamic>)
        (item as Map<String, dynamic>)['achievement_id'] as String: item,
    };

    return (achRows as List<dynamic>).map((item) {
      final row = item as Map<String, dynamic>;
      final id = row['id'] as String;
      final userRow = userMap[id];

      // Prefer the explicit `state` column; fall back to unlocked_at check
      // for rows written before the migration.
      final stateStr = userRow?['state'] as String?;
      final isUnlocked = stateStr == 'unlocked' ||
          (stateStr == null &&
              userRow != null &&
              userRow['unlocked_at'] != null);

      return Achievement.fromRow(
        row,
        unlocked: isUnlocked,
        unlockedAt: userRow != null
            ? DateTime.tryParse(userRow['unlocked_at'] as String? ?? '')
            : null,
        progress: (userRow?['progress'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Fetch the real-time streak state directly from xi_streak_state.
  /// This is the authoritative source — do NOT derive streak days from
  /// achievement progress_max values.
  static Future<StreakState> fetchStreakState() async {
    try {
      final uid = _uid();
      final rows =
          await _db.from('xi_streak_state').select().eq('firebase_uid', uid);

      final list = rows as List<dynamic>;
      if (list.isEmpty) return const StreakState();

      final row = list.first as Map<String, dynamic>;
      return StreakState(
        streakDays: (row['streak_days'] as int?) ?? 0,
        lastActiveDate: row['last_active_date'] != null
            ? DateTime.tryParse(row['last_active_date'] as String)
            : null,
        graceUsed: (row['grace_used'] as int?) ?? 0,
      );
    } catch (_) {
      return const StreakState();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVENIENCE WRAPPERS
// ─────────────────────────────────────────────────────────────────────────────

class AchievementEvents {
  AchievementEvents._();

  // ── Screener ──────────────────────────────────────────────────────────────
  static void ranScreener() =>
      AchievementToastService.trackAndShow('ran_screener');

  static void addedToWatchlist() =>
      AchievementToastService.trackAndShow('added_to_watchlist');

  // ── Feature first-opens ───────────────────────────────────────────────────
  static void openedScreener() =>
      AchievementToastService.trackAndShow('opened_screener_page');

  static void openedMarketMovers() =>
      AchievementToastService.trackAndShow('opened_market_movers');

  static void openedSectorPulse() =>
      AchievementToastService.trackAndShow('opened_sector_pulse');

  static void openedBreakouts() =>
      AchievementToastService.trackAndShow('opened_breakouts');

  static void openedSentiment() =>
      AchievementToastService.trackAndShow('opened_sentiment');

  static void openedAIChat() =>
      AchievementToastService.trackAndShow('opened_ai_chat');

  static void openedStockAlerts() =>
      AchievementToastService.trackAndShow('opened_stock_alerts');

  static void openedNews() =>
      AchievementToastService.trackAndShow('opened_news');

  static void openedLive() =>
      AchievementToastService.trackAndShow('opened_live');

  // ── Trades ────────────────────────────────────────────────────────────────
  static void tradePlaced({
    required String instrument,
    required String transactionType,
    required bool isShortSell,
    required String segment,
  }) =>
      AchievementToastService.trackAndShow('trade_placed', meta: {
        'instrument': instrument,
        'transaction_type': transactionType,
        'is_short_sell': isShortSell,
        'segment': segment,
      });

  static void optionTradePlaced({required String type}) =>
      AchievementToastService.trackAndShow('option_trade_placed',
          meta: {'type': type});

  static void expiryTradeClosed() =>
      AchievementToastService.trackAndShow('expiry_trade_closed');

  // ── Streak ────────────────────────────────────────────────────────────────

  /// Call once from each page's initState.
  /// In production: fires at most once per calendar day.
  /// In devMode (AchievementConfig.devMode == true): fires every time,
  /// which increments the streak on every app restart — for testing only.
  static Future<void> dailyActivity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final shouldFire = await _StreakCache.shouldFire(uid);
    if (!shouldFire) return;

    // fire-and-forget — toast will appear if a streak milestone is hit
    AchievementToastService.trackAndShow('daily_activity');
  }

  static void marketOpenTrade() =>
      AchievementToastService.trackAndShow('market_open_trade');

  static void nightOwlActivity() =>
      AchievementToastService.trackAndShow('night_owl_activity');

  // ── Social ────────────────────────────────────────────────────────────────
  static void portfolioShared() =>
      AchievementToastService.trackAndShow('portfolio_shared');

  static void referralCompleted({required int totalReferrals}) =>
      AchievementToastService.trackAndShow('referral_completed',
          meta: {'total_referrals': totalReferrals});

  static void leaderboardRankUpdated({required int rank}) =>
      AchievementToastService.trackAndShow('leaderboard_rank_updated',
          meta: {'rank': rank});

  // ── Special ───────────────────────────────────────────────────────────────
  static void weekClosed({required bool allTradesProfitable}) =>
      AchievementToastService.trackAndShow('week_closed',
          meta: {'all_trades_profitable': allTradesProfitable});
}
