import 'package:flutter/material.dart';
import '../widgets/otp_verification_dialog.dart';

/// Service to handle OTP verification for profile management changes
///
/// This service determines when OTP verification is needed and handles
/// the verification flow for different types of profile changes.
class ProfileOtpService {
  /// Check if profile changes require OTP verification
  ///
  /// Returns true if any of the following fields have changed:
  /// - First name
  /// - Last name
  /// - Phone number
  /// - Profile picture
  static bool requiresOtpVerification({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
    bool hasNewProfileImage = false,
  }) {
    final currentFirstName =
        currentProfile['firstName']?.toString().trim() ?? '';
    final currentLastName = currentProfile['lastName']?.toString().trim() ?? '';
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';

    // Check if any field has changed
    return currentFirstName != newFirstName.trim() ||
        currentLastName != newLastName.trim() ||
        currentPhone != newPhone.trim() ||
        hasNewProfileImage;
  }

  /// Get the phone number to send OTP to based on the type of change
  ///
  /// For name changes: send to current phone
  /// For phone changes: send to new phone
  static String getOtpPhoneNumber({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
  }) {
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';
    final newPhoneTrimmed = newPhone.trim();

    // If phone number is changing, send OTP to the new number
    if (currentPhone != newPhoneTrimmed) {
      return newPhoneTrimmed;
    }

    // For name changes, send to current phone
    return currentPhone;
  }

  /// Get the appropriate dialog title based on the type of change
  static String getDialogTitle({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
  }) {
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';
    final newPhoneTrimmed = newPhone.trim();

    if (currentPhone != newPhoneTrimmed) {
      return 'Verify New Phone Number';
    } else {
      return 'Verify Profile Changes';
    }
  }

  /// Get the appropriate dialog message based on the type of change
  static String getDialogMessage({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
  }) {
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';
    final newPhoneTrimmed = newPhone.trim();

    if (currentPhone != newPhoneTrimmed) {
      return 'We\'ve sent a verification code to your new phone number. Enter it to confirm the change.';
    } else {
      return 'We\'ve sent a verification code to your phone to verify these changes. Enter it to continue.';
    }
  }

  /// Get the appropriate OTP message based on the type of change
  static String getOtpMessage({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
  }) {
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';
    final newPhoneTrimmed = newPhone.trim();

    if (currentPhone != newPhoneTrimmed) {
      return 'Your Campus Safe verification code is {otp}. Enter this code to confirm your new phone number. Valid for 5 minutes.';
    } else {
      return 'Your Campus Safe verification code is {otp}. Enter this code to verify your profile changes. Valid for 5 minutes.';
    }
  }

  /// Show OTP verification dialog for profile changes
  ///
  /// Returns true if verification was successful, false otherwise
  static Future<bool> showProfileOtpVerification({
    required BuildContext context,
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
    bool hasNewProfileImage = false,
  }) async {
    // Check if OTP verification is needed
    if (!requiresOtpVerification(
      currentProfile: currentProfile,
      newFirstName: newFirstName,
      newLastName: newLastName,
      newPhone: newPhone,
      hasNewProfileImage: hasNewProfileImage,
    )) {
      // No changes detected, no OTP needed
      return true;
    }

    // Get the phone number to send OTP to
    final otpPhone = getOtpPhoneNumber(
      currentProfile: currentProfile,
      newFirstName: newFirstName,
      newLastName: newLastName,
      newPhone: newPhone,
    );

    // Validate phone number
    if (otpPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required for verification'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Get appropriate messages
    final title = getDialogTitle(
      currentProfile: currentProfile,
      newFirstName: newFirstName,
      newLastName: newLastName,
      newPhone: newPhone,
    );

    final message = getDialogMessage(
      currentProfile: currentProfile,
      newFirstName: newFirstName,
      newLastName: newLastName,
      newPhone: newPhone,
    );

    final otpMessage = getOtpMessage(
      currentProfile: currentProfile,
      newFirstName: newFirstName,
      newLastName: newLastName,
      newPhone: newPhone,
    );

    // Show OTP verification dialog
    return await showOtpVerificationDialog(
      context: context,
      phone: otpPhone,
      title: title,
      message: message,
      customOtpMessage: otpMessage,
      onVerified: () {
        // Log successful verification
        print('Profile OTP verification successful for phone: $otpPhone');
      },
      onCancelled: () {
        // Log cancellation
        print('Profile OTP verification cancelled');
      },
    );
  }

  /// Get a summary of what changes will be made
  static List<String> getChangeSummary({
    required Map<String, dynamic> currentProfile,
    required String newFirstName,
    required String newLastName,
    required String newPhone,
    bool hasNewProfileImage = false,
  }) {
    final changes = <String>[];

    final currentFirstName =
        currentProfile['firstName']?.toString().trim() ?? '';
    final currentLastName = currentProfile['lastName']?.toString().trim() ?? '';
    final currentPhone = currentProfile['phone']?.toString().trim() ?? '';

    if (currentFirstName != newFirstName.trim()) {
      changes
          .add('First name: "$currentFirstName" → "${newFirstName.trim()}"');
    }

    if (currentLastName != newLastName.trim()) {
      changes.add('Last name: "$currentLastName" → "${newLastName.trim()}"');
    }

    if (currentPhone != newPhone.trim()) {
      changes.add('Phone: "$currentPhone" → "${newPhone.trim()}"');
    }

    if (hasNewProfileImage) {
      changes.add('Profile picture: New image selected');
    }

    return changes;
  }
}
