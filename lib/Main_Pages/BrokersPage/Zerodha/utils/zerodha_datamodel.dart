// ─────────────────────────────────────────────────────────────
//  zerodha_datamodel.dart
//  All Zerodha data models.
//  Fix: OrderModel now includes triggerPrice and validity,
//       required by ZerodhaOrderEditPage.
// ─────────────────────────────────────────────────────────────

// ── Holding ───────────────────────────────────────────────────

class HoldingModel {
  final String tradingSymbol;
  final String exchange;
  final int instrumentToken;
  final String isin;
  final String product;
  final double price;
  final int quantity;
  final int usedQuantity;
  final int t1Quantity;
  final int realisedQuantity;
  final int authorisedQuantity;
  final String authorisedDate;
  final int openingQuantity;
  final int shortQuantity;
  final int collateralQuantity;
  final String collateralType;
  final bool discrepancy;
  final double averagePrice;
  final double lastPrice;
  final double closePrice;
  final double pnl;
  final double dayChange;
  final double dayChangePercentage;
  final Map<String, dynamic>? mtf;

  HoldingModel({
    required this.tradingSymbol,
    required this.exchange,
    required this.instrumentToken,
    required this.isin,
    required this.product,
    required this.price,
    required this.quantity,
    required this.usedQuantity,
    required this.t1Quantity,
    required this.realisedQuantity,
    required this.authorisedQuantity,
    required this.authorisedDate,
    required this.openingQuantity,
    required this.shortQuantity,
    required this.collateralQuantity,
    required this.collateralType,
    required this.discrepancy,
    required this.averagePrice,
    required this.lastPrice,
    required this.closePrice,
    required this.pnl,
    required this.dayChange,
    required this.dayChangePercentage,
    this.mtf,
  });

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      tradingSymbol: json['tradingsymbol'] ?? '',
      exchange: json['exchange'] ?? '',
      instrumentToken: json['instrument_token'] ?? 0,
      isin: json['isin'] ?? '',
      product: json['product'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      usedQuantity: json['used_quantity'] ?? 0,
      t1Quantity: json['t1_quantity'] ?? 0,
      realisedQuantity: json['realised_quantity'] ?? 0,
      authorisedQuantity: json['authorised_quantity'] ?? 0,
      authorisedDate: json['authorised_date'] ?? '',
      openingQuantity: json['opening_quantity'] ?? 0,
      shortQuantity: json['short_quantity'] ?? 0,
      collateralQuantity: json['collateral_quantity'] ?? 0,
      collateralType: json['collateral_type'] ?? '',
      discrepancy: json['discrepancy'] ?? false,
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      lastPrice: (json['last_price'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? 0).toDouble(),
      pnl: (json['pnl'] ?? 0).toDouble(),
      dayChange: (json['day_change'] ?? 0).toDouble(),
      dayChangePercentage: (json['day_change_percentage'] ?? 0).toDouble(),
      mtf: json['mtf'] as Map<String, dynamic>?,
    );
  }

  int get netQuantity => quantity;
  int get availableQuantity => quantity - usedQuantity;
  bool get hasT1Holdings => t1Quantity > 0;
  bool get isCollateral => collateralQuantity > 0;

  double get investmentValue => averagePrice * (quantity + t1Quantity);
  double get currentValue => lastPrice * (quantity + t1Quantity);
  double get pnlPercentage =>
      investmentValue > 0 ? (pnl / investmentValue) * 100 : 0;
  double get totalValue => currentValue;
  bool get isProfit => pnl >= 0;

  @override
  String toString() =>
      'HoldingModel(symbol: $tradingSymbol, qty: $quantity, avg: $averagePrice, ltp: $lastPrice, pnl: $pnl)';
}

// ── Position ──────────────────────────────────────────────────

class PositionModel {
  final String tradingSymbol;
  final String exchange;
  final int instrumentToken;
  final String product;
  final int quantity;
  final int overnightQuantity;
  final int multiplier;
  final double averagePrice;
  final double closePrice;
  final double lastPrice;
  final double value;
  final double pnl;
  final double m2m;
  final double unrealised;
  final double realised;

