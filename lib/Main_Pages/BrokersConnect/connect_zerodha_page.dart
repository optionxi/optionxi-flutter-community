import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/Main_Pages/BrokersConnect/step_sections.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/homepage_zerodha.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────
class _ZerodhaTheme {
  static const zerodhaRed = Color(0xFFE63946);
  static const successGreen = Color(0xFF22C55E);
  static const errorRed = Color(0xFFEF4444);
  static const warningAmber = Color(0xFFF59E0B);

  static Color surface(bool dark) =>
      dark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC);
  static Color card(bool dark) => dark ? const Color(0xFF1A1D27) : Colors.white;
  static Color cardBorder(bool dark) =>
      dark ? const Color(0xFF2A2D3A) : const Color(0xFFE8ECF0);
  static Color subtle(bool dark) =>
      dark ? const Color(0xFF2A2D3A) : const Color(0xFFF1F5F9);
  static Color textPrimary(bool dark) =>
      dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color textSecondary(bool dark) =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color inputFill(bool dark) =>
      dark ? const Color(0xFF1E2130) : const Color(0xFFF8FAFC);
  static Color inputBorder(bool dark) =>
      dark ? const Color(0xFF2E3347) : const Color(0xFFDDE3ED);
}

// ─────────────────────────────────────────────────────────────
//  Main Widget
// ─────────────────────────────────────────────────────────────
class ZerodhaConnectPage extends StatefulWidget {
  const ZerodhaConnectPage({Key? key}) : super(key: key);

  @override
  State<ZerodhaConnectPage> createState() => _ZerodhaConnectPageState();
}

