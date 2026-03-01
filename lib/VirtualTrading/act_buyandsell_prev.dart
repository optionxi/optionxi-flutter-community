import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Helpers/lotsize_helper.dart';
import 'package:optionxi/VirtualTrading/VDialogs/order_placed_dialog.dart';
import 'package:optionxi/VirtualTrading/VDialogs/subscription_required_dialog.dart';
import 'package:optionxi/VirtualTrading/buyandsell_prev_loading.dart';
import 'package:optionxi/browser_lite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

class BuyandSellPagePrev extends StatefulWidget {
  final String? stockname;
  final String? segment;
  final bool tosell;

  const BuyandSellPagePrev(this.stockname, this.segment, this.tosell,
      {Key? key})
      : super(key: key);

  @override
  _BuyandSellPagePrevState createState() => _BuyandSellPagePrevState();
}

class _BuyandSellPagePrevState extends State<BuyandSellPagePrev> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _limitController = TextEditingController();
  final _slController = TextEditingController();
  final _triggerController = TextEditingController();

  bool _isPriceRangeExpanded = false;
  bool _isExpanded = false;

  // State Variables
  late String _orderType;
  String _priceType = 'MKT';
  String _productType = 'INTRADAY';
  bool _isSubscribed = false;
  bool _isLoading = true;
  bool _datafound = true;
  bool _isPlacingOrder = false;

  // Financial Data
  double _originalAvailableBalance = Constants.INITAL_BAL_PREV;
  double _projectedBalance = Constants.INITAL_BAL_PREV;
  double _marginRequired = 0.0;
  bool _hasShortPosition = false;
  int _shortPositionQuantity = 0;
  double _shortPositionAvgPrice = 0.0;
  double _shortProfitLoss = 0.0;

  bool _hasHolding = false;
  int _holdingQuantity = 0;
  double _holdingAvgPrice = 0.0;
  double _holdingProfitLoss = 0.0;

  // Real-time Stock Data
  double _currentPrice = 0.0;
  double _open = 0.0;
  double _high = 0.0;
  double _low = 0.0;
  double _prevClose = 0.0;
  double _percentChange = 0.0;

  // Backend References
  late RealtimeChannel _supabaseChannel;

  @override
  void initState() {
    super.initState();
    _orderType = widget.tosell ? 'SELL' : 'BUY';
    _qtyController.text = '1'; // Set default quantity to 1
    _qtyController.addListener(_calculateMargin);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _checkSubscription(),
        _getUserBalance(),
        _checkShortPosition(),
        _checkHolding(),
        _fetchInitialStockData(),
      ]);

      _setupRealtimeData();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _cleanupOnError();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _datafound = false;
        });
      }
    }
  }

  void _cleanupOnError() {
    try {
      _supabaseChannel.unsubscribe();
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  Future<void> _fetchInitialStockData() async {
    final tableName = widget.segment == 'EQ'
        ? 'prev_nifty50_stocks'
        : 'prev_fno_bankandnifty';

    final response = await Supabase.instance.client
        .from(tableName)
        .select()
        .eq('symbol', widget.stockname!)
        .single();

    if (mounted) {
      setState(() {
        _currentPrice = (response['ltp'] ?? 0.0).toDouble();
        _open = (response['o'] ?? 0.0).toDouble();
        _high = (response['h'] ?? 0.0).toDouble();
        _low = (response['l'] ?? 0.0).toDouble();
        _prevClose = (response['pc'] ?? 0.0).toDouble();
        _percentChange = (response['pcnt'] ?? 0.0).toDouble();
      });
    }
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref('subscribed/${user.uid}');
      final snapshot = await ref.get();
      if (mounted) {
        setState(() {
          _isSubscribed = snapshot.exists;
        });
      }
    }
  }

  Future<void> _getUserBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('prev_balance')
            .select('balance')
            .eq('suid', user.uid)
            .single();
        if (mounted) {
          setState(() {
            _originalAvailableBalance = (response['balance'] ?? 0.0).toDouble();
            _projectedBalance = _originalAvailableBalance;
          });
        }
      } catch (e) {
        print("Error fetching balance: $e");
      }
    }
  }

  Future<void> _checkShortPosition() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.stockname != null) {
      final response = await Supabase.instance.client
          .from('prev_short_positions')
          .select('quantity, average_price')
          .eq('suid', user.uid)
          .eq('symbol', widget.stockname!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _hasShortPosition = response != null;
          if (_hasShortPosition && response != null) {
            _shortPositionQuantity = (response['quantity'] ?? 0) as int;
            _shortPositionAvgPrice =
                (response['average_price'] ?? 0).toDouble();
          } else {
            _shortPositionQuantity = 0;
            _shortPositionAvgPrice = 0.0;
          }
        });
      }
    }
  }

  Future<void> _checkHolding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.stockname != null) {
      final response = await Supabase.instance.client
          .from('prev_user_holdings')
          .select('quantity, average_price')
          .eq('suid', user.uid)
          .eq('symbol', widget.stockname!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _hasHolding = response != null;
          if (_hasHolding && response != null) {
            _holdingQuantity = (response['quantity'] ?? 0) as int;
            _holdingAvgPrice = (response['average_price'] ?? 0).toDouble();
          } else {
            _holdingQuantity = 0;
            _holdingAvgPrice = 0.0;
          }
        });
      }
    }
  }

  void _setupRealtimeData() {
    final tableName = widget.segment == 'EQ'
        ? 'prev_nifty50_stocks'
        : 'prev_fno_bankandnifty';

    _supabaseChannel =
        Supabase.instance.client.channel('stock_${widget.stockname}');
    _supabaseChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'symbol',
            value: widget.stockname,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (mounted) {
              setState(() {
                _currentPrice = (record['ltp'] ?? 0.0).toDouble();
                _open = (record['o'] ?? 0.0).toDouble();
                _high = (record['h'] ?? 0.0).toDouble();
                _low = (record['l'] ?? 0.0).toDouble();
                _prevClose = (record['pc'] ?? 0.0).toDouble();
                _percentChange = (record['pcnt'] ?? 0.0).toDouble();
                _calculateMargin();
                _calculateShortProfitLoss();
                _calculateHoldingProfitLoss();
                if (_isLoading) _isLoading = false;
              });
            }
          },
        )
        .subscribe();
  }

  void _calculateMargin() {
    final qty = int.tryParse(_qtyController.text) ?? 0;

    int lotsize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );

    final price = _priceType == 'LIMIT'
        ? (double.tryParse(_limitController.text) ?? _currentPrice)
        : _currentPrice;

    final totalQty = qty * lotsize;

    setState(() {
      if (_orderType == 'SELL') {
        if (_hasHolding) {
          if (totalQty <= _holdingQuantity) {
            _marginRequired = 0.0;
            final holdingValue = _holdingAvgPrice * totalQty;
            final sellValue = price * totalQty;
            final profitLoss = sellValue - holdingValue;
            _projectedBalance =
                _originalAvailableBalance + profitLoss + sellValue;
          } else {
            final sellingFromHoldingsQty = _holdingQuantity;
            final newShortQty = totalQty - sellingFromHoldingsQty;

            final holdingValue = _holdingAvgPrice * sellingFromHoldingsQty;
            final sellValueForHoldings = price * sellingFromHoldingsQty;
            final profitLoss = sellValueForHoldings - holdingValue;

            _marginRequired = price * newShortQty;
            _projectedBalance =
                _originalAvailableBalance + profitLoss - _marginRequired;
          }
        } else {
          _marginRequired = price * totalQty;
          _projectedBalance = _originalAvailableBalance - _marginRequired;
        }
      } else {
        if (_hasShortPosition) {
          if (totalQty <= _shortPositionQuantity) {
            _marginRequired = 0.0;
            final shortValue = _shortPositionAvgPrice * totalQty;
            final buyValue = price * totalQty;
            final profitLoss = shortValue - buyValue;
            _projectedBalance =
                _originalAvailableBalance + profitLoss + shortValue;
          } else {
            final coveringQty = _shortPositionQuantity;
            final newBuyQty = totalQty - coveringQty;

            final shortValue = _shortPositionAvgPrice * coveringQty;
            final buyValueForShort = price * coveringQty;
            final profitLoss = shortValue - buyValueForShort;

            _marginRequired = price * newBuyQty;
            _projectedBalance = _originalAvailableBalance +
                profitLoss -
                _marginRequired +
                shortValue;
          }
        } else {
          _marginRequired = price * totalQty;
          _projectedBalance = _originalAvailableBalance - _marginRequired;
        }
      }
    });
  }

  void _calculateShortProfitLoss() {
    if (_hasShortPosition) {
      setState(() {
        _shortProfitLoss =
            (_shortPositionAvgPrice - _currentPrice) * _shortPositionQuantity;
      });
    }
  }

  void _calculateHoldingProfitLoss() {
    if (_hasHolding) {
      setState(() {
        _holdingProfitLoss =
            (_currentPrice - _holdingAvgPrice) * _holdingQuantity;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isSubscribed && (_priceType != 'MKT' || _productType == 'NORMAL')) {
      showSubscriptionRequiredDialog(context, 'Premium Feature',
          'This feature is only available to subscribed users. Contact customer support');
      return;
    }

    final ist = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.now(ist);

    final morningStart =
        tz.TZDateTime(ist, now.year, now.month, now.day, 9, 15);
    final afternoonEnd =
        tz.TZDateTime(ist, now.year, now.month, now.day, 15, 30);
    final eveningStart =
        tz.TZDateTime(ist, now.year, now.month, now.day, 16, 0);
    final nightEnd = tz.TZDateTime(ist, now.year, now.month, now.day, 22, 15);

    final isMarketHours =
        (now.isAfter(morningStart) && now.isBefore(afternoonEnd)) ||
            (now.isAfter(eveningStart) && now.compareTo(nightEnd) <= 0);

    if (!isMarketHours) {
      showSubscriptionRequiredDialog(context, 'Market Hours',
          'Place orders only on market hours, 9:15 AM-3:30 PM or after market 4:00 PM-10:15 PM');
      return;
    }

    setState(() => _isPlacingOrder = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isPlacingOrder = false);
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref('prev_pend_order/${user.uid}');
    final newOrderRef = dbRef.push();

    int lotsize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );

    final orderData = {
      'id': newOrderRef.key,
      'suid': user.uid,
      'symbol': widget.stockname,
      'quantity': (int.tryParse(_qtyController.text) ?? 0) * lotsize,
      'order_type': _priceType,
      'transaction_type': _orderType,
      'segment': widget.segment,
      'price': _priceType == 'LIMIT' || _priceType == 'SL'
          ? (double.tryParse(_limitController.text) ?? 0.0)
          : null,
      'trigger_price': _priceType == 'SL' || _priceType == 'SLM'
          ? (double.tryParse(_triggerController.text) ?? 0.0)
          : null,
      'status': 'pending',
    };

    try {
      await newOrderRef.set(orderData);
      showOrderConfiramationDialog(context, _orderType.toLowerCase());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  void dispose() {
    _qtyController.removeListener(_calculateMargin);
    _qtyController.dispose();
    _limitController.dispose();
    _slController.dispose();
    _triggerController.dispose();

    try {
      _supabaseChannel.unsubscribe();
    } catch (e) {
      print('Error unsubscribing from Supabase channel: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: _isLoading
            ? StockTradingSkeleton(isDark: isDark)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStockHeader(isDark),

                            if (_hasShortPosition && _orderType == 'BUY')
                              _buildPositionCard(
                                isDark: isDark,
                                title: 'Short Position',
                                quantity: _shortPositionQuantity,
                                avgPrice: _shortPositionAvgPrice,
                                profitLoss: _shortProfitLoss,
                                isShort: true,
                              ),

                            if (_hasHolding && _orderType == 'SELL')
                              _buildPositionCard(
                                isDark: isDark,
                                title: 'Holdings',
                                quantity: _holdingQuantity,
                                avgPrice: _holdingAvgPrice,
                                profitLoss: _holdingProfitLoss,
                                isShort: false,
                              ),

                            // Group all inputs in a single uniform padding wrapper
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOrderTypeSelector(isDark),
                                  const SizedBox(height: 24),

                                  // Removed the extra inner Padding here
                                  _buildQuantityInput(isDark),
                                  const SizedBox(height: 24),

                                  // Moved Price Selectors inside the same padded block
                                  _buildPriceTypeSelector(isDark),

                                  if (_priceType != 'MKT') ...[
                                    const SizedBox(height: 24),
                                    _buildPriceInputs(isDark),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomSection(isDark),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Place Order',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _navigateToChart(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.candlestick_chart_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStockHeader(bool isDark) {
    final isPositive = _percentChange >= 0;
    final changeColor = isPositive
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626));

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: Name + Price ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.stockname ?? 'Stock',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${_currentPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // ── Row 2: Segment chip + Change badge + Chevron ────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.segment ?? 'EQ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 14,
                        color: changeColor,
                      ),
                      Text(
                        '${_percentChange.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
              ],
            ),

            // ── Expandable price range ──────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              firstCurve: Curves.easeIn,
              secondCurve: Curves.easeOut,
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                  const SizedBox(height: 14),
                  _buildPriceRangeBar(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeBar(bool isDark) {
    final range = (_high - _low).abs();
    final position = range > 0 ? (_currentPrice - _low) / range : 0.5;
    final clampedPosition = position.clamp(0.0, 1.0);

    Color rangeColor;
    String statusText;

    if (clampedPosition >= 0.8) {
      rangeColor = const Color(0xFF4ADE80);
      statusText = 'Near High';
    } else if (clampedPosition <= 0.2) {
      rangeColor = const Color(0xFFF87171);
      statusText = 'Near Low';
    } else {
      rangeColor = const Color(0xFF60A5FA);
      statusText = 'Mid Range';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isPriceRangeExpanded = !_isPriceRangeExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: rangeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rangeColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Always visible: compact view
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LTP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: rangeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rangeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isPriceRangeExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar - always visible
            SizedBox(
              height: 6,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: rangeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: clampedPosition,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: rangeColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(clampedPosition * 2 - 1, 0),
                    child: Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: rangeColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: rangeColor.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Low and High - always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${_low.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                Text(
                  '₹${_high.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
            // Expandable section - additional details
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: rangeColor.withOpacity(0.15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriceDetail('Open', _open, isDark),
                      Container(
                        width: 1,
                        height: 30,
                        color: rangeColor.withOpacity(0.15),
                      ),
                      _buildPriceDetail('Prev Close', _prevClose, isDark),
                    ],
                  ),
                ],
              ),
              crossFadeState: _isPriceRangeExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail(String label, double value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCard({
    required bool isDark,
    required String title,
    required int quantity,
    required double avgPrice,
    required double profitLoss,
    required bool isShort,
  }) {
    final pnlColor = profitLoss >= 0
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isShort
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: pnlColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Quantity',
                  quantity.toString(),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Avg Price',
                  '₹${avgPrice.toStringAsFixed(2)}',
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pnlColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'P&L',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '₹${profitLoss.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: pnlColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelector(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          _buildOrderButton(
              'BUY', const Color(0xFF10B981), isDark), // Emerald green
          Container(
            width: 1,
            height: 32,
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          _buildOrderButton(
              'SELL', const Color(0xFFEF4444), isDark), // Bright red
        ],
      ),
    );
  }

  Widget _buildOrderButton(String type, Color activeColor, bool isDark) {
    final isSelected = _orderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _orderType = type;
          _calculateMargin();
        }),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            type,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white38 : Colors.black38),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityInput(bool isDark) {
    int lotSize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );

    final currentQty = int.tryParse(_qtyController.text) ?? 0;
    final totalShares = currentQty * lotSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              _buildQtyButton(
                Icons.remove_rounded,
                () {
                  int current = int.tryParse(_qtyController.text) ?? 0;
                  if (current > 1) {
                    _qtyController.text = (current - 1).toString();
                  }
                },
                isDark,
              ),
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.segment == 'FNO' ? 'Lots' : 'Qty',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter quantity';
                    final int? qty = int.tryParse(value);
                    if (qty == null || qty <= 0) return 'Invalid quantity';
                    return null;
                  },
                ),
              ),
              _buildQtyButton(
                Icons.add_rounded,
                () {
                  int current = int.tryParse(_qtyController.text) ?? 0;
                  _qtyController.text = (current + 1).toString();
                },
                isDark,
              ),
            ],
          ),
        ),
        if (widget.segment == "FNO" && currentQty > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF60A5FA).withOpacity(0.08)
                  : const Color(0xFF60A5FA).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF60A5FA).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentQty lots × $lotSize',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '$totalShares shares',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPriceTypeSelector(bool isDark) {
    final types = ['MKT', 'LIMIT', 'SL', 'SLM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((type) {
            final isSelected = _priceType == type;
            final isEnabled = type == 'MKT' || _isSubscribed;

            return GestureDetector(
              onTap: () {
                if (isEnabled) {
                  setState(() => _priceType = type);
                } else {
                  showSubscriptionRequiredDialog(
                    context,
                    'Premium Feature',
                    'This feature is only available to subscribed users. Contact customer support',
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A))
                      : (isDark ? const Color(0xFF111111) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isEnabled
                                ? (isDark ? Colors.white70 : Colors.black54)
                                : (isDark ? Colors.white24 : Colors.black26)),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceInputs(bool isDark) {
    return Column(
      children: [
        if (_priceType == 'LIMIT' || _priceType == 'SL') ...[
          _buildInputField(
            controller: _limitController,
            label: _priceType == 'LIMIT' ? 'Limit Price' : 'Price',
            icon: Icons.currency_rupee_rounded,
            isDark: isDark,
          ),
        ],
        if (_priceType == 'SL' || _priceType == 'SLM') ...[
          const SizedBox(height: 16),
          _buildInputField(
            controller: _triggerController,
            label: 'Trigger Price',
            icon: Icons.notifications_active_rounded,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Enter price',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool isDark) {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    int lotsize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );
    final totalQty = qty * lotsize;

    String marginLabel;
    if (_orderType == 'SELL' && _hasHolding && totalQty <= _holdingQuantity) {
      marginLabel = 'Selling from Holdings';
    } else if (_orderType == 'SELL' &&
        _hasHolding &&
        totalQty > _holdingQuantity) {
      marginLabel = 'Net Margin';
    } else if (_orderType == 'BUY' &&
        _hasShortPosition &&
        totalQty <= _shortPositionQuantity) {
      marginLabel = 'Buyback Value';
    } else if (_orderType == 'BUY' &&
        _hasShortPosition &&
        totalQty > _shortPositionQuantity) {
      marginLabel = 'Net Margin';
    } else if (_orderType == 'BUY') {
      marginLabel = 'Margin Required';
    } else {
      marginLabel = 'Short Value';
    }

    final balanceChange = _projectedBalance - _originalAvailableBalance;
    final isProfit = balanceChange > 0;
    final goesNegative = _projectedBalance < 0;

    Color balanceColor;
    if (goesNegative) {
      balanceColor = const Color(0xFFF87171);
    } else if (isProfit) {
      balanceColor = const Color(0xFF4ADE80);
    } else {
      balanceColor = isDark ? Colors.white70 : Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${convertToKMB(_originalAvailableBalance.toStringAsFixed(2))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'After Order',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${convertToKMB(_projectedBalance.toStringAsFixed(2))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  marginLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '₹${_marginRequired.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPlacingOrder
                  ? null
                  : _datafound
                      ? _placeOrder
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orderType == 'BUY'
                    ? const Color(0xFF10B981) // Emerald green
                    : const Color(0xFFEF4444), // Bright red
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _datafound ? _orderType : 'No Data Found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChart(BuildContext context) {
    final String chartUrl = _getChartUrl();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserLite_V(chartUrl),
      ),
    );
  }

  String _getChartUrl() {
    if (widget.segment == "FNO") {
      return widget.stockname.toString().startsWith("BANK")
          ? "https://in.tradingview.com/chart/?symbol=BANKNIFTY"
          : "https://in.tradingview.com/chart/?symbol=NIFTY";
    }
    return "https://in.tradingview.com/chart/?symbol=NSE%3A${widget.stockname}";
  }
}
