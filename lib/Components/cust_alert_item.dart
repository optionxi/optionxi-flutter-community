import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/StockPages/act_alert_stocks.dart';
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

  Widget _buildAlertItem(AlertModel alert, int index) {
    // Determine styles based on sentiment
    final isBullish = alert.sentiment == 'bullish';

    // Core color for the sleek vertical bar
    final Color barColor = isBullish ? Colors.green : Colors.red;

    // Background color for the card: subtle tint in light mode, cardColor in dark mode
    final Color cardBackgroundColor =
        Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : barColor.withOpacity(0.05);

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
        margin: const EdgeInsets.only(bottom: 12), // Compressed margin
        decoration: BoxDecoration(
          // Use the new subtle background color, replacing the old bgColor/borderColor
          color: cardBackgroundColor,
          // Removed: border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // Main Alert Content
              // Main Alert Content
              InkWell(
                borderRadius: BorderRadius.circular(12),
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
                // 1. Wrap Row in IntrinsicHeight to force children to same height
                child: IntrinsicHeight(
                  child: Row(
                    // 2. Stretch children vertically to fill the IntrinsicHeight
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3. Sleek Color Bar on the Left
                      Container(
                        width: 4,
                        // REMOVED: height: 80,  <-- Removed fixed height
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),

                      // 4. The rest of the content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stock Logo
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    height: 40,
                                    width: 40,
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
                              const SizedBox(width: 12),
                              // Alert Content Text Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ... (Rest of your text/content code remains exact same) ...
                                    // Header Row: Symbol (Left) vs Price (Right)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displaySymbol,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (alert.close != null)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${alert.close!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              if (alert.pcnt != null)
                                                Text(
                                                  '${alert.pcnt! >= 0 ? '+' : ''}${alert.pcnt!.toStringAsFixed(2)}%',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: alert.pcnt! >= 0
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.description,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.8),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${DateFormat('hh:mm a').format(alertDatetime)} • ${timeago.format(alertDatetime)}",
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.6),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (hasDetailedData)
                                          AnimatedRotation(
                                            turns: _isExpanded ? 0.5 : 0,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            child: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.5),
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
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
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

    // Change from Previous Alert
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
  final AlertModel? prevAlert;
  final int index;

  const AlertItem(
      {Key? key, required this.alert, this.prevAlert, required this.index})
      : super(key: key);

  @override
  _AlertItemState createState() => _AlertItemState();
}
