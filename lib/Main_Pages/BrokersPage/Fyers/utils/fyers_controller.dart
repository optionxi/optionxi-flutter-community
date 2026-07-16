import 'package:dio/dio.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_datamodel.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_api_service.dart';

class FyersRepository {
  final FyersApiService _apiService = FyersApiService();

  Future<FyersProfileModel> getProfile() async {
    try {
      return await _apiService.fetchProfile();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<FyersHoldingsResponse> getHoldings() async {
    try {
      return await _apiService.fetchHoldings();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<FyersPositionsResponse> getPositions() async {
    try {
      return await _apiService.fetchPositions();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<List<FyersOrderModel>> getOrders() async {
    try {
      return await _apiService.fetchOrders();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }

  Future<FyersFundsResponse> getFunds() async {
    try {
      return await _apiService.fetchFunds();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    }
  }
}
