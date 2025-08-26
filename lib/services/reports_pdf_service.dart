import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class ReportsPDFService {
  // Generate and download report
  Future<void> generateAndDownloadReport({
    required Query reportsQuery,
    required String selectedDateFilter,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      // Get reports data based on current filter
      final QuerySnapshot reportsSnapshot = await reportsQuery.get();
      final List<Map<String, dynamic>> reportsData =
          reportsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        final formattedDate = timestamp != null
            ? DateFormat('MMM d, y HH:mm').format(timestamp.toDate())
            : 'Time not available';

        String? imageUrl = data['imageUrl'];

        return {
          'userName': data['userName'] ?? 'N/A',
          'incidentType': data['incidentType'] ?? 'N/A',
          'description': data['description'] ?? 'No description',
          'location': data['location'] ?? 'Unknown location',
          'date': formattedDate,
          'status': data['status'] ?? 'pending',
          'imageUrl': imageUrl,
        };
      }).toList();

      // Generate PDF
      final bytes = await _generatePDF(reportsData, selectedDateFilter);

      // Download PDF
      _downloadPDF(bytes);
      onSuccess();
    } catch (e) {
      onError('Error generating report: $e');
    }
  }

  // Generate PDF Report
  Future<Uint8List> _generatePDF(
      List<Map<String, dynamic>> reportsData, String selectedDateFilter) async {
    // Download images first if available
    final List<Map<String, dynamic>> reportsWithImages =
        await Future.wait(reportsData.map((report) async {
      final imageUrl = report['imageUrl'];
      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            return {...report, 'imageData': response.bodyBytes};
          }
        } catch (e) {
          // Silently continue without the image
        }
      }
      // Return original report if no image or error
      return report;
    }));

    // Load the logo image
    final ByteData logoData = await rootBundle.load('assets/ustpLogo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    // Create a PDF document
    final pdf = pw.Document();

    // Add a title page
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo at top left
              pw.Image(logoImage, width: 200, height: 100),
              pw.SizedBox(height: 20),
              // Centered content
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Campus Safety Reports',
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
                          pw.Text('Total Reports: ${reportsData.length}'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              'Pending Reports: ${reportsData.where((report) => report['status'] == 'pending').length}'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              'In Progress: ${reportsData.where((report) => report['status'] == 'in progress').length}'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              'Resolved Reports: ${reportsData.where((report) => report['status'] == 'resolved').length}'),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              'False Information: ${reportsData.where((report) => report['status'] == 'false information').length}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }));

    // Create a table for the reports data
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo and title in a row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo at the top left with consistent size
                  pw.Image(logoImage, width: 100, height: 50),
                  pw.Text(
                    'Campus Safety Reports - Details',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: [
                'Reported By',
                'Incident Type',
                'Location',
                'Description',
                'Date',
                'Status'
              ],
              data: reportsWithImages.map((report) {
                return [
                  report['userName'],
                  report['incidentType'],
                  report['location'],
                  report['description'],
                  report['date'],
                  report['status'],
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

    // Add pages with images (if available)
    for (var report in reportsWithImages) {
      final imageData = report['imageData'];
      if (imageData != null && _isValidImageData(imageData)) {
        await _addImagePageToPdf(pdf, report, imageData, logoImage);
      }
    }

    // Save the PDF
    return await pdf.save();
  }

  // Method to handle the actual download
  void _downloadPDF(Uint8List bytes) {
    try {
      // For web platform, use html for downloading
      if (kIsWeb) {
        final fileName =
            'campus_reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

        // Create a blob from bytes
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  // Verify image data is valid
  bool _isValidImageData(Uint8List? data) {
    if (data == null || data.isEmpty) {
      return false;
    }

    // Check for common image format headers
    if (data.length > 4) {
      // Check for JPEG header (starts with FF D8 FF)
      if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
        return true;
      }

      // Check for PNG header (starts with 89 50 4E 47)
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        return true;
      }
    }
    return false;
  }

  // Helper method to add image pages to PDF with fallback options
  Future<void> _addImagePageToPdf(
      pw.Document pdf, Map<String, dynamic> report, Uint8List imageData,
      [pw.MemoryImage? logoImage]) async {
    try {
      // Create a new page for this image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            // Try to create the image widget
            pw.Widget imageWidget;
            try {
              final image = pw.MemoryImage(imageData);
              imageWidget = pw.Image(image);
            } catch (e) {
              // Fallback to an error message
              imageWidget = pw.Container(
                height: 200,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Center(
                  child: pw.Text(
                    'Image could not be displayed',
                    style: const pw.TextStyle(color: PdfColors.red),
                  ),
                ),
              );
            }

            // The page content with logo at top left and centered content
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo at top left with consistent size
                if (logoImage != null)
                  pw.Image(logoImage, width: 100, height: 50),
                pw.SizedBox(height: 16),

                // Row with title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Report Image: ${report['incidentType']}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Centered report details
                pw.Center(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Reported by: ${report['userName']} on ${report['date']}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Location: ${report['location']}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        height: 300,
                        child: pw.Center(
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.grey300,
                                width: 1,
                              ),
                            ),
                            padding: const pw.EdgeInsets.all(8),
                            child: imageWidget,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'Description:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        report['description'] ?? 'No description provided',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      // Silently handle errors in PDF image page generation
    }
  }
}
