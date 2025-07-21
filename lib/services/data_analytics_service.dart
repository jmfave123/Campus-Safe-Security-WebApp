// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../repositories/data_repository.dart';

// /// Service class responsible for data analytics operations
// ///
// /// This class follows the Single Responsibility Principle by handling
// /// all data analytics operations in one place, separating them from UI components.
// class DataAnalyticsService {
//   final DataRepository _repository;

//   // Dependency injection through constructor
//   DataAnalyticsService({DataRepository? repository})
//       : _repository = repository ?? FirebaseDataRepository();

//   /// Get reports data from a specific collection
//   Stream<QuerySnapshot> getCollectionStream(
//       String collectionName, String orderByField,
//       {bool descending = false}) {
//     return _repository.getCollectionStream(collectionName, orderByField,
//         descending: descending);
//   }

//   /// Count unique reports based on reportId
//   int countUniqueReports(List<QueryDocumentSnapshot> documents) {
//     final Set<String> uniqueReportIds = {};

//     for (var doc in documents) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data.containsKey(DatabasePaths.reportIdField)) {
//         uniqueReportIds.add(data[DatabasePaths.reportIdField].toString());
//       } else {
//         // If no reportId, use document ID
//         uniqueReportIds.add(doc.id);
//       }
//     }

//     return uniqueReportIds.length;
//   }

//   /// Get total reports count from both collections
//   Future<int> getTotalReportsCount() async {
//     try {
//       // Get reports count
//       final reportsSnapshot =
//           await _repository.getCollection(DatabasePaths.reportsCollection);

//       // Get alcohol detection data count
//       final alcoholDataSnapshot = await _repository
//           .getCollection(DatabasePaths.alcoholDetectionCollection);

//       // Count unique reports based on reportId to avoid duplicates
//       final Set<String> uniqueReportIds = {};

//       // Add report IDs from reports_to_campus_security
//       for (var doc in reportsSnapshot.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         if (data.containsKey(DatabasePaths.reportIdField)) {
//           uniqueReportIds.add(data[DatabasePaths.reportIdField].toString());
//         } else {
//           // If no reportId, use document ID
//           uniqueReportIds.add(doc.id);
//         }
//       }

//       // Add alcohol detection data count
//       final alcoholCount = alcoholDataSnapshot.docs.length;

//       // Return the combined total
//       return uniqueReportIds.length + alcoholCount;
//     } catch (e) {
//       print('Error calculating total reports: $e');
//       return 0;
//     }
//   }

//   /// Determines the most appropriate timestamp field from a collection of documents
//   String determineTimestampField(List<QueryDocumentSnapshot> documents) {
//     final Set<String> timestampFields = {
//       'timestamp',
//       'dateDetected',
//       'createdAt',
//       'date',
//       'detectedAt'
//     };

//     final Map<String, int> fieldCounts = {};
//     for (String field in timestampFields) {
//       fieldCounts[field] = 0;
//     }

//     for (var doc in documents) {
//       final data = doc.data() as Map<String, dynamic>;
//       for (String field in timestampFields) {
//         if (data.containsKey(field)) {
//           fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
//         }
//       }
//     }

//     // Use the most common timestamp field or fallback to 'timestamp'
//     String mostCommonField = DatabasePaths.timestampField;
//     int maxCount = 0;
//     fieldCounts.forEach((field, count) {
//       if (count > maxCount) {
//         maxCount = count;
//         mostCommonField = field;
//       }
//     });

//     return mostCommonField;
//   }

//   /// Process monthly report data for charts
//   Map<String, dynamic> processMonthlyReportData(
//     List<QueryDocumentSnapshot> documents, {
//     required String timestampField,
//     bool countUniqueIds = false,
//     bool includeAllMonths = false,
//   }) {
//     final Map<String, int> monthlyReportCounts = {};
//     final Map<String, Set<String>> monthlyUniqueDocIds = {};
//     final now = DateTime.now();

//     // Define standard month order from January to December
//     final List<String> monthAbbr = [
//       'JAN',
//       'FEB',
//       'MAR',
//       'APR',
//       'MAY',
//       'JUN',
//       'JUL',
//       'AUG',
//       'SEP',
//       'OCT',
//       'NOV',
//       'DEC'
//     ];
//     List<String> monthKeys = [];

//     // Initialize all months in the current year with zero counts
//     for (int i = 0; i < 12; i++) {
//       final month = DateTime(now.year, i + 1, 1);
//       final monthKey = DateFormat('MMM yyyy').format(month);
//       monthKeys.add(monthKey);
//       monthlyReportCounts[monthKey] = 0;
//     }

