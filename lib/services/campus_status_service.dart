// campus_status_service.dart
import 'package:campus_safe_app_admin_capstone/services/notify_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/campus_status_model.dart';

class CampusStatusService {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  // Path constants
  static const String campusStatusPath = 'campus_status';
  static const String campusStatusHistoryPath = 'campus_status_history';

  // Dependency injection through constructor
  CampusStatusService({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Get current status
  Future<CampusStatus> getCurrentStatus() async {
    try {
      final snapshot = await _database.ref(campusStatusPath).get();
      if (snapshot.exists) {
        return CampusStatus.fromMap(snapshot.value as Map<dynamic, dynamic>);
      } else {
        // Default to safe if no status exists
        return _createDefaultStatus();
      }
    } catch (e) {
      print('Error getting current status: $e');
      return _createDefaultStatus();
    }
  }

  // Listen to status changes
  Stream<CampusStatus> getStatusStream() {
    return _database.ref(campusStatusPath).onValue.map((event) {
      if (event.snapshot.exists) {
        return CampusStatus.fromMap(
            event.snapshot.value as Map<dynamic, dynamic>);
      } else {
        return _createDefaultStatus();
      }
    });
  }

  // Update status
  Future<void> updateStatus(String status, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Convert string status to enum
      final statusLevel = _statusLevelFromString(status);

      final statusData = {
        'current_status': status.toLowerCase(),
        'reason': reason,
        'last_updated': ServerValue.timestamp,
        'updated_by': user.uid,
      };

      // Update current status
      await _database.ref(campusStatusPath).update(statusData);

      // Add to history
      final historyData = {
        'status': status.toLowerCase(),
        'reason': reason,
        'timestamp': ServerValue.timestamp,
        'updated_by': user.uid,
      };

      await _database.ref(campusStatusHistoryPath).push().set(historyData);

      // Send notification about the status change
      await sendStatusChangeNotification(status, reason);
    } catch (e) {
      print('Error updating campus status: $e');
      throw Exception('Failed to update campus status: $e');
    }
  }

  CampusStatus _createDefaultStatus() {
    return CampusStatus(
      level: CampusStatusLevel.safe,
      timestamp: DateTime.now(),
      updatedBy: 'system',
      reason: 'Default status',
    );
  }

  // Convert string status to enum
  CampusStatusLevel _statusLevelFromString(String status) {
    switch (status.toLowerCase()) {
      case 'caution':
        return CampusStatusLevel.caution;
      case 'emergency':
        return CampusStatusLevel.emergency;
      case 'safe':
      default:
        return CampusStatusLevel.safe;
    }
  }

  // Method to send notification about status change
  Future<void> sendStatusChangeNotification(
      String status, String reason) async {
    try {
      // Format status for display (capitalize first letter)
      final formattedStatus =
          status.substring(0, 1).toUpperCase() + status.substring(1);

      // Create notification heading based on status
      String heading;
      switch (status.toLowerCase()) {
        case 'caution':
          heading = "⚠️ Campus Caution Alert";
          break;
        case 'emergency':
          heading = "🚨 CAMPUS EMERGENCY ALERT";
          break;
        case 'safe':
          heading = "✅ Campus Status Update";
          break;
        default:
          heading = "Campus Status Update";
      }

      // Create notification content
      final content = "Campus status changed to $formattedStatus: $reason";

      // Send to both student and faculty groups
      await Future.wait([
        NotifServices.sendGroupNotification(
          userType: "Student",
          heading: heading,
          content: content,
        ),
        NotifServices.sendGroupNotification(
          userType: "Faculty & Staff",
          heading: heading,
          content: content,
        ),
      ]);
    } catch (e) {
      print('Error sending status change notification: $e');
    }
  }
}
