import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AlcoholDetectionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'alcohol_detection_data';

  // Status constants
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusResolved = 'resolved';
  static const String statusCompleted = 'completed';
  static const String statusPending = 'pending';

  /// Get filtered detections stream
  static Stream<QuerySnapshot> getFilteredDetectionsStream({
    String? status,
    bool countOnly = false,
    DateRange? dateRange,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true);

      // Apply status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Apply date range filters to the query (not client-side)
      if (dateRange != null && !dateRange.useAll) {
        query = query
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
      }

      return query.limit(countOnly ? 100 : 50).snapshots();
    } catch (e) {
      print('Error in getFilteredDetectionsStream: $e');
      // Return an empty stream on error
      return _firestore.collection(_collection).limit(0).snapshots();
    }
  }

  /// Update detection status
  static Future<bool> updateDetectionStatus(String docId, bool isActive) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(docId)
          .update({'status': isActive ? statusResolved : statusActive});
      return true;
    } catch (e) {
      print('Error updating detection status: $e');
      return false;
    }
  }

  /// Filter detections by date range (client-side filtering)
  static List<QueryDocumentSnapshot> filterDetectionsByDateRange(
      List<QueryDocumentSnapshot> docs, DateRange dateRange) {
    if (dateRange.useAll) return docs;

    final startTimestamp = Timestamp.fromDate(dateRange.start);
    final endTimestamp = Timestamp.fromDate(dateRange.end);

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp == null) return false;

      return timestamp.compareTo(startTimestamp) >= 0 &&
          timestamp.compareTo(endTimestamp) <= 0;
    }).toList();
  }

  /// Get date range for filter
  static DateRange getDateRangeForFilter(
    String selectedFilter, {
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    final now = DateTime.now();

    try {
      switch (selectedFilter) {
        case 'Today':
          return DateRange(
            DateTime(now.year, now.month, now.day, 0, 0, 0),
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
        case 'Yesterday':
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          return DateRange(
            DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0),
            DateTime(
                yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
          );
        case 'Last Week':
          return DateRange(
            DateTime(now.year, now.month, now.day - 7, 0, 0, 0),
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
        case 'Last Month':
          DateTime oneMonthAgo;
          try {
            oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
          } catch (e) {
            oneMonthAgo = DateTime(now.year, now.month - 1, 1);
          }
          return DateRange(
            DateTime(
                oneMonthAgo.year, oneMonthAgo.month, oneMonthAgo.day, 0, 0, 0),
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
        case 'Custom':
          if (customStartDate != null && customEndDate != null) {
            return DateRange(
              DateTime(customStartDate.year, customStartDate.month,
                  customStartDate.day, 0, 0, 0),
              DateTime(customEndDate.year, customEndDate.month,
                  customEndDate.day, 23, 59, 59),
            );
          }
          return DateRange.all();
        default: // 'All'
          return DateRange.all();
      }
    } catch (e) {
      print('Error creating date range: $e');
      return DateRange.all();
    }
  }

  /// Generate PDF report
  static Future<bool> generatePdfReport({
    required List<QueryDocumentSnapshot> detections,
    required DateRange dateRange,
  }) async {
    try {
      // Load the logo image
      final ByteData logoData = await rootBundle.load('assets/ustpLogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(logoImage, width: 200, height: 100),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Alcohol Detection Report',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 20),
                      pw.Text(
                          'Date Range: ${_formatDateRangeForReport(dateRange)}',
                          style: const pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 10),
                      pw.Text(
                          'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 40),
                      pw.Text('Total Detections: ${detections.length}',
                          style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Add statistics page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            // Count statuses
            int activeCount = 0;
            int resolvedCount = 0;

            for (var doc in detections) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? statusActive;

              if (status == statusActive) {
                activeCount++;
              } else if (status == statusResolved) {
                resolvedCount++;
              }
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(logoImage, width: 100, height: 50),
                        pw.Text('Detection Statistics',
                            style: pw.TextStyle(
                                fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ]),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPdfStatBox('Total', detections.length.toString()),
                      _buildPdfStatBox('Active', activeCount.toString()),
                      _buildPdfStatBox('Resolved', resolvedCount.toString()),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Detection Details',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  _buildPdfDetectionTable(detections),
                ],
              ),
            );
          },
        ),
      );

      // Save the PDF
      final Uint8List pdfBytes = await pdf.save();

      // Download the PDF (for web)
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'alcohol_detection_report.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      return true;
    } catch (e) {
      print('Error generating PDF report: $e');
      return false;
    }
  }

  /// Helper method to format date range for report
  static String _formatDateRangeForReport(DateRange range) {
    if (range.useAll) {
      return 'All Time';
    }
    return '${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}';
  }

  /// Helper method to build PDF stat box
  static pw.Widget _buildPdfStatBox(String title, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Helper method to build PDF detection table
  static pw.Widget _buildPdfDetectionTable(
      List<QueryDocumentSnapshot> detections) {
    final headers = [
      'Student Name',
      'Student ID',
      'Course',
      'Detection Time',
      'Synced Time to Database',
      'BAC',
      'Status'
    ];

    final data = detections.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Detection Time (originalTimestamp)
      String detectionTime = 'No time applied';
      final originalTimestampRaw = data['originalTimestamp'];
      if (originalTimestampRaw != null) {
        DateTime? dt;
        if (originalTimestampRaw is String) {
          try {
            dt = DateTime.parse(originalTimestampRaw);
          } catch (_) {}
        } else if (originalTimestampRaw is Timestamp) {
          dt = originalTimestampRaw.toDate();
        }
        if (dt != null) {
          detectionTime = DateFormat('dd/MM/yyyy HH:mm').format(dt);
        }
      }
      // Synced Time (timestamp)
      String syncedTime = 'No time applied';
      final timestamp = data['timestamp'];
      if (timestamp != null) {
        DateTime? dt;
        if (timestamp is String) {
          try {
            dt = DateTime.parse(timestamp);
          } catch (_) {}
        } else if (timestamp is Timestamp) {
          dt = timestamp.toDate();
        }
        if (dt != null) {
          syncedTime = DateFormat('dd/MM/yyyy HH:mm').format(dt);
        }
      }
      return [
        data['studentName'] ?? 'N/A',
        data['studentId'] ?? 'N/A',
        data['studentCourse'] ?? 'N/A',
        detectionTime,
        syncedTime,
        '${data['bac'] ?? 'N/A'}',
        data['status'] ?? statusActive,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
    );
  }
}

/// DateRange class for date filtering
class DateRange {
  final DateTime start;
  final DateTime end;
  final bool useAll;

  const DateRange._internal(this.start, this.end, this.useAll);

  /// Creates a date range with validation
  factory DateRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      throw ArgumentError('Start date must be before end date');
    }
    return DateRange._internal(start, end, false);
  }

  /// Creates a date range for all dates (no filtering)
  factory DateRange.all() {
    return DateRange._internal(
      DateTime(2000),
      DateTime.now().add(const Duration(days: 1)),
      true,
    );
  }
}

/// Helper class for status display
class StatusInfo {
  final Color color;
  final IconData icon;

  const StatusInfo(this.color, this.icon);
}
