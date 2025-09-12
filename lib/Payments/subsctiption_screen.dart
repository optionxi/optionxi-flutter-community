import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Payments/payment_history_page.dart';
import 'package:optionxi/Payments/subscription_model.dart';
import 'package:optionxi/Payments/subscription_provider.dart';

class ModernSubscriptionScreen extends StatefulWidget {
  const ModernSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<ModernSubscriptionScreen> createState() =>
      _ModernSubscriptionScreenState();
}

class _ModernSubscriptionScreenState extends State<ModernSubscriptionScreen>
    with TickerProviderStateMixin {
  late SubscriptionController subscriptionController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    subscriptionController = Get.put(SubscriptionController());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Load user subscription data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      subscriptionController.loadUserSubscription(currentUser.uid);
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    Get.delete<SubscriptionController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildModernAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Obx(() {
          if (subscriptionController.isLoading) {
            return _buildLoadingState();
          }
          return _buildContent(context);
        }),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: const Text(
        'Subscription',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton.outlined(
            icon: const Icon(Icons.history_rounded, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentHistoryScreen()),
            ),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your subscription...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentSubscriptionCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Choose Your Plan'),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plans = SubscriptionPlan.getPlans();
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildModernPlanCard(
                    plan,
                    FirebaseAuth.instance.currentUser,
                    index,
                  ),
                );
              },
              childCount: SubscriptionPlan.getPlans().length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    return Obx(() {
      final currentSub = subscriptionController.currentSubscription;
      final currentPlan = subscriptionController.currentPlan;
      final hasActiveSub = subscriptionController.hasActiveSubscription;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: hasActiveSub
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surfaceVariant,
                      Theme.of(context).colorScheme.surfaceVariant,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: hasActiveSub
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: hasActiveSub && currentSub != null && currentPlan != null
              ? _buildActiveSubscriptionContent(currentSub, currentPlan)
              : _buildNoSubscriptionContent(),
        ),
      );
    });
  }

  Widget _buildActiveSubscriptionContent(subscription, plan) {
    final textColor = Theme.of(context).colorScheme.onPrimary;
    final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Plan',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                '₹${plan.price.toInt()}/mo',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                daysLeft > 7 ? Icons.schedule : Icons.warning_rounded,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daysLeft > 0
                          ? '$daysLeft days remaining'
                          : 'Expires today',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Expires ${subscription.endDate.toString().split(' ')[0]}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: subscription.autoRenew,
                onChanged: (value) {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    subscriptionController.toggleAutoRenew(
                        currentUser.uid, value);
                  }
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _showManageSubscriptionBottomSheet,
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Manage'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelSubscription,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoSubscriptionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.workspace_premium_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock Premium Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a subscription plan to access exclusive features and enhance your experience.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildModernPlanCard(SubscriptionPlan plan, User? user, int index) {
    return Obx(() {
      final isCurrentPlan = subscriptionController.currentPlan?.id == plan.id;
      final isPopular = index == 1; // Middle plan is popular

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrentPlan
                ? Theme.of(context).colorScheme.primary
                : isPopular
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isCurrentPlan || isPopular ? 2 : 1,
          ),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isPopular) _buildPopularBadge(),
            Padding(
              padding: EdgeInsets.all(isPopular ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '₹${plan.price.toInt()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  TextSpan(
                                    text: '/month',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...plan.features.asMap().entries.map((entry) {
                    // final index = entry.key;
                    final feature = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isCurrentPlan
                          ? null
                          : () => _subscribeToPlan(plan, user),
                      style: FilledButton.styleFrom(
                        backgroundColor: isCurrentPlan
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: isCurrentPlan
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isCurrentPlan ? 'Current Plan' : 'Get Started',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPopularBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Text(
        'Most Popular',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _subscribeToPlan(SubscriptionPlan plan, User? user) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubscriptionConfirmationSheet(plan),
    );

    if (confirmed == true && user != null) {
      final success = await subscriptionController.purchaseSubscription(
        plan.id,
        user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? 'Welcome to ${plan.name}! 🎉'
                        : 'Subscription failed. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildSubscriptionConfirmationSheet(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.workspace_premium_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Subscribe to ${plan.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be charged ₹${plan.price.toInt()} every month',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showManageSubscriptionBottomSheet() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Subscription',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              _buildManageOption(
                icon: Icons.trending_up_rounded,
                title: 'Upgrade Plan',
                subtitle: 'Get access to more features',
                onTap: () {
                  Navigator.pop(context);
                  _showUpgradeOptions();
                },
              ),
              const SizedBox(height: 16),
              _buildManageOption(
                icon: Icons.trending_down_rounded,
                title: 'Downgrade Plan',
                subtitle: 'Reduce your monthly cost',
                onTap: () {
                  Navigator.pop(context);
                  _showDowngradeOptions();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeOptions() {
    final currentPlan = subscriptionController.currentPlan!;
    final availablePlans = SubscriptionPlan.getPlans()
        .where((plan) => plan.price > currentPlan.price)
        .toList();

    if (availablePlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You\'re already on the highest plan! 🎉'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlanSelectionSheet(
        title: 'Upgrade Plan',
        subtitle: 'Choose a higher tier plan',
        plans: availablePlans,
        onPlanSelected: _upgradePlan,
      ),
    );
  }

  void _showDowngradeOptions() {
    final currentPlan = subscriptionController.currentPlan!;
    final availablePlans = SubscriptionPlan.getPlans()
        .where((plan) => plan.price < currentPlan.price)
        .toList();

    if (availablePlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You\'re already on the lowest plan!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlanSelectionSheet(
        title: 'Downgrade Plan',
        subtitle: 'Changes will take effect at the end of your billing cycle',
        plans: availablePlans,
        onPlanSelected: _downgradePlan,
      ),
    );
  }

  Widget _buildPlanSelectionSheet({
    required String title,
    required String subtitle,
    required List<SubscriptionPlan> plans,
    required Function(SubscriptionPlan) onPlanSelected,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...plans
                .map((plan) => _buildPlanSelectionTile(plan, onPlanSelected)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelectionTile(
    SubscriptionPlan plan,
    Function(SubscriptionPlan) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSelected(plan);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '₹${plan.price.toInt()}/month',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _upgradePlan(SubscriptionPlan plan) async {
    final authProvider = FirebaseAuth.instance;
    final success = await subscriptionController.upgradeSubscription(
      authProvider.currentUser!.uid,
      plan.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.upgrade_rounded : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Successfully upgraded to ${plan.name}! 🚀'
                      : 'Upgrade failed. Please try again.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _downgradePlan(SubscriptionPlan plan) async {
    final authProvider = FirebaseAuth.instance;
    final success = await subscriptionController.downgradeSubscription(
      authProvider.currentUser!.uid,
      plan.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.schedule_rounded : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Plan will change to ${plan.name} at the end of your billing cycle'
                      : 'Downgrade failed. Please try again.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _cancelSubscription() async {
    HapticFeedback.heavyImpact();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cancel Subscription',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel? You\'ll lose access to premium features at the end of your billing cycle.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keep Subscription'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final authProvider = FirebaseAuth.instance;
      final success = await subscriptionController
          .cancelSubscription(authProvider.currentUser!.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? 'Subscription cancelled successfully'
                        : 'Failed to cancel subscription. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
