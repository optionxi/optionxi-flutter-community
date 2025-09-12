import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'upstox_datamodel.dart';

class UpstoxApiService {
  late final Dio _dio;
  static String baseUrl = dotenv.env['UPSTOX_URL']!;

  UpstoxApiService() {
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
        print('Upstox API Error: ${error.message}');
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
  Future<UpstoxProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get('/user/profile');

      if (response.data['success'] == true) {
        return UpstoxProfileModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch profile: ${response.data['message']}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  /// Fetch portfolio holdings
  Future<UpstoxHoldingsResponse> fetchHoldings() async {
    try {
      final response = await _dio.get('/portfolio/long-term-holdings');

      if (response.data['success'] == true) {
        return UpstoxHoldingsResponse.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to fetch holdings: ${response.data['message']}');
      }
    } catch (e) {
      print('Error fetching holdings: $e');
      rethrow;
    }
  }

  /// Fetch portfolio positions
  Future<UpstoxPositionsResponse> fetchPositions() async {
    try {
      final response = await _dio.get('/portfolio/short-term-positions');

      if (response.data['success'] == true) {
        return UpstoxPositionsResponse.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to fetch positions: ${response.data['message']}');
      }
    } catch (e) {
      print('Error fetching positions: $e');
      rethrow;
    }
  }

  // /// Fetch orders
  Future<List<UpstoxOrderModel>> fetchOrders() async {
    try {
      final response = await _dio.get('/order/retrieve-all');

      if (response.data['success'] == true) {
        final List<dynamic> ordersData = response.data['data'];
        return ordersData
            .map((json) => UpstoxOrderModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.data['message']}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Fetch funds/margins
  Future<UpstoxFundsResponse> fetchFunds() async {
    try {
      final response = await _dio.get('/user/get-funds-and-margin');

      if (response.data['success'] == true) {
        return UpstoxFundsResponse.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch funds: ${response.data['message']}');
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
            return 'Access denied. Your Upstox credentials may be invalid or expired.';
          case 404:
            return 'Upstox credentials not found. Please configure your account.';
          case 429:
            return 'Rate limit exceeded. Please try again later.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
            return 'Upstox API error. Please try again.';
          case 504:
            return 'Request timeout. Please try again.';
          default:
            if (errorData != null && errorData['message'] != null) {
              return errorData['message'];
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
