import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/VirtualTrading/VDatabaseSupabase/db_read_supabase_prev_virtual.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnodata.dart';

class FNOController extends GetxController {
  final VirtualSupabaseService _fnoService = VirtualSupabaseService();

  // Observable lists
  final RxList<DataStockModel> nifty50Stocks = <DataStockModel>[].obs;
  final RxList<DataFNOModel> allFNOOptions = <DataFNOModel>[].obs;

  // State management
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt activeTab = 0.obs;
  final RxInt optionSubTab = 0.obs; // 0 = Call, 1 = Put

  // Subscriptions
  StreamSubscription? _nifty50Subscription;
  StreamSubscription? _fnoSubscription;

  // Simplified getters
  List<DataStockModel> get filteredNifty50Stocks {
    return _filterStocks(nifty50Stocks);
  }

  List<DataFNOModel> get filteredBankNiftyOptions {
    return _filterFNOOptions(allFNOOptions, 'BANKNIFTY');
  }

  List<DataFNOModel> get filteredNiftyOptions {
    return _filterFNOOptions(allFNOOptions, 'NIFTY');
  }

  List<DataFNOModel> get filteredBankNiftyCallOptions {
    return _filterFNOOptions(allFNOOptions, 'BANKNIFTY', optionType: 'CE');
  }

  List<DataFNOModel> get filteredBankNiftyPutOptions {
    return _filterFNOOptions(allFNOOptions, 'BANKNIFTY', optionType: 'PE');
  }

  List<DataFNOModel> get filteredNiftyCallOptions {
    return _filterFNOOptions(allFNOOptions, 'NIFTY', optionType: 'CE');
  }

  List<DataFNOModel> get filteredNiftyPutOptions {
    return _filterFNOOptions(allFNOOptions, 'NIFTY', optionType: 'PE');
  }

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  @override
  void onClose() {
    _cancelSubscriptions();
    super.onClose();
  }

  void _cancelSubscriptions() {
    _nifty50Subscription?.cancel();
    _fnoSubscription?.cancel();
    _nifty50Subscription = null;
    _fnoSubscription = null;
  }

  // Simplified filter methods
  List<DataStockModel> _filterStocks(List<DataStockModel> stocks) {
    if (searchQuery.value.isEmpty) return stocks;

    return stocks.where((stock) {
      final query = searchQuery.value.toLowerCase();
      return stock.symbol.toLowerCase().contains(query) ||
          stock.stckname.toLowerCase().contains(query);
    }).toList();
  }

  List<DataFNOModel> _filterFNOOptions(
      List<DataFNOModel> options, String underlying,
      {String? optionType}) {
    // Filter by underlying
    var filtered = options.where((option) {
      if (underlying == 'BANKNIFTY') {
        return option.isBankNifty;
      } else if (underlying == 'NIFTY') {
        return option.isNifty;
      }
      return false;
    });

    // Filter by option type if specified
    if (optionType != null) {
      filtered = filtered.where((option) => option.optionType == optionType);
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered
          .where((option) => option.symbol.toLowerCase().contains(query));
    }

    return filtered.toList();
  }

  // State management methods
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setActiveTab(int index) {
    activeTab.value = index;
  }

  void setOptionSubTab(int index) {
    optionSubTab.value = index;
  }

