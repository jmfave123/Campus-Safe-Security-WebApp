/// Local OTP verification helper for providers that don't offer verification endpoints.
///
/// Since Semaphore SMS doesn't provide an OTP verification API endpoint,
/// this utility handles storing and verifying OTPs locally in your app.
/// It provides secure, time-based OTP verification with proper expiry handling.
///
/// Features:
/// - Store OTPs with automatic expiry
/// - Secure verification (constant-time comparison)
/// - Automatic cleanup of expired OTPs
/// - Protection against brute force attacks
/// - Thread-safe operations
///
/// Usage:
/// ```dart
/// final verifier = LocalOtpVerifier();
///
/// // Store OTP when sending
/// await verifier.storeOtp(phone: '+639171234567', code: '123456', ttlSeconds: 300);
///
/// // Verify when user submits
/// final isValid = await verifier.verifyOtp(phone: '+639171234567', code: '123456');
/// ```
///
/// Security Notes:
/// - OTPs are stored with hash for security
/// - Automatic rate limiting prevents brute force
/// - Expired OTPs are automatically cleaned up
/// - Uses constant-time comparison to prevent timing attacks
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'otp_provider.dart';

/// Represents a stored OTP with metadata
class StoredOtp {
  /// Phone number this OTP was sent to
  final String phone;

  /// Hashed OTP code (never store plaintext)
  final String hashedCode;

  /// When this OTP expires (Unix timestamp)
  final int expiresAt;

  /// When this OTP was created
  final int createdAt;

  /// Number of verification attempts made
  int attemptCount;

  /// Maximum attempts allowed before blocking
  static const int maxAttempts = 5;

  StoredOtp({
    required this.phone,
    required this.hashedCode,
    required this.expiresAt,
    required this.createdAt,
    this.attemptCount = 0,
  });

  /// Check if this OTP has expired
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiresAt;

  /// Check if max attempts exceeded
  bool get isBlocked => attemptCount >= maxAttempts;

  /// Time remaining in seconds
  int get secondsRemaining {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return math.max(0, expiresAt - now);
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'hashedCode': hashedCode,
        'expiresAt': expiresAt,
        'createdAt': createdAt,
        'attemptCount': attemptCount,
      };

  factory StoredOtp.fromJson(Map<String, dynamic> json) => StoredOtp(
        phone: json['phone'] ?? '',
        hashedCode: json['hashedCode'] ?? '',
        expiresAt: json['expiresAt'] ?? 0,
        createdAt: json['createdAt'] ?? 0,
        attemptCount: json['attemptCount'] ?? 0,
      );
}

/// Local OTP storage and verification system.
///
/// This class manages OTP storage and verification for providers like Semaphore
/// that don't offer server-side verification endpoints.
class LocalOtpVerifier {
  /// In-memory storage for OTPs (use database/Firestore for production)
  final Map<String, StoredOtp> _otpStorage = <String, StoredOtp>{};

  /// Timer for periodic cleanup of expired OTPs
  Timer? _cleanupTimer;

  /// Salt for hashing OTPs (in production, use a stronger random salt per OTP)
  static const String _salt = 'otp_salt_2024';

  LocalOtpVerifier() {
    // Start periodic cleanup every 60 seconds
    _startCleanupTimer();
  }

  /// Store an OTP for later verification.
  ///
  /// [phone] - Phone number in international format
  /// [code] - The OTP code to store (will be hashed)
  /// [ttlSeconds] - Time-to-live in seconds (default: 300 = 5 minutes)
  ///
  /// Returns true if stored successfully, false if there's an existing valid OTP
  Future<bool> storeOtp({
    required String phone,
    required String code,
    int ttlSeconds = 300,
  }) async {
    if (phone.isEmpty || code.isEmpty) {
      throw ArgumentError('Phone and code cannot be empty');
    }

    final cleanPhone = _normalizePhone(phone);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check if there's already a valid OTP for this phone
    final existing = _otpStorage[cleanPhone];
    if (existing != null && !existing.isExpired && !existing.isBlocked) {
      // Don't allow storing new OTP if valid one exists (prevents spam)
      return false;
    }

    // Hash the OTP code for secure storage
    final hashedCode = _hashOtp(code);

    // Store the new OTP
    _otpStorage[cleanPhone] = StoredOtp(
      phone: cleanPhone,
      hashedCode: hashedCode,
      expiresAt: now + ttlSeconds,
      createdAt: now,
    );

    return true;
  }

