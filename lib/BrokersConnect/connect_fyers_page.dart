import 'dart:async';
import 'dart:developer' as developer; // Using aliased import for clarity
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/BrokersConnect/step_sections.dart';
import 'package:optionxi/BrokersPage/Fyers/homepage_fyers.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// --- Main Widget ---
class FyersConnectPage extends StatefulWidget {
  const FyersConnectPage({Key? key}) : super(key: key);

  @override
  State<FyersConnectPage> createState() => _FyersConnectPageState();
}

class _FyersConnectPageState extends State<FyersConnectPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();

  // State variables
  String _status = 'disconnected';
  String _statusMessage = 'Initializing...';
  DateTime? _lastUpdated;
  bool _isLoading = false;
  bool _obscureApiSecret = true;
  String? _suid;
  bool _isAuthChecking = true;

  // Firebase and animation controllers
  late DatabaseReference _dbRef;
  StreamSubscription<DatabaseEvent>? _realtimeListener;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    developer.log('🚀 [FyersConnectPage] Initializing page...',
        name: 'FyersConnect');

    // Initialize animations
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Start the page initialization logic
    _initializePage();
  }

  @override
  void dispose() {
    developer.log('🧹 [FyersConnectPage] Disposing resources...',
        name: 'FyersConnect');
    _realtimeListener?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  Future<void> _initializePage() async {
    developer.log('🔧 [FyersConnectPage] Starting page initialization...',
        name: 'FyersConnect');
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _suid = user.uid;
      _dbRef = FirebaseDatabase.instance.ref().child('brokers/fyers/$_suid');
      await _loadConnectionDetails();
      _setupRealtimeListener();
    } else {
      developer.log('❌ [FyersConnectPage] No authenticated user found',
          name: 'FyersConnect');
      if (mounted) {
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Please sign in to connect your broker account.';
        });
      }
    }

    if (mounted) {
      setState(() => _isAuthChecking = false);
      _animationController.forward();
      if (_status == 'checking' || _status == 'pending') {
        _pulseController.repeat(reverse: true);
      }
    }
    developer.log('✅ [FyersConnectPage] Page initialization complete',
        name: 'FyersConnect');
  }

  void _setupRealtimeListener() {
    if (_suid == null) return;
    developer.log('🔄 [FyersConnectPage] Setting up real-time listener...',
        name: 'FyersConnect');
    _realtimeListener = _dbRef.onValue.listen(
      (DatabaseEvent event) {
        developer.log('📡 [FyersConnectPage] Real-time update received',
            name: 'FyersConnect');
        if (mounted) _handleRealtimeUpdate(event);
      },
      onError: (error) {
        developer.log('❌ [FyersConnectPage] Real-time listener error: $error',
            error: error, name: 'FyersConnect');

        // ✅ Explicitly log to Crashlytics with context
        FirebaseCrashlytics.instance.recordError(
          error,
          StackTrace.current,
          reason: 'Real-time listener error in FyersConnectPage',
          fatal: false,
          information: ['User ID: $_suid', 'Database path: ${_dbRef.path}'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Connection monitoring error: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error));
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
      // No data exists, reset to disconnected state
      if (_status != 'disconnected') {
        if (mounted) {
          setState(() {
            _status = 'disconnected';
            _statusMessage = 'Enter credentials to connect.';
            _lastUpdated = null;
            _apiKeyController.clear();
            _apiSecretController.clear();
          });
          _pulseController.stop();
        }
        developer.log(
            '📭 [FyersConnectPage] Real-time update: Data removed, status reset',
            name: 'FyersConnect');
      }
    }
  }

  Future<void> _loadConnectionDetails() async {
    if (_suid == null) return;
    developer.log(
        '📥 [FyersConnectPage] Loading connection details from Firebase...',
        name: 'FyersConnect');
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        developer.log('📊 [FyersConnectPage] Connection details found',
            name: 'FyersConnect');
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _updateStateFromData(data, isInitialLoad: true);
      } else {
        developer.log('📭 [FyersConnectPage] No connection details found',
            name: 'FyersConnect');
        if (mounted) {
          setState(() {
            _status = 'disconnected';
            _statusMessage = 'Enter credentials to connect.';
          });
        }
      }
    } catch (e) {
      developer.log('❌ [FyersConnectPage] Error loading details: $e',
          error: e, name: 'FyersConnect');
      if (mounted) {
        setState(() {
          _status = 'error';
          _statusMessage = 'Failed to load details: ${e.toString()}';
        });
      }
    }
  }

  void _updateStateFromData(Map<String, dynamic> data,
      {bool isInitialLoad = false}) {
    if (!mounted) return;

    // Update controllers only on initial load to avoid overwriting user input
    if (isInitialLoad) {
      _apiKeyController.text = data['api_key'] ?? '';
      _apiSecretController.text = data['api_secret'] ?? '';
    }

    final lastUpdatedMillis = data['updated_at'];
    DateTime? newLastUpdated = (lastUpdatedMillis is int)
        ? DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis)
        : null;

    final newStatus = data['status'] ?? 'disconnected';
    String newStatusMessage;

    _pulseController.stop(); // Stop pulse by default

    switch (newStatus) {
      case 'authenticated':
        newStatusMessage = 'You are connected to Fyers and ready to trade!';
        if (_status != 'authenticated') {
          _showSuccessBottomSheet(); // Show success confirmation
        }
        break;
      case 'credentials_saved':
        newStatusMessage =
            'Credentials saved. Please authenticate with Fyers to proceed.';
        break;
      case 'pending':
        newStatusMessage = 'Generating access token... Please wait.';
        _pulseController.repeat(reverse: true);
        break;
      case 'connection_failed':
        newStatusMessage =
            'Connection failed: ${data['error_message'] ?? 'Please check credentials and try again.'}';
        break;
      default:
        newStatusMessage = 'Enter credentials to connect.';
    }

    // Update state if anything changed
    if (_status != newStatus ||
        _statusMessage != newStatusMessage ||
        _lastUpdated != newLastUpdated) {
      setState(() {
        _status = newStatus;
        _statusMessage = newStatusMessage;
        _lastUpdated = newLastUpdated;
      });
      developer.log('📊 [FyersConnectPage] State updated - Status: $newStatus',
          name: 'FyersConnect');
    }
  }

  // --- User Actions ---

  /// NEW FLOW: Step 1 - Save App ID and Secret
  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) {
      developer.log('❌ [FyersConnectPage] Form validation failed',
          name: 'FyersConnect');
      return;
    }

    developer.log('🔄 [FyersConnectPage] Saving credentials...',
        name: 'FyersConnect');
    setState(() => _isLoading = true);

    try {
      final payload = {
        'api_key': _apiKeyController.text.trim(),
        'api_secret': _apiSecretController.text.trim(),
        'updated_at': ServerValue.timestamp,
        'status': 'credentials_saved', // New status
      };
      await _dbRef.update(payload); // Use update to preserve other fields
      developer.log('✅ [FyersConnectPage] Credentials saved successfully',
          name: 'FyersConnect');
      _showStatusNotification(
          'Credentials Saved',
          'Next, authenticate with Fyers to complete the connection.',
          Colors.blue,
          Icons.save_rounded);
    } catch (e) {
      developer.log('❌ [FyersConnectPage] Save failed: $e',
          error: e, name: 'FyersConnect');
      setState(() => _statusMessage = 'Saving failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// NEW FLOW: Step 2 - Launch Fyeres authentication URL
  Future<void> _launchFyersAuthentication() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save a valid App ID first.')));
      return;
    }
    developer.log('🎥 [FyersConnectPage] Launching Fyers authentication...',
        name: 'FyersConnect');
    final suid = FirebaseAuth.instance.currentUser!.uid.toString();
    final url = Uri.parse(
        'https://api-t1.fyers.in/api/v3/generate-authcode?client_id=${_apiKeyController.text.trim()}&redirect_uri=https://fastapi.optionxi.com/broker/fyers&response_type=code&state=$suid');
    print(url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      developer.log('❌ [FyersConnectPage] Failed to launch fyers URL',
          name: 'FyersConnect');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not launch authentication URL.')));
    }
  }

  Future<void> _disconnectAccount() async {
    // This function remains largely the same
    developer.log('🔌 [FyersConnectPage] Disconnect account requested',
        name: 'FyersConnect');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disconnect'),
        content: const Text(
            'This will delete your stored credentials and disconnect your account. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbRef.remove();
      _formKey.currentState?.reset();
      developer.log('✅ [FyersConnectPage] Account disconnected successfully',
          name: 'FyersConnect');
    }
  }

  // --- UI and Widgets ---

  @override
  Widget build(BuildContext context) {
    // The build method now conditionally renders UI based on the new flow
    final theme = Theme.of(context);

    // Loading/Auth Check Screens
    if (_isAuthChecking) return _buildLoadingScreen(theme, 'Initializing...');
    if (_suid == null) return _buildAuthRequiredScreen(theme);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(theme, theme.brightness == Brightness.dark),
                const SizedBox(height: 24),

                // Show trading button if authenticated
                if (_status == 'authenticated') ...[
                  _buildStartTradingButton(),
                  const SizedBox(height: 16),
                ],

                // Input Fields
                _buildTextField(
                  controller: _apiKeyController,
                  label: 'App ID',
                  icon: Icons.vpn_key_rounded,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'App ID is required' : null,
                  readOnly: _isLoading,
                  theme: theme,
                ),
                _buildTextField(
                  controller: _apiSecretController,
                  label: 'Secret ID',
                  icon: Icons.key_rounded,
                  obscureText: _obscureApiSecret,
                  onToggle: () =>
                      setState(() => _obscureApiSecret = !_obscureApiSecret),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Secret ID is required' : null,
                  readOnly: _isLoading,
                  theme: theme,
                ),

                // Action Buttons
                _buildActionButtons(theme),

                const SizedBox(height: 20),
                _buildRedirectNote(theme),

                const SizedBox(height: 20),
                ApiKeyStepsSection(brokerName: "fyers"),

                const SizedBox(height: 20),
                _buildSecurityNote(theme),
                const SizedBox(height: 20),
                _buildHelpSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main action button(s) based on the current connection status.
  Widget _buildActionButtons(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // NEW FLOW: Conditional buttons
    switch (_status) {
      case 'credentials_saved':
      case 'connection_failed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _launchFyersAuthentication,
              icon: const Icon(Icons.security_rounded),
              label: const Text('Authenticate with Fyers'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saveCredentials,
              child: const Text('Re-save Credentials'),
            )
          ],
        );
      case 'authenticated':
        return OutlinedButton.icon(
          onPressed: _disconnectAccount,
          icon: const Icon(Icons.link_off_rounded),
          label: const Text('Disconnect and Delete Credentials'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      case 'disconnected':
      default:
        return FilledButton.icon(
          onPressed: _saveCredentials,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Credentials'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
    }
  }

  /// Shows a modern bottom sheet confirming successful connection.
  void _showSuccessBottomSheet() {
    // Ensure it doesn't build if the widget is disposed
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // solid white background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16), // same as container
                      child: Image.asset(
                        "assets/brokers/fyers.png", // e.g., "assets/image/broker.png"
                        width: 50,
                        height: 50,
                        fit: BoxFit
                            .cover, // ensures cutoff/fill inside rounded edges
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Connection Successful!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Fyers account is connected and ready for trading.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildStartTradingButton(isPrimary: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartTradingButton({bool isPrimary = false}) {
    final button = FilledButton.icon(
      onPressed: () async {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close bottom sheet if open
        }

        // Open Fyers Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageFyers(),
          ),
        );
      },
      icon: const Icon(FontAwesomeIcons.chartArea),
      label: const Text('Start Trading'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return SizedBox(width: double.infinity, child: button);
  }

  void _showStatusNotification(
      String title, String message, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Row(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text(message, style: const TextStyle(color: Colors.white)),
              ])),
        ])));
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(children: [
        const Text('Connect to Fyers'),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _realtimeListener != null ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ]),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadConnectionDetails,
          tooltip: 'Refresh Status',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingScreen(ThemeData theme, String text) {
    return Scaffold(
        appBar: AppBar(title: const Text('Connect to Fyers')),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.bodyLarge),
        ])));
  }

  Widget _buildAuthRequiredScreen(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.no_accounts_rounded,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text('Authentication Required',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Please sign in to connect your broker account.',
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final statusConfig = {
      'authenticated': {
        'color': Colors.green,
        'icon': Icons.check_circle_rounded,
        'containerColor': Colors.green.withOpacity(0.1),
        'onContainerColor': theme.brightness == Brightness.dark
            ? Colors.green.shade200
            : Colors.green.shade900
      },
      'error': {
        'color': theme.colorScheme.error,
        'icon': Icons.error_rounded,
        'containerColor': theme.colorScheme.errorContainer,
        'onContainerColor': theme.colorScheme.onErrorContainer
      },
      'connection_failed': {
        'color': theme.colorScheme.error,
        'icon': Icons.warning_rounded,
        'containerColor': theme.colorScheme.errorContainer,
        'onContainerColor': theme.colorScheme.onErrorContainer
      },
      'credentials_saved': {
        'color': Colors.blue,
        'icon': Icons.save_rounded,
        'containerColor': Colors.blue.withOpacity(0.1),
        'onContainerColor': theme.brightness == Brightness.dark
            ? Colors.blue.shade200
            : Colors.blue.shade900
      },
      'pending': {
        'color': theme.colorScheme.tertiary,
        'icon': Icons.pending_rounded,
        'containerColor': theme.colorScheme.tertiaryContainer,
        'onContainerColor': theme.colorScheme.onTertiaryContainer
      },
      'disconnected': {
        'color': theme.colorScheme.outline,
        'icon': Icons.info_rounded,
        'containerColor': theme.colorScheme.surfaceVariant,
        'onContainerColor': theme.colorScheme.onSurfaceVariant
      },
    };
    final config = statusConfig[_status] ?? statusConfig['disconnected']!;
    return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
              scale: (_status == 'pending') ? _pulseAnimation.value : 1.0,
              child: Card(
                  elevation: 0,
                  color: config['containerColor'] as Color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(children: [
                        Icon(config['icon'] as IconData,
                            color: config['color'] as Color, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_status.toUpperCase().replaceAll('_', ' '),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          config['onContainerColor'] as Color)),
                              const SizedBox(height: 4),
                              Text(_statusMessage,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          (config['onContainerColor'] as Color)
                                              .withOpacity(0.8))),
                              if (_lastUpdated != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                    'Last Updated: ${DateFormat.yMMMd().add_jm().format(_lastUpdated!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: (config['onContainerColor']
                                                as Color)
                                            .withOpacity(0.6))),
                              ]
                            ])),
                      ]))));
        });
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      required ThemeData theme,
      bool obscureText = false,
      VoidCallback? onToggle,
      String? Function(String?)? validator,
      bool readOnly = false}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            readOnly: readOnly,
            decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: theme.colorScheme.primary),
                suffixIcon: onToggle != null
                    ? IconButton(
                        icon: Icon(obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: onToggle)
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: readOnly
                    ? theme.colorScheme.onSurface.withOpacity(0.05)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3))));
  }

  Widget _buildRedirectNote(ThemeData theme) {
    const String redirectUrl = 'https://fastapi.optionxi.com/broker/fyers';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.link, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Text('Redirect URL',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer)),
            ]),
            const SizedBox(height: 12),
            Text(
              'You should add the redirect url in your fyers developer app',
              style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color:
                      theme.colorScheme.onSecondaryContainer.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: redirectUrl));
                _showStatusNotification(
                    'Link Copied',
                    'Paste the link as the redirect url in the fyers developer portal',
                    Colors.blue,
                    Icons.link);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        redirectUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 16,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://myapi.fyers.in/dashboard');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text('go to fyers developer page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.security_rounded,
                  color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Text('Verification Process',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer)),
            ]),
            const SizedBox(height: 12),
            Text(
              'Your API credentials are securely stored and are used solely to generate an access token for placing trades. You can delete your data at any time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color:
                      theme.colorScheme.onSecondaryContainer.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme) {
    void launchYouTube() async {
      final url = Uri.parse('https://www.youtube.com/watch?v=-k-3eZQkxPU');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Need Help?',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Follow our video guide to get your API credentials from Fyers.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: launchYouTube,
              icon: const Icon(Icons.play_circle_rounded),
              label: const Text('Watch Setup Guide'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showContactOptions(context),
              icon: const Icon(Icons.email_rounded),
              label: const Text('Contact Customer Support'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
