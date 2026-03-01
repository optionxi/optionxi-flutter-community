import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// --- YOUR IMPORTS ---
import 'package:optionxi/BrokersConnect/connect_fyers_page.dart';
import 'package:optionxi/BrokersConnect/connect_upstox_page.dart';
import 'package:optionxi/BrokersConnect/connect_zerodha_page.dart';
import 'package:optionxi/VirtualTrading/VDialogs/connect_broker_dialog.dart';

class BrokerConnectPage extends StatelessWidget {
  BrokerConnectPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> brokers = [
    {
      'name': 'Fyers',
      'logo': 'assets/brokers/fyers.png',
      'color': const Color(0xFF26A69A),
      'subtitle': 'API First • Low Latency',
      'status': 'trending',
      'isActive': true,
      'features': ['Free API', 'TradingView', 'Option Chain'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FyersConnectPage()));
      }
    },
    {
      'name': 'Zerodha',
      'logo': 'assets/brokers/kite.png',
      'color': const Color(0xFF387ED1),
      'subtitle': 'Kite Connect • No.1 Broker',
      'status': 'popular',
      'isActive': true,
      'features': ['Kite Web', 'Coin', 'Console'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ZerodhaConnectPage()));
      }
    },
    {
      'name': 'Upstox',
      'logo': 'assets/brokers/upstox.png',
      'color': const Color(0xFF5C6BC0),
      'subtitle': 'RKSV • Pro Trading Tools',
      'status': 'new',
      'isActive': true,
      'features': ['Fast Execution', 'Strategy Builder'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UpstoxConnectPage()));
      }
    },
    {
      'name': 'Angel One',
      'logo': 'assets/brokers/angelone.png',
      'color': const Color(0xFFFF7043),
      'subtitle': 'Smart API • Full Service',
      'status': 'coming soon',
      'isActive': false,
      'features': ['Advisory', 'Robo Order', 'Smart API'],
      'onTap': (BuildContext context) {}
    },
    {
      'name': 'Groww',
      'logo': 'assets/brokers/groww.png',
      'color': const Color(0xFF43D865),
      'subtitle': 'Simple Investing',
      'status': 'queued',
      'isActive': false,
      'features': ['Direct MF', 'Stocks'],
      'onTap': (BuildContext context) {}
    },
    {
      'name': 'ICICI Direct',
      'logo': 'assets/brokers/icicidirect.png',
      'color': const Color(0xFFFF6D00),
      'subtitle': 'Breeze API • Banking',
      'status': 'queued',
      'isActive': false,
      'features': ['3-in-1', 'Research', 'Margin'],
      'onTap': (BuildContext context) {
        showConnectionDialog(context, 'ICICI Direct');
      }
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Modern background color
    final backgroundColor =
        isDark ? const Color(0xFF0F1115) : const Color(0xFFF2F4F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernHeader(context, theme, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _BrokerCard(
                    broker: brokers[index],
                    isDark: isDark,
                  );
                },
                childCount: brokers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(
      BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        'Connect Broker',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  final Map<String, dynamic> broker;
  final bool isDark;

  const _BrokerCard({
    Key? key,
    required this.broker,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = broker['isActive'] as bool;
    final primaryColor = broker['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF9EA3B0).withOpacity(0.2), // Soft shadow
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isActive
              ? () {
                  HapticFeedback.lightImpact();
                  broker['onTap'](context);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Column(
                children: [
                  // Top Row: Logo, Info, Connect Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogo(primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  broker['name'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                // if (broker['status'] != null && isActive) ...[
                                //   const SizedBox(width: 8),
                                //   _buildStatusBadge(broker['status']),
                                // ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              broker['subtitle'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildConnectButton(isActive, primaryColor),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                  ),

                  const SizedBox(height: 12),

                  // Features List
                  _buildFeaturesList(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color color) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Image.asset(
        broker['logo'],
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => Icon(Icons.show_chart, color: color),
      ),
    );
  }

  Widget _buildConnectButton(bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Text(
        isActive ? 'Connect' : 'Soon',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  // Widget _buildStatusBadge(String status) {
  //   Color badgeColor;
  //   switch (status) {
  //     case 'popular':
  //       badgeColor = Colors.orange;
  //       break;
  //     case 'new':
  //       badgeColor = Colors.green;
  //       break;
  //     case 'trending':
  //       badgeColor = Colors.purple;
  //       break;
  //     default:
  //       badgeColor = Colors.blue;
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //     decoration: BoxDecoration(
  //       color: badgeColor.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(6),
  //     ),
  //     child: Text(
  //       status.toUpperCase(),
  //       style: GoogleFonts.inter(
  //         fontSize: 9,
  //         fontWeight: FontWeight.w700,
  //         color: badgeColor,
  //         letterSpacing: 0.5,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFeaturesList(ThemeData theme) {
    final features = broker['features'] as List<String>;
    return Row(
      children: features.take(3).map((feature) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 14, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                feature,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
