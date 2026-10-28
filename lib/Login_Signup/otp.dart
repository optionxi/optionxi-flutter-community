import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Colors_Text_Components/colors.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';

class OTP extends StatefulWidget {
  final String number;
  const OTP(this.number, {Key? key}) : super(key: key);

  @override
  State<OTP> createState() => _OTPState();
}

class _OTPState extends State<OTP> {
  String? smsCode;
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          unselectedWidgetColor: const Color(0xffe0e0e0),
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xff1d98f0)),
      home: Scaffold(
          body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/loginbg.png"),
                      fit: BoxFit.cover)),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => {Navigator.pop(context)},
                      child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: SvgPicture.asset("assets/images/backbtn.svg")),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: const Text(
                    "Signup",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.Black),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 0, 4),
                  child: const Text(
                    "Verify OTP",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.Black),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 2, 0, 8),
                  child: Text(
                    "We have sent a 6-digit OTP to your mobile number",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 20),
                // OTPTextField(
                //   onChanged: (value) => {smsCode = value},
                //   margin: EdgeInsets.fromLTRB(4, 8, 4, 12),
                //   width: MediaQuery.of(context).size.width,
                //   length: 6,
                //   textFieldAlignment: MainAxisAlignment.spaceEvenly,
                //   fieldWidth: 45,
                //   spaceBetween: 4,
                //   fieldStyle: FieldStyle.box,
                //   outlineBorderRadius: 5,
                //   otpFieldStyle: OtpFieldStyle(
                //     focusBorderColor: Color(0xFF58B85F),
                //     backgroundColor: Color(0xFFFFFFFF),
                //     borderColor: Color(0xffe0e0e0).withValues(alpha:0.6),
                //     //(here)
                //   ),
                //   style: TextStyle(
                //       fontSize: 16,
                //       fontFamily: "Poppins",
                //       fontWeight: FontWeight.w400,
                //       color: Color(0xFF424242)),
                // ),
                Container(
                    height: 15,
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(right: 25, top: 8),
                    alignment: Alignment.centerRight,
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF343c47),
                          decoration: TextDecoration.underline),
                    )),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () async {
                    if (smsCode != null) {
                      if (loading) {
                        GlobalSnackBarGet()
                            .showGetError("Loading", 'please wait');
                      } else {
                        loading = true;
                        setState(() {});
                        try {
                          // PhoneAuthCredential credential =
                          //     PhoneAuthProvider.credential(
                          //         verificationId: Singup.verifiId,
                          //         smsCode: smsCode!);

                          AuthService().verifyOtp(smsCode, context);

                          // var success = await FirebaseAuth.instance
                          //     .signInWithCredential(credential);

                          // GlobalSnackBarGet()
                          //     .showGetSuccess("Success", 'OTP Verified');

                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => Homepage()),
                          // );
                        } catch (e) {
                          loading = false;
                          GlobalSnackBarGet()
                              .showGetError("Error", 'InValid OTP');
                        }
                      }
                    } else {
                      loading = false;
                      GlobalSnackBarGet()
                          .showGetError("Error", 'Enter Valid OTP');
                    }
                  },
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Center(
                            child: Text("Verify OTP",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: AppColors.White,
                                    fontWeight: FontWeight.w500)),
                          ),
                  ),
                ),
              ],
            )
          ],
        ),
      )),
    );
  }
}
