/// One-time password (OTP) generator utilities.
///
/// Exposes `generateNumericOtp` which returns a string of numeric digits
/// of the requested length (minimum 6). Uses `Random.secure()` when
/// available for better randomness.
library;

import 'dart:math';

/// Generate a numeric OTP as a string of digits.
///
/// - [length]: number of digits to generate. Minimum value is 6; values
///   smaller than 6 will be treated as 6. Defaults to 6.
///
/// Returns a string containing only digits (`0`-`9`).
String generateNumericOtp([int length = 6]) {
  final int otpLength = length < 6 ? 6 : length;

  // Prefer a cryptographically secure RNG if available.
  final Random rng = Random.secure();

  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < otpLength; i++) {
    sb.write(rng.nextInt(10)); // 0..9
  }

  return sb.toString();
}

// Example usage (commented): how to call SMSCHEF client using `flutter_dotenv`.
// Uncomment and adapt the snippet below. Do NOT hardcode secrets in source.
/*
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'smschef_client.dart';

Future<void> exampleSendOtp() async {
  // Ensure you loaded dotenv earlier in your app: await dotenv.load();
  final apiKey = dotenv.env['SMS_CHEF_API'];
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('SMS_CHEF_API not set in environment');
  }

  final client = SmsChefClient(baseUrl: 'https://www.cloud.smschef.com', apiSecret: apiKey);

  try {
    final res = await client.sendOtp(phone: '+40712034567');
    // Avoid logging OTP or message containing the OTP in production.
    print('Send status: ${res.status} message=${res.message}');
  } catch (e) {
    print('Error sending OTP: $e');
  } finally {
    client.dispose();
  }
}
*/
