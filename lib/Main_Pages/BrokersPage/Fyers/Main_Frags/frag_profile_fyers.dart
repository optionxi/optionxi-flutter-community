import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_datamodel.dart';

class ProfilePageFyers extends StatefulWidget {
  const ProfilePageFyers({
    Key? key,
  }) : super(key: key);

  @override
  _ProfilePageFyersState createState() => _ProfilePageFyersState();
}

class _ProfilePageFyersState extends State<ProfilePageFyers>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  final FyersRepository _fyersRepository = FyersRepository();
  FyersProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfile();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Shimmer animation controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (_isLoading) {
      _shimmerController.repeat();
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await _fyersRepository.getProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });

        _shimmerController.stop();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(theme, isDark),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildLoadingSkeleton(theme, isDark);
    } else if (_error != null) {
      return _buildErrorState(isDark);
    } else {
      return _buildProfileContent(theme, isDark);
    }
  }

  Widget _buildLoadingSkeleton(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header Skeleton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    // Profile avatar - static
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.3),
                            theme.colorScheme.secondary.withOpacity(0.3)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name skeleton
                    _buildShimmerContainer(
                      width: 150,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // Display name skeleton
                    _buildShimmerContainer(
                      width: 100,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    // Broker badge skeleton
                    _buildShimmerContainer(
                      width: 80,
                      height: 28,
                      borderRadius: BorderRadius.circular(20),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Cards Skeleton
              _buildInfoSectionSkeleton(theme, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSectionSkeleton(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;

    return Column(
      children: [
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Account Information',
          FontAwesomeIcons.user,
          [
            {'icon': Icons.email, 'label': 'Email'},
            {'icon': Icons.phone_outlined, 'label': 'Mobile'},
            {'icon': Icons.credit_card_outlined, 'label': 'PAN'},
            {'icon': Icons.account_box_outlined, 'label': 'Fyers ID'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Security',
          FontAwesomeIcons.shield,
          [
            {'icon': Icons.security_outlined, 'label': 'TOTP Enabled'},
            {'icon': Icons.lock_outline, 'label': 'Password Changed'},
            {'icon': Icons.pin_outlined, 'label': 'PIN Changed'},
            {'icon': Icons.schedule_outlined, 'label': 'Password Expires In'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Features',
          FontAwesomeIcons.cog,
          [
            {'icon': Icons.verified_user_outlined, 'label': 'DDPI'},
            {'icon': Icons.trending_up_outlined, 'label': 'MTF'},
          ],
          isDark,
        ),
      ],
    );
  }

  Widget _buildInfoCardSkeleton(
    ThemeData theme,
    Color borderColor,
    String title,
    IconData titleIcon,
    List<Map<String, dynamic>> items,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - static
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    titleIcon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Items - animated skeletons for values only
          ...items
              .map((item) => _buildInfoRowSkeleton(
                    item['label'],
                    item['icon'],
                    isDark,
                    borderColor,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRowSkeleton(
      String label, IconData icon, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon container - static
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label - static
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Value skeleton - animated
                _buildShimmerContainer(
                  width: 120,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    required BorderRadius borderRadius,
    required bool isDark,
  }) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment(-1.0, 0.0),
          end: Alignment(1.0, 0.0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            (_shimmerAnimation.value - 1.0).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 1.0).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.red[900] : Colors.red[50],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: isDark ? Colors.red[300] : Colors.red[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue[700] : Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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

  Widget _buildProfileContent(ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(theme, isDark),
            const SizedBox(height: 24),
            _buildInfoSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade700, Colors.blue.shade700]
                    : [Colors.blue.shade400, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _profile!.name,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Display Name
          Text(
            'ID:${_profile!.fyId}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Fyers Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'FYERS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;

    return Column(
      children: [
        _buildInfoCard(
          theme,
          borderColor,
          'Account Information',
          FontAwesomeIcons.user,
          [
            InfoItem('Email', _profile!.emailId, Icons.email),
            InfoItem('Mobile', _profile!.mobileNumber, Icons.phone_outlined),
            InfoItem('PAN', _profile!.pan, Icons.credit_card_outlined),
            InfoItem('Fyers ID', _profile!.fyId, Icons.account_box_outlined),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme,
          borderColor,
          'Security',
          FontAwesomeIcons.shield,
          [
            InfoItem('TOTP Enabled', _profile!.totp ? 'Yes' : 'No',
                Icons.security_outlined,
                valueColor: _profile!.totp
                    ? (isDark ? Colors.green[400] : Colors.green[600])
                    : (isDark ? Colors.red[400] : Colors.red[600])),
            InfoItem('Password Changed', _profile!.pwdChangeDate,
                Icons.lock_outline),
            InfoItem(
                'PIN Changed', _profile!.pinChangeDate, Icons.pin_outlined),
            InfoItem('Password Expires In', '${_profile!.pwdToExpire} days',
                Icons.schedule_outlined),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme,
          borderColor,
          'Features',
          FontAwesomeIcons.cog,
          [
            InfoItem('DDPI', _profile!.ddpiEnabled ? 'Enabled' : 'Disabled',
                Icons.verified_user_outlined,
                valueColor: _profile!.ddpiEnabled
                    ? (isDark ? Colors.green[400] : Colors.green[600])
                    : (isDark ? Colors.grey[500] : Colors.grey[600])),
            InfoItem('MTF', _profile!.mtfEnabled ? 'Enabled' : 'Disabled',
                Icons.trending_up_outlined,
                valueColor: _profile!.mtfEnabled
                    ? (isDark ? Colors.green[400] : Colors.green[600])
                    : (isDark ? Colors.grey[500] : Colors.grey[600])),
          ],
          isDark,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    Color borderColor,
    String title,
    IconData titleIcon,
    List<InfoItem> items,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    titleIcon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          ...items
              .map((item) => _buildInfoRow(item, isDark, borderColor))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(InfoItem item, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.valueColor ??
                        (isDark ? Colors.white : Colors.black87),
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

class InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  InfoItem(this.label, this.value, this.icon, {this.valueColor});
}
