import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Upstox/utils/upstox_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Upstox/utils/upstox_datamodel.dart';

class ProfilePageUpstox extends StatefulWidget {
  const ProfilePageUpstox({
    Key? key,
  }) : super(key: key);

  @override
  _ProfilePageUpstoxState createState() => _ProfilePageUpstoxState();
}

class _ProfilePageUpstoxState extends State<ProfilePageUpstox>
    with TickerProviderStateMixin {
  final UpstoxRepository _repository = UpstoxRepository();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  UpstoxProfileModel? profileData;
  UpstoxFundsResponse? fundsData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchData();
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

    if (isLoading) {
      _shimmerController.repeat();
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final results = await Future.wait([
        _repository.getProfile(),
        _repository.getFunds(),
      ]);

      setState(() {
        profileData = results[0] as UpstoxProfileModel;
        fundsData = results[1] as UpstoxFundsResponse;
        isLoading = false;
      });
      _shimmerController.stop();
      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: _buildBody(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (isLoading) {
      return _buildLoadingSkeleton(theme, isDark);
    } else if (error != null) {
      return _buildErrorState(theme);
    } else {
      return _buildProfileContent(theme, isDark);
    }
  }

  Widget _buildProfileContent(ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(theme, isDark),
            const SizedBox(height: 24),
            _buildProfileInfoSection(theme, isDark),
            const SizedBox(height: 16),
            _buildFundsSection(theme, isDark),
            const SizedBox(height: 16),
            _buildTradingInfoSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.orange.shade700, Colors.red.shade700]
                    : [Colors.orange.shade400, Colors.red.shade400],
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
          Text(
            profileData?.userName ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${profileData?.userId ?? 'N/A'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  profileData?.broker ?? 'Upstox',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    FontAwesomeIcons.user,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Information',
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
          _buildInfoRow('Email', profileData?.email ?? 'N/A', Icons.email,
              isDark, borderColor),
          _buildInfoRow(
              'User Type',
              profileData?.userType.toUpperCase() ?? 'N/A',
              Icons.person_outline,
              isDark,
              borderColor),
          _buildInfoRow('Broker', profileData?.broker ?? 'Upstox',
              Icons.business, isDark, borderColor,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, bool isDark, Color borderColor,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
            {'icon': Icons.business, 'label': 'Broker'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Funds & Margins',
          FontAwesomeIcons.wallet,
          [
            {'icon': Icons.account_balance_wallet, 'label': 'Equity Funds'},
            {'icon': Icons.trending_up, 'label': 'Commodity Funds'},
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoCardSkeleton(
          theme,
          borderColor,
          'Trading Information',
          FontAwesomeIcons.chartLine,
          [
            {'icon': Icons.account_balance, 'label': 'Exchanges'},
            {'icon': Icons.inventory, 'label': 'Products'},
            {'icon': Icons.receipt_long, 'label': 'Order Types'},
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
              .asMap()
              .entries
              .map((entry) => _buildInfoRowSkeleton(
                    entry.value['label'],
                    entry.value['icon'],
                    isDark,
                    borderColor,
                    isLast: entry.key == items.length - 1,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRowSkeleton(
      String label, IconData icon, bool isDark, Color borderColor,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
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
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
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

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load profile data',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundsSection(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.wallet,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Funds & Margins',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Equity Section
            _buildFundCategory('Equity', fundsData?.equity, theme, isDark),
            const SizedBox(height: 16),

            // Commodity Section
            _buildFundCategory(
                'Commodity', fundsData?.commodity, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFundCategory(
      String title, UpstoxFundSegment? data, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFundItem('Available',
                    data?.availableMargin.toStringAsFixed(2) ?? '0.00', theme),
              ),
              Expanded(
                child: _buildFundItem('Used',
                    data?.usedMargin.toStringAsFixed(2) ?? '0.00', theme),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFundItem('Pay-in',
                    data?.payinAmount.toStringAsFixed(2) ?? '0.00', theme),
              ),
              Expanded(
                child: _buildFundItem('Exposure',
                    data?.exposureMargin.toStringAsFixed(2) ?? '0.00', theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹$value',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildTradingInfoSection(ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;
    final exchanges = profileData?.exchanges ?? [];
    final orderTypes = profileData?.orderTypes ?? [];
    final products = profileData?.products ?? [];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.chartLine,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trading Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection('Exchanges', exchanges, theme, isDark),
            const SizedBox(height: 16),
            _buildInfoSection('Order Types', orderTypes, theme, isDark),
            const SizedBox(height: 16),
            _buildInfoSection('Products', products, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<String> items, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No data available',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
