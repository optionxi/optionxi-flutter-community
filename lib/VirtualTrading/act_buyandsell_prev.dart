import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Helpers/lotsize_helper.dart';
import 'package:optionxi/Main_Pages/act_atlas_page.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_colorful_action_button.dart';
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

  bool _isExpanded = false;

  // State Variables
  late String _orderType;
  String _priceType = 'MKT'; // MKT, LIMIT, SL, SLM
  String _productType = 'INTRADAY'; // INTRADAY or NORMAL
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
    // Add listener to recalculate margin when quantity changes
    _qtyController.addListener(_calculateMargin);
    _initializeData();
  }

  // Fetches initial data required for the page
  // Improved _initializeData method with better error handling
  Future<void> _initializeData() async {
    try {
      // First fetch initial data
      await Future.wait([
        _checkSubscription(),
        _getUserBalance(),
        _checkShortPosition(),
        _fetchInitialStockData(),
      ]);

      // Then setup real-time listener
      _setupRealtimeData();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Clean up any partially initialized resources
      _cleanupOnError();

      if (mounted) {
        setState(() => _isLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(
        //     // SnackBar(content: Text('Failed to load data: $e')),
        //     SnackBar(
        //   content: Text(
        //     'Failed to load data',
        //   ),
        //   // SnackBar consistent with primary color
        //   behavior: SnackBarBehavior.floating,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        // ));
        _datafound = false;
      }
    }
  }

// Cleanup method for error scenarios
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

  // Checks if the user has an active subscription via Firebase
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

  // Fetches the user's trading balance from Supabase
  Future<void> _getUserBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Used id:" + user.uid.toString());
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
        // Handle error, e.g., show a snackbar
        print("Error fetching balance: $e");
      }
    }
  }

  // Checks if the user holds a short position for the current stock
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

  // Subscribes to real-time stock price updates from Supabase
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
                if (_isLoading) _isLoading = false;
              });
            }
          },
        )
        .subscribe();
  }

// Calculates the margin required for an order
  void _calculateMargin() {
    final qty = int.tryParse(_qtyController.text) ?? 0;

    int lotsize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );

    final price = _priceType == 'LIMIT'
        ? (double.tryParse(_limitController.text) ?? _currentPrice)
        : _currentPrice;

    setState(() {
      _marginRequired = price * qty * lotsize;
      if (_orderType == 'BUY') {
        _projectedBalance = _originalAvailableBalance - _marginRequired;
      } else {
        _projectedBalance = _originalAvailableBalance + _marginRequired;
      }
    });
  }

  // Calculates the profit or loss on the short position
  void _calculateShortProfitLoss() {
    if (_hasShortPosition) {
      setState(() {
        _shortProfitLoss =
            (_shortPositionAvgPrice - _currentPrice) * _shortPositionQuantity;
      });
    }
  }

  // Places the order by pushing it to Firebase
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isSubscribed && (_priceType != 'MKT' || _productType == 'NORMAL')) {
      showSubscriptionRequiredDialog(context, 'Premium Feature',
          'This feature is only available to subscribed users. Contact customer support');
      return;
    }

    // Check the indiantime, if 9:15am-3:30pm or 4pm-10:15pm, continue,
    // Else call showSubscriptionRequiredDialog
    // Get current time in IST
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
      // Handle not logged in case
      setState(() => _isPlacingOrder = false);
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref('prev_pend_order/${user.uid}');
    final newOrderRef = dbRef.push(); // Generates a unique ID

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
      // 'product_type': _productType, // Added Product Type
      'segment': widget.segment,
      'price': _priceType == 'LIMIT' || _priceType == 'SL'
          ? (double.tryParse(_limitController.text) ?? 0.0)
          : null,
      'trigger_price': _priceType == 'SL' || _priceType == 'SLM'
          ? (double.tryParse(_triggerController.text) ?? 0.0)
          : null,
      'status': 'pending',
      // 'created_at': ServerValue.timestamp, // Firebase server-side timestamp
    };

    try {
      await newOrderRef.set(orderData);
      showOrderConfiramationDialog(context, _orderType.toLowerCase());
    } catch (e) {
      // Handle error
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
    // Remove listeners first
    _qtyController.removeListener(_calculateMargin);

    // Dispose controllers
    _qtyController.dispose();
    _limitController.dispose();
    _slController.dispose();
    _triggerController.dispose();

    // Unsubscribe from Supabase channel safely
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
          isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Place Order",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        // Add chart button to app bar
        actions: [
          IconButton(
            onPressed: () => _navigateToChart(context),
            icon: Icon(
              Icons.trending_up_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: 'View Chart',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? StockTradingSkeleton(isDark: isDark)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stock info card with integrated chart and alerts buttons
                            _buildStockInfoCardWithActions(isDark),
                            if (_hasShortPosition && _orderType == 'BUY') ...[
                              const SizedBox(height: 20),
                              _buildShortPositionInfoCard(isDark),
                            ],

                            const SizedBox(height: 20),
                            _buildQuantityInput(isDark),
                            const SizedBox(height: 20),

                            _buildOrderTypeSelection(isDark),
                            const SizedBox(height: 32),
                            _buildProductTypeSelection(isDark),
                            const SizedBox(height: 32),

                            _buildPriceTypeSelection(isDark),
                            const SizedBox(height: 32),
                            // _buildBalanceCard(isDark),
                            // const SizedBox(height: 20),
                            if (_priceType != 'MKT') _buildPriceInputs(isDark),
                            // _buildStockInfoCardWithActions(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Sticky Bottom Bar
                  const SizedBox(height: 20),
                  _buildBalanceCard(isDark),
                  const SizedBox(height: 4),
                  _buildBottomBuyandSellButton(isDark),
                ],
              ),
      ),
    );
  }

