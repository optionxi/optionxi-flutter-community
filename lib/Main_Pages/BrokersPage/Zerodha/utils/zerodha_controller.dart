// Example usage in your widgets/controllers
import 'package:dio/dio.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_api_service.dart';

class ZerodhaRepository {
  final ZerodhaApiService _apiService = ZerodhaApiService();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      return await _apiService.fetchProfile();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<List<HoldingModel>> getHoldings() async {
    try {
      return await _apiService.fetchHoldings();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<List<PositionModel>> getPositions() async {
    try {
      return await _apiService.fetchPositions();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<List<OrderModel>> getOrders() async {
    try {
      return await _apiService.fetchOrders();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }
}
