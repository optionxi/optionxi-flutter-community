import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:optionxi/Helpers/badge_service.dart';

void showOrderConfiramationDialog(BuildContext context, String whichorder) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _OrderConfirmationDialog(whichorder: whichorder),
  );
}

class _OrderConfirmationDialog extends StatefulWidget {
  final String whichorder;
  const _OrderConfirmationDialog({required this.whichorder});

  @override
  State<_OrderConfirmationDialog> createState() =>
      _OrderConfirmationDialogState();
}

class _OrderConfirmationDialogState extends State<_OrderConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // fire both after first frame so the dialog is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Card
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Placed',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ${widget.whichorder} order has been\nplaced successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await BadgeService.incrementPortfolioBadge();
                      Get.offNamedUntil(
                        '/trade/orders',
                        (route) => route.settings.name == '/',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Okay',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti burst, centered above the check badge
          Positioned(
            top: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 18,
              maxBlastForce: 12,
              minBlastForce: 6,
              gravity: 0.3,
              emissionFrequency: 0.05,
              colors: [
                theme.colorScheme.primary,
                Colors.amber,
                Colors.greenAccent,
                Colors.pinkAccent,
              ],
            ),
          ),

          // Success badge, floats above the card edge
          Positioned(
            top: -28,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 4),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
