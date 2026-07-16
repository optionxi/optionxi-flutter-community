import 'package:flutter/material.dart';

class AnimatedPriceWidget extends StatefulWidget {
  final double price;
  final double? previousPrice;
  final bool? wasUp;
  final TextStyle? style;
  final String prefix;

  const AnimatedPriceWidget({
    Key? key,
    required this.price,
    this.previousPrice,
    this.wasUp,
    this.style,
    this.prefix = '₹',
  }) : super(key: key);

  @override
  State<AnimatedPriceWidget> createState() => _AnimatedPriceWidgetState();
}

class _AnimatedPriceWidgetState extends State<AnimatedPriceWidget>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _textColorAnimation;
  late Animation<double> _pulseAnimation;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();

    // Background fade controller (longer animation)
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse controller (faster blinking)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      // Use a curve that goes up and down for blinking effect
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize animations here instead of initState since we need the Theme
    if (!_animationsInitialized) {
      _setupAnimations();
      _animationsInitialized = true;
    }

    // Only trigger animation if there's a price change
    if (widget.previousPrice != null && widget.previousPrice != widget.price) {
      _triggerAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedPriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price) {
      _setupAnimations();
      _triggerAnimations();
    }
  }

  void _triggerAnimations() {
    _backgroundController.forward(from: 0);

    // Reset and restart the pulse animation
    _pulseController.stop();
    _pulseController.reset();
    _pulseController.repeat(
        min: 0.0,
        max: 1.0,
        period: const Duration(milliseconds: 500),
        reverse: true);

    // Stop pulse after a few iterations
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  void _setupAnimations() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Set up background color animation
    if (widget.wasUp == true) {
      _backgroundColorAnimation = ColorTween(
        begin: isDark
            ? Colors.green.shade900.withValues(alpha: 0.7)
            : Colors.green.shade100.withValues(alpha: 0.9),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeOut,
      ));

      _textColorAnimation = ColorTween(
        begin: isDark ? Colors.green.shade100 : Colors.green.shade800,
        end: widget.style?.color ??
            Theme.of(context).textTheme.titleLarge?.color,
      ).animate(CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ));
    } else if (widget.wasUp == false) {
      _backgroundColorAnimation = ColorTween(
        begin: isDark
            ? Colors.red.shade900.withValues(alpha: 0.7)
            : Colors.red.shade100.withValues(alpha: 0.9),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeOut,
      ));

      _textColorAnimation = ColorTween(
        begin: isDark ? Colors.red.shade100 : Colors.red.shade800,
        end: widget.style?.color ??
            Theme.of(context).textTheme.titleLarge?.color,
      ).animate(CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ));
    } else {
      _backgroundColorAnimation = ColorTween(
        begin: Colors.transparent,
        end: Colors.transparent,
      ).animate(_backgroundController);

      _textColorAnimation = ColorTween(
        begin: widget.style?.color ??
            Theme.of(context).textTheme.titleLarge?.color,
        end: widget.style?.color ??
            Theme.of(context).textTheme.titleLarge?.color,
      ).animate(_backgroundController);
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make sure animations are initialized if not already
    if (!_animationsInitialized) {
      _setupAnimations();
      _animationsInitialized = true;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundController, _pulseController]),
      builder: (BuildContext context, Widget? child) {
        // Create a pulse effect by modifying the opacity based on the pulse animation
        Color? currentBgColor = _backgroundColorAnimation.value;

        if (_pulseController.isAnimating &&
            currentBgColor != Colors.transparent) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Determine base color for pulsing
          Color baseColor;
          if (widget.wasUp == true) {
            baseColor = isDark ? Colors.green.shade900 : Colors.green.shade100;
          } else if (widget.wasUp == false) {
            baseColor = isDark ? Colors.red.shade900 : Colors.red.shade100;
          } else {
            baseColor = Colors.transparent;
          }

          // Apply pulse effect to background color
          if (baseColor != Colors.transparent) {
            double pulseValue = _pulseAnimation.value;
            // Create pulsing effect by adjusting opacity
            currentBgColor =
                baseColor.withValues(alpha: 0.3 + (pulseValue * 0.6));
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: currentBgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${widget.prefix}${widget.price.toStringAsFixed(2)}',
            style: widget.style?.copyWith(
                  color: _textColorAnimation.value,
                ) ??
                TextStyle(
                  color: _textColorAnimation.value,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}
