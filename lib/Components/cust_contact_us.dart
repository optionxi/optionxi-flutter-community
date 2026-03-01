import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────

abstract class _CT {
  // Brand accent
  static const indigo = Color(0xFF5B5BD6);

  // Dark surface palette
  static const darkSurface = Color(0xFF111114);
  static const darkBorder = Color(0xFF2A2A32);
  static const darkDivider = Color(0xFF222228);

  // Light surface palette
  static const lightSurface = Color(0xFFFAFAFC);
  static const lightBorder = Color(0xFFEAEAF0);

  // Platform tints
  static const whatsapp = Color(0xFF25D366);
  static const email = Color(0xFFE84040);
  static const instagram = Color(0xFFE1306C);
}

// ─── Entry Point ─────────────────────────────────────────────────────────────

void showContactOptions(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const _ContactSheet(),
  );
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _CT.darkSurface : _CT.lightSurface;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? _CT.darkBorder : _CT.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(isDark: isDark),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 28),
            child: Column(
              children: [
                _Header(isDark: isDark),
                const SizedBox(height: 28),
                _ContactRow(
                  isDark: isDark,
                  icon: FontAwesomeIcons.whatsapp,
                  tint: _CT.whatsapp,
                  label: 'WhatsApp',
                  meta: 'Usually replies in minutes',
                  onTap: () => _dismiss(context, _launchWhatsApp),
                ),
                _Divider(isDark: isDark),
                _ContactRow(
                  isDark: isDark,
                  icon: FontAwesomeIcons.envelope,
                  tint: _CT.email,
                  label: 'Email',
                  meta: 'For detailed inquiries',
                  onTap: () => _dismiss(context, _launchGmail),
                ),
                _Divider(isDark: isDark),
                _ContactRow(
                  isDark: isDark,
                  icon: FontAwesomeIcons.instagram,
                  tint: _CT.instagram,
                  label: 'Instagram',
                  meta: 'Updates & announcements',
                  onTap: () => _dismiss(context, _launchInstagram),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _dismiss(BuildContext context, VoidCallback action) {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 220), action);
  }
}

// ─── Handle ───────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  final bool isDark;
  const _Handle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTACT US',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                  color: _CT.indigo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Get in touch',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '3 channels',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: isDark ? _CT.darkDivider : _CT.lightBorder,
    );
  }
}

// ─── Contact Row ──────────────────────────────────────────────────────────────

class _ContactRow extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final Color tint;
  final String label;
  final String meta;
  final VoidCallback onTap;

  const _ContactRow({
    required this.isDark,
    required this.icon,
    required this.tint,
    required this.label,
    required this.meta,
    required this.onTap,
  });

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Opacity(opacity: _fade.value, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              // Icon pill
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.tint
                      .withValues(alpha: widget.isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FaIcon(
                    widget.icon,
                    size: 20,
                    color: widget.tint,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.meta,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.40)
                            : Colors.black.withValues(alpha: 0.40),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Launch Helpers ───────────────────────────────────────────────────────────

Future<void> _launchWhatsApp() async {
  const phone = '9496672190';
  const msg = "Hi! I'm new to OptionXi, can you help me?";
  final uri =
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _launchGmail() async {
  const email = 'optionxi24@gmail.com';
  const subject = 'Algorithm Deployment Inquiry';
  const body =
      'Hello,\n\nI would like to learn more about deploying my algorithm with OptionXi.\n\nBest regards';
  final uri = Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _launchInstagram() async {
  final uri = Uri.parse('https://instagram.com/optionxi');
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}
