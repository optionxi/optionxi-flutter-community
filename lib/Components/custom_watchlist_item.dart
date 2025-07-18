import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/custom_animated_price.dart';
import 'package:optionxi/Controllers/watchlist_controller.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/volume_formater.dart';
import 'package:optionxi/Main_Pages/act_stock_detail.dart';
import 'package:optionxi/browser_lite.dart';

class WatchlistItem extends StatefulWidget {
  final DataStockModel stock;

  const WatchlistItem({Key? key, required this.stock}) : super(key: key);

  @override
  State<WatchlistItem> createState() => _WatchlistItemState();
}

class _WatchlistItemState extends State<WatchlistItem> {
  double? previousClose;
  bool? wasUp; // null means no previous state

  @override
  void initState() {
    super.initState();
    previousClose = widget.stock.close;
  }

  @override
  void didUpdateWidget(WatchlistItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stock.close != widget.stock.close) {
      setState(() {
        wasUp = widget.stock.close > oldWidget.stock.close;
        previousClose = oldWidget.stock.close;
      });
    }
  }

  String _getActualStockSymbol(String stock) {
    for (var key in totalStocks.keys) {
      if (key.contains(stock.split(":")[1].split("-")[0])) {
        return key;
      }
    }
    return stock; // fallback if no match found
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositiveChange = widget.stock.pcnt >= 0;
    final controller = Get.find<WatchlistController>();

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showStockDialog(widget.stock, context),
            backgroundColor:
                isDark ? const Color(0xFF1E4731) : Colors.green.shade100,
            foregroundColor: isDark ? Colors.green[100] : Colors.green[800],
            icon: Icons.add_rounded,
            label: 'Info',
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          SlidableAction(
            onPressed: (context) =>
                controller.removeFromWatchlist(widget.stock),
            backgroundColor:
                isDark ? const Color(0xFF4A1F23) : Colors.red.shade100,
            foregroundColor: isDark ? Colors.red[100] : Colors.red[800],
            icon: Icons.delete_rounded,
            label: 'Remove',
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showStockDialog(widget.stock, context),
        child: stockLogo(context, isPositiveChange, isDark),
      ),
    );
  }

  Container stockLogo(
      BuildContext context, bool isPositiveChange, bool isDark) {
    final TextStyle priceTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CachedNetworkImage(
              height: 48,
              width: 48,
              imageUrl: Constants.OptionXiS3Loc +
                  widget.stock.symbol.split("-")[0].split(":")[1] +
                  ".png",
              fit: BoxFit.cover,
              placeholder: (context, url) => ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/stockdefault.png',
                  fit: BoxFit.cover,
                ),
              ),
              errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/stockdefault.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.stock.symbol
                            .toString()
                            .split(":")[1]
                            .split("-")[0],
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Replace with AnimatedPriceWidget
                      AnimatedPriceWidget(
                        price: widget.stock.close,
                        previousPrice: previousClose,
                        wasUp: wasUp,
                        style: priceTextStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.stock.stckname,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.titleSmall?.color,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPositiveChange
                              ? (isDark ? Colors.green[900] : Colors.green[50])
                              : (isDark ? Colors.red[900] : Colors.red[50]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.stock.percentChangeFormatted,
                          style: TextStyle(
                            color: isPositiveChange
                                ? (isDark
                                    ? Colors.green[100]
                                    : Colors.green[700])
                                : (isDark ? Colors.red[100] : Colors.red[700]),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  void _showStockDialog(DataStockModel stock, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextStyle priceTextStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.color
                        ?.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with Logo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      height: 48,
                      width: 48,
                      imageUrl: Constants.OptionXiS3Loc +
                          stock.symbol.split("-")[0].split(":")[1] +
                          ".png",
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/images/stockdefault.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stock.symbol
                                    .toString()
                                    .split(":")[1]
                                    .split("-")[0],
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: stock.pcnt >= 0
                                      ? (isDark
                                          ? Colors.green[900]
                                          : Colors.green[50])
                                      : (isDark
                                          ? Colors.red[900]
                                          : Colors.red[50]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stock.pcnt >= 0
                                      ? '+${(stock.pcnt).toStringAsFixed(2)}%'
                                      : '${(stock.pcnt).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: stock.pcnt >= 0
                                        ? (isDark
                                            ? Colors.green[100]
                                            : Colors.green[700])
                                        : (isDark
                                            ? Colors.red[100]
                                            : Colors.red[700]),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            stock.stckname,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.titleSmall?.color,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Price Section - Updated with AnimatedPriceWidget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Price section on the left
                    Expanded(
                      child: AnimatedPriceWidget(
                        price: widget.stock.close,
                        previousPrice: previousClose,
                        wasUp: wasUp,
                        style: priceTextStyle,
                      ),
                    ),
                    // View chart button on the right
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            // Add your TradingView chart navigation logic here
                            // Get.toNamed('/tradingview/${stock.symbol}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BrowserLite_V(
                                      "https://in.tradingview.com/chart/?symbol=NSE%3A" +
                                          stock.symbol
                                              .toString()
                                              .split("-")[0]
                                              .split(":")[1])),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.candlestick_chart_outlined,
                                  size: 16,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View Chart',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Theme.of(context).dividerColor),
              ),

              // Market Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMarketStat('Day Low',
                        '${(stock.low).toStringAsFixed(2)}', context),
                    _buildMarketStat('Day High',
                        '${(stock.high).toStringAsFixed(2)}', context),
                    _buildMarketStat(
                        'Volume', formatVolume(stock.vol), context),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 44,
                      margin: const EdgeInsets.only(
                          bottom: 16, right: 16, left: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StockDetailPage(
                                        stockname:
                                            _getActualStockSymbol(stock.symbol),
                                      )));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.white.withValues(alpha: 0.1);
                              }
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.white.withValues(alpha: 0.05);
                              }
                              return null;
                            },
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View Stock Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Bottom padding for safe area
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketStat(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleSmall?.color,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
