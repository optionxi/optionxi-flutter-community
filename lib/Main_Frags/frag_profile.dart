import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_tools_chips_mytools.dart';
import 'package:optionxi/Helpers/open_url.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_broker_list.dart';
import 'package:optionxi/Main_Pages/Achivements/act_achievement_page.dart';
import 'package:optionxi/Main_Pages/Achivements/streak_card_widget.dart';
import 'package:optionxi/Main_Pages/DeployedAlgos/Act_DeployedAlgos.dart';
import 'package:optionxi/Main_Pages/HealthPage/act_health_monitors.dart';
import 'package:optionxi/Main_Pages/Leaderboard/act_leaderboard.dart';
import 'package:optionxi/Main_Pages/Organisation/act_org_onboarding.dart';
import 'package:optionxi/MobileLink/link_phone_screen.dart';
import 'package:optionxi/Theme/theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — swap these to retheme the entire page
// ─────────────────────────────────────────────────────────────────────────────
class _AppColors {
  // Dark palette
  static const darkBg = Color(0xFF0A0C10);
  static const darkSurface = Color(0xFF111318);
  static const darkSurface2 = Color(0xFF191D24);
  static const darkBorder = Color(0x0FFFFFFF); // 6 % white

  // Light palette
  static const lightBg = Color(0xFFF4F5F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFEEF0F5);
  static const lightBorder = Color(0x12000000); // 7 % black

  // Accent (same in both modes — tweak if needed)
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFF8B85FF);
  static const teal = Color(0xFF1DC9A4);
  static const coral = Color(0xFFFF6B6B);
  static const amber = Color(0xFFF5A623);
  static const purple = Color(0xFFA78BFA);
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class TradingProfilePage extends StatefulWidget {
  const TradingProfilePage({Key? key}) : super(key: key);

  @override
  State<TradingProfilePage> createState() => _TradingProfilePageState();
}

