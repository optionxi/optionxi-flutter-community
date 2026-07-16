// Base API Response Model
class FyersApiResponse<T> {
  final String status;
  final int code;
  final String message;
  final T? data;

  FyersApiResponse({
    required this.status,
    required this.code,
    required this.message,
    this.data,
  });

  factory FyersApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return FyersApiResponse<T>(
      status: json['s'] ?? '',
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }
}

// Fyers Profile Model (Updated for v3)
class FyersProfileModel {
  final String name;
  final String? image;
  final String displayName;
  final String emailId;
  final String pan;
  final String fyId;
  final String pinChangeDate;
  final String mobileNumber;
  final bool totp;
  final String pwdChangeDate;
  final int pwdToExpire;
  final bool ddpiEnabled;
  final bool mtfEnabled;

  FyersProfileModel({
    required this.name,
    this.image,
    required this.displayName,
    required this.emailId,
    required this.pan,
    required this.fyId,
    required this.pinChangeDate,
    required this.mobileNumber,
    required this.totp,
    required this.pwdChangeDate,
    required this.pwdToExpire,
    required this.ddpiEnabled,
    required this.mtfEnabled,
  });

  factory FyersProfileModel.fromJson(Map<String, dynamic> json) {
    return FyersProfileModel(
      name: json['name'] ?? '',
      image: json['image'],
      displayName: json['display_name'] ?? '',
      emailId: json['email_id'] ?? '',
      pan: json['PAN'] ?? '',
      fyId: json['fy_id'] ?? '',
      pinChangeDate: json['pin_change_date'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      totp: json['totp'] ?? false,
      pwdChangeDate: json['pwd_change_date'] ?? '',
      pwdToExpire: json['pwd_to_expire'] ?? 0,
      ddpiEnabled: json['ddpi_enabled'] ?? false,
      mtfEnabled: json['mtf_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'display_name': displayName,
      'email_id': emailId,
      'PAN': pan,
      'fy_id': fyId,
      'pin_change_date': pinChangeDate,
      'mobile_number': mobileNumber,
      'totp': totp,
      'pwd_change_date': pwdChangeDate,
      'pwd_to_expire': pwdToExpire,
      'ddpi_enabled': ddpiEnabled,
      'mtf_enabled': mtfEnabled,
    };
  }
}

// Funds Models (Updated for v3)
class FyersFundsResponse {
  final String status;
  final int code;
  final String message;
  final List<FyersFundLimit> fundLimit;

  FyersFundsResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.fundLimit,
  });

  factory FyersFundsResponse.fromJson(Map<String, dynamic> json) {
    return FyersFundsResponse(
      status: json['s'] ?? '',
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      fundLimit: (json['fund_limit'] as List<dynamic>?)
              ?.map((fund) => FyersFundLimit.fromJson(fund))
              .toList() ??
          [],
    );
  }
}

class FyersFundLimit {
  final int id;
  final String title;
  final double equityAmount;
  final double commodityAmount;

  FyersFundLimit({
    required this.id,
    required this.title,
    required this.equityAmount,
    required this.commodityAmount,
  });

  factory FyersFundLimit.fromJson(Map<String, dynamic> json) {
    return FyersFundLimit(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      equityAmount: (json['equityAmount'] ?? 0).toDouble(),
      commodityAmount: (json['commodityAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'equityAmount': equityAmount,
      'commodityAmount': commodityAmount,
    };
  }
}

// Helper class to get specific fund types
class FyersFundsHelper {
  static FyersFundLimit? getTotalBalance(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 1).firstOrNull;
  }

  static FyersFundLimit? getUtilizedAmount(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 2).firstOrNull;
  }

  static FyersFundLimit? getClearBalance(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 3).firstOrNull;
  }

  static FyersFundLimit? getRealizedPnL(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 4).firstOrNull;
  }

  static FyersFundLimit? getCollaterals(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 5).firstOrNull;
  }

  static FyersFundLimit? getFundTransfer(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 6).firstOrNull;
  }

  static FyersFundLimit? getReceivables(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 7).firstOrNull;
  }

  static FyersFundLimit? getAdhocLimit(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 8).firstOrNull;
  }

  static FyersFundLimit? getLimitAtStartOfDay(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 9).firstOrNull;
  }

  static FyersFundLimit? getAvailableBalance(List<FyersFundLimit> fundLimits) {
    return fundLimits.where((fund) => fund.id == 10).firstOrNull;
  }
}

