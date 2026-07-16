import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showSubscriptionRequiredDialog(
    BuildContext context, String title, String description) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor, // Consistent with card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      ),
      content: Text(
        description,
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
