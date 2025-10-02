import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityGuardProvider extends ChangeNotifier {
  // State variables
  Map<String, dynamic> _guardStats = {};
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _guards = [];

  // Getters
  Map<String, dynamic> get guardStats => _guardStats;
  bool get isLoading => _isLoading;
  List<QueryDocumentSnapshot> get guards => _guards;

  // Stream getter for guards list
  Stream<QuerySnapshot> getGuardsStream() {
    // Check if user is authenticated before returning stream
    if (FirebaseAuth.instance.currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('securityGuard_user')
        .orderBy('accountCreated', descending: true)
        .snapshots();
  }

  // Load guard statistics (async operation)
  Future<void> loadGuardData() async {
    // Check if user is authenticated before loading data
    if (FirebaseAuth.instance.currentUser == null) {
      print(
          'SecurityGuardProvider: User not authenticated, skipping data load');
      _isLoading = false;
      notifyListeners();
      return;
    }

    print('SecurityGuardProvider: Loading guard data...');
    _isLoading = true;
    notifyListeners();

    try {
      // Get all guards
      final querySnapshot = await FirebaseFirestore.instance
          .collection('securityGuard_user')
          .get();

      _guards = querySnapshot.docs;

      // Calculate statistics
      final stats = {
        'total_guards': _guards.length,
        'verified_guards': _guards.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isVerifiedByAdmin'] == true ||
              data['emailVerified'] == true;
        }).length,
        'pending_guards': _guards.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !(data['isVerifiedByAdmin'] == true ||
              data['emailVerified'] == true);
        }).length,
      };

      print('SecurityGuardProvider: Calculated stats: $stats');
      _guardStats = stats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('SecurityGuardProvider: Error loading guard data: $e');
      _isLoading = false;
      notifyListeners();
      // Re-throw to let UI handle error display
      rethrow;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadGuardData();
  }
}
