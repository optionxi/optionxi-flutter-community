import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void showContactOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Choose your preferred way to get in touch",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // Contact options
          _buildContactOption(
            context: context,
            icon: FontAwesomeIcons.whatsapp,
            iconColor: Color(0xFF25D366),
            title: "WhatsApp",
            subtitle: "Quick instant responses",
            onTap: () {
              Navigator.pop(context);
              _launchWhatsApp();
            },
          ),

          _buildContactOption(
            context: context,
            icon: FontAwesomeIcons.envelope,
            iconColor: Color(0xFFEA4335),
            title: "Gmail",
            subtitle: "Professional email support",
            onTap: () {
              Navigator.pop(context);
              _launchGmail();
            },
          ),

          _buildContactOption(
            context: context,
            icon: FontAwesomeIcons.instagram,
            iconColor: Color(0xFFE4405F),
            title: "Instagram",
            subtitle: "Follow us for updates",
            onTap: () {
              Navigator.pop(context);
              _launchInstagram();
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}

// Social Media Launch Functions
Future<void> _launchWhatsApp() async {
  const phoneNumber = "9496672190"; // Replace with your WhatsApp number
  const message = "Hi! I'm interested in deploying my algorithm with OptionXi.";

  final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch WhatsApp');
    }
  } catch (e) {
    print('Error launching WhatsApp: $e');
  }
}

Future<void> _launchGmail() async {
  const email = 'optionxi24@gmail.com';
  const subject = 'Algorithm Deployment Inquiry';
  const body =
      'Hello,\n\nI would like to learn more about deploying my algorithm with OptionXi.\n\nBest regards';

  // Create the mailto URL string directly
  final String mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
  final Uri gmailUri = Uri.parse(mailtoUrl);

  try {
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(
        gmailUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch Gmail');
    }
  } catch (e) {
    print('Error launching Gmail: $e');
  }
}

Future<void> _launchInstagram() async {
  const instagramUsername = "optionxi"; // Replace with your Instagram username
  final Uri instagramUri =
      Uri.parse("https://instagram.com/$instagramUsername");

  try {
    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(
        instagramUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch Instagram');
    }
  } catch (e) {
    print('Error launching Instagram: $e');
  }
}

Widget _buildContactOption({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    ),
  );
}
