import 'package:dio/dio.dart';
import 'upstox_datamodel.dart';
import 'upstox_api_service.dart';

class UpstoxRepository {
  final UpstoxApiService _apiService = UpstoxApiService();

  /// Get user profile information
  Future<UpstoxProfileModel> getProfile() async {
    try {
      return await _apiService.fetchProfile();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  /// Get portfolio holdings (long-term)
  Future<UpstoxHoldingsResponse> getHoldings() async {
    try {
      return await _apiService.fetchHoldings();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  /// Get portfolio positions (short-term)
  Future<UpstoxPositionsResponse> getPositions() async {
    try {
      return await _apiService.fetchPositions();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  // Get all orders
  Future<List<UpstoxOrderModel>> getOrders() async {
    try {
      return await _apiService.fetchOrders();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  /// Get funds and margin information
  Future<UpstoxFundsResponse> getFunds() async {
    try {
      return await _apiService.fetchFunds();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }
}
