import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyStepsSection extends StatelessWidget {
  final String brokerName;

  const ApiKeyStepsSection({
    super.key,
    required this.brokerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, List<Map<String, dynamic>>> brokerSteps = {
      "fyers": [
        {
          "title": "Open a Fyers trading account",
          "description":
              "If you don’t already have a Fyers account, register and complete KYC.",
          "icon": Icons.account_circle,
          "link": "https://open-account.fyers.in/",
        },
        {
          "title": "Login to Fyers Developer Console",
          "description": "Go to Fyers API portal and log in.",
          "icon": Icons.login,
          "link": "https://myapi.fyers.in/dashboard",
        },
        {
          "title": "Create a New App",
          "description":
              "Click 'Create App'. Fill in App Name, Redirect URL, permissions etc.",
          "icon": Icons.app_registration,
        },
        {
          "title": "Get App ID & Secret",
          "description": "After creation, copy the App ID and App Secret.",
          "icon": Icons.vpn_key,
        },
        {
          "title": "Add Redirect URL",
          "description":
              "Ensure the Redirect URL matches exactly with what you will use.",
          "icon": Icons.link,
          "redirectUrl": "https://fastapi.optionxi.com/broker/fyers",
        },
        {
          "title": "Enter API Keys",
          "description":
              "Paste App ID and App Secret here in the UI to connect.",
          "icon": Icons.check_circle,
        },
      ],
      "zerodha": [
        {
          "title": "Open a Zerodha trading account",
          "description":
              "Register with Zerodha and complete KYC if not already done.",
          "icon": Icons.account_circle,
          "link": "https://zerodha.com/open-account",
        },
        {
          "title": "Sign up as a developer",
          "description":
              "Go to Kite Connect signup page and create a developer account.",
          "icon": Icons.login,
          "link": "https://developers.kite.trade/signup",
        },
        {
          "title": "Choose your API plan",
          "description": "Select Free or Paid plan depending on your usage.",
          "icon": Icons.payment,
        },
        {
          "title": "Create a New App",
          "description":
              "Click 'Create New App'. Provide App Name, Redirect URL, etc.",
          "icon": Icons.app_registration,
        },
        {
          "title": "Get API Key & Secret",
          "description":
              "After app creation, copy your API Key and API Secret.",
          "icon": Icons.vpn_key,
        },
        {
          "title": "Add Redirect URL",
          "description":
              "Redirect URL must exactly match the one in your app setup.",
          "icon": Icons.link,
          "redirectUrl": "https://fastapi.optionxi.com/broker/zerodha",
        },
        {
          "title": "Enter API Keys",
          "description": "Paste API Key & Secret here to connect Zerodha.",
          "icon": Icons.check_circle,
        },
      ],
      "upstox": [
        {
          "title": "Open an Upstox trading account",
          "description":
              "Register with Upstox and complete KYC if not already done.",
          "icon": Icons.account_circle,
          "link": "https://upstox.com/open-demat-account",
        },
        {
          "title": "Login to Upstox Developer Portal",
          "description": "Go to the developer portal and log in.",
          "icon": Icons.login,
          "link": "https://account.upstox.com/developer/apps",
        },
        {
          "title": "Create a New App",
          "description":
              "Click 'Create App'. Fill app name, redirect URL, etc.",
          "icon": Icons.app_registration,
        },
        {
          "title": "Get API Key & Secret",
          "description": "After creation, copy your API Key and Secret.",
          "icon": Icons.vpn_key,
        },
        {
          "title": "Add Redirect URL",
          "description":
              "Ensure the Redirect URL matches exactly as configured.",
          "icon": Icons.link,
          "redirectUrl": "https://fastapi.optionxi.com/broker/upstox",
        },
        {
          "title": "Enter API Keys",
          "description": "Paste API Key & Secret here to connect Upstox.",
          "icon": Icons.check_circle,
        },
      ],
    };

    final steps = brokerSteps[brokerName.toLowerCase()] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How to Get Your ${brokerName[0].toUpperCase()}${brokerName.substring(1)} API Keys",
          style: theme.textTheme.headlineSmall?.copyWith(
            // ⬆ bigger title
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final step = entry.value;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              dense: false, // ⬆ gives more breathing space
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  step["icon"] as IconData,
                  size: 22, // ⬆ bigger icon
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step $index",
                    style: theme.textTheme.labelLarge?.copyWith(
                      // ⬆ bigger
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step["title"] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      // ⬆ bigger
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step["description"] as String,
                          textAlign: TextAlign.left,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // ⬆ bigger
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                        if (step.containsKey("redirectUrl")) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    step["redirectUrl"],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      // ⬆ bigger monospace
                                      fontFamily: "monospace",
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: "Copy",
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: step["redirectUrl"]));
                                    _showStatusNotification(
                                      'Link Copied',
                                      'Paste the link as the redirect url in the $brokerName developer portal',
                                      Colors.blue,
                                      Icons.link,
                                      context,
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                        if (step.containsKey("link")) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: theme
                                  .textTheme.bodySmall, // ⬆ bigger button text
                            ),
                            onPressed: () async {
                              final url = Uri.parse(step["link"]);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text("Open Link"),
                          ),
                        ]
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showStatusNotification(String title, String message, Color color,
      IconData icon, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Row(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text(message, style: const TextStyle(color: Colors.white)),
              ])),
        ])));
  }
}