//     // Count reports by month
//     for (var doc in documents) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data.containsKey(timestampField)) {
//         final dynamic timestampData = data[timestampField];
//         // Handle different timestamp formats
//         DateTime date;
//         if (timestampData is Timestamp) {
//           date = timestampData.toDate();
//         } else if (timestampData is int) {
//           // Handle cases where timestamp might be stored as milliseconds
//           date = DateTime.fromMillisecondsSinceEpoch(timestampData);
//         } else if (timestampData is String) {
//           // Try to parse string format
//           try {
//             date = DateTime.parse(timestampData);
//           } catch (e) {
//             print(
//                 'Error parsing timestamp string: $e for doc ${doc.id}. Skipping.');
//             continue;
//           }
//         } else {
//           print('Unsupported timestamp format for doc ${doc.id}. Skipping.');
//           continue;
//         }

//         // Only consider reports from the current year or include all if specified
//         if (date.year == now.year || includeAllMonths) {
//           final monthKey =
//               DateFormat('MMM yyyy').format(DateTime(date.year, date.month, 1));

//           // Check if we need to add this month to our tracking
//           if (!monthlyReportCounts.containsKey(monthKey) && includeAllMonths) {
//             // Only add if we don't exceed 12 months total
//             if (monthKeys.length < 12) {
//               monthKeys.add(monthKey);
//               monthlyReportCounts[monthKey] = 0;
//               if (countUniqueIds) {
//                 monthlyUniqueDocIds[monthKey] = <String>{};
//               }
//             }
//           }

//           if (countUniqueIds) {
//             // Only count each document once per month
//             if (!monthlyUniqueDocIds.containsKey(monthKey)) {
//               monthlyUniqueDocIds[monthKey] = <String>{};
//             }

//             if (!monthlyUniqueDocIds[monthKey]!.contains(doc.id)) {
//               monthlyUniqueDocIds[monthKey]!.add(doc.id);
//               monthlyReportCounts[monthKey] =
//                   (monthlyReportCounts[monthKey] ?? 0) + 1;
//             }
//           } else {
//             // Standard counting (may count duplicates)
//             monthlyReportCounts[monthKey] =
//                 (monthlyReportCounts[monthKey] ?? 0) + 1;
//           }
//         }
//       }
//     }

//     // Ensure monthKeys doesn't exceed 12 months
//     if (monthKeys.length > 12) {
//       monthKeys = monthKeys.sublist(monthKeys.length - 12);
//     }

//     // Get the values in standard month order (Jan to Dec)
//     final List<double> values = [];
//     for (int i = 0; i < monthKeys.length; i++) {
//       values.add(monthlyReportCounts[monthKeys[i]]?.toDouble() ?? 0);
//     }

//     // Ensure we have exactly 12 or fewer values
//     if (values.length > 12) {
//       values.removeRange(12, values.length);
//     }

//     return {
//       'monthKeys': monthKeys,
//       'values': values,
//       'monthAbbr': monthAbbr,
//     };
//   }

//   /// Calculate appropriate interval for y-axis
//   double calculateAppropriateInterval(int maxValue) {
//     if (maxValue <= 5) return 1;
//     if (maxValue <= 10) return 2;
//     if (maxValue <= 20) return 4;
//     if (maxValue <= 50) return 10;
//     if (maxValue <= 100) return 20;
//     return (maxValue / 5).ceilToDouble();
//   }

//   /// Generate insights from the data
//   String getInsightsFromData(List<double> values, List<String> months,
//       {String itemLabel = 'report'}) {
//     if (values.isEmpty) return 'No data available for analysis.';

//     // Find highest and lowest months
//     int highestMonth = 0;
//     int lowestMonth = 0;
//     double highestValue = values[0];
//     double lowestValue = values[0];

//     for (int i = 1; i < values.length; i++) {
//       if (values[i] > highestValue) {
//         highestValue = values[i];
//         highestMonth = i;
//       }
//       if (values[i] < lowestValue) {
//         lowestValue = values[i];
//         lowestMonth = i;
//       }
//     }

//     // Calculate trend (increasing, decreasing, stable)
//     String trend = 'stable';
//     if (values.length > 3) {
//       double recentAvg = (values[values.length - 1] +
//               values[values.length - 2] +
//               values[values.length - 3]) /
//           3;
//       double earlierAvg = (values[0] + values[1] + values[2]) / 3;

//       if (recentAvg > earlierAvg * 1.2) {
//         trend = 'increasing';
//       } else if (recentAvg < earlierAvg * 0.8) {
//         trend = 'decreasing';
//       }
//     }

//     // Generate insight text
//     return 'The highest number of ${itemLabel}s (${highestValue.toInt()}) was in ${months[highestMonth]}, '
//         'while the lowest (${lowestValue.toInt()}) was in ${months[lowestMonth]}. '
//         'Overall, ${itemLabel} submissions show a $trend trend over the last year.';
//   }
// }
