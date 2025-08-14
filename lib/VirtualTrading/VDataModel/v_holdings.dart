// --- DATA MODELS ---
// NOTE: It's best practice to have these in separate files (e.g., 'models/holding_model.dart')
class Holding {
  final String symbol;
  final String segment;
  final int quantity;
  final double averagePrice;
  final DateTime updatedAt;

  Holding({
    required this.symbol,
    required this.segment,
    required this.quantity,
    required this.averagePrice,
    required this.updatedAt,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] ?? 'N/A',
      segment: json['segment'] ?? 'N/A',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      averagePrice: (json['average_price'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class TradeHistory {
  final String symbol;
  final String segment;
  final String transactionType;
  final double price;
  final double quantity;
  final double profitLoss;
  final bool isShortSell;
  final DateTime executionTime;

  TradeHistory({
    required this.symbol,
    required this.segment,
    required this.transactionType,
    required this.price,
    required this.quantity,
    required this.profitLoss,
    required this.isShortSell,
    required this.executionTime,
  });

  factory TradeHistory.fromJson(Map<String, dynamic> json) {
    return TradeHistory(
      symbol: json['symbol'] ?? 'N/A',
      segment: json['segment'] ?? 'N/A',
      transactionType: json['transaction_type'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      profitLoss: (json['profit_loss'] as num?)?.toDouble() ?? 0.0,
      isShortSell: (json['is_short_sell'] as bool?) ?? false,
      executionTime: json['execution_time'] != null
          ? DateTime.parse(json['execution_time'])
          : DateTime.now(),
    );
  }
}
