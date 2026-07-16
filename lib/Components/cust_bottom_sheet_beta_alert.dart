import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Theme/theme_controller.dart';

/// Call this in your initState:
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     showBetaBottomSheet(context);
///   });
/// }
/// ```

void showBetaBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _BetaBottomSheet(),
  );
}

class _BetaBottomSheet extends StatelessWidget {
  const _BetaBottomSheet();

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    final isDark = themeController.isDarkMode;

    // ── Semantic tokens ──────────────────────────────────────────────────────
    final bgColor = isDark ? const Color(0xFF0F0F14) : const Color(0xFFFFFFFF);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F0F14);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final handleColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final outlineBorder = isDark ? Colors.white24 : const Color(0xFFD1D5DB);
    final outlineFg = isDark ? Colors.white : const Color(0xFF0F0F14);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Beta badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            "You're in early access",
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            "This feature is currently in beta. Some features may be unstable or incomplete. Our team has been notified and is actively working to improve your experience.",
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Info cards row
          Row(
            children: [
              _InfoCard(
                icon: Icons.bug_report_outlined,
                label: 'Bugs possible',
                accentColor: const Color(0xFFFF6B6B),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _InfoCard(
                icon: Icons.notifications_active_outlined,
                label: 'Admin notified',
                accentColor: const Color(0xFF6C63FF),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _InfoCard(
                icon: Icons.update_outlined,
                label: 'Updates soon',
                accentColor: const Color(0xFF3ECFCF),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Divider
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 24),

          // Contact Us button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showContactOptions(context);
              },
              icon:
                  Icon(Icons.mail_outline_rounded, size: 18, color: outlineFg),
              label: Text('Contact Us', style: TextStyle(color: outlineFg)),
              style: OutlinedButton.styleFrom(
                foregroundColor: outlineFg,
                side: BorderSide(color: outlineBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Got it / dismiss button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              child: const Text("Got it, let's go"),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white70 : const Color(0xFF374151);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.20 : 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