// Holdings Models (Updated for v3)
class FyersHoldingsResponse {
  final String status;
  final int code;
  final String message;
  final List<FyersHoldingModel> holdings;
  final FyersOverallSummary overall;

  FyersHoldingsResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.holdings,
    required this.overall,
  });

  factory FyersHoldingsResponse.fromJson(Map<String, dynamic> json) {
    return FyersHoldingsResponse(
      status: json['s'] ?? '',
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      holdings: safeList(json['holdings'])
          .map((holding) => FyersHoldingModel.fromJson(safeMap(holding)))
          .toList(),
      overall: FyersOverallSummary.fromJson(safeMap(json['overall'])),
    );
  }
}

class FyersHoldingModel {
  final String holdingType;
  final int quantity;
  final double costPrice;
  final double marketVal;
  final int remainingQuantity;
  final double pl;
  final double ltp;
  final int id;
  final int fyToken;
  final int exchange;
  final String symbol;
  final int segment;
  final String isin;
  final int qtyT1;
  final int remainingPledgeQuantity;
  final int collateralQuantity;

  FyersHoldingModel({
    required this.holdingType,
    required this.quantity,
    required this.costPrice,
    required this.marketVal,
    required this.remainingQuantity,
    required this.pl,
    required this.ltp,
    required this.id,
    required this.fyToken,
    required this.exchange,
    required this.symbol,
    required this.segment,
    required this.isin,
    required this.qtyT1,
    required this.remainingPledgeQuantity,
    required this.collateralQuantity,
  });

  factory FyersHoldingModel.fromJson(Map<String, dynamic> json) {
    return FyersHoldingModel(
      holdingType: json['holdingType']?.toString() ?? '',
      quantity: _safeInt(json['quantity']),
      costPrice: _safeDouble(json['costPrice']),
      marketVal: _safeDouble(json['marketVal']),
      remainingQuantity: _safeInt(json['remainingQuantity']),
      pl: _safeDouble(json['pl']),
      ltp: _safeDouble(json['ltp']),
      id: _safeInt(json['id']),
      fyToken: _safeInt(json['fyToken']),
      exchange: _safeInt(json['exchange']),
      symbol: json['symbol']?.toString() ?? '',
      segment: _safeInt(json['segment']),
      isin: json['isin']?.toString() ?? '',
      qtyT1: _safeInt(json['qty_t1']),
      remainingPledgeQuantity: _safeInt(json['remainingPledgeQuantity']),
      collateralQuantity: _safeInt(json['collateralQuantity']),
    );
  }

  // Helper method to safely convert to int
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method to safely convert to double
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'holdingType': holdingType,
      'quantity': quantity,
      'costPrice': costPrice,
      'marketVal': marketVal,
      'remainingQuantity': remainingQuantity,
      'pl': pl,
      'ltp': ltp,
      'id': id,
      'fyToken': fyToken,
      'exchange': exchange,
      'symbol': symbol,
      'segment': segment,
      'isin': isin,
      'qty_t1': qtyT1,
      'remainingPledgeQuantity': remainingPledgeQuantity,
      'collateralQuantity': collateralQuantity,
    };
  }

  // Helper getters
  double get pnlPercentage =>
      costPrice != 0 ? (pl / (costPrice * quantity)) * 100 : 0.0;
  double get totalInvestment => costPrice * quantity;
}

class FyersOverallSummary {
  final int countTotal;
  final double totalInvestment;
  final double totalCurrentValue;
  final double totalPl;
  final double pnlPerc;

  FyersOverallSummary({
    required this.countTotal,
    required this.totalInvestment,
    required this.totalCurrentValue,
    required this.totalPl,
    required this.pnlPerc,
  });

  factory FyersOverallSummary.fromJson(Map<String, dynamic> json) {
    return FyersOverallSummary(
      countTotal: _safeInt(json['count_total']),
      totalInvestment: _safeDouble(json['total_investment']),
      totalCurrentValue: _safeDouble(json['total_current_value']),
      totalPl: _safeDouble(json['total_pl']),
      pnlPerc: _safeDouble(json['pnl_perc']),
    );
  }
}

// Positions Models
class FyersPositionsResponse {
  final String status;
  final int code;
  final String message;
  final List<FyersPositionModel> netPositions;
  final FyersOverallPositionsSummary overall;

  FyersPositionsResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.netPositions,
    required this.overall,
  });

  factory FyersPositionsResponse.fromJson(Map<String, dynamic> json) {
    return FyersPositionsResponse(
      status: json['s'] ?? '',
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      netPositions: safeList(json['data'])
          .map((p) => FyersPositionModel.fromJson(safeMap(p)))
          .toList(),
      overall: FyersOverallPositionsSummary.fromJson(safeMap(json['overall'])),
    );
  }
}

class FyersPositionModel {
  final String symbol;
  final String id;
  final double buyAvg;
  final int buyQty;
  final double buyVal;
  final double sellAvg;
  final int sellQty;
  final double sellVal;
  final double netAvg;
  final int netQty;
  final int side;
  final int qty;
  final String productType;
  final double realizedProfit;
  final String crossCurrency;
  final int rbiRefRate;
  final int fyToken;
  final int exchange;
  final int segment;
  final int dayBuyQty;
  final int daySellQty;
  final int cfBuyQty;
  final int cfSellQty;
  final int qtyMultiCom;
  final double pl;
  final double unrealizedProfit;
  final double ltp;
  final int slNo;

  FyersPositionModel({
    required this.symbol,
    required this.id,
    required this.buyAvg,
    required this.buyQty,
    required this.buyVal,
    required this.sellAvg,
    required this.sellQty,
    required this.sellVal,
    required this.netAvg,
    required this.netQty,
    required this.side,
    required this.qty,
    required this.productType,
    required this.realizedProfit,
    required this.crossCurrency,
    required this.rbiRefRate,
    required this.fyToken,
    required this.exchange,
    required this.segment,
    required this.dayBuyQty,
    required this.daySellQty,
    required this.cfBuyQty,
    required this.cfSellQty,
    required this.qtyMultiCom,
    required this.pl,
    required this.unrealizedProfit,
    required this.ltp,
    required this.slNo,
  });

  factory FyersPositionModel.fromJson(Map<String, dynamic> json) {
    return FyersPositionModel(
      symbol: json['symbol']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      buyAvg: _safeDouble(json['buyAvg']),
      buyQty: _safeInt(json['buyQty']),
      buyVal: _safeDouble(json['buyVal']),
      sellAvg: _safeDouble(json['sellAvg']),
      sellQty: _safeInt(json['sellQty']),
      sellVal: _safeDouble(json['sellVal']),
      netAvg: _safeDouble(json['netAvg']),
      netQty: _safeInt(json['netQty']),
      side: _safeInt(json['side']),
      qty: _safeInt(json['qty']),
      productType: json['productType']?.toString() ?? '',
      realizedProfit: _safeDouble(json['realized_profit']),
      crossCurrency: json['crossCurrency']?.toString() ?? '',
      rbiRefRate: _safeInt(json['rbiRefRate']),
      fyToken: _safeInt(json['fyToken']),
      exchange: _safeInt(json['exchange']),
      segment: _safeInt(json['segment']),
      dayBuyQty: _safeInt(json['dayBuyQty']),
      daySellQty: _safeInt(json['daySellQty']),
      cfBuyQty: _safeInt(json['cfBuyQty']),
      cfSellQty: _safeInt(json['cfSellQty']),
      qtyMultiCom: _safeInt(json['qtyMulti_com']),
      pl: _safeDouble(json['pl']),
      unrealizedProfit: _safeDouble(json['unrealized_profit']),
      ltp: _safeDouble(json['ltp']),
      slNo: _safeInt(json['slNo']),
    );
  }
}

class FyersOverallPositionsSummary {
  final int totalCount;
  final double pnlRealized;
  final double pnlUnrealized;
  final double totalPnl;
  final double brokerage;

  FyersOverallPositionsSummary({
    required this.totalCount,
    required this.pnlRealized,
    required this.pnlUnrealized,
    required this.totalPnl,
    required this.brokerage,
  });

  factory FyersOverallPositionsSummary.fromJson(Map<String, dynamic> json) {
    return FyersOverallPositionsSummary(
      totalCount: _safeInt(json['total_count']),
      pnlRealized: _safeDouble(json['pnl_realized']),
      pnlUnrealized: _safeDouble(json['pnl_unrealized']),
      totalPnl: _safeDouble(json['total_pnl']),
      brokerage: _safeDouble(json['brokerage']),
    );
  }
}

// Helper function for safe list casting
List<T> safeList<T>(dynamic list) {
  if (list is List) {
    return list.cast<T>();
  }
  return [];
}

