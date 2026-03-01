import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

  late StreamSubscription<DatabaseEvent> _noticesSubscription;

  late AnimationController _expandController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _headerEntranceController;

  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _headerEntranceAnimation;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _headerEntranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerEntranceAnimation = CurvedAnimation(
      parent: _headerEntranceController,
      curve: Curves.easeOutBack,
    );
    _headerEntranceController.forward();

    _fetchNotices();
  }

  void _fetchNotices() {
    _noticesSubscription = _noticesRef.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final notices = <NoticeModel>[];
        data.forEach(
            (key, value) => notices.add(NoticeModel.fromMap(key, value)));
        notices.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _notices = notices;
          _isLoading = false;
        });

        if (_notices.isNotEmpty && !_isExpanded) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        setState(() {
          _notices = [];
          _isLoading = false;
        });
        _pulseController.stop();
        _shimmerController.stop();
      }
    });
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _pulseController.stop();
      _pulseController.reset();
    } else {
      _expandController.reverse();
      if (_notices.isNotEmpty) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _headerEntranceController.dispose();
    _noticesSubscription.cancel();
    super.dispose();
  }

  // ─── Color Tokens ────────────────────────────────────────────────────────────

  Color _surface(bool isDark) =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);

  Color _surfaceElevated(bool isDark) =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7);

  Color _border(bool isDark) =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  Color _textPrimary(bool isDark) =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);

  Color _textSecondary(bool isDark) =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

  static const Color _accentAmber = Color(0xFFF5A623);

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _headerEntranceAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border(isDark), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(isDark),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        splashColor: _accentAmber.withOpacity(0.06),
        highlightColor: _accentAmber.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _isExpanded
                ? _surfaceElevated(isDark).withOpacity(0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              _buildNotificationIcon(isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Notices',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary(isDark),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!_isLoading && _notices.isNotEmpty)
                      Text(
                        '${_notices.length} active ${_notices.length == 1 ? 'notice' : 'notices'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary(isDark),
                          letterSpacing: -0.1,
                        ),
                      ),
                    if (_isLoading) const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildBadgeOrStatus(isDark),
              const SizedBox(width: 8),
              _buildChevron(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final glow = math.sin(_pulseAnimation.value * math.pi);
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isLoading
                ? _surfaceElevated(isDark)
                : _accentAmber.withOpacity(0.12 + glow * 0.06),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isLoading || _isExpanded
                ? null
                : [
                    BoxShadow(
                      color: _accentAmber.withOpacity(0.25 * glow),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Icon(
            _isLoading
                ? Icons.notifications_outlined
                : (_notices.isEmpty
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded),
            color: _isLoading ? _textSecondary(isDark) : _accentAmber,
            size: 18,
          ),
        );
      },
    );
  }

  Widget _buildBadgeOrStatus(bool isDark) {
    if (_isLoading) {
      return AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, _) {
          return Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment(_shimmerAnimation.value - 0.5, 0),
                end: Alignment(_shimmerAnimation.value + 0.5, 0),
                colors: [
                  _border(isDark),
                  _surfaceElevated(isDark),
                  _border(isDark),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_notices.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final glow = math.sin(_pulseAnimation.value * math.pi);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _accentAmber.withOpacity(0.13 + glow * 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentAmber.withOpacity(0.35 + glow * 0.25),
              width: 1,
            ),
          ),
          child: Text(
            '${_notices.length}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _accentAmber,
              letterSpacing: 0.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChevron(bool isDark) {
    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border(isDark), width: 1),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _textSecondary(isDark),
          size: 18,
        ),
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        Divider(color: _border(isDark), height: 1, thickness: 1),
        if (_notices.isEmpty && !_isLoading) _buildEmpty(isDark),
        if (_notices.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildNoticeItem(_notices[index], isDark, index),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _surfaceElevated(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border(isDark)),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 24,
              color: _textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'All clear',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary(isDark),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No active system notices right now.',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notice Item ─────────────────────────────────────────────────────────────

  Widget _buildNoticeItem(NoticeModel notice, bool isDark, int index) {
    final priorityColor = _priorityColor(notice.priority);
    final icon = _noticeIcon(notice.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark), width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority indicator bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 14, color: priorityColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notice.heading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary(isDark),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityChip(notice.priority, priorityColor),
                        ],
                      ),
                      if (notice.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          notice.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _textSecondary(isDark),
                            height: 1.45,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  IconData _noticeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.construction_rounded;
      case 'issue':
        return Icons.error_outline_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.circle_notifications_rounded;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF3B30);
      case 'medium':
        return const Color(0xFFFF9500);
      case 'low':
        return const Color(0xFF30B0C7);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class NoticeModel {
  final String id;
  final String type;
  final String heading;
  final String description;
  final DateTime timestamp;
  final String priority;

  const NoticeModel({
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
