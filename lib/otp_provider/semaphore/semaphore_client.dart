/// Semaphore SMS Philippines OTP client implementation.
///
/// This client handles sending OTP messages through Semaphore's API.
/// It implements the OtpProvider interface to work with the unified
/// OTP system in the app.
///
/// Features:
/// - Sends OTP via Semaphore's dedicated OTP endpoint
/// - Handles auto-generated or custom OTP codes
/// - Safe logging that redacts sensitive information
/// - Proper error handling and timeouts
///
/// Usage:
/// ```dart
/// final client = SemaphoreClient(apiKey: 'your_api_key');
/// final result = await client.sendOtp(
///   phone: '+639171234567',
///   message: 'Your login code is {otp}. Valid for 5 minutes.',
/// );
/// ```
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../otp_provider.dart';

/// Semaphore SMS client for sending OTP messages via Node.js server.
///
/// This implementation calls a Node.js server that handles SMS sending
/// and OTP generation, avoiding CORS issues and keeping API keys secure.
class SemaphoreClient implements OtpProvider {
  /// Your Semaphore API key (get from semaphore.co dashboard)
  final String apiKey;

  /// HTTP client for making requests
  final http.Client _httpClient;

  SemaphoreClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    if (apiKey.isEmpty) {
      throw ArgumentError('Semaphore API key cannot be empty');
    }
  }

  @override
  Future<SendResult> sendOtp({
    required String phone,
    required String message,
    int expireSeconds = 300,
    String? code,
  }) async {
    // Validate inputs
    if (phone.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }

    // Clean phone number (remove spaces, dashes, but keep + for international)
    final cleanPhone = _cleanPhoneNumber(phone);

    try {
      print('DEBUG: Starting OTP send for phone: $cleanPhone');
      final response = await _sendOtpRequest(
        phone: cleanPhone,
        message: message,
        code: code,
        expireSeconds: expireSeconds,
      );

      print('DEBUG: OTP request completed, processing response...');
      return _handleSendResponse(response);
    } catch (e) {
      print('DEBUG: OTP Send Exception - type: ${e.runtimeType}, message: $e');
      if (e is ProviderException) rethrow;
      throw ProviderException('Failed to send OTP: $e');
    }
  }

  @override
  Future<VerifyResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    // Semaphore doesn't provide an OTP verification endpoint.
    // The OTP verification must be handled by your application logic
    // using the code returned in the send response.
    throw UnimplementedError(
        'Semaphore does not provide OTP verification endpoint. '
        'Use LocalVerifier or implement server-side verification '
        'using the OTP code returned from sendOtp().');
  }

  /// Send OTP request to Node.js server
  Future<http.Response> _sendOtpRequest({
    required String phone,
    required String message,
    String? code,
    int expireSeconds = 300,
  }) async {
    // Try multiple server configurations for better compatibility
    final serverUrls = [
      'http://quest4inno.mooo.com:3000/send-otp', // Primary - working perfectly
      'https://quest4inno.mooo.com:3000/send-otp', // HTTPS version
      // Removed port 80 URLs due to nginx redirect issues
    ];

    Exception? lastException;

    for (final url in serverUrls) {
      try {
        print('DEBUG: Trying OTP server URL: $url');
        final uri = Uri.parse(url);

        // Send only phone number - server handles OTP generation and messaging
        final requestBody = jsonEncode({
          'phone': phone,
        });

        final response = await _httpClient
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'CampusSafeApp/1.0',
              },
              body: requestBody,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw ProviderException('Request timeout for $url'),
            );

        print('DEBUG: OTP server response for $url: ${response.statusCode}');

        // If we get a successful response, return it
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('DEBUG: Successfully connected to OTP server: $url');
          return response;
        }

        // If we get a different status code, try next URL
        print(
            'DEBUG: Server $url returned status ${response.statusCode}, trying next...');
      } catch (e) {
        print('DEBUG: Failed to connect to $url: $e');
        lastException = e is Exception ? e : Exception(e.toString());
        continue; // Try next URL
      }
    }

    // If all URLs failed, throw the last exception
    throw lastException ?? ProviderException('All OTP server URLs failed');
  }

  /// Handle the response from Node.js server
  SendResult _handleSendResponse(http.Response response) {
    final decoded = _tryDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        // Handle Node.js server response format: {success: true, otp: "123456", message: "...", sms_response: [...]}
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final otpCode = decoded['otp']?.toString();
          final smsResponse = decoded['sms_response'];

          // Extract message_id from Semaphore response for tracking
          String? messageId;
          if (smsResponse is List && smsResponse.isNotEmpty) {
            final firstMessage = smsResponse[0] as Map<String, dynamic>?;
            messageId = firstMessage?['message_id']?.toString();
          }

          return SendResult(
            success: true,
            providerMessageId:
                messageId ?? 'node_${DateTime.now().millisecondsSinceEpoch}',
            code: otpCode, // OTP code generated by Node.js server
            message: decoded['message']?.toString() ?? 'OTP sent successfully',
            rawResponse: _redactSensitiveData(decoded),
          );
        }

        // If not successful format, throw error
        throw ProviderException(
          'Unexpected response format from Node.js server',
          statusCode: response.statusCode,
          body: _redactSensitiveData(decoded),
        );
      } catch (e) {
        throw ProviderException(
          'Failed to parse Node.js server response: $e',
          statusCode: response.statusCode,
          body: _redactSensitiveData(decoded),
        );
      }
    } else {
      // Handle error responses
      final errorMessage = _extractErrorMessage(decoded);
      throw ProviderException(
        errorMessage,
        statusCode: response.statusCode,
        body: _redactSensitiveData(decoded),
      );
    }
  }

  /// Extract error message from API response
  String _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      // Try common error message fields
      if (decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded['error'] != null) {
        return decoded['error'].toString();
      }
      if (decoded['errors'] != null) {
        return decoded['errors'].toString();
      }
    }
    return 'API request failed';
  }

  /// Clean phone number format for Semaphore
  String _cleanPhoneNumber(String phone) {
    // Remove spaces, dashes, parentheses
    String clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If it starts with 0 and looks like a Philippine number, convert to +63
    if (clean.startsWith('0') && clean.length == 11) {
      clean = '+63${clean.substring(1)}';
    }

    // If it starts with 63 but no +, add the +
    if (clean.startsWith('63') && !clean.startsWith('+63')) {
      clean = '+$clean';
    }

    return clean;
  }

  /// Safely decode JSON response
  dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) {
      return {'error': 'Empty response body'};
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      // If not JSON, return the raw body wrapped in an object
      return {'raw_response': body, 'parse_error': e.toString()};
    }
  }

  /// Remove sensitive data from response for safe logging
  Map<String, dynamic> _redactSensitiveData(dynamic data) {
    if (data is List) {
      // Handle array responses (typical for Semaphore)
      final safeList = <Map<String, dynamic>>[];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          final safeItem = Map<String, dynamic>.from(item);
          _redactMapSensitiveData(safeItem);
          safeList.add(safeItem);
        }
      }
      return {'messages': safeList};
    } else if (data is Map<String, dynamic>) {
      final safe = Map<String, dynamic>.from(data);
      _redactMapSensitiveData(safe);
      return safe;
    } else {
      return {'raw': data.toString()};
    }
  }

  /// Redact sensitive data from a map
  void _redactMapSensitiveData(Map<String, dynamic> map) {
    // Redact OTP codes
    if (map.containsKey('code')) {
      map['code'] = '••••';
    }

    // Redact messages that might contain OTPs
    if (map.containsKey('message') && map['message'] is String) {
      map['message'] = _redactMessageContent(map['message'] as String);
    }
  }

  /// Redact OTP codes from message content
  String _redactMessageContent(String message) {
    // Replace sequences of 4+ digits with bullets
    return message.replaceAll(RegExp(r'\d{4,}'), '••••');
  }

  /// Debug logging (only in debug mode)
  void _debugLog(String operation, http.Response response) {
    if (!kDebugMode) return;

    try {
      final decoded = _tryDecode(response.body);
      final safe = _redactSensitiveData(decoded);

      print('SemaphoreClient[$operation] '
          'status=${response.statusCode} '
          'body=${jsonEncode(safe)}');
    } catch (e) {
      print('SemaphoreClient[$operation] '
          'status=${response.statusCode} '
          'body=<failed to parse>');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}
