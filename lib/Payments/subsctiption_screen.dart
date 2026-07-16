import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Payments/payment_history_page.dart';
import 'package:optionxi/Payments/subscription_model.dart';
import 'package:optionxi/Payments/subscription_provider.dart';

// ─────────────────────────────────────────────
// Adaptive Token Helper
// Usage: final t = _T(context);  →  t.bg, t.card, t.gold …
// Every color resolves at build time using the current brightness.
// ─────────────────────────────────────────────
class _T {
  final bool isDark;
  _T(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  // Backgrounds
  Color get bg => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA);
  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get card => isDark ? const Color(0xFF16161F) : const Color(0xFFFFFFFF);
  Color get cardBorder =>
      isDark ? const Color(0xFF22222E) : const Color(0xFFE4E4EF);

  // Brand — gold shifts slightly darker on light for contrast
  Color get gold => isDark ? const Color(0xFFD4A853) : const Color(0xFFB8872A);
  Color get goldDim =>
      isDark ? const Color(0x33D4A853) : const Color(0x1FB8872A);

  // Text
  Color get onSurface =>
      isDark ? const Color(0xFFF2F2F5) : const Color(0xFF111118);
  Color get onSurfaceMuted =>
      isDark ? const Color(0xFF6B7080) : const Color(0xFF8892A4);
  Color get silver =>
      isDark ? const Color(0xFF8892A4) : const Color(0xFF5C6475);

  // Accent (blue-indigo — same hue, same readability on both)
  Color get accent => const Color(0xFF5B7CFA);
  Color get accentDim =>
      isDark ? const Color(0x1A5B7CFA) : const Color(0x145B7CFA);

  // Semantic
  Color get danger => const Color(0xFFE05C5C);
  Color get success => const Color(0xFF4CAF80);

  // Active subscription card
  List<Color> get activeGradient => isDark
      ? [
          const Color(0xFF1A1608),
          const Color(0xFF1C1710),
          const Color(0xFF111008)
        ]
      : [
          const Color(0xFFFDF8EE),
          const Color(0xFFFAF3DC),
          const Color(0xFFF5ECC8)
        ];

  Color get activeGradientBorder => isDark
      ? const Color(0xFFD4A853).withOpacity(0.25)
      : const Color(0xFFB8872A).withOpacity(0.30);

  Color get activeGlowShadow => isDark
      ? const Color(0xFFD4A853).withOpacity(0.12)
      : const Color(0xFFB8872A).withOpacity(0.10);

  Color get activePillBg => gold.withOpacity(0.15);
  Color get activePillBorder => gold.withOpacity(0.30);

  Color get activeTextPrimary =>
      isDark ? const Color(0xFFF2F2F5) : const Color(0xFF2A1E00);
  Color get activeTextSecondary =>
      isDark ? const Color(0xFF8892A4) : const Color(0xFF7A6230);

  Color get progressTrack => gold.withOpacity(0.12);

  // Auto-renew row inner surface
  Color get rowInnerBg =>
      isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
  Color get rowInnerBorder =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

  Color get switchTrackActive => gold.withOpacity(0.20);
  Color get switchThumbInactive => silver;
  Color get switchTrackInactive => silver.withOpacity(0.10);

  Color get sectionDivider =>
      isDark ? const Color(0xFF22222E) : const Color(0xFFDDDDEE);
}

