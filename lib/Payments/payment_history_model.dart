class PaymentHistory {
  final String id;
  final String userId;
  final String planId;
  final double amount;
  final DateTime date;
  final String status;
  final String transactionId;

  PaymentHistory({
    required this.id,
    required this.userId,
    required this.planId,
    required this.amount,
    required this.date,
    required this.status,
    required this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'transactionId': transactionId,
    };
  }

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'],
      userId: json['userId'],
      planId: json['planId'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      transactionId: json['transactionId'],
    );
  }
}
