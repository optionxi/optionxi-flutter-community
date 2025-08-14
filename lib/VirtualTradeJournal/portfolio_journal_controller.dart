import 'dart:async'; // Added import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:optionxi/VirtualTradeJournal/db_read_supabase_journal_portfolio.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings_journal.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';

class PortfolioJournalController extends GetxController {
  final String? suid;

  PortfolioJournalController({this.suid});

  late final String userSuid;

  final PortfolioJournalService _portfolioService = PortfolioJournalService();

  // --- Observables for UI State ---
  final RxBool isLoading = true.obs;
  final RxDouble availableBalance = 0.0.obs;

  // --- Observables for Data Lists ---
  final RxList<BasketUserHolding> holdings = <BasketUserHolding>[].obs;
  final RxList<BasketUserHolding> shortPositions = <BasketUserHolding>[].obs;
  final RxList<JournalTradeHistory> tradeHistory = <JournalTradeHistory>[].obs;

  // --- Live Data ---
  final RxMap<String, double> livePrices = <String, double>{}.obs;

  // --- UPDATED: Observables for Detailed Stats ---
  final RxDouble totalProfit = 0.0.obs; // Overall P&L (Realised + Unrealised)
  final RxDouble totalInvestment =
      0.0.obs; // Current investment in open positions
  final RxDouble realisedPnl = 0.0.obs;
  final RxDouble unrealisedPnl = 0.0.obs;
  final RxInt totalWins = 0.obs; // Renamed from profitableTrades
  final RxInt totalLosses = 0.obs;
  final RxInt totalTrades = 0.obs; // Total closed trades

  // --- Previous counts for detecting new items ---
  int _previousHoldingsCount = 0;
  int _previousShortsCount = 0;
  int _previousTradesCount = 0;

  // --- Subscriptions ---
  StreamSubscription? _balanceSubscription;
  StreamSubscription? _holdingsSubscription;
  StreamSubscription? _shortsSubscription;
  StreamSubscription? _historySubscription;
  StreamSubscription? _nifty50Subscription;
  StreamSubscription? _fnoSubscription;

  @override
  void onInit() {
    super.onInit();
    userSuid = suid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    fetchAllData();
    _setupSubscriptions();
  }

  @override
  void onClose() {
    _cancelSubscriptions();
    super.onClose();
  }

  Future<void> fetchAllData() async {
    isLoading(true);
    try {
      final results = await Future.wait([
        _portfolioService.fetchBalance(userSuid),
        _portfolioService.fetchHoldings(userSuid),
        _portfolioService.fetchShortPositions(userSuid),
        _portfolioService.fetchTradeHistory(userSuid),
      ]);

      // Assign data from futures
      availableBalance.value = results[0] as double;
      holdings
          .assignAll((results[1] as List<BasketUserHolding>).reversed.toList());
      shortPositions
          .assignAll((results[2] as List<BasketUserHolding>).reversed.toList());
      tradeHistory.assignAll(
          (results[3] as List<JournalTradeHistory>).reversed.toList());

      // Initialize previous counts to prevent snackbars on first load
      _previousHoldingsCount = holdings.length;
      _previousShortsCount = shortPositions.length;
      _previousTradesCount = tradeHistory.length;

      _calculateStats();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load portfolio data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Portfolio fetch error: $e");
    } finally {
      isLoading(false);
    }
  }

