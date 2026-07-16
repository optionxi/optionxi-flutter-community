import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Compact notification-bell style icon for use in a header/app bar.
/// Tap it to open a dialog with the full notices list.
class NoticesSectionIcon extends StatefulWidget {
  const NoticesSectionIcon({Key? key}) : super(key: key);

  @override
  State<NoticesSectionIcon> createState() => _NoticesSectionIconState();
}

class _NoticesSectionIconState extends State<NoticesSectionIcon>
    with TickerProviderStateMixin {
  final DatabaseReference _noticesRef =
      FirebaseDatabase.instance.ref('notices');
  List<NoticeModel> _notices = [];
  bool _isLoading = true;

  late StreamSubscription<DatabaseEvent> _noticesSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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

        if (_notices.isNotEmpty) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        setState(() {
          _notices = [];
          _isLoading = false;
        });
        _pulseController.stop();
      }
    });
  }

  void _openNoticesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _NoticesDialog(notices: _notices),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _noticesSubscription.cancel();
    super.dispose();
  }

  // ─── Color Tokens ────────────────────────────────────────────────────────
  Color _surfaceElevated(bool isDark) =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7);

  Color _border(bool isDark) =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  Color _textSecondary(bool isDark) =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

  static const Color _accentAmber = Color(0xFFF5A623);

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none, // <-- badge allowed to overflow
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias, // only clips the ripple now
            child: InkWell(
              onTap: _isLoading ? null : _openNoticesDialog,
              customBorder: const CircleBorder(),
              splashColor: _accentAmber.withOpacity(0.15),
              highlightColor: _accentAmber.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedBuilder(
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
                        border: Border.all(color: _border(isDark), width: 1),
                        boxShadow: _isLoading || _notices.isEmpty
                            ? null
                            : [
                                BoxShadow(
                                  color: _accentAmber.withOpacity(0.25 * glow),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isLoading
                            ? Icons.notifications_outlined
                            : (_notices.isEmpty
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded),
                        color:
                            _isLoading ? _textSecondary(isDark) : _accentAmber,
                        size: 18,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Badge now lives OUTSIDE the clipped Material — won't get cut off
          if (!_isLoading && _notices.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  final glow = math.sin(_pulseAnimation.value * math.pi);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: _accentAmber,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accentAmber.withOpacity(0.5 * glow),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _notices.length > 9 ? '9+' : '${_notices.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Dialog ────────────────────────────────────────────────────────────────

class _NoticesDialog extends StatelessWidget {
  final List<NoticeModel> notices;

  const _NoticesDialog({required this.notices});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          width: math.min(size.width * 0.9, 420),
          constraints: BoxConstraints(maxHeight: size.height * 0.75),
          decoration: BoxDecoration(
            color: _surface(isDark),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(context, isDark),
              Divider(color: _border(isDark), height: 1, thickness: 1),
              Flexible(
                child: notices.isEmpty
                    ? _buildEmpty(isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: notices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildNoticeItem(notices[index], isDark, index),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accentAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: _accentAmber,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
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
                Text(
                  notices.isEmpty
                      ? 'No active notices'
                      : '${notices.length} active ${notices.length == 1 ? 'notice' : 'notices'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary(isDark),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _surfaceElevated(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border(isDark), width: 1),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: _textSecondary(isDark),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            style: TextStyle(fontSize: 12, color: _textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(NoticeModel notice, bool isDark, int index) {
    final priorityColor = _priorityColor(notice.priority);
    final icon = _noticeIcon(notice.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
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
}

// ─── Model ───────────────────────────────────────────────────────────────

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
