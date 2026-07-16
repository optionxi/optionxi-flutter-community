import 'package:flutter/material.dart';

class StrategyCard extends StatelessWidget {
  final String name;
  final String description;
  final String winRate;
  final Color accentColor;
  final String userName;
  final String profilePicUrl;
  final String time;
  final String timeAgo;
  final String userCategory;

  const StrategyCard({
    Key? key,
    required this.name,
    required this.description,
    required this.winRate,
    required this.accentColor,
    required this.userName,
    required this.profilePicUrl,
    required this.time,
    required this.timeAgo,
    required this.userCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access current theme data
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(profilePicUrl),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '$timeAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: userCategory == 'Elite'
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userCategory,
                  style: TextStyle(
                    color: userCategory == 'Elite' ? Colors.amber : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Strategy Info Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  winRate,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.show_chart, color: accentColor),
              const SizedBox(width: 8),
              Text(
                "View Details",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
