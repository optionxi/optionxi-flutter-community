import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/BrokersPage/Zerodha/error_state.dart';
import 'package:optionxi/BrokersPage/Zerodha/utils/zerodha_controller.dart';
import 'package:optionxi/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';

class ProfilePageZerodha extends StatefulWidget {
  const ProfilePageZerodha({
    Key? key,
  }) : super(key: key);

  @override
  _ProfilePageZerodhaState createState() => _ProfilePageZerodhaState();
}

class _ProfilePageZerodhaState extends State<ProfilePageZerodha>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  bool _isLoading = true;
  bool _hasError = false;
  dynamic _errorMessage = '';
  KiteUserProfile? _userProfile;

  final ZerodhaRepository _repository = ZerodhaRepository();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchUserProfile();
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

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Use the repository to get profile data
      final profileData = await _repository.getProfile();

      setState(() {
        _userProfile = KiteUserProfile.fromJson(profileData);
        _isLoading = false;
        _hasError = false;
      });

      _shimmerController.stop();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }

      _shimmerController.stop();
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
    } else if (_hasError) {
      return buildErrorStateBroker(_fetchUserProfile, _errorMessage, context);
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
                    // Name skeleton - animated
                    _buildShimmerContainer(
                      width: 150,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // ID skeleton - animated
                    _buildShimmerContainer(
                      width: 100,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    // Broker badge skeleton - animated
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
            {'icon': Icons.person_outline, 'label': 'User Type'},
            {'icon': Icons.badge, 'label': 'Short Name'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Trading Access',
          FontAwesomeIcons.chartLine,
          [
            {'icon': Icons.account_balance, 'label': 'Exchanges'},
            {'icon': Icons.inventory, 'label': 'Products'},
            {'icon': Icons.receipt_long, 'label': 'Order Types'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Account Settings',
          FontAwesomeIcons.cog,
          [
            {'icon': Icons.verified_user, 'label': 'Demat Consent'},
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.userName ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${_userProfile?.userId ?? 'N/A'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  _userProfile?.broker ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
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
            InfoItem('Email', _userProfile?.email ?? 'N/A', Icons.email),
            InfoItem(
                'User Type',
                _userProfile?.userType?.toUpperCase() ?? 'N/A',
                Icons.person_outline),
            InfoItem('Short Name', _userProfile?.userShortname ?? 'N/A',
                Icons.badge),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme,
          borderColor,
          'Trading Access',
          FontAwesomeIcons.chartLine,
          [
            InfoItem('Exchanges', _userProfile?.exchanges?.join(', ') ?? 'N/A',
                Icons.account_balance),
            InfoItem('Products', _userProfile?.products?.join(', ') ?? 'N/A',
                Icons.inventory),
            InfoItem(
                'Order Types',
                _userProfile?.orderTypes?.join(', ') ?? 'N/A',
                Icons.receipt_long),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme,
          borderColor,
          'Account Settings',
          FontAwesomeIcons.cog,
          [
            InfoItem(
                'Demat Consent',
                _userProfile?.meta?.dematConsent?.toUpperCase() ?? 'N/A',
                Icons.verified_user),
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
                    color: isDark ? Colors.white : Colors.black87,
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

  InfoItem(this.label, this.value, this.icon);
}
