import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Helpers/conversions.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({
    Key? key,
  }) : super(key: key);

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  double? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _balance = Constants.INITAL_BAL_PREV;
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('prev_balance')
          .select('balance')
          .eq('suid', user.uid)
          .maybeSingle();

      setState(() {
        _balance = response != null
            ? (response['balance'] as num).toDouble()
            : Constants.INITAL_BAL_PREV;
        _isLoading = false;
      });
    } catch (e) {
      // In case of any error, use default balance
      setState(() {
        _balance = Constants.INITAL_BAL_PREV;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Text(
            'Virtual Balance:',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const Spacer(),
          _isLoading
              ? Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )
              : Text(
                  '₹${convertToKMB(_balance?.toString() ?? '0')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
        ],
      ),
    );
  }
}
