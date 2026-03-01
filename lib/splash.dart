// import 'package:appoptionxi/Auth_Service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:optionxi/Login_Signup/login2.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    // navigatehome();
    super.initState();
  }

  navigatehome() async {
    await Future.delayed(const Duration(milliseconds: 500), () {});
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const ModernLoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    navigatehome();
    return Scaffold(
        // backgroundColor: Color(0xFFF7F7F7),
        body: Stack(children: [
      Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(5.0)),
            image: DecorationImage(
                image: AssetImage("assets/images/loginbg.png"),
                fit: BoxFit.cover)),
      ),

      Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                const Color(0xff1BD692),
                const Color(0xff0D7D33).withValues(alpha: .70)
              ], // Gradient colors
              begin: Alignment.topCenter, // Gradient start point
              end: Alignment.bottomCenter, // Gradient end point
            ).createShader(bounds);
          },
          child: const Text(
            'appoptionxi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1,
              fontFamily: 'Kanit',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      // Center(
      //   child: Container(
      //       height: 100,
      //       width: 270,
      //       child: Align(
      //         alignment: Alignment.topCenter,
      //         child: Image.asset(
      //           "assets/images/logo.png",
      //         ),
      //       )),
      // ),
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     Text(
      //       "Bench",
      //       textAlign: TextAlign.center,
      //       style: TextStyle(
      //           fontFamily: 'Poppins',
      //           fontSize: 24,
      //           fontWeight: FontWeight.w700,
      //           color: Color(0xffffffff)),
      //     ),
      //     Text(
      //       "mate",
      //       textAlign: TextAlign.center,
      //       style: TextStyle(
      //           fontFamily: 'Poppins',
      //           fontSize: 24,
      //           fontWeight: FontWeight.w400,
      //           color: Color(0xffffffff)),
      //     ),
      //   ],
      // )
      // Expanded(
      //   child: Align(
      //       alignment: Alignment.bottomCenter,
      //       child: Container(
      //           margin: EdgeInsets.only(bottom: 16),
      //           child: Image.asset("assets/images/btechlogo.png"))),
      // )
      //     Positioned(
      //       bottom: 40,
      //       left: 0,
      //       right: 0,
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //           SvgPicture.asset("assets/images/india.svg"),
      //           SizedBox(
      //             width: 8,
      //           ),
      //           Text(
      //             "Indias first direct college admission app",
      //             textAlign: TextAlign.center,
      //             style: TextStyle(
      //                 fontFamily: 'Poppins',
      //                 fontSize: 13,
      //                 fontWeight: FontWeight.w300,
      //                 color: Color(0xffffffff)),
      //           ),
      //         ],
      //       ),
      //     )
      //   ],
      // ));
    ]));
  }
}
