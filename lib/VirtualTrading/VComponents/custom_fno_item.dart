import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/cust_animated_price.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnodata.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnoitem.dart';
import 'package:optionxi/VirtualTrading/act_buyandsell_prev.dart';

class FNOItem extends StatefulWidget {
  final dynamic stock;
  final FNOItemType type;

  const FNOItem({
    Key? key,
    required this.stock,
    required this.type,
  }) : super(key: key);

  @override
  State<FNOItem> createState() => _FNOItemState();
}

class _FNOItemState extends State<FNOItem> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  double? previousPrice;
  bool? wasUp;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.18), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.012), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.012, end: 1.0), weight: 65),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _initPrice();
  }

  void _initPrice() {
    if (widget.type.isStock) {
      previousPrice = (widget.stock as DataStockModel).close;
    } else {
      previousPrice = (widget.stock as DataFNOModel).ltp;
    }
  }

  @override
  void didUpdateWidget(FNOItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    double currentPrice;
    double oldPrice;

    if (widget.type.isStock) {
      currentPrice = (widget.stock as DataStockModel).close;
      oldPrice = (oldWidget.stock as DataStockModel).close;
    } else {
      currentPrice = (widget.stock as DataFNOModel).ltp;
      oldPrice = (oldWidget.stock as DataFNOModel).ltp;
    }

    if (currentPrice != oldPrice) {
      setState(() {
        wasUp = currentPrice > oldPrice;
        previousPrice = oldPrice;
      });
      _flashController.forward(from: 0);
      _scaleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color get _flashColor =>
      wasUp == true ? const Color(0xFF00C853) : const Color(0xFFFF3D57);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flashController, _scaleController]),
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              _buildCard(context),
              if (_flashController.isAnimating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _flashColor.withOpacity(_flashOpacity.value),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1,
        ),
        color: isDark ? const Color(0xFF0F1117) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: widget.type.isStock
                ? _buildStockItem(context)
                : _buildOptionItem(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAccentBar(bool isPositive) {
    return Container(
      width: 3,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPositive
              ? [const Color(0xFF00E676), const Color(0xFF00C853)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFF3D57)],
        ),
      ),
    );
  }

  Widget _buildStockItem(BuildContext context) {
    final stockData = widget.stock as DataStockModel;
    final isPositive = stockData.pcnt >= 0;
    final pctColor =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3D57);

    return Row(
      children: [
        _buildAccentBar(isPositive),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stockData.symbol,
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                stockData.stckname.isNotEmpty
                    ? stockData.stckname
                    : stockData.symbol,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.color
                      ?.withOpacity(0.55),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedPriceWidget(
              price: stockData.close,
              previousPrice: previousPrice,
              wasUp: wasUp,
              style: GoogleFonts.dmMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 5),
            _buildPctBadge(
              '${isPositive ? '+' : ''}${stockData.pcnt.toStringAsFixed(2)}%',
              pctColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionItem(BuildContext context) {
    final optionData = widget.stock as DataFNOModel;
    final isPositive = optionData.pcnt >= 0;
    final pctColor =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3D57);

    return Row(
      children: [
        _buildAccentBar(isPositive),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                optionData.displayName,
                style: GoogleFonts.dmMono(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'Strike  ${optionData.strikePrice.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.color
                      ?.withOpacity(0.55),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedPriceWidget(
              price: optionData.ltp,
              previousPrice: previousPrice,
              wasUp: wasUp,
              style: GoogleFonts.dmMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 5),
            _buildPctBadge(optionData.formattedPercentage, pctColor),
          ],
        ),
      ],
    );
  }

  Widget _buildPctBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmMono(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (widget.type.isStock) {
      final stockData = widget.stock as DataStockModel;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BuyandSellPagePrev(stockData.symbol, "EQ", false),
        ),
      );
    } else {
      final optionData = widget.stock as DataFNOModel;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BuyandSellPagePrev(optionData.symbol, "FNO", false),
        ),
      );
    }
  }
}
