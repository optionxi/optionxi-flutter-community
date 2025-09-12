import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';

class ZerodhaApiService {
  late final Dio _dio;
  static String baseUrl = dotenv.env['ZERODHA_URL']!;

  ZerodhaApiService() {
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
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/profile');

      if (response.data['success'] == true) {
        return response.data['data']['data'];
      } else {
        throw Exception('Failed to fetch profile: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  /// Fetch portfolio holdings
  Future<List<HoldingModel>> fetchHoldings() async {
    try {
      final response = await _dio.get('/portfolio/holdings');

      if (response.data['success'] == true) {
        print(response.data['data']);
        final List<dynamic> holdingsData = response.data['data'];
        return holdingsData.map((json) => HoldingModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch holdings: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching holdings: $e');
      rethrow;
    }
  }

  /// Fetch portfolio positions
  Future<List<PositionModel>> fetchPositions() async {
    try {
      final response = await _dio.get('/portfolio/positions');

      if (response.data['success'] == true) {
        final List<dynamic> netData = response.data['data'];
        return netData.map((json) => PositionModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch positions: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching positions: $e');
      rethrow;
    }
  }

  /// Fetch orders
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final response = await _dio.get('/orders');

      if (response.data['success'] == true) {
        final List<dynamic> ordersData = response.data['data'];
        return ordersData.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.data['error']}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
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
            return 'Access denied. Your Zerodha credentials may be invalid.';
          case 404:
            return 'Zerodha credentials not found. Please configure your account.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
            return 'Zerodha API error. Please try again.';
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
