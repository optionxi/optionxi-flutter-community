import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_contact_us.dart';

// Replace with your actual import
// import 'package:optionxi/Components/cust_contact_us.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: OrganizationOnboardingPage(
        onToggleTheme: () => setState(
          () => _themeMode =
              _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
        ),
      ),
    );
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────

abstract class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Georgia',
    scaffoldBackgroundColor: const Color(0xFFF5F4F0),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A3C5E),
      secondary: Color(0xFF2B7FD4),
      surface: Color(0xFFFFFFFF),
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Georgia',
    scaffoldBackgroundColor: const Color(0xFF0B0F19),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4DA6FF),
      secondary: Color(0xFF2B7FD4),
      surface: Color(0xFF131929),
    ),
  );
}

// ─── Tokens ───────────────────────────────────────────────────────────────────

class _T {
  // Light
  static const bgLight = Color(0xFFF5F4F0);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8E6E0);
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);

  // Dark
  static const bgDark = Color(0xFF0B0F19);
  static const surfaceDark = Color(0xFF131929);
  static const borderDark = Color(0xFF1E2A3D);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFF8B9AB1);

  // Accent
  static const accentBlue = Color(0xFF2B7FD4);
  static const accentBlueBright = Color(0xFF4DA6FF);
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class OrganizationOnboardingPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const OrganizationOnboardingPage({super.key, this.onToggleTheme});

  @override
  State<OrganizationOnboardingPage> createState() =>
      _OrganizationOnboardingPageState();
}

