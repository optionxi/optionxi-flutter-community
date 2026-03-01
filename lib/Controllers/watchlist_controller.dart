import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:optionxi/DB_Services/database_read.dart';
import 'package:optionxi/DB_Services/database_write.dart';
import 'package:optionxi/DB_Services_Supabase/database_read_supabase.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';

class WatchlistController extends GetxController {
  final DatabaseReadService _dbService = DatabaseReadService();
  final StockSupabaseService _supabaseService = StockSupabaseService();

  final RxList<DataStockModel> watchlistStocks = <DataStockModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  // Subscription management
  StreamSubscription? _stocksSubscription;
  final RxList<String> _watchlistSymbols = <String>[].obs;

  // Map to store stock full names
  final Map<String, String> _stockFullNames = <String, String>{};

  List<DataStockModel> get filteredWatchlistStocks {
    if (searchQuery.value.isEmpty) {
      return watchlistStocks;
    }
    return watchlistStocks.where((stock) {
      return stock.symbol
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          stock.stckname
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    super.onInit();
    loadWatchlist();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _cancelSubscription();
    super.onClose();
  }

  void _cancelSubscription() {
    _stocksSubscription?.cancel();
    _stocksSubscription = null;
  }

  Future<void> _setupRealtimeSubscription() async {
    // Cancel any existing subscription
    _cancelSubscription();

    // Only setup subscription if we have symbols to watch
    if (_watchlistSymbols.isEmpty) {
      watchlistStocks.clear();
      return;
    }

    try {
      _stocksSubscription = _supabaseService
          .subscribeToStocks(_watchlistSymbols, _stockFullNames)
          .listen(
        (stockDataList) {
          // Update watchlist stocks with real-time data

          for (var stockData in stockDataList) {
            final updatedStock = DataStockModel.fromJson(stockData);
            // print("Updating stocks watchlist" + updatedStock.symbol.toString());
            final index = watchlistStocks
                .indexWhere((s) => s.symbol == updatedStock.symbol);

            if (index >= 0) {
              watchlistStocks[index] = updatedStock;
            } else {
              // This shouldn't normally happen, but handle it just in case
              watchlistStocks.add(updatedStock);
            }
          }
        },
        onError: (error) {
          print('Subscription error: $error');
          errorMessage('Connection error. Pull to refresh.');
        },
      );
    } catch (e) {
      print('Error setting up real-time subscription: $e');
      errorMessage('Failed to setup real-time updates');
    }
  }

  Future<void> refreshLTP() async {
    try {
      if (_watchlistSymbols.isEmpty) return;

      // Fetch all stocks in one query with custom full names
      final updatedStocks = await _supabaseService.fetchMultipleStocksBySymbols(
          _watchlistSymbols, _stockFullNames);

      // Update the watchlist with the fresh data
      watchlistStocks.assignAll(updatedStocks);
    } catch (e) {
      errorMessage('Failed to refresh LTP: ${e.toString()}');
    }
  }

  Future<void> loadWatchlist() async {
    try {
      isLoading(true);
      errorMessage('');

      // Get user's favorite stocks from Firebase
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        errorMessage('User not logged in');
        return;
      }

      final favorites = await _dbService.getFavoriteStocks(userId);

      // Clear existing data
      _watchlistSymbols.clear();
      _stockFullNames.clear();

      // Extract symbols and full names
      for (final favorite in favorites) {
        _watchlistSymbols.add(favorite.stockName);
        _stockFullNames[favorite.stockName] = favorite.fullStockName;
      }

      // Fetch all stocks in a single query with custom full names
      if (_watchlistSymbols.isNotEmpty) {
        final stocks = await _supabaseService.fetchMultipleStocksBySymbols(
            _watchlistSymbols, _stockFullNames);
        watchlistStocks.assignAll(stocks);
      } else {
        watchlistStocks.clear();
      }

      // Setup real-time subscription
      await _setupRealtimeSubscription();
    } catch (e) {
      errorMessage('Failed to load watchlist: ${e.toString()}');
      watchlistStocks.clear();
    } finally {
      isLoading(false);
    }
  }

  Future<void> removeFromWatchlist(DataStockModel stock) async {
    try {
      isLoading(true); // Show loading state
      errorMessage('');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        errorMessage('User not logged in');
        return;
      }

      // Remove from Firebase first
      await DatabaseWriteService().removeFromFavorites(userId, stock.symbol);

      // Update local state
      watchlistStocks.removeWhere((s) => s.symbol == stock.symbol);
      _watchlistSymbols.removeWhere((symbol) => symbol == stock.symbol);
      _stockFullNames.remove(stock.symbol);

      // Force a refresh of the subscription
      await _setupRealtimeSubscription();

      // Optional: Force a refresh of the remaining stocks
      await refreshLTP();
    } catch (e) {
      errorMessage('Failed to remove stock: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }
}
