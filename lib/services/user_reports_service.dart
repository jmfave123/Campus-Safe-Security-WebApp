import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notify_services.dart';

class UserReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get filtered reports stream
  Stream<QuerySnapshot> getFilteredReportsStream(
    String selectedDateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
  ) {
    Query query = _firestore.collection('reports_to_campus_security');

    // Apply date filters
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Week':
        startDate = DateTime(now.year, now.month, now.day - 7);
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Custom':
        if (customStartDate != null && customEndDate != null) {
          startDate = customStartDate;
          endDate = customEndDate
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
        }
        break;
      default: // 'All'
        break;
    }

    // Date filter
    if (startDate != null && endDate != null) {
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Add ordering
    return query.orderBy('timestamp', descending: true).limit(100).snapshots();
  }

  // Get filtered reports query (for PDF generation)
  Query getFilteredReportsQuery(
    String selectedDateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
  ) {
    Query query = _firestore.collection('reports_to_campus_security');

    // Apply date filters
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Week':
        startDate = DateTime(now.year, now.month, now.day - 7);
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Custom':
        if (customStartDate != null && customEndDate != null) {
          startDate = customStartDate;
          endDate = customEndDate
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
        }
        break;
      default: // 'All'
        break;
    }

    // Date filter
    if (startDate != null && endDate != null) {
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Add ordering
    return query.orderBy('timestamp', descending: true);
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String newStatus,
      [String? remarks]) async {
    try {
      // First, get the current report data to access the reporter's userId
      final reportDoc = await _firestore
          .collection('reports_to_campus_security')
          .doc(reportId)
          .get();

      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final reporterId = reportData['userId'];
      final reportTitle = reportData['incidentType'] ?? 'Report';
      final userName = reportData['userName'] ?? 'User';

      // Prepare update data for the report
      final Map<String, dynamic> updateData = {'status': newStatus};

      // Add or remove remarks based on status
      if (newStatus == 'resolved' && remarks != null) {
        updateData['resolveRemarks'] = remarks;
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'false information' && remarks != null) {
        updateData['falseInfoRemarks'] = remarks;
        updateData['falseInfoMarkedAt'] = FieldValue.serverTimestamp();
      }

      // Update the report
      await _firestore
          .collection('reports_to_campus_security')
          .doc(reportId)
          .update(updateData);

      // Create notification for the user
      if (reporterId != null) {
        // Create Firestore notification entry
        await _createUserNotification(
          reporterId: reporterId,
          reportId: reportId,
          reportTitle: reportTitle,
          newStatus: newStatus,
          remarks: remarks,
        );

        // Send push notification to user device
        try {
          // Generate notification message
          final String message =
              _generateNotificationMessage(reportTitle, newStatus);

          // Get the image URL from report data for big picture
          final String? imageUrl = reportData['imageUrl'];

          await NotifServices.sendNotificationToSpecificUser(
            userId: reporterId,
            heading: "Report Status Update",
            content: message,
            bigPicture: imageUrl,
          );

          print(
              'Push notification sent to $userName (ID: $reportId) about report status update');
        } catch (e) {
          // Log error but don't stop the process if push notification fails
          print('Error sending push notification: $e');
        }
      }
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  // Create user notification
  Future<void> _createUserNotification({
    required String reporterId,
    required String reportId,
    required String reportTitle,
    required String newStatus,
    String? remarks,
  }) async {
    try {
      // Generate notification message based on status
      final String message =
          _generateNotificationMessage(reportTitle, newStatus);

      // Create notification document
      await _firestore.collection('reports_notifications_for_users').add({
        'userId': reporterId,
        'reportId': reportId,
        'message': message,
        'status': newStatus,
        'remarks': remarks,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Silent error - don't prevent status update if notification fails
      print('Error creating user notification: $e');
    }
  }

  // Generate notification message
  String _generateNotificationMessage(String reportTitle, String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return 'Your report about "$reportTitle" is now being processed by our security team. We\'ll keep you updated on its progress.';
      case 'resolved':
        return 'Good news! Your report about "$reportTitle" has been resolved. You can check the details in the app.';
      case 'false information':
        return 'Your report about "$reportTitle" has been marked as containing incorrect information. Please check the app for more details.';
      default:
        return 'Your report about "$reportTitle" has been updated to "$status". Please check the app for more information.';
    }
  }

  // Get user profile image
  Future<String?> getUserProfileImage(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          return userData['profileImage'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile image: $e');
      return null;
    }
  }

  // Get available status options based on current status
  List<Map<String, dynamic>> getAvailableStatusOptions(String currentStatus) {
    final List<Map<String, dynamic>> allOptions = [
      {
        'value': 'pending',
        'label': 'Pending',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
      },
      {
        'value': 'in progress',
        'label': 'In Progress',
        'icon': Icons.engineering,
        'color': Colors.blue,
      },
      {
        'value': 'resolved',
        'label': 'Resolved',
        'icon': Icons.task_alt,
        'color': Colors.green,
      },
      {
        'value': 'false information',
        'label': 'False Information',
        'icon': Icons.report_problem,
        'color': Colors.red,
      },
    ];

    // Apply restrictions based on current status
    switch (currentStatus.toLowerCase()) {
      case 'in progress':
        // Can't go back to pending from in progress
        return allOptions.map((option) {
          if (option['value'] == 'pending') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      case 'resolved':
        // Can't change from resolved to any other status
        return allOptions.map((option) {
          if (option['value'] != 'resolved') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      case 'false information':
        // Can't change from false information to any other status
        return allOptions.map((option) {
          if (option['value'] != 'false information') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      default:
        // No restrictions for pending status
        return allOptions;
    }
  }

  // Get initials helper
  String getInitials(String name) {
    if (name.isEmpty) return 'NA';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  // Format date helper
  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
