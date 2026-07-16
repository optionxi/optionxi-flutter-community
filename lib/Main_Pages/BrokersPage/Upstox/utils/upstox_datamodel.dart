// Base API Response Model
class UpstoxApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  UpstoxApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UpstoxApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return UpstoxApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }
}

// Upstox Profile Model
class UpstoxProfileModel {
  final String userId;
  final String userName;
  final String email;
  final String broker;
  final String userType;
  final bool isActive;
  final bool poa;
  final bool ddpi;
  final List<String> exchanges;
  final List<String> orderTypes;
  final List<String> products;

  UpstoxProfileModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.broker,
    required this.userType,
    required this.isActive,
    required this.poa,
    required this.ddpi,
    required this.exchanges,
    required this.orderTypes,
    required this.products,
  });

  factory UpstoxProfileModel.fromJson(Map<String, dynamic> json) {
    return UpstoxProfileModel(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      email: json['email'] ?? '',
      broker: json['broker'] ?? '',
      userType: json['user_type'] ?? '',
      isActive: json['is_active'] ?? false,
      poa: json['poa'] ?? false,
      ddpi: json['ddpi'] ?? false,
      exchanges: (json['exchanges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      orderTypes: (json['order_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'email': email,
      'broker': broker,
      'user_type': userType,
      'is_active': isActive,
      'poa': poa,
      'ddpi': ddpi,
      'exchanges': exchanges,
      'order_types': orderTypes,
      'products': products,
    };
  }
}

// Upstox Funds Model
class UpstoxFundsResponse {
  final UpstoxFundSegment equity;
  final UpstoxFundSegment commodity;

  UpstoxFundsResponse({
    required this.equity,
    required this.commodity,
  });

  factory UpstoxFundsResponse.fromJson(Map<String, dynamic> json) {
    return UpstoxFundsResponse(
      equity: UpstoxFundSegment.fromJson(json['equity'] ?? {}),
      commodity: UpstoxFundSegment.fromJson(json['commodity'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equity': equity.toJson(),
      'commodity': commodity.toJson(),
    };
  }
}

class UpstoxFundSegment {
  final double availableMargin;
  final double usedMargin;
  final double payinAmount;
  final double spanMargin;
  final double adhocMargin;
  final double notionalCash;
  final double additionMargin;
  final double cashhMargin;
  final double collateralAmount;
  final double intradayPayin;
  final double exposureMargin;

  UpstoxFundSegment({
    required this.availableMargin,
    required this.usedMargin,
    required this.payinAmount,
    required this.spanMargin,
    required this.adhocMargin,
    required this.notionalCash,
    required this.additionMargin,
    required this.cashhMargin,
    required this.collateralAmount,
    required this.intradayPayin,
    required this.exposureMargin,
  });

  factory UpstoxFundSegment.fromJson(Map<String, dynamic> json) {
    return UpstoxFundSegment(
      availableMargin: (json['available_margin'] ?? 0).toDouble(),
      usedMargin: (json['used_margin'] ?? 0).toDouble(),
      payinAmount: (json['payin_amount'] ?? 0).toDouble(),
      spanMargin: (json['span_margin'] ?? 0).toDouble(),
      adhocMargin: (json['adhoc_margin'] ?? 0).toDouble(),
      notionalCash: (json['notional_cash'] ?? 0).toDouble(),
      additionMargin: (json['addition_margin'] ?? 0).toDouble(),
      cashhMargin: (json['cashh_margin'] ?? 0).toDouble(),
      collateralAmount: (json['collateral_amount'] ?? 0).toDouble(),
      intradayPayin: (json['intraday_payin'] ?? 0).toDouble(),
      exposureMargin: (json['exposure_margin'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available_margin': availableMargin,
      'used_margin': usedMargin,
      'payin_amount': payinAmount,
      'span_margin': spanMargin,
      'adhoc_margin': adhocMargin,
      'notional_cash': notionalCash,
      'addition_margin': additionMargin,
      'cashh_margin': cashhMargin,
      'collateral_amount': collateralAmount,
      'intraday_payin': intradayPayin,
      'exposure_margin': exposureMargin,
    };
  }
}

// Upstox Holdings Model
class UpstoxHoldingsResponse {
  final List<UpstoxHoldingModel> holdings;

  UpstoxHoldingsResponse({
    required this.holdings,
  });

  factory UpstoxHoldingsResponse.fromJson(List<dynamic> json) {
    return UpstoxHoldingsResponse(
      holdings:
          json.map((holding) => UpstoxHoldingModel.fromJson(holding)).toList(),
    );
  }

  // Calculate overall summary
  UpstoxOverallSummary get overall {
    double totalInvestment = 0;
    double totalCurrentValue = 0;
    double totalPnl = 0;

    for (var holding in holdings) {
      totalInvestment += holding.totalInvestment;
      totalCurrentValue += holding.currentValue;
      totalPnl += holding.pnl;
    }

    double pnlPercentage =
        totalInvestment != 0 ? (totalPnl / totalInvestment) * 100 : 0.0;

    return UpstoxOverallSummary(
      countTotal: holdings.length,
      totalInvestment: totalInvestment,
      totalCurrentValue: totalCurrentValue,
      totalPnl: totalPnl,
      pnlPercentage: pnlPercentage,
    );
  }
}

class UpstoxHoldingModel {
  final String instrumentToken;
  final String isin;
  final String cnc;
  final String collateralType;
  final String collateralQty;
  final String company;
  final double lastPrice;
  final double closePrice;
  final double pnl;
  final double dayChange;
  final double dayChangePercentage;
  final int quantity;
  final double averagePrice;
  final String tradingsymbol;
  final String exchange;

  UpstoxHoldingModel({
    required this.instrumentToken,
    required this.isin,
    required this.cnc,
    required this.collateralType,
    required this.collateralQty,
    required this.company,
    required this.lastPrice,
    required this.closePrice,
    required this.pnl,
    required this.dayChange,
    required this.dayChangePercentage,
    required this.quantity,
    required this.averagePrice,
    required this.tradingsymbol,
    required this.exchange,
  });

  factory UpstoxHoldingModel.fromJson(Map<String, dynamic> json) {
    return UpstoxHoldingModel(
      instrumentToken: json['instrument_token'] ?? '',
      isin: json['isin'] ?? '',
      cnc: json['cnc'] ?? '',
      collateralType: json['collateral_type'] ?? '',
      collateralQty: json['collateral_qty'] ?? '',
      company: json['company'] ?? '',
      lastPrice: (json['last_price'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? 0).toDouble(),
      pnl: (json['pnl'] ?? 0).toDouble(),
      dayChange: (json['day_change'] ?? 0).toDouble(),
      dayChangePercentage: (json['day_change_percentage'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      tradingsymbol: json['tradingsymbol'] ?? '',
      exchange: json['exchange'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instrument_token': instrumentToken,
      'isin': isin,
      'cnc': cnc,
      'collateral_type': collateralType,
      'collateral_qty': collateralQty,
      'company': company,
      'last_price': lastPrice,
      'close_price': closePrice,
      'pnl': pnl,
      'day_change': dayChange,
      'day_change_percentage': dayChangePercentage,
      'quantity': quantity,
      'average_price': averagePrice,
      'tradingsymbol': tradingsymbol,
      'exchange': exchange,
    };
  }

  // Helper getters
  double get currentValue => lastPrice * quantity;
  double get totalInvestment => averagePrice * quantity;
  double get pnlPercentage =>
      totalInvestment != 0 ? (pnl / totalInvestment) * 100 : 0.0;
}

class UpstoxOverallSummary {
  final int countTotal;
  final double totalInvestment;
  final double totalCurrentValue;
  final double totalPnl;
  final double pnlPercentage;

  UpstoxOverallSummary({
    required this.countTotal,
    required this.totalInvestment,
    required this.totalCurrentValue,
    required this.totalPnl,
    required this.pnlPercentage,
  });
}

// Upstox Positions Model
class UpstoxPositionsResponse {
  final List<UpstoxPositionModel> positions;

  UpstoxPositionsResponse({
    required this.positions,
  });

  factory UpstoxPositionsResponse.fromJson(List<dynamic> json) {
    return UpstoxPositionsResponse(
      positions: json
          .map((position) => UpstoxPositionModel.fromJson(position))
          .toList(),
    );
  }

  // Calculate overall summary
  UpstoxOverallPositions get overall {
    double pnlRealized = 0;
    double pnlUnrealized = 0;
    int countOpen = 0;

    for (var position in positions) {
      pnlUnrealized += position.unrealisedPnl;
      pnlRealized += position.realisedPnl;
      if (position.quantity != 0) {
        countOpen++;
      }
    }

    return UpstoxOverallPositions(
      countTotal: positions.length,
      countOpen: countOpen,
      pnlRealized: pnlRealized,
      pnlUnrealized: pnlUnrealized,
    );
  }
}

class UpstoxPositionModel {
  final String exchange;
  final double multiplier;
  final String instrumentToken;
  final String productType;
  final String tradingsymbol;
  final double averagePrice;
  final double buyPrice;
  final double sellPrice;
  final double lastPrice;
  final double closePrice;
  final double pnl;
  final double dayChange;
  final double dayChangePercentage;
  final int buyQuantity;
  final int sellQuantity;
  final int quantity;
  final double realisedPnl;
  final double unrealisedPnl;
  final double buyValue;
  final double sellValue;

  UpstoxPositionModel({
    required this.exchange,
    required this.multiplier,
    required this.instrumentToken,
    required this.productType,
    required this.tradingsymbol,
    required this.averagePrice,
    required this.buyPrice,
    required this.sellPrice,
    required this.lastPrice,
    required this.closePrice,
    required this.pnl,
    required this.dayChange,
    required this.dayChangePercentage,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.quantity,
    required this.realisedPnl,
    required this.unrealisedPnl,
    required this.buyValue,
    required this.sellValue,
  });

  factory UpstoxPositionModel.fromJson(Map<String, dynamic> json) {
    return UpstoxPositionModel(
      exchange: json['exchange'] ?? '',
      multiplier: (json['multiplier'] ?? 0).toDouble(),
      instrumentToken: json['instrument_token'] ?? '',
      productType: json['product_type'] ?? '',
      tradingsymbol: json['tradingsymbol'] ?? '',
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      buyPrice: (json['buy_price'] ?? 0).toDouble(),
      sellPrice: (json['sell_price'] ?? 0).toDouble(),
      lastPrice: (json['last_price'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? 0).toDouble(),
      pnl: (json['pnl'] ?? 0).toDouble(),
      dayChange: (json['day_change'] ?? 0).toDouble(),
      dayChangePercentage: (json['day_change_percentage'] ?? 0).toDouble(),
      buyQuantity: (json['buy_quantity'] ?? 0).toInt(),
      sellQuantity: (json['sell_quantity'] ?? 0).toInt(),
      quantity: (json['quantity'] ?? 0).toInt(),
      realisedPnl: (json['realised_pnl'] ?? 0).toDouble(),
      unrealisedPnl: (json['unrealised_pnl'] ?? 0).toDouble(),
      buyValue: (json['buy_value'] ?? 0).toDouble(),
      sellValue: (json['sell_value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exchange': exchange,
      'multiplier': multiplier,
      'instrument_token': instrumentToken,
      'product_type': productType,
      'tradingsymbol': tradingsymbol,
      'average_price': averagePrice,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'last_price': lastPrice,
      'close_price': closePrice,
      'pnl': pnl,
      'day_change': dayChange,
      'day_change_percentage': dayChangePercentage,
      'buy_quantity': buyQuantity,
      'sell_quantity': sellQuantity,
      'quantity': quantity,
      'realised_pnl': realisedPnl,
      'unrealised_pnl': unrealisedPnl,
      'buy_value': buyValue,
      'sell_value': sellValue,
    };
  }
}

class UpstoxOverallPositions {
  final int countTotal;
  final int countOpen;
  final double pnlRealized;
  final double pnlUnrealized;

  UpstoxOverallPositions({
    required this.countTotal,
    required this.countOpen,
    required this.pnlRealized,
    required this.pnlUnrealized,
  });
}

// Upstox Orders Model
class UpstoxOrderModel {
  final String orderId;
  final String exchange;
  final String instrumentToken;
  final String tradingsymbol;
  final String
      tradingSymbol; // API returns both tradingsymbol and trading_symbol
  final String orderType;
  final String transactionType;
  final String product; // Changed from productType to product
  final String status; // Changed from orderStatus to status
  final String variety;
  final int quantity;
  final int filledQuantity;
  final int pendingQuantity;
  final double price;
  final double triggerPrice;
  final double averagePrice;
  final String validity;
  final String orderTimestamp;
  final String? exchangeTimestamp; // Can be null
  final String exchangeOrderId;
  final String? parentOrderId; // Can be null
  final String? statusMessage; // Can be null
  final String? statusMessageRaw; // New field
  final double disclosedQuantity;
  final String? tag; // Can be null
  final String? guid; // New field
  final String placedBy; // New field
  final bool isAmo; // New field
  final String orderRequestId; // New field
  final String orderRefId; // New field

  UpstoxOrderModel({
    required this.orderId,
    required this.exchange,
    required this.instrumentToken,
    required this.tradingsymbol,
    required this.tradingSymbol,
    required this.orderType,
    required this.transactionType,
    required this.product,
    required this.status,
    required this.variety,
    required this.quantity,
    required this.filledQuantity,
    required this.pendingQuantity,
    required this.price,
    required this.triggerPrice,
    required this.averagePrice,
    required this.validity,
    required this.orderTimestamp,
    this.exchangeTimestamp,
    required this.exchangeOrderId,
    this.parentOrderId,
    this.statusMessage,
    this.statusMessageRaw,
    required this.disclosedQuantity,
    this.tag,
    this.guid,
    required this.placedBy,
    required this.isAmo,
    required this.orderRequestId,
    required this.orderRefId,
  });

  factory UpstoxOrderModel.fromJson(Map<String, dynamic> json) {
    return UpstoxOrderModel(
      orderId: json['order_id'] ?? '',
      exchange: json['exchange'] ?? '',
      instrumentToken: json['instrument_token'] ?? '',
      tradingsymbol: json['tradingsymbol'] ?? '',
      tradingSymbol: json['trading_symbol'] ?? '',
      orderType: json['order_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      product: json['product'] ?? '',
      status: json['status'] ?? '',
      variety: json['variety'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      filledQuantity: (json['filled_quantity'] ?? 0).toInt(),
      pendingQuantity: (json['pending_quantity'] ?? 0).toInt(),
      price: (json['price'] ?? 0).toDouble(),
      triggerPrice: (json['trigger_price'] ?? 0).toDouble(),
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      validity: json['validity'] ?? '',
      orderTimestamp: json['order_timestamp'] ?? '',
      exchangeTimestamp: json['exchange_timestamp'],
      exchangeOrderId: json['exchange_order_id'] ?? '',
      parentOrderId: json['parent_order_id'],
      statusMessage: json['status_message'],
      statusMessageRaw: json['status_message_raw'],
      disclosedQuantity: (json['disclosed_quantity'] ?? 0).toDouble(),
      tag: json['tag'],
      guid: json['guid'],
      placedBy: json['placed_by'] ?? '',
      isAmo: json['is_amo'] ?? false,
      orderRequestId: json['order_request_id'] ?? '',
      orderRefId: json['order_ref_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'exchange': exchange,
      'instrument_token': instrumentToken,
      'tradingsymbol': tradingsymbol,
      'trading_symbol': tradingSymbol,
      'order_type': orderType,
      'transaction_type': transactionType,
      'product': product,
      'status': status,
      'variety': variety,
      'quantity': quantity,
      'filled_quantity': filledQuantity,
      'pending_quantity': pendingQuantity,
      'price': price,
      'trigger_price': triggerPrice,
      'average_price': averagePrice,
      'validity': validity,
      'order_timestamp': orderTimestamp,
      'exchange_timestamp': exchangeTimestamp,
      'exchange_order_id': exchangeOrderId,
      'parent_order_id': parentOrderId,
      'status_message': statusMessage,
      'status_message_raw': statusMessageRaw,
      'disclosed_quantity': disclosedQuantity,
      'tag': tag,
      'guid': guid,
      'placed_by': placedBy,
      'is_amo': isAmo,
      'order_request_id': orderRequestId,
      'order_ref_id': orderRefId,
    };
  }

  // Helper getters
  double get totalValue =>
      averagePrice > 0 ? averagePrice * filledQuantity : price * quantity;
  bool get isBuy => transactionType.toUpperCase() == 'BUY';
  bool get isSell => transactionType.toUpperCase() == 'SELL';
  bool get isComplete => status.toLowerCase() == 'complete';
  bool get isPending =>
      ['open', 'pending', 'trigger pending'].contains(status.toLowerCase());
  bool get isCancelled =>
      ['cancelled', 'rejected'].contains(status.toLowerCase());
}

// NEW: Upstox Trade Model (matches your API response)
class UpstoxTradeModel {
  final String tradeId;
  final String orderId;
  final String orderRefId;
  final String exchange;
  final String instrumentToken;
  final String tradingsymbol;
  final String
      tradingSymbol; // API returns both tradingsymbol and trading_symbol
  final String transactionType;
  final String product;
  final String orderType;
  final int quantity;
  final double averagePrice;
  final String tradeTimestamp;
  final String orderTimestamp;
  final String exchangeTimestamp;
  final String exchangeOrderId;

  UpstoxTradeModel({
    required this.tradeId,
    required this.orderId,
    required this.orderRefId,
    required this.exchange,
    required this.instrumentToken,
    required this.tradingsymbol,
    required this.tradingSymbol,
    required this.transactionType,
    required this.product,
    required this.orderType,
    required this.quantity,
    required this.averagePrice,
    required this.tradeTimestamp,
    required this.orderTimestamp,
    required this.exchangeTimestamp,
    required this.exchangeOrderId,
  });

  factory UpstoxTradeModel.fromJson(Map<String, dynamic> json) {
    return UpstoxTradeModel(
      tradeId: json['trade_id'] ?? '',
      orderId: json['order_id'] ?? '',
      orderRefId: json['order_ref_id'] ?? '',
      exchange: json['exchange'] ?? '',
      instrumentToken: json['instrument_token'] ?? '',
      tradingsymbol: json['tradingsymbol'] ?? '',
      tradingSymbol: json['trading_symbol'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      product: json['product'] ?? '',
      orderType: json['order_type'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      tradeTimestamp: json['trade_timestamp'] ?? '',
      orderTimestamp: json['order_timestamp'] ?? '',
      exchangeTimestamp: json['exchange_timestamp'] ?? '',
      exchangeOrderId: json['exchange_order_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trade_id': tradeId,
      'order_id': orderId,
      'order_ref_id': orderRefId,
      'exchange': exchange,
      'instrument_token': instrumentToken,
      'tradingsymbol': tradingsymbol,
      'trading_symbol': tradingSymbol,
      'transaction_type': transactionType,
      'product': product,
      'order_type': orderType,
      'quantity': quantity,
      'average_price': averagePrice,
      'trade_timestamp': tradeTimestamp,
      'order_timestamp': orderTimestamp,
      'exchange_timestamp': exchangeTimestamp,
      'exchange_order_id': exchangeOrderId,
    };
  }

  // Helper getters
  double get totalValue => averagePrice * quantity;
  bool get isBuy => transactionType.toUpperCase() == 'BUY';
  bool get isSell => transactionType.toUpperCase() == 'SELL';
}

// Upstox Trades Response
class UpstoxTradesResponse {
  final List<UpstoxTradeModel> trades;

  UpstoxTradesResponse({
    required this.trades,
  });

  factory UpstoxTradesResponse.fromJson(List<dynamic> json) {
    return UpstoxTradesResponse(
      trades: json.map((trade) => UpstoxTradeModel.fromJson(trade)).toList(),
    );
  }

  // Calculate summary
  UpstoxTradesSummary get summary {
    double totalBuyValue = 0;
    double totalSellValue = 0;
    int buyTrades = 0;
    int sellTrades = 0;

    for (var trade in trades) {
      if (trade.isBuy) {
        totalBuyValue += trade.totalValue;
        buyTrades++;
      } else if (trade.isSell) {
        totalSellValue += trade.totalValue;
        sellTrades++;
      }
    }

    return UpstoxTradesSummary(
      totalTrades: trades.length,
      buyTrades: buyTrades,
      sellTrades: sellTrades,
      totalBuyValue: totalBuyValue,
      totalSellValue: totalSellValue,
      netValue: totalSellValue - totalBuyValue,
    );
  }
}

class UpstoxTradesSummary {
  final int totalTrades;
  final int buyTrades;
  final int sellTrades;
  final double totalBuyValue;
  final double totalSellValue;
  final double netValue;

  UpstoxTradesSummary({
    required this.totalTrades,
    required this.buyTrades,
    required this.sellTrades,
    required this.totalBuyValue,
    required this.totalSellValue,
    required this.netValue,
  });
}

// Upstox Brokerage Model
class UpstoxBrokerageModel {
  final double brokerage;
  final double taxes;
  final double charges;
  final double total;

  UpstoxBrokerageModel({
    required this.brokerage,
    required this.taxes,
    required this.charges,
    required this.total,
  });

  factory UpstoxBrokerageModel.fromJson(Map<String, dynamic> json) {
    return UpstoxBrokerageModel(
      brokerage: (json['brokerage'] ?? 0).toDouble(),
      taxes: (json['taxes'] ?? 0).toDouble(),
      charges: (json['charges'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brokerage': brokerage,
      'taxes': taxes,
      'charges': charges,
      'total': total,
    };
  }
}

// Helper function for safe map conversion
Map<String, dynamic> safeMap(dynamic json) {
  if (json is Map<String, dynamic>) return json;
  return {}; // return empty map if it's [] or null
}