  PositionModel({
    required this.tradingSymbol,
    required this.exchange,
    required this.instrumentToken,
    required this.product,
    required this.quantity,
    required this.overnightQuantity,
    required this.multiplier,
    required this.averagePrice,
    required this.closePrice,
    required this.lastPrice,
    required this.value,
    required this.pnl,
    required this.m2m,
    required this.unrealised,
    required this.realised,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      tradingSymbol: json['tradingsymbol'] ?? '',
      exchange: json['exchange'] ?? '',
      instrumentToken: json['instrument_token'] ?? 0,
      product: json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
      overnightQuantity: json['overnight_quantity'] ?? 0,
      multiplier: json['multiplier'] ?? 1,
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? 0).toDouble(),
      lastPrice: (json['last_price'] ?? 0).toDouble(),
      value: (json['value'] ?? 0).toDouble(),
      pnl: (json['pnl'] ?? 0).toDouble(),
      m2m: (json['m2m'] ?? 0).toDouble(),
      unrealised: (json['unrealised'] ?? 0).toDouble(),
      realised: (json['realised'] ?? 0).toDouble(),
    );
  }
}

// ── Order ─────────────────────────────────────────────────────
//
// FIXED: Added `triggerPrice` and `validity` fields.
//
// Kite API response keys:
//   trigger_price  → triggerPrice  (double, 0.0 when unused)
//   validity       → validity      (String, e.g. "DAY" | "IOC" | "GTC")
//
// Both fields are used by ZerodhaOrderEditPage to pre-fill the
// modify form and detect changes in _DiffCard.

class OrderModel {
  final String orderId;
  final String tradingSymbol;
  final String status;
  final String orderType;
  final String transactionType;
  final String exchange;
  final int quantity;
  final int filledQuantity;
  final int pendingQuantity;
  final double price;
  final double triggerPrice; // ← ADDED
  final double averagePrice;
  final String validity; // ← ADDED
  final String orderTimestamp;
  final String? statusMessage;
  final String product;
  final String variety;

  OrderModel({
    required this.orderId,
    required this.tradingSymbol,
    required this.status,
    required this.orderType,
    required this.transactionType,
    required this.exchange,
    required this.quantity,
    required this.filledQuantity,
    required this.pendingQuantity,
    required this.price,
    required this.triggerPrice, // ← ADDED
    required this.averagePrice,
    required this.validity, // ← ADDED
    required this.orderTimestamp,
    this.statusMessage,
    required this.product,
    required this.variety,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? '',
      tradingSymbol: json['tradingsymbol'] ?? '',
      status: json['status'] ?? '',
      orderType: json['order_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      exchange: json['exchange'] ?? '',
      quantity: json['quantity'] ?? 0,
      filledQuantity: json['filled_quantity'] ?? 0,
      pendingQuantity: json['pending_quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      triggerPrice: (json['trigger_price'] ?? 0).toDouble(), // ← ADDED
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      validity: json['validity'] ?? 'DAY', // ← ADDED
      orderTimestamp: json['order_timestamp'] ?? '',
      statusMessage: json['status_message'],
      product: json['product'] ?? '',
      variety: json['variety'] ?? 'regular',
    );
  }
}

// ── Kite User Profile ─────────────────────────────────────────

class KiteUserProfile {
  final String? userId;
  final String? userType;
  final String? email;
  final String? userName;
  final String? userShortname;
  final String? broker;
  final List<String>? exchanges;
  final List<String>? products;
  final List<String>? orderTypes;
  final String? avatarUrl;
  final KiteMeta? meta;

  KiteUserProfile({
    this.userId,
    this.userType,
    this.email,
    this.userName,
    this.userShortname,
    this.broker,
    this.exchanges,
    this.products,
    this.orderTypes,
    this.avatarUrl,
    this.meta,
  });

  factory KiteUserProfile.fromJson(Map<String, dynamic> json) {
    return KiteUserProfile(
      userId: json['user_id'],
      userType: json['user_type'],
      email: json['email'],
      userName: json['user_name'],
      userShortname: json['user_shortname'],
      broker: json['broker'],
      exchanges: json['exchanges']?.cast<String>(),
      products: json['products']?.cast<String>(),
      orderTypes: json['order_types']?.cast<String>(),
      avatarUrl: json['avatar_url'],
      meta: json['meta'] != null ? KiteMeta.fromJson(json['meta']) : null,
    );
  }
}

class KiteMeta {
  final String? dematConsent;

  KiteMeta({this.dematConsent});

  factory KiteMeta.fromJson(Map<String, dynamic> json) {
    return KiteMeta(dematConsent: json['demat_consent']);
  }
}
