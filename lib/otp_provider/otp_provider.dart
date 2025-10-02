/// Abstract interface for OTP (One-Time Password) providers.
///
/// This interface allows the app to support multiple SMS/OTP providers
/// (like Semaphore, SmsChef, etc.) with a unified API. Different providers
/// can be swapped without changing app logic.
///
/// Usage:
/// ```dart
/// final provider = OtpProviderFactory.createSemaphoreProvider();
/// final result = await provider.sendOtp(
///   phone: '+639171234567',
///   message: 'Your OTP is {otp}. Valid for 5 minutes.'
/// );
/// ```
library;

/// Result of sending an OTP message
class SendResult {
  /// Whether the send operation was successful
  final bool success;

  /// Provider-specific message ID for tracking
  final String? providerMessageId;

  /// The OTP code that was sent (only available internally, never log this)
  final String? code;

  /// Human-readable status message
  final String message;

  /// Raw response from provider (for debugging, ensure it's redacted)
  final Map<String, dynamic>? rawResponse;

  SendResult({
    required this.success,
    this.providerMessageId,
    this.code,
    required this.message,
    this.rawResponse,
  });

  /// Safe JSON representation that excludes sensitive data
  Map<String, dynamic> toJson({bool redactSensitive = true}) => {
        'success': success,
        'providerMessageId': providerMessageId,
        'message': message,
        'code': redactSensitive ? null : code,
        // rawResponse is excluded from JSON to prevent accidental logging
      };
}

/// Result of verifying an OTP code
class VerifyResult {
  /// Whether the OTP verification was successful
  final bool verified;

  /// Reason for verification result (success/failure message)
  final String message;

  /// Provider-specific data (optional)
  final Map<String, dynamic>? data;

  VerifyResult({
    required this.verified,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'verified': verified,
        'message': message,
        'data': data,
      };
}

/// Exception thrown by OTP providers on errors
class ProviderException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? body;

  ProviderException(this.message, {this.statusCode = 0, this.body});

  @override
  String toString() => 'ProviderException($statusCode): $message';
}

/// Abstract interface for OTP providers
abstract class OtpProvider {
  /// Send an OTP to the specified phone number.
  ///
  /// [phone] - Mobile number in international format (e.g., '+639171234567')
  /// [message] - SMS message template. Use '{otp}' placeholder for auto-generated OTP
  /// [expireSeconds] - OTP validity duration in seconds (default: 300 = 5 minutes)
  /// [code] - Optional custom OTP code. If not provided, provider generates one
  ///
  /// Returns [SendResult] with success status and provider response details.
  /// Throws [ProviderException] on network errors or invalid responses.
  Future<SendResult> sendOtp({
    required String phone,
    required String message,
    int expireSeconds = 300,
    String? code,
  });

  /// Verify an OTP code for the given phone number.
  ///
  /// [phone] - Mobile number that received the OTP
  /// [code] - OTP code entered by the user
  ///
  /// Returns [VerifyResult] indicating if the code is valid.
  /// Throws [ProviderException] on network errors.
  ///
  /// Note: Some providers (like Semaphore) don't have verify endpoints.
  /// In those cases, verification is handled locally using stored OTPs.
  Future<VerifyResult> verifyOtp({
    required String phone,
    required String code,
  });

  /// Clean up resources (close HTTP clients, etc.)
  void dispose();
}
