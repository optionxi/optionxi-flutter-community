import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';

class SectorStocksPage extends StatelessWidget {
  final String sectorName;
  final List<StockData> stocks;

  const SectorStocksPage({
    Key? key,
    required this.sectorName,
    required this.stocks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ??
            (isDark ? const Color(0xFF1A1A1B) : Colors.white),
        title: Text(
          sectorName,
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor ??
                (isDark ? Colors.white : Colors.black),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor ??
                (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Get.back(),
        ),
        elevation: isDark ? 0 : 1,
      ),
      body: _buildStocksList(context),
    );
  }

  Widget _buildStocksList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (stocks.isEmpty) {
      return Center(
        child: Text(
          'No stocks found for this sector',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                (isDark ? Colors.grey : Colors.grey[600]),
            fontSize: 16,
          ),
        ),
      );
    }

    // Sort stocks by performance
    stocks.sort((a, b) => b.pcnt.compareTo(a.pcnt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final isPositive = stock.pcnt > 0;

        // Theme-aware colors
        final cardColor = isDark ? const Color(0xFF1A1A1B) : theme.cardColor;
        final primaryTextColor = theme.textTheme.bodyLarge?.color ??
            (isDark ? Colors.white : Colors.black);
        final secondaryTextColor =
            theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                (isDark ? Colors.grey : Colors.grey[600]);

        // Stock performance colors
        final positiveColor = isDark ? const Color(0xFF00FF88) : Colors.green;
        final negativeColor = isDark ? const Color(0xFFFF4444) : Colors.red;
        final performanceColor = isPositive ? positiveColor : negativeColor;

        return InkWell(
          onTap: () {
            Get.toNamed('/stocks/${(stock.stckname.toUpperCase())}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: performanceColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Stock icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    height: 48,
                    width: 48,
                    imageUrl: Constants.OptionXiS3Loc +
                        stock.stckname.split("-")[0].split(":")[1] +
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.stckname.split("-")[0].split(":")[1],
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'High: ₹${stock.high.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Low: ₹${stock.low.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${stock.close.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: performanceColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${stock.pcnt > 0 ? '+' : ''}${stock.pcnt.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: performanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Add these classes to a separate file if they're not already
class StockData {
  final String stckname;
  final double pcnt;
  final double close;
  final double high;
  final double low;
  final double open;
  final int vol;
  final String? sector;
  final double? rsi14;
  final double? ema20;
  final double? sma20;

  StockData({
    required this.stckname,
    required this.pcnt,
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.vol,
    this.sector,
    this.rsi14,
    this.ema20,
    this.sma20,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      stckname: json['stckname'] as String,
      pcnt: (json['pcnt'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      vol: json['vol'] as int,
      sector: json['sec'] as String?,
      rsi14: json['rsi14'] != null ? (json['rsi14'] as num).toDouble() : null,
      ema20: json['ema20'] != null ? (json['ema20'] as num).toDouble() : null,
      sma20: json['sma20'] != null ? (json['sma20'] as num).toDouble() : null,
    );
  }
}
