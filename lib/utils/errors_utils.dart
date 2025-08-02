import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorUtils {
  // Show a snackbar with error message
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = _getUserFriendlyErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show an error dialog with retry option
  static Future<bool?> showErrorDialog(
    BuildContext context, {
    required String title,
    required dynamic error,
    String? retryText,
  }) async {
    final message = _getUserFriendlyErrorMessage(error);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            if (retryText != null)
              TextButton(
                child: Text(retryText),
                onPressed: () => Navigator.of(context).pop(true),
              ),
          ],
        );
      },
    );
  }

  // Convert technical error to user-friendly message
  static String _getUserFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error is String) {
      return error;
    } else if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is StateError) {
      return 'An unexpected error occurred. Please restart the app.';
    } else if (error is Error) {
      return 'An unexpected error occurred: ${error.toString()}';
    } else if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    }
    return 'An unknown error occurred. Please try again.';
  }

  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      default:
        return 'Authentication error: ${error.message ?? 'Unknown error'}';
    }
  }

  static String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access this resource.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'cancelled':
        return 'The operation was cancelled.';
      case 'deadline-exceeded':
        return 'The operation took too long to complete. Please try again.';
      case 'already-exists':
        return 'A resource with this identifier already exists.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'resource-exhausted':
        return 'The service has been exhausted. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to a precondition not being met.';
      case 'aborted':
        return 'The operation was aborted. Please try again.';
      case 'out-of-range':
        return 'The operation was attempted past the valid range.';
      case 'unimplemented':
        return 'This operation is not implemented.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'data-loss':
        return 'Data was lost during the operation. Please try again.';
      case 'unauthenticated':
        return 'You need to be authenticated to perform this action.';
      default:
        return 'Firebase error: ${error.message ?? 'Unknown error'}';
    }
  }
}