class _OrganizationOnboardingPageState extends State<OrganizationOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  int _selectedPlan = 1; // 0 = Starter, 1 = Professional

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _T.bgDark : _T.bgLight;
    final textPrimary = isDark ? _T.textPrimaryDark : _T.textPrimaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _AppBar(
                          isDark: isDark,
                          textPrimary: textPrimary,
                          onToggleTheme: widget.onToggleTheme),
                      const SizedBox(height: 40),
                      _HeroSection(isDark: isDark, textPrimary: textPrimary),
                      const SizedBox(height: 48),
                      _SectionLabel(label: 'Key Features', isDark: isDark),
                      const SizedBox(height: 20),
                      _FeaturesGrid(isDark: isDark),
                      const SizedBox(height: 48),
                      _SectionLabel(label: 'How It Works', isDark: isDark),
                      const SizedBox(height: 20),
                      _HowItWorks(isDark: isDark),
                      const SizedBox(height: 48),
                      _SecurityBadge(isDark: isDark),
                      const SizedBox(height: 48),
                      _SectionLabel(label: 'Simple Pricing', isDark: isDark),
                      const SizedBox(height: 8),
                      Text(
                        'Scale as your organization grows',
                        style: TextStyle(
                          color: isDark
                              ? _T.textSecondaryDark
                              : _T.textSecondaryLight,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PricingSection(
                        isDark: isDark,
                        selectedPlan: _selectedPlan,
                        onPlanChanged: (i) => setState(() => _selectedPlan = i),
                      ),
                      const SizedBox(height: 48),
                      _CTAButton(isDark: isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final VoidCallback? onToggleTheme;

  const _AppBar(
      {required this.isDark,
      required this.textPrimary,
      required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          isDark: isDark,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Organization',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (onToggleTheme != null)
          _IconBtn(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            isDark: isDark,
            onTap: onToggleTheme!,
          ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? _T.surfaceDark : _T.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? _T.borderDark : _T.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;

  const _HeroSection({required this.isDark, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? _T.accentBlueBright.withOpacity(0.4)
                  : _T.accentBlue.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(100),
            color: isDark
                ? _T.accentBlueBright.withOpacity(0.08)
                : _T.accentBlue.withOpacity(0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? _T.accentBlueBright : _T.accentBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'For Organizations',
                style: TextStyle(
                  color: isDark ? _T.accentBlueBright : _T.accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -1.2,
              fontFamily: 'Georgia',
            ),
            children: [
              const TextSpan(text: 'Empower Your\n'),
              TextSpan(
                text: 'Investment\nStrategy',
                style: TextStyle(
                  color: isDark ? _T.accentBlueBright : _T.accentBlue,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Divider accent
        Container(
          height: 2,
          width: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [_T.accentBlueBright, _T.accentBlueBright.withOpacity(0)]
                  : [_T.accentBlue, _T.accentBlue.withOpacity(0)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Create custom screeners and algorithms for your clients with complete transparency. Connect multiple clients and track their performance seamlessly.',
          style: TextStyle(
            color: isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
            fontSize: 15.5,
            height: 1.65,
            letterSpacing: 0.1,
          ),
        ),

        const SizedBox(height: 28),

        // Stat pills
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatPill(label: '500+ Clients', isDark: isDark),
            _StatPill(label: 'Real-time Analytics', isDark: isDark),
            _StatPill(label: 'SEBI Compliant', isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final bool isDark;

  const _StatPill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? _T.surfaceDark : _T.surfaceLight,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isDark ? _T.borderDark : _T.borderLight),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: isDark ? _T.accentBlueBright : _T.accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

// ─── Features Grid ────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final bool isDark;

  const _FeaturesGrid({required this.isDark});

  static const _features = [
    (
      Icons.tune_rounded,
      'Custom Screeners',
      'Build sophisticated screening algorithms tailored to your strategy'
    ),
    (
      Icons.visibility_rounded,
      'Full Transparency',
      'Algorithm disclosure ensures fair and transparent practices'
    ),
    (
      Icons.people_alt_rounded,
      'Client Hub',
      'Connect and manage multiple clients in one dashboard'
    ),
    (
      Icons.analytics_rounded,
      'Performance Intel',
      'Detailed metrics and real-time portfolio analytics'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) {
        final f = _features[i];
        return _FeatureCard(
            icon: f.$1, title: f.$2, desc: f.$3, isDark: isDark);
      },
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isDark;

  const _FeatureCard(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.isDark});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? _T.surfaceDark : _T.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? _T.borderDark : _T.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark
                      ? _T.accentBlueBright.withOpacity(0.1)
                      : _T.accentBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: isDark ? _T.accentBlueBright : _T.accentBlue,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.desc,
                style: TextStyle(
                  color: isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── How It Works ─────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isDark;

  const _HowItWorks({required this.isDark});

  static const _steps = [
    (
      'Register',
      'Create your organization profile and configure your dashboard settings'
    ),
    (
      'Build Algos',
      'Design and deploy transparent screening algorithms for clients'
    ),
    (
      'Connect Clients',
      'Invite clients to link broker APIs for automated portfolio tracking'
    ),
    (
      'Monitor',
      'Access real-time updates and comprehensive performance analytics'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final isLast = i == _steps.length - 1;
        return _StepRow(
          number: '${i + 1}',
          title: _steps[i].$1,
          desc: _steps[i].$2,
          isDark: isDark,
          showLine: !isLast,
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final bool isDark;
  final bool showLine;

  const _StepRow({
    required this.number,
    required this.title,
    required this.desc,
    required this.isDark,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _T.accentBlueBright : _T.accentBlue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (showLine)
                Container(
                  width: 1.5,
                  height: 56,
                  color: isDark ? _T.borderDark : _T.borderLight,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color:
                        isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Security Badge ───────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  final bool isDark;

  const _SecurityBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1E35) : const Color(0xFFEBF3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? _T.accentBlueBright.withOpacity(0.2)
              : _T.accentBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? _T.accentBlueBright.withOpacity(0.15)
                  : _T.accentBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: isDark ? _T.accentBlueBright : _T.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & SEBI Compliant',
                  style: TextStyle(
                    color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Portfolio data stored with a 24-hour delay for compliance. Clients retain full control over data sharing.',
                  style: TextStyle(
                    color:
                        isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
                    fontSize: 13,
                    height: 1.5,
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

// ─── Pricing ──────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  final bool isDark;
  final int selectedPlan;
  final ValueChanged<int> onPlanChanged;

  const _PricingSection({
    required this.isDark,
    required this.selectedPlan,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? _T.surfaceDark : _T.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? _T.borderDark : _T.borderLight),
          ),
          child: Row(
            children: [
              _PlanToggle(
                  label: 'Starter',
                  selected: selectedPlan == 0,
                  isDark: isDark,
                  onTap: () => onPlanChanged(0)),
              _PlanToggle(
                  label: 'Professional',
                  selected: selectedPlan == 1,
                  isDark: isDark,
                  onTap: () => onPlanChanged(1)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: selectedPlan == 0
              ? _PricingCard(
                  key: const ValueKey('starter'),
                  isDark: isDark,
                  title: 'Starter',
                  price: '₹3,999',
                  members: 'Up to 100 members',
                  isPopular: false,
                  perks: [
                    'Custom screeners',
                    'Client management',
                    'Performance analytics',
                    'Email support',
                  ],
                )
              : _PricingCard(
                  key: const ValueKey('pro'),
                  isDark: isDark,
                  title: 'Professional',
                  price: '₹6,999',
                  members: '500+ members',
                  isPopular: true,
                  perks: [
                    'Everything in Starter',
                    'Advanced algo builder',
                    'Priority support',
                    'Dedicated account manager',
                    'Custom integrations',
                  ],
                ),
        ),
      ],
    );
  }
}

class _PlanToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanToggle(
      {required this.label,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? _T.accentBlueBright : _T.accentBlue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? _T.textSecondaryDark : _T.textSecondaryLight),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String price;
  final String members;
  final bool isPopular;
  final List<String> perks;

  const _PricingCard({
    super.key,
    required this.isDark,
    required this.title,
    required this.price,
    required this.members,
    required this.isPopular,
    required this.perks,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _T.accentBlueBright : _T.accentBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? _T.surfaceDark : _T.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? accent.withOpacity(0.6)
              : (isDark ? _T.borderDark : _T.borderLight),
          width: isPopular ? 1.5 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.12 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isPopular) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: isPopular
                      ? accent
                      : (isDark ? _T.textPrimaryDark : _T.textPrimaryLight),
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ month',
                  style: TextStyle(
                    color:
                        isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            members,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: isDark ? _T.borderDark : _T.borderLight,
          ),
          const SizedBox(height: 20),
          ...perks.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 13, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p,
                      style: TextStyle(
                        color:
                            isDark ? _T.textPrimaryDark : _T.textPrimaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── CTA ──────────────────────────────────────────────────────────────────────

class _CTAButton extends StatefulWidget {
  final bool isDark;

  const _CTAButton({required this.isDark});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? _T.accentBlueBright : _T.accentBlue;
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _hovered = true),
          onTapUp: (_) => setState(() => _hovered = false),
          onTapCancel: () => setState(() => _hovered = false),
          onTap: () {
            showContactOptions(context);
          },
          child: AnimatedScale(
            scale: _hovered ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Register Your Organization',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'No commitment required • Cancel anytime',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDark ? _T.textSecondaryDark : _T.textSecondaryLight,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
