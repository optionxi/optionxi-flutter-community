class JournalTradeHistory {
  final int id;
  final String suid;
  final String orderId;
  final String symbol;
  final String segment;
  final int quantity;
  final double charges;
  final double profitLoss;
  final DateTime exitDate; // exit_date in DB
  final bool isShortSell;
  final DateTime createdAt;
  final double exitPrice; // exit_price column in DB (nullable)
  final String timeframe;
  final DateTime entryDate;
  final double entryPrice; // entry_price column in DB
  final String? reason;
  final double? targetPrice;
  final double? stopLossPrice;

  JournalTradeHistory({
    required this.id,
    required this.suid,
    required this.orderId,
    required this.symbol,
    required this.segment,
    required this.quantity,
    required this.charges,
    required this.profitLoss,
    required this.exitDate,
    required this.isShortSell,
    required this.createdAt,
    required this.exitPrice,
    required this.timeframe,
    required this.entryDate,
    required this.entryPrice,
    this.reason,
    this.targetPrice,
    this.stopLossPrice,
  });

  factory JournalTradeHistory.fromJson(Map<String, dynamic> json) {
    return JournalTradeHistory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      suid: json['suid'] ?? '',
      orderId: json['order_id'] ?? '',
      symbol: json['symbol'] ?? 'N/A',
      segment: json['segment'] ?? 'N/A',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      charges: (json['charges'] as num?)?.toDouble() ?? 0.0,
      profitLoss: (json['profit_loss'] as num?)?.toDouble() ?? 0.0,
      exitDate: DateTime.tryParse(json['exit_date'] ?? '') ?? DateTime.now(),
      isShortSell: json['is_short_sell'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      exitPrice: (json['exit_price'] as num).toDouble(),
      timeframe: json['timeframe'] ?? '',
      entryDate: DateTime.tryParse(json['entry_date'] ?? '') ?? DateTime.now(),
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'],
      targetPrice: (json['target_price'] as num?)?.toDouble(),
      stopLossPrice: (json['stop_loss_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suid': suid,
      'order_id': orderId,
      'symbol': symbol,
      'segment': segment,
      'quantity': quantity,
      'charges': charges,
      'profit_loss': profitLoss,
      'exit_date': exitDate.toIso8601String(),
      'is_short_sell': isShortSell,
      'created_at': createdAt.toIso8601String(),
      'exit_price': exitPrice,
      'timeframe': timeframe,
      'entry_date': entryDate.toIso8601String(),
      'entry_price': entryPrice,
      'reason': reason,
      'target_price': targetPrice,
      'stop_loss_price': stopLossPrice,
    };
  }
}
