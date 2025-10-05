import 'package:flutter/material.dart';
import '../widgets/otp_verification_dialog.dart';
import '../services/admin_profile_service.dart';

/// Service to handle OTP verification for password changes
///
/// This service handles OTP verification when changing passwords
/// to add an extra layer of security.
class PasswordOtpService {
  /// Show OTP verification dialog for password changes
  ///
  /// Returns true if verification was successful, false otherwise
  static Future<bool> showPasswordOtpVerification({
    required BuildContext context,
  }) async {
    // Get current admin profile to get phone number
    try {
      final profileData = await AdminProfileService.getCurrentAdminProfile();
      if (profileData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load profile data for verification'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final phone = profileData['phone']?.toString().trim() ?? '';
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Phone number is required for password change verification'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Show OTP verification dialog
      return await showOtpVerificationDialog(
        context: context,
        phone: phone,
        title: 'Verify Password Change',
        message:
            'We\'ve sent a verification code to your phone to confirm the password change. Enter it to continue.',
        customOtpMessage:
            'Your Campus Safe verification code is {otp}. Enter this code to confirm your password change. Valid for 5 minutes.',
        onVerified: () {
          // Log successful verification
          print(
              'Password change OTP verification successful for phone: $phone');
        },
        onCancelled: () {
          // Log cancellation
          print('Password change OTP verification cancelled');
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Show confirmation dialog for password change
  static Future<bool> showPasswordChangeConfirmation({
    required BuildContext context,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text('Confirm Password Change'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are about to change your password. This action requires additional verification for security.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will receive a verification code to confirm this password change.',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
