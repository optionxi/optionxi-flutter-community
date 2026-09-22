import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:optionxi/Components/cust_contact_us.dart';

String get _kRazorApiBase => dotenv.env['RAZORPAY_API_URL']!;

class SubscriptionHistoryItem {
  final String planKey;
  final String? planName;
  final String
      action; // new | renewed | upgraded | downgraded | expired | cancelled
  final String? previousPlanKey;
  final int? amount; // paise
  final String currency;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  SubscriptionHistoryItem({
    required this.planKey,
    this.planName,
    required this.action,
    this.previousPlanKey,
    this.amount,
    required this.currency,
    required this.startsAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory SubscriptionHistoryItem.fromMap(Map<String, dynamic> map) {
    return SubscriptionHistoryItem(
      planKey: map['plan_key'] as String? ?? '',
      planName: map['plan_name'] as String?,
      action: map['action'] as String? ?? 'new',
      previousPlanKey: map['previous_plan_key'] as String?,
      amount: map['amount'] as int?,
      currency: map['currency'] as String? ?? 'INR',
      startsAt: DateTime.parse(map['starts_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedAmount {
    if (amount == null) return '—';
    final rupees = amount! / 100;
    final symbol = currency == 'INR' ? '₹' : currency;
    return '$symbol${rupees.toStringAsFixed(rupees == rupees.roundToDouble() ? 0 : 2)}';
  }
}

class _HistoryService {
  static Future<List<SubscriptionHistoryItem>> fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You need to be signed in.');
    final idToken = await user.getIdToken();
    final resp = await http.get(
      Uri.parse('$_kRazorApiBase/payments/history'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Could not load billing history.');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (body['history'] as List? ?? []);
    return list
        .map((e) => SubscriptionHistoryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  late Future<List<SubscriptionHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _HistoryService.fetch();
  }

  Future<void> _refresh() async {
    setState(() => _future = _HistoryService.fetch());
    await _future;
  }

  void _onContactSupport() {
    showContactOptions(context);
  }

  Color _actionColor(String action, ThemeData theme) {
    switch (action) {
      case 'cancelled':
      case 'expired':
        return const Color(0xFFEF4444);
      case 'upgraded':
      case 'new':
        return const Color(0xFF22C55E);
      case 'downgraded':
        return const Color(0xFFF59E0B);
      default: // renewed
        return theme.colorScheme.primary;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.hourglass_bottom_rounded;
      case 'upgraded':
        return Icons.arrow_upward_rounded;
      case 'downgraded':
        return Icons.arrow_downward_rounded;
      case 'renewed':
        return Icons.autorenew_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Billing History')),
      body: SafeArea(
        child: FutureBuilder<List<SubscriptionHistoryItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HistorySkeletonList();
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 40, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                      _SupportFooter(
                        theme: theme,
                        onContactSupport: _onContactSupport,
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Center(child: Text('No billing history yet.')),
                    _SupportFooter(
                      theme: theme,
                      onContactSupport: _onContactSupport,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length + 1,
                itemBuilder: (context, i) {
                  if (i == items.length) {
                    return _SupportFooter(
                      theme: theme,
                      onContactSupport: _onContactSupport,
                    );
                  }
                  final item = items[i];
                  final color = _actionColor(item.action, theme);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_actionIcon(item.action),
                              color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.planName ?? item.planKey,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                    ),
                                  ),
                                  Text(item.formattedAmount,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.action[0].toUpperCase()}${item.action.substring(1)} · ${_fmtDate(item.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (item.expiresAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${_fmtDate(item.startsAt)} → ${_fmtDate(item.expiresAt!)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lightweight shimmer skeleton for the billing history list.
/// No external shimmer package — just an opacity pulse via AnimationController.
class _HistorySkeletonList extends StatefulWidget {
  const _HistorySkeletonList();

  @override
  State<_HistorySkeletonList> createState() => _HistorySkeletonListState();
}

class _HistorySkeletonListState extends State<_HistorySkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(begin: 0.35, end: 0.85)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (context, i) {
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Opacity(opacity: _pulse.value, child: child);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: 38,
                  height: 38,
                  radius: 19,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SkeletonBox(
                                height: 15, radius: 4, theme: theme),
                          ),
                          const SizedBox(width: 12),
                          _SkeletonBox(
                              width: 60, height: 15, radius: 4, theme: theme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _SkeletonBox(
                          width: 140, height: 12, radius: 4, theme: theme),
                      const SizedBox(height: 6),
                      _SkeletonBox(
                          width: 110, height: 12, radius: 4, theme: theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final ThemeData theme;

  const _SkeletonBox({
    this.width,
    required this.height,
    required this.radius,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SupportFooter extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onContactSupport;
  const _SupportFooter({required this.theme, required this.onContactSupport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: TextButton.icon(
          onPressed: onContactSupport,
          icon: Icon(Icons.headset_mic_outlined,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          label: Text(
            'Have a doubt? Contact Support',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
