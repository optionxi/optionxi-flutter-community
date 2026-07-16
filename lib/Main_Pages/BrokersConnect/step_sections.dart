import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF1B6FEB);
  static const green = Color(0xFF22C55E);

  static Color surface(bool dark) =>
      dark ? const Color(0xFF1A1D27) : Colors.white;
  static Color border(bool dark) =>
      dark ? const Color(0xFF2A2D3A) : const Color(0xFFE8ECF0);
  static Color subtle(bool dark) =>
      dark ? const Color(0xFF22263A) : const Color(0xFFF1F5F9);
  static Color textPrimary(bool dark) =>
      dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color textSecondary(bool dark) =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

// ─────────────────────────────────────────────────────────────
//  Step data
// ─────────────────────────────────────────────────────────────
const _brokerSteps = <String, List<Map<String, dynamic>>>{
  "fyers": [
    {
      "title": "Open a Fyers Account",
      "description":
          "If you don't already have a Fyers account, register and complete your KYC verification.",
      "icon": Icons.account_circle_rounded,
      "link": "https://open-account.fyers.in/",
      "linkLabel": "Open Fyers Account",
    },
    {
      "title": "Login to Developer Console",
      "description":
          "Visit the Fyers API portal and sign in with your trading account credentials.",
      "icon": Icons.terminal_rounded,
      "link": "https://myapi.fyers.in/dashboard",
      "linkLabel": "Go to Developer Portal",
    },
    {
      "title": "Create a New App",
      "description":
          "Click 'Create App', fill in the App Name, Redirect URL, and set the required permissions.",
      "icon": Icons.add_box_rounded,
    },
    {
      "title": "Copy App ID & Secret",
      "description":
          "After the app is created, copy the App ID and App Secret from the dashboard.",
      "icon": Icons.vpn_key_rounded,
    },
    {
      "title": "Set the Redirect URL",
      "description":
          "Paste the URL below exactly as-is into the Redirect URL field of your Fyers app.",
      "icon": Icons.link_rounded,
      "redirectUrl": "https://fastapi.optionxi.com/broker/fyers",
    },
    {
      "title": "Paste Keys & Connect",
      "description":
          "Enter the App ID and App Secret into the fields above and tap Save Credentials.",
      "icon": Icons.check_circle_rounded,
    },
  ],
  "zerodha": [
    {
      "title": "Open a Zerodha Account",
      "description":
          "Register with Zerodha and complete KYC if not already done.",
      "icon": Icons.account_circle_rounded,
      "link": "https://zerodha.com/open-account",
      "linkLabel": "Open Zerodha Account",
    },
    {
      "title": "Sign up as a Developer",
      "description": "Go to Kite Connect and create a developer account.",
      "icon": Icons.terminal_rounded,
      "link": "https://developers.kite.trade/signup",
      "linkLabel": "Kite Connect Signup",
    },
    {
      "title": "Choose an API Plan",
      "description":
          "Select a Free or Paid plan depending on your usage requirements.",
      "icon": Icons.payment_rounded,
    },
    {
      "title": "Create a New App",
      "description":
          "Click 'Create New App', provide App Name, Redirect URL, and other details.",
      "icon": Icons.add_box_rounded,
    },
    {
      "title": "Copy API Key & Secret",
      "description":
          "After app creation, copy your API Key and API Secret from the dashboard.",
      "icon": Icons.vpn_key_rounded,
    },
    {
      "title": "Set the Redirect URL",
      "description":
          "Paste the URL below exactly as-is into the Redirect URL field of your app.",
      "icon": Icons.link_rounded,
      "redirectUrl": "https://fastapi.optionxi.com/broker/zerodha",
    },
    {
      "title": "Paste Keys & Connect",
      "description":
          "Enter API Key and Secret in the fields above, then tap Save Credentials.",
      "icon": Icons.check_circle_rounded,
    },
  ],
  "upstox": [
    {
      "title": "Open an Upstox Account",
      "description":
          "Register with Upstox and complete KYC if not already done.",
      "icon": Icons.account_circle_rounded,
      "link": "https://upstox.com/open-demat-account",
      "linkLabel": "Open Upstox Account",
    },
    {
      "title": "Login to Developer Portal",
      "description": "Visit the Upstox developer portal and sign in.",
      "icon": Icons.terminal_rounded,
      "link": "https://account.upstox.com/developer/apps",
      "linkLabel": "Go to Developer Portal",
    },
    {
      "title": "Create a New App",
      "description":
          "Click 'Create App', fill in the app name, redirect URL, and other details.",
      "icon": Icons.add_box_rounded,
    },
    {
      "title": "Copy API Key & Secret",
      "description":
          "After creation, copy your API Key and Secret from the app details.",
      "icon": Icons.vpn_key_rounded,
    },
    {
      "title": "Set the Redirect URL",
      "description":
          "Paste the URL below exactly as-is into the Redirect URL field of your app.",
      "icon": Icons.link_rounded,
      "redirectUrl": "https://fastapi.optionxi.com/broker/upstox",
    },
    {
      "title": "Paste Keys & Connect",
      "description":
          "Enter API Key and Secret in the fields above, then tap Save Credentials.",
      "icon": Icons.check_circle_rounded,
    },
  ],
};

// ─────────────────────────────────────────────────────────────
//  Main widget
// ─────────────────────────────────────────────────────────────
class ApiKeyStepsSection extends StatefulWidget {
  final String brokerName;
  const ApiKeyStepsSection({super.key, required this.brokerName});

  @override
  State<ApiKeyStepsSection> createState() => _ApiKeyStepsSectionState();
}

