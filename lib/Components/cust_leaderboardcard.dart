import 'dart:ui';
import 'package:flutter/material.dart';

class ModernLeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index;
  final AnimationController controller;

  const ModernLeaderboardCard({
    Key? key,
    required this.entry,
    required this.index,
    required this.controller,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Interval(
          0.05 * index,
          0.05 * index + 0.8,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), // Slide in from the right
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.05 * index,
              0.05 * index + 0.8,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * controller.value),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildRank(),
                        const SizedBox(width: 16),
                        _buildAvatar(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildUserInfo(),
                        ),
                        _buildPoints(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRank() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRankGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getRankGradient().first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#${entry.rank}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade400.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          entry.imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.username,
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Member',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPoints() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${entry.points}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  List<Color> _getRankGradient() {
    switch (entry.rank) {
      case 1:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFA000),
        ];
      case 2:
        return [
          const Color(0xFFC0C0C0),
          const Color(0xFF9E9E9E),
        ];
      case 3:
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFB56324),
        ];
      default:
        return [
          Colors.blue.shade400,
          Colors.blue.shade600,
        ];
    }
  }
}

class LeaderboardEntry {
  final String username;
  final String imageUrl;
  final int points;
  final int rank;
  final int level;

  LeaderboardEntry({
    required this.username,
    required this.imageUrl,
    required this.points,
    required this.rank,
    required this.level,
  });
}
