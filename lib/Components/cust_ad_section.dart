import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_info_section_item.dart';

class AdSectionProfilePrev extends StatefulWidget {
  const AdSectionProfilePrev({super.key});

  @override
  State<AdSectionProfilePrev> createState() => _AdSectionProfilePrevState();
}

class _AdSectionProfilePrevState extends State<AdSectionProfilePrev> {
  final int maxFailedLoadAttempts = 3;

  //Mobile Ads
  // static final AdRequest request = AdRequest(
  //   keywords: <String>['foo', 'bar'],
  //   contentUrl: 'http://foo.com/bar.html',
  //   nonPersonalizedAds: true,
  // );

  // // InterstitialAd? _interstitialAd;
  // // int _numInterstitialLoadAttempts = 0;

  // RewardedAd? _rewardedAd;
  // int _numRewardedLoadAttempts = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return buildActionItem(
      title: 'Watch an Ad',
      subtitle: 'Watch ad to increase virtual money',
      icon: FontAwesomeIcons.wallet,
      color: Color(0xFF9B59B6),
      onTap: showAd_IncrementBalance,
      isDark: isDark,
      badge: 'AD',
    );
  }

  void showAd_IncrementBalance() {}
}
