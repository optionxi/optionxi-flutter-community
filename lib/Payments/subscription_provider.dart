import 'package:get/get.dart';
import 'package:optionxi/Payments/firebase_payment_db.dart';
import 'package:optionxi/Payments/payment_history_model.dart';
import 'package:optionxi/Payments/payment_service.dart';
import 'package:optionxi/Payments/subscription_model.dart';

class SubscriptionController extends GetxController {
  final Rx<UserSubscription?> _currentSubscription =
      Rx<UserSubscription?>(null);
  final RxList<PaymentHistory> _paymentHistory = <PaymentHistory>[].obs;
  final RxBool _isLoading = false.obs;

  UserSubscription? get currentSubscription => _currentSubscription.value;
  List<PaymentHistory> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading.value;

  SubscriptionPlan? get currentPlan {
    if (_currentSubscription.value == null) return null;
    return SubscriptionPlan.getPlans()
        .firstWhere((plan) => plan.id == _currentSubscription.value!.planId);
  }

  bool get hasActiveSubscription {
    return _currentSubscription.value?.isActive == true &&
        _currentSubscription.value!.endDate.isAfter(DateTime.now());
  }

  Future<void> loadUserSubscription(String userId) async {
    _isLoading.value = true;

    try {
      _currentSubscription.value =
          await FirebaseService.getUserSubscription(userId);
      _paymentHistory.value = await PaymentService.getPaymentHistory(userId);
    } catch (e) {
      print('Error loading subscription: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> purchaseSubscription(String planId, String userId) async {
    _isLoading.value = true;

    try {
      final productId =
          '${planId}_monthly_${SubscriptionPlan.getPlans().firstWhere((p) => p.id == planId).price.toInt()}';
      print('ProductID is ' + productId);
      final success =
          await PaymentService.purchaseSubscription(productId, userId);

      if (success) {
        await _createSubscription(userId, planId);
        await loadUserSubscription(userId);
      }

      return success;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _createSubscription(String userId, String planId) async {
    final subscription = UserSubscription(
      id: FirebaseService.generateId(),
      userId: userId,
      planId: planId,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 30)),
      isActive: true,
      autoRenew: true,
      paidAmount:
          SubscriptionPlan.getPlans().firstWhere((p) => p.id == planId).price,
    );

    await FirebaseService.saveUserSubscription(subscription);
  }

  Future<bool> cancelSubscription(String userId) async {
    try {
      await PaymentService.cancelSubscription(userId);
      await loadUserSubscription(userId);
      return true;
    } catch (e) {
      print('Cancel error: $e');
      return false;
    }
  }

  Future<bool> downgradeSubscription(String userId, String newPlanId) async {
    try {
      final success =
          await PaymentService.downgradeSubscription(userId, newPlanId);
      if (success) {
        await loadUserSubscription(userId);
      }
      return success;
    } catch (e) {
      print('Downgrade error: $e');
      return false;
    }
  }

  Future<bool> upgradeSubscription(String userId, String newPlanId) async {
    return await purchaseSubscription(newPlanId, userId);
  }

  void clearSubscriptionData() {
    _currentSubscription.value = null;
    _paymentHistory.clear();
  }

  Future<void> toggleAutoRenew(String userId, bool value) async {
    try {
      if (_currentSubscription.value != null) {
        final updatedSubscription = UserSubscription(
          id: _currentSubscription.value!.id,
          userId: _currentSubscription.value!.userId,
          planId: _currentSubscription.value!.planId,
          startDate: _currentSubscription.value!.startDate,
          endDate: _currentSubscription.value!.endDate,
          isActive: _currentSubscription.value!.isActive,
          autoRenew: value,
          paidAmount: _currentSubscription.value!.paidAmount,
        );

        await FirebaseService.saveUserSubscription(updatedSubscription);
        _currentSubscription.value = updatedSubscription;
      }
    } catch (e) {
      print('Error toggling auto-renew: $e');
    }
  }
}
