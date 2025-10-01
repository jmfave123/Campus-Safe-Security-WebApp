// lib/services/audit_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Enum for different audit action types
enum AuditAction {
  // Authentication
  adminLogin,
  adminLogout,
  adminPasswordChanged,

  // Campus Status
  statusUpdated,
  statusViewed,

  // Reports
  reportViewed,
  reportStatusUpdated,
  reportExported,
  reportDeleted,

  // Alerts
  alertCreated,
  alertEdited,
  alertDeleted,
  alertSent,

  // Data Access
  dashboardAccessed,
  dataExported,
  backupCreated,
  backupFailed,

  // Communication
  announcementCreated,

  // Guard Management
  guardProfileUpdated,
  guardVerified,

  // Profile Management
  adminProfileUpdated,
}

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current admin user info
  Map<String, dynamic> _getCurrentUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    return {
      'user_id': user?.uid ?? 'unknown',
      'user_email': user?.email ?? 'unknown',
      'user_name': user?.displayName ?? 'Admin User',
    };
  }

  // Special method for logout logging that captures user info before signing out
  Map<String, dynamic> _getUserInfoForLogout() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return {
        'user_id': user.uid,
        'user_email': user.email ?? 'unknown',
        'user_name': user.displayName ?? 'Admin User',
      };
    }
    return {
      'user_id': 'unknown',
      'user_email': 'unknown',
      'user_name': 'Admin User',
    };
  }

  // Convert action enum to display-friendly names
  String _getActionDisplayName(AuditAction action) {
    switch (action) {
      case AuditAction.adminLogin:
        return 'Login';
      case AuditAction.adminLogout:
        return 'Logout';
      case AuditAction.adminPasswordChanged:
        return 'Password Changed';
      case AuditAction.reportStatusUpdated:
        return 'Report Updated';
      case AuditAction.statusUpdated:
        return 'Status Updated';
      case AuditAction.announcementCreated:
        return 'Announcement Created';
      case AuditAction.guardProfileUpdated:
        return 'Guard Profile Updated';
      case AuditAction.guardVerified:
        return 'Guard Verified';
      case AuditAction.adminProfileUpdated:
        return 'Profile Updated';
      case AuditAction.dataExported:
        return 'Data Exported';
      case AuditAction.backupCreated:
        return 'Backup Created';
      case AuditAction.backupFailed:
        return 'Backup Failed';
      default:
        return action.name;
    }
  }

  // Generic method to log any admin action
  Future<void> logAdminAction({
    required AuditAction action,
    String? description,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    try {
      final userInfo = _getCurrentUserInfo();

      final logData = {
        'timestamp': FieldValue.serverTimestamp(),
        'action': _getActionDisplayName(action),
        'userId': userInfo['user_id'], // Required by Firebase rules
        'user_email': userInfo['user_email'],
        'user_type': 'Campus Security Administrator',
        'status': isSuccess ? 'success' : 'failed',
        'platform': kIsWeb ? 'Web Application' : 'Mobile Application',
      };

      await _firestore.collection('audit_logs').add(logData);
    } catch (e) {
      print('Failed to log admin action ${_getActionDisplayName(action)}: $e');
      // Don't rethrow - audit logging should not block user operations
    }
  }

  // Log backup operations (backward compatibility)
  Future<void> logBackupOperation({
    required String action, // 'backup_created', 'backup_failed'
    required String fileType, // 'json', 'csv', 'excel'
    required String fileName,
    required String status, // 'success', 'failed', 'in_progress'
    String? fileSizeBytes,
    int? recordCount,
    String? errorMessage,
    int? durationMs,
  }) async {
    await logAdminAction(
      action: action == 'backup_created'
          ? AuditAction.backupCreated
          : AuditAction.backupFailed,
      description: 'Backup operation: $action',
      isSuccess: status == 'success',
      errorMessage: errorMessage,
    );
  }

  // Specific logging methods for different admin actions

  // Authentication logging
  Future<void> logLogin() async {
    await logAdminAction(
      action: AuditAction.adminLogin,
    );
  }

  Future<void> logLogout() async {
    try {
      // Capture user info before signing out, as user will be null after signOut
      final userInfo = _getUserInfoForLogout();

      final logData = {
        'timestamp': FieldValue.serverTimestamp(),
        'action': _getActionDisplayName(AuditAction.adminLogout),
        'userId': userInfo['user_id'], // Required by Firebase rules
        'user_email': userInfo['user_email'],
        'user_type': 'Campus Security Administrator',
        'status': 'success',
        'platform': kIsWeb ? 'Web Application' : 'Mobile Application',
      };

      await _firestore.collection('audit_logs').add(logData);
    } catch (e) {
      print('Failed to log logout action: $e');
      // Don't rethrow - this should not block logout
    }
  }

  // Password change logging
  Future<void> logPasswordChanged() async {
    await logAdminAction(
      action: AuditAction.adminPasswordChanged,
    );
  }

  // Campus status logging
  Future<void> logStatusUpdate({
    required String newStatus,
    required String reason,
    String? previousStatus,
  }) async {
    await logAdminAction(
      action: AuditAction.statusUpdated,
      description: 'Campus status updated to $newStatus',
    );
  }

  // Report logging
  Future<void> logReportViewed(String reportId) async {
    await logAdminAction(
      action: AuditAction.reportViewed,
      description: 'Viewed security report details',
    );
  }

  Future<void> logReportStatusUpdate({
    required String reportId,
    required String newStatus,
    String? previousStatus,
  }) async {
    await logAdminAction(
      action: AuditAction.reportStatusUpdated,
      description: 'Updated report status to $newStatus',
    );
  }

  Future<void> logReportExport({
    required String exportType,
    required String fileName,
    int? reportCount,
  }) async {
    await logAdminAction(
      action: AuditAction.reportExported,
      description: 'Exported reports as $exportType',
    );
  }

  // Alert logging
  Future<void> logAlertCreated({
    required String alertId,
    required String message,
    required String targetAudience,
  }) async {
    await logAdminAction(
      action: AuditAction.alertCreated,
      description: 'Created new security alert',
    );
  }

  Future<void> logAlertEdited({
    required String alertId,
    required String newMessage,
    String? previousMessage,
  }) async {
    await logAdminAction(
      action: AuditAction.alertEdited,
      description: 'Edited security alert',
    );
  }

  Future<void> logAlertDeleted(String alertId) async {
    await logAdminAction(
      action: AuditAction.alertDeleted,
      description: 'Deleted security alert',
    );
  }

  // Communication logging
  Future<void> logAnnouncementCreated() async {
    await logAdminAction(
      action: AuditAction.announcementCreated,
    );
  }

  // Guard management logging
  Future<void> logGuardProfileUpdated() async {
    await logAdminAction(
      action: AuditAction.guardProfileUpdated,
    );
  }

  Future<void> logGuardVerified() async {
    await logAdminAction(
      action: AuditAction.guardVerified,
    );
  }

  // Profile management logging
  Future<void> logAdminProfileUpdated() async {
    await logAdminAction(
      action: AuditAction.adminProfileUpdated,
    );
  }

  // Page access logging (removed - no longer tracking page access)

  // Dashboard access logging
  Future<void> logDashboardAccess() async {
    await logAdminAction(
      action: AuditAction.dashboardAccessed,
      description: 'Accessed admin dashboard',
    );
  }

  // Get audit logs with optional filtering
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 50,
    String? filterByAction,
    String? filterByStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs') // Changed from 'data_logs' to 'audit_logs'
          .orderBy('timestamp', descending: true);

      if (filterByAction != null) {
        query = query.where('action', isEqualTo: filterByAction);
      }

      if (filterByStatus != null) {
        query = query.where('status', isEqualTo: filterByStatus);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Timestamp is already a string in the new format, no conversion needed
        // The data structure now uses ISO string format directly

        return data;
      }).toList();
    } catch (e) {
      print('Failed to fetch audit logs: $e');
      return [];
    }
  }

  // Get audit log statistics
  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final logs = await getAuditLogs(limit: 1000);

      final stats = {
        'total_logs': logs.length,
        'successful_operations':
            logs.where((log) => log['status'] == 'success').length,
        'failed_operations':
            logs.where((log) => log['status'] == 'failed').length,
        'user_types': <String, int>{},
        'recent_activity': logs.take(5).toList(),
      };

      // Count user types
      for (var log in logs) {
        final userType = log['user_type'] as String?;
        if (userType != null) {
          final userTypes = stats['user_types'] as Map<String, int>;
          userTypes[userType] = (userTypes[userType] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Failed to fetch audit stats: $e');
      return {};
    }
  }
}
