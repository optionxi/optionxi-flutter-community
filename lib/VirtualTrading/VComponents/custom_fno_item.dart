import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/custom_animated_price.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnodata.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnoitem.dart';
import 'package:optionxi/VirtualTrading/act_buyandsell_prev.dart';

class FNOItem extends StatefulWidget {
  final dynamic stock; // Can be DataStockModel or DataFNOModel
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
  late AnimationController _containerPulseController;
  late Animation<double> _containerScaleAnimation;
  Animation<Color?>? _containerColorAnimation;

  double? previousPrice;
  bool? wasUp;

  @override
  void initState() {
    super.initState();

    // Initialize container pulse animation
    _containerPulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _containerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _containerPulseController,
      curve: Curves.easeInOut,
    ));

    // Set initial price
    if (widget.type.isStock) {
      final stockData = widget.stock as DataStockModel;
      previousPrice = stockData.close;
    } else {
      final optionData = widget.stock as DataFNOModel;
      previousPrice = optionData.ltp;
    }
  }

  @override
  void didUpdateWidget(FNOItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    double currentPrice;
    double oldPrice;

    if (widget.type.isStock) {
      final stockData = widget.stock as DataStockModel;
      final oldStockData = oldWidget.stock as DataStockModel;
      currentPrice = stockData.close;
      oldPrice = oldStockData.close;
    } else {
      final optionData = widget.stock as DataFNOModel;
      final oldOptionData = oldWidget.stock as DataFNOModel;
      currentPrice = optionData.ltp;
      oldPrice = oldOptionData.ltp;
    }

    if (currentPrice != oldPrice) {
      setState(() {
        wasUp = currentPrice > oldPrice;
        previousPrice = oldPrice;
      });
      _triggerContainerPulse();
    }
  }

  void _triggerContainerPulse() {
    final theme = Theme.of(context);
    final bool isPriceUp = wasUp ?? false;

    // Setup container color animation
    _containerColorAnimation = ColorTween(
      begin: theme.cardColor,
      end: isPriceUp
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _containerPulseController,
      curve: Curves.easeInOut,
    ));

    _containerPulseController.forward().then((_) {
      _containerPulseController.reverse();
    });
  }

  @override
  void dispose() {
    _containerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _containerPulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _containerScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _containerColorAnimation?.value ??
                  Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                // Add extra glow during animation
                if (_containerPulseController.isAnimating)
                  BoxShadow(
                    color: (wasUp ?? false ? Colors.green : Colors.red)
                        .withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: InkWell(
              onTap: () => _onTap(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.type.isStock
                    ? _buildStockItem(context)
                    : _buildOptionItem(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockItem(BuildContext context) {
    final stockData = widget.stock as DataStockModel;
    final isPositive = stockData.pcnt >= 0;

    return Row(
      children: [
        // Stock Icon with pulsating effect
        // AnimatedBuilder(
        //   animation: _containerPulseController,
        //   builder: (context, child) {
        //     return Container(
        //       width: 48,
        //       height: 48,
        //       decoration: BoxDecoration(
        //         color: isPositive
        //             ? Colors.green.withOpacity(
        //                 _containerPulseController.isAnimating ? 0.2 : 0.1)
        //             : Colors.red.withOpacity(
        //                 _containerPulseController.isAnimating ? 0.2 : 0.1),
        //         borderRadius: BorderRadius.circular(12),
        //         border: Border.all(
        //           color: isPositive
        //               ? Colors.green.withOpacity(
        //                   _containerPulseController.isAnimating ? 0.4 : 0.2)
        //               : Colors.red.withOpacity(
        //                   _containerPulseController.isAnimating ? 0.4 : 0.2),
        //           width: 1,
        //         ),
        //       ),
        //       child: Icon(
        //         Icons.trending_up,
        //         color: isPositive ? Colors.green : Colors.red,
        //         size: 24,
        //       ),
        //     );
        //   },
        // ),

        Container(
          height: 48,
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/images/stockdefault.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Stock Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stockData.symbol,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Use AnimatedPriceWidget for pulsating price
                  AnimatedPriceWidget(
                    price: stockData.close,
                    previousPrice: previousPrice,
                    wasUp: wasUp,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stockData.stckname.isNotEmpty
                          ? stockData.stckname
                          : stockData.symbol,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _containerPulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(
                                  _containerPulseController.isAnimating
                                      ? 0.2
                                      : 0.1)
                              : Colors.red.withOpacity(
                                  _containerPulseController.isAnimating
                                      ? 0.2
                                      : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${stockData.pcnt.toStringAsFixed(2)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(BuildContext context) {
    final optionData = widget.stock as DataFNOModel;
    final isPositive = optionData.pcnt >= 0;

    return Column(
      children: [
        Row(
          children: [
            // Option Type Badge with pulsating effect
            AnimatedBuilder(
              animation: _containerPulseController,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.type.isCall
                        ? Colors.blue.withOpacity(
                            _containerPulseController.isAnimating ? 0.2 : 0.1)
                        : Colors.orange.withOpacity(
                            _containerPulseController.isAnimating ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.type.isCall
                          ? Colors.blue.withOpacity(
                              _containerPulseController.isAnimating ? 0.4 : 0.2)
                          : Colors.orange.withOpacity(
                              _containerPulseController.isAnimating
                                  ? 0.4
                                  : 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.type.shortName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.type.isCall ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),

            // Option Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          optionData.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Use AnimatedPriceWidget for pulsating price
                      AnimatedPriceWidget(
                        price: optionData.ltp,
                        previousPrice: previousPrice,
                        wasUp: wasUp,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Strike: ${optionData.strikePrice.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.titleSmall?.color,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _containerPulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withOpacity(
                                      _containerPulseController.isAnimating
                                          ? 0.2
                                          : 0.1)
                                  : Colors.red.withOpacity(
                                      _containerPulseController.isAnimating
                                          ? 0.2
                                          : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              optionData.formattedPercentage,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Option Stats Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Open',
                '₹${optionData.o.toStringAsFixed(2)}',
              ),
              _buildStatItem(
                context,
                'High',
                '₹${optionData.h.toStringAsFixed(2)}',
              ),
              _buildStatItem(
                context,
                'Low',
                '₹${optionData.l.toStringAsFixed(2)}',
              ),
              _buildStatItem(
                context,
                'Volume',
                _formatVolume(optionData.v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Theme.of(context).textTheme.titleSmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  void _onTap(BuildContext context) {
    // Handle tap - navigate to details or add to watchlist
    if (widget.type.isStock) {
      final stockData = widget.stock as DataStockModel;
      print('Tapped on stock: ${stockData.symbol}');
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BuyandSellPagePrev(stockData.symbol, "EQ", false)),
      );
    } else {
      final optionData = widget.stock as DataFNOModel;
      print('Tapped on option: ${optionData.symbol}');
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BuyandSellPagePrev(optionData.symbol, "FNO", false)),
      );
    }
  }
}
