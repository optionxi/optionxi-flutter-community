class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final List<String> features;
  final int maxBrokers;
  final bool realTimeData;
  final bool customNotifications;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.maxBrokers,
    required this.realTimeData,
    required this.customNotifications,
  });

  static List<SubscriptionPlan> getPlans() {
    return [
      SubscriptionPlan(
        id: 'basic',
        name: 'Basic',
        price: 299.0,
        maxBrokers: 1,
        realTimeData: false,
        customNotifications: true,
        features: [
          'Virtual Trading',
          'Basic Charts',
          '1 Broker Connection',
          'Custom Notifications',
          'Email Support'
        ],
      ),
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        price: 499.0,
        maxBrokers: 3,
        realTimeData: true,
        customNotifications: true,
        features: [
          'All Basic Features',
          'Real-time Data',
          '3 Broker Connections',
          'Advanced Charts',
          'Portfolio Analytics',
          'Priority Support'
        ],
      ),
      SubscriptionPlan(
        id: 'pro',
        name: 'Pro',
        price: 899.0,
        maxBrokers: -1, // Unlimited
        realTimeData: true,
        customNotifications: true,
        features: [
          'All Premium Features',
          'Unlimited Brokers',
          'Advanced Analytics',
          'Custom Indicators',
          'API Access',
          '24/7 Phone Support',
          'White-label Options'
        ],
      ),
    ];
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final double paidAmount;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.autoRenew,
    required this.paidAmount,
  });

  /// From JSON Map
  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? false,
      autoRenew: json['autoRenew'] ?? false,
      paidAmount: (json['paidAmount'] as num).toDouble(),
    );
  }

  /// To JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'paidAmount': paidAmount,
    };
  }
}
