import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/BrokersPage/Zerodha/error_state.dart';
import 'package:optionxi/BrokersPage/Upstox/utils/upstox_datamodel.dart';
import 'package:optionxi/BrokersPage/Upstox/utils/upstox_controller.dart';

// Orders Page for Upstox
class OrdersPageUpstox extends StatefulWidget {
  const OrdersPageUpstox({
    Key? key,
  }) : super(key: key);

  @override
  State<OrdersPageUpstox> createState() => _OrdersPageUpstoxState();
}

class _OrdersPageUpstoxState extends State<OrdersPageUpstox>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UpstoxRepository _repository = UpstoxRepository();

  List<UpstoxOrderModel> _allOrders = [];
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

  List<UpstoxOrderModel> get _completedOrders => _allOrders
      .where((order) => order.status.toLowerCase() == 'complete')
      .toList();

  List<UpstoxOrderModel> get _pendingOrders => _allOrders
      .where((order) =>
          order.status.toLowerCase() == 'open' ||
          order.status.toLowerCase() == 'pending' ||
          order.status.toLowerCase() == 'trigger pending' ||
          order.status.toLowerCase() == 'validation pending')
      .toList();

  List<UpstoxOrderModel> get _cancelledOrders => _allOrders
      .where((order) =>
          order.status.toLowerCase() == 'cancelled' ||
          order.status.toLowerCase() == 'rejected')
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              indicatorColor: const Color(0xFF6366F1),
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              tabs: [
                Tab(
                  text: 'Success (${_completedOrders.length})',
                ),
                Tab(
                  text: 'Pending (${_pendingOrders.length})',
                ),
                Tab(
                  text: 'Cancelled (${_cancelledOrders.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : _errorMessage != null
                    ? buildErrorStateBroker(_loadOrders, _errorMessage, context)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrdersList(_completedOrders, 'success'),
                          _buildOrdersList(_pendingOrders, 'pending'),
                          _buildOrdersList(_cancelledOrders, 'cancelled'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
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
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 16,
                width: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<UpstoxOrderModel> orders, String type) {
    if (orders.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index], type),
    );
  }

  Widget _buildEmptyState(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title, subtitle;
    IconData icon;

    switch (type) {
      case 'success':
        title = 'No completed orders';
        subtitle = 'Your successful orders will appear here';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        title = 'No pending orders';
        subtitle = 'Your pending orders will appear here';
        icon = Icons.schedule;
        break;
      default:
        title = 'No cancelled orders';
        subtitle = 'Your cancelled orders will appear here';
        icon = Icons.cancel_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(UpstoxOrderModel order, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    Color statusBgColor;

    switch (type) {
      case 'success':
        statusColor = Colors.green[600]!;
        statusBgColor = Colors.green[50]!;
        if (isDark) statusBgColor = Colors.green[900]!.withOpacity(0.2);
        break;
      case 'pending':
        statusColor = Colors.orange[600]!;
        statusBgColor = Colors.orange[50]!;
        if (isDark) statusBgColor = Colors.orange[900]!.withOpacity(0.2);
        break;
      default:
        statusColor = Colors.red[600]!;
        statusBgColor = Colors.red[50]!;
        if (isDark) statusBgColor = Colors.red[900]!.withOpacity(0.2);
    }

    final DateTime orderTime = DateTime.parse(order.orderTimestamp);
    final String formattedTime =
        DateFormat('MMM dd, yyyy HH:mm').format(orderTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.tradingSymbol.isNotEmpty
                        ? order.tradingSymbol
                        : order.tradingsymbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.transactionType.toUpperCase() == 'BUY'
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.transactionType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: order.transactionType.toUpperCase() == 'BUY'
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.product.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.quantity} qty',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  order.exchange,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      if (order.averagePrice > 0)
                        Text(
                          'Avg: ₹${order.averagePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      if (order.filledQuantity > 0 &&
                          order.filledQuantity != order.quantity)
                        Text(
                          'Filled: ${order.filledQuantity}/${order.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (order.statusMessage?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
            if (order.orderType != 'MARKET') ...[
              const SizedBox(height: 4),
              Text(
                'Order Type: ${order.orderType}${order.triggerPrice > 0 ? ' (Trigger: ₹${order.triggerPrice.toStringAsFixed(2)})' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
            // Show additional order info if available
            if (order.isAmo) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AMO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
