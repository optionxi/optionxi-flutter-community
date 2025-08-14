import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';

import 'trending_stocks_section.dart';

class ModernStockCard extends StatelessWidget {
  final StockData stock;

  const ModernStockCard({Key? key, required this.stock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildModernStockCard(context);
  }

  Widget _buildModernStockCard(BuildContext context) {
    final bool isBullish =
        stock.sentiment == 'BULLISH' || stock.sentiment == 'BULL';
    final Color sentimentColor =
        isBullish ? const Color(0xFF00C896) : const Color(0xFFFF3B30);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double changePercentage = stock.pcnt;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed('/stocks/${stock.symbol.toUpperCase()}'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCardHeader(context, sentimentColor, isDark),
                const SizedBox(height: 20),
                _buildPriceSection(context, sentimentColor, changePercentage),
                const SizedBox(height: 20),
                _buildMetricsRow(context, isDark),
                const SizedBox(height: 16),
                // _buildSignalChips(context, sentimentColor, isDark),
                _buildActionButtons(context, sentimentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, Color sentimentColor, bool isDark) {
    return Row(
      children: [
        // Stock Logo with modern styling
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl:
                  '${Constants.OptionXiS3Loc}${stock.symbol.replaceAll('-EQ', '').replaceAll('NSE:', '')}.png',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sentimentColor.withOpacity(0.1),
                      sentimentColor.withOpacity(0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: sentimentColor,
                  size: 28,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sentimentColor.withOpacity(0.1),
                      sentimentColor.withOpacity(0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: sentimentColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Stock Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.symbol.replaceAll('-EQ', '').replaceAll('NSE:', ''),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                stock.shortDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 14,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Sentiment Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sentimentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: sentimentColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stock.pcnt < 0 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                stock.sentiment,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(
      BuildContext context, Color sentimentColor, double changePercentage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${stock.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: -1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sentimentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                changePercentage >= 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: sentimentColor,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '${changePercentage.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  color: sentimentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (stock.sector != 'N/A') ...[
            Expanded(
                child: _buildMetricItem(
                    context, 'Sector', stock.sector, Icons.business)),
            _buildVerticalDivider(context),
          ],
          Expanded(
              child: _buildMetricItem(
                  context, 'Risk', stock.riskLevel, Icons.shield_outlined)),
          _buildVerticalDivider(context),
          Expanded(
              child: _buildMetricItem(context, 'Signal', stock.signalStrength,
                  Icons.signal_cellular_alt)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color sentimentColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                Get.toNamed('/stocks/${stock.symbol.toUpperCase()}'),
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('View Analysis',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: sentimentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: sentimentColor.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
