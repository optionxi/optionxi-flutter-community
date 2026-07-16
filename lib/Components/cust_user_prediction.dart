import 'package:flutter/material.dart';

class StockAnalysisCard extends StatelessWidget {
  final String symbol;
  final String analysis;
  final double movement;
  final double supportLevel;
  final double resistanceLevel;
  final double entryPoint;
  final String sentiment;
  final String userName;
  final String profilePicUrl;
  final String time;
  final String timeAgo;
  final String userCategory;
  final VoidCallback onTap;

  const StockAnalysisCard({
    Key? key,
    required this.symbol,
    required this.analysis,
    required this.movement,
    required this.supportLevel,
    required this.resistanceLevel,
    required this.entryPoint,
    required this.sentiment,
    required this.userName,
    required this.profilePicUrl,
    required this.time,
    required this.timeAgo,
    required this.userCategory,
    required this.onTap,
  }) : super(key: key);

  Color _getSentimentColor(BuildContext context) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'bearish':
        return Colors.red;
      case 'neutral':
        return Colors.amber;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentimentColor = _getSentimentColor(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: sentimentColor,
                  width: 4,
                ),
              ),
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
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          '$timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.titleSmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: userCategory == 'Elite'
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userCategory,
                        style: TextStyle(
                          color: userCategory == 'Elite'
                              ? Colors.amber
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stock Info Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          symbol,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sentiment.toLowerCase() == 'bullish'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sentiment,
                            style: TextStyle(
                              color: sentimentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: movement >= 0
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            movement >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: movement >= 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movement.abs()}%',
                            style: TextStyle(
                              color: movement >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  analysis,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildLevelRow(context, 'Support', supportLevel),
                      const SizedBox(height: 12),
                      _buildLevelRow(context, 'Resistance', resistanceLevel),
                      const SizedBox(height: 12),
                      _buildLevelRow(context, 'Entry Point', entryPoint),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.show_chart,
                        color: sentimentColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'View Chart',
                      style: TextStyle(
                        color: sentimentColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow(BuildContext context, String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