  // Data loading methods
  Future<void> loadAllData() async {
    try {
      isLoading(true);
      errorMessage('');

      await Future.wait([
        loadNifty50Data(),
        loadFNOData(),
      ]);

      await _setupSubscriptions();
    } catch (e) {
      errorMessage('Failed to load data: ${e.toString()}');
      print('Error loading FNO data: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadNifty50Data() async {
    try {
      final stocks = await _fnoService.fetchNifty50Stocks();
      nifty50Stocks.assignAll(stocks);
      print('Loaded ${stocks.length} Nifty 50 stocks');
    } catch (e) {
      print('Error loading Nifty 50 data: $e');
      throw e;
    }
  }

  Future<void> loadFNOData() async {
    try {
      final fnoData = await _fnoService.fetchFNOData();
      allFNOOptions.assignAll(fnoData);
      print('Loaded ${fnoData.length} FNO options');
    } catch (e) {
      print('Error loading FNO data: $e');
      throw e;
    }
  }

  // Simplified subscription setup
  Future<void> _setupSubscriptions() async {
    final _suid = FirebaseAuth.instance.currentUser?.uid.toString();
    try {
      _cancelSubscriptions();

      // Nifty 50 subscription
      _nifty50Subscription = _fnoService.subscribeToNifty50Stocks().listen(
        (stockDataList) {
          _updateStockData(stockDataList);
        },
        onError: (error) {
          print('Nifty 50 subscription error: $error');
          // ✅ Explicitly log to Crashlytics with context
          FirebaseCrashlytics.instance.recordError(
            error,
            StackTrace.current,
            reason:
                'Real-time subscription settingup error, in previous NIFTY50',
            fatal: false,
            information: ['User ID: $_suid'],
          );
        },
      );

      // FNO subscription
      _fnoSubscription = _fnoService.subscribeToFNOData().listen(
        (fnoDataList) {
          _updateFNOData(fnoDataList);
        },
        onError: (error) {
          print('FNO subscription error: $error');
          // ✅ Explicitly log to Crashlytics with context
          FirebaseCrashlytics.instance.recordError(
            error,
            StackTrace.current,
            reason: 'Real-time subscription settingup error, in previous FNO',
            fatal: false,
            information: ['User ID: $_suid'],
          );
        },
      );
    } catch (error) {
      print('Error setting up subscriptions: $error');
      // ✅ Explicitly log to Crashlytics with context
      FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Real-time subscription settingup error, in previous',
        fatal: false,
        information: ['User ID: $_suid'],
      );
    }
  }

  void _updateStockData(List<Map<String, dynamic>> stockDataList) {
    for (var stockData in stockDataList) {
      final updatedStock = DataStockModel.fromJson(stockData);
      final index =
          nifty50Stocks.indexWhere((s) => s.symbol == updatedStock.symbol);

      if (index >= 0) {
        nifty50Stocks[index] = updatedStock;
      }
    }
    nifty50Stocks.refresh();
  }

  void _updateFNOData(List<Map<String, dynamic>> fnoDataList) {
    for (var fnoData in fnoDataList) {
      final String? symbol = fnoData['symbol'];
      // print("Updating fno" + symbol.toString());
      if (symbol == null) continue;

      final index = allFNOOptions.indexWhere((o) => o.symbol == symbol);
      if (index != -1) {
        // Merge existing data with new data
        final existingOption = allFNOOptions[index];
        final mergedData = existingOption.toJson();
        mergedData.addAll(fnoData);

        allFNOOptions[index] = DataFNOModel.fromJson(mergedData);
      }
    }
    allFNOOptions.refresh();
  }

  Future<void> refreshData() async {
    try {
      isLoading(true);

      switch (activeTab.value) {
        case 0:
          await loadNifty50Data();
          break;
        case 1:
        case 2:
          await loadFNOData();
          break;
      }
    } catch (e) {
      errorMessage('Failed to refresh data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Helper methods (kept for backward compatibility)
  String getOptionType(String symbol) {
    return symbol.toUpperCase().endsWith('CE')
        ? 'Call'
        : symbol.toUpperCase().endsWith('PE')
            ? 'Put'
            : 'Unknown';
  }

  String getStrikePrice(String symbol) {
    final RegExp regex = RegExp(r'(\d+)(CE|PE)$');
    final match = regex.firstMatch(symbol.toUpperCase());
    return match?.group(1) ?? '';
  }

  String getExpiry(String symbol) {
    final RegExp regex = RegExp(r'(\d{2}[A-Z]{3})');
    final match = regex.firstMatch(symbol.toUpperCase());
    return match?.group(1) ?? '';
  }
}
