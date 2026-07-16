import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_animated_price.dart';
import 'package:optionxi/Controllers/watchlist_controller.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/volume_formater.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/act_buy_sell_live_fyers.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/act_buy_sell_live_upstox.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/act_buy_sell_live_zerodha.dart';
import 'package:optionxi/Main_Pages/StockPages/act_stock_detail.dart';
import 'package:optionxi/Helpers/browser_lite.dart';

class WatchlistItemBroker extends StatefulWidget {
  final DataStockModel stock;
  final String whichbroker;

  const WatchlistItemBroker(
      {Key? key, required this.stock, required this.whichbroker})
      : super(key: key);

  @override
  State<WatchlistItemBroker> createState() => _WatchlistItemBrokerState();
}

class _WatchlistItemBrokerState extends State<WatchlistItemBroker> {
  double? previousClose;
  bool? wasUp;

  @override
  void initState() {
    super.initState();
    previousClose = widget.stock.close;
  }

  @override
  void didUpdateWidget(WatchlistItemBroker oldWidget) {
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
    return stock;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositiveChange = widget.stock.pcnt >= 0;
    final controller = Get.find<WatchlistController>();

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (context) => _showStockDialog(widget.stock, context),
            backgroundColor:
                isDark ? const Color(0xFF1E4731) : Colors.green.shade100,
            foregroundColor: isDark ? Colors.green[100] : Colors.green[800],
            icon: Icons.remove_red_eye,
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

  Widget stockLogo(BuildContext context, bool isPositiveChange, bool isDark) {
    final TextStyle priceTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(12),
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
              child: Image.asset('assets/images/stockdefault.png',
                  fit: BoxFit.cover),
            ),
            errorWidget: (context, url, error) => ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset('assets/images/stockdefault.png',
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.stock.symbol.split(":")[1].split("-")[0],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        "Vol: ${formatVolume(widget.stock.vol)}",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleSmall?.color,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                              ? (isDark ? Colors.green[100] : Colors.green[700])
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
    );
  }

  void _showStockDialog(DataStockModel stock, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/stockdefault.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.symbol.split(":")[1].split("-")[0],
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          Text(stock.stckname,
                              style: TextStyle(
                                  color: theme.textTheme.titleSmall?.color)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedPriceWidget(
                  price: widget.stock.close,
                  previousPrice: previousClose,
                  wasUp: wasUp,
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              _buildActionRow(context, Icons.candlestick_chart_outlined,
                  'View Chart', 'Technical analysis', isDark, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BrowserLite_V(
                            "https://in.tradingview.com/chart/?symbol=NSE%3A${stock.symbol.split("-")[0].split(":")[1]}")));
              }),
              _buildActionRow(context, Icons.analytics_outlined,
                  'Stock Details', 'Comprehensive info', isDark, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StockDetailPage(
                            stockname: _getActualStockSymbol(stock.symbol))));
              }),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMarketStat(
                        'Day Low', stock.low.toStringAsFixed(2), context),
                    _buildMarketStat(
                        'Day High', stock.high.toStringAsFixed(2), context),
                    _buildMarketStat(
                        'Volume', formatVolume(stock.vol), context),
                  ],
                ),
              ),
              addToVirtualJournal(context, stock, theme),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget addToVirtualJournal(
      BuildContext context, DataStockModel stock, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTradeButton(
              context: context,
              label: 'BUY',
              color: Colors.green,
              onTap: () => _navigateToOrder(
                context,
                stock,
                'BUY',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTradeButton(
              context: context,
              label: 'SELL',
              color: Colors.red,
              onTap: () => _navigateToOrder(context, stock, 'SELL'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButton(
      {required BuildContext context,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _navigateToOrder(
      BuildContext context, DataStockModel stock, String side) {
    HapticFeedback.mediumImpact();

    bool toSell = side == "BUY" ? false : true;
    String cleanedName = stock.symbol.split(':').last.split('-').first;
    if (widget.whichbroker == "Zerodha") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZerodhaOrderPage(
            stockname: cleanedName,
            tosell: toSell,
            segment: "NSE",
          ),
        ),
      );
    }

    if (widget.whichbroker == "Upstox") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpstoxOrderPage(
            stockname: cleanedName,
            tosell: toSell,
            segment: "NSE",
          ),
        ),
      );
    }

    if (widget.whichbroker == "Fyers") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FyersOrderPage(
            stockname: cleanedName,
            tosell: toSell,
            segment: "NSE",
          ),
        ),
      );
    }
  }

  Widget _buildActionRow(BuildContext context, IconData icon, String title,
      String subtitle, bool isDark, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildMarketStat(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).textTheme.titleSmall?.color,
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
