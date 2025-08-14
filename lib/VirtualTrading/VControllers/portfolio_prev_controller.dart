import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings.dart';
import 'package:optionxi/VirtualTrading/VDatabaseSupabase/db_read_supabase_prev_portfolio.dart';

class PortfolioController extends GetxController {
  final String? suid;

  PortfolioController({this.suid});

  late final String userSuid;

  final PortfolioService _portfolioService = PortfolioService();

  // --- Observables ---
  final RxBool isLoading = true.obs;
  final RxDouble availableBalance = 0.0.obs;
  final RxList<Holding> holdings = <Holding>[].obs;
  final RxList<Holding> shortPositions = <Holding>[].obs;
  final RxList<TradeHistory> tradeHistory = <TradeHistory>[].obs;

  // --- Live Data ---
  final RxMap<String, double> livePrices = <String, double>{}.obs;

  // --- Calculated Stats ---
  final RxDouble totalProfit = 0.0.obs;
  final RxDouble totalInvestment = 0.0.obs;
  final RxDouble avgInvestment = 0.0.obs;
  final RxDouble avgProfit = 0.0.obs;
  final RxInt profitableTrades = 0.obs;
  final RxInt totalTrades = 0.obs;

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

  // This should be replaced by your actual authentication logic
  // final String userSuid = FirebaseAuth.instance.currentUser!.uid.toString();
  // final String? userSuid = suid ?? FirebaseAuth.instance.currentUser?.uid;

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

  // Add this flag to track initial load
  bool _isInitialLoad = true;

  Future<void> fetchAllData() async {
    isLoading(true);
    try {
      final results = await Future.wait([
        _portfolioService.fetchBalance(userSuid),
        _portfolioService.fetchHoldings(userSuid),
        _portfolioService.fetchShortPositions(userSuid),
        _portfolioService.fetchTradeHistory(userSuid),
      ]);

      holdings.assignAll((results[1] as List<Holding>).reversed.toList());
      shortPositions.assignAll((results[2] as List<Holding>).reversed.toList());
      tradeHistory
          .assignAll((results[3] as List<TradeHistory>).reversed.toList());

      // Initialize previous counts
      _previousHoldingsCount = holdings.length;
      _previousShortsCount = shortPositions.length;
      _previousTradesCount = tradeHistory.length;

      _calculateStats();

      // Set initial load complete after first fetch
      _isInitialLoad = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load initial portfolio data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      print("Portfolio fetch error: $e");
    } finally {
      isLoading(false);
    }
  }

  void _setupSubscriptions() {
    // Cancel any existing subscriptions first
    _cancelSubscriptions();

    _balanceSubscription =
        _portfolioService.subscribeToBalance(userSuid).listen(
      (balance) {
        if (balance != availableBalance.value) {
          availableBalance.value = balance;
          print("Balance updated: $balance");
        }
      },
      onError: (e) {
        print("Balance subscription error: $e");
        _handleSubscriptionError("Balance", e);
      },
      onDone: () {
        print("Balance subscription ended");
      },
    );

    _holdingsSubscription =
        _portfolioService.subscribeToHoldings(userSuid).listen(
      (data) {
        final newCount = data.length;
        final oldCount = _previousHoldingsCount;

        holdings.assignAll(data.reversed.toList());
        _calculateStats();

        // Check for new holdings
        if (newCount > oldCount) {
          _showNewItemSnackbar("New stock position added!", "holdings");
        }

        _previousHoldingsCount = newCount;
        print("Holdings updated: ${data.length} items");
      },
      onError: (e) {
        print("Holdings subscription error: $e");
        _handleSubscriptionError("Holdings", e);
      },
      onDone: () {
        print("Holdings subscription ended");
      },
    );

    _shortsSubscription =
        _portfolioService.subscribeToShortPositions(userSuid).listen(
      (data) {
        final newCount = data.length;
        final oldCount = _previousShortsCount;

        shortPositions.assignAll(data.reversed.toList());
        _calculateStats();

        // Check for new short positions
        if (newCount > oldCount) {
          _showNewItemSnackbar("New short position added!", "shorts");
        }

        _previousShortsCount = newCount;
        print("Short positions updated: ${data.length} items");
      },
      onError: (e) {
        print("Shorts subscription error: $e");
        _handleSubscriptionError("Short Positions", e);
      },
      onDone: () {
        print("Shorts subscription ended");
      },
    );

    _historySubscription =
        _portfolioService.subscribeToTradeHistory(userSuid).listen(
      (data) {
        final newCount = data.length;
        final oldCount = _previousTradesCount;

        tradeHistory.assignAll(data.reversed.toList());
        _calculateStats();

        // Check for new trades
        if (newCount > oldCount) {
          _showNewItemSnackbar("Order executed!", "Order");
        }

        _previousTradesCount = newCount;
        print("Trade history updated: ${data.length} items");
      },
      onError: (e) {
        print("History subscription error: $e");
        _handleSubscriptionError("Trade History", e);
      },
      onDone: () {
        print("History subscription ended");
      },
    );

    _nifty50Subscription = _portfolioService.subscribeToLiveNifty50().listen(
      _updateLivePrices,
      onError: (e) {
        print("Nifty50 subscription error: $e");
        _handleSubscriptionError("Live Nifty50", e);
      },
      onDone: () {
        print("Nifty50 subscription ended");
      },
    );

    _fnoSubscription = _portfolioService.subscribeToLiveFNO().listen(
      _updateLivePrices,
      onError: (e) {
        print("FNO subscription error: $e");
        _handleSubscriptionError("Live FNO", e);
      },
      onDone: () {
        print("FNO subscription ended");
      },
    );

    print("All subscriptions set up successfully");
  }

