// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'data_analytics_service.dart';

// /// Service class responsible for building chart UI components
// ///
// /// This class follows the Single Responsibility Principle by handling
// /// only chart building logic, separating it from data processing.
// class ChartBuilderService {
//   final DataAnalyticsService _analyticsService;

//   // Dependency injection through constructor
//   ChartBuilderService({DataAnalyticsService? analyticsService})
//       : _analyticsService = analyticsService ?? DataAnalyticsService();

//   /// Builds a monthly report chart with the provided data
//   Widget buildMonthlyReportChart(
//     List<QueryDocumentSnapshot> documents, {
//     required String timestampField,
//     required String chartTitle,
//     required String yAxisTitle,
//     required Color chartColor,
//     required String insightTitle,
//     String? itemLabel = 'report',
//     bool includeAllMonths = false,
//     bool countUniqueIds = false,
//   }) {
//     // Process the data using the analytics service
//     final chartData = _analyticsService.processMonthlyReportData(
//       documents,
//       timestampField: timestampField,
//       countUniqueIds: countUniqueIds,
//       includeAllMonths: includeAllMonths,
//     );

//     final List<double> values = chartData['values'];
//     final List<String> monthKeys = chartData['monthKeys'];
//     final List<String> monthAbbr = chartData['monthAbbr'];

//     // Default item label if not provided
//     final label = itemLabel ?? 'report';
//     final now = DateTime.now();

//     // Get the maximum count for y-axis scaling
//     final maxCount =
//         values.fold(0.0, (prev, count) => count > prev ? count : prev);

