// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:optionxi/Auth_Service/auth_service.dart';
// import 'package:optionxi/DB_Services/database_read.dart';
// import 'package:optionxi/DataModels/dm_reg_users.dart';
// import 'package:optionxi/Helpers/constants.dart';
// import 'package:optionxi/Helpers/date_conversion.dart';
// import 'package:optionxi/Helpers/global_snackbar_get.dart';

// class ModernTradingLoginPage extends StatefulWidget {
//   const ModernTradingLoginPage({Key? key}) : super(key: key);

//   @override
//   State<ModernTradingLoginPage> createState() => _ModernTradingLoginPageState();
// }

// class _ModernTradingLoginPageState extends State<ModernTradingLoginPage>
//     with SingleTickerProviderStateMixin {
//   bool _isLoading = false;
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B0F1A),
//       body: Stack(
//         children: [
//           // Animated background elements
//           _buildBackgroundElements(),

//           // Main content
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // const SizedBox(height: 40),
//                     // _buildLogo(),
//                     const SizedBox(height: 40),
//                     _buildWelcomeText(),
//                     const SizedBox(height: 30),
//                     _buildTradingFeatures(),
//                     const SizedBox(height: 50),
//                     Flexible(child: Container()),
//                     _buildLoginButtons(),
//                     const SizedBox(height: 30),
//                     _buildFooterText(),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Loading overlay
//           if (_isLoading)
//             Container(
//               color: Colors.black87,
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF1A1F2E),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const CircularProgressIndicator(
//                         color: Color(0xFF6C63FF),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Connecting to markets...',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackgroundElements() {
//     return Stack(
//       children: [
//         // Top gradient
//         Positioned(
//           top: -150,
//           right: -100,
//           child: Container(
//             height: 300,
//             width: 300,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [
//                   const Color(0xFF6C63FF).withValues(alpha: 0.2),
//                   Colors.transparent,
//                 ],
//               ),
//             ),
//           ),
//         ),
//         // Market pattern
//         Positioned(
//           top: MediaQuery.of(context).size.height * 0.3,
//           right: -50,
//           child: Transform.rotate(
//             angle: -0.2,
//             child: Container(
//               height: 150,
//               width: 200,
//               child: CustomPaint(
//                 painter: ChartPatternPainter(),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Widget _buildLogo() {
//   //   return Hero(
//   //     tag: 'app_logo',
//   //     child: Center(
//   //       child: Container(
//   //         height: 100,
//   //         width: 100,
//   //         decoration: BoxDecoration(
//   //           borderRadius: BorderRadius.circular(25),
//   //           boxShadow: [
//   //             BoxShadow(
//   //               // color: const Color(0xFF6C63FF).withValues(alpha:0.3),
//   //               blurRadius: 50,
//   //               offset: const Offset(0, 10),
//   //             ),
//   //           ],
//   //         ),
//   //         child: ClipRRect(
//   //           borderRadius: BorderRadius.circular(25),
//   //           child: Image.asset(
//   //             'assets/images/option_xi.png',
//   //             fit: BoxFit.cover,
//   //           ),
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }

