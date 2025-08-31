import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
// Note: firebase imports removed because client-side addSecurityGuard is disabled.
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/*
// Service function to add a security guard.
// NOTE: Disabled in client. Admin user creation must be performed via a
// trusted server-side flow (Cloud Function / Admin SDK) to avoid auth-state
// switching issues and Firestore permission errors.
// The original implementation is retained here as a commented reference.
// Only admins can create security guard accounts
Future<void> addSecurityGuard({
  required String name,
  required String phone,
  required String badge,
  Uint8List? profileImageData,
  String? imageFileName,
  String? email,
  String? password,
}) async {
  // Original implementation removed (commented-out). Use server-side admin
  // functions to create auth users and write Firestore documents.
  throw UnimplementedError(
      'addSecurityGuard is disabled on the client. Use server-side admin flow.');
}
*/

// Updated function for uploading image to Cloudinary using Uint8List (web compatible)
Future<Map<String, dynamic>> uploadImage(
    Uint8List imageData, String fileName) async {
  try {
    const cloudName = 'df278xmtx';
    const uploadPreset = 'xj3ldhuc';
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageData,
        filename: fileName,
      ));

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);

    if (response.statusCode == 200) {
      return jsonDecode(responseString);
    } else {
      throw 'Upload failed: ${response.statusCode}';
    }
  } catch (e) {
    throw 'Error uploading image: $e';
  }
}

/// Marks a security guard document as verified by admin.
/// Returns true on success, false on failure.
Future<bool> verifyGuard(String uid) async {
  try {
    final docRef =
        FirebaseFirestore.instance.collection('securityGuard_user').doc(uid);
    await docRef.update({
      'isVerifiedByAdmin': true,
      // also set emailVerified true if you want to reflect the same
      'emailVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    // Log if needed
    return false;
  }
}

/// Update fields on a security guard document. Returns true on success.
Future<bool> updateGuard(String uid, Map<String, dynamic> updates) async {
  try {
    final docRef =
        FirebaseFirestore.instance.collection('securityGuard_user').doc(uid);
    await docRef.update(updates);
    return true;
  } catch (e) {
    return false;
  }
}
