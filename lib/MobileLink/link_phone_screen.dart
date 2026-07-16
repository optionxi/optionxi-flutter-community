import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:optionxi/Components/cust_contact_us.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Config
// ─────────────────────────────────────────────────────────────────────────────
String get _kApiBase => dotenv.env['PHONELINK_URL']!;

// ─────────────────────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const radius = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const duration300 = Duration(milliseconds: 300);
  static const duration500 = Duration(milliseconds: 500);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Country Code model
// ─────────────────────────────────────────────────────────────────────────────
class CountryCode {
  final String name;
  final String code;
  final String flag;
  const CountryCode(
      {required this.name, required this.code, required this.flag});
}

// ─────────────────────────────────────────────────────────────────────────────
//  API service
// ─────────────────────────────────────────────────────────────────────────────
class _OtpApiService {
  static Future<String> _getFirebaseUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.uid;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<PhoneStatusResult> checkStatus() async {
    final uid = await _getFirebaseUid();
    final resp = await http
        .post(Uri.parse('$_kApiBase/otp/status'),
            headers: _headers, body: jsonEncode({'firebase_uid': uid}))
        .timeout(const Duration(seconds: 15));
    final body = _parseBody(resp);
    if (resp.statusCode != 200) _throwFromBody(body, resp.statusCode);
    return PhoneStatusResult(
      isVerified: body['is_verified'] as bool? ?? false,
      phone: body['phone'] as String?,
      verifiedAt: body['verified_at'] as String?,
    );
  }

  static Future<void> unlinkPhone() async {
    final uid = await _getFirebaseUid();
    final resp = await http
        .post(Uri.parse('$_kApiBase/otp/unlink'),
            headers: _headers, body: jsonEncode({'firebase_uid': uid}))
        .timeout(const Duration(seconds: 15));
    final body = _parseBody(resp);
    if (resp.statusCode != 200) _throwFromBody(body, resp.statusCode);
  }

  static Future<SendOtpResult> sendOtp(String phone,
      {bool isResend = false}) async {
    final uid = await _getFirebaseUid();
    final endpoint = isResend ? '/otp/resend' : '/otp/send';
    final resp = await http
        .post(Uri.parse('$_kApiBase$endpoint'),
            headers: _headers,
            body: jsonEncode({'firebase_uid': uid, 'phone': phone}))
        .timeout(const Duration(seconds: 20));
    final body = _parseBody(resp);
    if (resp.statusCode == 200 &&
        (body['already_verified'] as bool? ?? false)) {
      return SendOtpResult(
        success: false,
        alreadyVerified: true,
        message: body['message'] as String? ?? 'Already verified',
        linkedPhone: body['phone'] as String?,
      );
    }
    if (resp.statusCode != 200) _throwFromBody(body, resp.statusCode);
    return SendOtpResult(
      success: true,
      message: body['message'] as String? ?? 'OTP sent',
      resendCooldown: body['resend_cooldown_seconds'] as int? ?? 30,
      expiresInMinutes: body['expires_in_minutes'] as int? ?? 5,
    );
  }

  static Future<VerifyOtpResult> verifyOtp(String phone, String otp) async {
    final uid = await _getFirebaseUid();
    final resp = await http
        .post(Uri.parse('$_kApiBase/otp/verify'),
            headers: _headers,
            body: jsonEncode({'firebase_uid': uid, 'phone': phone, 'otp': otp}))
        .timeout(const Duration(seconds: 20));
    final body = _parseBody(resp);
    if (resp.statusCode != 200) _throwFromBody(body, resp.statusCode);
    return VerifyOtpResult(
      success: body['success'] as bool? ?? false,
      alreadyVerified: body['already_verified'] as bool? ?? false,
      message: body['message'] as String? ?? 'Verified',
      phone: body['phone'] as String?,
    );
  }