  void _handleSubscriptionError(String subscriptionName, dynamic error) {
    // Get.snackbar(
    //   '$subscriptionName Error',
    //   'Connection lost. Trying to reconnect...',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
    //   colorText: Get.theme.colorScheme.error,
    //   duration: const Duration(seconds: 2),
    // );

    // Retry subscription after a delay
    Timer(const Duration(seconds: 3), () {
      _setupSubscriptions();
    });
  }

  void _showNewItemSnackbar(String message, String type) {
    if (!_isInitialLoad) {
      // GlobalSnackBarGet().showGetSuccessOnTop(type, message);
    }
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
      // print("Live prices updated: ${livePrices.length} symbols");
    }
  }

  void _calculateStats() {
    // --- Realised Profit from trade history ---
    double realisedPnl =
        tradeHistory.fold(0.0, (sum, item) => sum + item.profitLoss);

    // --- Unrealised Profit from holdings and short positions ---
    double unrealisedPnl = 0;
    for (var holding in holdings) {
      final ltp = getLtp(holding.symbol);
      if (ltp > 0) {
        unrealisedPnl += (ltp - holding.averagePrice) * holding.quantity;
      }
    }
    for (var short in shortPositions) {
      final ltp = getLtp(short.symbol);
      if (ltp > 0) {
        unrealisedPnl += (short.averagePrice - ltp) * short.quantity;
      }
    }

    totalProfit.value = realisedPnl + unrealisedPnl;

    // --- Combined Investment (Holdings + Trade History) ---
    double holdingInvestment = holdings.fold(
        0.0, (sum, item) => sum + (item.averagePrice * item.quantity));

    double tradeInvestment = tradeHistory.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));

    totalInvestment.value = holdingInvestment + tradeInvestment;

    int totalCount = holdings.length + tradeHistory.length;

    // --- Average Investment (per position: holding or trade) ---
    avgInvestment.value =
        totalCount > 0 ? totalInvestment.value / totalCount : 0;

    // --- Average Profit (only on realised trades) ---
    avgProfit.value =
        tradeHistory.isNotEmpty ? realisedPnl / tradeHistory.length : 0;

    // --- Accuracy: profitable trades / total trades ---
    profitableTrades.value =
        tradeHistory.where((trade) => trade.profitLoss > 0).length;
    totalTrades.value = tradeHistory.length;
    // print("Stats calculated - Total P&L: ${totalProfit.value}");
  }

  double getLtp(String symbol) {
    return livePrices[symbol] ?? 0.0;
  }

  void _cancelSubscriptions() {
    _balanceSubscription?.cancel();
    _holdingsSubscription?.cancel();
    _shortsSubscription?.cancel();
    _historySubscription?.cancel();
    _nifty50Subscription?.cancel();
    _fnoSubscription?.cancel();

    _balanceSubscription = null;
    _holdingsSubscription = null;
    _shortsSubscription = null;
    _historySubscription = null;
    _nifty50Subscription = null;
    _fnoSubscription = null;

    print("All subscriptions cancelled");
  }

  // Method to manually refresh data
  Future<void> refreshData() async {
    print("Manual refresh triggered");
    await fetchAllData();
  }

  // Method to check subscription status
  bool get isSubscriptionActive {
    return _balanceSubscription != null &&
        _holdingsSubscription != null &&
        _shortsSubscription != null &&
        _historySubscription != null;
  }

  // Method to restart subscriptions if needed
  void restartSubscriptions() {
    print("Restarting subscriptions...");
    _setupSubscriptions();
  }
}
