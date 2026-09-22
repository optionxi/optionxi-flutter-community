import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String get _kRazorApiBase => dotenv.env['RAZORPAY_API_URL']!;

Future<String> createPaymentLink({
  required String phone,
  required String planKey,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not signed in');

  final idToken = await user.getIdToken();

  final response = await http.post(
    Uri.parse('${_kRazorApiBase}/payments/create-link'),
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'phone': phone,
      'plan_key': planKey,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to create payment link: ${response.body}');
  }

  final data = jsonDecode(response.body);
  return data[
      'short_url']; // open this URL (webview or url_launcher) for the user to pay
}
