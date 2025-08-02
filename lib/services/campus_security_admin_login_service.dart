import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminLoginService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Login method that returns a Future with login result
  Future<AdminLoginResult> login(String username, String password) async {
    try {
      // Get the username and convert to lowercase email
      final email = username.toLowerCase().trim();

      // Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        // Get the user ID
        final userId = userCredential.user!.uid;
        print('User authenticated with ID: $userId');
        bool isAdmin = false;

        // First try with the direct document reference approach (more reliable)
        try {
          // Add a small delay to ensure Firebase Auth operation is complete
          await Future.delayed(const Duration(milliseconds: 300));
          print('Checking admin status in admin_users collection');

          final adminDoc =
              await _firestore.collection('admin_users').doc(userId).get();

          print('Admin doc exists: ${adminDoc.exists}');
          if (adminDoc.exists) {
            final userData = adminDoc.data();
            print('Admin doc data: $userData');
            isAdmin = userData != null && userData['isAdmin'] == true;
            print('Is admin: $isAdmin');
          } else {
            print('Admin document does not exist for this user');
          }
        } catch (directFetchError) {
          print('Error with direct document fetch: $directFetchError');

          // If direct fetch fails, try the query approach as fallback
          try {
            // Add a delay before trying a different approach
            await Future.delayed(const Duration(milliseconds: 500));

            final adminQuery = await _firestore
                .collection('admin_users')
                .where(FieldPath.documentId, isEqualTo: userId)
                .limit(1)
                .get();

            if (adminQuery.docs.isNotEmpty) {
              final userData = adminQuery.docs.first.data();
              isAdmin = userData['isAdmin'] == true;
            }
          } catch (queryError) {
            print('Error with query approach: $queryError');
            // If both approaches fail, we'll handle it in the outer catch block
            rethrow;
          }
        }

        // Process the result
        if (isAdmin) {
          return AdminLoginResult(
            success: true,
            errorMessage: '',
          );
        } else {
          // Sign out the user since they're not an admin
          await _auth.signOut();
          return AdminLoginResult(
            success: false,
            errorMessage: 'Not authorized as admin',
          );
        }
      } catch (firestoreError) {
        // Handle Firestore specific errors
        print('Firestore error during login: $firestoreError');

        // Check if we still have a valid Firebase Auth user despite Firestore error
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          // We could check a cached version or use a different approach
          // For now, just show an error and sign the user out
          await _auth.signOut();
        }

        return AdminLoginResult(
          success: false,
          errorMessage: 'Error verifying admin status. Please try again.',
        );
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        errorMessage = _getErrorMessage(e.code);
      } else {
        errorMessage = 'Login failed: ${e.toString()}';
      }

      return AdminLoginResult(
        success: false,
        errorMessage: errorMessage,
      );
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No admin account found with this username';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid username format';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      default:
        return 'Login failed: $code';
    }
  }
}

// Class to represent login result
class AdminLoginResult {
  final bool success;
  final String errorMessage;

  AdminLoginResult({
    required this.success,
    required this.errorMessage,
  });
}
