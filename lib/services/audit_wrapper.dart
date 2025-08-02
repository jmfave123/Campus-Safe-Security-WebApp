// lib/services/audit_wrapper.dart
import 'audit_log_service.dart';

/// Audit wrapper service to make integration easier
/// This provides a singleton instance and helper methods
class AuditWrapper {
  static final AuditWrapper _instance = AuditWrapper._internal();
  static AuditWrapper get instance => _instance;

  final AuditLogService _auditService = AuditLogService();

  AuditWrapper._internal();

  // Page tracking
  static const Map<int, String> _pageNames = {
    0: 'Dashboard',
    1: 'Campus Status',
    2: 'Alcohol Detection',
    3: 'Throw Alerts',
    4: 'User Logs',
    5: 'Reports',
    6: 'Gemini Chat',
    7: 'Audit Logs',
    8: 'Settings',
  };

  // Wrapper methods for easy access
  Future<void> logPageAccess(int pageIndex) async {
    final pageName = _pageNames[pageIndex] ?? 'Unknown Page';
    await _auditService.logPageAccess(pageName);
  }

  Future<void> logLogin() async {
    await _auditService.logLogin();
  }

  Future<void> logLogout() async {
    await _auditService.logLogout();
  }

  Future<void> logDashboardAccess() async {
    await _auditService.logDashboardAccess();
  }

  Future<void> logStatusUpdate({
    required String newStatus,
    required String reason,
    String? previousStatus,
  }) async {
    await _auditService.logStatusUpdate(
      newStatus: newStatus,
      reason: reason,
      previousStatus: previousStatus,
    );
  }

  Future<void> logReportViewed(String reportId) async {
    await _auditService.logReportViewed(reportId);
  }

  Future<void> logReportStatusUpdate({
    required String reportId,
    required String newStatus,
    String? previousStatus,
  }) async {
    await _auditService.logReportStatusUpdate(
      reportId: reportId,
      newStatus: newStatus,
      previousStatus: previousStatus,
    );
  }

  Future<void> logReportExport({
    required String exportType,
    required String fileName,
    int? reportCount,
  }) async {
    await _auditService.logReportExport(
      exportType: exportType,
      fileName: fileName,
      reportCount: reportCount,
    );
  }

  Future<void> logAlertCreated({
    required String alertId,
    required String message,
    required String targetAudience,
  }) async {
    await _auditService.logAlertCreated(
      alertId: alertId,
      message: message,
      targetAudience: targetAudience,
    );
  }

  Future<void> logAlertEdited({
    required String alertId,
    required String newMessage,
    String? previousMessage,
  }) async {
    await _auditService.logAlertEdited(
      alertId: alertId,
      newMessage: newMessage,
      previousMessage: previousMessage,
    );
  }

  Future<void> logAlertDeleted(String alertId) async {
    await _auditService.logAlertDeleted(alertId);
  }

  // Generic action logging
  Future<void> logAction({
    required AuditAction action,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? details,
    String? description,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    await _auditService.logAdminAction(
      action: action,
      description: description,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }
}
