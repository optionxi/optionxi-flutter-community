import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlidetoBuyorSell extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onCompleted;
  final String orderType; // "buy" or "sell"

  const SlidetoBuyorSell({
    Key? key,
    required this.theme,
    required this.onCompleted,
    required this.orderType,
  }) : super(key: key);

  @override
  State<SlidetoBuyorSell> createState() => _SlidetoBuyorSellState();
}

class _SlidetoBuyorSellState extends State<SlidetoBuyorSell>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _clickAnimationController;

  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;
  late Animation<double> _clickAnimation;

  double _dragPosition = 0;
  bool _isSliding = false;
  bool _isCompleted = false;

  static const double _sliderHeight = 70.0;
  static const double _thumbSize = 54.0;
  static const double _completionThreshold = 0.85;

  // Get colors based on order type
  Color get _primaryColor =>
      widget.orderType.toLowerCase() == 'buy' ? Colors.green : Colors.red;

  Color get _secondaryColor => widget.orderType.toLowerCase() == 'buy'
      ? Colors.green.shade400
      : Colors.red.shade400;

  String get _orderText => widget.orderType.toLowerCase() == 'buy'
      ? 'Slide to Buy'
      : 'Slide to Sell';

  IconData get _orderIcon => widget.orderType.toLowerCase() == 'buy'
      ? Icons.trending_up_rounded
      : Icons.trending_down_rounded;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _clickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _clickAnimation = Tween<double>(begin: 0, end: 30).animate(
      CurvedAnimation(parent: _clickAnimationController, curve: Curves.easeOut),
    );

    // Start subtle pulsing animation
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _clickAnimationController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_isCompleted || _isSliding) return;

    HapticFeedback.lightImpact();
    _clickAnimationController.forward().then((_) {
      _clickAnimationController.reverse();
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;

    _isSliding = true;
    _stopPulseAnimation();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final maxDrag =
        box.size.width - _thumbSize - 16; // 8px padding on each side

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Haptic feedback when approaching completion
    if (_dragPosition / maxDrag > _completionThreshold &&
        _dragPosition / maxDrag < 0.9) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final maxDrag = box.size.width - _thumbSize - 16;
    final completion = _dragPosition / maxDrag;

    if (completion >= _completionThreshold) {
      _completeSlide();
    } else {
      _resetSlide();
    }
  }

  void _completeSlide() async {
    _isCompleted = true;
    HapticFeedback.heavyImpact();

    // Slide to complete position
    final RenderBox box = context.findRenderObject() as RenderBox;
    final maxDrag = box.size.width - _thumbSize - 16;

    setState(() {
      _dragPosition = maxDrag;
    });

    // Start success animations
    await _successController.forward();

    // Wait a moment to show success state
    await Future.delayed(const Duration(milliseconds: 500));

    // Execute the callback
    widget.onCompleted();
  }

  void _resetSlide() {
    _slideController.reset();
    _slideController.forward();

    _slideAnimation.addListener(() {
      setState(() {
        _dragPosition = _dragPosition * (1 - _slideAnimation.value);
      });
    });

    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isSliding = false;
        _startPulseAnimation();
        _slideController.removeStatusListener((_) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseAnimation, _successAnimation, _clickAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isSliding ? 1.0 : _pulseAnimation.value,
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              height: _sliderHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background text and icons
                  _buildBackgroundContent(),

                  // Sliding thumb
                  _buildSlidingThumb(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundContent() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Order type icon
            AnimatedOpacity(
              opacity: _dragPosition < 100 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isCompleted ? Icons.check_rounded : _orderIcon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),

            // Center text
            AnimatedOpacity(
              opacity: _dragPosition < 150 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isCompleted ? 'Order Placed!' : _orderText,
                    style: TextStyle(
                      fontSize: _isCompleted ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (!_isCompleted)
                    Text(
                      'Place ${widget.orderType.toLowerCase()} order via broker',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.1,
                      ),
                    ),
                ],
              ),
            ),

            // Right side - Arrow icons
            AnimatedOpacity(
              opacity: _dragPosition < 100 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidingThumb() {
    return AnimatedPositioned(
      duration: _isSliding ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      left: 8 + _dragPosition + _clickAnimation.value,
      top: 8,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: _thumbSize,
          height: _thumbSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isCompleted
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('check'),
                    color: _primaryColor,
                    size: 28,
                  )
                : Icon(
                    _orderIcon,
                    key: ValueKey(_orderIcon),
                    color: _primaryColor,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