// Sleek method that combines stock info with expandable details
  Widget _buildStockInfoCardWithActions(bool isDark) {
    final Color gainColor =
        isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color lossColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
    final Color changeColor = _percentChange >= 0 ? gainColor : lossColor;

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main stock info section
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top row: Stock name, icon, and price info
                  Row(
                    children: [
                      // Stock Icon
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            height: 52,
                            width: 52,
                            imageUrl: Constants.OptionXiS3Loc +
                                widget.stockname.toString() +
                                ".png",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Image.asset(
                              'assets/images/stockdefault.png',
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/stockdefault.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Stock name and segment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stockname ?? 'Unknown Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.segment ?? 'EQ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price and change
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_currentPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: changeColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _percentChange >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: changeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_percentChange.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: changeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Expand/collapse indicator
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded
                            ? 'Tap to hide details'
                            : 'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable OHLC section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isExpanded
                  ? Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E5E5),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // First row: Open and High
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOhlcItem('Open',
                                        _open.toStringAsFixed(2), isDark),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildOhlcItem('High',
                                        _high.toStringAsFixed(2), isDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Second row: Low and Previous Close
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOhlcItem(
                                        'Low', _low.toStringAsFixed(2), isDark),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildOhlcItem('Prev. Close',
                                        _prevClose.toStringAsFixed(2), isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Action buttons section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: buildModernActionButton(
                    context,
                    isDark,
                    'Chart',
                    Icons.trending_up_rounded,
                    () => _navigateToChart(context),
                    true, // isChart button
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildModernActionButton(
                    context,
                    isDark,
                    'Alerts',
                    Icons.analytics_outlined,
                    () {
                      if (widget.segment == "FNO") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AtlasOutputPage()));
                      } else {
                        Get.toNamed('/alerts/${widget.stockname}');
                      }
                    },
                    false, // isChart button
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Enhanced OHLC item builder with better styling for 2x2 grid
  Widget _buildOhlcItem(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortPositionInfoCard(bool isDark) {
    final Color pnlColor =
        _shortProfitLoss >= 0 ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Short Position',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity: $_shortPositionQuantity',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              Text(
                'Avg. Sell Price: ₹${_shortPositionAvgPrice.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Potential P/L',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${_shortProfitLoss.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: pnlColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildOhlcItem(String title, String value, bool isDark) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title,
  //           style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
  //       const SizedBox(height: 2),
  //       Text(value,
  //           style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: isDark ? Colors.white70 : Colors.black87)),
  //     ],
  //   );
  // }

  Widget _buildBalanceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Text(
            'Virtual Balance:',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            '₹${convertToKMB(_projectedBalance.toStringAsFixed(2))}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
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

  Widget _buildProductTypeSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSelectChip('INTRADAY', _productType, isDark, true, (type) {
              setState(() => _productType = type);
            }),
            const SizedBox(width: 12),
            _buildSelectChip('NORMAL', _productType, isDark, _isSubscribed,
                (type) {
              if (_isSubscribed) {
                setState(() => _productType = type);
              } else {
                showSubscriptionRequiredDialog(context, 'Premium Feature',
                    'This feature is only available to subscribed users. Contact customer support');
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton('BUY', Colors.green, isDark),
          ),
          Container(
            width: 1,
            height: 35,
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: _buildTypeButton('SELL', Colors.red, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, Color color, bool isDark) {
    final isSelected = _orderType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _orderType = type;
        _calculateMargin();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: type == 'BUY'
              ? const BorderRadius.only(
                  topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
              : const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12)),
        ),
        child: Text(
          type,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? color
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityInput(bool isDark) {
    // Calculate lot size
    int lotSize = getLotSize(
      segment: widget.segment,
      stockName: widget.stockname,
    );

    // Get current quantity
    final currentQty = int.tryParse(_qtyController.text) ?? 0;
    final totalShares = currentQty * lotSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.grey[700]!.withOpacity(0.5)
                  : Colors.grey[300]!.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              labelText: 'Quantity',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              floatingLabelStyle: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              // helperText:
              //     'Enter number of units (e.g., 1, 2)',
              // helperStyle: TextStyle(
              //   color: isDark ? Colors.grey[500] : Colors.grey[600],
              //   fontSize: 12,
              // ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[400]!.withOpacity(0.15)
                      : Colors.blue[50]!.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                  size: 20,
                ),
              ),
              hintText: 'Enter number of units (e.g., 1, 2)',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.blue[300]! : Colors.blue[500]!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.red[300]! : Colors.red[500]!,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.red[300]! : Colors.red[500]!,
                  width: 2,
                ),
              ),
              errorStyle: TextStyle(
                color: isDark ? Colors.red[300] : Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter quantity';
              final int? qty = int.tryParse(value);
              if (qty == null || qty <= 0) return 'Enter a valid quantity';
              if (_orderType == 'SELL' &&
                  _hasShortPosition &&
                  qty > _shortPositionQuantity) {
                return 'Cannot sell more than your short position';
              }
              return null;
            },
          ),
        ),

        // Add lot size info and total shares display
        if (widget.segment == "FNO") ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lot Size: $lotSize',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Total Shares: $totalShares',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Note: Enter lot quantity, not individual shares. For example, if you want ${lotSize * 5} shares, enter 5 (since 5 lots × $lotSize = ${lotSize * 5} shares).',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    // fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceTypeSelection(bool isDark) {
    final types = ['MKT', 'LIMIT', 'SL', 'SLM'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: types.map((type) {
            final isEnabled = type == 'MKT' || _isSubscribed;
            return _buildSelectChip(type, _priceType, isDark, isEnabled,
                (selectedType) {
              if (isEnabled) {
                setState(() => _priceType = selectedType);
              } else {
                showSubscriptionRequiredDialog(context, 'Premium Feature',
                    'This feature is only available to subscribed users. Contact customer support');
              }
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectChip(String type, String currentSelection, bool isDark,
      bool isEnabled, Function(String) onTap) {
    final isSelected = currentSelection == type;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue.shade700 : Colors.blue.shade600)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.blue.shade600 : Colors.blue.shade500)
                  : (isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isEnabled
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInputs(bool isDark) {
    return Column(
      children: [
        if (_priceType == 'LIMIT' || _priceType == 'SL')
          TextFormField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
                labelText: _priceType == 'LIMIT' ? 'Limit Price' : 'Price',
                prefixIcon: Icons.price_change_outlined,
                isDark: isDark),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Price is required' : null,
          ),
        if (_priceType == 'SL' || _priceType == 'SLM') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _triggerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
                labelText: 'Trigger Price',
                prefixIcon: Icons.touch_app_outlined,
                isDark: isDark),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Trigger price is required' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBuyandSellButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? const Color(0xFF2E2E2E)
                    : const Color(0xFFE0E0E0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _buildMarginInfo(isDark),
          const SizedBox(height: 16),
          _buildPlaceOrderButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMarginInfo(bool isDark) {
    final label = _orderType == 'BUY' ? 'Margin Required' : 'Order Value';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          // '₹${convertToKMB(_marginRequired.toStringAsFixed(2))}',
          '₹${_marginRequired.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isPlacingOrder
            ? null
            : _datafound
                ? _placeOrder
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _orderType == 'BUY' ? Colors.green.shade600 : Colors.red.shade600,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Text(
                _datafound ? '${_orderType.toUpperCase()}' : "No Data Found",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // Helper for consistent InputDecoration
  InputDecoration _inputDecoration(
      {required String labelText,
      required IconData prefixIcon,
      required bool isDark}) {
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0);
    final focusedColor = isDark ? Colors.blue[400]! : Colors.blue[600]!;

    return InputDecoration(
      labelText: labelText,
      prefixIcon:
          Icon(prefixIcon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 1.5),
      ),
      labelStyle:
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
    );
  }
}
