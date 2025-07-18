import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Helpers/badge_service.dart';

void showOrderConfiramationDialog(BuildContext context, String whichorder) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor, // Consistent with card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Order Placed',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      ),
      content: Text(
        'Your ${whichorder} order has been placed successfully.',
        style: GoogleFonts.inter(
          color:
              theme.colorScheme.onSurface.withOpacity(0.8), // Use theme colors
        ),
      ),
      actions: [
        // TextButton(
        //   onPressed: () => Navigator.pop(context),
        //   child: Text('Cancel',
        //       style: GoogleFonts.inter(color: theme.colorScheme.primary)),
        // ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Please check the orders tab',
            //         style:
            //             GoogleFonts.inter(color: theme.colorScheme.onPrimary)),
            //     backgroundColor: theme.colorScheme
            //         .primary, // SnackBar consistent with primary color
            //     behavior: SnackBarBehavior.floating,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     duration: Duration(milliseconds: 1500),
            //     margin: EdgeInsets.only(bottom: 70), // Add bottom margin
            //   ),
            // );
            // Navigator.pop(context);
            await BadgeService.incrementPortfolioBadge();
            Get.offAllNamed('/trade/orders');
          },
          child: Text('Okay', style: GoogleFonts.inter()),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                theme.colorScheme.primary, // Use primary color for button
            foregroundColor:
                theme.colorScheme.onPrimary, // Text color on primary
          ),
        ),
      ],
    ),
  );
}