class _ZerodhaConnectPageState extends State<ZerodhaConnectPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _apiKeyFocus = FocusNode();
  final _apiSecretFocus = FocusNode();

  String _status = 'disconnected';
  String _statusMessage = 'Initializing...';
  DateTime? _lastUpdated;
  bool _isLoading = false;
  bool _obscureApiSecret = true;
  String? _suid;
  bool _isAuthChecking = true;
  bool _apiKeyFocused = false;
  bool _apiSecretFocused = false;

  late DatabaseReference _dbRef;
  StreamSubscription<DatabaseEvent>? _realtimeListener;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _apiKeyFocus.addListener(() {
      if (mounted) setState(() => _apiKeyFocused = _apiKeyFocus.hasFocus);
    });
    _apiSecretFocus.addListener(() {
      if (mounted) setState(() => _apiSecretFocused = _apiSecretFocus.hasFocus);
    });

    _initializePage();
  }

  @override
  void dispose() {
    _realtimeListener?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _apiKeyFocus.dispose();
    _apiSecretFocus.dispose();
    super.dispose();
  }

  // ── Core Logic ────────────────────────────────────────────

  Future<void> _initializePage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _suid = user.uid;
      _dbRef = FirebaseDatabase.instance.ref().child('brokers/zerodha/$_suid');
      await _loadConnectionDetails();
      _setupRealtimeListener();
    } else {
      if (mounted) {
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Please sign in to connect your broker account.';
        });
      }
    }
    if (mounted) {
      setState(() => _isAuthChecking = false);
      _fadeController.forward();
      _slideController.forward();
      if (_status == 'pending') _pulseController.repeat(reverse: true);
    }
  }

  void _setupRealtimeListener() {
    if (_suid == null) return;
    _realtimeListener = _dbRef.onValue.listen(
      (event) {
        if (mounted) _handleRealtimeUpdate(event);
      },
      onError: (error) {
        FirebaseCrashlytics.instance.recordError(error, StackTrace.current,
            reason: 'Real-time listener error in ZerodhaConnectPage',
            fatal: false,
            information: ['User ID: $_suid']);
        if (mounted) {
          _showToast('Connection monitoring error', isError: true);
        }
      },
    );
  }

  void _handleRealtimeUpdate(DatabaseEvent event) {
    if (!mounted) return;
    final snapshot = event.snapshot;
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      _updateStateFromData(data);
    } else {
      if (_status != 'disconnected') {
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Enter credentials to connect.';
          _lastUpdated = null;
          _apiKeyController.clear();
          _apiSecretController.clear();
        });
        _pulseController.stop();
      }
    }
  }

  Future<void> _loadConnectionDetails() async {
    if (_suid == null) return;
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _updateStateFromData(data, isInitialLoad: true);
      } else {
        if (mounted) {
          setState(() {
            _status = 'disconnected';
            _statusMessage = 'Enter credentials to connect.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'error';
          _statusMessage = 'Failed to load: ${e.toString()}';
        });
      }
    }
  }

  void _updateStateFromData(Map<String, dynamic> data,
      {bool isInitialLoad = false}) {
    if (!mounted) return;
    if (isInitialLoad) {
      _apiKeyController.text = data['api_key'] ?? '';
      _apiSecretController.text = data['api_secret'] ?? '';
    }
    final lastMs = data['updated_at'];
    final newLastUpdated =
        (lastMs is int) ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    final newStatus = data['status'] ?? 'disconnected';
    String newMsg;
    _pulseController.stop();

    switch (newStatus) {
      case 'authenticated':
        newMsg = 'Connected and ready to trade';
        if (_status != 'authenticated') _showSuccessBottomSheet();
        break;
      case 'credentials_saved':
        newMsg = 'Credentials saved — tap Authenticate to continue';
        break;
      case 'pending':
        newMsg = 'Generating access token…';
        _pulseController.repeat(reverse: true);
        break;
      case 'connection_failed':
        newMsg =
            data['error_message'] ?? 'Connection failed. Check credentials.';
        break;
      default:
        newMsg = 'Enter your API Key and Secret to get started';
    }

    if (_status != newStatus ||
        _statusMessage != newMsg ||
        _lastUpdated != newLastUpdated) {
      setState(() {
        _status = newStatus;
        _statusMessage = newMsg;
        _lastUpdated = newLastUpdated;
      });
    }
  }

  // ── User Actions ──────────────────────────────────────────

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _dbRef.update({
        'api_key': _apiKeyController.text.trim(),
        'api_secret': _apiSecretController.text.trim(),
        'updated_at': ServerValue.timestamp,
        'status': 'credentials_saved',
      });
      _showToast('Credentials saved — now authenticate with Zerodha');
    } catch (e) {
      _showToast('Save failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchZerodhaAuthentication() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showToast('Please save a valid API Key first', isError: true);
      return;
    }
    final suid = FirebaseAuth.instance.currentUser!.uid;
    final encodedSuid =
        Uri.encodeComponent('suid=$suid'); // encodes to suid%3D<value>
    final url = Uri.parse(
        'https://kite.trade/connect/login?v=3&api_key=${_apiKeyController.text.trim()}&redirect_params=$encodedSuid');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showToast('Could not launch authentication URL', isError: true);
    }
  }

  Future<void> _disconnectAccount() async {
    final confirm = await _showConfirmDialog();
    if (confirm == true) {
      await _dbRef.remove();
      _formKey.currentState?.reset();
    }
  }

  // ── Dialogs & Sheets ──────────────────────────────────────

  Future<bool?> _showConfirmDialog() => showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: _ZerodhaTheme.card(dark),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _ZerodhaTheme.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_off_rounded,
                      color: _ZerodhaTheme.errorRed, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Disconnect Account'),
              ],
            ),
            content: Text(
              'This will delete your stored credentials and disconnect your Zerodha account permanently.',
              style: TextStyle(color: _ZerodhaTheme.textSecondary(dark)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: _ZerodhaTheme.errorRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Disconnect'),
              ),
            ],
          );
        },
      );

  void _showSuccessBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: _ZerodhaTheme.card(dark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).padding.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _ZerodhaTheme.cardBorder(dark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _ZerodhaTheme.successGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _ZerodhaTheme.successGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.check_rounded,
                      color: _ZerodhaTheme.successGreen, size: 32),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'You\'re Connected!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ZerodhaTheme.textPrimary(dark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Zerodha account is linked and ready.\nStart trading now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _ZerodhaTheme.textSecondary(dark),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => HomepageZerodha()));
                  },
                  icon: const Icon(FontAwesomeIcons.chartLine, size: 16),
                  label: const Text('Start Trading',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ZerodhaTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      backgroundColor:
          isError ? _ZerodhaTheme.errorRed : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [
        Icon(
          isError ? Icons.warning_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.white, fontSize: 14))),
      ]),
    ));
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (_isAuthChecking) return _buildLoadingScreen(dark);
    if (_suid == null) return _buildAuthRequiredScreen(dark);

    return Scaffold(
      backgroundColor: _ZerodhaTheme.surface(dark),
      appBar: _buildAppBar(dark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBanner(dark),
                  const SizedBox(height: 24),
                  if (_status == 'authenticated') ...[
                    _buildStartTradingCard(dark),
                    const SizedBox(height: 24),
                    _buildSectionDivider('Account Settings', dark),
                    const SizedBox(height: 16),
                  ],
                  if (_status != 'authenticated') ...[
                    _buildStepFlow(dark),
                    const SizedBox(height: 24),
                  ],
                  _buildCredentialsCard(dark),
                  const SizedBox(height: 16),
                  _buildActionArea(dark),
                  const SizedBox(height: 28),
                  _buildRedirectCard(dark),
                  const SizedBox(height: 16),
                  ApiKeyStepsSection(brokerName: "zerodha"),
                  const SizedBox(height: 16),
                  _buildSecurityCard(dark),
                  const SizedBox(height: 16),
                  _buildHelpCard(dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool dark) => AppBar(
        backgroundColor: _ZerodhaTheme.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: _ZerodhaTheme.textPrimary(dark)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.asset('assets/brokers/kite.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Zerodha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ZerodhaTheme.textPrimary(dark),
              ),
            ),
            const SizedBox(width: 8),
            _buildLiveDot(dark),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: _ZerodhaTheme.textSecondary(dark), size: 20),
            onPressed: _loadConnectionDetails,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      );

  Widget _buildLiveDot(bool dark) {
    final isActive =
        _status == 'authenticated' || _status == 'credentials_saved';
    final isPending = _status == 'pending';
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? _ZerodhaTheme.successGreen
            : isPending
                ? _ZerodhaTheme.warningAmber
                : _ZerodhaTheme.textSecondary(dark).withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  // ── Status Banner ─────────────────────────────────────────

  Widget _buildStatusBanner(bool dark) {
    final config = _statusConfig(dark);
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (ctx, _) {
        return Transform.scale(
          scale: _status == 'pending' ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: config['bg'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (config['accent'] as Color).withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (config['accent'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(config['icon'] as IconData,
                      color: config['accent'] as Color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: config['accent'] as Color,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: _ZerodhaTheme.textSecondary(dark),
                          height: 1.4,
                        ),
                      ),
                      if (_lastUpdated != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Updated ${DateFormat.MMMd().add_jm().format(_lastUpdated!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _ZerodhaTheme.textSecondary(dark)
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
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

  Map<String, dynamic> _statusConfig(bool dark) {
    switch (_status) {
      case 'authenticated':
        return {
          'bg': _ZerodhaTheme.successGreen.withOpacity(dark ? 0.1 : 0.06),
          'accent': _ZerodhaTheme.successGreen,
          'icon': Icons.verified_rounded,
          'label': 'CONNECTED',
        };
      case 'credentials_saved':
        return {
          'bg': _ZerodhaTheme.zerodhaRed.withOpacity(dark ? 0.1 : 0.06),
          'accent': _ZerodhaTheme.zerodhaRed,
          'icon': Icons.task_alt_rounded,
          'label': 'CREDENTIALS SAVED',
        };
      case 'pending':
        return {
          'bg': _ZerodhaTheme.warningAmber.withOpacity(dark ? 0.1 : 0.06),
          'accent': _ZerodhaTheme.warningAmber,
          'icon': Icons.hourglass_top_rounded,
          'label': 'CONNECTING',
        };
      case 'connection_failed':
      case 'error':
        return {
          'bg': _ZerodhaTheme.errorRed.withOpacity(dark ? 0.1 : 0.06),
          'accent': _ZerodhaTheme.errorRed,
          'icon': Icons.error_outline_rounded,
          'label': 'FAILED',
        };
      default:
        return {
          'bg': _ZerodhaTheme.subtle(dark),
          'accent': _ZerodhaTheme.textSecondary(dark),
          'icon': Icons.radio_button_unchecked_rounded,
          'label': 'NOT CONNECTED',
        };
    }
  }

  // ── Step Flow Guide ───────────────────────────────────────

  Widget _buildStepFlow(bool dark) {
    final steps = [
      _StepInfo(
        number: '1',
        title: 'Save Credentials',
        subtitle: 'Enter your API Key & Secret',
        isDone: _status != 'disconnected',
        isActive: _status == 'disconnected',
      ),
      _StepInfo(
        number: '2',
        title: 'Authenticate',
        subtitle: 'Login via Zerodha Kite',
        isDone: _status == 'authenticated',
        isActive: _status == 'credentials_saved' ||
            _status == 'pending' ||
            _status == 'connection_failed',
      ),
      _StepInfo(
        number: '3',
        title: 'Start Trading',
        subtitle: 'You\'re ready to go',
        isDone: false,
        isActive: _status == 'authenticated',
      ),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = steps[i ~/ 2];
          return Expanded(
            child: Container(
              height: 2,
              color: leftStep.isDone
                  ? _ZerodhaTheme.zerodhaRed.withOpacity(0.5)
                  : _ZerodhaTheme.cardBorder(dark),
            ),
          );
        }
        return _buildStepDot(steps[i ~/ 2], dark);
      }),
    );
  }

  Widget _buildStepDot(_StepInfo step, bool dark) {
    Color accentColor;
    Widget icon;

    if (step.isDone) {
      accentColor = _ZerodhaTheme.zerodhaRed;
      icon = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
    } else if (step.isActive) {
      accentColor = _ZerodhaTheme.zerodhaRed;
      icon = Text(step.number,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700));
    } else {
      accentColor = _ZerodhaTheme.cardBorder(dark);
      icon = Text(step.number,
          style: TextStyle(
              color: _ZerodhaTheme.textSecondary(dark),
              fontSize: 12,
              fontWeight: FontWeight.w600));
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: step.isDone || step.isActive
                ? accentColor
                : _ZerodhaTheme.subtle(dark),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 2),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        Text(
          step.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: step.isActive || step.isDone
                ? _ZerodhaTheme.textPrimary(dark)
                : _ZerodhaTheme.textSecondary(dark),
          ),
        ),
      ],
    );
  }

  // ── Start Trading Card ────────────────────────────────────

  Widget _buildStartTradingCard(bool dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ZerodhaTheme.successGreen,
            Color(0xFF16A34A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _ZerodhaTheme.successGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('Account Active',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready to trade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zerodha account connected',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => HomepageZerodha())),
            icon: const Icon(FontAwesomeIcons.chartLine, size: 14),
            label: const Text('Trade',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _ZerodhaTheme.successGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Credentials Card ──────────────────────────────────────

  Widget _buildCredentialsCard(bool dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ZerodhaTheme.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ZerodhaTheme.cardBorder(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('API Credentials',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ZerodhaTheme.textPrimary(dark),
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _ZerodhaTheme.zerodhaRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Kite Connect',
                    style: TextStyle(
                        fontSize: 10,
                        color: _ZerodhaTheme.zerodhaRed,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Find these in your Kite Connect developer dashboard',
            style: TextStyle(
                fontSize: 12, color: _ZerodhaTheme.textSecondary(dark)),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _apiKeyController,
            focusNode: _apiKeyFocus,
            isFocused: _apiKeyFocused,
            label: 'API Key',
            hint: 'e.g. abc123xyz',
            icon: Icons.vpn_key_rounded,
            dark: dark,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'API Key is required' : null,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _apiSecretController,
            focusNode: _apiSecretFocus,
            isFocused: _apiSecretFocused,
            label: 'API Secret',
            hint: '••••••••••••••••',
            icon: Icons.lock_rounded,
            dark: dark,
            obscureText: _obscureApiSecret,
            onToggleObscure: () =>
                setState(() => _obscureApiSecret = !_obscureApiSecret),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'API Secret is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String label,
    required String hint,
    required IconData icon,
    required bool dark,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFocused
                  ? _ZerodhaTheme.zerodhaRed
                  : _ZerodhaTheme.textSecondary(dark),
            )),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? _ZerodhaTheme.zerodhaRed
                  : _ZerodhaTheme.inputBorder(dark),
              width: isFocused ? 1.5 : 1,
            ),
            color: _ZerodhaTheme.inputFill(dark),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            validator: validator,
            readOnly: _isLoading,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _ZerodhaTheme.textPrimary(dark),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: _ZerodhaTheme.textSecondary(dark).withOpacity(0.5),
                  fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon,
                    size: 18,
                    color: isFocused
                        ? _ZerodhaTheme.zerodhaRed
                        : _ZerodhaTheme.textSecondary(dark)),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: _ZerodhaTheme.textSecondary(dark),
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              errorStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action Buttons ────────────────────────────────────────

  Widget _buildActionArea(bool dark) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _ZerodhaTheme.zerodhaRed,
              ),
            ),
            const SizedBox(width: 14),
            Text('Saving…',
                style: TextStyle(
                    color: _ZerodhaTheme.textSecondary(dark), fontSize: 14)),
          ],
        ),
      );
    }

    switch (_status) {
      case 'credentials_saved':
      case 'connection_failed':
        return Column(
          children: [
            _primaryButton(
              label: 'Authenticate with Zerodha',
              icon: Icons.open_in_browser_rounded,
              color: _ZerodhaTheme.zerodhaRed,
              onTap: _launchZerodhaAuthentication,
            ),
            const SizedBox(height: 10),
            _ghostButton(
              label: 'Update Credentials',
              icon: Icons.edit_rounded,
              onTap: _saveCredentials,
              dark: dark,
            ),
            const SizedBox(height: 10),
            _ghostButton(
              label: 'Delete & Disconnect',
              icon: Icons.delete_outline_rounded,
              onTap: _disconnectAccount,
              dark: dark,
              isDestructive: true,
            ),
          ],
        );
      case 'authenticated':
        return _ghostButton(
          label: 'Disconnect Account',
          icon: Icons.link_off_rounded,
          onTap: _disconnectAccount,
          dark: dark,
          isDestructive: true,
        );
      default:
        return _primaryButton(
          label: 'Save Credentials',
          icon: Icons.save_rounded,
          color: _ZerodhaTheme.zerodhaRed,
          onTap: _saveCredentials,
        );
    }
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _ghostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool dark,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? _ZerodhaTheme.errorRed
        : _ZerodhaTheme.textSecondary(dark);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Redirect URL Card ─────────────────────────────────────

  Widget _buildRedirectCard(bool dark) {
    const redirectUrl = 'https://fastapi.optionxi.com/broker/zerodha';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ZerodhaTheme.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ZerodhaTheme.cardBorder(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _ZerodhaTheme.zerodhaRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link_rounded,
                  color: _ZerodhaTheme.zerodhaRed, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Redirect URL',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ZerodhaTheme.textPrimary(dark),
                )),
          ]),
          const SizedBox(height: 10),
          Text(
            'Add this URL as the redirect URI in your Kite Connect app settings. You can use the FREE Personal app type.',
            style: TextStyle(
                fontSize: 13,
                color: _ZerodhaTheme.textSecondary(dark),
                height: 1.5),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: redirectUrl));
              _showToast('Redirect URL copied to clipboard');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _ZerodhaTheme.subtle(dark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _ZerodhaTheme.zerodhaRed.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      redirectUrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _ZerodhaTheme.zerodhaRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy_rounded,
                      size: 16, color: _ZerodhaTheme.textSecondary(dark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://developers.kite.trade/apps');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('Open Kite Connect Developer Portal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ZerodhaTheme.zerodhaRed,
                side: BorderSide(
                    color: _ZerodhaTheme.zerodhaRed.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security & Help Cards ─────────────────────────────────

  Widget _buildSecurityCard(bool dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ZerodhaTheme.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ZerodhaTheme.cardBorder(dark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _ZerodhaTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                color: _ZerodhaTheme.successGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your data is secure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ZerodhaTheme.textPrimary(dark),
                    )),
                const SizedBox(height: 4),
                Text(
                  'Credentials are encrypted and used only to generate trading access tokens. You can delete your data anytime.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _ZerodhaTheme.textSecondary(dark),
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

  Widget _buildHelpCard(bool dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ZerodhaTheme.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ZerodhaTheme.cardBorder(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need help?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ZerodhaTheme.textPrimary(dark),
              )),
          const SizedBox(height: 4),
          Text(
            'Watch our step-by-step guide to connect Zerodha',
            style: TextStyle(
                fontSize: 13, color: _ZerodhaTheme.textSecondary(dark)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                        'https://www.youtube.com/watch?v=z7swHkB3Pa0');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Watch Guide',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showContactOptions(context),
                  icon: const Icon(Icons.headset_mic_rounded, size: 18),
                  label: const Text('Support',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ZerodhaTheme.zerodhaRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Utility Widgets ───────────────────────────────────────

  Widget _buildSectionDivider(String label, bool dark) {
    return Row(children: [
      Expanded(child: Divider(color: _ZerodhaTheme.cardBorder(dark))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _ZerodhaTheme.textSecondary(dark),
            letterSpacing: 0.5,
          ),
        ),
      ),
      Expanded(child: Divider(color: _ZerodhaTheme.cardBorder(dark))),
    ]);
  }

  // ── Loading / Auth Required ───────────────────────────────

  Widget _buildLoadingScreen(bool dark) => Scaffold(
        backgroundColor: _ZerodhaTheme.surface(dark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: _ZerodhaTheme.zerodhaRed,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              Text('Loading…',
                  style: TextStyle(
                      color: _ZerodhaTheme.textSecondary(dark), fontSize: 14)),
            ],
          ),
        ),
      );

  Widget _buildAuthRequiredScreen(bool dark) => Scaffold(
        backgroundColor: _ZerodhaTheme.surface(dark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _ZerodhaTheme.errorRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_circle_outlined,
                      color: _ZerodhaTheme.errorRed, size: 48),
                ),
                const SizedBox(height: 24),
                Text('Sign in Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ZerodhaTheme.textPrimary(dark),
                    )),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to connect your Zerodha account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: _ZerodhaTheme.textSecondary(dark),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  Helper model
// ─────────────────────────────────────────────────────────────
class _StepInfo {
  final String number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _StepInfo({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
  });
}
