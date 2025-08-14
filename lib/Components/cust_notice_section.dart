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
    with TickerProviderStateMixin {
  final DatabaseReference _noticesRef =
      FirebaseDatabase.instance.ref('notices');
  List<NoticeModel> _notices = [];
  bool _isExpanded = false;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late StreamSubscription<DatabaseEvent> _noticesSubscription;

  // Animation controllers for pulse effects
  late AnimationController _pulseController;
  late AnimationController _badgePulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _badgePulseAnimation;
  late Animation<double> _badgeScaleAnimation;

  // Loading shimmer animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

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

    // Initialize pulse animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _badgePulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _badgePulseController,
      curve: Curves.easeInOut,
    ));

    _badgeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _badgePulseController,
      curve: Curves.elasticOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _fetchNotices();
  }

  void _fetchNotices() {
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
            _isLoading = false;
          });

          // Start pulse animations when there are notices and not expanded
          if (_notices.isNotEmpty && !_isExpanded) {
            _startPulseAnimations();
          } else {
            _stopPulseAnimations();
          }
        }
      } else {
        // No notices found
        if (mounted) {
          setState(() {
            _notices = [];
            _isLoading = false;
          });
          _stopPulseAnimations();
        }
      }
    });
  }

  void _startPulseAnimations() {
    _pulseController.repeat(reverse: true);
    _badgePulseController.repeat(reverse: true);
  }

  void _stopPulseAnimations() {
    _pulseController.stop();
    _badgePulseController.stop();
    _pulseController.reset();
    _badgePulseController.reset();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
      // Reduce pulse intensity when expanded
      _pulseController.stop();
      _badgePulseController.stop();
    } else {
      _animationController.reverse();
      // Resume pulse when collapsed
      if (_notices.isNotEmpty) {
        _startPulseAnimations();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _badgePulseController.dispose();
    _shimmerController.dispose();
    _noticesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
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
          // Header - always visible
          _buildHeader(isDark),
          // Expandable Content - shows loading/content/empty state
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[750] : Colors.grey[50],
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
              ),
              // Add subtle glow effect during pulse
              boxShadow: _isExpanded || _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.amber.withOpacity(
                            (_pulseAnimation.value * 0.3).clamp(0.0, 1.0)),
                        blurRadius:
                            (8 * _pulseAnimation.value).clamp(0.0, 20.0),
                        spreadRadius:
                            (1 * _pulseAnimation.value).clamp(0.0, 5.0),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Animated notification icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isLoading ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(
                                        (0.4 * _pulseAnimation.value)
                                            .clamp(0.0, 1.0)),
                                    blurRadius: (6 * _pulseAnimation.value)
                                        .clamp(0.0, 15.0),
                                    spreadRadius: (2 * _pulseAnimation.value)
                                        .clamp(0.0, 4.0),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: _isLoading
                              ? (isDark ? Colors.grey[500] : Colors.grey[400])
                              : Colors.amber[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
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
                // Badge - shows loading or count
                _buildBadge(isDark),
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
          );
        },
      ),
    );
  }

  Widget _buildBadge(bool isDark) {
    if (_isLoading) {
      // Loading shimmer badge
      return AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment(_shimmerAnimation.value - 0.3, 0),
                end: Alignment(_shimmerAnimation.value + 0.3, 0),
                colors: [
                  (isDark ? Colors.grey[600] : Colors.grey[300])!,
                  (isDark ? Colors.grey[500] : Colors.grey[200])!,
                  (isDark ? Colors.grey[600] : Colors.grey[300])!,
                ],
              ),
            ),
          );
        },
      );
    }

    // Normal animated badge
    return AnimatedBuilder(
      animation: Listenable.merge([_badgeScaleAnimation, _badgePulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _badgeScaleAnimation.value,
          child: Stack(
            children: [
              // Pulsing background glow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (Colors.amber[100] ?? Colors.amber.withOpacity(0.3))
                      .withOpacity(
                          (0.3 + _badgePulseAnimation.value).clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(
                          (0.5 * _badgePulseAnimation.value).clamp(0.0, 1.0)),
                      blurRadius:
                          (8 * _badgePulseAnimation.value).clamp(0.0, 16.0),
                      spreadRadius:
                          (2 * _badgePulseAnimation.value).clamp(0.0, 4.0),
                    ),
                  ],
                ),
                child: Text(
                  '${_notices.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[800] ?? Colors.amber.shade800,
                  ),
                ),
              ),
              // Ripple effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(
                          (0.6 * _badgePulseAnimation.value).clamp(0.0, 1.0)),
                      width: (1 + _badgePulseAnimation.value).clamp(0.5, 3.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    if (_notices.isEmpty) {
      // Empty state
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No notices at the moment',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loaded notices content
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: _notices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return _buildNoticeItem(notice, isDark);
        },
      ),
    );
  }

  Widget _buildNoticeItem(NoticeModel notice, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
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
