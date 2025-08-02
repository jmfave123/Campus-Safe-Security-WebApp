// lib/services/audit_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Enum for different audit action types
enum AuditAction {
  // Authentication
  adminLogin,
  adminLogout,
  sessionExpired,

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

  // System
  settingsChanged,
  userManaged,

  // Navigation
  pageAccessed,
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
        'action': action.name,
        'user_id': userInfo['user_id'],
        'user_email': userInfo['user_email'],
        'user_name': userInfo['user_name'],
        'status': isSuccess ? 'success' : 'failed',
        'platform': kIsWeb ? 'web' : 'mobile',
        if (description != null) 'description': description,
        if (errorMessage != null) 'error_message': errorMessage,
      };

      await _firestore.collection('data_logs').add(logData);
    } catch (e) {
      // Silent fail - don't disrupt user experience
      print('Failed to log admin action: $e');
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
      description: 'Admin user logged in',
    );
  }

  Future<void> logLogout() async {
    await logAdminAction(
      action: AuditAction.adminLogout,
      description: 'Admin user logged out',
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

  // Page access logging
  Future<void> logPageAccess(String pageName) async {
    await logAdminAction(
      action: AuditAction.pageAccessed,
    );
  }

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
          .collection('data_logs')
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

        // Convert Firestore Timestamp to DateTime string for display
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }

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
        'successful_backups':
            logs.where((log) => log['status'] == 'success').length,
        'failed_backups': logs.where((log) => log['status'] == 'failed').length,
        'file_types': <String, int>{},
        'recent_activity': logs.take(5).toList(),
      };

      // Count file types
      for (var log in logs) {
        final fileType = log['file_type'] as String?;
        if (fileType != null) {
          final fileTypes = stats['file_types'] as Map<String, int>;
          fileTypes[fileType] = (fileTypes[fileType] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Failed to fetch audit stats: $e');
      return {};
    }
  }
}
