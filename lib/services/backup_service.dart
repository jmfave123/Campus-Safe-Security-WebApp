// lib/services/backup_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'audit_log_service.dart';

// Conditional imports for web and mobile
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

// For web download
import 'package:universal_html/html.dart' as html;

enum BackupFormat { json, csv, excel }

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLog = AuditLogService();

  // Helper method to convert Firestore data to a JSON-serializable format
  dynamic _convertFirestoreData(dynamic data) {
    if (data == null) return null;

    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return Map<String, dynamic>.fromEntries((data)
          .entries
          .map((e) => MapEntry(e.key, _convertFirestoreData(e.value))));
    } else if (data is List) {
      return data.map((e) => _convertFirestoreData(e)).toList();
    } else if (data is DocumentReference) {
      return data.path;
    } else if (data is GeoPoint) {
      return {'latitude': data.latitude, 'longitude': data.longitude};
    } else if (data is DateTime) {
      return data.toIso8601String();
    }

    // For any other type, return as is
    return data;
  }

  // Create a backup with specified format
  Future<String> createBackup(BackupFormat format) async {
    final startTime = DateTime.now();
    String? fileName;
    int totalRecords = 0;

    try {
      // 1. Get all collections from Firestore
      final Map<String, dynamic> allData = {};

      // 2. Define the collections we want to back up
      final collections = [
        'users',
        'reports_to_campus_security',
        'alcohol_detection_data',
        'alerts_data'
      ];

      // 3. Fetch all documents from each collection
      for (var collectionName in collections) {
        try {
          final querySnapshot =
              await _firestore.collection(collectionName).get();
          final documents = querySnapshot.docs.map((doc) {
            final data = doc.data();
            // Convert Firestore-specific types to primitive types
            final cleanData = _convertFirestoreData(data);
            return {
              'id': doc.id,
              'data': cleanData,
            };
          }).toList();

          allData[collectionName] = {
            'documents': documents,
          };
          totalRecords += documents.length;
        } catch (e) {
          // If a collection doesn't exist or can't be accessed, log and continue
          print('Warning: Could not access collection $collectionName: $e');
        }
      }

      if (allData.isEmpty) {
        throw Exception('No data available to backup');
      }

      // 4. Generate backup based on format
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileExtension = format.name;
      fileName = 'campus_safe_backup_$timestamp.$fileExtension';

      String result;
      switch (format) {
        case BackupFormat.json:
          result = await _createJsonBackup(allData, timestamp);
          break;
        case BackupFormat.csv:
          result = await _createCsvBackup(allData, timestamp);
          break;
        case BackupFormat.excel:
          result = await _createExcelBackup(allData, timestamp);
          break;
      }

      // Log successful backup
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      await _auditLog.logBackupOperation(
        action: 'backup_created',
        fileType: format.name,
        fileName: fileName,
        status: 'success',
        recordCount: totalRecords,
        durationMs: duration,
      );

      return result;
    } catch (e) {
      // Log failed backup
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      await _auditLog.logBackupOperation(
        action: 'backup_failed',
        fileType: format.name,
        fileName: fileName ?? 'unknown',
        status: 'failed',
        recordCount: totalRecords,
        durationMs: duration,
        errorMessage: e.toString(),
      );

      print('Backup failed: $e');
      rethrow;
    }
  }

  // Open the backup file using a file viewer (mobile only)
  static Future<void> openBackupFile(String filePath) async {
    if (kIsWeb) {
      // Not applicable for web
      return;
    }
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error opening file: $e');
      rethrow;
    }
  }

  // Create JSON backup
  Future<String> _createJsonBackup(
      Map<String, dynamic> allData, String timestamp) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
    final filename = 'campus_safe_backup_$timestamp.json';

    if (kIsWeb) {
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'JSON backup download started: $filename';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(jsonString);
      return 'JSON backup saved to: ${file.path}';
    }
  }

  // Create CSV backup (single file with all collections separated)
  Future<String> _createCsvBackup(
      Map<String, dynamic> allData, String timestamp) async {
    final List<String> csvSections = [];
    bool hasData = false;

    for (var entry in allData.entries) {
      final collectionName = entry.key;
      final documents = entry.value['documents'] as List;

      if (documents.isEmpty) continue;

      // Add collection section header
      csvSections.add(''); // Empty line for separation
      csvSections.add('=== $collectionName Collection ===');
      csvSections.add(''); // Empty line

      // Create CSV content for this collection
      final csvContent = _convertToCSV(documents);
      csvSections.add(csvContent);
      hasData = true;
    }

    // If no data, create a summary
    if (!hasData) {
      csvSections.add('No data available for backup');
      csvSections.add('Timestamp: ${DateTime.now().toIso8601String()}');
    }

    final finalCsvContent = csvSections.join('\n');
    final filename = 'campus_safe_backup_$timestamp.csv';

    if (kIsWeb) {
      final bytes = utf8.encode(finalCsvContent);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'CSV backup download started: $filename';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(finalCsvContent);
      return 'CSV backup saved to: ${file.path}';
    }
  }

  // Create Excel backup (one worksheet per collection)
  Future<String> _createExcelBackup(
      Map<String, dynamic> allData, String timestamp) async {
    final excel = Excel.createExcel();

    // Keep track of sheets created
    bool hasData = false;

    for (var entry in allData.entries) {
      final collectionName = entry.key;
      final documents = entry.value['documents'] as List;

      if (documents.isEmpty) {
        continue;
      }

      // Create a new sheet for this collection
      final sheet = excel[collectionName];
      _addDataToExcelSheet(sheet, documents);
      hasData = true;
    }

    // Remove default sheet only if we have data
    if (hasData && excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // If no data was added, create a summary sheet
    if (!hasData) {
      final summarySheet = excel['Summary'];
      summarySheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('No data available for backup');
      summarySheet.cell(CellIndex.indexByString('A2')).value =
          TextCellValue('Timestamp: ${DateTime.now().toIso8601String()}');
    }

    final filename = 'campus_safe_backup_$timestamp.xlsx';
    final excelBytes = excel.save();

    if (kIsWeb) {
      final blob = html.Blob([excelBytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'Excel backup download started: $filename';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(excelBytes!);
      return 'Excel backup saved to: ${file.path}';
    }
  }

  // Convert documents to CSV format
  String _convertToCSV(List documents) {
    if (documents.isEmpty) return '';

    // Get all unique keys from all documents
    final Set<String> allKeys = {'id'};
    for (var doc in documents) {
      final data = doc['data'] as Map<String, dynamic>;
      allKeys.addAll(_flattenKeys(data));
    }

    final List<String> csvLines = [];

    // Add header
    csvLines.add(allKeys.map((key) => '"$key"').join(','));

    // Add data rows
    for (var doc in documents) {
      final List<String> row = [];
      final docId = doc['id'];
      final data = doc['data'] as Map<String, dynamic>;
      final flatData = _flattenMap(data);

      for (var key in allKeys) {
        if (key == 'id') {
          row.add('"$docId"');
        } else {
          final value = flatData[key]?.toString() ?? '';
          row.add('"${value.replaceAll('"', '""')}"');
        }
      }
      csvLines.add(row.join(','));
    }

    return csvLines.join('\n');
  }

  // Add data to Excel sheet
  void _addDataToExcelSheet(Sheet sheet, List documents) {
    if (documents.isEmpty) {
      return;
    }

    // Get all unique keys from all documents (same as CSV approach)
    final Set<String> allKeys = {'id'};
    for (var doc in documents) {
      final data = doc['data'] as Map<String, dynamic>;
      allKeys.addAll(_flattenKeys(data));
    }

    final keysList = allKeys.toList();

    // Add headers
    for (int i = 0; i < keysList.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(keysList[i]);
    }

    // Add data rows (same logic as CSV)
    for (int rowIndex = 0; rowIndex < documents.length; rowIndex++) {
      final doc = documents[rowIndex];
      final docId = doc['id'];
      final data = doc['data'] as Map<String, dynamic>;
      final flatData = _flattenMap(data);

      for (int colIndex = 0; colIndex < keysList.length; colIndex++) {
        final key = keysList[colIndex];
        dynamic value;

        if (key == 'id') {
          value = docId;
        } else {
          value = flatData[key];
        }

        // Convert value to string, handling null values properly
        final cellValue = value?.toString() ?? '';

        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(cellValue);
      }
    }
  }

  // Flatten nested maps for CSV/Excel
  Map<String, dynamic> _flattenMap(Map<String, dynamic> map,
      [String prefix = '']) {
    final Map<String, dynamic> result = {};

    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '${prefix}_$key';

      if (value is Map<String, dynamic>) {
        result.addAll(_flattenMap(value, newKey));
      } else if (value is List) {
        result[newKey] = value.join('; ');
      } else {
        result[newKey] = value;
      }
    });

    return result;
  }

  // Get all keys from flattened map
  Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
    final Set<String> keys = {};

    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '${prefix}_$key';

      if (value is Map<String, dynamic>) {
        keys.addAll(_flattenKeys(value, newKey));
      } else {
        keys.add(newKey);
      }
    });

    return keys;
  }
}
