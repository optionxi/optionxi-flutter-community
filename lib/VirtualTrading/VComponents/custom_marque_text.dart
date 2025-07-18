import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple alternative using PageView for infinite scrolling
Widget buildScrollingText(BuildContext context) {
  const String text =
      'Previous day data • As per SEBI and NSE regulations • Educational purpose • No real money • Virutal trade • ';
  return Container(
    height: 32,
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    child: _CustomMarqueeText(
      text: text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

// Simpler marquee text widget
class _CustomMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity = 30.0;

  const _CustomMarqueeText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  State<_CustomMarqueeText> createState() => _CustomMarqueeTextState();
}

class _CustomMarqueeTextState extends State<_CustomMarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _timer;
  double _offset = 0.0;
  double _maxScrollExtent = 0.0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _startScrolling();
      }
    });
  }

  void _startScrolling() {
    if (_isDisposed) return;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_maxScrollExtent > 0) {
        _offset += widget.velocity * 0.05; // 50ms intervals

        if (_offset >= _maxScrollExtent) {
          _offset = 0.0;
        }

        if (_scrollController.hasClients && !_isDisposed) {
          _scrollController.jumpTo(_offset);
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duplicatedText = widget.text * 3; // Triple the text for seamless loop

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && !_isDisposed) {
              _maxScrollExtent = _scrollController.position.maxScrollExtent / 2;
            }
          });

          return Container(
            alignment: Alignment.center,
            child: Text(
              duplicatedText,
              style: widget.style,
              maxLines: 1,
            ),
          );
        },
      ),
    );
  }
}

// Custom widget for infinite scrolling text
class _InfiniteScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double speed = 50.0;

  const _InfiniteScrollingText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  State<_InfiniteScrollingText> createState() => _InfiniteScrollingTextState();
}

class _InfiniteScrollingTextState extends State<_InfiniteScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late String _displayText;
  double _textWidth = 0;
  double _containerWidth = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Create duplicated text for seamless loop
    _displayText = '${widget.text} • ${widget.text} • ';

    _controller = AnimationController(
      duration: const Duration(seconds: 1), // Will be recalculated
      vsync: this,
    );

    // Calculate text width after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _calculateTextWidth();
      }
    });
  }

  void _calculateTextWidth() {
    if (_isDisposed) return;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    if (!_isDisposed) {
      setState(() {
        _textWidth = textPainter.width;
      });

      // Start animation after calculating width
      _startAnimation();
    }

    // Clean up TextPainter
    textPainter.dispose();
  }

  void _startAnimation() {
    if (_isDisposed) return;

    if (_textWidth > 0 && _containerWidth > 0) {
      // Calculate duration based on text width and desired speed
      final duration = Duration(
        milliseconds: ((_textWidth / widget.speed) * 1000).round(),
      );

      if (!_isDisposed) {
        _controller.duration = duration;

        _animation = Tween<double>(
          begin: 0.0,
          end: -_textWidth,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.linear,
        ));

        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_containerWidth != constraints.maxWidth) {
          _containerWidth = constraints.maxWidth;
          // Restart animation when container width changes
          if (_textWidth > 0 && !_isDisposed) {
            _startAnimation();
          }
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: Row(
                  children: [
                    Text(
                      _displayText,
                      style: widget.style,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
