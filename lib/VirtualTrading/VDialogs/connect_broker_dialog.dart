import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showConnectionDialog(BuildContext context, String brokerName) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor, // Consistent with card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Connect to $brokerName',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      ),
      content: Text(
        'You will be redirected to $brokerName to authenticate your account securely.',
        style: GoogleFonts.inter(
          color:
              theme.colorScheme.onSurface.withOpacity(0.8), // Use theme colors
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: theme.colorScheme.primary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This feature will be comming soon!, Stay tuned',
                    style:
                        GoogleFonts.inter(color: theme.colorScheme.onPrimary)),
                backgroundColor: theme.colorScheme
                    .primary, // SnackBar consistent with primary color
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Text('Connect', style: GoogleFonts.inter()),
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
