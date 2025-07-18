import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:optionxi/Components/custom_nav_bar.dart';
import 'package:optionxi/Dialogs/custom_dialog.dart';
import 'package:optionxi/Helpers/open_url.dart';
import 'package:optionxi/Helpers/update_helper.dart';
import 'package:optionxi/Main_Frags/frag_home.dart';
import 'package:optionxi/Main_Frags/frag_virtualtrading.dart';
import 'package:optionxi/Main_Frags/frag_tools.dart';
import 'package:optionxi/Main_Frags/frag_watchlist.dart';
import 'package:optionxi/Main_Frags/frag_profile.dart';

class Homepage extends StatefulWidget {
  final int initialIndex;
  final int? tradeFragIndex;

  const Homepage({
    Key? key,
    this.initialIndex = 0,
    this.tradeFragIndex,
  }) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool compulsory = false;
  String androidurl =
      "https://play.google.com/store/apps/details?id=com.optionxi.app";
  String iosurl = "https://apps.apple.com/in/app/optionxi/id6447514602";

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex; // Set initial index

    fetchRemoteConfig();
  }

  void onTap(int index) {
    setState(() => currentIndex = index);
  }

  Widget getPage(int index) {
    switch (index) {
      case 0:
        return TradingHomeScreen();
      case 1:
        return VirtualTradingFragment(
          initialFragIndex: widget.tradeFragIndex, // Pass the fragment index
        );
      case 2:
        return WatchlistPage();
      case 3:
        return AdvancedTradingToolsPage();
      case 4:
        return TradingProfilePage();
      default:
        return TradingHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: 400.ms,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: getPage(currentIndex), // <-- rebuilt dynamically
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }

  Future<void> fetchRemoteConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 120),
        ),
      );
      await remoteConfig.activate();
      await remoteConfig.fetch();

      iosurl = remoteConfig.getString('ioslink');
      androidurl = remoteConfig.getString('androidlink');
      String message = remoteConfig.getString('Message');
      int latestVersion = remoteConfig.getInt('latest_version');
      int minVersion = remoteConfig.getInt('min_version');
      int buildNumber = await getBuildNumber();

      if (buildNumber < minVersion) compulsory = true;
      if (buildNumber < latestVersion) {
        DialogUtils().showCustomDialogUpdate(
          context: context,
          title: "Update Available",
          description: message,
          confirmButtonText: "Update",
          cancelButtonText: "Cancel",
          onConfirm: updateFunction,
          onCancel: cancelFunction,
          isDismissible: compulsory,
        );
      }
    } catch (e) {
      print('Error fetching remote config: $e');
    }
  }

  void updateFunction() {
    OpenHelper.open_url(Platform.isIOS ? iosurl : androidurl);
  }

  void cancelFunction() {
    if (!compulsory) Navigator.pop(context);
  }
}
