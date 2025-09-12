import 'package:flutter/material.dart';
import 'package:optionxi/BrokersConnect/connect_fyers_page.dart';
import 'package:optionxi/BrokersConnect/connect_upstox_page.dart';
import 'package:optionxi/BrokersConnect/connect_zerodha_page.dart';
import 'package:optionxi/VirtualTrading/act_broker_connectpage.dart';

/// -------- DATA MODEL --------
class BrokerData {
  final String name;
  final String subtitle; // e.g., API tagline
  final Color color;
  final IconData icon;
  final String assetimage;
  final bool hasApi; // for future conditional UI

  const BrokerData({
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.assetimage,
    this.hasApi = true,
  });
}

/// -------- BROKER LIST --------
final List<BrokerData> brokers = const [
  BrokerData(
    name: "Fyers",
    subtitle: "Fyers API",
    // color: Color(0xFF6200EA),
    color: Color(0xFF2962FF),
    assetimage: "assets/brokers/fyers.png",
    icon: Icons.show_chart,
  ),
  BrokerData(
    name: "Upstox",
    subtitle: "Upstox API",
    // color: Color(0xFFFF6D00),
    color: Color(0xFF6200EA),
    assetimage: "assets/brokers/upstox.png",
    icon: Icons.trending_up,
  ),
  BrokerData(
    name: "Zerodha",
    subtitle: "Kite Connect API",
    // color: Color(0xFF2962FF),
    color: Color.fromARGB(255, 227, 75, 36),
    assetimage: "assets/brokers/kite.png",
    icon: Icons.account_balance,
  ),
];

/// -------- MAIN SECTION WIDGET --------
Widget buildBrokerHub(BuildContext context, AnimationController controller) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate card width to fill around 2/3 of available width
      // final screenWidth = constraints.maxWidth;
      // final cardWidth = (screenWidth * 0.7).clamp(300.0, 400.0);
      final cardWidth = 310.0; // Set your desired fixed width here

      final cardSpacing = 20.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with enhanced styling
          _buildHeader(context),
          const SizedBox(height: 24),

          // Enhanced cards section - Back to sleek height
          SizedBox(
            height: 228, // Back to sleek original height
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: brokers.length,
              itemBuilder: (context, index) {
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(
                    right: index < brokers.length - 1 ? cardSpacing : 0,
                  ),
                  child: _buildBrokerCard(
                      context, brokers[index], index, controller),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildHeader(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Broker Connections',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect with your preferred broker',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrokerConnectPage(),
            ),
          );
        },
        child: const Text('View All'),
      ),
    ],
  );
}

/// -------- ENHANCED CARD BUILDER --------
Widget _buildBrokerCard(
  BuildContext context,
  BrokerData broker,
  int index,
  AnimationController controller,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          (0.1 * index).clamp(0.0, 0.8),
          (0.1 * index + 0.3).clamp(0.2, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    ),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Interval(
          (0.1 * index).clamp(0.0, 0.8),
          (0.1 * index + 0.4).clamp(0.2, 1.0),
          curve: Curves.easeOut,
        ),
      ),
      child: GestureDetector(
        onTap: () => _openBroker(context, broker),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: broker.color.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    broker.color,
                    broker.color.withOpacity(0.85),
                    broker.color.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          center: const Alignment(0.8, -0.8),
                          radius: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(18.0), // Sleek padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // solid white background
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    16), // same as container
                                child: Image.asset(
                                  broker
                                      .assetimage, // e.g., "assets/image/broker.png"
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit
                                      .cover, // ensures cutoff/fill inside rounded edges
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            // Broker name
                            Text(
                              broker.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20, // Slightly smaller for sleek look
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const Spacer(),
                            _cornerBadge(),
                          ],
                        ),

                        const SizedBox(height: 14), // Sleek spacing

                        // Subtitle
                        Text(
                          broker.subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13, // Smaller subtitle
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Spacer(), // Back to spacer for sleek distribution

                        // Feature badges - more compact
                        Row(
                          children: [
                            _enhancedFeatureBadge(
                                Icons.security_rounded, "Secure"),
                            const SizedBox(width: 8), // Reduced spacing
                            _enhancedFeatureBadge(
                                Icons.flash_on_rounded, "Fast"),
                            const SizedBox(width: 8),
                            _enhancedFeatureBadge(Icons.api_rounded, "API"),
                          ],
                        ),

                        const SizedBox(height: 12), // Sleek spacing

                        // Connect button - more compact
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: broker.color,
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10), // Reduced padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    14), // Slightly smaller radius
                              ),
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: () => _openBroker(context, broker),
                            icon: Icon(Icons.link_rounded,
                                size: 16), // Smaller icon
                            label: const Text(
                              "Connect Now",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14, // Smaller text
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
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

Widget _enhancedFeatureBadge(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.25),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        // const SizedBox(width: 4),
        // Text(
        //   label,
        //   style: const TextStyle(
        //     color: Colors.white,
        //     fontSize: 11,
        //     fontWeight: FontWeight.w600,
        //     letterSpacing: 0.3,
        //   ),
        // ),
      ],
    ),
  );
}

Widget _cornerBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.verified_rounded, color: Colors.white, size: 14),
        SizedBox(width: 6),
        Text(
          "Beta",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

/// -------- ROUTING TO EACH BROKER PAGE --------
void _openBroker(BuildContext context, BrokerData broker) {
  Widget page;
  switch (broker.name) {
    case "Zerodha":
      page = const ZerodhaConnectPage();
      break;
    case "Fyers":
      page = const FyersConnectPage();
      break;
    case "Upstox":
      page = const UpstoxConnectPage();
      break;
    default:
      page = const ZerodhaConnectPage();
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}