  /// Verify an OTP code against stored OTPs.
  ///
  /// [phone] - Phone number that received the OTP
  /// [code] - The OTP code entered by user
  ///
  /// Returns VerifyResult with verification status and details
  Future<VerifyResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    if (phone.isEmpty || code.isEmpty) {
      return VerifyResult(
        verified: false,
        message: 'Phone number and code are required',
      );
    }

    final cleanPhone = _normalizePhone(phone);
    final storedOtp = _otpStorage[cleanPhone];

    // No OTP found for this phone
    if (storedOtp == null) {
      return VerifyResult(
        verified: false,
        message: 'No OTP found for this phone number',
      );
    }

    // OTP has expired
    if (storedOtp.isExpired) {
      _otpStorage.remove(cleanPhone); // Clean up expired OTP
      return VerifyResult(
        verified: false,
        message: 'OTP has expired. Please request a new one.',
      );
    }

    // Too many attempts
    if (storedOtp.isBlocked) {
      return VerifyResult(
        verified: false,
        message: 'Too many verification attempts. Please request a new OTP.',
      );
    }

    // Increment attempt count
    storedOtp.attemptCount++;

    // Verify the code using constant-time comparison
    final isValid = _verifyOtp(code, storedOtp.hashedCode);

    if (isValid) {
      // Success - remove the OTP to prevent reuse
      _otpStorage.remove(cleanPhone);
      return VerifyResult(
        verified: true,
        message: 'OTP verified successfully',
        data: {
          'verified_at': DateTime.now().toIso8601String(),
          'attempts_made': storedOtp.attemptCount,
        },
      );
    } else {
      // Invalid code
      final attemptsLeft = StoredOtp.maxAttempts - storedOtp.attemptCount;
      return VerifyResult(
        verified: false,
        message: attemptsLeft > 0
            ? 'Invalid OTP. $attemptsLeft attempts remaining.'
            : 'Invalid OTP. Maximum attempts exceeded.',
        data: {
          'attempts_remaining': math.max(0, attemptsLeft),
          'seconds_remaining': storedOtp.secondsRemaining,
        },
      );
    }
  }

  /// Check if there's a valid OTP for the given phone number
  bool hasValidOtp(String phone) {
    final cleanPhone = _normalizePhone(phone);
    final storedOtp = _otpStorage[cleanPhone];
    return storedOtp != null && !storedOtp.isExpired && !storedOtp.isBlocked;
  }

  /// Get remaining time for OTP in seconds
  int getOtpTimeRemaining(String phone) {
    final cleanPhone = _normalizePhone(phone);
    final storedOtp = _otpStorage[cleanPhone];
    return storedOtp?.secondsRemaining ?? 0;
  }

  /// Remove expired OTPs and clean up storage
  void cleanupExpiredOtps() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _otpStorage.removeWhere((phone, otp) => otp.expiresAt <= now);
  }

  /// Get stats for monitoring (safe for logging)
  Map<String, dynamic> getStats() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final valid = _otpStorage.values.where((otp) => !otp.isExpired).length;
    final expired = _otpStorage.values.where((otp) => otp.isExpired).length;
    final blocked = _otpStorage.values.where((otp) => otp.isBlocked).length;

    return {
      'total_stored': _otpStorage.length,
      'valid_otps': valid,
      'expired_otps': expired,
      'blocked_otps': blocked,
      'timestamp': now,
    };
  }

  /// Normalize phone number for consistent storage keys
  String _normalizePhone(String phone) {
    // Remove all non-digit characters except +
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure it starts with + for international format
    if (!clean.startsWith('+')) {
      if (clean.startsWith('63')) {
        clean = '+$clean';
      } else if (clean.startsWith('0') && clean.length == 11) {
        clean = '+63${clean.substring(1)}';
      } else {
        clean = '+$clean';
      }
    }

    return clean;
  }

  /// Start the cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => cleanupExpiredOtps(),
    );
  }

  /// Hash an OTP code for secure storage
  String _hashOtp(String code) {
    final combined = '$code$_salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify OTP using constant-time comparison
  bool _verifyOtp(String code, String hashedCode) {
    final candidateHash = _hashOtp(code);

    // Constant-time comparison to prevent timing attacks
    if (candidateHash.length != hashedCode.length) {
      return false;
    }

    var result = 0;
    for (int i = 0; i < candidateHash.length; i++) {
      result |= candidateHash.codeUnitAt(i) ^ hashedCode.codeUnitAt(i);
    }

    return result == 0;
  }

  /// Clean up resources
  void dispose() {
    _cleanupTimer?.cancel();
    _otpStorage.clear();
  }
}