Map<String, dynamic> safeMap(dynamic map) {
  if (map is Map<String, dynamic>) {
    return map;
  }
  return {};
}

// Helper function for safe integer conversion
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

// Helper function for safe double conversion
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

class FyersOverallPositions {
  final int countTotal;
  final int countOpen;
  final double pnlRealized;
  final double pnlUnrealized;

  FyersOverallPositions({
    required this.countTotal,
    required this.countOpen,
    required this.pnlRealized,
    required this.pnlUnrealized,
  });

  factory FyersOverallPositions.fromJson(Map<String, dynamic> json) {
    return FyersOverallPositions(
      countTotal: json['count_total'] ?? 0,
      countOpen: json['count_open'] ?? 0,
      pnlRealized: (json['pl_realized'] ?? 0).toDouble(),
      pnlUnrealized: (json['pl_unrealized'] ?? 0).toDouble(),
    );
  }
}

// Updated Orders Model to match actual API response
class FyersOrderModel {
  final String clientId;
  final int exchange;
  final String fyToken;
  final String id;
  final int instrument;
  final bool offlineOrder;
  final String source;
  final int status;
  final int type;
  final String pan;
  final double limitPrice;
  final String productType;
  final int qty;
  final int disclosedQty;
  final int remainingQuantity;
  final int segment;
  final String symbol;
  final String description;
  final String exSym;
  final String orderDateTime;
  final int side;
  final String orderValidity;
  final double stopPrice;
  final double tradedPrice;
  final int filledQty;
  final String exchOrdId;
  final String message;
  final double ch;
  final double chp;
  final double lp;
  final String orderNumStatus;
  final int slNo;
  final String orderTag;

  FyersOrderModel({
    required this.clientId,
    required this.exchange,
    required this.fyToken,
    required this.id,
    required this.instrument,
    required this.offlineOrder,
    required this.source,
    required this.status,
    required this.type,
    required this.pan,
    required this.limitPrice,
    required this.productType,
    required this.qty,
    required this.disclosedQty,
    required this.remainingQuantity,
    required this.segment,
    required this.symbol,
    required this.description,
    required this.exSym,
    required this.orderDateTime,
    required this.side,
    required this.orderValidity,
    required this.stopPrice,
    required this.tradedPrice,
    required this.filledQty,
    required this.exchOrdId,
    required this.message,
    required this.ch,
    required this.chp,
    required this.lp,
    required this.orderNumStatus,
    required this.slNo,
    required this.orderTag,
  });

  factory FyersOrderModel.fromJson(Map<String, dynamic> json) {
    return FyersOrderModel(
      clientId: json['clientId'] ?? '',
      exchange: _safeInt(json['exchange']),
      fyToken: json['fyToken']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      instrument: _safeInt(json['instrument']),
      offlineOrder: json['offlineOrder'] ?? false,
      source: json['source'] ?? '',
      status: _safeInt(json['status']),
      type: _safeInt(json['type']),
      pan: json['pan'] ?? '',
      limitPrice: _safeDouble(json['limitPrice']),
      productType: json['productType'] ?? '',
      qty: _safeInt(json['qty']),
      disclosedQty: _safeInt(json['disclosedQty']),
      remainingQuantity: _safeInt(json['remainingQuantity']),
      segment: _safeInt(json['segment']),
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      exSym: json['ex_sym'] ?? '',
      orderDateTime: json['orderDateTime'] ?? '',
      side: _safeInt(json['side']),
      orderValidity: json['orderValidity'] ?? '',
      stopPrice: _safeDouble(json['stopPrice']),
      tradedPrice: _safeDouble(json['tradedPrice']),
      filledQty: _safeInt(json['filledQty']),
      exchOrdId: json['exchOrdId'] ?? '',
      message: json['message'] ?? '',
      ch: _safeDouble(json['ch']),
      chp: _safeDouble(json['chp']),
      lp: _safeDouble(json['lp']),
      orderNumStatus: json['orderNumStatus']?.toString() ?? '',
      slNo: _safeInt(json['slNo']),
      orderTag: json['orderTag'] ?? '',
    );
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper getters for compatibility with existing UI
  String get statusText {
    switch (status) {
      case 2:
        return 'FILLED';
      case 5:
        return 'REJECTED';
      case 6:
        return 'CANCELLED';
      case 1:
        return 'PENDING';
      default:
        return 'UNKNOWN';
    }
  }

  double get avgPrice => tradedPrice > 0 ? tradedPrice : limitPrice;
}
