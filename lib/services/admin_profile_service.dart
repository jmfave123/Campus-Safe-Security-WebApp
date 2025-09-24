import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/add_security_guard_services.dart' show uploadImage;

class AdminProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gets the current admin user data from Firestore
  static Future<Map<String, dynamic>?> getCurrentAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Try admin_users collection first
      try {
        final adminDoc = await _firestore
            .collection('admin_users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (adminDoc.exists) {
          final data = adminDoc.data() ?? {};
          // Add Firebase Auth data as fallback
          return {
            'uid': user.uid,
            'email': user.email ?? data['email'] ?? '',
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'phone': data['phone'] ?? '',
            'profileImageUrl': data['profileImageUrl'] ?? '',
            'displayName': user.displayName ??
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            ...data,
          };
        }
      } catch (e) {
        print('Error fetching from admin_users: $e');
      }

      // Try campus_security_admin collection as fallback
      try {
        final adminDoc = await _firestore
            .collection('campus_security_admin')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (adminDoc.exists) {
          final data = adminDoc.data() ?? {};
          return {
            'uid': user.uid,
            'email': user.email ?? data['email'] ?? '',
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'phone': data['phone'] ?? '',
            'profileImageUrl': data['profileImageUrl'] ?? '',
            'displayName': user.displayName ??
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            ...data,
          };
        }
      } catch (e) {
        print('Error fetching from campus_security_admin: $e');
      }

      // Return Firebase Auth data only if no Firestore document exists
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'firstName': '',
        'lastName': '',
        'phone': '',
        'profileImageUrl': '',
        'displayName': user.displayName ?? '',
      };
    } catch (e) {
      print('Error getting current admin profile: $e');
      return null;
    }
  }

  /// Updates the admin profile in Firestore
  static Future<bool> updateAdminProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final updateData = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Try to update admin_users collection first
      bool updated = false;
      try {
        final adminDoc =
            await _firestore.collection('admin_users').doc(user.uid).get();

        if (adminDoc.exists) {
          await _firestore
              .collection('admin_users')
              .doc(user.uid)
              .update(updateData);
          updated = true;
        }
      } catch (e) {
        print('Error updating admin_users: $e');
      }

      // Try campus_security_admin collection if admin_users update failed or doesn't exist
      if (!updated) {
        try {
          final adminDoc = await _firestore
              .collection('campus_security_admin')
              .doc(user.uid)
              .get();

          if (adminDoc.exists) {
            await _firestore
                .collection('campus_security_admin')
                .doc(user.uid)
                .update(updateData);
            updated = true;
          } else {
            // Create new document in admin_users if neither exists
            await _firestore.collection('admin_users').doc(user.uid).set({
              ...updateData,
              'email': user.email,
              'isAdmin': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
            updated = true;
          }
        } catch (e) {
          print('Error updating campus_security_admin: $e');
        }
      }

      // Update Firebase Auth display name if successful
      if (updated) {
        try {
          final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
          await user.updateDisplayName(displayName);
        } catch (e) {
          print('Warning: Could not update display name: $e');
          // Don't fail the entire operation for this
        }
      }

      return updated;
    } catch (e) {
      print('Error updating admin profile: $e');
      return false;
    }
  }

  /// Uploads profile image and returns the URL
  static Future<String?> uploadProfileImage(
      Uint8List imageData, String fileName) async {
    try {
      final result = await uploadImage(imageData, fileName);
      return result['secure_url'] as String?;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Updates profile with new image
  static Future<bool> updateProfileImage(
      Uint8List imageData, String fileName) async {
    try {
      final imageUrl = await uploadProfileImage(imageData, fileName);
      if (imageUrl == null) return false;

      final user = _auth.currentUser;
      if (user == null) return false;

      final updateData = {
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Try to update admin_users collection first
      bool updated = false;
      try {
        final adminDoc =
            await _firestore.collection('admin_users').doc(user.uid).get();

        if (adminDoc.exists) {
          await _firestore
              .collection('admin_users')
              .doc(user.uid)
              .update(updateData);
          updated = true;
        }
      } catch (e) {
        print('Error updating admin_users profile image: $e');
      }

      // Try campus_security_admin collection if admin_users update failed
      if (!updated) {
        try {
          await _firestore
              .collection('campus_security_admin')
              .doc(user.uid)
              .update(updateData);
          updated = true;
        } catch (e) {
          print('Error updating campus_security_admin profile image: $e');
        }
      }

      return updated;
    } catch (e) {
      print('Error updating profile image: $e');
      return false;
    }
  }
}
