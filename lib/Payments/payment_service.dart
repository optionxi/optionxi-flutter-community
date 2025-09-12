import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:optionxi/Payments/payment_history_model.dart';

class PaymentService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static const Set<String> _productIds = {
    'basic_monthly_299',
    'premium_monthly_499',
    'pro_monthly_899',
  };

  static Future<bool> initializePayments() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      return false;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    return response.productDetails.isNotEmpty;
  }

  static Future<List<ProductDetails>> getAvailableProducts() async {
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);
    return response.productDetails;
  }

  static Future<bool> purchaseSubscription(
      String productId, String userId) async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails({productId});
      print('Purchase Subscrip Response: ${response.productDetails}');
      if (response.productDetails.isEmpty) {
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      final bool success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (success) {
        await _recordPayment(userId, productId, productDetails.price);
      }

      return success;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  static Future<void> _recordPayment(
      String userId, String productId, String price) async {
    final paymentId = _database.child('payments').child(userId).push().key!;
    final payment = PaymentHistory(
      id: paymentId,
      userId: userId,
      planId: _getPlanIdFromProduct(productId),
      amount: double.parse(price.replaceAll(RegExp(r'[^0-9.]'), '')),
      date: DateTime.now(),
      status: 'completed',
      transactionId: 'txn_$paymentId',
    );

    await _database.child('payments/$paymentId').set(payment.toJson());
  }

  static String _getPlanIdFromProduct(String productId) {
    if (productId.contains('basic')) return 'basic';
    if (productId.contains('premium')) return 'premium';
    if (productId.contains('pro')) return 'pro';
    return 'basic';
  }

  static Future<void> cancelSubscription(String userId) async {
    await _database.child('subscriptions/$userId/autoRenew').set(false);
  }

  static Future<bool> downgradeSubscription(
      String userId, String newPlanId) async {
    try {
      final subscription = await _database.child('subscriptions/$userId').get();
      if (subscription.exists) {
        final data = Map<String, dynamic>.from(subscription.value as Map);
        data['planId'] = newPlanId;
        data['autoRenew'] = true;
        await _database.child('subscriptions/$userId').update(data);
        return true;
      }
      return false;
    } catch (e) {
      print('Downgrade error: $e');
      return false;
    }
  }

  static Future<List<PaymentHistory>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _database.child('payments').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.values
            .map((e) => PaymentHistory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }
}