const _cardRadius = 20.0;
const _sheetRadius = 28.0;

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class SubscriptionScreenModern extends StatefulWidget {
  const SubscriptionScreenModern({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreenModern> createState() =>
      _SubscriptionScreenModernState();
}

class _SubscriptionScreenModernState extends State<SubscriptionScreenModern>
    with TickerProviderStateMixin {
  late SubscriptionController subscriptionController;
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroScale;

  @override
  void initState() {
    super.initState();
    subscriptionController = Get.put(SubscriptionController());

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _heroController = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _heroScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      subscriptionController.loadUserSubscription(currentUser.uid);
    }

    _fadeController.forward();
    _heroController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    Get.delete<SubscriptionController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return Scaffold(
      backgroundColor: t.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(t),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Obx(() {
          if (subscriptionController.isLoading) return _buildLoadingState(t);
          return _buildContent(t);
        }),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────
  PreferredSizeWidget _buildAppBar(_T t) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: t.surface,
      foregroundColor: t.onSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.maybePop(context),
        color: t.silver,
      ),
      title: Text(
        'Subscription',
        style: TextStyle(
          color: t.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: 0.2,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _GlassButton(
            icon: Icons.receipt_long_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentHistoryScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading ───────────────────────────────────
  Widget _buildLoadingState(_T t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.gold),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading subscription…',
            style: TextStyle(
                color: t.onSurfaceMuted, fontSize: 14, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  // ── Main Content ──────────────────────────────
  Widget _buildContent(_T t) {
    final plans = SubscriptionPlan.getPlans();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 56 + 16),
        ),
        // Hero card
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: ScaleTransition(
              scale: _heroScale,
              child: _buildHeroCard(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
        // Section label
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _SectionDivider(color: t.sectionDivider),
                const SizedBox(width: 12),
                Text(
                  'PLANS',
                  style: TextStyle(
                    color: t.onSurfaceMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _SectionDivider(color: t.sectionDivider)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // Plan cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AnimatedPlanCard(
                    plan: plan,
                    index: index,
                    isPopular: index == 1,
                    isCurrentPlan:
                        subscriptionController.currentPlan?.id == plan.id,
                    onSubscribe: () => _subscribeToPlan(
                        plan, FirebaseAuth.instance.currentUser),
                  ),
                );
              },
              childCount: plans.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

  // ── Hero / Status Card ────────────────────────
  Widget _buildHeroCard() {
    return Obx(() {
      final currentSub = subscriptionController.currentSubscription;
      final currentPlan = subscriptionController.currentPlan;
      final hasActive = subscriptionController.hasActiveSubscription;

      if (hasActive && currentSub != null && currentPlan != null) {
        return _ActiveStatusCard(
          subscription: currentSub,
          plan: currentPlan,
          onManage: _showManageSheet,
          onCancel: _cancelSubscription,
          onToggleAutoRenew: (value) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null)
              subscriptionController.toggleAutoRenew(user.uid, value);
          },
        );
      }
      return const _EmptyStatusCard();
    });
  }

  // ── Subscribe Flow ────────────────────────────
  void _subscribeToPlan(SubscriptionPlan plan, User? user) async {
    HapticFeedback.mediumImpact();
    final confirmed =
        await _showSheet<bool>(child: _ConfirmSubscribeSheet(plan: plan));
    if (confirmed == true && user != null) {
      final success =
          await subscriptionController.purchaseSubscription(plan.id, user.uid);
      if (mounted) {
        _showResultSnack(
            success,
            success
                ? 'Welcome to ${plan.name}! 🎉'
                : 'Subscription failed. Please try again.');
      }
    }
  }

  void _showManageSheet() {
    HapticFeedback.mediumImpact();
    _showSheet<void>(
      child: Builder(
        builder: (ctx) => _ManageSubscriptionSheet(
          onUpgrade: () {
            Navigator.pop(ctx);
            _showUpgradeOptions();
          },
          onDowngrade: () {
            Navigator.pop(ctx);
            _showDowngradeOptions();
          },
        ),
      ),
    );
  }

  void _showUpgradeOptions() {
    final currentPlan = subscriptionController.currentPlan!;
    final plans = SubscriptionPlan.getPlans()
        .where((p) => p.price > currentPlan.price)
        .toList();
    if (plans.isEmpty) {
      _showResultSnack(true, "You're already on the highest plan! 🏆");
      return;
    }
    _showSheet<void>(
      child: _PlanPickerSheet(
        title: 'Upgrade Plan',
        subtitle: 'Unlock more powerful features',
        plans: plans,
        onSelected: (p) {
          Navigator.pop(context);
          _upgradePlan(p);
        },
      ),
    );
  }

  void _showDowngradeOptions() {
    final currentPlan = subscriptionController.currentPlan!;
    final plans = SubscriptionPlan.getPlans()
        .where((p) => p.price < currentPlan.price)
        .toList();
    if (plans.isEmpty) {
      _showResultSnack(false, "You're already on the lowest plan.");
      return;
    }
    _showSheet<void>(
      child: _PlanPickerSheet(
        title: 'Downgrade Plan',
        subtitle: 'Changes apply at end of billing cycle',
        plans: plans,
        onSelected: (p) {
          Navigator.pop(context);
          _downgradePlan(p);
        },
      ),
    );
  }

  void _upgradePlan(SubscriptionPlan plan) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final success =
        await subscriptionController.upgradeSubscription(uid, plan.id);
    if (mounted) {
      _showResultSnack(
          success,
          success
              ? 'Upgraded to ${plan.name}! 🚀'
              : 'Upgrade failed. Please try again.');
    }
  }

  void _downgradePlan(SubscriptionPlan plan) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final success =
        await subscriptionController.downgradeSubscription(uid, plan.id);
    if (mounted) {
      _showResultSnack(
          success,
          success
              ? 'Plan will change to ${plan.name} at end of cycle.'
              : 'Downgrade failed. Please try again.');
    }
  }

  void _cancelSubscription() async {
    HapticFeedback.heavyImpact();
    final confirmed = await _showSheet<bool>(child: const _CancelSheet());
    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final success = await subscriptionController.cancelSubscription(uid);
      if (mounted) {
        _showResultSnack(
            success,
            success
                ? 'Subscription cancelled.'
                : 'Failed to cancel. Please try again.');
      }
    }
  }

  Future<T?> _showSheet<T>({required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  void _showResultSnack(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor:
            success ? const Color(0xFF4CAF80) : const Color(0xFFE05C5C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Active Status Card
// ─────────────────────────────────────────────
class _ActiveStatusCard extends StatelessWidget {
  final dynamic subscription;
  final dynamic plan;
  final VoidCallback onManage;
  final VoidCallback onCancel;
  final Function(bool) onToggleAutoRenew;

  const _ActiveStatusCard({
    required this.subscription,
    required this.plan,
    required this.onManage,
    required this.onCancel,
    required this.onToggleAutoRenew,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;
    final progress = (daysLeft / 30).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        gradient: LinearGradient(
          colors: t.activeGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: t.activeGradientBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: t.activeGlowShadow,
              blurRadius: 32,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.activePillBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.activePillBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: t.gold, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('ACTIVE',
                          style: TextStyle(
                              color: t.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('₹${plan.price.toInt()}/mo',
                    style: TextStyle(
                        color: t.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 20),
            // Plan name
            Text(plan.name,
                style: TextStyle(
                    color: t.activeTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Renews ${subscription.endDate.toString().split(' ')[0]}',
                style: TextStyle(color: t.activeTextSecondary, fontSize: 13)),
            const SizedBox(height: 22),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$daysLeft days remaining',
                    style: TextStyle(
                        color: t.activeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        color: t.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: t.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(t.gold),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 22),
            // Auto-renew row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: t.rowInnerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.rowInnerBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.autorenew_rounded,
                      color: t.activeTextSecondary, size: 16),
                  const SizedBox(width: 10),
                  Text('Auto-renew',
                      style: TextStyle(
                          color: t.activeTextSecondary, fontSize: 13)),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: subscription.autoRenew,
                      onChanged: onToggleAutoRenew,
                      activeColor: t.gold,
                      activeTrackColor: t.switchTrackActive,
                      inactiveThumbColor: t.switchThumbInactive,
                      inactiveTrackColor: t.switchTrackInactive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                      label: 'Manage',
                      icon: Icons.tune_rounded,
                      onPressed: onManage),
                ),
                const SizedBox(width: 10),
                _GhostButton(label: 'Cancel', onPressed: onCancel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty Status Card
// ─────────────────────────────────────────────
class _EmptyStatusCard extends StatelessWidget {
  const _EmptyStatusCard();

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        color: t.card,
        border: Border.all(color: t.cardBorder),
        boxShadow: t.isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: t.accentDim, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.workspace_premium_rounded,
                color: t.accent, size: 24),
          ),
          const SizedBox(height: 18),
          Text('No active plan',
              style: TextStyle(
                  color: t.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text(
              'Choose a subscription below to unlock\nexclusive trading features.',
              style: TextStyle(color: t.silver, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated Plan Card
// ─────────────────────────────────────────────
class _AnimatedPlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final int index;
  final bool isPopular;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  const _AnimatedPlanCard({
    required this.plan,
    required this.index,
    required this.isPopular,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  @override
  State<_AnimatedPlanCard> createState() => _AnimatedPlanCardState();
}

class _AnimatedPlanCardState extends State<_AnimatedPlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + widget.index * 100));
    _slideAnim = Tween<double>(begin: 24, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
            offset: Offset(0, _slideAnim.value), child: child),
      ),
      child: _PlanCard(
        plan: widget.plan,
        isPopular: widget.isPopular,
        isCurrentPlan: widget.isCurrentPlan,
        onSubscribe: widget.onSubscribe,
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isPopular;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isPopular,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = _T(context);

    final borderColor = widget.isCurrentPlan
        ? t.gold.withOpacity(0.60)
        : widget.isPopular
            ? t.accent.withOpacity(0.50)
            : t.cardBorder;

    final glowColor = widget.isCurrentPlan
        ? t.gold.withOpacity(t.isDark ? 0.08 : 0.06)
        : widget.isPopular
            ? t.accent.withOpacity(t.isDark ? 0.06 : 0.04)
            : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            color: t.card,
            border: Border.all(
                color: borderColor,
                width: widget.isCurrentPlan || widget.isPopular ? 1.5 : 1),
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: 24),
              if (!t.isDark)
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              if (widget.isPopular) _buildPopularBadge(t),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.plan.name,
                                  style: TextStyle(
                                      color: t.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3)),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${widget.plan.price.toInt()}',
                                      style: TextStyle(
                                          color: widget.isPopular
                                              ? t.accent
                                              : t.onSurface,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5)),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 4, left: 2),
                                    child: Text('/month',
                                        style: TextStyle(
                                            color: t.silver,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.isCurrentPlan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.goldDim,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: t.gold.withOpacity(0.30)),
                            ),
                            child: Text('Current',
                                style: TextStyle(
                                    color: t.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: t.cardBorder, thickness: 1, height: 1),
                    const SizedBox(height: 18),
                    // Features
                    ...widget.plan.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color:
                                    widget.isPopular ? t.accentDim : t.goldDim,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.check_rounded,
                                  color: widget.isPopular ? t.accent : t.gold,
                                  size: 12),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(feature,
                                  style: TextStyle(
                                      color: t.silver,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: widget.isCurrentPlan
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: t.cardBorder)),
                              alignment: Alignment.center,
                              child: Text('Active Plan',
                                  style: TextStyle(
                                      color: t.onSurfaceMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            )
                          : _PrimaryButton(
                              label: 'Get Started',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: widget.onSubscribe,
                              filled: widget.isPopular,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularBadge(_T t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_cardRadius),
          topRight: Radius.circular(_cardRadius),
        ),
      ),
      child: const Text('MOST POPULAR',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.5)),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheets
// ─────────────────────────────────────────────
class _ConfirmSubscribeSheet extends StatelessWidget {
  final SubscriptionPlan plan;
  const _ConfirmSubscribeSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return _BaseSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: t.accentDim, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.workspace_premium_rounded,
                color: t.accent, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Subscribe to ${plan.name}',
              style: TextStyle(
                  color: t.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
              'You\'ll be charged ₹${plan.price.toInt()} every month.\nCancel anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.silver, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _GhostButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                    label: 'Subscribe Now',
                    onPressed: () => Navigator.pop(context, true)),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _ManageSubscriptionSheet extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onDowngrade;
  const _ManageSubscriptionSheet(
      {required this.onUpgrade, required this.onDowngrade});

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return _BaseSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Subscription',
              style: TextStyle(
                  color: t.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 20),
          _ManageTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF4CAF80),
            title: 'Upgrade Plan',
            subtitle: 'Unlock more powerful features',
            onTap: onUpgrade,
          ),
          const SizedBox(height: 10),
          _ManageTile(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFF8892A4),
            title: 'Downgrade Plan',
            subtitle: 'Reduce your monthly cost',
            onTap: onDowngrade,
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.cardBorder),
              color: t.card),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: t.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(subtitle,
                        style: TextStyle(color: t.silver, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: t.onSurfaceMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanPickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SubscriptionPlan> plans;
  final Function(SubscriptionPlan) onSelected;

  const _PlanPickerSheet({
    required this.title,
    required this.subtitle,
    required this.plans,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return _BaseSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: t.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: t.silver, fontSize: 13)),
          const SizedBox(height: 20),
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(plan),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.cardBorder),
                        color: t.card),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.name,
                                  style: TextStyle(
                                      color: t.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('₹${plan.price.toInt()}/month',
                                  style: TextStyle(
                                      color: t.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: t.onSurfaceMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _CancelSheet extends StatelessWidget {
  const _CancelSheet();

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return _BaseSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: t.danger.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.cancel_outlined, color: t.danger, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Cancel Subscription',
              style: TextStyle(
                  color: t.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),
          Text(
            'You\'ll retain access until the end of your\ncurrent billing cycle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.silver, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _GhostButton(
                    label: 'Keep Plan',
                    onPressed: () => Navigator.pop(context, false)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────
class _BaseSheet extends StatelessWidget {
  final Widget child;
  const _BaseSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(_sheetRadius),
        border: Border.all(color: t.cardBorder),
        boxShadow: t.isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4))
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3.5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: t.onSurfaceMuted.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool filled;

  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? t.accent : t.accentDim,
        foregroundColor: filled ? Colors.white : t.accent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (icon != null) ...[
            const SizedBox(width: 6),
            Icon(icon, size: 16),
          ],
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GhostButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.silver,
        side: BorderSide(color: t.cardBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = _T(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Icon(icon, color: t.silver, size: 18),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final Color color;
  const _SectionDivider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 20, height: 1, color: color);
}
