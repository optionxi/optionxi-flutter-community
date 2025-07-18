import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/Main_Pages/act_alert_stocks.dart';
import 'package:optionxi/Main_Pages/act_atlas_page.dart';
import 'package:optionxi/Main_Pages/act_breakout_page.dart';
import 'package:optionxi/Main_Pages/act_scanner_page.dart';
import 'package:optionxi/Main_Pages/act_sectorwise_page.dart';
import 'package:optionxi/Main_Pages/act_topgainers_losers.dart';

class AdvancedTradingToolsPage extends StatefulWidget {
  const AdvancedTradingToolsPage({Key? key}) : super(key: key);

  @override
  _AdvancedTradingToolsPageState createState() =>
      _AdvancedTradingToolsPageState();
}

class _AdvancedTradingToolsPageState extends State<AdvancedTradingToolsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to get current theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color(0xFF0A0F1E),
                    Color(0xFF1A1F35),
                  ]
                : [
                    Colors.white,
                    Colors.grey[100]!,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildToolsSections(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trading Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                // Container(
                //   decoration: BoxDecoration(
                //     color: (isDark ? Colors.white : Colors.black)
                //         .withValues(alpha: 0.1),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: IconButton(
                //     icon: Icon(Icons.search,
                //         color: isDark ? Colors.white70 : Colors.black54),
                //     onPressed: () {},
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Unlock sophisticated trading strategies with our comprehensive toolset',
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSections(bool isDark) {
    // Define color maps for light/dark mode
    final tools = [
      {
        'title': 'Market Leaders',
        'icon': FontAwesomeIcons.trophy,
        'tools': [
          {
            'name': 'Top Gainers',
            'description':
                'Real-time tracking of stocks with highest percentage gains',
            'icon': FontAwesomeIcons.arrowTrendUp,
            'gradient': isDark
                ? [Color(0xFF4CAF50), Color(0xFF2196F3)]
                : [Color(0xFF81C784), Color(0xFF64B5F6)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopGainersLosersPage(
                      initialTab: StockMarketTab.topGainers),
                ),
              );
            },
          },
          {
            'name': 'Top Losers',
            'description':
                'Stocks experiencing significant percentage declines',
            'icon': FontAwesomeIcons.arrowTrendDown,
            'gradient': isDark
                ? [Color(0xFFF44336), Color(0xFFE91E63)]
                : [Color(0xFFEF5350), Color(0xFFEC407A)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopGainersLosersPage(
                      initialTab: StockMarketTab.topLosers),
                ),
              );
            },
          },
          {
            'name': 'Volume Leaders',
            'description':
                'Highest traded volume stocks with liquidity insights',
            'icon': FontAwesomeIcons.chartColumn,
            'gradient': isDark
                ? [Color(0xFFFF9800), Color(0xFFFF5722)]
                : [Color(0xFFFFB74D), Color(0xFFFF8A65)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopGainersLosersPage(
                      initialTab: StockMarketTab.topVolume),
                ),
              );
            },
          },
        ]
      },
      {
        'title': 'Pattern Scanners',
        'icon': FontAwesomeIcons.magnifyingGlassChart,
        'tools': [
          {
            'name': 'Daily Weekly Trends',
            'description':
                'Stocks with sustained bullish, bearish momentum period',
            'icon': FontAwesomeIcons.chartLine,
            'gradient': isDark
                ? [Color(0xFF009688), Color(0xFF00BCD4)]
                : [Color(0xFF4DB6AC), Color(0xFF4DD0E1)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockScreenerPage(),
                ),
              );
            },
          },
        ]
      },
      {
        'title': 'Breakout Alerts',
        'icon': FontAwesomeIcons.bell,
        'tools': [
          {
            'name': 'Stock Alerts',
            'description': 'Stocks breaking key annual price levels',
            'icon': FontAwesomeIcons.arrowUpRightDots,
            'gradient': isDark
                ? [Color(0xFF3F51B5), Color(0xFF9C27B0)]
                : [Color(0xFF7986CB), Color(0xFFBA68C8)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockAlertsPage(null),
                ),
              );
            },
          },
          {
            'name': 'Bollinger Breakouts',
            'description': 'Nifty stocks showing volatility expansion signals',
            'icon': FontAwesomeIcons.arrowsLeftRightToLine,
            'gradient': isDark
                ? [Color(0xFFFF9800), Color(0xFFFF5722)]
                : [Color(0xFFFFB74D), Color(0xFFFF8A65)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BollingerBreakoutsPage(),
                ),
              );
            },
          },
        ]
      },
      {
        'title': 'Market Sentiment',
        'icon': FontAwesomeIcons.globe,
        'tools': [
          {
            'name': 'Atlas Market Pulse',
            'description': 'Real-time bullish/bearish sentiment indicator',
            'icon': FontAwesomeIcons.gaugeHigh,
            'gradient': isDark
                ? [Color(0xFF607D8B), Color(0xFF455A64)]
                : [Color(0xFF90A4AE), Color(0xFF78909C)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AtlasOutputPage(),
                ),
              );
            },
          },
          {
            'name': 'Sector Heatmap',
            'description': 'Visual representation of sector performance',
            'icon': FontAwesomeIcons.fire,
            'gradient': isDark
                ? [Color(0xFFF44336), Color(0xFFFF9800)]
                : [Color(0xFFEF5350), Color(0xFFFFB74D)],
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SectorAnalysisPage(),
                ),
              );
            },
          },
        ]
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: tools.map((section) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(section['icon'] as IconData,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20),
                    ),
                    SizedBox(width: 16),
                    Text(
                      section['title'] as String,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              ...((section['tools'] as List).map((tool) {
                return _buildToolCard(tool, isDark);
              })),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool, bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.grey[100]!,
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: tool['onTap'] as VoidCallback?, // Pass the onTap function
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tool['gradient'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FaIcon(
                      tool['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool['name'],
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          tool['description'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.5),
                      size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
