// File: lib/utils/stock_converters.dart

import 'package:optionxi/DataModels/dm_stock_details.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';

/// Utility class for converting between different stock model types
class StockConverters {
  /// Converts StockModel to DataStockModel
  static DataStockModel convertStockToDataStock(StockModel stock) {
    // Determine the stock name
    String? stockName = totalStocks.containsKey(stock.stckname)
        ? totalStocks[stock.stckname]!['full_stock_name']
        : stock.stckname;

    return DataStockModel(
      close: stock.ltp, // ltp is the current price
      pclose: stock.ltp - stock.priceChange, // Calculate previous close
      high: stock.high,
      low: stock.low,
      open: stock.open,
      pcnt: stock.percentChange,
      sec: '', // Not available in StockModel, using empty string
      stckname: stockName ?? "",
      vol: stock.volume,
      symbol: stock.symbol,
    );
  }

  /// Converts DataStockModel to StockModel
  static StockModel convertDataStockToStock(DataStockModel dataStock) {
    final double priceChange = dataStock.close - dataStock.pclose;

    return StockModel(
      symbol: dataStock.symbol,
      stckname: dataStock.stckname,
      ltp: dataStock.close,
      open: dataStock.open,
      close: dataStock.close,
      high: dataStock.high,
      low: dataStock.low,
      volume: dataStock.vol,
      priceChange: priceChange,
      percentChange: dataStock.pcnt,
      isUp: priceChange >= 0,
    );
  }
}

// Helper function for backward compatibility with your existing code
DataStockModel convertDmStockToDataStockModel(StockModel stock) {
  return StockConverters.convertStockToDataStock(stock);
}
