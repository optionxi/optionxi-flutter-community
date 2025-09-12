import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildErrorStateBroker(
    VoidCallback tryagainfnction, dynamic _errorMessage, BuildContext context) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getErrorMessageParsed(_errorMessage),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: tryagainfnction,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _getErrorMessageParsed(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond.';
      case DioExceptionType.badResponse:
        return 'Invalid response from server (${error.response?.statusCode}).';
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  // return 'An unexpected error occurred. Please try again.';
  return error.toString();
}
