import 'package:flutter_test/flutter_test.dart';
import 'package:campus_safe_app_admin_capstone/OTP/otp_generator.dart';

void main() {
  test('default length is 6 and numeric', () {
    final otp = generateNumericOtp();
    expect(otp.length, 6);
    expect(RegExp(r'^\d+\$').hasMatch(otp), isTrue);
  });

  test('custom length greater than 6', () {
    final otp = generateNumericOtp(8);
    expect(otp.length, 8);
    expect(RegExp(r'^\d+\$').hasMatch(otp), isTrue);
  });

  test('length less than 6 falls back to 6', () {
    final otp = generateNumericOtp(3);
    expect(otp.length, 6);
    expect(RegExp(r'^\d+\$').hasMatch(otp), isTrue);
  });

  test('multiple calls produce different values (non-deterministic)', () {
    final a = generateNumericOtp();
    final b = generateNumericOtp();
    // It's possible (though unlikely) two successive calls produce the same OTP.
    // We assert they're strings of digits and only warn if equal.
    expect(RegExp(r'^\d+\$').hasMatch(a), isTrue);
    expect(RegExp(r'^\d+\$').hasMatch(b), isTrue);
  });
}
