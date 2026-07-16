import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_contact_us.dart';

/// Button: "Purchase the Pro version, to receive realtime notifications."
/// Opens WhatsApp with a prefilled message when tapped.
class ProUpgradeButton extends StatelessWidget {
  const ProUpgradeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            10), // Tighter border radius for a slim banner
        gradient: const LinearGradient(
          colors: [
            Color(0xFF109D58),
            Color(0xFF25D366),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3), // Closer shadow for a compressed feel
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          onTap: () => showContactOptions(
            context,
            'Upgrade to Pro — get realtime alerts on WhatsApp',
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),

                // Using RichText to keep the title and subtitle on a single, slim line
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Upgrade to Pro  ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: '•  Get realtime alerts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 14, // Scaled down to match the slim profile
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
