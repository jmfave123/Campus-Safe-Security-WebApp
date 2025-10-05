import 'dart:async';
import 'package:flutter/material.dart';
import '../otp_provider/otp_provider_factory.dart';
import '../otp_provider/local_verifier.dart';

/// A reusable OTP verification dialog that can be used across the app
///
/// This dialog handles:
/// - Sending OTP to a phone number
/// - Displaying verification input
/// - Resend functionality with cooldown
/// - Verification with proper error handling
/// - Loading states and user feedback
class OtpVerificationDialog extends StatefulWidget {
  final String phone;
  final String title;
  final String message;
  final String? customOtpMessage;
  final int otpExpireSeconds;
  final VoidCallback? onVerified;
  final VoidCallback? onCancelled;

  const OtpVerificationDialog({
    super.key,
    required this.phone,
    this.title = 'Enter OTP',
    this.message = 'An OTP was sent to the provided phone. Enter it to verify.',
    this.customOtpMessage,
    this.otpExpireSeconds = 600, // 10 minutes
    this.onVerified,
    this.onCancelled,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  final LocalOtpVerifier _otpVerifier = LocalOtpVerifier();

  bool _isSendingOtp = false;
  bool _isVerifying = false;
  int _resendRemaining = 0;
  Timer? _resendTimer;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    // Automatically send OTP when dialog opens
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Send OTP to the provided phone number
  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    setState(() => _isSendingOtp = true);

    try {
      // Create Semaphore client
      final otpProvider =
          OtpProviderFactory.createSemaphoreProvider(apiKey: 'dummy');

      // Use custom message if provided, otherwise use default
      final message = widget.customOtpMessage ??
          'Your Campus Safe verification code is {otp}. Valid for 5 minutes.';

      final result = await otpProvider.sendOtp(
        phone: widget.phone,
        message: message,
        expireSeconds: widget.otpExpireSeconds,
      );

      if (result.success && result.code != null) {
        // Store OTP for local verification
        await _otpVerifier.storeOtp(
          phone: widget.phone,
          code: result.code!,
          ttlSeconds: widget.otpExpireSeconds,
        );

        setState(() => _otpSent = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('OTP sent successfully')),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP: ${result.message}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  /// Resend OTP with cooldown
  Future<void> _resendOtp() async {
    if (_resendRemaining > 0 || _isSendingOtp) return;

    setState(() {
      _isSendingOtp = true;
      _resendRemaining = 30; // 30 second cooldown
    });

    // Start cooldown timer
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendRemaining--;
        if (_resendRemaining <= 0) {
          timer.cancel();
        }
      });
    });

    try {
      await _sendOtp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  /// Verify the entered OTP
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isVerifying = true);

    try {
      final verifyResult = await _otpVerifier.verifyOtp(
        phone: widget.phone,
        code: otp,
      );

      if (verifyResult.verified) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call onVerified callback if provided
          widget.onVerified?.call();

          // Close dialog with success result
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying OTP: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Cancel the verification process
  void _cancel() {
    widget.onCancelled?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          if (_isSendingOtp && !_otpSent)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Sending OTP...'),
              ],
            )
          else if (_otpSent)
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),

        // Resend button (only show if OTP was sent)
        if (_otpSent)
          TextButton(
            onPressed:
                (_resendRemaining > 0 || _isSendingOtp) ? null : _resendOtp,
            child: _isSendingOtp
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_resendRemaining > 0
                    ? Text('Resend (${_resendRemaining}s)')
                    : const Text('Resend')),
          ),

        // Verify button (only show if OTP was sent)
        if (_otpSent)
          ElevatedButton(
            onPressed: _isVerifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Verify'),
          ),
      ],
    );
  }
}

/// Helper function to show OTP verification dialog
///
/// Returns true if OTP was verified successfully, false otherwise
Future<bool> showOtpVerificationDialog({
  required BuildContext context,
  required String phone,
  String title = 'Enter OTP',
  String message = 'An OTP was sent to the provided phone. Enter it to verify.',
  String? customOtpMessage,
  int otpExpireSeconds = 600,
  VoidCallback? onVerified,
  VoidCallback? onCancelled,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpVerificationDialog(
          phone: phone,
          title: title,
          message: message,
          customOtpMessage: customOtpMessage,
          otpExpireSeconds: otpExpireSeconds,
          onVerified: onVerified,
          onCancelled: onCancelled,
        ),
      ) ??
      false;
}
