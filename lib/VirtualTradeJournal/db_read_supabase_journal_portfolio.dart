import 'dart:async';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings_journal.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- SERVICE CLASS ---
class PortfolioJournalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- FETCH METHODS ---
  Future<double> fetchBalance(String suid) async {
    try {
      final response = await _supabase
          .from('journal_balance')
          .select('balance')
          .eq('suid', suid)
          .maybeSingle();
      if (response == null || response['balance'] == null) {
        return 0.0;
      }
      return (response['balance'] as num).toDouble();
    } catch (e) {
      print('Error fetching balance: $e');
      return 0.0;
    }
  }

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

  Future<List<JournalTradeHistory>> fetchTradeHistory(String suid) async {
    try {
      final response = await _supabase
          .from('journal_trade_history')
          .select()
          .eq('suid', suid);
      return (response as List)
          .map((e) => JournalTradeHistory.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching trade history: $e');
      return [];
    }
  }

  // --- SUBSCRIPTION (REALTIME) METHODS ---
  // Note: These now filter on the client-side to prevent the PostgrestException.
  // For large tables, a more optimized approach using database functions (RPC) or channels is recommended.

  Stream<double> subscribeToBalance(String suid) {
    return _supabase
        .from('journal_balance')
        .stream(primaryKey: ['id'])
        .eq('suid', suid) // Server-side filtering
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
        .eq('suid', suid) // Server-side filtering
        .map((payload) => payload
            .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: false))
            .toList());
  }

  Stream<List<BasketUserHolding>> subscribeToShortPositions(String suid) {
    return _supabase
        .from('journal_short_positions')
        .stream(primaryKey: ['id'])
        .eq('suid', suid) // Apply server-side filter
        .map((payload) => payload
            .map((e) => BasketUserHolding.fromJson(e).copyWith(isshort: true))
            .toList());
  }

  Stream<List<JournalTradeHistory>> subscribeToTradeHistory(String suid) {
    return _supabase
        .from('journal_trade_history')
        .stream(primaryKey: ['id'])
        .eq('suid', suid) // Apply server-side filter
        .map((payload) =>
            payload.map((e) => JournalTradeHistory.fromJson(e)).toList());
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