  static Map<String, dynamic> _parseBody(http.Response resp) {
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {'detail': resp.body};
    }
  }

  static void _throwFromBody(Map<String, dynamic> body, int statusCode) {
    final detail = body['detail'] as String? ??
        body['message'] as String? ??
        'Something went wrong (HTTP $statusCode)';
    throw ApiException(detail, statusCode);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Result models
// ─────────────────────────────────────────────────────────────────────────────
class PhoneStatusResult {
  final bool isVerified;
  final String? phone;
  final String? verifiedAt;
  const PhoneStatusResult(
      {required this.isVerified, this.phone, this.verifiedAt});
}

class SendOtpResult {
  final bool success;
  final bool alreadyVerified;
  final String message;
  final String? linkedPhone;
  final int resendCooldown;
  final int expiresInMinutes;
  const SendOtpResult({
    required this.success,
    this.alreadyVerified = false,
    required this.message,
    this.linkedPhone,
    this.resendCooldown = 30,
    this.expiresInMinutes = 5,
  });
}

class VerifyOtpResult {
  final bool success;
  final bool alreadyVerified;
  final String message;
  final String? phone;
  const VerifyOtpResult(
      {required this.success,
      this.alreadyVerified = false,
      required this.message,
      this.phone});
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen states
// ─────────────────────────────────────────────────────────────────────────────
enum _ScreenState {
  checkingStatus,
  alreadyVerified,
  enterPhone,
  enterOtp,
  verifiedSuccess, // NEW: shown after successful OTP verification
  serviceDown
}

// ─────────────────────────────────────────────────────────────────────────────
//  LinkPhoneScreen
// ─────────────────────────────────────────────────────────────────────────────
class LinkPhoneScreen extends StatefulWidget {
  const LinkPhoneScreen({Key? key}) : super(key: key);

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  _ScreenState _screenState = _ScreenState.checkingStatus;
  bool _isLoading = false;
  bool _isObscured = true;
  int _remainingTime = 0;
  Timer? _timer;

  String? _linkedPhone;
  String? _verifiedAt;
  String? _justVerifiedPhone; // phone shown on success screen

  static const _countryCodes = <CountryCode>[
    CountryCode(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryCode(name: 'United States', code: '+1', flag: '🇺🇸'),
    CountryCode(name: 'Canada', code: '+1', flag: '🇨🇦'),
    CountryCode(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Germany', code: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Japan', code: '+81', flag: '🇯🇵'),
    CountryCode(name: 'Brazil', code: '+55', flag: '🇧🇷'),
    CountryCode(name: 'China', code: '+86', flag: '🇨🇳'),
    CountryCode(name: 'Singapore', code: '+65', flag: '🇸🇬'),
    CountryCode(name: 'UAE', code: '+971', flag: '🇦🇪'),
  ];

  CountryCode _selectedCountry = _countryCodes.first;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkExistingVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  bool _isConnectionError(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('timeout');
  }

  void _transitionTo(_ScreenState next) {
    setState(() => _screenState = next);
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Built-in snackbars ────────────────────────────────────────────────────

  void _showSuccess(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: _SnackBarContent(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF22C55E),
          title: title,
          message: message,
          isError: false,
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: _SnackBarContent(
          icon: Icons.error_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'Error',
          message: msg,
          isError: true,
        ),
      ),
    );
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _checkExistingVerification() async {
    try {
      final status = await _OtpApiService.checkStatus();
      if (!mounted) return;
      if (status.isVerified) {
        setState(() {
          _linkedPhone = status.phone;
          _verifiedAt = status.verifiedAt;
        });
        _transitionTo(_ScreenState.alreadyVerified);
      } else {
        _transitionTo(_ScreenState.enterPhone);
      }
    } catch (e) {
      if (!mounted) return;
      if (_isConnectionError(e)) {
        _transitionTo(_ScreenState.serviceDown);
      } else {
        _transitionTo(_ScreenState.enterPhone);
        _showError('Could not check verification status.');
      }
    }
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }
    final fullPhone = '${_selectedCountry.code}$phone';
    setState(() => _isLoading = true);
    try {
      final result =
          await _OtpApiService.sendOtp(fullPhone, isResend: isResend);
      if (!mounted) return;
      if (result.alreadyVerified) {
        setState(() => _linkedPhone = result.linkedPhone);
        _transitionTo(_ScreenState.alreadyVerified);
        return;
      }
      _startResendTimer(result.resendCooldown);
      _transitionTo(_ScreenState.enterOtp);
      _showSuccess(
        'OTP Sent',
        'Check WhatsApp on ${_selectedCountry.code}$phone. '
            'Expires in ${result.expiresInMinutes} min.',
      );
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      if (_isConnectionError(e)) {
        _transitionTo(_ScreenState.serviceDown);
      } else {
        _showError('Network error. Please check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _showError('Enter the full 6-digit OTP');
      return;
    }
    final fullPhone = '${_selectedCountry.code}${_phoneCtrl.text.trim()}';
    setState(() => _isLoading = true);
    try {
      final result = await _OtpApiService.verifyOtp(fullPhone, otp);
      if (!mounted) return;
      // Instead of popping, show the in-screen success state
      setState(() {
        _justVerifiedPhone = result.phone ?? fullPhone;
      });
      _transitionTo(_ScreenState.verifiedSuccess);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      if (_isConnectionError(e)) {
        _transitionTo(_ScreenState.serviceDown);
      } else {
        _showError('Verification failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkPhone({required bool changeNumber}) async {
    setState(() => _isLoading = true);
    try {
      await _OtpApiService.unlinkPhone();
      if (!mounted) return;
      setState(() {
        _linkedPhone = null;
        _verifiedAt = null;
        _phoneCtrl.clear();
        _otpCtrl.clear();
      });
      if (changeNumber) {
        _transitionTo(_ScreenState.enterPhone);
        _showSuccess('Unlinked', 'Please enter your new number.');
      } else {
        _showSuccess('Deleted', 'Phone number removed successfully.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to unlink number. $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnlinkConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(
        onConfirm: () {
          Navigator.pop(ctx);
          _unlinkPhone(changeNumber: false);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _remainingTime = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingTime <= 1) {
        t.cancel();
        setState(() => _remainingTime = 0);
      } else {
        setState(() => _remainingTime--);
      }
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        countries: _countryCodes,
        selected: _selectedCountry,
        onSelected: (c) => setState(() => _selectedCountry = c),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Link Phone Number',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_left_rounded,
                color: theme.colorScheme.onSurface, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_screenState),
            child: _buildBody(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    switch (_screenState) {
      case _ScreenState.checkingStatus:
        return _CheckingStatusView(theme: theme);
      case _ScreenState.serviceDown:
        return _ServiceDownView(
          theme: theme,
          onContactSupport: () => showContactOptions(context),
          onRetry: () {
            _transitionTo(_ScreenState.checkingStatus);
            _checkExistingVerification();
          },
        );
      case _ScreenState.alreadyVerified:
        return _AlreadyVerifiedView(
          theme: theme,
          linkedPhone: _linkedPhone,
          verifiedAt: _verifiedAt,
          isLoading: _isLoading,
          onChangeNumber: () => _unlinkPhone(changeNumber: true),
          onDeleteNumber: _showUnlinkConfirmation,
          onGoBack: () => Navigator.pop(context),
        );
      case _ScreenState.enterPhone:
        return _EnterPhoneView(
          theme: theme,
          isDark: isDark,
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          selectedCountry: _selectedCountry,
          isLoading: _isLoading,
          onPickCountry: _showCountryPicker,
          onChanged: (_) => setState(() {}),
          onSendOtp: _sendOtp,
        );
      case _ScreenState.enterOtp:
        return _EnterOtpView(
          theme: theme,
          isDark: isDark,
          otpController: _otpCtrl,
          otpFocus: _otpFocus,
          selectedCountry: _selectedCountry,
          phoneNumber: _phoneCtrl.text.trim(),
          isLoading: _isLoading,
          isObscured: _isObscured,
          remainingTime: _remainingTime,
          onToggleObscure: () => setState(() => _isObscured = !_isObscured),
          onChangeNumber: () {
            _timer?.cancel();
            _otpCtrl.clear();
            _transitionTo(_ScreenState.enterPhone);
          },
          onResendOtp: () => _sendOtp(isResend: true),
          onVerifyOtp: _verifyOtp,
        );
      case _ScreenState.verifiedSuccess:
        return _VerifiedSuccessView(
          theme: theme,
          phone: _justVerifiedPhone,
          onDone: () => Navigator.pop(context, true),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Built-in Snack Bar Content Widget
// ─────────────────────────────────────────────────────────────────────────────
class _SnackBarContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final bool isError;

  const _SnackBarContent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isError
        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
        : const Color(0xFF22C55E).withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Verified Success View  — NEW: shown after OTP verification
// ─────────────────────────────────────────────────────────────────────────────
class _VerifiedSuccessView extends StatefulWidget {
  final ThemeData theme;
  final String? phone;
  final VoidCallback onDone;

  const _VerifiedSuccessView({
    required this.theme,
    required this.phone,
    required this.onDone,
  });

  @override
  State<_VerifiedSuccessView> createState() => _VerifiedSuccessViewState();
}

class _VerifiedSuccessViewState extends State<_VerifiedSuccessView>
    with TickerProviderStateMixin {
  late AnimationController _circleCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _rippleCtrl;

  late Animation<double> _circleScale;
  late Animation<double> _checkDraw;
  late Animation<double> _contentFade;
  late Animation<double> _contentSlide;
  late Animation<double> _ripple;

  @override
  void initState() {
    super.initState();

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ripple = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);

    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _circleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut));

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkDraw = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<double>(begin: 24, end: 0)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    // Sequence the animations
    _circleCtrl.forward().then((_) {
      _checkCtrl.forward().then((_) {
        _contentCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF22C55E);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // ── Animated success icon ──────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_circleCtrl, _checkCtrl, _rippleCtrl]),
            builder: (_, __) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple rings
                    if (_checkDraw.value > 0) ...[
                      _RippleRing(
                        progress: _ripple.value,
                        color: green,
                        size: 160,
                        delay: 0,
                      ),
                      _RippleRing(
                        progress: _ripple.value,
                        color: green,
                        size: 160,
                        delay: 0.4,
                      ),
                    ],
                    // Main circle
                    ScaleTransition(
                      scale: _circleScale,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              green.withValues(alpha: 0.25),
                              green.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                              color: green.withValues(alpha: 0.4), width: 2),
                        ),
                      ),
                    ),
                    // Check circle
                    ScaleTransition(
                      scale: _circleScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: green,
                        ),
                        child: FadeTransition(
                          opacity: _checkDraw,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 36),

          // ── Content ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _contentCtrl,
            builder: (_, child) {
              return Opacity(
                opacity: _contentFade.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Text(
                  'Phone Verified!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your number is now linked to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),

                // Phone badge
                if (widget.phone != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(_Tokens.radiusLg),
                      border: Border.all(
                          color: green.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_android_rounded,
                              color: green, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verified Number',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.phone!,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_rounded,
                            color: green, size: 22),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Perks row
                _SuccessPerksCard(theme: widget.theme),

                const SizedBox(height: 36),

                _PrimaryButton(
                  label: 'Done',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: widget.onDone,
                  theme: widget.theme,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ripple ring widget for the success animation
class _RippleRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double delay; // 0..1 offset

  const _RippleRing({
    required this.progress,
    required this.color,
    required this.size,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final adjusted = ((progress - delay) % 1.0).clamp(0.0, 1.0);
    final opacity = (1.0 - adjusted).clamp(0.0, 0.3);
    final scale = 0.6 + adjusted * 0.8;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

// Success perks card
class _SuccessPerksCard extends StatelessWidget {
  final ThemeData theme;
  const _SuccessPerksCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.notifications_active_rounded, 'Real-time trade alerts'),
      (Icons.lock_rounded, 'Two-factor authentication'),
      (Icons.headset_mic_rounded, 'Priority support access'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlocked with your number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(item.$1, size: 15, color: const Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Already Verified View  — IMPROVED
// ─────────────────────────────────────────────────────────────────────────────
class _AlreadyVerifiedView extends StatefulWidget {
  final ThemeData theme;
  final String? linkedPhone;
  final String? verifiedAt;
  final bool isLoading;
  final VoidCallback onChangeNumber;
  final VoidCallback onDeleteNumber;
  final VoidCallback onGoBack;

  const _AlreadyVerifiedView({
    required this.theme,
    required this.linkedPhone,
    required this.verifiedAt,
    required this.isLoading,
    required this.onChangeNumber,
    required this.onDeleteNumber,
    required this.onGoBack,
  });

  @override
  State<_AlreadyVerifiedView> createState() => _AlreadyVerifiedViewState();
}

class _AlreadyVerifiedViewState extends State<_AlreadyVerifiedView>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _shieldCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _entranceFade;
  late Animation<double> _entranceSlide;
  late Animation<double> _shieldScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _shieldCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _shieldScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shieldCtrl, curve: Curves.elasticOut));

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide = Tween<double>(begin: 20, end: 0)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _shieldCtrl.forward().then((_) {
          if (mounted) _entranceCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shieldCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF22C55E);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 36),

          // ── Shield hero ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_shieldCtrl, _pulseCtrl]),
            builder: (_, __) {
              return ScaleTransition(
                scale: _shieldScale,
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 130 + 10 * _pulse.value,
                        height: 130 + 10 * _pulse.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: green.withValues(
                              alpha: 0.04 + 0.04 * _pulse.value),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: green.withValues(alpha: 0.08),
                          border: Border.all(
                              color: green.withValues(alpha: 0.2), width: 1.5),
                        ),
                      ),
                      // Inner filled
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              green.withValues(alpha: 0.9),
                              const Color(0xFF16A34A),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: green.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      // Small check badge
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: green, width: 2),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: green, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Title & subtitle ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (_, child) => Opacity(
              opacity: _entranceFade.value,
              child: Transform.translate(
                offset: Offset(0, _entranceSlide.value),
                child: child,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Number Verified',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Active & Secure',
                        style: TextStyle(
                          color: green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Phone detail card ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (_, child) => Opacity(
              opacity: _entranceFade.value,
              child: Transform.translate(
                offset: Offset(0, _entranceSlide.value * 1.2),
                child: child,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F2818) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(_Tokens.radiusLg),
                border:
                    Border.all(color: green.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.phone_android_rounded,
                            color: green, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Linked Phone',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.linkedPhone ?? '—',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.verifiedAt != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: green.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 15,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 7),
                        Text(
                          'Verified on ${_formatDate(widget.verifiedAt!)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(
                              color: green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Actions ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (_, child) => Opacity(
              opacity: _entranceFade.value,
              child: Transform.translate(
                offset: Offset(0, _entranceSlide.value * 1.4),
                child: child,
              ),
            ),
            child: widget.isLoading
                ? _LoadingIndicator(theme: theme, label: 'Processing…')
                : _AccountActionsCard(
                    theme: theme,
                    onChangeNumber: widget.onChangeNumber,
                    onDeleteNumber: widget.onDeleteNumber,
                  ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Account Actions Card (settings-style rows)
// ─────────────────────────────────────────────────────────────────────────────
class _AccountActionsCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onChangeNumber;
  final VoidCallback onDeleteNumber;

  const _AccountActionsCard({
    required this.theme,
    required this.onChangeNumber,
    required this.onDeleteNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _AccountActionRow(
            theme: theme,
            icon: Icons.edit_outlined,
            iconColor: theme.colorScheme.primary,
            label: 'Change Number',
            subtitle: 'Update your linked phone number',
            onTap: onChangeNumber,
          ),
          Divider(
            height: 1,
            indent: 66,
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
          _AccountActionRow(
            theme: theme,
            icon: Icons.delete_outline_rounded,
            iconColor: theme.colorScheme.error,
            label: 'Remove Number',
            subtitle: 'Unlink this number from your account',
            onTap: onDeleteNumber,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountActionRow({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Orbital Ring Painter
// ─────────────────────────────────────────────────────────────────────────────
class _OrbitalRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double gapFraction;

  _OrbitalRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.5,
    this.gapFraction = 0.25,
  }) : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final arcLength = (1 - gapFraction) * 2 * math.pi;
    final startAngle = progress * 2 * math.pi - math.pi / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        arcLength, false, paint);

    final dotAngle = startAngle + arcLength;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(
        Offset(dotX, dotY), strokeWidth * 0.7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OrbitalRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shimmer Painter
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;

  _ShimmerPainter({
    required this.progress,
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );
    canvas.drawRRect(rrect, Paint()..color = baseColor);

    final shimmerLeft = size.width * (progress * 2 - 0.5);
    final gradient = LinearGradient(
      colors: [
        highlightColor.withValues(alpha: 0),
        highlightColor.withValues(alpha: 0.6),
        highlightColor.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final paint = Paint()
      ..shader = gradient
          .createShader(Rect.fromLTWH(shimmerLeft - 80, 0, 160, size.height));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.progress != progress || old.baseColor != baseColor;
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double shimmerProgress;
  final bool isDark;
  final double radius;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.shimmerProgress,
    required this.isDark,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E8F0);
    final highlight =
        isDark ? const Color(0xFF3E3E55) : const Color(0xFFFFFFFF);

    return CustomPaint(
      painter: _ShimmerPainter(
        progress: shimmerProgress,
        baseColor: base,
        highlightColor: highlight,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Checking Status View
// ─────────────────────────────────────────────────────────────────────────────
class _CheckingStatusView extends StatefulWidget {
  final ThemeData theme;
  const _CheckingStatusView({required this.theme});

  @override
  State<_CheckingStatusView> createState() => _CheckingStatusViewState();
}

class _CheckingStatusViewState extends State<_CheckingStatusView>
    with TickerProviderStateMixin {
  late AnimationController _ring1Ctrl;
  late AnimationController _ring2Ctrl;
  late AnimationController _ring3Ctrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;

  int _statusIndex = 0;
  Timer? _statusTimer;
  static const _statusMessages = [
    'Checking status',
    'Connecting securely',
    'Almost there',
  ];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack));
    _entranceCtrl.forward();

    _ring1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ring2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
    _ring3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear);

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        _statusIndex = (_statusIndex + 1) % _statusMessages.length;
      });
    });
  }

  @override
  void dispose() {
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    _ring3Ctrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _entranceCtrl.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final tertiary = theme.colorScheme.tertiary;

    return FadeTransition(
      opacity: _entranceFade,
      child: ScaleTransition(
        scale: _entranceScale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_ring1Ctrl, _ring2Ctrl, _ring3Ctrl, _glowAnim]),
                  builder: (_, __) {
                    return SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80 + 20 * _glowAnim.value,
                            height: 80 + 20 * _glowAnim.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primary.withValues(
                                      alpha: 0.18 * _glowAnim.value),
                                  primary.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _OrbitalRingPainter(
                              progress: _ring3Ctrl.value,
                              color: tertiary.withValues(alpha: 0.5),
                              strokeWidth: 1.5,
                              gapFraction: 0.5,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(84, 84),
                            painter: _OrbitalRingPainter(
                              progress: 1 - _ring2Ctrl.value,
                              color: secondary.withValues(alpha: 0.7),
                              strokeWidth: 2.0,
                              gapFraction: 0.35,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(58, 58),
                            painter: _OrbitalRingPainter(
                              progress: _ring1Ctrl.value,
                              color: primary,
                              strokeWidth: 2.5,
                              gapFraction: 0.25,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? primary.withValues(alpha: 0.15)
                                  : primary.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.3),
                                  width: 1.5),
                            ),
                            child: Icon(Icons.phone_android_rounded,
                                size: 18, color: primary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _statusMessages[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait a moment…',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, __) {
                    final p = _shimmerAnim.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBlock(
                            width: 110,
                            height: 12,
                            shimmerProgress: p,
                            isDark: isDark,
                            radius: 6),
                        const SizedBox(height: 10),
                        _ShimmerBlock(
                            width: double.infinity,
                            height: 56,
                            shimmerProgress: p,
                            isDark: isDark,
                            radius: 14),
                        const SizedBox(height: 16),
                        _ShimmerBlock(
                            width: double.infinity,
                            height: 36,
                            shimmerProgress: p,
                            isDark: isDark,
                            radius: 8),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _ShimmerBlock(
                                width: 28,
                                height: 28,
                                shimmerProgress: p,
                                isDark: isDark,
                                radius: 14),
                            const SizedBox(width: 4),
                            Expanded(
                                child: _ShimmerBlock(
                                    width: double.infinity,
                                    height: 2,
                                    shimmerProgress: p,
                                    isDark: isDark,
                                    radius: 1)),
                            const SizedBox(width: 4),
                            _ShimmerBlock(
                                width: 28,
                                height: 28,
                                shimmerProgress: p,
                                isDark: isDark,
                                radius: 14),
                            const SizedBox(width: 4),
                            Expanded(
                                child: _ShimmerBlock(
                                    width: double.infinity,
                                    height: 2,
                                    shimmerProgress: p,
                                    isDark: isDark,
                                    radius: 1)),
                            const SizedBox(width: 4),
                            _ShimmerBlock(
                                width: 28,
                                height: 28,
                                shimmerProgress: p,
                                isDark: isDark,
                                radius: 14),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _ShimmerBlock(
                            width: double.infinity,
                            height: 54,
                            shimmerProgress: p,
                            isDark: isDark,
                            radius: 14),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Service Down View
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceDownView extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onContactSupport;
  final VoidCallback onRetry;

  const _ServiceDownView({
    required this.theme,
    required this.onContactSupport,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _IllustrationCircle(
            color: theme.colorScheme.error,
            bgOpacity: 0.1,
            size: 120,
            child: Icon(Icons.wifi_off_rounded,
                size: 52, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 32),
          Text(
            'Can\'t connect',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re having trouble reaching the server. Check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          _InfoCard(
            theme: theme,
            items: const [
              _InfoItem(
                  icon: Icons.wifi_rounded,
                  label: 'Check your Wi-Fi or mobile data'),
              _InfoItem(
                  icon: Icons.refresh_rounded, label: 'Try restarting the app'),
              _InfoItem(
                  icon: Icons.schedule_rounded,
                  label: 'Service may be briefly unavailable'),
            ],
          ),
          const SizedBox(height: 32),
          _PrimaryButton(
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Contact Support',
            icon: Icons.headset_mic_rounded,
            onPressed: onContactSupport,
            theme: theme,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Enter Phone View
// ─────────────────────────────────────────────────────────────────────────────
class _EnterPhoneView extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final CountryCode selectedCountry;
  final bool isLoading;
  final VoidCallback onPickCountry;
  final ValueChanged<String> onChanged;
  final VoidCallback onSendOtp;

  const _EnterPhoneView({
    required this.theme,
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.selectedCountry,
    required this.isLoading,
    required this.onPickCountry,
    required this.onChanged,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: _IllustrationCircle(
                    color: theme.colorScheme.primary,
                    bgOpacity: 0.1,
                    size: 96,
                    child: Icon(Icons.phone_android_rounded,
                        size: 44, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Verify Your Number',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll send a one-time code to your WhatsApp',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 8),
                _PhoneInputField(
                  controller: controller,
                  focusNode: focusNode,
                  selectedCountry: selectedCountry,
                  theme: theme,
                  isDark: isDark,
                  onPickCountry: onPickCountry,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 12),
                _WhatsAppHint(theme: theme),
                const SizedBox(height: 28),
                _StepIndicator(
                    theme: theme,
                    steps: const ['Enter number', 'Verify OTP', 'Done'],
                    currentStep: 0),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: AnimatedSwitcher(
            duration: _Tokens.duration300,
            child: isLoading
                ? _LoadingIndicator(
                    key: const ValueKey('loading'),
                    theme: theme,
                    label: 'Sending OTP…')
                : _PrimaryButton(
                    key: const ValueKey('btn'),
                    label: 'Send OTP',
                    icon: Icons.send_rounded,
                    onPressed: onSendOtp,
                    theme: theme,
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Enter OTP View
// ─────────────────────────────────────────────────────────────────────────────
class _EnterOtpView extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final TextEditingController otpController;
  final FocusNode otpFocus;
  final CountryCode selectedCountry;
  final String phoneNumber;
  final bool isLoading;
  final bool isObscured;
  final int remainingTime;
  final VoidCallback onToggleObscure;
  final VoidCallback onChangeNumber;
  final VoidCallback onResendOtp;
  final VoidCallback onVerifyOtp;

  const _EnterOtpView({
    required this.theme,
    required this.isDark,
    required this.otpController,
    required this.otpFocus,
    required this.selectedCountry,
    required this.phoneNumber,
    required this.isLoading,
    required this.isObscured,
    required this.remainingTime,
    required this.onToggleObscure,
    required this.onChangeNumber,
    required this.onResendOtp,
    required this.onVerifyOtp,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark
        ? theme.colorScheme.surfaceVariant.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5);
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.25)
        : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: _IllustrationCircle(
                    color: theme.colorScheme.primary,
                    bgOpacity: 0.1,
                    size: 96,
                    child: Icon(Icons.mark_chat_read_rounded,
                        size: 44, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Enter Code',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            const TextSpan(text: 'Code sent via WhatsApp to\n'),
                            TextSpan(
                              text: '${selectedCountry.code} $phoneNumber',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_Tokens.radius),
                    color: inputBg,
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: otpController,
                    focusNode: otpFocus,
                    keyboardType: TextInputType.number,
                    obscureText: isObscured,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: isObscured ? 6.0 : 8.0,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • • • •',
                      hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          fontSize: 22,
                          letterSpacing: 6),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Icon(Icons.lock_outline_rounded,
                            color: theme.colorScheme.primary, size: 22),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_Tokens.radius),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: isLoading ? null : onChangeNumber,
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Change Number'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: _Tokens.duration300,
                      child: remainingTime > 0
                          ? _TimerChip(
                              key: const ValueKey('timer'),
                              remainingTime: remainingTime,
                              theme: theme)
                          : TextButton.icon(
                              key: const ValueKey('resend'),
                              onPressed: isLoading ? null : onResendOtp,
                              icon: const Icon(Icons.refresh_rounded, size: 15),
                              label: const Text('Resend OTP'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StepIndicator(
                    theme: theme,
                    steps: const ['Enter number', 'Verify OTP', 'Done'],
                    currentStep: 1),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: AnimatedSwitcher(
            duration: _Tokens.duration300,
            child: isLoading
                ? _LoadingIndicator(
                    key: const ValueKey('loading'),
                    theme: theme,
                    label: 'Verifying…')
                : _PrimaryButton(
                    key: const ValueKey('btn'),
                    label: 'Verify & Link',
                    icon: Icons.verified_rounded,
                    onPressed: onVerifyOtp,
                    theme: theme,
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable Components
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationCircle extends StatelessWidget {
  final Color color;
  final double bgOpacity;
  final double size;
  final Widget child;

  const _IllustrationCircle({
    required this.color,
    required this.bgOpacity,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgOpacity),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});
}

class _InfoCard extends StatelessWidget {
  final ThemeData theme;
  final List<_InfoItem> items;

  const _InfoCard({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(item.icon,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final ThemeData theme;
  final List<String> steps;
  final int currentStep;

  const _StepIndicator({
    required this.theme,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: _Tokens.duration500,
              height: 2,
              decoration: BoxDecoration(
                color: isDone
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isActive = stepIdx == currentStep;
        final isDone = stepIdx < currentStep;

        return Column(
          children: [
            AnimatedContainer(
              duration: _Tokens.duration300,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                border: isActive || isDone
                    ? null
                    : Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : Text(
                        '${stepIdx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIdx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WhatsAppHint extends StatelessWidget {
  final ThemeData theme;
  const _WhatsAppHint({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wechat_sharp, size: 16, color: Color(0xFF25D366)),
          const SizedBox(width: 8),
          Text(
            'OTP will be delivered via WhatsApp',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final int remainingTime;
  final ThemeData theme;
  const _TimerChip(
      {super.key, required this.remainingTime, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            'Resend in ${remainingTime}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final ThemeData theme;
  final String label;
  const _LoadingIndicator(
      {super.key, required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Button Components
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _PrimaryButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_Tokens.radius)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_Tokens.radius)),
          side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Phone Input Field
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({
    required this.controller,
    required this.focusNode,
    required this.selectedCountry,
    required this.theme,
    required this.isDark,
    required this.onPickCountry,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CountryCode selectedCountry;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onPickCountry;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark
        ? theme.colorScheme.surfaceVariant.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5);
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.25)
        : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_Tokens.radius),
        color: inputBg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPickCountry,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(_Tokens.radius)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: borderColor))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selectedCountry.flag,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      selectedCountry.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radius),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6)),
                        onPressed: controller.clear,
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Confirm Delete Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmDeleteDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusXl)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded,
                  color: theme.colorScheme.error, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              'Remove Phone Number?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This will permanently unlink your phone. You\'ll need to verify again to use phone features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Tokens.radius)),
                      side: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Tokens.radius)),
                    ),
                    child: const Text('Remove',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Country Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  final List<CountryCode> countries;
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<CountryCode> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.countries
          .where((c) => c.name.toLowerCase().contains(q) || c.code.contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 14),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text('Select Country',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search country or code…',
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant, size: 20),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Tokens.radius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected.code &&
                    c.name == widget.selected.name;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                  title: Text(c.name,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.code,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary, size: 20),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    widget.onSelected(c);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
