// lib/services/audit_wrapper.dart
import 'audit_log_service.dart';

/// Audit wrapper service to make integration easier
/// This provides a singleton instance and helper methods
class AuditWrapper {
  static final AuditWrapper _instance = AuditWrapper._internal();
  static AuditWrapper get instance => _instance;

  final AuditLogService _auditService = AuditLogService();

  AuditWrapper._internal();

  // Authentication & Security
  Future<void> logLogin() async {
    await _auditService.logLogin();
  }

  Future<void> logLogout() async {
    await _auditService.logLogout();
  }

  Future<void> logPasswordChanged() async {
    await _auditService.logPasswordChanged();
  }

  // Campus Status Management

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

  // Report Management
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

  // Alert Management
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

  // Communication & Announcements
  Future<void> logAnnouncementCreated() async {
    await _auditService.logAnnouncementCreated();
  }

  // Guard Management
  Future<void> logGuardProfileUpdated() async {
    await _auditService.logGuardProfileUpdated();
  }

  Future<void> logGuardVerified() async {
    await _auditService.logGuardVerified();
  }

  // Profile Management
  Future<void> logAdminProfileUpdated() async {
    await _auditService.logAdminProfileUpdated();
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
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }
}
