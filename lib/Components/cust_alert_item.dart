import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Colors_Text_Components/colors.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_alert_stocks.dart';
import 'package:timeago/timeago.dart' as timeago;

class _AlertItemState extends State<AlertItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  // Helper widget for creating styled price info chips
  Widget _buildPriceChip(String text, Color textColor, Color bgColor,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // if (icon != null) Icon(icon, size: 12, color: textColor),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AlertModel alert, int index) {
    // Determine styles based on sentiment
    final isBullish = alert.sentiment == 'bullish';
    final Color borderColor =
        isBullish ? Colors.green.shade200 : Colors.red.shade200;
    final Color bgColor = isBullish ? Colors.green.shade50 : Colors.red.shade50;
    final Color tagColor =
        isBullish ? Colors.green.shade700 : Colors.red.shade700;
    final Color tagBgColor =
        isBullish ? Colors.green.shade100 : Colors.red.shade100;

    final DateTime alertDatetime = DateTime.parse(alert.createdAt).toLocal();

    // Get full stock name if available
    String displaySymbol = alert.symbol ?? 'Market Alert';
    if (alert.symbol != null && totalStocks.containsKey(alert.symbol)) {
      displaySymbol =
          totalStocks[alert.symbol]?['full_stock_name'] ?? alert.symbol!;
    }

    // Check if we have detailed stock data
    final hasDetailedData = alert.close != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // Main Alert Content
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (hasDetailedData) {
                    setState(() {
                      _isExpanded = !_isExpanded;
                      if (_isExpanded) {
                        _expandController.forward();
                      } else {
                        _expandController.reverse();
                      }
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Logo, Title, Description
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stock Logo
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                height: 48,
                                width: 48,
                                imageUrl:
                                    "${Constants.OptionXiS3Loc}${alert.symbol}.png",
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Image.asset(
                                  'assets/images/stockdefault.png',
                                  fit: BoxFit.cover,
                                ),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/images/stockdefault.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Alert Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Sentiment Tag
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displaySymbol,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (alert.sentiment != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: tagBgColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          alert.sentiment!.toUpperCase(),
                                          style: TextStyle(
                                            color: tagColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Description
                                Text(
                                  alert.description,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  maxLines:
                                      2, // Reduced max lines for compactness
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // **NEW**: Price Info Section (Sleek Design)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          // Close price
                          if (alert.close != null)
                            _buildPriceChip(
                              '₹${alert.close!.toStringAsFixed(2)}',
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                            ),

                          // Percentage Change
                          if (alert.pcnt != null)
                            _buildPriceChip(
                              '${alert.pcnt! >= 0 ? '+' : ''}${alert.pcnt!.toStringAsFixed(2)}%',
                              alert.pcnt! >= 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              alert.pcnt! >= 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              icon: alert.pcnt! >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                            ),

                          // **NEW**: Change From Previous Alert
                          if (widget.prevAlert != null &&
                              widget.prevAlert!.close != null &&
                              alert.close != null)
                            Builder(builder: (context) {
                              final prevClose = widget.prevAlert!.close!;
                              final change = alert.close! - prevClose;
                              if (change == 0)
                                return const SizedBox
                                    .shrink(); // Hide if no change

                              final bool isUp = change > 0;
                              return _buildPriceChip(
                                '${isUp ? '+' : ''}₹${change.toStringAsFixed(2)}',
                                isUp
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                isUp
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                icon: isUp
                                    ? Icons.change_history_rounded
                                    : Icons.change_history_rounded,
                              );
                            }),

                          // Yesterday Day high, Day low
                          if (alert.pcnt != null)
                            if (((alert.high ?? 0) >=
                                        (alert.prevDayHigh ?? 0)) &&
                                    (alert.pcnt ?? 0) >= 0 ||
                                (alert.low ?? 0) <= (alert.prevDayLow ?? 0) &&
                                    (alert.pcnt ?? 0) <= 0)
                              _buildPriceChip(
                                (alert.high ?? 0) >= (alert.prevDayHigh ?? 0)
                                    ? 'High Breakout'
                                    : "Low Breakout",
                                alert.pcnt! >= 0
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                alert.pcnt! >= 0
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                icon: alert.pcnt! >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                              ),
                          // Volume Breakout
                          if (alert.pcnt != null &&
                              alert.volume != null &&
                              alert.sma5Volume != null)
                            if ((alert.volume ?? 0) >=
                                2 * (alert.sma5Volume ?? 0))
                              _buildPriceChip(
                                'Volume Breakout',
                                alert.pcnt! >= 0
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                alert.pcnt! >= 0
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                icon: alert.pcnt! >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                              ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // **NEW**: Time Info Section
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${DateFormat('hh:mm a').format(alertDatetime)} • ${timeago.format(alertDatetime)}",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action Row
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            // Expand/collapse button
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: hasDetailedData
                                      ? () {
                                          setState(() {
                                            _isExpanded = !_isExpanded;
                                            if (_isExpanded) {
                                              _expandController.forward();
                                            } else {
                                              _expandController.reverse();
                                            }
                                          });
                                        }
                                      : null, // Disabled when no data
                                  icon: AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  label: Text(
                                    hasDetailedData
                                        ? (_isExpanded
                                            ? 'Show Less'
                                            : 'Show More')
                                        : 'No Data',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: hasDetailedData
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.6),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(
                                              hasDetailedData ? 0.3 : 0.2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Navigate Button
                            if (alert.symbol != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    String? fullKey;
                                    totalStocks.forEach((key, value) {
                                      if (key.contains(alert.symbol!)) {
                                        fullKey = key;
                                      }
                                    });

                                    if (fullKey != null) {
                                      Get.toNamed(
                                          '/stocks/${fullKey!.toUpperCase()}');
                                    }
                                  },
                                  icon: const Icon(Icons.trending_up_rounded,
                                      size: 16),
                                  label: const Text(
                                    'View Stock',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable Details Section
              if (hasDetailedData)
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Indicators
                          _buildProgressIndicators(alert),
                          const SizedBox(height: 16),
                          // Additional Info Cards
                          _buildInfoCards(alert),
                          const SizedBox(height: 16),
                          // Volume Section
                          if (alert.volume != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade800.withOpacity(0.3)
                                    : Colors.grey.shade100.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Volume',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatVolume(alert.volume!),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (alert.sma5Volume != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Avg Volume (5D)',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatVolume(alert.sma5Volume!),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators(AlertModel alert) {
    return Column(
      children: [
        // Day Range Progress Bar
        if (alert.high != null && alert.low != null && alert.close != null)
          _buildProgressBar(
            'Day Range',
            alert.low!,
            alert.high!,
            alert.close!,
            '₹${alert.low!.toStringAsFixed(2)}',
            '₹${alert.high!.toStringAsFixed(2)}',
          ),

        const SizedBox(height: 12),

        // 52 Week Range Progress Bar
        if (alert.week52High != null &&
            alert.week52Low != null &&
            alert.close != null)
          _buildProgressBar(
            '52 Week Range',
            alert.week52Low!,
            alert.week52High!,
            alert.close!,
            '₹${alert.week52Low!.toStringAsFixed(2)}',
            '₹${alert.week52High!.toStringAsFixed(2)}',
          ),
      ],
    );
  }

  Widget _buildProgressBar(
    String title,
    double min,
    double max,
    double current,
    String minLabel,
    String maxLabel,
  ) {
    final range = max - min;
    final position = range > 0 ? (current - min) / range : 0.0;
    final clampedPosition = position.clamp(0.0, 1.0);

    // Determine position status and color
    String positionText;
    final Color color;
    if (clampedPosition <= 0.2) {
      positionText = 'Near Low';
      color = Colors.red.shade400;
    } else if (clampedPosition >= 0.8) {
      positionText = 'Near High';
      color = Colors.green.shade400;
    } else {
      positionText = 'Mid Range';
      color = Colors.blue.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${current.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bar Background
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress Fill
                FractionallySizedBox(
                  widthFactor: clampedPosition,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Current Position Indicator (using Alignment for correct positioning)
                Align(
                  alignment: Alignment(clampedPosition * 2 - 1, 0),
                  child: Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.7), width: 1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  positionText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(AlertModel alert) {
    List<Widget> cards = [];

    // **NEW**: Change from Previous Alert
    if (widget.prevAlert != null &&
        widget.prevAlert!.close != null &&
        alert.close != null) {
      final prevClose = widget.prevAlert!.close!;
      final change = alert.close! - prevClose;
      final changePercent = (change / prevClose) * 100;

      cards.add(
        _buildInfoCard(
          'Change From Prev. Alert',
          '${change >= 0 ? '+' : ''}₹${change.toStringAsFixed(2)}',
          '${changePercent.toStringAsFixed(2)}% vs ₹${prevClose.toStringAsFixed(2)}',
          change >= 0 ? Colors.green : Colors.red,
        ),
      );
    }

    // Previous Close vs Current
    if (alert.prevClose != null && alert.close != null) {
      final change = alert.close! - alert.prevClose!;
      final changePercent = (change / alert.prevClose!) * 100;

      cards.add(
        _buildInfoCard(
          'vs Previous Close',
          '₹${alert.prevClose!.toStringAsFixed(2)}',
          '${change >= 0 ? '+' : ''}₹${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
          change >= 0 ? Colors.green : Colors.red,
        ),
      );
    }

    // Opening Price
    if (alert.open != null) {
      cards.add(
        _buildInfoCard(
          'Opening Price',
          '₹${alert.open!.toStringAsFixed(2)}',
          alert.close != null
              ? '${alert.close! > alert.open! ? '+' : ''}₹${(alert.close! - alert.open!).toStringAsFixed(2)} from open'
              : 'Current session',
          alert.close != null
              ? (alert.close! > alert.open! ? Colors.green : Colors.red)
              : Colors.blue,
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: cards
          .map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: card,
              ))
          .toList(),
    );
  }

  Widget _buildInfoCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return _buildAlertItem(widget.alert, widget.index);
  }
}

class AlertItem extends StatefulWidget {
  final AlertModel alert;
  final AlertModel? prevAlert; // <-- ADD THIS
  final int index;

  const AlertItem(
      {Key? key,
      required this.alert,
      this.prevAlert, // <-- ADD THIS
      required this.index})
      : super(key: key);

  @override
  _AlertItemState createState() => _AlertItemState();
}
