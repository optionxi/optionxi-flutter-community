import 'dart:convert';
import 'package:crypto/crypto.dart' as encrypt;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:otp/otp.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Secure Encryption Service ---
// This service now generates and stores its encryption key securely on the device.
class EncryptionService {
  final _secureStorage = const FlutterSecureStorage();
  static const _keyStorageIdentifier = 'zerodha_encryption_key';

  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;

  // Initialize the service by loading or creating a secure key.
  Future<void> initialize() async {
    print('🔐 [EncryptionService] Initializing encryption service...');
    String? b64Key = await _secureStorage.read(key: _keyStorageIdentifier);
    encrypt.Key key;

    if (b64Key == null) {
      print(
          '🔐 [EncryptionService] No existing key found, generating new one...');
      // If no key exists, generate a new one and save it securely.
      key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _keyStorageIdentifier,
        value: key.base64,
      );
      print('🔐 [EncryptionService] New key generated and saved securely');
    } else {
      print('🔐 [EncryptionService] Loading existing key from secure storage');
      // If a key exists, load it.
      key = encrypt.Key.fromBase64(b64Key);
    }

    _iv =
        encrypt.IV.fromSecureRandom(16); // IV can be securely random each time
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    print('🔐 [EncryptionService] Encryption service initialized successfully');
  }

  // Encrypts text after ensuring the service is initialized.
  String? encryptText(String? text) {
    if (text == null || text.isEmpty || _encrypter == null || _iv == null) {
      print(
          '🔐 [EncryptionService] Cannot encrypt: text is null/empty or service not initialized');
      return null;
    }
    // Prepend IV for decryption. This is a common practice.
    final encrypted = _encrypter!.encrypt(text, iv: _iv!);
    print('🔐 [EncryptionService] Text encrypted successfully');
    return "${_iv!.base64}:${encrypted.base64}";
  }

  // Decrypts text after ensuring the service is initialized.
  String? decryptText(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty || _encrypter == null) {
      print(
          '🔐 [EncryptionService] Cannot decrypt: encrypted text is null/empty or service not initialized');
      return null;
    }
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) throw Exception("Invalid encrypted format.");

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedContent = encrypt.Encrypted.fromBase64(parts[1]);

      final decrypted = _encrypter!.decrypt(encryptedContent, iv: iv);
      print('🔐 [EncryptionService] Text decrypted successfully');
      return decrypted;
    } catch (e) {
      print(
          '🔐 [EncryptionService] Decryption Error: $e. The data might be corrupt or the key might have changed.');
      return null;
    }
  }
}

// --- Main Widget ---
class ZerodhaConnectPageEncrypt extends StatefulWidget {
  const ZerodhaConnectPageEncrypt({Key? key}) : super(key: key);

  @override
  State<ZerodhaConnectPageEncrypt> createState() =>
      _ZerodhaConnectPageEncryptState();
}

