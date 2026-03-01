import 'dart:async';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings_journal.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- SERVICE CLASS ---
class PortfolioJournalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- FETCH METHODS ---
  Future<List<BasketUserHolding>> fetchHoldings(String suid) async {
    try {
      final response = await _supabase
          .from('journal_user_holdings')
          .select()
          .eq('suid', suid);
      return (response as List)
          .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: false))
          .toList();
    } catch (e) {
      print('Error fetching holdings: $e');
      return [];
    }
  }

  Future<List<BasketUserHolding>> fetchShortPositions(String suid) async {
    try {
      final response = await _supabase
          .from('journal_short_positions')
          .select()
          .eq('suid', suid);
      return (response as List)
          .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: true))
          .toList();
    } catch (e) {
      print('Error fetching short positions: $e');
      return [];
    }
  }

  /// Fetches trade history filtered by [days] from today server-side.
  /// Pass [days] = null to fetch all records (no date filter).
  Future<List<JournalTradeHistory>> fetchTradeHistory(
    String suid, {
    int days = 30,
  }) async {
    try {
      var query =
          _supabase.from('journal_trade_history').select().eq('suid', suid);

      final cutoff =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      query = query.gte('exit_date', cutoff);

      final response = await query;
      return (response as List)
          .map((e) => JournalTradeHistory.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching trade history: $e');
      return [];
    }
  }

  // --- SUBSCRIPTION (REALTIME) METHODS ---
  Stream<double> subscribeToBalance(String suid) {
    return _supabase
        .from('journal_balance')
        .stream(primaryKey: ['id'])
        .eq('suid', suid)
        .map((payload) {
          if (payload.isEmpty || payload.first['balance'] == null) {
            return 0.0;
          }
          return (payload.first['balance'] as num).toDouble();
        });
  }

  Stream<List<BasketUserHolding>> subscribeToHoldings(String suid) {
    return _supabase
        .from('journal_user_holdings')
        .stream(primaryKey: ['id'])
        .eq('suid', suid)
        .map((payload) => payload
            .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: false))
            .toList());
  }

  Stream<List<BasketUserHolding>> subscribeToShortPositions(String suid) {
    return _supabase
        .from('journal_short_positions')
        .stream(primaryKey: ['id'])
        .eq('suid', suid)
        .map((payload) => payload
            .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: true))
            .toList());
  }

  /// Realtime change-notification stream for trade history.
  /// Returns a void stream that fires whenever the table changes for this user.
  /// The controller re-fetches server-side (with date filter) on each event,
  /// so all filtering happens on Supabase — not on the client.
  Stream<void> subscribeToTradeHistoryChanges(String suid) {
    return _supabase
        .from('journal_trade_history')
        .stream(primaryKey: ['id'])
        .eq('suid', suid)
        .map((_) => null);
  }

  Stream<List<Map<String, dynamic>>> subscribeToLiveNifty50() {
    return _supabase.from('live_5000_stocks').stream(primaryKey: ['symbol']);
  }

  Stream<List<Map<String, dynamic>>> subscribeToLiveFNO() {
    return _supabase
        .from('live_fno_bankandnifty')
        .stream(primaryKey: ['symbol']);
  }
}
