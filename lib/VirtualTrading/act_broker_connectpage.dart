// Modern Broker Connect Page
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/BrokersConnect/connect_fyers_page.dart';
import 'package:optionxi/BrokersConnect/connect_upstox_page.dart';
import 'package:optionxi/BrokersConnect/connect_zerodha_page.dart';
import 'package:optionxi/VirtualTrading/VDialogs/connect_broker_dialog.dart';

class BrokerConnectPage extends StatelessWidget {
  BrokerConnectPage({
    Key? key,
  }) : super(key: key);

  final List<Map<String, dynamic>> brokers = [
    {
      'name': 'Fyers',
      'logo': 'assets/brokers/fyers.png',
      'color': Color(0xFF26A69A),
      'subtitle': 'Technology-first broker with advanced APIs',
      'status': 'trending',
      'rating': 4.5,
      'features': ['API Trading', 'Low Brokerage', 'Charts'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FyersConnectPage()));
      }
    },
    {
      'name': 'Upstox',
      'logo': 'assets/brokers/upstox.png',
      'color': Color(0xFF5C6BC0),
      'subtitle': 'Advanced trading platform with pro tools',
      'status': 'new',
      'rating': 4.2,
      'features': ['Pro Platform', 'Options', 'Futures'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UpstoxConnectPage()));
      }
    },
    {
      'name': 'Zerodha',
      'logo': 'assets/brokers/kite.png',
      'color': Color(0xFF387ED1),
      'subtitle': 'India\'s largest discount broker',
      'status': 'popular',
      'rating': 4.8,
      'features': ['Kite Platform', 'Coin', 'Console'],
      'onTap': (BuildContext context) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ZerodhaConnectPage()));
      }
    },
    {
      'name': 'Angel One',
      'logo': 'assets/brokers/angelone.png',
      'color': Color(0xFFFF7043),
      'subtitle': 'Smart investment & advisory solutions',
      'status': 'coming soon',
      'rating': 4.3,
      'features': ['SmartAPI', 'Advisory', 'Research'],
      'onTap': (BuildContext context) {
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (_) => const AngelOneConnectPage()));
      }
    },
    {
      'name': 'Groww',
      'logo': 'assets/brokers/groww.png',
      'color': Color(0xFF43D865),
      'subtitle': 'Simple & elegant investment platform',
      'status': 'coming soon',
      'rating': 4.4,
      'features': ['Stocks', 'Mutual Funds', 'IPO'],
      'onTap': (BuildContext context) {
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (_) => const GrowwConnectPage()));
      }
    },
    {
      'name': 'ICICI Direct',
      'logo': 'assets/brokers/icicidirect.png',
      'color': Color(0xFFFF6D00),
      'subtitle': 'Full-service broker with banking integration',
      'status': 'queued',
      'rating': 4.1,
      'features': ['Banking', 'Research', '3-in-1 Account'],
      'onTap': (BuildContext context) {
        showConnectionDialog(context, 'ICICI Direct');
      }
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: theme.colorScheme.onBackground, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Connect Broker',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeaderSection(theme),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModernBrokerCard(
                  context,
                  brokers[index],
                  isDark,
                  () => brokers[index]['onTap'](context),
                ),
                childCount: brokers.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.link,
          //       color: theme.primaryColor,
          //       size: 24,
          //     ),
          //     SizedBox(width: 12),
          //     Expanded(
          //       child: Text(
          //         'Connect & Trade Live',
          //         style: GoogleFonts.inter(
          //           fontSize: 18,
          //           fontWeight: FontWeight.w600,
          //           color: theme.colorScheme.onSurface,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          SizedBox(height: 12),
          Text(
            'Link your existing broker account to execute trades seamlessly. Your credentials are encrypted and secure.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBrokerCard(BuildContext context,
      Map<String, dynamic> broker, bool isDark, VoidCallback onTapFunction) {
    final theme = Theme.of(context);
    final isDisabled =
        ['coming soon', 'queued'].contains(broker['status']?.toLowerCase());

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDisabled ? null : onTapFunction,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabled
                    ? (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03))
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (broker['color'] as Color).withOpacity(0.1),
                  offset: Offset(0, 4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        _buildBrokerLogo(broker, isDisabled),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      broker['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: isDisabled
                                            ? theme.colorScheme.onSurface
                                                .withOpacity(0.4)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  // if (broker['rating'] != null)
                                  //   _buildRating(
                                  //       broker['rating'], theme, isDisabled),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                broker['subtitle'] as String,
                                style: GoogleFonts.inter(
                                  color: isDisabled
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.3)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDisabled)
                          Container(
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.fromLTRB(0, 32, 0, 0),
                            decoration: BoxDecoration(
                              color:
                                  (broker['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: broker['color'] as Color,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildFeatureTags(broker['features'], theme, isDisabled),
                  ],
                ),
                // Status chip
                if (broker['status'] != null)
                  Positioned(
                    top: -12,
                    right: -12,
                    child: _buildModernStatusChip(
                        broker['status'] as String, theme),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildBrokerLogo(Map<String, dynamic> broker, bool isDisabled) {
  //   return Container(
  //     width: 56,
  //     height: 56,
  //     decoration: BoxDecoration(
  //       color: (broker['color'] as Color).withOpacity(isDisabled ? 0.05 : 0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: (broker['color'] as Color).withOpacity(isDisabled ? 0.1 : 0.2),
  //         width: 1,
  //       ),
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(15),
  //       child: CachedNetworkImage(
  //         imageUrl: broker['logo'] as String,
  //         width: 32,
  //         height: 32,
  //         fit: BoxFit.contain,
  //         placeholder: (context, url) => Container(
  //           padding: EdgeInsets.all(12),
  //           child: CircularProgressIndicator(
  //             strokeWidth: 2,
  //             valueColor: AlwaysStoppedAnimation<Color>(
  //               (broker['color'] as Color).withOpacity(0.5),
  //             ),
  //           ),
  //         ),
  //         errorWidget: (context, url, error) => Container(
  //           padding: EdgeInsets.all(12),
  //           child: Icon(
  //             Icons.business,
  //             color: (broker['color'] as Color)
  //                 .withOpacity(isDisabled ? 0.3 : 0.7),
  //             size: 24,
  //           ),
  //         ),
  //         color: isDisabled ? Colors.grey.withOpacity(0.5) : null,
  //         colorBlendMode: isDisabled ? BlendMode.saturation : null,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBrokerLogo(Map<String, dynamic> broker, bool isDisabled) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: (broker['color'] as Color).withOpacity(isDisabled ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (broker['color'] as Color).withOpacity(isDisabled ? 0.1 : 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          broker['logo'] as String,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          color: isDisabled ? Colors.grey.withOpacity(0.5) : null,
          colorBlendMode: isDisabled ? BlendMode.saturation : null,
        ),
      ),
    );
  }

  // Widget _buildRating(double rating, ThemeData theme, bool isDisabled) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: isDisabled
  //           ? Colors.grey.withOpacity(0.1)
  //           : Colors.amber.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           Icons.star_rounded,
  //           size: 14,
  //           color: isDisabled ? Colors.grey : Colors.amber.shade600,
  //         ),
  //         SizedBox(width: 4),
  //         Text(
  //           rating.toString(),
  //           style: GoogleFonts.inter(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //             color: isDisabled
  //                 ? Colors.grey
  //                 : theme.colorScheme.onSurface.withOpacity(0.8),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFeatureTags(
      List<String> features, ThemeData theme, bool isDisabled) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.take(3).map((feature) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDisabled
                ? theme.colorScheme.onSurface.withOpacity(0.05)
                : theme.colorScheme.onSurface.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDisabled
                  ? theme.colorScheme.onSurface.withOpacity(0.05)
                  : theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            feature,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDisabled
                  ? theme.colorScheme.onSurface.withOpacity(0.3)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernStatusChip(String status, ThemeData theme) {
    Color chipColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'new':
        chipColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.new_releases_rounded;
        break;
      case 'popular':
        chipColor = Colors.purple;
        textColor = Colors.white;
        icon = Icons.trending_up_rounded;
        break;
      case 'trending':
        chipColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.whatshot_rounded;
        break;
      case 'coming soon':
        chipColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.schedule_rounded;
        break;
      case 'queued':
        chipColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.queue_rounded;
        break;
      default:
        chipColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.4),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
