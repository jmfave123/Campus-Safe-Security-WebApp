// lib/services/announcement_services.dart

/// Announcement Service - Backend logic for managing campus announcements
///
/// This service handles all backend operations for announcements including:
/// - Creating and sending announcements to target audiences
/// - Updating and deleting existing announcements
/// - Filtering and querying announcements with date ranges
/// - Getting target audience counts and statistics
/// - Managing push notifications through NotifServices
/// - Image upload handling through existing services
/// - PDF report generation and download functionality
///
/// Usage Example:
/// ```dart
/// final service = AnnouncementService();
///
/// // Create announcement
/// final result = await service.createAnnouncement(
///   message: "Emergency announcement",
///   target: AlertTarget.all,
///   imageData: myImageBytes,
///   imageName: "alert.jpg"
/// );
///
/// // Get filtered stream
/// final stream = service.getFilteredAlertsStream(
///   selectedDateFilter: "Last Week",
///   limit: 20
/// );
///
/// // Generate PDF report
/// final alertsData = await service.prepareAlertDataForPDF();
/// final pdfResult = await service.generatePDFReport(
///   alertsData: alertsData,
///   selectedDateFilter: "All"
/// );
///
/// // Get statistics
/// final stats = await service.getAnnouncementStats();
/// ```
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:html' as html;
import 'notify_services.dart';
import 'add_security_guard_services.dart'; // For image upload

enum AlertTarget { student, facultyStaff, all }

class AnnouncementResult {
  final bool success;
  final String? error;
  final String? documentId;
  final Map<String, dynamic>? alertData;

  AnnouncementResult({
    required this.success,
    this.error,
    this.documentId,
    this.alertData,
  });
}

class AnnouncementUpdateResult {
  final bool success;
  final String? error;

  AnnouncementUpdateResult({
    required this.success,
    this.error,
  });
}

class PdfGenerationResult {
  final bool success;
  final String? error;
  final Uint8List? pdfBytes;
  final String? fileName;

