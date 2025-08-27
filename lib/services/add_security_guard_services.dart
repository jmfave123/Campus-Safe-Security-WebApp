import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Service function to add a security guard.
// Replace the body with real backend calls (Firestore, REST API, storage upload) as needed.
Future<void> addSecurityGuard({
  required String name,
  required String phone,
  required String badge,
  Uint8List? profileImage,
  String? email,
  String? password,
}) async {
  // Simulate a short network delay
  await Future.delayed(const Duration(milliseconds: 300));

  if (kDebugMode) {
    // ignore: avoid_print
    print(
        'addSecurityGuard -> name: $name, phone: $phone, badge: $badge, hasImage: ${profileImage != null}, email: ${email != null}');
  }

  // TODO: implement real persistence (e.g., Firestore document + upload image to Storage)
}