  void _setupSubscriptions() {
    _cancelSubscriptions();

    _balanceSubscription =
        _portfolioService.subscribeToBalance(userSuid).listen(
      (balance) {
        if (balance != availableBalance.value) {
          availableBalance.value = balance;
        }
      },
      onError: (e) => _handleSubscriptionError("Balance", e),
    );

    _holdingsSubscription =
        _portfolioService.subscribeToHoldings(userSuid).listen(
      (data) {
        holdings.assignAll(data.reversed.toList());
        _calculateStats();
        if (data.length > _previousHoldingsCount) {
          _showNewItemSnackbar("New holding added!");
        }
        _previousHoldingsCount = data.length;
      },
      onError: (e) => _handleSubscriptionError("Holdings", e),
    );

    _shortsSubscription =
        _portfolioService.subscribeToShortPositions(userSuid).listen(
      (data) {
        shortPositions.assignAll(data.reversed.toList());
        _calculateStats();
        if (data.length > _previousShortsCount) {
          _showNewItemSnackbar("New short position added!");
        }
        _previousShortsCount = data.length;
      },
      onError: (e) => _handleSubscriptionError("Short Positions", e),
    );

    _historySubscription =
        _portfolioService.subscribeToTradeHistory(userSuid).listen(
      (data) {
        tradeHistory.assignAll(data.reversed.toList());
        _calculateStats();
        if (data.length > _previousTradesCount) {
          _showNewItemSnackbar("Trade Journal Added!");
        }
        _previousTradesCount = data.length;
      },
      onError: (e) => _handleSubscriptionError("Trade History", e),
    );

    _nifty50Subscription = _portfolioService.subscribeToLiveNifty50().listen(
          _updateLivePrices,
          onError: (e) => _handleSubscriptionError("Live Nifty50", e),
        );

    _fnoSubscription = _portfolioService.subscribeToLiveFNO().listen(
          _updateLivePrices,
          onError: (e) => _handleSubscriptionError("Live FNO", e),
        );
  }

  void _handleSubscriptionError(String name, dynamic error) {
    print("$name subscription error: $error");
    // Optional: Add logic to attempt reconnection after a delay
    Timer(const Duration(seconds: 5), () {
      print("Attempting to restart subscriptions...");
      _setupSubscriptions();
    });
  }

  void _showNewItemSnackbar(String message) {
    // if (!_isInitialLoad) {
    //   Get.snackbar(
    //     'Portfolio Update',
    //     message,
    //     snackPosition: SnackPosition.TOP,
    //     duration: const Duration(seconds: 2),
    //   );
    // }
  }

  void _updateLivePrices(List<Map<String, dynamic>> data) {
    bool pricesUpdated = false;
    for (var stock in data) {
      final symbol = stock['symbol'];
      if (symbol is String) {
        final ltp = (stock['ltp'] as num?)?.toDouble() ??
            (stock['close'] as num?)?.toDouble();
        if (ltp != null && ltp != livePrices[symbol]) {
          livePrices[symbol] = ltp;
          pricesUpdated = true;
        }
      }
    }
    if (pricesUpdated) {
      livePrices.refresh();
      _calculateStats();
    }
  }

  // ### UPDATED: Refactored statistics calculation logic ###
  void _calculateStats() {
    // --- 1. Realised P&L (from closed trades) ---
    realisedPnl.value =
        tradeHistory.fold(0.0, (sum, item) => sum + item.profitLoss);

    // --- 2. Unrealised P&L (from open positions) ---
    double currentUnrealisedPnl = 0.0;
    for (var holding in holdings) {
      final ltp = getLtp(holding.symbol);
      currentUnrealisedPnl += (ltp - holding.averagePrice) * holding.quantity;
    }
    for (var short in shortPositions) {
      final ltp = getLtp(short.symbol);
      currentUnrealisedPnl += (short.averagePrice - ltp) * short.quantity;
    }
    unrealisedPnl.value = currentUnrealisedPnl;

    // --- 3. Total P&L (Realised + Unrealised) ---
    totalProfit.value = realisedPnl.value + unrealisedPnl.value;

    // --- 4. Total Investment (Value of current open positions) ---
    double currentInvestment = 0.0;
    currentInvestment += holdings.fold(
        0.0, (sum, item) => sum + (item.averagePrice * item.quantity));
    currentInvestment += shortPositions.fold(
        0.0, (sum, item) => sum + (item.averagePrice * item.quantity));
    totalInvestment.value = currentInvestment;

    // --- 5. Win/Loss Stats (from closed trades) ---
    totalTrades.value = tradeHistory.length;
    totalWins.value =
        tradeHistory.where((trade) => trade.profitLoss > 0).length;
    totalLosses.value =
        tradeHistory.where((trade) => trade.profitLoss < 0).length;
  }

  double getLtp(String symbol) {
    // Return live price if available, otherwise 0.
    return livePrices[symbol] ?? 0.0;
  }

  void _cancelSubscriptions() {
    _balanceSubscription?.cancel();
    _holdingsSubscription?.cancel();
    _shortsSubscription?.cancel();
    _historySubscription?.cancel();
    _nifty50Subscription?.cancel();
    _fnoSubscription?.cancel();
  }

  Future<void> refreshData() async {
    print("Manual refresh triggered");
    await fetchAllData();
  }
}
