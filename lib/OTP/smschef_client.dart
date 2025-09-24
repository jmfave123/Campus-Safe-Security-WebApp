import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'smschef_models.dart';

/// Minimal SMSCHEF client. This client sends form-encoded requests to match
/// the examples provided. The API secret must be provided by the caller and
/// should not be hard-coded.
class SmsChefClient {
  final String baseUrl;
  final String apiSecret;
  final http.Client _httpClient;

  SmsChefClient(
      {required this.baseUrl, required this.apiSecret, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Send OTP. Returns a parsed response object. Throws on network errors.
  Future<SmsChefSendResponse> sendOtp({
    required String phone,
    String type = 'sms',
    String message = 'Your OTP is {{otp}}',
    int expire = 300,

    /// For SMS type: sending mode. 'devices' uses linked Android devices.
    String mode = 'devices',

    /// Linked device unique id (required for 'devices' mode)
    String device = '013ed9ec7b99365f',

    /// SIM slot number (1 or 2). Default to 2 (SIM2).
    int sim = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl/api/send/otp');

    final body = {
      'secret': apiSecret,
      'type': type,
      'message': message,
      'phone': phone,
      'expire': expire.toString(),
    };

    // Include device-mode params for SMS sending when applicable
    if (type == 'sms') {
      if (mode.isNotEmpty) body['mode'] = mode;
      if (device.isNotEmpty) body['device'] = device;
      body['sim'] = sim.toString();
    }

    // Only the basic required fields are sent (secret, type, message, phone, expire)

    final response = await _httpClient
        .post(uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body)
        .timeout(timeout);

    // Debug output (redacted) for inspection during development only
    _debugLogResponse('sendOtp', response);

    final decoded = _tryDecode(response.body);

    if (response.statusCode == 200) {
      return SmsChefSendResponse.fromJson(decoded);
    }

    // Non-200: still attempt to parse error payload for diagnostics
    throw HttpException('Failed to send OTP',
        statusCode: response.statusCode, body: decoded);
  }

  Future<SmsChefVerifyResponse> verifyOtp({
    required String otp,
    String? phone,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final query = <String, String>{'secret': apiSecret, 'otp': otp};
    if (phone != null && phone.isNotEmpty) query['phone'] = phone;
    final uri =
        Uri.parse('$baseUrl/api/get/otp').replace(queryParameters: query);

    final response = await _httpClient.get(uri).timeout(timeout);
    // Debug output (redacted) for inspection during development only
    _debugLogResponse('verifyOtp', response);

    final decoded = _tryDecode(response.body);

    if (response.statusCode == 200) {
      return SmsChefVerifyResponse.fromJson(decoded);
    }

    throw HttpException('Failed to verify OTP',
        statusCode: response.statusCode, body: decoded);
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      return {'raw': parsed};
    } catch (_) {
      return {'raw': body};
    }
  }

  // Redact digit sequences and OTPs from server responses for safe debug logs.
  String _redactMessage(String msg) {
    return msg.replaceAll(RegExp(r'\d{4,}'), '••••');
  }

  void _debugLogResponse(String tag, http.Response response) {
    if (!kDebugMode) return;
    final decoded = _tryDecode(response.body);
    final safe = Map<String, dynamic>.from(decoded);
    // redact data.otp if present
    if (safe['data'] is Map<String, dynamic>) {
      final d = Map<String, dynamic>.from(safe['data']);
      if (d.containsKey('otp')) d['otp'] = '••••';
      safe['data'] = d;
    }
    if (safe['message'] is String) {
      safe['message'] = _redactMessage(safe['message']);
    }
    try {
      // Use print so logs appear in debug console; avoid logging secrets.
      print(
          'SmsChefClient[$tag] status=${response.statusCode} body=${jsonEncode(safe)}');
    } catch (_) {
      // ignore logging errors
    }
  }

  void dispose() => _httpClient.close();
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? body;

  HttpException(this.message, {this.statusCode = 0, this.body});

  @override
  String toString() => 'HttpException($statusCode): $message - body=$body';
}
