import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickSettingsPage extends StatefulWidget {
  const QuickSettingsPage({
    Key? key,
  }) : super(key: key);

  @override
  _QuickSettingsPageState createState() => _QuickSettingsPageState();
}

class _QuickSettingsPageState extends State<QuickSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _skipLandingPage = false;
  String? _defaultMode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _loadPreferences();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF0A0F1E), Color(0xFF1A1F35)]
                : [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header with settings
                SizedBox(
                  height: 24,
                ),

                _buildQuickSettingsSection(isDark, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isDark,
    required StateSetter setModalState,
  }) {
    final isSelected = _defaultMode == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _defaultMode = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _defaultMode,
              onChanged: (val) {
                setModalState(() {
                  _defaultMode = val;
                });
              },
              activeColor: theme.colorScheme.primary,
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FaIcon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingsSection(bool isDark, ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'Quick Launch',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Skip the decision-making next time and launch directly into your preferred trading mode',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),

            // Quick Settings Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Color(0xFF1E3A8A).withOpacity(0.2),
                          Color(0xFF7C3AED).withOpacity(0.1),
                        ]
                      : [
                          Color(0xFF3B82F6).withOpacity(0.05),
                          Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[300]!.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showSettingsBottomSheet,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Icon Container
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 20),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Quick Settings',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                Colors.amber.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'TIME SAVER',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.amber[700],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Set your preferred mode and skip this page',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.5),
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Features Row
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickFeature(
                                icon: Icons.speed,
                                label: 'Faster Access',
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300],
                              ),
                              _buildQuickFeature(
                                icon: Icons.memory,
                                label: 'Remembers Choice',
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300],
                              ),
                              _buildQuickFeature(
                                icon: Icons.tune,
                                label: 'Customizable',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeature({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.blue[300] : Colors.blue[600],
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _skipLandingPage = prefs.getBool('skipLandingPage') ?? false;
      _defaultMode =
          prefs.getString('defaultTradingMode'); // 'virtual' or 'live'
      _isLoading = false;
    });
  }

  Future<void> _updatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipLandingPage', _skipLandingPage);
    if (_defaultMode != null) {
      await prefs.setString('defaultTradingMode', _defaultMode!);
    } else {
      await prefs.remove('defaultTradingMode');
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1A1F35) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Quick Launch Settings',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Customize your trading experience for faster access',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Skip Landing Page Option
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Quick Launch',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Skip this page and launch directly into your preferred trading mode',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _skipLandingPage,
                          onChanged: (value) {
                            setModalState(() {
                              _skipLandingPage = value ?? false;
                              if (!_skipLandingPage) {
                                _defaultMode = null;
                              }
                            });
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enable Quick Launch',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Default Mode Selection (only shown if skip is enabled)
              if (_skipLandingPage) ...[
                SizedBox(height: 16),
                Text(
                  'Default Trading Mode',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose which mode to launch directly into',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),

                // Virtual Trading Option
                _buildModeOption(
                  title: 'Virtual Trading',
                  subtitle: 'Previous-day data • Risk-free',
                  icon: FontAwesomeIcons.gamepad,
                  value: 'virtual',
                  isDark: isDark,
                  setModalState: setModalState,
                ),
                SizedBox(height: 8),
              ],

              SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _updatePreferences();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Settings saved successfully'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save Settings',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
