// --- DATA MODELS ---
// NOTE: It's best practice to have these in separate files (e.g., 'models/journal_user_holdings_model.dart')

class BasketUserHolding {
  final int? id;
  final String suid;
  final String symbol;
  final String segment;
  final int quantity;
  final double averagePrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String timeframe;
  final DateTime entryDate;
  final double entryPrice;
  final String? reason;
  final String? transactionType;
  final double? targetPrice;
  final double? stopLossPrice;
  final bool? isshort;

  BasketUserHolding({
    this.id,
    required this.suid,
    required this.symbol,
    required this.segment,
    required this.quantity,
    required this.averagePrice,
    required this.createdAt,
    required this.updatedAt,
    required this.timeframe,
    required this.entryDate,
    required this.entryPrice,
    this.reason,
    this.transactionType,
    this.targetPrice,
    this.stopLossPrice,
    this.isshort,
  });

  factory BasketUserHolding.fromJson(Map<String, dynamic> json) {
    return BasketUserHolding(
      id: json['id'] as int?,
      suid: json['suid'] ?? '',
      symbol: json['symbol'] ?? 'N/A',
      segment: json['segment'] ?? 'N/A',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      averagePrice: (json['average_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      timeframe: json['timeframe'] ?? '',
      entryDate: DateTime.tryParse(json['entry_date'] ?? '') ?? DateTime.now(),
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      targetPrice: (json['target_price'] as num?)?.toDouble(),
      stopLossPrice: (json['stop_loss_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'suid': suid,
      'symbol': symbol,
      'segment': segment,
      'quantity': quantity,
      'average_price': averagePrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'timeframe': timeframe,
      'entry_date': entryDate.toIso8601String(),
      'entry_price': entryPrice,
      'reason': reason,
      'target_price': targetPrice,
      'stop_loss_price': stopLossPrice,
    };
  }

  // Create a copy with updated fields
  BasketUserHolding copyWith(
      {int? id,
      String? suid,
      String? symbol,
      String? segment,
      int? quantity,
      double? averagePrice,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? timeframe,
      DateTime? entryDate,
      double? entryPrice,
      String? reason,
      double? targetPrice,
      double? stopLossPrice,
      bool? isshort}) {
    return BasketUserHolding(
      id: id ?? this.id,
      suid: suid ?? this.suid,
      symbol: symbol ?? this.symbol,
      segment: segment ?? this.segment,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeframe: timeframe ?? this.timeframe,
      entryDate: entryDate ?? this.entryDate,
      entryPrice: entryPrice ?? this.entryPrice,
      reason: reason ?? this.reason,
      targetPrice: targetPrice ?? this.targetPrice,
      stopLossPrice: stopLossPrice ?? this.stopLossPrice,
      isshort: isshort ?? this.isshort,
    );
  }

  @override
  String toString() {
    return 'JournalUserHoldings(id: $id, suid: $suid, symbol: $symbol, segment: $segment, quantity: $quantity, averagePrice: $averagePrice, timeframe: $timeframe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasketUserHolding &&
        other.id == id &&
        other.suid == suid &&
        other.symbol == symbol &&
        other.segment == segment;
  }

  @override
  int get hashCode {
    return Object.hash(id, suid, symbol, segment);
  }
}
