// subscription_screen.dart
//
// Dependencies (add to pubspec.yaml if not already present):
//   supabase_flutter: ^2.0.0
//   url_launcher: ^6.2.0
//
// Adjust the two relative imports below to match where LinkPhoneScreen and
// showContactOptions actually live in your project.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/SubscriptionsRazorpay/act_manage_subscription_screen.dart';
import 'package:optionxi/Main_Pages/SubscriptionsRazorpay/helper_razorpay.dart';
import 'package:optionxi/MobileLink/link_phone_screen.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:optionxi/Components/cust_contact_us.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens (kept consistent with the rest of the app)
// ─────────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const radius = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 26.0;
}

String get _kApiBase => dotenv.env['PHONELINK_URL']!;
String get _kRazorApiBase => dotenv.env['RAZORPAY_API_URL']!;

// ─────────────────────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionPlan {
  final String id;
  final String planKey;
  final String name;
  final String? tagline;
  final double price;
  final String currency;
  final String billingPeriod;
  final List<String> features;
  final String paymentLink;
  final bool isPopular;
  final int? screenerLimit;

  const SubscriptionPlan({
    required this.id,
    required this.planKey,
    required this.name,
    this.tagline,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    required this.paymentLink,
    required this.isPopular,
    this.screenerLimit,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'].toString(),
      planKey: map['plan_key'] as String? ?? '',
      name: map['name'] as String? ?? 'Plan',
      tagline: map['tagline'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'INR',
      billingPeriod: map['billing_period'] as String? ?? 'month',
      features: ((map['features'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      paymentLink: map['payment_link'] as String? ?? '',
      isPopular: map['is_popular'] as bool? ?? false,
      screenerLimit: map['screener_limit'] as int?,
    );
  }

  String get currencySymbol => currency == 'INR' ? '₹' : currency;

  String get formattedPrice {
    final isWhole = price == price.roundToDouble();
    return isWhole ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  }
}

class WhatsAppStatus {
  final bool isVerified;
  final String? phone;
  const WhatsAppStatus({required this.isVerified, this.phone});
}

class ActiveSubscription {
  final String? planKey;
  final DateTime? expiresAt;
  const ActiveSubscription({this.planKey, this.expiresAt});

  bool get isActive =>
      planKey != null &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data services
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionApiException implements Exception {
  final String message;
  const SubscriptionApiException(this.message);
  @override
  String toString() => message;
}

class _PlansService {
  static Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      final rows = await Supabase.instance.client
          .from('subscription_plans')
          .select()
          .eq("is_enabled", true)
          .order('sort_order', ascending: true);
      return (rows as List)
          .map((row) => SubscriptionPlan.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const SubscriptionApiException(
          'Could not load subscription plans.');
    }
  }
}

class _WhatsAppStatusService {
  static Future<WhatsAppStatus> checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const SubscriptionApiException('You need to be signed in.');
    }
    try {
      final resp = await http
          .post(
            Uri.parse('$_kApiBase/otp/status'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'firebase_uid': user.uid}),
          )
          .timeout(const Duration(seconds: 15));
      final body = _parseBody(resp);
      if (resp.statusCode != 200) {
        throw SubscriptionApiException(
            body['detail'] as String? ?? 'Could not check WhatsApp status.');
      }
      return WhatsAppStatus(
        isVerified: body['is_verified'] as bool? ?? false,
        phone: body['phone'] as String?,
      );
    } on SubscriptionApiException {
      rethrow;
    } catch (_) {
      throw const SubscriptionApiException(
          'Could not reach the server. Check your connection.');
    }
  }

  static Map<String, dynamic> _parseBody(http.Response resp) {
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

class _SubscriptionStatusService {
  static Future<ActiveSubscription> fetchCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const SubscriptionApiException('You need to be signed in.');
    }
    try {
      final idToken = await user.getIdToken();
      final resp = await http.get(
        Uri.parse('${_kRazorApiBase}/payments/current-subscription'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw const SubscriptionApiException(
            'Could not load your subscription.');
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return ActiveSubscription(
        planKey: body['active_plan_key'] as String?,
        expiresAt: body['expires_at'] != null
            ? DateTime.tryParse(body['expires_at'] as String)
            : null,
      );
    } on SubscriptionApiException {
      rethrow;
    } catch (_) {
      throw const SubscriptionApiException('Could not reach the server.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────
enum _LoadState { loading, error, ready }

class SubscriptionScreenRazorPay extends StatefulWidget {
  const SubscriptionScreenRazorPay({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreenRazorPay> createState() =>
      _SubscriptionScreenRazorPayState();
}

class _SubscriptionScreenRazorPayState
    extends State<SubscriptionScreenRazorPay> {
  _LoadState _state = _LoadState.loading;
  String _errorMessage = '';

  List<SubscriptionPlan> _plans = [];
  bool _isVerified = false;
  String? _verifiedPhone;
  ActiveSubscription _activeSubscription = const ActiveSubscription();

  bool _launchingPlanId = false;
  String? _launchingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = '';
    });
    try {
      final results = await Future.wait([
        _PlansService.fetchPlans(),
        _WhatsAppStatusService.checkStatus(),
        _SubscriptionStatusService.fetchCurrent(),
      ]);
      final plans = results[0] as List<SubscriptionPlan>;
      final status = results[1] as WhatsAppStatus;
      final activeSub = results[2] as ActiveSubscription;
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isVerified = status.isVerified;
        _verifiedPhone = status.phone;
        _activeSubscription = activeSub;
        _state = _LoadState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = _LoadState.error;
      });
    }
  }

  Future<void> _recheckVerification() async {
    try {
      final status = await _WhatsAppStatusService.checkStatus();
      if (!mounted) return;
      setState(() {
        _isVerified = status.isVerified;
        _verifiedPhone = status.phone;
      });
    } catch (_) {
      // Silently ignore — the banner just stays as-is until the next pull-to-refresh.
    }
  }

  Future<void> _goVerifyNumber() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LinkPhoneScreen()),
    );
    if (!mounted) return;
    _recheckVerification();
  }

  Future<void> _manageSubscription() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageSubscriptionScreen()),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (!_isVerified) {
      _goVerifyNumber();
      return;
    }
    if (plan.paymentLink.isEmpty) {
      _showSnack('This plan isn\'t available for purchase right now.',
          isError: true);
      return;
    }
    setState(() {
      _launchingPlanId = true;
      _launchingId = plan.id;
    });
    try {
      //Creating the payment Link using the helper function from helper_razorpay.dart
      var url = await createPaymentLink(
          phone: _verifiedPhone ?? '', planKey: plan.planKey);

      //Opening the payment link in an external browser
      if (_verifiedPhone != null && _verifiedPhone!.isNotEmpty) {
        final sep = url.contains('?') ? '&' : '?';
        url =
            '$url${sep}prefill[contact]=${Uri.encodeComponent(_verifiedPhone!)}';
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnack('Could not open the payment page.', isError: true);
      }
    } catch (_) {
      _showSnack('Could not open the payment page.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _launchingPlanId = false;
          _launchingId = null;
        });
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_state) {
      case _LoadState.loading:
        return _LoadingView(key: const ValueKey('loading'), theme: theme);
      case _LoadState.error:
        return _ErrorView(
          key: const ValueKey('error'),
          theme: theme,
          message: _errorMessage,
          onRetry: _load,
          onContactSupport: () => showContactOptions(context),
        );
      case _LoadState.ready:
        return RefreshIndicator(
          onRefresh: _load,
          child: _ReadyView(
            key: const ValueKey('ready'),
            theme: theme,
            plans: _plans,
            isVerified: _isVerified,
            verifiedPhone: _verifiedPhone,
            activeSubscription: _activeSubscription,
            launchingId: _launchingPlanId ? _launchingId : null,
            onVerify: _goVerifyNumber,
            onSubscribe: _subscribe,
            onContactSupport: () => showContactOptions(context),
            onManageSubscription: _manageSubscription,
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading state
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatefulWidget {
  final ThemeData theme;
  const _LoadingView({super.key, required this.theme});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E8F0);

    Widget block(double width, double height, {double radius = 10}) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Opacity(
          opacity: 0.5 + 0.5 * _pulseCtrl.value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );
    }

    Widget skeletonCard() => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(_Tokens.radiusLg),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(90, 18),
              const SizedBox(height: 12),
              block(140, 30),
              const SizedBox(height: 18),
              block(double.infinity, 14),
              const SizedBox(height: 10),
              block(double.infinity, 14),
              const SizedBox(height: 10),
              block(180, 14),
              const SizedBox(height: 18),
              block(double.infinity, 48, radius: _Tokens.radius),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading your plans…',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          skeletonCard(),
          skeletonCard(),
          skeletonCard(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error state
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContactSupport;

  const _ErrorView({
    super.key,
    required this.theme,
    required this.message,
    required this.onRetry,
    required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 28),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message.isEmpty
                ? 'We couldn\'t load subscription plans. Please try again.'
                : message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radius)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onContactSupport,
              icon: const Icon(Icons.headset_mic_rounded, size: 18),
              label: const Text('Contact Support'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radius)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ready state
// ─────────────────────────────────────────────────────────────────────────────
class _ReadyView extends StatelessWidget {
  final ThemeData theme;
  final List<SubscriptionPlan> plans;
  final bool isVerified;
  final String? verifiedPhone;
  final ActiveSubscription activeSubscription;
  final String? launchingId;
  final VoidCallback onVerify;
  final ValueChanged<SubscriptionPlan> onSubscribe;
  final VoidCallback onContactSupport;
  final VoidCallback onManageSubscription;

  const _ReadyView({
    super.key,
    required this.theme,
    required this.plans,
    required this.isVerified,
    required this.verifiedPhone,
    required this.activeSubscription,
    required this.launchingId,
    required this.onVerify,
    required this.onSubscribe,
    required this.onContactSupport,
    required this.onManageSubscription,
  });

  SubscriptionPlan? get _currentPlan {
    if (!activeSubscription.isActive) return null;
    for (final p in plans) {
      if (p.planKey == activeSubscription.planKey) return p;
    }
    return null;
  }

  void _openSwitchPlanSheet(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SwitchPlanSheet(
        theme: theme,
        plan: plan,
        onContactSupport: () {
          Navigator.pop(sheetContext);
          onContactSupport();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPlan;
    final hasActive = activeSubscription.isActive;
    final otherPlans = plans
        .where((p) => !hasActive || p.planKey != current?.planKey)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          hasActive ? 'Your subscription' : 'Choose the plan that fits you',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasActive
              ? 'You\'re all set. Manage your plan or explore other options below.'
              : (isVerified
                  ? 'Your WhatsApp number is verified — pick a plan to get started.'
                  : 'Verify your WhatsApp number first, then pick a plan.'),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // ── Active subscription: hero treatment ──
        if (hasActive && current != null) ...[
          _CurrentPlanHero(
            theme: theme,
            plan: current,
            expiresAt: activeSubscription.expiresAt!,
            onManage: onManageSubscription,
          ),
          const SizedBox(height: 28),
        ],

        if (!hasActive && !isVerified) ...[
          _VerifyBanner(theme: theme, onVerify: onVerify),
          const SizedBox(height: 20),
        ],

        // ── Other plans ──
        if (otherPlans.isNotEmpty) ...[
          if (hasActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text(
                'OTHER PLANS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          if (hasActive)
            // Compact, low-emphasis rows — Spotify/Netflix style "other plans" list
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(_Tokens.radiusLg),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < otherPlans.length; i++) ...[
                    _CompactPlanRow(
                      theme: theme,
                      plan: otherPlans[i],
                      onTap: () => _openSwitchPlanSheet(context, otherPlans[i]),
                    ),
                    if (i != otherPlans.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.08),
                      ),
                  ],
                ],
              ),
            )
          else
            // No active plan yet — full-detail cards to help the first decision
            ...otherPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanCard(
                  theme: theme,
                  plan: plan,
                  isVerified: isVerified,
                  isLaunching: launchingId == plan.id,
                  onSubscribe: () => onSubscribe(plan),
                ),
              ),
            ),
        ],

        const SizedBox(height: 12),
        _SupportFooter(theme: theme, onContactSupport: onContactSupport),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Current plan hero (Spotify/Netflix-style "you're subscribed" card)
// ─────────────────────────────────────────────────────────────────────────────
class _CurrentPlanHero extends StatelessWidget {
  final ThemeData theme;
  final SubscriptionPlan plan;
  final DateTime expiresAt;
  final VoidCallback onManage;

  const _CurrentPlanHero({
    required this.theme,
    required this.plan,
    required this.expiresAt,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 3;
    final formattedDate = DateFormat('MMM d, yyyy').format(expiresAt);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, Colors.black, 0.35) ?? primary,
          ],
        ),
        borderRadius: BorderRadius.circular(_Tokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (plan.tagline != null && plan.tagline!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.tagline!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                isExpiringSoon
                    ? Icons.error_outline_rounded
                    : Icons.event_repeat_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                isExpiringSoon
                    ? 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}'
                    : 'Renews on $formattedDate',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onManage,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radius)),
              ),
              child: const Text(
                'Manage Plan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Compact row for other plans (shown once a plan is active)
// ─────────────────────────────────────────────────────────────────────────────
class _CompactPlanRow extends StatelessWidget {
  final ThemeData theme;
  final SubscriptionPlan plan;
  final VoidCallback onTap;

  const _CompactPlanRow({
    required this.theme,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.currencySymbol}${plan.formattedPrice} / ${plan.billingPeriod}',
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ],
              ),
            ),
            Text(
              'Details',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Switch-plan bottom sheet — since plan changes aren't self-serve yet,
//  this shows what the plan includes and routes to support instead of
//  pretending an in-app upgrade/downgrade happens.
// ─────────────────────────────────────────────────────────────────────────────
class _SwitchPlanSheet extends StatelessWidget {
  final ThemeData theme;
  final SubscriptionPlan plan;
  final VoidCallback onContactSupport;

  const _SwitchPlanSheet({
    required this.theme,
    required this.plan,
    required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_Tokens.radiusXl),
            topRight: Radius.circular(_Tokens.radiusXl),
          ),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${plan.currencySymbol}${plan.formattedPrice}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 3),
                  child: Text('/ ${plan.billingPeriod}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
            if (plan.tagline != null && plan.tagline!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(plan.tagline!,
                  style: TextStyle(
                      fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(_Tokens.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan changes are handled by our support team so any billing adjustment is done correctly.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onContactSupport,
                icon: const Icon(Icons.headset_mic_rounded, size: 17),
                label: const Text('Contact Support to Switch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_Tokens.radius)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Verify banner (unchanged, only shown pre-purchase)
// ─────────────────────────────────────────────────────────────────────────────
class _VerifyBanner extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onVerify;
  const _VerifyBanner({required this.theme, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(color: amber.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amber.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded, color: amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your WhatsApp number',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We use this number to link your payment to your account and to send plan alerts.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Verify Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full plan card — only used for first-time purchase (no active plan yet)
// ─────────────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final ThemeData theme;
  final SubscriptionPlan plan;
  final bool isVerified;
  final bool isLaunching;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.theme,
    required this.plan,
    required this.isVerified,
    required this.isLaunching,
    required this.onSubscribe,
  });

  IconData _iconFor(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('whatsapp')) return Icons.chat_rounded;
    if (f.contains('algo')) return Icons.smart_toy_rounded;
    if (f.contains('market depth')) return Icons.layers_rounded;
    if (f.contains('research')) return Icons.analytics_rounded;
    if (f.contains('stock pick')) return Icons.trending_up_rounded;
    if (f.contains('news')) return Icons.article_rounded;
    if (f.contains('screener')) return Icons.filter_alt_rounded;
    if (f.contains('sentiment')) return Icons.insights_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final accent = plan.isPopular
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant
            .withValues(alpha: plan.isPopular ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(
          color: plan.isPopular
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
          width: plan.isPopular ? 1.6 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              if (plan.isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (plan.tagline != null && plan.tagline!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.tagline!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.currencySymbol,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                plan.formattedPrice,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ ${plan.billingPeriod}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_iconFor(feature), size: 14, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isLaunching ? null : onSubscribe,
              icon: isLaunching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      isVerified
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_outline_rounded,
                      size: 17,
                    ),
              label: Text(
                isLaunching
                    ? 'Opening…'
                    : (isVerified ? 'Subscribe Now' : 'Verify to Subscribe'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isPopular
                    ? theme.colorScheme.primary
                    : (isDark
                        ? theme.colorScheme.surfaceVariant
                        : theme.colorScheme.onSurface),
                foregroundColor: plan.isPopular
                    ? theme.colorScheme.onPrimary
                    : (isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.surface),
                elevation: 0,
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radius)),
              ),
            ),
          ),
        ],
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
