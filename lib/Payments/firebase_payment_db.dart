import 'package:firebase_database/firebase_database.dart';
import 'package:optionxi/Payments/subscription_model.dart';

class FirebaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static String generateId() {
    return _database.push().key!;
  }

  // Subscription Methods
  static Future<void> saveUserSubscription(
      UserSubscription subscription) async {
    await _database
        .child('subscriptions/${subscription.userId}')
        .set(subscription.toJson());
  }

  static Future<UserSubscription?> getUserSubscription(String userId) async {
    try {
      final snapshot = await _database.child('subscriptions/$userId').get();
      if (snapshot.exists) {
        return UserSubscription.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  static Future<void> updateSubscriptionStatus(
      String userId, bool isActive) async {
    await _database.child('subscriptions/$userId/isActive').set(isActive);
  }

  // Real-time listeners
  static Stream<UserSubscription?> subscriptionStream(String userId) {
    return _database.child('subscriptions/$userId').onValue.map((event) {
      if (event.snapshot.exists) {
        return UserSubscription.fromJson(
            Map<String, dynamic>.from(event.snapshot.value as Map));
      }
      return null;
    });
  }
}
