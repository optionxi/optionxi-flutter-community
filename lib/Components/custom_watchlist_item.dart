import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/custom_animated_price.dart';
import 'package:optionxi/Controllers/watchlist_controller.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/volume_formater.dart';
import 'package:optionxi/Main_Pages/act_stock_detail.dart';
import 'package:optionxi/VirtualTradeJournal/add_basket_page.dart';
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
        extentRatio: 0.4, // Add this to control slide distance
        children: [
          SlidableAction(
            onPressed: (context) => _showStockDialog(widget.stock, context),
            backgroundColor:
                isDark ? const Color(0xFF1E4731) : Colors.green.shade100,
            foregroundColor: isDark ? Colors.green[100] : Colors.green[800],
            icon: Icons.remove_red_eye,
            // label: 'Info',
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
            // label: 'Remove',
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: InkWell(
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
      child: Padding(
        padding: const EdgeInsets.all(8),
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
                          "Vol: " + formatVolume(widget.stock.vol),
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
                          // Text(
                          //   stock.stckname,
                          //   style: TextStyle(
                          //     color:
                          //         Theme.of(context).textTheme.titleSmall?.color,
                          //     fontSize: 14,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Price Section - Updated with AnimatedPriceWidget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedPriceWidget(
                  price: widget.stock.close,
                  previousPrice: previousClose,
                  wasUp: wasUp,
                  style: priceTextStyle,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Theme.of(context).dividerColor),
              ),

              // Quick Action Section - Chart and Details as clickable rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildActionRow(
                      context,
                      Icons.candlestick_chart_outlined,
                      'View Chart',
                      'See price trends and technical analysis',
                      isDark,
                      () {
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
                    ),
                    const SizedBox(height: 4),
                    _buildActionRow(
                      context,
                      Icons.analytics_outlined,
                      'Stock Details',
                      'View comprehensive stock information',
                      isDark,
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StockDetailPage(
                                      stockname:
                                          _getActualStockSymbol(stock.symbol),
                                    )));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

              // Prominent Action Button - Add to Virtual Basket
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    addToVirtualJournal(context, stock, theme),
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

  Container addToVirtualJournal(
      BuildContext context, DataStockModel stock, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Add haptic feedback for better UX
            HapticFeedback.lightImpact();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddToBasketPage(stock: stock),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated basket icon with modern styling
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Main text with improved typography
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Virtual Basket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Track performance virtually',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Modern arrow with subtle animation hint
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.titleSmall?.color,
              ),
            ],
          ),
        ),
      ),
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
