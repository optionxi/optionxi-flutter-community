import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/BrokersPage/Fyers/utils/fyers_datamodel.dart';
import 'package:optionxi/BrokersPage/Fyers/utils/fyers_controller.dart';

// Orders Page for Fyers
class OrdersPageFyers extends StatefulWidget {
  const OrdersPageFyers({
    Key? key,
  }) : super(key: key);

  @override
  State<OrdersPageFyers> createState() => _OrdersPageFyersState();
}

class _OrdersPageFyersState extends State<OrdersPageFyers>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FyersRepository _repository = FyersRepository();

  List<FyersOrderModel> _allOrders = [];
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

  List<FyersOrderModel> get _completedOrders =>
      _allOrders.where((order) => order.statusText == 'FILLED').toList();

  List<FyersOrderModel> get _pendingOrders =>
      _allOrders.where((order) => order.statusText == 'PENDING').toList();

  List<FyersOrderModel> get _cancelledOrders => _allOrders
      .where((order) =>
          order.statusText == 'CANCELLED' || order.statusText == 'REJECTED')
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
                    ? _buildErrorState()
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            child: const Text('Retry'),
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

  Widget _buildOrdersList(List<FyersOrderModel> orders, String type) {
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

  Widget _buildOrderCard(FyersOrderModel order, String type) {
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

    // Parse order date time - handle different formats
    DateTime orderTime;
    try {
      // Try parsing the format "12-Sep-2025 13:55:29"
      if (order.orderDateTime.contains('-') &&
          order.orderDateTime.contains(' ')) {
        final parts = order.orderDateTime.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0];
          final timePart = parts[1];

          // Convert "12-Sep-2025" to a parseable format
          final dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            final monthMap = {
              'Jan': '01',
              'Feb': '02',
              'Mar': '03',
              'Apr': '04',
              'May': '05',
              'Jun': '06',
              'Jul': '07',
              'Aug': '08',
              'Sep': '09',
              'Oct': '10',
              'Nov': '11',
              'Dec': '12'
            };
            final day = dateComponents[0].padLeft(2, '0');
            final month = monthMap[dateComponents[1]] ?? '01';
            final year = dateComponents[2];

            final isoDateTime = '$year-$month-$day $timePart';
            orderTime = DateTime.parse(isoDateTime);
          } else {
            orderTime = DateTime.now();
          }
        } else {
          orderTime = DateTime.now();
        }
      } else {
        // Try parsing as ISO format or other standard formats
        orderTime = DateTime.tryParse(order.orderDateTime) ?? DateTime.now();
      }
    } catch (e) {
      orderTime = DateTime.now();
    }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (order.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          order.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
                    order.statusText,
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
                    color:
                        order.side == 1 ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.side == 1 ? 'BUY' : 'SELL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          order.side == 1 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.qty} qty',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  order.productType,
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
                        'Price: ₹${order.limitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      if (order.avgPrice > 0 &&
                          order.avgPrice != order.limitPrice) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Avg: ₹${order.avgPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
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
            if (order.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