//     // Calculate appropriate interval for grid lines based on maximum value
//     final interval =
//         _analyticsService.calculateAppropriateInterval(maxCount.toInt());

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Chart title with count summary
//         Row(
//           children: [
//             Icon(Icons.analytics_outlined, color: chartColor, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               '$chartTitle (${documents.length} total)',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Chart description
//         Text(
//           'Number of ${label}s submitted during ${now.year}',
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey.shade600,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Main chart area
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.only(
//               right: 16.0,
//               top: 16.0,
//               bottom: 24.0,
//               left: 8.0,
//             ),
//             child: _buildLineChart(
//               values: values,
//               monthAbbr: monthAbbr,
//               chartColor: chartColor,
//               interval: interval,
//               maxCount: maxCount,
//               yAxisTitle: yAxisTitle,
//               monthKeys: monthKeys,
//               label: label,
//             ),
//           ),
//         ),

//         // Chart information card
//         _buildInsightsCard(
//           values: values,
//           monthAbbr: monthAbbr,
//           chartColor: chartColor,
//           insightTitle: insightTitle,
//           label: label,
//         ),
//       ],
//     );
//   }

//   /// Builds the line chart component
//   Widget _buildLineChart({
//     required List<double> values,
//     required List<String> monthAbbr,
//     required List<String> monthKeys,
//     required Color chartColor,
//     required double interval,
//     required double maxCount,
//     required String yAxisTitle,
//     required String label,
//   }) {
//     final now = DateTime.now();

//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: true,
//           horizontalInterval: interval,
//           verticalInterval: 1,
//           getDrawingHorizontalLine: (value) {
//             return FlLine(
//               color: Colors.grey.shade200,
//               strokeWidth: 1,
//               dashArray: [5, 5],
//             );
//           },
//           getDrawingVerticalLine: (value) {
//             return FlLine(
//               color: Colors.grey.shade200,
//               strokeWidth: 1,
//               dashArray: [5, 5],
//             );
//           },
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           bottomTitles: AxisTitles(
//             axisNameWidget: Text(
//               'Months of ${now.year}',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 12,
//               ),
//             ),
//             axisNameSize: 20,
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 30,
//               interval: 1,
//               getTitlesWidget: (value, meta) {
//                 final index = value.toInt();
//                 if (index >= 0 && index < monthAbbr.length) {
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(
//                       monthAbbr[index],
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             axisNameWidget: Text(
//               yAxisTitle,
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 12,
//               ),
//             ),
//             axisNameSize: 20,
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 40,
//               interval: interval,
//               getTitlesWidget: (value, meta) {
//                 if (value == 0) {
//                   return const SizedBox.shrink();
//                 }
//                 // Only show integer values
//                 if (value == value.toInt().toDouble()) {
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: Text(
//                       value.toInt().toString(),
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border(
//             bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//             left: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//         ),
//         minX: 0,
//         maxX: 11,
//         minY: 0,
//         maxY: (maxCount + interval) < maxCount * 1.2
//             ? maxCount * 1.2
//             : (maxCount + interval).toDouble(),
//         lineTouchData: LineTouchData(
//           enabled: true,
//           touchTooltipData: LineTouchTooltipData(
//             tooltipBgColor: Colors.blueGrey.shade800,
//             tooltipRoundedRadius: 8,
//             tooltipPadding: const EdgeInsets.all(8),
//             getTooltipItems: (List<LineBarSpot> touchedSpots) {
//               return touchedSpots.map((spot) {
//                 final index = spot.x.toInt();

//                 // Make sure index is in valid range
//                 if (index < 0 ||
//                     index >= monthKeys.length ||
//                     index >= values.length) {
//                   return null; // Skip this spot if index is out of range
//                 }

//                 final monthYear = monthKeys[index];
//                 final count = values[index].toInt();

//                 return LineTooltipItem(
//                   '$monthYear\n',
//                   const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                   children: [
//                     TextSpan(
//                       text: '$count $label${count == 1 ? '' : 's'}',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 13,
//                         fontWeight: FontWeight.normal,
//                       ),
//                     )
//                   ],
//                 );
//               }).toList();
//             },
//           ),
//           touchCallback:
//               (FlTouchEvent event, LineTouchResponse? touchResponse) {},
//         ),
//         lineBarsData: [
//           LineChartBarData(
//             spots: List.generate(
//                 values.length > 12
//                     ? 12
//                     : values.length, // Limit to 12 max points
//                 (index) => FlSpot(index.toDouble(), values[index])),
//             isCurved: true,
//             gradient: LinearGradient(
//               colors: [
//                 chartColor.withOpacity(0.7),
//                 chartColor,
//               ],
//             ),
//             barWidth: 3,
//             isStrokeCapRound: true,
//             dotData: FlDotData(
//               show: true,
//               getDotPainter: (spot, percent, barData, index) {
//                 return FlDotCirclePainter(
//                   radius: 5,
//                   color: chartColor,
//                   strokeWidth: 2,
//                   strokeColor: Colors.white,
//                 );
//               },
//             ),
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 colors: [
//                   chartColor.withOpacity(0.3),
//                   chartColor.withOpacity(0.0),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds the insights card below the chart
//   Widget _buildInsightsCard({
//     required List<double> values,
//     required List<String> monthAbbr,
//     required Color chartColor,
//     required String insightTitle,
//     required String label,
//   }) {
//     final insightsText = _analyticsService.getInsightsFromData(
//       values,
//       monthAbbr,
//       itemLabel: label,
//     );

//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: chartColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: chartColor.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline,
//                   size: 16, color: chartColor.withOpacity(0.8)),
//               const SizedBox(width: 8),
//               Text(
//                 insightTitle,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: chartColor.withOpacity(0.9),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             insightsText,
//             style: TextStyle(
//               fontSize: 12,
//               color: chartColor.withOpacity(0.8),
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds a widget for reports analysis with chart
//   Widget buildReportsAnalysisWidget({
//     required BuildContext context,
//     required String title,
//     required IconData icon,
//     required String buttonText,
//     required String routeName,
//     required String collectionName,
//     required String orderByField,
//     required Widget Function(List<QueryDocumentSnapshot>) buildChartFunction,
//     VoidCallback? onButtonPressed,
//     bool descending = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       icon,
//                       size: 22,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blueGrey,
//                     ),
//                   ),
//                 ],
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blue.withOpacity(0.1),
//                       spreadRadius: 1,
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: TextButton.icon(
//                   icon: const Icon(Icons.arrow_forward, size: 16),
//                   label: Text(buttonText),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.blue,
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       side: BorderSide(color: Colors.blue.shade100),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                   ),
//                   onPressed: onButtonPressed ??
//                       () {
//                         // Navigate to full reports page
//                         Navigator.of(context).pushNamed(routeName);
//                       },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _analyticsService.getCollectionStream(
//                   collectionName, orderByField,
//                   descending: descending),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return _buildErrorWidget();
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 }

//                 final documents = snapshot.data?.docs ?? [];

//                 if (documents.isEmpty) {
//                   return _buildEmptyDataWidget();
//                 }

//                 // Process data for chart using the provided function
//                 return buildChartFunction(documents);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds an error widget for chart errors
//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
//           const SizedBox(height: 16),
//           Text(
//             'Error loading data',
//             style: TextStyle(color: Colors.red.shade700),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds an empty data widget when no data is available
//   Widget _buildEmptyDataWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(
//             'No data available',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds a statistics card with icon and value
//   Widget buildStatCard(String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.15),
//               spreadRadius: 1,
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Icon(icon, size: 30, color: color),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       value,
//                       style: TextStyle(
//                         fontSize: 30,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
