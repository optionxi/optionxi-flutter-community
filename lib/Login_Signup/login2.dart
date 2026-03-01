import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/DB_Services/database_read.dart';
import 'package:optionxi/DataModels/dm_reg_users.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/date_conversion.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';

class ModernLoginPage extends StatefulWidget {
  const ModernLoginPage({Key? key}) : super(key: key);

  @override
  State<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends State<ModernLoginPage>
    with TickerProviderStateMixin {
  // late AnimationController _orbitController;
  late AnimationController _innerOrbitController;
  late AnimationController _outerOrbitController;

  late AnimationController _pulseController;
  late AnimationController _centerPulseController;
  bool _isLoading = false;

  final List<BrokerNode> innerOrbitBrokers = [
    BrokerNode("Zerodha", "assets/loginicons/improvement.png", 0),
    BrokerNode("Upstox", "assets/loginicons/bellcurve.png", 120),
    BrokerNode("Fyers", "assets/loginicons/dollar.png", 240),
  ];

  final List<BrokerNode> outerOrbitBrokers = [
    BrokerNode("Angel", "assets/loginicons/donut_chart.png", 60),
    BrokerNode("ICICI", "assets/loginicons/line_chart.png", 180),
    BrokerNode("Groww", "assets/loginicons/venn_diagram.png", 300),
  ];

  @override
  void initState() {
    super.initState();

    _innerOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), // little faster
    )..repeat();

    _outerOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45), // slightly slower
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _centerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _innerOrbitController.dispose();
    _outerOrbitController.dispose();

    _pulseController.dispose();
    _centerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgGradientStart = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgGradientStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Single scrollable column
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top padding
                    SizedBox(height: MediaQuery.of(context).padding.top + 20),

                    // Orbital system
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double minSide = math.min(
                              constraints.maxWidth, constraints.maxHeight);
                          final double baseRadius = minSide * 0.35;
                          final double r1 = baseRadius * 0.6;
                          final double r2 = baseRadius * 0.9;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Center Pulse with pulsating rings
                              _buildCenterPulse(r1),

                              // Orbit Rings
                              _buildOrbitRing(r1 * 2),
                              _buildOrbitRing(r2 * 2),

                              // Center Logo
                              _buildCenterLogo(),

                              // Inner Brokers
                              ...innerOrbitBrokers
                                  .map((broker) => _buildOrbitingBroker(
                                        broker: broker,
                                        radius: r1,
                                        controller: _innerOrbitController,
                                      )),

                              // Outer Brokers
                              ...outerOrbitBrokers
                                  .map((broker) => _buildOrbitingBroker(
                                        broker: broker,
                                        radius: r2,
                                        controller: _outerOrbitController,
                                      )),
                            ],
                          );
                        },
                      ),
                    ),

                    // Small margin between orbital and login
                    // const SizedBox(height: 24),

                    // Login Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildGlassLoginCard(),
                    ),

                    // Bottom padding
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connecting to markets...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  Widget _buildCenterPulse(double radius) {
    return AnimatedBuilder(
      animation: _centerPulseController,
      builder: (context, _) {
        final scale = 1.0 + (_centerPulseController.value * 0.2);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsating ring
            Container(
              width: radius * 2.2 * scale,
              height: radius * 2.2 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6366F1)
                      .withOpacity(0.3 * (1 - _centerPulseController.value)),
                  width: 2,
                ),
              ),
            ),
            // Inner pulsating ring
            Container(
              width: radius * 1.8 * (2 - scale),
              height: radius * 1.8 * (2 - scale),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6366F1)
                      .withOpacity(0.4 * _centerPulseController.value),
                  width: 2,
                ),
              ),
            ),
            // Gradient pulse
            Container(
              width: radius * 1.8,
              height: radius * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1)
                        .withOpacity(0.15 * _pulseController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrbitRing(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildCenterLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/option_xi_w.png",
              fit: BoxFit.contain,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.error, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitingBroker({
    required BrokerNode broker,
    required double radius,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double currentAngle = (controller.value * 2 * math.pi);
        final double startAngleRad = broker.startAngleDeg * (math.pi / 180);
        final double finalAngle = currentAngle + startAngleRad;

        return Transform.translate(
          offset: Offset(
            math.cos(finalAngle) * radius,
            math.sin(finalAngle) * radius,
          ),
          child: _buildBrokerBubble(broker),
        );
      },
    );
  }

  Widget _buildBrokerBubble(BrokerNode broker) {
    return Container(
      width: 35,
      height: 35,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 213, 212, 212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Image.asset(
        broker.logoPath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildGlassLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Welcome Back",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to access your trading dashboard",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildSocialButton(
                "Continue with Google",
                "assets/illustrations/google_logo.svg",
                () => _handleGoogleSignIn(),
              ),
              const SizedBox(height: 16),
              if (Platform.isIOS)
                _buildSocialButton(
                  "Continue with Apple",
                  null,
                  () => _handleAppleSignIn(),
                  isApple: true,
                ),
              const SizedBox(height: 24),
              Text(
                "By continuing you agree to our Terms & Privacy Policy",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text, String? iconPath, VoidCallback onTap,
      {bool isApple = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isApple)
                const Icon(Icons.apple, color: Colors.black, size: 22)
              else if (iconPath != null)
                SvgPicture.asset(iconPath, width: 20, height: 20)
              else
                const Icon(Icons.login, color: Colors.black),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Login Logic - Google Sign In
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      await AuthService().signInWithGoogle();
      await _checkIfFirstTime();
    } catch (e) {
      GlobalSnackBarGet().showGetError(
        "Authentication Failed",
        "Unable to sign in with Google. Please try again.",
      );
    } finally {
      // setState(() => _isLoading = false);
      // Note: Loading state is managed by navigation or kept on
    }
  }

  // Login Logic - Apple Sign In
  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);
      await AuthService().signInWithApple();
      await _checkIfFirstTime();
    } catch (e) {
      GlobalSnackBarGet().showGetError(
        "Authentication Failed",
        "Unable to sign in with Apple. Please try again.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check if first time user and process user data
  Future<void> _checkIfFirstTime() async {
    try {
      var currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        var user = dm_reg_user()
          ..rgEmail = currentUser.email
          ..rgName = currentUser.displayName
          ..rgImage = currentUser.photoURL
          ..rgTimeinmill = Date_Conversions().getTimeinmill()
          ..rgTime = Date_Conversions().getCurrentDate(Constants.TIME_format)
          ..rgDate = Date_Conversions().getCurrentDate(Constants.DATE_format);

        await DatabaseReadService().getUserDetail(currentUser.uid, user);
      }
    } catch (e) {
      GlobalSnackBarGet().showGetError(
        "Error",
        "Unable to process your information. Please try again.",
      );
    }
  }
}

class BrokerNode {
  final String name;
  final String logoPath;
  final double startAngleDeg;
  BrokerNode(this.name, this.logoPath, this.startAngleDeg);
}
