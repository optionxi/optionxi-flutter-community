import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  // Form and controller declarations remain the same...
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _totpKeyController = TextEditingController();

  // State variables remain the same...
  String _status = 'disconnected';
  String _statusMessage = 'Initializing...';
  DateTime? _lastUpdated;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureApiSecret = true;
  bool _obscureTotpKey = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  String? _suid;
  bool _isAuthChecking = true;
  late DatabaseReference _dbRef;

  // ✨ Real-time listener variable
  StreamSubscription<DatabaseEvent>? _realtimeListener;

  @override
  void initState() {
    super.initState();
    print('🚀 [FyersConnectPage] Initializing page...');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializePage();
  }

  Future<void> _initializePage() async {
    print('🔧 [FyersConnectPage] Starting page initialization...');

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('👤 [FyeresConnectPage] User authenticated: ${user.uid}');
      _suid = user.uid;
      _dbRef = FirebaseDatabase.instance.ref().child('brokers/fyers/$_suid');

      // Load initial data and setup real-time listener
      await _loadConnectionDetails();
      _setupRealtimeListener();
    } else {
      print('❌ [FyersConnectPage] No authenticated user found');
      setState(() {
        _status = 'disconnected';
        _statusMessage = 'Please sign in to connect your broker account.';
      });
    }

    setState(() => _isAuthChecking = false);
    _animationController.forward();
    if (_status == 'checking' || _status == 'pending') {
      _pulseController.repeat(reverse: true);
    }
    print('✅ [FyersConnectPage] Page initialization complete');
  }

  // ✨ Setup real-time listener for Firebase changes
  void _setupRealtimeListener() {
    if (_suid == null) return;

    print('🔄 [FyersConnectPage] Setting up real-time listener...');

    _realtimeListener = _dbRef.onValue.listen(
      (DatabaseEvent event) {
        print('📡 [FyersConnectPage] Real-time update received');
        _handleRealtimeUpdate(event);
      },
      onError: (error) {
        print('❌ [FyersConnectPage] Real-time listener error: $error');
        // Optionally show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection monitoring error: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  // ✨ Handle real-time updates from Firebase
  void _handleRealtimeUpdate(DatabaseEvent event) {
    if (!mounted) return;

    final snapshot = event.snapshot;

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Update form controllers if values changed
      if (_usernameController.text != (data['user_id'] ?? '')) {
        _usernameController.text = data['user_id'] ?? '';
      }
      if (_passwordController.text != (data['password'] ?? '')) {
        _passwordController.text = data['password'] ?? '';
      }
      if (_apiKeyController.text != (data['api_key'] ?? '')) {
        _apiKeyController.text = data['api_key'] ?? '';
      }
      if (_apiSecretController.text != (data['api_secret'] ?? '')) {
        _apiSecretController.text = data['api_secret'] ?? '';
      }
      if (_totpKeyController.text != (data['totp_key'] ?? '')) {
        _totpKeyController.text = data['totp_key'] ?? '';
      }

      // Update last updated time
      final lastUpdatedMillis = data['updated_at'];
      DateTime? newLastUpdated;
      if (lastUpdatedMillis is int) {
        newLastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
      }

      final newStatus = data['status'] ?? 'disconnected';
      String newStatusMessage;

      // Determine status message based on new status
      switch (newStatus) {
        case 'authenticated':
          newStatusMessage = 'You are connected to Fyers and ready to trade!';
          _pulseController.stop();
          // Show success snackbar if status changed to authenticated
          if (_status != 'authenticated') {
            _showStatusNotification(
              'Connection Successful!',
              'Your Fyers account is now connected and ready for trading.',
              Colors.green,
              Icons.check_circle_rounded,
            );
          }
          break;
        case 'pending':
          newStatusMessage =
              'Credentials saved. Server verification in progress...';
          _pulseController.repeat(reverse: true);
          break;
        case 'credentials_saved':
          newStatusMessage = 'Connection details saved. Ready to connect.';
          _pulseController.stop();
          break;
        case 'connection_failed':
          newStatusMessage =
              'Connection failed: ${data['error_message'] ?? 'Please check credentials and try again.'}';
          _pulseController.stop();
          // Show error notification if status changed to failed
          if (_status != 'connection_failed') {
            _showStatusNotification(
              'Connection Failed',
              data['error_message'] ??
                  'Please check your credentials and try again.',
              Theme.of(context).colorScheme.error,
              Icons.error_rounded,
            );
          }
          break;
        case 'checking':
          newStatusMessage = 'Checking connection status...';
          _pulseController.repeat(reverse: true);
          break;
        default:
          newStatusMessage = 'Enter credentials to connect.';
          _pulseController.stop();
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

        print(
            '📊 [FyersConnectPage] Real-time update applied - Status: $newStatus');
      }
    } else {
      // No data exists, reset to disconnected state
      if (_status != 'disconnected') {
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Enter credentials to connect.';
          _lastUpdated = null;
        });
        _pulseController.stop();
        print(
            '📭 [FyersConnectPage] Real-time update: Data removed, status reset');
      }
    }
  }

  // ✨ Show status notification to user
  void _showStatusNotification(
      String title, String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadConnectionDetails() async {
    if (_suid == null) {
      print(
          '❌ [FyersConnectPage] Cannot load connection details: SUID is null');
      setState(() {
        _status = 'disconnected';
        _statusMessage = 'Please sign in to connect your broker account.';
      });
      return;
    }

    print('📥 [FyersConnectPage] Loading connection details from Firebase...');
    setState(() {
      _status = 'checking';
      _statusMessage = 'Checking for existing connection...';
    });
    _pulseController.repeat(reverse: true);

    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        print('📊 [FyersConnectPage] Connection details found in Firebase');
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        _usernameController.text = data['user_id'] ?? '';
        _passwordController.text = data['password'] ?? '';
        _apiKeyController.text = data['api_key'] ?? '';
        _apiSecretController.text = data['api_secret'] ?? '';
        _totpKeyController.text = data['totp_key'] ?? '';

        final lastUpdatedMillis = data['updated_at'];
        if (lastUpdatedMillis is int) {
          _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
        }

        final currentStatus = data['status'] ?? 'disconnected';

        setState(() {
          _status = currentStatus;
          if (currentStatus == 'authenticated') {
            _statusMessage = 'You are connected to Fyers and ready to trade!';
            _pulseController.stop();
          } else if (currentStatus == 'pending') {
            _statusMessage =
                'Credentials saved. Server verification in progress...';
            _pulseController.repeat(reverse: true);
          } else if (currentStatus == 'credentials_saved') {
            _statusMessage = 'Connection details saved. Ready to connect.';
            _pulseController.stop();
          } else if (currentStatus == 'connection_failed') {
            _statusMessage =
                'Connection failed: ${data['error_message'] ?? 'Please check credentials and try again.'}';
            _pulseController.stop();
          } else {
            _statusMessage = 'Enter credentials to connect.';
            _pulseController.stop();
          }
        });
      } else {
        print('📭 [FyersConnectPage] No connection details found in Firebase');
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Enter credentials to connect.';
        });
        _pulseController.stop();
      }
    } catch (e) {
      print('❌ [FyersConnectPage] Error loading connection details: $e');
      setState(() {
        _status = 'error';
        _statusMessage = 'Failed to load details: ${e.toString()}';
      });
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    print('🧹 [FyersConnectPage] Disposing resources...');

    // ✨ Cancel real-time listener
    _realtimeListener?.cancel();
    _realtimeListener = null;

    _animationController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _totpKeyController.dispose();
    super.dispose();
  }

  // Method to save credentials
  Future<void> _saveAndConnectCredentials() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [FyersConnectPage] Form validation failed');
      return;
    }

    print('🔄 [FyersConnectPage] Starting credential save process...');
    setState(() {
      _isLoading = true;
      _status = 'pending';
      _statusMessage = 'Saving credentials and sending for verification...';
    });
    _pulseController.repeat(reverse: true);

    try {
      final username = _usernameController.text;
      final password = _passwordController.text;
      final apiKey = _apiKeyController.text;
      final apiSecret = _apiSecretController.text;
      final totpKey = _totpKeyController.text;

      final payload = {
        'user_id': username,
        'password': password,
        'api_key': apiKey,
        'api_secret': apiSecret,
        'totp_key': totpKey,
        'updated_at': ServerValue.timestamp,
        'status': 'pending',
        'connection_complete': false,
        'verification_requested': true,
      };

      await _dbRef.set(payload);
      print('✅ [FyersConnectPage] Credentials saved successfully to Firebase');

      // Note: State will be updated automatically by real-time listener
      print('🎉 [FyersConnectPage] Save process completed successfully!');
    } catch (e) {
      print('❌ [FyersConnectPage] Save failed: $e');

      try {
        await _dbRef.update({
          'status': 'connection_failed',
          'connection_complete': false,
          'error_message': e.toString(),
          'updated_at': ServerValue.timestamp,
        });
        print('💾 [FyersConnectPage] Firebase updated with error status');
      } catch (dbError) {
        print(
            '❌ [FyersConnectPage] Failed to update Firebase with error: $dbError');
      }

      // Manual state update for immediate error feedback
      setState(() {
        _status = 'error';
        _statusMessage = 'Saving failed: ${e.toString()}';
      });
      _pulseController.stop();
    } finally {
      setState(() => _isLoading = false);
      print('🔄 [FyersConnectPage] Save process finished');
    }
  }

  Future<void> _disconnectAccount() async {
    print('🔌 [FyersConnectPage] Disconnect account requested');

    print('🗑️ [FyersConnectPage] User confirmed disconnect, removing data...');
    await _dbRef.remove();
    _formKey.currentState?.reset();
    _usernameController.clear();
    _passwordController.clear();
    _apiKeyController.clear();
    _apiSecretController.clear();
    _totpKeyController.clear();

    // Note: State will be updated automatically by real-time listener when data is removed
    print('✅ [FyersConnectPage] Account disconnected successfully');
  }

  void _launchYouTube() async {
    print('🎥 [FyersConnectPage] Launching YouTube guide...');
    final url = Uri.parse('https://www.youtube.com/watch?v=z7swHkB3Pa0');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      print('✅ [FyersConnectPage] YouTube guide launched successfully');
    } else {
      print('❌ [FyersConnectPage] Failed to launch YouTube guide');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch video guide.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isAuthChecking) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Connect to Fyers'),
              const SizedBox(width: 8),
              // ✨ Real-time indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _realtimeListener != null ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadConnectionDetails,
              tooltip: 'Refresh Status',
              style: IconButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_suid == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.no_accounts_rounded,
                    size: 64,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Authentication Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to connect your broker account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Connect to Fyers'),
            const SizedBox(width: 8),
            // ✨ Real-time indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _realtimeListener != null ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadConnectionDetails,
            tooltip: 'Refresh Status',
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(theme, isDark),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _usernameController,
                  label: 'User ID',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'User ID is required' : null,
                  theme: theme,
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                  theme: theme,
                ),
                _buildTextField(
                  controller: _apiKeyController,
                  label: 'API Key',
                  icon: Icons.vpn_key_rounded,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'API Key is required' : null,
                  theme: theme,
                ),
                _buildTextField(
                  controller: _apiSecretController,
                  label: 'API Secret',
                  icon: Icons.key_rounded,
                  obscureText: _obscureApiSecret,
                  onToggle: () =>
                      setState(() => _obscureApiSecret = !_obscureApiSecret),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'API Secret is required'
                      : null,
                  theme: theme,
                ),
                _buildTextField(
                  controller: _totpKeyController,
                  label: 'TOTP Key (from Authenticator App)',
                  icon: Icons.security_rounded,
                  obscureText: _obscureTotpKey,
                  onToggle: () =>
                      setState(() => _obscureTotpKey = !_obscureTotpKey),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'TOTP Key is required' : null,
                  theme: theme,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _isLoading ? null : _saveAndConnectCredentials,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label:
                            Text(_isLoading ? 'Saving...' : 'Save & Connect'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_rounded,
                                        color: theme.colorScheme.error,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Confirm Disconnect'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('This will permanently:'),
                                      const SizedBox(height: 8),
                                      Text(
                                        '• Delete all stored credentials\n'
                                        '• Disconnect your Fyers account\n'
                                        '• Stop all trading activities',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              theme.colorScheme.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: theme
                                                  .colorScheme.onErrorContainer,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'This action cannot be undone.',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onErrorContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      icon: const Icon(
                                          Icons.delete_forever_rounded),
                                      label: const Text('Delete All'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.error,
                                        foregroundColor:
                                            theme.colorScheme.onError,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _disconnectAccount();
                              }
                            },
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final statusConfig = {
      'authenticated': {
        'color': theme.colorScheme.primary,
        'icon': Icons.check_circle_rounded,
        'containerColor': theme.colorScheme.primaryContainer,
        'onContainerColor': theme.colorScheme.onPrimaryContainer,
      },
      'error': {
        'color': theme.colorScheme.error,
        'icon': Icons.error_rounded,
        'containerColor': theme.colorScheme.errorContainer,
        'onContainerColor': theme.colorScheme.onErrorContainer,
      },
      'connection_failed': {
        'color': theme.colorScheme.tertiary,
        'icon': Icons.warning_rounded,
        'containerColor': theme.colorScheme.tertiaryContainer,
        'onContainerColor': theme.colorScheme.onTertiaryContainer,
      },
      'credentials_saved': {
        'color': theme.colorScheme.secondary,
        'icon': Icons.save_rounded,
        'containerColor': theme.colorScheme.secondaryContainer,
        'onContainerColor': theme.colorScheme.onSecondaryContainer,
      },
      'pending': {
        'color': theme.colorScheme.tertiary,
        'icon': Icons.pending_rounded,
        'containerColor': theme.colorScheme.tertiaryContainer,
        'onContainerColor': theme.colorScheme.onTertiaryContainer,
      },
      'checking': {
        'color': theme.colorScheme.secondary,
        'icon': Icons.sync_rounded,
        'containerColor': theme.colorScheme.secondaryContainer,
        'onContainerColor': theme.colorScheme.onSecondaryContainer,
      },
      'disconnected': {
        'color': theme.colorScheme.outline,
        'icon': Icons.info_rounded,
        'containerColor': theme.colorScheme.surfaceVariant,
        'onContainerColor': theme.colorScheme.onSurfaceVariant,
      },
    };

    final config = statusConfig[_status] ?? statusConfig['disconnected']!;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (_status == 'checking' || _status == 'pending')
              ? _pulseAnimation.value
              : 1.0,
          child: Card(
            elevation: isDark ? 2 : 1,
            color: config['containerColor'] as Color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: config['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      config['icon'] as IconData,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status.toUpperCase().replaceAll('_', ' '),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: config['onContainerColor'] as Color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: (config['onContainerColor'] as Color)
                                .withOpacity(0.8),
                          ),
                        ),
                        if (_lastUpdated != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last Updated: ${DateFormat.yMMMd().add_jm().format(_lastUpdated!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: (config['onContainerColor'] as Color)
                                  .withOpacity(0.6),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool obscureText = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSecurityNote(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Verification Process',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '• Your credentials are securely stored in Firebase and sent to our verification server\n'
              '• Server verification may take a few minutes to complete\n'
              '• Once verified, you can start trading immediately\n'
              '• You can delete your stored data at any time using the "Delete All" button',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Follow this video guide to get your API credentials from the Fyers Developer portal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _launchYouTube,
                icon: const Icon(Icons.play_circle_rounded),
                label: const Text('Watch Setup Guide'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  showContactOptions(context);
                },
                icon: const Icon(Icons.email),
                label: const Text('Customer Support'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
