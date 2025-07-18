import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStatsWidget extends StatefulWidget {
  const ProfileStatsWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileStatsWidget> createState() => _ProfileStatsWidgetState();
}

class _ProfileStatsWidgetState extends State<ProfileStatsWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTradeStats();
  }

  Future<void> _fetchTradeStats() async {
    var userId = FirebaseAuth.instance.currentUser!.uid.toString();
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final response = await Supabase.instance.client
          .from('prev_trade_history')
          .select()
          .eq('suid', userId);

      if (response.isEmpty) {
        setState(() {
          _stats = null;
          _isLoading = false;
        });
        return;
      }

      // Calculate stats
      double totalProfitLoss = 0;
      int totalTrades = response.length;
      int winningTrades = 0;

      for (var trade in response) {
        double profitLoss = (trade['profit_loss'] ?? 0).toDouble();
        totalProfitLoss += profitLoss;
        if (profitLoss > 0) {
          winningTrades++;
        }
      }

      double winRate =
          totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;

      if (mounted) {
        setState(() {
          _stats = {
            'totalProfit': totalProfitLoss,
            'winRate': winRate,
            'totalTrades': totalTrades,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container();
    }

    if (_error != null) {
      return Container();
    }

    if (_stats == null) {
      return Container();
    }

    return _buildStatsContainer();
  }

  Widget _buildStatsContainer() {
    final theme = Theme.of(context);
    final totalProfit = _stats!['totalProfit'];
    final winRate = _stats!['winRate'];
    final totalTrades = _stats!['totalTrades'];

    final isProfitPositive = totalProfit > 0;
    final profitColor = isProfitPositive ? Colors.green : Colors.red;

    final isWinRatePositive = winRate > 0;
    final winRateColor = isWinRatePositive ? Colors.green : Colors.red;

    final isTradesPositive = totalTrades > 0;
    final tradesColor = isTradesPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            "Total Profit",
            "₹${convertToKMB(_stats!['totalProfit'].toStringAsFixed(0))}",
            Icons.trending_up,
            theme,
            textColor: profitColor,
            borderColor: profitColor,
          ),
          _buildStatItem(
            "Win Rate",
            "${_stats!['winRate'].toStringAsFixed(1)}%",
            Icons.auto_graph,
            theme,
            textColor: winRateColor,
            borderColor: winRateColor,
          ),
          _buildStatItem(
            "Total Trades",
            "${_stats!['totalTrades']}",
            Icons.currency_exchange,
            theme,
            textColor: tradesColor,
            borderColor: tradesColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, ThemeData theme,
      {Color? textColor, Color? borderColor}) {
    final defaultBorderColor = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? defaultBorderColor!, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor ?? theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onBackground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