//   Widget _buildWelcomeText() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ShaderMask(
//           shaderCallback: (bounds) => const LinearGradient(
//             colors: [Color(0xFF6C63FF), Color(0xFF00B4D8)],
//           ).createShader(bounds),
//           child: const Text(
//             'OptionXi',
//             style: TextStyle(
//               color: Colors.white, // This color will be masked by the gradient
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         const Text(
//           'Join the next generation of virtual trading',
//           style: TextStyle(
//             color: Color(0xFF9796B8),
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTradingFeatures() {
//     final features = [
//       {
//         'icon': Icons.trending_up_rounded,
//         'iconColor': const Color(0xFF00B4D8),
//         'title': 'AI-Powered Analysis',
//         'subtitle': 'Advanced market predictions',
//         'gradient': const [Color(0xFF1A237E), Color(0xFF0D47A1)],
//       },
//       {
//         'icon': Icons.flash_on_rounded,
//         'iconColor': const Color(0xFFFFA000),
//         'title': 'Real-Time Trading',
//         'subtitle': 'Lightning-fast execution',
//         'gradient': const [Color(0xFF311B92), Color(0xFF4527A0)],
//       },
//       {
//         'icon': Icons.shield_rounded,
//         'iconColor': const Color(0xFF64DD17),
//         'title': 'Risk Management',
//         'subtitle': 'Smart portfolio protection',
//         'gradient': const [Color(0xFF1A237E), Color(0xFF0D47A1)],
//       },
//     ];

//     return Column(
//       children: features.asMap().entries.map((entry) {
//         final feature = entry.value;
//         final index = entry.key;

//         return TweenAnimationBuilder<double>(
//           tween: Tween(begin: 0.0, end: 1.0),
//           duration: Duration(milliseconds: 800 + (index * 200)),
//           builder: (context, value, child) {
//             return Transform.translate(
//               offset: Offset(0, 20 * (1 - value)),
//               child: Opacity(
//                 opacity: value,
//                 child: Container(
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: feature['gradient'] as List<Color>,
//                     ),
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: (feature['gradient'] as List<Color>)[0]
//                             .withValues(alpha: 0.3),
//                         blurRadius: 12,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: BackdropFilter(
//                       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: Colors.white.withValues(alpha: 0.1),
//                             width: 1,
//                           ),
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               Colors.white.withValues(alpha: 0.1),
//                               Colors.white.withValues(alpha: 0.05),
//                             ],
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             // Icon container with glowing effect
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: (feature['iconColor'] as Color)
//                                         .withValues(alpha: 0.3),
//                                     blurRadius: 20,
//                                     spreadRadius: 2,
//                                   ),
//                                 ],
//                               ),
//                               child: Icon(
//                                 feature['icon'] as IconData,
//                                 color: feature['iconColor'] as Color,
//                                 size: 32,
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     feature['title'] as String,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold,
//                                       letterSpacing: 0.5,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     feature['subtitle'] as String,
//                                     style: TextStyle(
//                                       color:
//                                           Colors.white.withValues(alpha: 0.8),
//                                       fontSize: 15,
//                                       letterSpacing: 0.3,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             // Icon(
//                             //   Icons.arrow_forward_ios_rounded,
//                             //   color: Colors.white.withValues(alpha:0.5),
//                             //   size: 16,
//                             // ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildLoginButtons() {
//     return Column(
//       children: [
//         _buildLoginButton(
//           text: 'Continue with Google',
//           icon: Icons.g_mobiledata_rounded,
//           gradient: const LinearGradient(
//             colors: [Color(0xFF6C63FF), Color(0xFF4B45B2)],
//           ),
//           onTap: () => _handleGoogleSignIn(),
//         ),
//         const SizedBox(height: 16),
//         if (Platform.isIOS)
//           _buildLoginButton(
//             text: 'Continue with Apple',
//             icon: Icons.apple_rounded,
//             gradient: const LinearGradient(
//               colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
//             ),
//             onTap: () => _handleAppleSignIn(),
//           ),
//       ],
//     );
//   }

//   Widget _buildLoginButton({
//     required String text,
//     required IconData icon,
//     required Gradient gradient,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: gradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: Colors.white, size: 28),
//                 const SizedBox(width: 12),
//                 Text(
//                   text,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFooterText() {
//     return Center(
//       child: Text(
//         'By continuing, you agree to our Terms of Service\nBuilt By Traders, OptionXi',
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           color: Colors.white.withValues(alpha: 0.5),
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   Future<void> _handleGoogleSignIn() async {
//     try {
//       setState(() => _isLoading = true);
//       await AuthService().signInWithGoogle();
//       await _checkIfFirstTime();
//     } catch (e) {
//       GlobalSnackBarGet().showGetError(
//         "Authentication Failed",
//         "Unable to sign in with Google. Please try again.",
//       );
//     } finally {
//       // setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleAppleSignIn() async {
//     try {
//       setState(() => _isLoading = true);
//       await AuthService().signInWithApple();
//       await _checkIfFirstTime();
//     } catch (e) {
//       GlobalSnackBarGet().showGetError(
//         "Authentication Failed",
//         "Unable to sign in with Apple. Please try again.",
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _checkIfFirstTime() async {
//     try {
//       var currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser != null) {
//         var user = dm_reg_user()
//           ..rgEmail = currentUser.email
//           ..rgName = currentUser.displayName
//           ..rgImage = currentUser.photoURL
//           ..rgTimeinmill = Date_Conversions().getTimeinmill()
//           ..rgTime = Date_Conversions().getCurrentDate(Constants.TIME_format)
//           ..rgDate = Date_Conversions().getCurrentDate(Constants.DATE_format);

//         await DatabaseReadService().getUserDetail(currentUser.uid, user);
//       }
//     } catch (e) {
//       GlobalSnackBarGet().showGetError(
//         "Error",
//         "Unable to process your information. Please try again.",
//       );
//     }
//   }
// }

// // Custom painter for the chart pattern
// class ChartPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF6C63FF).withValues(alpha: 0.1)
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;

//     final path = Path();
//     path.moveTo(0, size.height * 0.5);

//     // Create a candlestick pattern
//     for (var i = 0; i < 5; i++) {
//       final x = size.width * (i / 4);
//       final y = size.height * (0.3 + 0.4 * (i % 2));

//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
