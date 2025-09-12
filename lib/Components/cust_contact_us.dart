import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void showContactOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => _ModernContactSheet(),
  );
}

class _ModernContactSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Color(0xFF1A1A1A),
                  Color(0xFF0F0F0F),
                ]
              : [
                  Colors.white,
                  Color(0xFFFAFAFA),
                ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern handle bar
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(height: 32),

            // Header
            Column(
              children: [
                Text(
                  "Get in Touch",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Color(0xFF6366F1).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Choose your preferred way to connect",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 36),

            // Contact options
            _ModernContactTile(
              icon: FontAwesomeIcons.whatsapp,
              iconColor: Color(0xFF25D366),
              title: "WhatsApp",
              subtitle: "Instant messaging • Usually replies in minutes",
              gradient: [Color(0xFF25D366), Color(0xFF128C7E)],
              onTap: () => _handleTap(context, _launchWhatsApp),
            ),
            SizedBox(height: 16),

            _ModernContactTile(
              icon: FontAwesomeIcons.envelope,
              iconColor: Color(0xFFEA4335),
              title: "Email",
              subtitle: "Professional support • Detailed responses",
              gradient: [Color(0xFFEA4335), Color(0xFFD33B2C)],
              onTap: () => _handleTap(context, _launchGmail),
            ),
            SizedBox(height: 16),

            _ModernContactTile(
              icon: FontAwesomeIcons.instagram,
              iconColor: Color(0xFFE4405F),
              title: "Instagram",
              subtitle: "Follow for updates • Latest news & tips",
              gradient: [Color(0xFFE4405F), Color(0xFFC13584)],
              onTap: () => _handleTap(context, _launchInstagram),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, VoidCallback action) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    Future.delayed(Duration(milliseconds: 200), action);
  }
}

class _ModernContactTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  _ModernContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  _ModernContactTileState createState() => _ModernContactTileState();
}

class _ModernContactTileState extends State<_ModernContactTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
      child: Material(
        elevation: _isPressed ? 2.0 : 6.0,
        borderRadius: BorderRadius.circular(24),
        shadowColor: widget.iconColor.withValues(alpha: 0.3),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(24),
          splashColor: widget.iconColor.withValues(alpha: 0.1),
          highlightColor: widget.iconColor.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color(0xFF2A2A2A),
                        Color(0xFF1F1F1F),
                      ]
                    : [
                        Colors.white,
                        Color(0xFFFDFDFD),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.iconColor.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 20),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: widget.iconColor,
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

// Social Media Launch Functions
Future<void> _launchWhatsApp() async {
  const phoneNumber = "9496672190";
  const message = "Hi! I'm interested in deploying my algorithm with OptionXi.";

  final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch WhatsApp');
    }
  } catch (e) {
    debugPrint('Error launching WhatsApp: $e');
  }
}

Future<void> _launchGmail() async {
  const email = 'optionxi24@gmail.com';
  const subject = 'Algorithm Deployment Inquiry';
  const body =
      'Hello,\n\nI would like to learn more about deploying my algorithm with OptionXi.\n\nBest regards';

  final String mailtoUrl =
      'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  final Uri gmailUri = Uri.parse(mailtoUrl);

  try {
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(
        gmailUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch Gmail');
    }
  } catch (e) {
    debugPrint('Error launching Gmail: $e');
  }
}

Future<void> _launchInstagram() async {
  const instagramUsername = "optionxi";
  final Uri instagramUri =
      Uri.parse("https://instagram.com/$instagramUsername");

  try {
    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(
        instagramUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch Instagram');
    }
  } catch (e) {
    debugPrint('Error launching Instagram: $e');
  }
}