class _ZerodhaConnectPageEncryptState extends State<ZerodhaConnectPageEncrypt>
    with TickerProviderStateMixin {
  // Form and controller declarations remain the same...
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _totpKeyController = TextEditingController();

  // State variables remain the same...
  String _status = 'checking';
  String _statusMessage = 'Initializing...';
  DateTime? _lastUpdated;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureApiSecret = true;
  bool _obscureTotpKey = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _suid;
  bool _isAuthChecking = true;
  late DatabaseReference _dbRef;

  // Instance of our secure encryption service
  final EncryptionService _encryptionService = EncryptionService();

  @override
  void initState() {
    super.initState();
    print('🚀 [ZerodhaConnectPage] Initializing page...');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializePage();
  }

  // New initialization flow
  Future<void> _initializePage() async {
    print('🔧 [ZerodhaConnectPage] Starting page initialization...');

    // 1. Initialize the encryption service first
    await _encryptionService.initialize();

    // 2. Authenticate the user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('👤 [ZerodhaConnectPage] User authenticated: ${user.uid}');
      _suid = user.uid;
      _dbRef = FirebaseDatabase.instance.ref().child('brokers/zerodha/$_suid');
      // 3. Load connection details using the initialized service
      await _loadConnectionDetails();
    } else {
      print('❌ [ZerodhaConnectPage] No authenticated user found');
    }

    setState(() => _isAuthChecking = false);
    _animationController.forward();
    print('✅ [ZerodhaConnectPage] Page initialization complete');
  }

  Future<void> _loadConnectionDetails() async {
    if (_suid == null) {
      print(
          '❌ [ZerodhaConnectPage] Cannot load connection details: SUID is null');
      return;
    }

    print(
        '📥 [ZerodhaConnectPage] Loading connection details from Firebase...');
    setState(() {
      _status = 'checking';
      _statusMessage = 'Checking for existing connection...';
    });

    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        print('📊 [ZerodhaConnectPage] Connection details found in Firebase');
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Use the service instance to decrypt data
        _usernameController.text =
            _encryptionService.decryptText(data['user_id_encrypted']) ?? '';
        _passwordController.text =
            _encryptionService.decryptText(data['password_encrypted']) ?? '';
        _apiKeyController.text =
            _encryptionService.decryptText(data['api_key_encrypted']) ?? '';
        _apiSecretController.text =
            _encryptionService.decryptText(data['api_secret_encrypted']) ?? '';
        _totpKeyController.text =
            _encryptionService.decryptText(data['totp_key_encrypted']) ?? '';

        final lastUpdatedMillis = data['updated_at'];
        if (lastUpdatedMillis is int) {
          _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
        }

        // Check if connection is complete
        final isConnectionComplete = data['connection_complete'] == true;
        print(
            '🔍 [ZerodhaConnectPage] Connection complete status: $isConnectionComplete');

        setState(() {
          _status = data['status'] ?? 'disconnected';
          _statusMessage = isConnectionComplete && data['access_token'] != null
              ? 'You are connected to Zerodha.'
              : 'Connection details found. Click Connect to complete setup.';
        });
      } else {
        print(
            '📭 [ZerodhaConnectPage] No connection details found in Firebase');
        setState(() {
          _status = 'disconnected';
          _statusMessage = 'Enter credentials to connect.';
        });
      }
    } catch (e) {
      print('❌ [ZerodhaConnectPage] Error loading connection details: $e');
      setState(() {
        _status = 'error';
        _statusMessage = 'Failed to load details: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    print('🧹 [ZerodhaConnectPage] Disposing resources...');
    // Dispose controllers as before
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _totpKeyController.dispose();
    super.dispose();
  }

  // New method to save credentials before connecting
  Future<void> _saveCredentialsToFirebase() async {
    print('💾 [ZerodhaConnectPage] Saving credentials to Firebase...');

    final username = _usernameController.text;
    final password = _passwordController.text;
    final apiKey = _apiKeyController.text;
    final apiSecret = _apiSecretController.text;
    final totpKey = _totpKeyController.text;

    final credentialsPayload = {
      'user_id_encrypted': _encryptionService.encryptText(username),
      'password_encrypted': _encryptionService.encryptText(password),
      'api_key_encrypted': _encryptionService.encryptText(apiKey),
      'api_secret_encrypted': _encryptionService.encryptText(apiSecret),
      'totp_key_encrypted': _encryptionService.encryptText(totpKey),
      'updated_at': ServerValue.timestamp,
      'status': 'credentials_saved',
      'connection_complete': false,
    };

    await _dbRef.set(credentialsPayload);
    print('✅ [ZerodhaConnectPage] Credentials saved successfully to Firebase');
  }

  Future<void> _updateCredentials() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [ZerodhaConnectPage] Form validation failed');
      return;
    }

    print('🔄 [ZerodhaConnectPage] Starting credential update process...');
    setState(() {
      _isLoading = true;
      _status = 'pending';
      _statusMessage = 'Saving credentials and connecting to Zerodha...';
    });

    // Use a single http.Client instance for the entire session
    final session = http.Client();

    try {
      final username = _usernameController.text;
      final password = _passwordController.text;
      final apiKey = _apiKeyController.text;
      final apiSecret = _apiSecretController.text;
      final totpKey = _totpKeyController.text;

      print('📝 [ZerodhaConnectPage] Form data collected:');
      print('  - Username: ${username.isNotEmpty ? "✓" : "✗"}');
      print('  - Password: ${password.isNotEmpty ? "✓" : "✗"}');
      print('  - API Key: ${apiKey.isNotEmpty ? "✓" : "✗"}');
      print('  - API Secret: ${apiSecret.isNotEmpty ? "✓" : "✗"}');
      print('  - TOTP Key: ${totpKey.isNotEmpty ? "✓" : "✗"}');

      // Save credentials to Firebase BEFORE attempting connection
      await _saveCredentialsToFirebase();

      setState(() {
        _statusMessage = 'Credentials saved. Connecting to Zerodha...';
      });

      // Now attempt the Zerodha connection
      print('🔌 [ZerodhaConnectPage] Starting Zerodha connection process...');

      // Step 1: Login
      print('🔐 [ZerodhaConnectPage] Step 1: Attempting login...');
      final loginResponse = await session.post(
        Uri.parse("https://kite.zerodha.com/api/login"),
        headers: {'X-Kite-Version': '3'},
        body: {"user_id": username, "password": password},
      );

      print(
          '🔐 [ZerodhaConnectPage] Login response status: ${loginResponse.statusCode}');
      print(
          '🔐 [ZerodhaConnectPage] Login response body: ${loginResponse.body}');

      if (loginResponse.statusCode != 200) {
        throw Exception('Login failed. Please check your User ID or Password.');
      }

      final loginData = jsonDecode(loginResponse.body);
      final requestId = loginData["data"]["request_id"];
      print('🔐 [ZerodhaConnectPage] Login successful, request ID: $requestId');

      // Step 2: 2FA
      print(
          '🔐 [ZerodhaConnectPage] Step 2: Generating TOTP and submitting 2FA...');
      final twofaValue = OTP.generateTOTPCodeString(
          totpKey, DateTime.now().millisecondsSinceEpoch,
          algorithm: Algorithm.SHA1, isGoogle: true);

      print('🔐 [ZerodhaConnectPage] Generated TOTP: $twofaValue');

      final twofaResponse = await session.post(
        Uri.parse("https://kite.zerodha.com/api/twofa"),
        headers: {
          'X-Kite-Version': '3',
          "User-Agent":
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        },
        body: {
          "user_id": username,
          "request_id": requestId,
          "twofa_value": twofaValue
        },
      );

      print(
          '🔐 [ZerodhaConnectPage] 2FA response status: ${twofaResponse.statusCode}');
      print('🔐 [ZerodhaConnectPage] 2FA response body: ${twofaResponse.body}');

      // Step 3: Get API session
      print('🔐 [ZerodhaConnectPage] Step 3: Getting API session...');
      final apiSessionResponse = await session.get(
        Uri.parse("https://kite.trade/connect/login?v=3&api_key=$apiKey"),
        headers: {
          'X-Kite-Version': '3',
          "User-Agent":
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        },
      );

      print(
          '🔐 [ZerodhaConnectPage] API session response status: ${apiSessionResponse.statusCode}');
      print(
          '🔐 [ZerodhaConnectPage] API session response URL: ${apiSessionResponse.request?.url}');

      final requestToken = Uri.parse(apiSessionResponse.request!.url.toString())
          .queryParameters['request_token'];

      print('🔐 [ZerodhaConnectPage] Request token: $requestToken');

      if (requestToken == null) {
        throw Exception(
            'Failed to get request token. Check API key permissions.');
      }

      // Step 4: Generate access token
      print('🔐 [ZerodhaConnectPage] Step 4: Generating access token...');
      final checksum = encrypt.sha256
          .convert(utf8.encode(apiKey + requestToken + apiSecret))
          .toString();

      print(
          '🔐 [ZerodhaConnectPage] Checksum generated: ${checksum.substring(0, 10)}...');

      // *** Use the SAME session client here ***
      final accessTokenResponse = await session.post(
        Uri.parse("https://api.kite.trade/session/token"),
        headers: {'X-Kite-Version': '3'},
        body: {
          "api_key": apiKey,
          "request_token": requestToken,
          "checksum": checksum
        },
      );

      print(
          '🔐 [ZerodhaConnectPage] Access token response status: ${accessTokenResponse.statusCode}');
      print(
          '🔐 [ZerodhaConnectPage] Access token response body: ${accessTokenResponse.body}');

      if (accessTokenResponse.statusCode != 200) {
        throw Exception(
            'Failed to generate access token. Check API key/secret.');
      }

      final accessTokenData = jsonDecode(accessTokenResponse.body);
      final accessToken = accessTokenData["data"]["access_token"];
      print(
          '🔐 [ZerodhaConnectPage] Access token generated successfully: ${accessToken.substring(0, 10)}...');

      // Step 5: Update Firebase with complete connection
      print(
          '💾 [ZerodhaConnectPage] Step 5: Updating Firebase with complete connection...');
      final completeDatabasePayload = {
        'user_id_encrypted': _encryptionService.encryptText(username),
        'password_encrypted': _encryptionService.encryptText(password),
        'api_key_encrypted': _encryptionService.encryptText(apiKey),
        'api_secret_encrypted': _encryptionService.encryptText(apiSecret),
        'totp_key_encrypted': _encryptionService.encryptText(totpKey),
        'access_token': accessToken,
        'updated_at': ServerValue.timestamp,
        'status': 'authenticated',
        'connection_complete': true,
      };

      await _dbRef.set(completeDatabasePayload);
      print('✅ [ZerodhaConnectPage] Firebase updated with complete connection');

      setState(() {
        _status = 'authenticated';
        _statusMessage = 'Successfully connected to Zerodha!';
        _lastUpdated = DateTime.now();
      });

      print(
          '🎉 [ZerodhaConnectPage] Connection process completed successfully!');
    } catch (e) {
      print('❌ [ZerodhaConnectPage] Connection failed: $e');

      // Update Firebase to show connection failed but keep credentials
      try {
        await _dbRef.update({
          'status': 'connection_failed',
          'connection_complete': false,
          'error_message': e.toString(),
          'updated_at': ServerValue.timestamp,
        });
        print('💾 [ZerodhaConnectPage] Firebase updated with error status');
      } catch (dbError) {
        print(
            '❌ [ZerodhaConnectPage] Failed to update Firebase with error: $dbError');
      }

      setState(() {
        _status = 'error';
        _statusMessage = 'Connection failed: ${e.toString()}';
      });
    } finally {
      // Always close the client when you're done with it.
      session.close();
      setState(() => _isLoading = false);
      print('🔄 [ZerodhaConnectPage] Connection process finished');
    }
  }

  // --- UI and helper methods from previous response ---
  Future<void> _disconnectAccount() async {
    print('🔌 [ZerodhaConnectPage] Disconnect account requested');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disconnect'),
        content: const Text(
            'Are you sure you want to disconnect and delete all stored credentials? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      print(
          '🗑️ [ZerodhaConnectPage] User confirmed disconnect, removing data...');
      await _dbRef.remove();
      _formKey.currentState?.reset();
      _usernameController.clear();
      _passwordController.clear();
      _apiKeyController.clear();
      _apiSecretController.clear();
      _totpKeyController.clear();
      setState(() {
        _status = 'disconnected';
        _statusMessage = 'Account disconnected and credentials deleted.';
        _lastUpdated = null;
      });
      print('✅ [ZerodhaConnectPage] Account disconnected successfully');
    } else {
      print('❌ [ZerodhaConnectPage] User cancelled disconnect');
    }
  }

  void _launchYouTube() async {
    print('🎥 [ZerodhaConnectPage] Launching YouTube guide...');
    final url = Uri.parse('http://www.youtube.com/watch?v=dA6IgCdg6tE');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      print('✅ [ZerodhaConnectPage] YouTube guide launched successfully');
    } else {
      print('❌ [ZerodhaConnectPage] Failed to launch YouTube guide');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch video guide.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_suid == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_accounts,
                    size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Authentication Required',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Please sign in to connect your broker account.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Zerodha'),
        actions: [
          if (_status != 'disconnected')
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnectAccount,
              tooltip: 'Disconnect Account',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConnectionDetails,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: 'User ID',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'User ID is required' : null,
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                _buildTextField(
                  controller: _apiKeyController,
                  label: 'API Key',
                  icon: Icons.vpn_key_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'API Key is required' : null,
                ),
                _buildTextField(
                  controller: _apiSecretController,
                  label: 'API Secret',
                  icon: Icons.key_outlined,
                  obscureText: _obscureApiSecret,
                  onToggle: () =>
                      setState(() => _obscureApiSecret = !_obscureApiSecret),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'API Secret is required'
                      : null,
                ),
                _buildTextField(
                  controller: _totpKeyController,
                  label: 'TOTP Key (from Authenticator App)',
                  icon: Icons.security_outlined,
                  obscureText: _obscureTotpKey,
                  onToggle: () =>
                      setState(() => _obscureTotpKey = !_obscureTotpKey),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'TOTP Key is required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateCredentials,
                    icon: _isLoading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? 'Connecting...' : 'Save & Connect',
                        style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSecurityNote(),
                const SizedBox(height: 16),
                _buildHelpSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusConfig = {
      'authenticated': {
        'color': Colors.green,
        'icon': Icons.check_circle_outline
      },
      'error': {'color': Colors.red, 'icon': Icons.error_outline},
      'connection_failed': {
        'color': Colors.orange,
        'icon': Icons.warning_outlined
      },
      'credentials_saved': {'color': Colors.blue, 'icon': Icons.save_outlined},
      'pending': {'color': Colors.orange, 'icon': Icons.pending_outlined},
      'checking': {'color': Colors.blue, 'icon': Icons.sync},
      'disconnected': {'color': Colors.grey, 'icon': Icons.info_outline},
    };

    final config = statusConfig[_status] ?? statusConfig['disconnected']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_statusMessage,
                      style: TextStyle(color: color.withOpacity(0.9))),
                  if (_lastUpdated != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last Updated: ${DateFormat.yMMMd().add_jm().format(_lastUpdated!)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.withOpacity(0.05),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Enhanced Security',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16)),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• A unique encryption key is generated and stored securely on your device.\n'
              '• Your credentials are encrypted using this key before being saved.\n'
              '• You can disconnect and delete your data at any time.',
              style:
                  TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, size: 20),
                SizedBox(width: 8),
                Text('Need Help?',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Follow our video guide to get your API credentials from the Zerodha Developer portal.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchYouTube,
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('Watch Setup Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
}