class _TradingProfilePageState extends State<TradingProfilePage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _pageCtrl;
  late final AnimationController _avatarRingCtrl;
  late final AnimationController _avatarFloatCtrl;
  late final AnimationController _glowPulseCtrl;

  late final List<Animation<double>> _fadeSlide; // staggered sections

  // ── State ──────────────────────────────────────────────────────────────────
  bool _privacyMode = false;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    // Master page entrance — 700 ms
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Rotating gradient ring — continuous
    _avatarRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Floating avatar bob — continuous
    _avatarFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Glow pulse for online dot & card orbs — continuous
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Build 6 staggered slide-up + fade-in animations
    _fadeSlide = List.generate(6, (i) {
      final start = i * 0.10;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _pageCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _fetchUserData();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _avatarRingCtrl.dispose();
    _avatarFloatCtrl.dispose();
    _glowPulseCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      if (_user == null) return;
      final snap = await _db.child('regusers/${_user!.uid}').get();
      if (snap.exists && mounted) {
        final data = snap.value as Map<dynamic, dynamic>;
        setState(() => _privacyMode = data['rg_privacy'] ?? false);
      }
    } catch (_) {}
  }

  Future<void> _updatePrivacySetting(bool value) async {
    HapticFeedback.lightImpact();
    try {
      if (_user == null) return;
      await _db.child('regusers/${_user!.uid}/rg_privacy').set(value);
      if (mounted) setState(() => _privacyMode = value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Privacy mode updated (takes effect next session)',
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _privacyMode = !value);
    }
  }

  late AnimationController _controller;
  final ThemeController themeController = Get.put(ThemeController());

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _AppColors.darkBg : _AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animSection(0, _buildHeader(isDark)),
              const SizedBox(height: 10),
              GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/achievements',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreakCard(),
                  )),
              const SizedBox(height: 12),
              _animSection(2, _buildTradingHub(isDark)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StockChipsSectionMyTools(),
              ),
              const SizedBox(height: 12),
              _animSection(3, _buildPreferences(isDark)),
              const SizedBox(height: 24),
              _animSection(4, _buildFooter(isDark)),
              const SizedBox(height: 24),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(0.3, 0.5, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: buildBrokerHub(context, _controller),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps a widget in a staggered slide-up + fade animation
  Widget _animSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _fadeSlide[index],
      builder: (_, __) => Opacity(
        opacity: _fadeSlide[index].value,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - _fadeSlide[index].value)),
          child: child,
        ),
      ),
    );
  }

  // ── 1. HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _AppColors.accent.withOpacity(0.06),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? _AppColors.darkBorder : _AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(isDark),
          const SizedBox(width: 14),
          Expanded(child: _buildHeaderInfo(isDark)),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // Rotating gradient ring + floating animation
  Widget _buildAvatar(bool isDark) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_avatarRingCtrl, _avatarFloatCtrl, _glowPulseCtrl]),
      builder: (_, __) {
        final floatOffset = Offset(0, -5 * _avatarFloatCtrl.value);
        return Transform.translate(
          offset: floatOffset,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating conic gradient ring
                Transform.rotate(
                  angle: _avatarRingCtrl.value * 2 * 3.14159,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          _AppColors.accent,
                          _AppColors.teal,
                          _AppColors.amber,
                          _AppColors.purple,
                          _AppColors.accent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner separator ring
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? _AppColors.darkBg : _AppColors.lightBg,
                  ),
                ),
                // Avatar face
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isDark
                      ? _AppColors.darkSurface2
                      : _AppColors.lightSurface2,
                  backgroundImage: _user?.photoURL != null
                      ? NetworkImage(_user!.photoURL!)
                      : null,
                  child: _user?.photoURL == null
                      ? Text(
                          (_user?.displayName?.isNotEmpty == true)
                              ? _user!.displayName![0].toUpperCase()
                              : 'T',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.accentLight,
                          ),
                        )
                      : null,
                ),
                // Pulsing online dot
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AppColors.teal
                          .withOpacity(0.6 + 0.4 * _glowPulseCtrl.value),
                      border: Border.all(
                        color: isDark ? _AppColors.darkBg : _AppColors.lightBg,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _user?.displayName ?? 'Trader',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.4,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          _user?.email ?? '',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: textColor.withOpacity(0.45),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // "Virtual Mode Active" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _AppColors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _AppColors.teal.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _glowPulseCtrl,
                builder: (_, __) => Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _AppColors.teal
                        .withOpacity(0.5 + 0.5 * _glowPulseCtrl.value),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Virtual Mode Active',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.teal,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          AuthService().logOut();
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _AppColors.coral.withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _AppColors.coral.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: _AppColors.coral,
            size: 18,
          ),
        ),
      ),
    );
  }

  // ── 2. BALANCE CARD ────────────────────────────────────────────────────────
  // The real BalanceCard from cust_virtual_balance_section.dart —
  // fetches balance from Supabase, shows skeleton loader while loading,
  // tap-to-refresh — all handled inside the widget itself.

  // ── 3. TRADING HUB ────────────────────────────────────────────────────────
  Widget _buildTradingHub(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Trading Hub'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _buildGridCard(
                index: 0,
                title: 'Leaderboard',
                subtitle: 'Global ranking',
                emoji: '🏆',
                iconBg: _AppColors.amber.withOpacity(0.12),
                isDark: isDark,
                onTap: () => _push(LeaderboardPage()),
              ),
              _buildGridCard(
                index: 3,
                title: 'Organizations',
                subtitle: 'Manage teams',
                emoji: '🏢',
                iconBg: _AppColors.teal.withOpacity(0.12),
                isDark: isDark,
                onTap: () => _push(OrganizationOnboardingPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required int index,
    required String title,
    required String subtitle,
    required String emoji,
    required Color iconBg,
    required bool isDark,
    required VoidCallback onTap,
    bool isNew = false,
  }) {
    final surface = isDark ? _AppColors.darkSurface : _AppColors.lightSurface;
    final border = isDark ? _AppColors.darkBorder : _AppColors.lightBorder;
    final titleClr = isDark ? Colors.white : const Color(0xFF0D0F14);
    final subClr = isDark
        ? Colors.white.withOpacity(0.38)
        : Colors.black.withOpacity(0.38);

    return AnimatedBuilder(
      animation: _fadeSlide[2],
      builder: (_, child) => Opacity(
        opacity: _fadeSlide[2].value,
        child: Transform.scale(
          scale: 0.92 + 0.08 * _fadeSlide[2].value,
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: titleClr,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: subClr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isNew)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _AppColors.coral.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _AppColors.coral.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.dmSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.coral,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 4. PREFERENCES ────────────────────────────────────────────────────────
  Widget _buildPreferences(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Preferences'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? _AppColors.darkSurface : _AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? _AppColors.darkBorder : _AppColors.lightBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Dark Mode toggle — driven by ThemeController
                GetBuilder<ThemeController>(builder: (controller) {
                  return _prefTile(
                    isDark: isDark,
                    emoji: controller.isDarkMode ? '🌙' : '☀️',
                    iconBg: const Color(0xFF6366F1).withOpacity(0.1),
                    title: 'Dark Mode',
                    subtitle: 'Adjust appearance',
                    trailing: _styledSwitch(
                      value: controller.isDarkMode,
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        controller.toggleTheme();
                      },
                    ),
                    divider: true,
                  );
                }),

                // Privacy Mode toggle
                _prefTile(
                  isDark: isDark,
                  emoji: '🔒',
                  iconBg: const Color(0xFFF97316).withOpacity(0.1),
                  title: 'Privacy Mode',
                  subtitle: 'Hide from leaderboard',
                  trailing: _styledSwitch(
                    value: _privacyMode,
                    onChanged: _updatePrivacySetting,
                  ),
                  divider: true,
                ),
                // Health Status
                _prefTile(
                  isDark: isDark,
                  emoji: '❤️',
                  iconBg: const Color(0xFFEF4444).withOpacity(0.1),
                  title: 'Health Status',
                  subtitle: 'System diagnostics',
                  trailing: _chevron(),
                  onTap: () => _push(HealthDashboard()),
                  divider: true,
                ),

                // Help & Support
                _prefTile(
                  isDark: isDark,
                  emoji: '💬',
                  iconBg: const Color(0xFFEC4899).withOpacity(0.12),
                  title: 'Support',
                  subtitle: 'Need help? Talk to us',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _chevron(),
                    ],
                  ),
                  onTap: () => showContactOptions(context),
                  divider: true,
                ),

                // Achievements
                _prefTile(
                  isDark: isDark,
                  emoji: '🏅',
                  iconBg: const Color(0xFF6366F1).withOpacity(0.1),
                  title: 'Achievements',
                  subtitle: 'View milestones',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      _chevron(),
                    ],
                  ),
                  onTap: () => _push(AchievementsPage()),
                  divider: true,
                ),

                // Rate Us
                _prefTile(
                  isDark: isDark,
                  emoji: '⭐',
                  iconBg: const Color(0xFFEAB308).withOpacity(0.1),
                  title: 'Rate Us',
                  subtitle: 'Leave a review',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star, size: 13, color: Color(0xFFFCD34D)),
                      Icon(Icons.star, size: 13, color: Color(0xFFFCD34D)),
                      Icon(Icons.star, size: 13, color: Color(0xFFFCD34D)),
                      Icon(Icons.star, size: 13, color: Color(0xFFFCD34D)),
                      Icon(Icons.star_half, size: 13, color: Color(0xFFFCD34D)),
                    ],
                  ),
                  onTap: () => OpenHelper.open_url(
                      'https://play.google.com/store/apps/details?id=com.optionxi.app'),
                  divider: false,
                ),

                _prefTile(
                  isDark: isDark,
                  emoji: '💬',
                  iconBg: const Color(0xFFEC4899).withOpacity(0.12),
                  title: 'Whatsapp',
                  subtitle: 'Link your mobile number',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _chevron(),
                    ],
                  ),
                  onTap: () => _push(LinkPhoneScreen()),
                  divider: true,
                ),
                _prefTile(
                  isDark: isDark,
                  emoji: '🤖',
                  iconBg: const Color(0xFF3B82F6).withOpacity(0.12),
                  title: 'Deployed Algos',
                  subtitle: 'Manage your live trading algorithms',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _chevron(),
                    ],
                  ),
                  onTap: () => _push(const DeployedAlgosScreen()),
                  divider: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefTile({
    required bool isDark,
    required String emoji,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    required bool divider,
  }) {
    final titleClr = isDark ? Colors.white : const Color(0xFF0D0F14);
    final subClr = isDark
        ? Colors.white.withOpacity(0.38)
        : Colors.black.withOpacity(0.38);
    final divClr = isDark ? _AppColors.darkBorder : _AppColors.lightBorder;

    return Column(
      children: [
        InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: divider
              ? BorderRadius.zero
              : const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: titleClr,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: subClr,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (divider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 67,
            color: divClr,
          ),
      ],
    );
  }

  // ── 5. FOOTER ─────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    final surface = isDark ? _AppColors.darkSurface : _AppColors.lightSurface;
    final border = isDark ? _AppColors.darkBorder : _AppColors.lightBorder;
    final titleClr = isDark ? Colors.white : const Color(0xFF0D0F14);
    final subClr = isDark
        ? Colors.white.withOpacity(0.38)
        : Colors.black.withOpacity(0.38);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => OpenHelper.open_url(
              'https://github.com/optionxi/optionxi-flutter-community'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? _AppColors.darkSurface2
                        : _AppColors.lightSurface2,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.github,
                        size: 18, color: _AppColors.accent),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Source Community',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleClr,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Built by traders, for traders · GitHub',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: subClr,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: subClr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _chevron() => const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: Colors.grey,
      );

  Widget _styledSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: _AppColors.accent,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.withOpacity(0.35),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
