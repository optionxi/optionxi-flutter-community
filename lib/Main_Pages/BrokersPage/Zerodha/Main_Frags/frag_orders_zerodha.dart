import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/act_buy_sell_live_zerodha.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/error_state.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/zerodha_order_edit.dart';

// ─────────────────────────────────────────────────────────────
//  Orders Page — Zerodha
//  Changes from original:
//    • Added FAB to place a new order via ZerodhaOrderPage
//    • Pending order cards are tappable → ZerodhaOrderEditPage
//    • After edit/cancel, list auto-refreshes
// ─────────────────────────────────────────────────────────────
class OrdersPageZerodha extends StatefulWidget {
  const OrdersPageZerodha({Key? key}) : super(key: key);

  @override
  State<OrdersPageZerodha> createState() => _OrdersPageZerodhaState();
}

class _OrdersPageZerodhaState extends State<OrdersPageZerodha>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ZerodhaRepository _repository = ZerodhaRepository();

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  dynamic _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orders = await _repository.getOrders();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e;
          _isLoading = false;
        });
      }
    }
  }

  List<OrderModel> get _completedOrders =>
      _allOrders.where((o) => o.status == 'COMPLETE').toList();

  List<OrderModel> get _pendingOrders => _allOrders
      .where((o) => o.status == 'OPEN' || o.status == 'TRIGGER PENDING')
      .toList();

  List<OrderModel> get _cancelledOrders => _allOrders
      .where((o) => o.status == 'CANCELLED' || o.status == 'REJECTED')
      .toList();

  // ── Navigation ─────────────────────────────────────────────

  /// Opens ZerodhaOrderEditPage for a pending order.
  /// Refreshes the list if the order was modified or cancelled.
  Future<void> _openEditPage(OrderModel order) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ZerodhaOrderEditPage(order: order),
      ),
    );
    // result == true (modified) or 'cancelled'
    if (result != null) _loadOrders();
  }

  /// Opens ZerodhaOrderPage (blank new order).
  Future<void> _openNewOrderPage() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => const ZerodhaOrderPage(),
      ),
    );
    if (result != null) _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      // ── FAB: place a new order ──────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewOrderPage,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New Order',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // ── Tab bar ─────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              indicatorColor: const Color(0xFF6366F1),
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              tabs: [
                Tab(text: 'Success (${_completedOrders.length})'),
                Tab(text: 'Pending (${_pendingOrders.length})'),
                Tab(text: 'Cancelled (${_cancelledOrders.length})'),
              ],
            ),
          ),
          // ── Content ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : _errorMessage != null
                    ? buildErrorStateBroker(_loadOrders, _errorMessage, context)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrdersList(_completedOrders, 'success',
                              tappable: false),
                          _buildOrdersList(_pendingOrders, 'pending',
                              tappable: true), // ← pending are editable
                          _buildOrdersList(_cancelledOrders, 'cancelled',
                              tappable: false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton ────────────────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _shimBox(80, 16, isDark),
            const Spacer(),
            _shimBox(60, 16, isDark),
          ]),
          const SizedBox(height: 12),
          _shimBox(double.infinity, 14, isDark),
          const SizedBox(height: 8),
          Row(children: [
            _shimBox(100, 12, isDark),
            const Spacer(),
            _shimBox(80, 12, isDark),
          ]),
        ],
      ),
    );
  }

  Widget _shimBox(double w, double h, bool isDark) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );

  // ── List ────────────────────────────────────────────────────
  Widget _buildOrdersList(List<OrderModel> orders, String type,
      {required bool tappable}) {
    if (orders.isEmpty) return _buildEmptyState(type);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // extra for FAB
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildOrderCard(
        orders[i],
        type,
        tappable: tappable,
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = {
      'success': (
        'No completed orders',
        'Your successful orders will appear here',
        Icons.check_circle_outline,
      ),
      'pending': (
        'No pending orders',
        'Tap + New Order to place one',
        Icons.schedule,
      ),
      'cancelled': (
        'No cancelled orders',
        'Your cancelled orders will appear here',
        Icons.cancel_outlined,
      ),
    }[type]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.$3,
                size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(data.$1,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 8),
            Text(data.$2,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // ── Order card ──────────────────────────────────────────────
  Widget _buildOrderCard(OrderModel order, String type,
      {required bool tappable}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    Color statusBgColor;
    switch (type) {
      case 'success':
        statusColor = Colors.green[600]!;
        statusBgColor =
            isDark ? Colors.green[900]!.withOpacity(0.2) : Colors.green[50]!;
        break;
      case 'pending':
        statusColor = Colors.orange[600]!;
        statusBgColor =
            isDark ? Colors.orange[900]!.withOpacity(0.2) : Colors.orange[50]!;
        break;
      default:
        statusColor = Colors.red[600]!;
        statusBgColor =
            isDark ? Colors.red[900]!.withOpacity(0.2) : Colors.red[50]!;
    }

    final DateTime orderTime = DateTime.parse(order.orderTimestamp);
    final String formattedTime =
        DateFormat('MMM dd, yyyy HH:mm').format(orderTime);

    // Pending cards get a subtle edit affordance
    final isPending = tappable;

    return GestureDetector(
      onTap: isPending ? () => _openEditPage(order) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? const Color(0xFF6366F1).withOpacity(0.25)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: symbol + status + edit icon ──────────
              Row(
                children: [
                  Expanded(
                    child: Text(order.tradingSymbol,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(order.status,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ),
                  // ── Edit affordance for pending ─────────────
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 14, color: Color(0xFF6366F1)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ── Row 2: BUY/SELL + qty + exchange ────────────
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.transactionType == 'BUY'
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(order.transactionType,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: order.transactionType == 'BUY'
                                ? Colors.green[700]
                                : Colors.red[700])),
                  ),
                  const SizedBox(width: 8),
                  Text('${order.quantity} qty',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  const Spacer(),
                  Text(order.exchange,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),

              // ── Row 3: price + avg + time ────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price: ₹${order.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                        if (order.averagePrice > 0)
                          Text(
                            'Avg: ₹${order.averagePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                  Text(formattedTime,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500])),
                ],
              ),

              // ── Status message (e.g. rejection reason) ───────
              if (order.statusMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(order.statusMessage!,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ),
              ],

              // ── Tap hint for pending ─────────────────────────
              if (isPending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 12,
                        color: const Color(0xFF6366F1).withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to modify or cancel',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6366F1).withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