  PdfGenerationResult({
    required this.success,
    this.error,
    this.pdfBytes,
    this.fileName,
  });
}

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert AlertTarget enum to display text
  String getTargetText(AlertTarget target) {
    switch (target) {
      case AlertTarget.student:
        return 'Student';
      case AlertTarget.facultyStaff:
        return 'Faculty & Staff';
      case AlertTarget.all:
        return 'All Users';
    }
  }

  // Get target count for specific audience
  Future<int> getTargetCount(AlertTarget target) async {
    try {
      QuerySnapshot query;
      if (target == AlertTarget.all) {
        query = await _firestore.collection('users').get();
      } else {
        String userType =
            target == AlertTarget.student ? 'Student' : 'Faculty & Staff';
        query = await _firestore
            .collection('users')
            .where('userType', isEqualTo: userType)
            .get();
      }
      return query.docs.length;
    } catch (e) {
      print('Error getting target count: $e');
      return 0;
    }
  }

  // Get detailed target count for analytics
  Future<Map<String, int>> getDetailedTargetCount(String target) async {
    try {
      int students = 0;
      int faculty = 0;

      if (target == 'all' || target == 'student') {
        final studentQuery = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'Student')
            .get();
        students = studentQuery.docs.length;
      }

      if (target == 'all' || target == 'facultyStaff') {
        final facultyQuery = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'Faculty & Staff')
            .get();
        faculty = facultyQuery.docs.length;
      }

      return {'students': students, 'faculty': faculty};
    } catch (e) {
      print('Error getting detailed target count: $e');
      return {'students': 0, 'faculty': 0};
    }
  }

  // Send push notification to target audience
  Future<void> sendPushNotification(
    String message,
    AlertTarget target, {
    String? bigPictureUrl,
  }) async {
    try {
      String userType;
      switch (target) {
        case AlertTarget.student:
          userType = "Student";
          break;
        case AlertTarget.facultyStaff:
          userType = "Faculty & Staff";
          break;
        case AlertTarget.all:
          // Send to both groups
          await Future.wait([
            NotifServices.sendGroupNotification(
              userType: "Student",
              heading: "Security Announcement",
              content: message,
              bigPicture: bigPictureUrl,
            ),
            NotifServices.sendGroupNotification(
              userType: "Faculty & Staff",
              heading: "Security Announcement",
              content: message,
              bigPicture: bigPictureUrl,
            ),
          ]);
          return;
      }

      await NotifServices.sendGroupNotification(
        userType: userType,
        heading: "Security Announcement",
        content: message,
        bigPicture: bigPictureUrl,
      );

      print('Sending notification to userType: $userType');
    } catch (e) {
      print('Push notification error: $e');
      rethrow; // Let the calling method handle the error
    }
  }

  // Create and send announcement
  Future<AnnouncementResult> createAnnouncement({
    required String message,
    required AlertTarget target,
    Uint8List? imageData,
    String? imageName,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageData != null && imageName != null) {
        try {
          final uploadResult = await uploadImage(imageData, imageName);
          imageUrl = uploadResult['secure_url'] as String?;
        } catch (e) {
          print('Image upload error: $e');
          // Continue without image if upload fails
        }
      }

      // Create alert document
      final alertData = {
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'target': target.toString().split('.').last,
        'targetDisplay': getTargetText(target),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (imageName != null) 'imageName': imageName,
      };

      // Add to Firestore
      final docRef = await _firestore.collection('alerts_data').add(alertData);

      // Send push notification
      await sendPushNotification(
        message.trim(),
        target,
        bigPictureUrl: imageUrl,
      );

      return AnnouncementResult(
        success: true,
        documentId: docRef.id,
        alertData: alertData,
      );
    } catch (e) {
      print('Error creating announcement: $e');
      return AnnouncementResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Update existing announcement
  Future<AnnouncementUpdateResult> updateAnnouncement({
    required String documentId,
    required String newMessage,
    required AlertTarget newTarget,
    required String newStatus,
    bool resendNotification = false, // New parameter to control resending
  }) async {
    try {
      final updateData = {
        'message': newMessage.trim(),
        'target': newTarget.toString().split('.').last,
        'targetDisplay': getTargetText(newTarget),
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('alerts_data')
          .doc(documentId)
          .update(updateData);

      // Send push notification if requested and status is active
      if (resendNotification && newStatus == 'active') {
        try {
          // Get the image URL from the existing document if it exists
          final doc =
              await _firestore.collection('alerts_data').doc(documentId).get();
          String? imageUrl;
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            imageUrl = data['imageUrl'] as String?;
          }

          await sendPushNotification(
            newMessage.trim(),
            newTarget,
            bigPictureUrl: imageUrl,
          );
        } catch (notificationError) {
          print(
              'Error sending notification for updated announcement: $notificationError');
          // Don't fail the entire update if notification fails
        }
      }

      return AnnouncementUpdateResult(success: true);
    } catch (e) {
      print('Error updating announcement: $e');
      return AnnouncementUpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Get filtered alerts stream with date filtering
  Stream<QuerySnapshot> getFilteredAlertsStream({
    String selectedDateFilter = "All",
    DateTime? customStartDate,
    DateTime? customEndDate,
    int limit = 10,
  }) {
    Query query = _firestore.collection('alerts_data');

    // Apply date filters
    if (selectedDateFilter != 'All') {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

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
          } else {
            return query
                .orderBy('timestamp', descending: true)
                .limit(limit)
                .snapshots();
          }
          break;
        default:
          return query
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .snapshots();
      }

      return query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();
    }

    // Default to showing all recent alerts
    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get filtered alerts query (for report generation)
  Query getFilteredAlertsQuery({
    String selectedDateFilter = "All",
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    Query query = _firestore.collection('alerts_data');

    // Apply date filters
    if (selectedDateFilter != 'All') {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

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
          } else {
            return query.orderBy('timestamp', descending: true);
          }
          break;
        default:
          return query.orderBy('timestamp', descending: true);
      }

      return query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true);
    }

    // Default to showing all alerts
    return query.orderBy('timestamp', descending: true);
  }

  // Get announcement statistics
  Future<Map<String, int>> getAnnouncementStats({
    String selectedDateFilter = "All",
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final query = getFilteredAlertsQuery(
        selectedDateFilter: selectedDateFilter,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );

      final snapshot = await query.get();

      int totalAlerts = snapshot.docs.length;
      int activeAlerts = 0;
      int inactiveAlerts = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'active';
        if (status == 'active') {
          activeAlerts++;
        } else {
          inactiveAlerts++;
        }
      }

      return {
        'total': totalAlerts,
        'active': activeAlerts,
        'inactive': inactiveAlerts,
      };
    } catch (e) {
      print('Error getting announcement stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }

  // Delete announcement
  Future<AnnouncementUpdateResult> deleteAnnouncement(String documentId) async {
    try {
      await _firestore.collection('alerts_data').doc(documentId).delete();
      return AnnouncementUpdateResult(success: true);
    } catch (e) {
      print('Error deleting announcement: $e');
      return AnnouncementUpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Get single announcement by ID
  Future<Map<String, dynamic>?> getAnnouncementById(String documentId) async {
    try {
      final doc =
          await _firestore.collection('alerts_data').doc(documentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting announcement by ID: $e');
      return null;
    }
  }

  // Convert string target to AlertTarget enum
  AlertTarget stringToAlertTarget(String target) {
    switch (target) {
      case 'student':
        return AlertTarget.student;
      case 'facultyStaff':
        return AlertTarget.facultyStaff;
      case 'all':
      default:
        return AlertTarget.all;
    }
  }

  // Get real-time statistics stream for dashboard
  Stream<Map<String, int>> getAnnouncementStatsStream({
    String selectedDateFilter = "All",
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return getFilteredAlertsStream(
      selectedDateFilter: selectedDateFilter,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
      limit: 1000, // Get more data for accurate stats
    ).map((snapshot) {
      int totalAlerts = snapshot.docs.length;
      int activeAlerts = 0;
      int inactiveAlerts = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'active';
        if (status == 'active') {
          activeAlerts++;
        } else {
          inactiveAlerts++;
        }
      }

      return {
        'total': totalAlerts,
        'active': activeAlerts,
        'inactive': inactiveAlerts,
      };
    });
  }

  // PDF Report Generation
  Future<PdfGenerationResult> generatePDFReport({
    required List<Map<String, dynamic>> alertsData,
    required String selectedDateFilter,
  }) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Load the logo image
      final ByteData logoData = await rootBundle.load('assets/ustpLogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      // Add a title page
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add logo image to the PDF at the top left
                pw.Image(logoImage, width: 200, height: 100),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Campus Safety Announcements Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Generated on: ${DateFormat('MMMM d, y HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Filter: $selectedDateFilter',
                        style: const pw.TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Summary:',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                                'Total Announcements: ${alertsData.length}'),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'Active Announcements: ${alertsData.where((alert) => alert['status'] == 'active').length}'),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'Inactive Announcements: ${alertsData.where((alert) => alert['status'] != 'active').length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }));

      // Create a table for the alert data
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add logo to subsequent pages (smaller size)
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo at the top left
                      pw.Image(logoImage, width: 100, height: 50),
                      pw.Text(
                        'Campus Safety Announcements - Details',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ]),
                pw.SizedBox(height: 5),
                pw.Divider(),
              ],
            );
          },
          build: (pw.Context context) {
            // Create a table
            return [
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                },
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['Announcement Message', 'Date', 'Target', 'Status'],
                data: alertsData.map((alert) {
                  return [
                    alert['message'],
                    alert['date'],
                    alert['target'],
                    alert['status'] == 'active' ? 'Active' : 'Inactive',
                  ];
                }).toList(),
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
        ),
      );

      // Save the PDF and return bytes
      final bytes = await pdf.save();
      final fileName =
          'campus_alerts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      return PdfGenerationResult(
        success: true,
        pdfBytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      print('PDF generation error: $e');
      return PdfGenerationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Download PDF for web platform
  void downloadPDFWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      try {
        // Create a blob from bytes
        final blob = html.Blob([bytes], 'application/pdf');

        // Create a URL for the blob
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create an anchor element with download attribute
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        // Add anchor to the body
        html.document.body?.children.add(anchor);

        // Trigger download and remove anchor
        anchor.click();
        html.document.body?.children.remove(anchor);

        // Release the object URL
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        print('Web PDF download error: $e');
        rethrow;
      }
    }
  }

  // Save PDF for mobile platform
  Future<String> savePDFMobile(Uint8List bytes, String fileName) async {
    try {
      // Get the app's documents directory to save the file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      // Write the PDF to the file
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      print('Mobile PDF save error: $e');

      // Fallback: try to use Downloads folder
      try {
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File('${directory.path}/$fileName');

        // Write the PDF to the file
        await file.writeAsBytes(bytes);

        return 'Downloads folder: $fileName';
      } catch (fallbackError) {
        print('Fallback PDF save error: $fallbackError');
        rethrow;
      }
    }
  }

  // Open PDF file (mobile only)
  void openPDFFile(String filePath) {
    if (!kIsWeb) {
      OpenFile.open(filePath);
    }
  }

  // Prepare alert data for PDF generation
  Future<List<Map<String, dynamic>>> prepareAlertDataForPDF({
    String selectedDateFilter = "All",
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final query = getFilteredAlertsQuery(
        selectedDateFilter: selectedDateFilter,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        final formattedDate = timestamp != null
            ? DateFormat('MMM d, y HH:mm').format(timestamp.toDate())
            : 'Time not available';

        return {
          'message': data['message'] ?? 'No message',
          'date': formattedDate,
          'status': data['status'] ?? 'unknown',
          'target': data['targetDisplay'] ?? 'All Users',
        };
      }).toList();
    } catch (e) {
      print('Error preparing alert data for PDF: $e');
      return [];
    }
  }
}
