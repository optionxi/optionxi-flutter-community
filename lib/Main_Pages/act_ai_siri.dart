import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomeScreenAI extends StatefulWidget {
  const HomeScreenAI({Key? key}) : super(key: key);

  @override
  State<HomeScreenAI> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenAI> {
  bool _showOverlay = false;

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using a dark theme base for better contrast with the glowing elements
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
        ),
      ),
      child: Scaffold(
        // appBar: AppBar(
        //   // title: const Text('Apple Intelligence Style'),
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        // ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background content
            // Positioned.fill(
            //   child: Image.network(
            //     'https://picsum.photos/seed/picsum/800/1200',
            //     fit: BoxFit.cover,
            //     color: Colors.black.withOpacity(0.6),
            //     colorBlendMode: BlendMode.darken,
            //   ),
            // ),
            Center(
              child: Text(
                'Press the button to activate',
                style: TextStyle(fontSize: 18, color: Colors.grey[300]),
              ),
            ),
            // The AI Overlay
            if (_showOverlay)
              Positioned.fill(
                child: SiriOverlay(
                  onClose: _toggleOverlay,
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleOverlay,
          backgroundColor: Colors.grey[900],
          child: Icon(_showOverlay ? Icons.close : Icons.auto_awesome,
              color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class SiriOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SiriOverlay({Key? key, required this.onClose}) : super(key: key);

  @override
  State<SiriOverlay> createState() => _SiriOverlayState();
}

class _SiriOverlayState extends State<SiriOverlay>
    with TickerProviderStateMixin {
  // Controller for the rotating border colors
  late AnimationController _borderController;
  // Boolean to trigger the chat UI appearance
  bool _showChat = false;
  final TextEditingController _textController = TextEditingController();

  // Dummy chat messages
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'How can I help you with what\'s on your screen?'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize border animation
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Delay showing the chat interface for a dramatic entrance effect
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showChat = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _borderController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add({'isUser': true, 'text': text});
    });
    // Simulate AI response after a short pause
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'I understand. Here are some results based on that...'
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // We use a Stack to layer the glowing border *underneath* the chat UI
    return Stack(
      children: [
        // Layer 1: The Glowing Screen Border
        // IgnorePointer allows taps to pass through to the chat layer below
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _borderController,
            builder: (context, child) {
              return CustomPaint(
                size: screenSize,
                painter: GlowingScreenBorderPainter(_borderController.value),
              );
            },
          ),
        ),

        // Layer 2: The Chat Interface appearing with a fade
        AnimatedOpacity(
          opacity: _showChat ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: _buildChatInterface(screenSize),
        ),
      ],
    );
  }

  Widget _buildChatInterface(Size screenSize) {
    // Using BackdropFilter for the classic Apple "Frosted Glass" look
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: widget.onClose,
            ),
            title: const Text("Visual Intelligence",
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Spacer to push content down slightly
              SizedBox(height: screenSize.height * 0.2),
              // Message List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg['text'], msg['isUser']);
                  },
                ),
              ),
              // Input Area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Apple-style gradient for user, subtle gray for AI
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF00C6FF)])
              : LinearGradient(colors: [Colors.grey[800]!, Colors.grey[900]!]),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(20),
            bottomLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 30),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _handleSubmitted(_textController.text),
            mini: true,
            backgroundColor: const Color(0xFF007AFF),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Painters the multi-color glowing screen edge
class GlowingScreenBorderPainter extends CustomPainter {
  final double animationValue;

  GlowingScreenBorderPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Define the rectangle for the screen border.
    // Insetting slightly ensures the thick blurred glow doesn't get clipped by the screen edges.
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    // Apple-style large rounded corners
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(45));

    // Define the colors for the glowing gradient.
    // Using a mix of vibrant blues, purples, oranges for the "Intelligence" look.
    final colors = [
      const Color(0xFF00C6FF), // Light Blue
      const Color(0xFF007AFF), // System Blue
      const Color(0xFF5856D6), // Purple
      const Color(0xFFFF2D55), // Pink/Red
      const Color(0xFFFF9500), // Orange
      const Color(0xFF00C6FF), // Wrap back to Light Blue for smooth loop
    ];
    final stops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

    // Create a sweep gradient that rotates based on the animation value.
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: colors,
      stops: stops,
      transform: GradientRotation(animationValue * math.pi * 2),
    );

    // Paint style for the main glow
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 // Thick stroke for the glow body
      // High blur for the outer glow effect
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Draw the main heavy glow
    canvas.drawRRect(rrect, paint);

    // Draw a second, thinner, less blurred line on top to define the edge sharply
    paint
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(GlowingScreenBorderPainter oldDelegate) => true;
}
