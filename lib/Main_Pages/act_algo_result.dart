import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BacktestResultPage extends StatefulWidget {
  final String algoId;
  final String algoName;

  const BacktestResultPage({
    Key? key,
    required this.algoId,
    required this.algoName,
  }) : super(key: key);

  @override
  State<BacktestResultPage> createState() => _BacktestResultPageState();
}

class _BacktestResultPageState extends State<BacktestResultPage>
    with SingleTickerProviderStateMixin {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String status = "initializing";
  Map<dynamic, dynamic>? summary;
  List<dynamic>? trades;
  String errorMessage = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _listenToStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listenToStatus() {
    db.ref('backtest_queue/$uid/${widget.algoId}').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        setState(() {
          status = data['status'];
          if (data.containsKey('message') && status == 'error') {
            errorMessage = data['message'];
          }
        });

        if (status == 'completed') {
          _fetchResults();
        }
      }
    });
  }

  Future<void> _fetchResults() async {
    final snap = await db.ref('backtest_results/$uid/${widget.algoId}').get();
    if (snap.exists) {
      final data = snap.value as Map;
      setState(() {
        summary = data['summary'];
        trades = data['trades'];
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.algoName),
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        actions: [
          if (status == 'completed')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              tooltip: 'Share Results',
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (status == 'queued' || status == 'running' || status == 'initializing') {
      return _buildLoadingState(isDark);
    }

    if (status == 'error') {
      return _buildErrorState(isDark);
    }

    if (summary == null) {
      return _buildLoadingState(isDark);
    }

    return _buildResultsView(isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.indigoAccent,
                  ),
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                size: 40,
                color: Colors.indigoAccent.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Running Backtest",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.indigoAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Analyzing market data and calculating performance metrics...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Backtest Failed",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage.isNotEmpty
                          ? errorMessage
                          : "An unexpected error occurred during backtesting",
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(bool isDark) {
    final totalPnl = summary!['total_pnl'] ?? 0;
    final isProfitable = totalPnl >= 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Stats Card
            _buildHeroCard(isDark, totalPnl, isProfitable),

            const SizedBox(height: 16),

            // Performance Metrics Grid
            _buildMetricsGrid(isDark),

            const SizedBox(height: 24),

            // Trade History Section
            _buildTradeHistorySection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark, dynamic totalPnl, bool isProfitable) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isProfitable
              ? [Colors.green[700]!, Colors.green[500]!]
              : [Colors.red[700]!, Colors.red[500]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProfitable ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total P&L',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfitable ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfitable ? 'Profit' : 'Loss',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatNumber(totalPnl),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final winRate = summary!['win_rate'] ?? 0;
    final totalTrades = summary!['total_trades'] ?? 0;

    // Calculate winning and losing trades from actual trade data
    int winningTrades = 0;
    int losingTrades = 0;
    double totalDurationMinutes = 0;
    int validDurationTrades = 0;

    if (trades != null) {
      for (var trade in trades!) {
        final pnl = trade['pnl'] ?? 0;
        if (pnl > 0) {
          winningTrades++;
        } else if (pnl < 0) {
          losingTrades++;
        }

        try {
          final entry = DateTime.parse(trade['entry_time']);
          final exit = DateTime.parse(trade['exit_time']);
          final diffMinutes = exit.difference(entry).inSeconds / 60;

          if (diffMinutes > 0) {
            totalDurationMinutes += diffMinutes;
            validDurationTrades++;
          }
        } catch (_) {
          // ignore invalid timestamps
        }
      }
    }

    // Calculate average duration
    String avgDuration = 'N/A';

    if (validDurationTrades > 0) {
      final avgMinutes = totalDurationMinutes / validDurationTrades;
      final roundedMinutes = avgMinutes.round();

      if (roundedMinutes >= 60) {
        final hours = roundedMinutes ~/ 60;
        final mins = roundedMinutes % 60;
        avgDuration = '${hours}h ${mins}m';
      } else {
        avgDuration = '${roundedMinutes}m';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark,
                cardColor,
                'Total Trades',
                totalTrades.toString(),
                Icons.swap_horiz,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                isDark,
                cardColor,
                'Win Rate',
                '${winRate.toStringAsFixed(1)}%',
                Icons.percent,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark,
                cardColor,
                'Winners',
                winningTrades.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                isDark,
                cardColor,
                'Losers',
                losingTrades.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          isDark,
          cardColor,
          'Avg Hold Time',
          avgDuration,
          Icons.schedule,
          Colors.orange,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(bool isDark, Color? cardColor, String title,
      String value, IconData icon, Color color,
      {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isFullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTradeHistorySection(bool isDark) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trade History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (trades != null && trades!.isNotEmpty)
              Text(
                '${trades!.length} trades',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (trades == null || trades!.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No trades generated',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trades!.length,
            itemBuilder: (context, index) {
              return _buildTradeCard(trades![index], isDark, cardColor, index);
            },
          ),
      ],
    );
  }

  Widget _buildTradeCard(
    dynamic trade,
    bool isDark,
    Color? cardColor,
    int index,
  ) {
    final pnl = trade['pnl'] ?? 0;
    final isWin = pnl > 0;
    final statusColor = isWin ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Trade Number Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // P&L Display
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'P&L',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isWin ? Icons.arrow_upward : Icons.arrow_downward,
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${pnl.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isWin ? 'WIN' : 'LOSS',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trade Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]!.withOpacity(0.5)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildTradeDetailRow(
                    'Entry',
                    '₹${trade['entry_price']}',
                    _fmtDate(trade['entry_time']),
                    isDark,
                    Icons.login,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  _buildTradeDetailRow(
                    'Exit',
                    '₹${trade['exit_price']}',
                    _fmtDate(trade['exit_time']),
                    isDark,
                    Icons.logout,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  _buildTradeDurationRow(
                    _calculateDuration(trade['entry_time'], trade['exit_time']),
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeDetailRow(
    String label,
    String price,
    String time,
    bool isDark,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeDurationRow(String duration, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.schedule, size: 14, color: Colors.purple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Hold Time',
            style: TextStyle(
              fontSize: 10,
              color: Colors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, HH:mm').format(dt);
    } catch (e) {
      return raw;
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = number is String ? double.parse(number) : number;
    return num.abs().toStringAsFixed(2);
  }

  String _calculateDuration(String entryTime, String exitTime) {
    try {
      final entry = DateTime.parse(entryTime);
      final exit = DateTime.parse(exitTime);
      final duration = exit.difference(entry);

      if (duration.inDays > 0) {
        return '${duration.inDays}d ${duration.inHours % 24}h';
      } else if (duration.inHours > 0) {
        return '${duration.inHours}h ${duration.inMinutes % 60}m';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes}m';
      } else {
        return '${duration.inSeconds}s';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
