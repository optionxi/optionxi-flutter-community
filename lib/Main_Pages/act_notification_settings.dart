// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final SupabaseClient _supabase = Supabase.instance.client;

  // Toggle states
  Map<String, bool> notificationSettings = {
    'general': true,
    'stock_scanner_breakouts': false,
    'watchlist_stock_breakouts': false,
    'market_sentiment_breakouts': false,
  };

  // Time interval state (0: 5min, 1: 15min, 2: 30min, 3: 1hour)
  int selectedTimeInterval = 2; // Default to 30min
  bool isPremiumUser = false; // Set this based on user's premium status

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationSettings.forEach((key, value) {
        notificationSettings[key] = prefs.getBool(key) ?? (key == 'general');
      });
      selectedTimeInterval = prefs.getInt('time_interval') ?? 2;
      isPremiumUser = prefs.getBool('is_premium') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    notificationSettings.forEach((key, value) async {
      await prefs.setBool(key, value);
    });
    await prefs.setInt('time_interval', selectedTimeInterval);
    // await _updateSupabase();
  }

  // Future<void> _updateSupabase() async {
  //   try {
  //     final Userlogged = FirebaseAuth.instance.currentUser;
  //     if (Userlogged != null) {
  //       final userId = Userlogged.uid;
  //       await _supabase.from('notification_settings').upsert({
  //         'user_id': userId,
  //         'general': notificationSettings['general'],
  //         'stock_scanner_breakouts':
  //             notificationSettings['stock_scanner_breakouts'],
  //         'watchlist_stock_breakouts':
  //             notificationSettings['watchlist_stock_breakouts'],
  //         'market_sentiment_breakouts':
  //             notificationSettings['market_sentiment_breakouts'],
  //         'higher_high_breakouts':
  //             notificationSettings['higher_high_breakouts'],
  //         'lower_low_breakouts': notificationSettings['lower_low_breakouts'],
  //         'top_gainers': notificationSettings['top_gainers'],
  //         'top_losers': notificationSettings['top_losers'],
  //         'top_volume': notificationSettings['top_volume'],
  //         'alert_frequency_minutes':
  //             _getMinutesFromInterval(selectedTimeInterval),
  //         'updated_at': DateTime.now().toIso8601String(),
  //       });
  //     }
  //   } catch (e) {
  //     print('Error updating Supabase: $e');
  //   }
  // }

  // int _getMinutesFromInterval(int intervalIndex) {
  //   switch (intervalIndex) {
  //     case 0:
  //       return 5;
  //     case 1:
  //       return 15;
  //     case 2:
  //       return 30;
  //     case 3:
  //       return 60;
  //     default:
  //       return 30;
  //   }
  // }

  // Future<void> _subscribeToTopic(String topic) async {
  //   await _firebaseMessaging.subscribeToTopic(topic);
  // }

  // Future<void> _unsubscribeFromTopic(String topic) async {
  //   await _firebaseMessaging.unsubscribeFromTopic(topic);
  // }

  void _toggleNotification(String key) async {
    setState(() {
      notificationSettings[key] = !notificationSettings[key]!;
    });

    if (notificationSettings[key]!) {
      // await _subscribeToTopic(key);
    } else {
      // await _unsubscribeFromTopic(key);
    }

    await _saveSettings();
  }

  void _selectTimeInterval(int index) {
    if ((index == 0 || index == 1) && !isPremiumUser) {
      _showPremiumDialog();
      return;
    }
    setState(() {
      selectedTimeInterval = index;
    });
    _saveSettings();
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
            'This time interval is available for premium users only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            size: 20,
          ),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General Alerts'),
            const SizedBox(height: 12),
            _buildNotificationTile(
              'general',
              'General',
              'System updates and important announcements',
              Icons.notifications_outlined,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Market Alerts'),
            const SizedBox(height: 12),
            _buildNotificationTile(
              'market_sentiment_breakouts',
              'Market Sentiment',
              'Notifications based on market sentiment shifts',
              Icons.psychology_outlined,
            ),
            _buildNotificationTile(
              'stock_scanner_breakouts',
              'Stock Scanner Breakouts',
              'Get notified when stocks break key resistance levels',
              Icons.trending_up_outlined,
            ),
            _buildNotificationTile(
              'watchlist_stock_breakouts',
              'Watchlist Breakouts',
              'Alerts for stocks in your watchlist breaking out',
              Icons.star_border_outlined,
              isPremium: true,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Alert Frequency'),
            const SizedBox(height: 12),
            _buildTimeIntervalSelector(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildNotificationTile(
    String key,
    String title,
    String description,
    IconData icon, {
    bool isPremium = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = notificationSettings[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                    : (isDarkMode ? Colors.grey[850] : Colors.grey[50]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isEnabled
                    ? const Color(0xFF3B82F6)
                    : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: isEnabled,
                onChanged: (value) => _toggleNotification(key),
                activeColor: const Color(0xFF3B82F6),
                activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.2),
                inactiveThumbColor:
                    isDarkMode ? Colors.grey[600] : Colors.grey[400],
                inactiveTrackColor:
                    isDarkMode ? Colors.grey[800] : Colors.grey[300],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIntervalSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final intervals = [
      {'label': '5min', 'premium': true},
      {'label': '15min', 'premium': true},
      {'label': '30min', 'premium': false},
      {'label': '1hour', 'premium': false},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Frequency',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How often you want to receive notifications',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: intervals.length,
                itemBuilder: (context, index) {
                  final interval = intervals[index];
                  final isSelected = selectedTimeInterval == index;
                  final isLocked =
                      interval['premium'] as bool && !isPremiumUser;

                  return Container(
                    margin: EdgeInsets.only(
                      right: index < intervals.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => _selectTimeInterval(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : (isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(8),
                          border: isLocked
                              ? Border.all(
                                  color: Colors.amber[600]!,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLocked) ...[
                              Icon(
                                Icons.lock_outlined,
                                color: Colors.amber[600],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              interval['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isLocked
                                        ? Colors.amber[600]
                                        : (isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