class _ApiKeyStepsSectionState extends State<ApiKeyStepsSection> {
  int? _expandedIndex;

  void _toggle(int i) =>
      setState(() => _expandedIndex = _expandedIndex == i ? null : i);

  void _toast(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text(body,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final key = widget.brokerName.toLowerCase();
    final steps = _brokerSteps[key] ?? [];
    final display =
        widget.brokerName[0].toUpperCase() + widget.brokerName.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────
        Row(children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: _T.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'How to Get API Keys',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary(dark),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _T.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(display,
                style: const TextStyle(
                    fontSize: 11, color: _T.blue, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Text(
            'Follow these steps to connect your account',
            style: TextStyle(fontSize: 12, color: _T.textSecondary(dark)),
          ),
        ),
        const SizedBox(height: 16),

        // ── Step list ────────────────────────────────────
        for (int i = 0; i < steps.length; i++)
          _StepItem(
            key: ValueKey(i),
            index: i,
            total: steps.length,
            step: steps[i],
            isExpanded: _expandedIndex == i,
            dark: dark,
            brokerDisplay: display,
            onTap: () => _toggle(i),
            onCopy: (url) => _toast(
              'Redirect URL copied',
              'Paste this in the $display developer portal',
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Single step row  (badge + connector on left, card on right)
//
//  Fix: no IntrinsicHeight, no Expanded inside a Column.
//  The connector line uses a Positioned Stack so it never
//  contributes to the intrinsic height of the row.
// ─────────────────────────────────────────────────────────────
class _StepItem extends StatelessWidget {
  static const double _badgeSize = 32;
  static const double _rowGap = 12; // spacing between rows

  final int index;
  final int total;
  final Map<String, dynamic> step;
  final bool isExpanded;
  final bool dark;
  final String brokerDisplay;
  final VoidCallback onTap;
  final void Function(String) onCopy;

  const _StepItem({
    super.key,
    required this.index,
    required this.total,
    required this.step,
    required this.isExpanded,
    required this.dark,
    required this.brokerDisplay,
    required this.onTap,
    required this.onCopy,
  });

  bool get _isLast => index == total - 1;
  bool get _isFinish => step["icon"] == Icons.check_circle_rounded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _isLast ? 0 : _rowGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left column: badge + connector line ─────────
          // Width is fixed; the Stack overflows downward into
          // the padding gap so the line visually connects rows.
          SizedBox(
            width: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Connector — extends from bottom of badge into the gap
                if (!_isLast)
                  Positioned(
                    top: _badgeSize + 4,
                    // stretch to the bottom of this row's padding gap
                    bottom: -(_rowGap),
                    left: (_badgeSize / 2) - 1, // centre on badge
                    child: Container(width: 2, color: _T.border(dark)),
                  ),

                // Badge
                Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: _isFinish
                        ? _T.green.withOpacity(0.12)
                        : _T.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isFinish
                          ? _T.green.withOpacity(0.4)
                          : _T.blue.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isFinish ? _T.green : _T.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right column: the card ───────────────────────
          Expanded(
            child: _StepCard(
              step: step,
              isExpanded: isExpanded,
              isFinish: _isFinish,
              dark: dark,
              onTap: onTap,
              onCopy: onCopy,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Animated card
//
//  Fix: use AnimatedSize (not AnimatedCrossFade) for expand/
//  collapse — it respects the child's intrinsic height and
//  never causes overflow. mainAxisSize.min on every Column.
// ─────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isExpanded;
  final bool isFinish;
  final bool dark;
  final VoidCallback onTap;
  final void Function(String) onCopy;

  const _StepCard({
    required this.step,
    required this.isExpanded,
    required this.isFinish,
    required this.dark,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isExpanded
            ? _T.blue.withOpacity(dark ? 0.07 : 0.04)
            : _T.surface(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? _T.blue.withOpacity(0.3) : _T.border(dark),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isFinish
                          ? _T.green.withOpacity(0.1)
                          : _T.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      step["icon"] as IconData,
                      size: 16,
                      color: isFinish ? _T.green : _T.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step["title"] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _T.textPrimary(dark),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _T.textSecondary(dark),
                    ),
                  ),
                ],
              ),
            ),

            // ── Collapsible body ──────────────────────
            // AnimatedSize smoothly grows/shrinks the height.
            // The child is either the real content or a zero-
            // height placeholder — no Expanded, no unbounded axis.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? _ExpandedBody(
                      step: step,
                      dark: dark,
                      onCopy: onCopy,
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Expanded body
// ─────────────────────────────────────────────────────────────
class _ExpandedBody extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool dark;
  final void Function(String) onCopy;

  const _ExpandedBody({
    required this.step,
    required this.dark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: _T.border(dark), height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Description
          Text(
            step["description"] as String,
            style: TextStyle(
              fontSize: 13,
              color: _T.textSecondary(dark),
              height: 1.55,
            ),
          ),

          // Redirect URL copy box
          if (step.containsKey("redirectUrl")) ...[
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final url = step["redirectUrl"] as String;
                Clipboard.setData(ClipboardData(text: url));
                onCopy(url);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _T.subtle(dark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step["redirectUrl"] as String,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: _T.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded,
                        size: 14, color: _T.textSecondary(dark)),
                  ],
                ),
              ),
            ),
          ],

          // External link button
          if (step.containsKey("link")) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(step["link"] as String);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(
                  step["linkLabel"] as String? ?? "Open Link",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _T.blue,
                  side: BorderSide(color: _T.blue.withOpacity(0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
