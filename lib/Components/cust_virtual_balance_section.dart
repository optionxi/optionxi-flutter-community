import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/conversions.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({Key? key}) : super(key: key);

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  double? _balance;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _baselineBalance =
      Constants.INITAL_BAL_PREV; // 3L threshold

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _fetchBalance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _updateBalance(Constants.INITAL_BAL_PREV);
        return;
      }

      final response = await Supabase.instance.client
          .from('prev_balance')
          .select('balance')
          .eq('suid', user.uid)
          .maybeSingle();

      _updateBalance(response != null
          ? (response['balance'] as num).toDouble()
          : Constants.INITAL_BAL_PREV);
    } catch (e) {
      _updateBalance(Constants.INITAL_BAL_PREV);
    }
  }

  void _updateBalance(double bal) {
    if (mounted) {
      setState(() {
        _balance = bal;
        _isLoading = false;
      });
    }
  }

  /// true  → balance > 300k (profit)
  /// false → balance ≤ 300k (loss)
  bool get _isProfit => (_balance ?? 0) >= _baselineBalance;
  bool get _isExactBaseline => (_balance ?? 0) == _baselineBalance;

  /// Percentage change relative to the 300k baseline
  /// e.g. 360k → +20.00%   |   240k → -20.00%
  String get _percentageLabel {
    final bal = _balance ?? 0;
    final pct = ((bal - _baselineBalance) / _baselineBalance) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _fetchBalance,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF111318) : const Color(0xFFFAFAFC),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconBadge(isDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIRTUAL BALANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: isDark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.black.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _isLoading
                        ? _buildSkeletonLoader(isDark)
                        : _buildBalanceRow(isDark),
                  ],
                ),
              ),
              _buildRefreshIndicator(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance amount + percentage pill side by side ────────────────────────
  Widget _buildBalanceRow(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBalanceText(isDark),
        const SizedBox(width: 8),
        if (!_isExactBaseline) ...[
          const SizedBox(width: 8),
          _buildPercentagePill(isDark),
        ],
      ],
    );
  }

  Widget _buildBalanceText(bool isDark) {
    final Color positiveColor =
        isDark ? const Color(0xFF00E676) : const Color(0xFF1B8C3E);
    final Color negativeColor =
        isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C);

    return Text(
      '₹${convertToKMB(_balance?.toString() ?? '0')}',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: _isProfit ? positiveColor : negativeColor,
        height: 1.1,
      ),
    );
  }

  Widget _buildPercentagePill(bool isDark) {
    // Profit colours
    const Color profitBgDark = Color(0xFF00E676);
    const Color profitBgLight = Color(0xFF1B8C3E);

    // Loss colours
    const Color lossBgDark = Color(0xFFFF5252);
    const Color lossBgLight = Color(0xFFB71C1C);

    final Color bgColor = _isProfit
        ? (isDark ? profitBgDark : profitBgLight)
        : (isDark ? lossBgDark : lossBgLight);

    final String arrow = _isProfit ? '▲' : '▼';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bgColor.withOpacity(0.35), width: 0.5),
      ),
      child: Text(
        '$arrow $_percentageLabel',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: bgColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── Icon badge (wallet) ──────────────────────────────────────────────────
  Widget _buildIconBadge(bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1C6EF5), const Color(0xFF0A4ECC)]
              : [const Color(0xFF2979FF), const Color(0xFF1A56E8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(isDark ? 0.3 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        size: 19,
        color: Colors.white,
      ),
    );
  }

  // ── Skeleton loader ──────────────────────────────────────────────────────
  Widget _buildSkeletonLoader(bool isDark) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        height: 26,
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.07),
        ),
      ),
    );
  }

  // ── Refresh button ───────────────────────────────────────────────────────
  Widget _buildRefreshIndicator(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
      ),
      child: Icon(
        Icons.refresh_rounded,
        size: 16,
        color: isDark
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.25),
      ),
    );
  }
}
