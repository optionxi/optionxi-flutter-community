import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/VirtualTrading/VComponents/custom_collapsible_headers.dart';
import 'package:optionxi/VirtualTrading/act_buyandsell_prev.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define the type alias for the subscription status callback
typedef SubscriptionStatusCallback = void
    Function(RealtimeSubscribeStatus status, [Object? error]);

class OrdersPage extends StatefulWidget {
  final LeaderboardEntry? user;
  const OrdersPage(this.user, {Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _rejectedOrders = [];

  bool _isLoading = true;
  String? _error;

  // Separate realtime channels for each table
  RealtimeChannel? _pendingOrdersChannel;
  RealtimeChannel? _processingOrdersChannel;
  RealtimeChannel? _completedOrdersChannel;
  RealtimeChannel? _rejectedOrdersChannel;

  int _previousTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchAllOrders();
    _setupOrdersSubscriptions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pendingOrdersChannel?.unsubscribe();
    _processingOrdersChannel?.unsubscribe();
    _completedOrdersChannel?.unsubscribe();
    _rejectedOrdersChannel?.unsubscribe();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging &&
        _tabController.index != _previousTabIndex) {
      _previousTabIndex = _tabController.index;
      _refreshCurrentTab();
    }
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await _fetchAllOrders();
        break;
      case 1:
        await _fetchCompletedOrders();
        break;
      case 2:
        await _fetchRejectedOrders();
        break;
    }
  }

  void _handleOrderChange(PostgresChangePayload payload, String tableName) {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord; // Get the old record for delete events

    String status;
    switch (tableName) {
      case 'prev_pending_orders':
        status = 'pending';
        break;
      case 'prev_processing_orders':
        status = 'processing';
        break;
      case 'prev_completed_orders':
        status = 'completed';
        break;
      case 'prev_rej_orders':
        status = 'rejected';
        break;
      default:
        return;
    }

    // Handle delete events
    if (eventType == PostgresChangeEvent.delete) {
      final deletedId = oldRecord['id'];
      if (deletedId != null) {
        // Remove from _allOrders
        _allOrders.removeWhere((order) => order['id'] == deletedId);
        // Remove from specific lists if applicable
        if (tableName == 'prev_completed_orders') {
          _completedOrders.removeWhere((order) => order['id'] == deletedId);
        } else if (tableName == 'prev_rej_orders') {
          _rejectedOrders.removeWhere((order) => order['id'] == deletedId);
        }
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Row(
          //       children: [
          //         Icon(Icons.delete_forever_rounded,
          //             color: Colors.white, size: 20),
          //         const SizedBox(width: 8),
          //         Expanded(
          //           child: Text(
          //             // 'Order processed: ID $deletedId',
          //             'Order processed sucessfully',
          //             style: const TextStyle(
          //               color: Colors.white,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //     backgroundColor: Colors.orange,
          //     duration: const Duration(seconds: 2),
          //     behavior: SnackBarBehavior.floating,
          //     margin: const EdgeInsets.all(16),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //   ),
          // );
          _refreshCurrentTab(); // Refresh UI after deletion
        }
      }
      return; // Stop further processing for delete events
    }

    // For insert/update events, use newRecord
    final record = newRecord;
    final stockName = record['symbol'] ?? 'Unknown';
    final quantity = record['quantity'] ?? record['executed_quantity'] ?? 0;

    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case 'pending':
        if (eventType == PostgresChangeEvent.insert) {
          message = 'Order placed: $stockName (${quantity} qty)';
          backgroundColor = Colors.amber;
          icon = Icons.pending_rounded;
        } else if (eventType == PostgresChangeEvent.update) {
          message = 'Order updated: $stockName (${quantity} qty)';
          backgroundColor = Colors.amber;
          icon = Icons.pending_rounded;
        } else {
          message = 'Order status changed: $stockName';
          backgroundColor = Colors.blue;
          icon = Icons.sync_rounded;
        }
        break;
      case 'processing':
        if (eventType == PostgresChangeEvent.insert) {
          message = 'Order processing: $stockName (${quantity} qty)';
          backgroundColor = Colors.blue;
          icon = Icons.sync_rounded;
        } else {
          return;
        }
        break;
      case 'completed':
        if (eventType == PostgresChangeEvent.insert) {
          message = 'Order completed: $stockName (${quantity} qty)';
          backgroundColor = Colors.green;
          icon = Icons.check_circle_rounded;
        } else {
          return;
        }
        break;
      case 'rejected':
        if (eventType == PostgresChangeEvent.insert) {
          final reason = record['rejection_reason'] ?? 'Unknown reason';
          message = 'Order rejected: $stockName - $reason';
          backgroundColor = Colors.red;
          icon = Icons.cancel_rounded;
        } else {
          return;
        }
        break;
      default:
        return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 70), // Add bottom margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      final int uniqueId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      NotificationService().showNotificationBasic(
        id: uniqueId,
        title: "Order status",
        body: message,
      );
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshCurrentTab();
      }
    });
  }

  void _setupOrdersSubscriptions() {
    final String? uid =
        widget.user?.suid ?? FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    // Unsubscribe from any existing channels
    _pendingOrdersChannel?.unsubscribe();
    _processingOrdersChannel?.unsubscribe();
    _completedOrdersChannel?.unsubscribe();
    _rejectedOrdersChannel?.unsubscribe();

    // Pending Orders Channel
    _pendingOrdersChannel =
        _supabase.channel('pending_orders_channel_$uid').onPostgresChanges(
              event: PostgresChangeEvent
                  .all, // Listen for all events including DELETE
              schema: 'public',
              table: 'prev_pending_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'suid',
                value: uid,
              ),
              callback: (payload) =>
                  _handleOrderChange(payload, 'prev_pending_orders'),
            );

    // Processing Orders Channel
    _processingOrdersChannel =
        _supabase.channel('processing_orders_channel_$uid').onPostgresChanges(
              event: PostgresChangeEvent
                  .all, // Listen for all events including DELETE
              schema: 'public',
              table: 'prev_processing_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'suid',
                value: uid,
              ),
              callback: (payload) =>
                  _handleOrderChange(payload, 'prev_processing_orders'),
            );

    // Completed Orders Channel
    _completedOrdersChannel =
        _supabase.channel('completed_orders_channel_$uid').onPostgresChanges(
              event: PostgresChangeEvent
                  .all, // Listen for all events including DELETE
              schema: 'public',
              table: 'prev_completed_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'suid',
                value: uid,
              ),
              callback: (payload) =>
                  _handleOrderChange(payload, 'prev_completed_orders'),
            );

    // Rejected Orders Channel
    _rejectedOrdersChannel = _supabase
        .channel('rejected_orders_channel_$uid')
        .onPostgresChanges(
          event:
              PostgresChangeEvent.all, // Listen for all events including DELETE
          schema: 'public',
          table: 'prev_rej_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'suid',
            value: uid,
          ),
          callback: (payload) => _handleOrderChange(payload, 'prev_rej_orders'),
        );

    // Subscribe to all channels
    _pendingOrdersChannel?.subscribe(_subscriptionStatusCallback('pending'));
    _processingOrdersChannel
        ?.subscribe(_subscriptionStatusCallback('processing'));
    _completedOrdersChannel
        ?.subscribe(_subscriptionStatusCallback('completed'));
    _rejectedOrdersChannel?.subscribe(_subscriptionStatusCallback('rejected'));
  }

  SubscriptionStatusCallback _subscriptionStatusCallback(String channelName) {
    return (status, [error]) {
      if (mounted) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('✅ Successfully subscribed to $channelName channel');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          print('❌ Error subscribing to $channelName channel: $error');
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _setupOrdersSubscriptions(); // Re-attempt all subscriptions
            }
          });
        } else if (status == RealtimeSubscribeStatus.closed) {
          print('🔌 $channelName channel closed');
        }
      }
    };
  }

  Future<void> _fetchAllOrders() async {
    try {
      // Only show loading if we don't have any data yet
      final shouldShowLoading = _allOrders.isEmpty;
      if (shouldShowLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // final uid = FirebaseAuth.instance.currentUser?.uid;
      final String? uid =
          widget.user?.suid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'User not logged in';
        });
        return;
      }

      final futures = await Future.wait([
        _supabase
            .from('prev_pending_orders')
            .select()
            .eq('suid', uid)
            .order('created_at', ascending: false),
        _supabase
            .from('prev_processing_orders')
            .select()
            .eq('suid', uid)
            .order('created_at', ascending: false),
        _supabase
            .from('prev_completed_orders')
            .select()
            .eq('suid', uid)
            .order('execution_time', ascending: false),
        _supabase
            .from('prev_rej_orders')
            .select()
            .eq('suid', uid)
            .order('rejected_at', ascending: false),
      ]);

      List<Map<String, dynamic>> allOrders = [];

      for (var order in futures[0]) {
        allOrders.add(_mapOrder(order, 'pending'));
      }

      for (var order in futures[1]) {
        allOrders.add(_mapOrder(order, 'processing'));
      }

      for (var order in futures[2]) {
        allOrders.add(_mapOrder(order, 'completed'));
      }

      for (var order in futures[3]) {
        allOrders.add(_mapOrder(order, 'rejected'));
      }

      allOrders.sort((a, b) => b['time'].compareTo(a['time']));

      if (mounted) {
        setState(() {
          _allOrders = allOrders;
          if (shouldShowLoading) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching orders: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCompletedOrders() async {
    try {
      // final uid = FirebaseAuth.instance.currentUser?.uid;
      final String? uid =
          widget.user?.suid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final response = await _supabase
          .from('prev_completed_orders')
          .select()
          .eq('suid', uid)
          .order('execution_time', ascending: false);

      List<Map<String, dynamic>> orders = [];
      for (var order in response) {
        orders.add(_mapOrder(order, 'completed'));
      }

      if (mounted) {
        setState(() {
          _completedOrders = orders;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching completed orders: $e';
        });
      }
    }
  }

  Future<void> _fetchRejectedOrders() async {
    try {
      // final uid = FirebaseAuth.instance.currentUser?.uid;
      final String? uid =
          widget.user?.suid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final response = await _supabase
          .from('prev_rej_orders')
          .select()
          .eq('suid', uid)
          .order('rejected_at', ascending: false);

      List<Map<String, dynamic>> orders = [];
      for (var order in response) {
        orders.add(_mapOrder(order, 'rejected'));
      }

      if (mounted) {
        setState(() {
          _rejectedOrders = orders;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching rejected orders: $e';
        });
      }
    }
  }

  Map<String, dynamic> _mapOrder(Map<String, dynamic> order, String status) {
    switch (status) {
      case 'pending':
        final price = order['price'] ?? 0.0;
        final quantity = order['quantity'] ?? 0;
        return {
          'id': order['id'],
          'status': 'pending',
          'stockName': order['symbol'],
          'qty': quantity,
          'time': DateTime.parse(order['created_at']),
          'details': '${order['transaction_type']} at ₹${price.toString()}',
          'rupees': price > 0
              ? '₹${convertToKMB((price * quantity).toStringAsFixed(2))}'
              : 'Market Price',
          'orderType': order['order_type'],
          'transactionType': order['transaction_type'],
          'segment': order['segment'],
          'price': price,
          'triggerPrice': order['trigger_price'],
        };
      case 'processing':
        final price = order['price'] ?? 0.0;
        final quantity = order['quantity'] ?? 0;
        return {
          'id': order['id'],
          'status': 'processing',
          'stockName': order['symbol'],
          'qty': quantity,
          'time': DateTime.parse(order['processing_started_at']),
          'details': '${order['transaction_type']} - Processing',
          'rupees': price > 0
              ? '₹${convertToKMB((price * quantity).toStringAsFixed(2))}'
              : 'Market Price',
          'orderType': order['order_type'],
          'transactionType': order['transaction_type'],
          'segment': order['segment'],
          'price': price,
          'triggerPrice': order['trigger_price'],
          'processingStartedAt': order['processing_started_at'],
          'createdAt': order['created_at'],
        };
      case 'completed':
        final executedPrice = order['executed_price'] ?? 0.0;
        final executedQuantity = order['executed_quantity'] ?? 0;
        return {
          'id': order['id'],
          'status': 'completed',
          'stockName': order['symbol'],
          'qty': executedQuantity,
          'time': DateTime.parse(order['execution_time']),
          'details':
              '${order['transaction_type']} at ₹${executedPrice.toString()}',
          'rupees':
              '₹${convertToKMB((executedPrice * executedQuantity).toStringAsFixed(2))}',
          'orderType': order['order_type'],
          'transactionType': order['transaction_type'],
          'segment': order['segment'],
          'executedPrice': executedPrice,
          'executedQuantity': executedQuantity,
          'originalPrice': order['price'],
          'triggerPrice': order['trigger_price'],
          'brokerage': order['brokerage'],
          'taxes': order['taxes'],
          'totalCharges': order['total_charges'],
          'isShortSell': order['is_short_sell'],
          'processingStartedAt': order['processing_started_at'],
          'createdAt': order['created_at'],
        };
      case 'rejected':
        final price = order['price'] ?? 0.0;
        final quantity = order['quantity'] ?? 0;
        return {
          'id': order['id'],
          'status': 'rejected',
          'stockName': order['symbol'],
          'qty': quantity,
          'time': DateTime.parse(order['rejected_at']),
          'details': order['rejection_reason'],
          'rupees': '₹0',
          'orderType': order['order_type'],
          'transactionType': order['transaction_type'],
          'segment': order['segment'],
          'price': price,
          'triggerPrice': order['trigger_price'],
          'rejectionReason': order['rejection_reason'],
        };
      default:
        return order;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: widget.user != null
          ? _fragOrders(textColor)
          : SafeArea(
              child: _fragOrders(textColor),
            ),
    );
  }

  NestedScrollView _fragOrders(Color textColor) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // Collapsible header
        // SliverPersistentHeader(
        //   floating: false,
        //   pinned: false,
        //   delegate: CollapsibleHeaderDelegate(
        //     minHeight: 0,
        //     maxHeight: 80, // Adjust based on your header height
        //     child: _buildHeader(textColor),
        //   ),
        // ),
        // Pinned tab bar
        SliverPersistentHeader(
          pinned: true,
          delegate: TabBarDelegate(
            tabBar: _buildTabBar(),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(_allOrders),
          _buildOrdersTab(_completedOrders),
          _buildOrdersTab(_rejectedOrders),
        ],
      ),
    );
  }

  // Widget _buildHeader(Color textColor) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           "Orders",
  //           style: GoogleFonts.poppins(
  //             fontSize: 28,
  //             fontWeight: FontWeight.bold,
  //             color: textColor,
  //           ),
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 8,
  //                 height: 8,
  //                 decoration: BoxDecoration(
  //                   color: Colors.green,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               const SizedBox(width: 6),
  //               Text(
  //                 'DELAYED',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: Theme.of(context).colorScheme.primary,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.trending_up_rounded, size: 18),
                  // SizedBox(width: 8),
                  Text('All'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.trending_up_rounded, size: 18),
                  // SizedBox(width: 8),
                  Text('Completed'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.history_rounded, size: 18),
                  // SizedBox(width: 8),
                  Text('Rejected'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(List<Map<String, dynamic>> orders) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = theme.dividerColor;
    final cardColor = theme.cardColor;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Orders',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshCurrentTab,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No orders found',
        subtitle: 'Start trading to see your orders here',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return InkWell(
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BuyandSellPagePrev(
                          order['stockName'], order['segment'], false)));

              setState(() {});
            },
            child: _buildOrderCard(order, isDark, textColor, secondaryTextColor,
                    dividerColor, cardColor)
                .animate()
                .fadeIn(
                  duration: Duration(milliseconds: 100),
                  delay: Duration(milliseconds: index * 10),
                )
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: Duration(milliseconds: 100),
                  delay: Duration(milliseconds: index * 10),
                ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
      Map<String, dynamic> order,
      bool isDark,
      Color textColor,
      Color? secondaryTextColor,
      Color dividerColor,
      Color cardColor) {
    final borderColor =
        isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2);
    final String segment = order['transactionType'];
    final bool isBUY = segment == 'BUY';
    final bool isSELL = segment == 'SELL';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
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
                _buildOrderStatusBadge(order, isDark),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBUY
                        ? (isDark ? Colors.green[900] : Colors.green[50])
                        : isSELL
                            ? (isDark ? Colors.red[900] : Colors.red[50])
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    segment,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isBUY
                          ? (isDark ? Colors.green[100] : Colors.green[700])
                          : isSELL
                              ? (isDark ? Colors.red[100] : Colors.red[700])
                              : secondaryTextColor,
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: dividerColor, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['stockName'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${order['segment']}',
                        style:
                            TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _timeAgo(order['time']),
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: dividerColor, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                    'Quantity',
                    order['qty'].toString(),
                    Icons.format_list_numbered_rounded,
                    textColor,
                    secondaryTextColor),
                if (order['status'] != 'rejected')
                  _buildDetailItem(
                    'Price',
                    (order['executedPrice'] == null ||
                            order['executedPrice'] == "null")
                        ? "processing"
                        : order['executedPrice'].toString(),
                    Icons.currency_rupee_rounded,
                    textColor,
                    secondaryTextColor,
                  ),
                _buildDetailItem('Type', order['orderType'] ?? 'MARKET',
                    Icons.category_rounded, textColor, secondaryTextColor),
              ],
            ),
            if (order['status'] == 'completed' && order['rupees'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['rupees'] != null
                          ? 'Total Value:'
                          : 'Total Charges:',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    Text(
                      '${order['rupees']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (order['status'] == 'rejected') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red[900]?.withOpacity(0.3)
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['details'],
                        style: TextStyle(fontSize: 12, color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(Map<String, dynamic> order, bool isDark) {
    final (color, backgroundColor) = _getStatusColors(order['status'], isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(order['status']), color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            order['status'].toString().toUpperCase(),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      Color textColor, Color? secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: secondaryTextColor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: secondaryTextColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }

  (Color, Color) _getStatusColors(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'completed':
        return isDark
            ? (Colors.green[400]!, Colors.green[900]!)
            : (Colors.green[700]!, Colors.green[50]!);
      case 'pending':
        return isDark
            ? (Colors.amber[400]!, Colors.amber[900]!)
            : (Colors.amber[700]!, Colors.amber[50]!);
      case 'processing':
        return isDark
            ? (Colors.blue[400]!, Colors.blue[900]!)
            : (Colors.blue[700]!, Colors.blue[50]!);
      case 'rejected':
        return isDark
            ? (Colors.red[400]!, Colors.red[900]!)
            : (Colors.red[700]!, Colors.red[50]!);
      default:
        return isDark
            ? (Colors.grey[400]!, Colors.grey[800]!)
            : (Colors.grey[700]!, Colors.grey[200]!);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'processing':
        return Icons.sync_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
