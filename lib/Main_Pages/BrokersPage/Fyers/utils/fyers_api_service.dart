import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_datamodel.dart';

class FyersApiService {
  late final Dio _dio;
  static String baseUrl = dotenv.env['FYERS_URL']!;

  FyersApiService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptor for Firebase token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get Firebase token and add to headers
        final firebaseToken = await _getFirebaseToken();
        if (firebaseToken != null) {
          options.headers['Authorization'] = 'Bearer $firebaseToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Get Firebase ID token
  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }

  /// Fetch user profile
  Future<FyersProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get('/profile');

      if (response.data['success'] == true) {
        return FyersProfileModel.fromJson(response.data['data']['data']);
      } else {
        throw Exception('Failed to fetch profile: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  /// Fetch portfolio holdings
  Future<FyersHoldingsResponse> fetchHoldings() async {
    try {
      final response = await _dio.get('/portfolio/holdings');

      if (response.data['success'] == true) {
        // Handle the case where data is directly a list of holdings
        var data = response.data['data'];

        if (data is List) {
          // If data is a list, create a proper structure
          Map<String, dynamic> formattedData = {
            'holdings': data,
            'overall': {
              'count_total': data.length,
              'total_investment': 0.0,
              'total_current_value': 0.0,
              'total_pl': 0.0,
              'pnl_perc': 0.0,
            }
          };

          // Calculate overall summary from holdings using safe conversion
          double totalInvestment = 0.0;
          double totalCurrentValue = 0.0;
          double totalPl = 0.0;

          for (var holding in data) {
            if (holding is Map<String, dynamic>) {
              double costPrice = _safeDouble(holding['costPrice']);
              int quantity = _safeInt(holding['quantity']);
              double marketVal = _safeDouble(holding['marketVal']);
              double pl = _safeDouble(holding['pl']);

              totalInvestment += costPrice * quantity;
              totalCurrentValue += marketVal;
              totalPl += pl;
            }
          }

          formattedData['overall'] = {
            'count_total': data.length,
            'total_investment': totalInvestment,
            'total_current_value': totalCurrentValue,
            'total_pl': totalPl,
            'pnl_perc':
                totalInvestment != 0 ? (totalPl / totalInvestment) * 100 : 0.0,
          };

          return FyersHoldingsResponse.fromJson(formattedData);
        } else {
          // If data is already in the expected format
          return FyersHoldingsResponse.fromJson(safeMap(data));
        }
      } else {
        throw Exception('Failed to fetch holdings: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching holdings: $e');
      rethrow;
    }
  }

// Helper methods for safe type conversion (add these to your class)
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

  /// Fetch portfolio positions
  Future<FyersPositionsResponse> fetchPositions() async {
    try {
      final response = await _dio.get('/portfolio/positions');

      if (response.data['success'] == true) {
        // The 'overall' summary is not provided in the positions API response,
        // so we will calculate it manually.
        var positionsList = response.data['data'];

        if (positionsList is List) {
          double totalPl = 0.0;
          double totalRealizedPl = 0.0;
          double totalUnrealizedPl = 0.0;

          // Loop through each position to calculate the totals
          for (var position in positionsList) {
            if (position is Map<String, dynamic>) {
              totalPl += _safeDouble(position['pl']);
              totalRealizedPl += _safeDouble(position['realized_profit']);
              totalUnrealizedPl += _safeDouble(position['unrealized_profit']);
            }
          }

          // Create a new map with the required structure for our model
          Map<String, dynamic> formattedData = {
            's': 'ok', // Manually setting status for the model
            'code': 200, // Manually setting code for the model
            'message':
                response.data['message'] ?? 'Positions fetched successfully',
            'data': positionsList, // The original list of positions
            'overall': {
              'total_count': positionsList.length,
              'pnl_realized': totalRealizedPl,
              'pnl_unrealized': totalUnrealizedPl,
              'total_pnl': totalPl,
              'brokerage':
                  0.0, // Note: Brokerage data is not available per position
            }
          };

          return FyersPositionsResponse.fromJson(formattedData);
        } else {
          throw Exception('Positions data is not a list.');
        }
      } else {
        throw Exception(
            'Failed to fetch positions: ${response.data['message']}');
      }
    } catch (e) {
      print('Error fetching positions: $e');
      rethrow;
    }
  }

  /// Fetch orders
  Future<List<FyersOrderModel>> fetchOrders() async {
    try {
      final response = await _dio.get('/orders');

      if (response.data['success'] == true) {
        final data = safeList(response.data['data']); // Ensure it's a list
        // Map each JSON object into FyersOrderModel
        final orders = data
            .map((json) => FyersOrderModel.fromJson(safeMap(json)))
            .toList();

        return orders;
      } else {
        throw Exception('Failed to fetch orders: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Fetch funds/margins
  Future<FyersFundsResponse> fetchFunds() async {
    try {
      final response = await _dio.get('/funds');

      if (response.data['success'] == true) {
        return FyersFundsResponse.fromJson(
            response.data['data']['data']['fund_limit']);
      } else {
        throw Exception('Failed to fetch funds: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching funds: $e');
      rethrow;
    }
  }

  /// Handle API errors with user-friendly messages
  String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final errorData = error.response?.data;

        switch (statusCode) {
          case 401:
            return 'Authentication failed. Please login again.';
          case 403:
            return 'Access denied. Your Fyers credentials may be invalid.';
          case 404:
            return 'Fyers credentials not found. Please configure your account.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
            return 'Fyers API error. Please try again.';
          case 504:
            return 'Request timeout. Please try again.';
          default:
            if (errorData != null && errorData['error'] != null) {
              return errorData['error'];
            }
            return 'An error occurred. Please try again.';
        }

      case DioExceptionType.cancel:
        return 'Request cancelled.';

      default:
        return 'Network error. Please check your connection.';
    }
  }
}
