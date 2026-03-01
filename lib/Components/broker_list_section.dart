import 'package:flutter/material.dart';
import 'package:optionxi/BrokersConnect/connect_fyers_page.dart';
import 'package:optionxi/BrokersConnect/connect_upstox_page.dart';
import 'package:optionxi/BrokersConnect/connect_zerodha_page.dart';
import 'package:optionxi/VirtualTrading/act_broker_connectpage.dart';

// ─── DATA MODEL ──────────────────────────────────────────────────────────────

class BrokerData {
  final String name;
  final String subtitle;
  final String description;
  final Color accentColor;
  final IconData icon;
  final String assetImage;
  final bool isConnected;

  const BrokerData({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.assetImage,
    this.isConnected = false,
  });
}

// ─── BROKER LIST ─────────────────────────────────────────────────────────────

final List<BrokerData> brokers = const [
  BrokerData(
    name: "Fyers",
    subtitle: "Fyers API",
    description: "Advanced options & equity trading with real-time data feeds.",
    accentColor: Color(0xFF2962FF),
    assetImage: "assets/brokers/fyers.png",
    icon: Icons.show_chart_rounded,
  ),
  BrokerData(
    name: "Upstox",
    subtitle: "Upstox API",
    description:
        "Next-gen trading platform with lightning-fast order execution.",
    accentColor: Color(0xFF7C3AED),
    assetImage: "assets/brokers/upstox.png",
    icon: Icons.trending_up_rounded,
  ),
  BrokerData(
    name: "Zerodha",
    subtitle: "Kite Connect API",
    description: "India's largest broker with robust API infrastructure.",
    accentColor: Color(0xFFEA4C28),
    assetImage: "assets/brokers/kite.png",
    icon: Icons.account_balance_rounded,
  ),
];

// ─── MAIN WIDGET ─────────────────────────────────────────────────────────────

Widget buildBrokerHub(BuildContext context, AnimationController controller) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _BrokerHubHeader(isDark: isDark),
      const SizedBox(height: 20),
      SizedBox(
        height: 220,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: brokers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < brokers.length - 1 ? 16 : 0,
              ),
              child: _BrokerCard(
                broker: brokers[index],
                index: index,
                controller: controller,
                isDark: isDark,
              ),
            );
          },
        ),
      ),
    ],
  );
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _BrokerHubHeader extends StatelessWidget {
  final bool isDark;

  const _BrokerHubHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Broker Hub',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0D0D0D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'Connect your trading account',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.45)
                        : const Color(0xFF0D0D0D).withOpacity(0.4),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BrokerConnectPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : const Color(0xFF0D0D0D).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.75)
                        : const Color(0xFF0D0D0D).withOpacity(0.65),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── BROKER CARD ─────────────────────────────────────────────────────────────

class _BrokerCard extends StatefulWidget {
  final BrokerData broker;
  final int index;
  final AnimationController controller;
  final bool isDark;

  const _BrokerCard({
    required this.broker,
    required this.index,
    required this.controller,
    required this.isDark,
  });

  @override
  State<_BrokerCard> createState() => _BrokerCardState();
}

class _BrokerCardState extends State<_BrokerCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final broker = widget.broker;
    final isDark = widget.isDark;

    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final subtitleColor =
        isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.38);
    // final descColor =
    //     isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.55);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: widget.controller,
          curve: Interval(
            (0.12 * widget.index).clamp(0.0, 0.7),
            (0.12 * widget.index + 0.35).clamp(0.15, 1.0),
            curve: Curves.easeOutQuart,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: widget.controller,
          curve: Interval(
            (0.12 * widget.index).clamp(0.0, 0.7),
            (0.12 * widget.index + 0.45).clamp(0.2, 1.0),
            curve: Curves.easeOut,
          ),
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _openBroker(context, broker);
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 268,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Accent top bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              broker.accentColor,
                              broker.accentColor.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Subtle accent glow in top-right
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              broker.accentColor
                                  .withOpacity(isDark ? 0.12 : 0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo + name row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo container
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          broker.accentColor.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.asset(
                                    broker.assetImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              // Name + subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      broker.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0D0D0D),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      broker.subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Beta pill
                              _BetaPill(isDark: isDark),
                            ],
                          ),

                          // const SizedBox(height: 14),

                          // // Description
                          // Text(
                          //   broker.description,
                          //   maxLines: 2,
                          //   overflow: TextOverflow.ellipsis,
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     height: 1.5,
                          //     color: descColor,
                          //     fontWeight: FontWeight.w400,
                          //   ),
                          // ),

                          const Spacer(),

                          // Feature tags row
                          Row(
                            children: [
                              _FeatureTag(
                                label: "Secure",
                                icon: Icons.shield_rounded,
                                accentColor: broker.accentColor,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _FeatureTag(
                                label: "Real-time",
                                icon: Icons.bolt_rounded,
                                accentColor: broker.accentColor,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _FeatureTag(
                                label: "API",
                                icon: Icons.api_rounded,
                                accentColor: broker.accentColor,
                                isDark: isDark,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Connect button
                          _ConnectButton(
                            accentColor: broker.accentColor,
                            isDark: isDark,
                            onTap: () => _openBroker(context, broker),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SUBWIDGETS ───────────────────────────────────────────────────────────────

class _BetaPill extends StatelessWidget {
  final bool isDark;

  const _BetaPill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark
              ? Colors.white.withOpacity(0.45)
              : Colors.black.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _FeatureTag({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: accentColor.withOpacity(0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor.withOpacity(0.9),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ConnectButton({
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor,
              accentColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDark ? 0.4 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.link_rounded,
              color: Colors.white,
              size: 15,
            ),
            SizedBox(width: 7),
            Text(
              'Connect Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ROUTING ─────────────────────────────────────────────────────────────────

void _openBroker(BuildContext context, BrokerData broker) {
  final Widget page = switch (broker.name) {
    "Zerodha" => const ZerodhaConnectPage(),
    "Fyers" => const FyersConnectPage(),
    "Upstox" => const UpstoxConnectPage(),
    _ => const ZerodhaConnectPage(),
  };

  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    ),
  );
}
