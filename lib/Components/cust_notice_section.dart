import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:timeago/timeago.dart' as timeago;

class NoticesSection extends StatefulWidget {
  const NoticesSection({Key? key}) : super(key: key);

  @override
  State<NoticesSection> createState() => _NoticesSectionState();
}

class _NoticesSectionState extends State<NoticesSection>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _noticesRef =
      FirebaseDatabase.instance.ref('notices');
  List<NoticeModel> _notices = [];
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late StreamSubscription<DatabaseEvent> _noticesSubscription; // Add this line

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchNotices();
  }

  void _fetchNotices() {
    // Store the subscription
    _noticesSubscription = _noticesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final notices = <NoticeModel>[];

        data.forEach((key, value) {
          notices.add(NoticeModel.fromMap(key, value));
        });

        // Sort by timestamp (newest first)
        notices.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (mounted) {
          setState(() {
            _notices = notices;
          });
        }
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noticesSubscription.cancel(); // Cancel the subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_notices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[750] : Colors.grey[50],
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.amber[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System Notices',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_notices.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isExpanded ? 'Hide' : 'Show',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: _notices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notice = _notices[index];
                  return _buildNoticeItem(notice, isDark);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(NoticeModel notice, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        // border: Border.left(
        //   width: 3,
        //   color: _getPriorityColor(notice.priority),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getNoticeIcon(notice.type),
                size: 16,
                color: _getPriorityColor(notice.priority),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notice.heading,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(notice.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notice.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getPriorityColor(notice.priority),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notice.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Row(
          //   children: [
          //     Icon(
          //       Icons.access_time,
          //       size: 12,
          //       color: isDark ? Colors.grey[400] : Colors.grey[500],
          //     ),
          //     const SizedBox(width: 4),
          //     Text(
          //       _formatTime(notice.timestamp),
          //       style: TextStyle(
          //         fontSize: 11,
          //         color: isDark ? Colors.grey[400] : Colors.grey[500],
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     Text(
          //       timeago.format(notice.timestamp),
          //       style: TextStyle(
          //         fontSize: 11,
          //         color: isDark ? Colors.grey[400] : Colors.grey[500],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  IconData _getNoticeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'issue':
        return Icons.error_outline;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // String _formatTime(DateTime timestamp) {
  //   return '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  // }
}

class NoticeModel {
  final String id;
  final String type;
  final String heading;
  final String description;
  final DateTime timestamp;
  final String priority;

  NoticeModel({
    required this.id,
    required this.type,
    required this.heading,
    required this.description,
    required this.timestamp,
    required this.priority,
  });

  factory NoticeModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return NoticeModel(
      id: id,
      type: map['type'] ?? 'info',
      heading: map['heading'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      priority: map['priority'] ?? 'low',
    );
  }
}

// Usage example:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notices Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('App with Notices')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const NoticesSection(),
              // Your other content here
              Container(
                height: 1000,
                child: Center(
                  child: Text('Other app content'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
