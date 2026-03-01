import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

Future<void> showOrderPlacedDialog(BuildContext context, bool fromedit) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _OrderPlacedCard(fromedit),
      ),
    ),
  );
}

class _OrderPlacedCard extends StatefulWidget {
  final bool fromedit;
  const _OrderPlacedCard(this.fromedit);

  @override
  State<_OrderPlacedCard> createState() => _OrderPlacedCardState();
}

class _OrderPlacedCardState extends State<_OrderPlacedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const String successSvg = '''
<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4CAF50"/>
      <stop offset="100%" stop-color="#66BB6A"/>
    </linearGradient>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#E8F5E9"/>
      <stop offset="100%" stop-color="#C8E6C9"/>
    </linearGradient>
  </defs>
  <circle cx="40" cy="40" r="37" fill="url(#bgGrad)" opacity="0.3"/>
  <circle cx="40" cy="40" r="32" fill="url(#grad)" opacity="0.15"/>
  <circle cx="40" cy="40" r="28" stroke="url(#grad)" stroke-width="4" fill="none"/>
  <path d="M28 41 L36 49 L52 30" stroke="url(#grad)" stroke-width="5" fill="none" 
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

    const String basketSvg = '''
<svg width="40" height="40" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="basketGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF6B6B"/>
      <stop offset="100%" stop-color="#FFA07A"/>
    </linearGradient>
  </defs>
  <path d="M8 16 L12 38 C12 40 13 42 16 42 L32 42 C35 42 36 40 36 38 L40 16 Z" 
        fill="url(#basketGrad)" opacity="0.2" stroke="url(#basketGrad)" stroke-width="2"/>
  <path d="M6 16 L42 16" stroke="url(#basketGrad)" stroke-width="3" stroke-linecap="round"/>
  <path d="M16 16 L16 12 C16 9 18 6 24 6 C30 6 32 9 32 12 L32 16" 
        stroke="url(#basketGrad)" stroke-width="2.5" fill="none" stroke-linecap="round"/>
  <circle cx="20" cy="26" r="1.5" fill="url(#basketGrad)"/>
  <circle cx="28" cy="26" r="1.5" fill="url(#basketGrad)"/>
</svg>
''';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with Background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1B5E20).withOpacity(0.2),
                              const Color(0xFF2E7D32).withOpacity(0.1),
                            ]
                          : [
                              const Color(0xFFE8F5E9),
                              const Color(0xFFC8E6C9).withOpacity(0.5),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SvgPicture.string(
                    successSvg,
                    height: 80,
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        'Order Placed Successfully! 🎉',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your order is now in your virtual basket and ready for processing.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Info Card
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();

                          if (widget.fromedit) {
                            Navigator.of(context).pop();
                          } else {
                            Get.offNamed('/basket');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.string(basketSvg, height: 40),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Virtual Basket',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'View and manage your orders',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (widget.fromedit) {
                              Navigator.of(context).pop();
                            } else {
                              Get.offNamed('/basket');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor:
                                theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Go to Virtual Basket',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
