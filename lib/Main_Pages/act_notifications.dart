import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_atlas_page.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
    BadgeService.clearNotificationsBadge();

    loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMore && !isLoading) {
        loadMoreNotifications();
      }
    }
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .range(0, pageSize - 1);

      final List<NotificationItem> loadedNotifications = (response as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList();

      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
        hasMore = loadedNotifications.length == pageSize;
        currentPage = 1;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Failed to load notifications');
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final int from = currentPage * pageSize;
      final int to = from + pageSize - 1;

      final response = await supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .range(from, to);

      final List<NotificationItem> newNotifications = (response as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList();

      setState(() {
        notifications.addAll(newNotifications);
        currentPage++;
        hasMore = newNotifications.length == pageSize;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Failed to load more notifications');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Container(
          //   margin: const EdgeInsets.all(8),
          //   decoration: BoxDecoration(
          //     color: isDark
          //         ? Colors.white.withOpacity(0.1)
          //         : Colors.black.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: IconButton(
          //     icon: Icon(
          //       Icons.tune,
          //       color: isDark ? Colors.white : Colors.black,
          //       size: 20,
          //     ),
          //     onPressed: () {
          //       // Settings action
          //     },
          //   ),
          // ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        color: const Color(0xFF6366F1),
        child: isLoading && notifications.isEmpty
            ? _buildShimmerLoading()
            : notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(48, 48, BorderRadius.circular(12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(120, 16, BorderRadius.circular(8)),
                      const SizedBox(height: 8),
                      _buildShimmerBox(
                          double.infinity, 14, BorderRadius.circular(6)),
                      const SizedBox(height: 4),
                      _buildShimmerBox(200, 14, BorderRadius.circular(6)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildShimmerBox(60, 24, BorderRadius.circular(12)),
                          const SizedBox(width: 8),
                          _buildShimmerBox(80, 24, BorderRadius.circular(12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildShimmerBox(80, 12, BorderRadius.circular(6)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerBox(
      double width, double height, BorderRadius borderRadius) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.1),
                ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
          end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 80,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll show up here',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return _buildLoadingIndicator();
        }
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }

  // Widget _buildStockChip(String text, bool isDark) {
  //   String extractSymbol(String input) {
  //     // Handle formats like "NSE:RELIANCE-EQ" or just "RELIANCE"
  //     final parts = input.split(':');
  //     final symbolPart = parts.length == 2 ? parts[1] : parts[0];
  //     return symbolPart.split('-').first;
  //   }

  //   final displayText = extractSymbol(text);

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: isDark
  //           ? Colors.white.withOpacity(0.1)
  //           : Colors.grey.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: isDark
  //             ? Colors.white.withOpacity(0.2)
  //             : Colors.grey.withOpacity(0.2),
  //         width: 0.5,
  //       ),
  //     ),
  //     child: Text(
  //       displayText,
  //       style: TextStyle(
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //         color: isDark
  //             ? Colors.white.withOpacity(0.9)
  //             : Colors.black.withOpacity(0.8),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (notification.stockData.isNotEmpty ||
                notification.stockName.isNotEmpty) {
              if (notification.stockName == "NIFTY" ||
                  notification.stockName == "BANKNIFTY" ||
                  notification.stockName == "MARKET") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AtlasOutputPage(),
                  ),
                );
              } else {
                if (checkStockExists(notification.stockName.toUpperCase())) {
                  final input = notification.stockName.toUpperCase();

                  final matchedKey = totalStocks.keys.firstWhere(
                    (key) =>
                        key.contains(input) ||
                        totalStocks[key]?["stock_name"]?.contains(input) ==
                            true,
                    orElse: () => input,
                  );

                  Get.toNamed('/stocks/$matchedKey');
                }
                if (notification.stockName.toLowerCase() == "leaderboard") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaderboardPage(),
                    ),
                  );
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, title, and time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main notification icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        children: [
                          // Title and unread indicator
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.heading,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (_isToday(notification.createdAt) &&
                                  !notification.isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  notification.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.75),
                    height: 1.4,
                  ),
                  // maxLines: 7,
                  // overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Stock chips and stock icon section
                if (notification.stockData.isNotEmpty ||
                    notification.stockName.isNotEmpty)
                  Row(
                    children: [
                      // Stock icon (if stock name exists)
                      if (notification.stockName.isNotEmpty &&
                          (notification.stockName == "NIFTY" ||
                              notification.stockName == "BANKNIFTY" ||
                              notification.stockName == "MARKET" ||
                              checkStockExists(
                                  notification.stockName.toUpperCase())))
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              height: 48,
                              width: 48,
                              imageUrl: Constants.OptionXiS3Loc +
                                  _extractSymbol(notification.stockName) +
                                  ".png",
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    notification.stockName.isNotEmpty
                                        ? notification.stockName[0]
                                        : 'S',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/stockdefault.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Stock chips
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ...notification.stockData
                                .map((stock) => _buildStockChip(stock, isDark)),
                            if (notification.stockData.isEmpty &&
                                notification.stockName.isNotEmpty)
                              _buildStockChip(notification.stockName, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Time section with both formatted time and time ago
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(notification.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        timeago.format(notification.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method to extract stock symbol
  String _extractSymbol(String input) {
    // Handle formats like "NSE:RELIANCE-EQ" or just "RELIANCE"
    final parts = input.split(':');
    final symbolPart = parts.length == 2 ? parts[1] : parts[0];
    return symbolPart.split('-').first;
  }

// Helper method to format time
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[dateTime.weekday - 1];

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedTime = '$displayHour:$minute $period';

    if (difference.inDays < 7) {
      // Within the last 7 days - show weekday and time
      return '$dayName, $formattedTime';
    } else {
      // Older - show full date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

// Enhanced stock chip with better styling
  Widget _buildStockChip(String text, bool isDark) {
    final displayText = _extractSymbol(text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF6366F1).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.15),
                ]
              : [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color:
              isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF6366F1),
        ),
      ),
    );
  }

  bool checkStockExists(String upperCase) {
    // Direct match on key
    if (totalStocks.containsKey(upperCase) &&
        totalStocks[upperCase]?["full_stock_name"] != null) {
      return true;
    }

    // Try matching on partial stock symbol
    for (final entry in totalStocks.entries) {
      final stockName = entry.value["stock_name"] ?? '';
      final fullName = entry.value["full_stock_name"] ?? '';

      if (stockName.contains(upperCase) || fullName.contains(upperCase)) {
        return true;
      }
    }

    return false;
  }
}

class NotificationItem {
  final String id;
  final String stockName;
  final String heading;
  final String description;
  final DateTime createdAt;
  final bool isRead;
  final List<String> stockData;

  NotificationItem({
    required this.id,
    required this.stockName,
    required this.heading,
    required this.description,
    required this.createdAt,
    required this.isRead,
    this.stockData = const [],
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      stockName: json['stock_name'],
      heading: json['heading'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      stockData: json['stock_data'] != null
          ? List<String>.from(json['stock_data'])
          : [],
    );
  }

  NotificationItem copyWith({
    String? id,
    String? stockName,
    String? heading,
    String? description,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      stockName: stockName ?? this.stockName,
      heading: heading ?? this.heading,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
