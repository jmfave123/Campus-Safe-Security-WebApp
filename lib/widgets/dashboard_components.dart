// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/campus_status_service.dart';
// import '../services/data_analytics_service.dart';
// import '../services/chart_builder_service.dart';
// import '../repositories/data_repository.dart';
// import '../models/campus_status_model.dart';

// /// A collection of reusable dashboard components
// ///
// /// This file follows the Composite Pattern by creating small,
// /// focused widget components that can be composed together.
// class DashboardComponents {
//   // Services (can be injected)
//   final CampusStatusService _campusStatusService;
//   final DataAnalyticsService _dataAnalyticsService;
//   final ChartBuilderService _chartBuilderService;

//   // Constructor with dependency injection
//   DashboardComponents({
//     CampusStatusService? campusStatusService,
//     DataAnalyticsService? dataAnalyticsService,
//     ChartBuilderService? chartBuilderService,
//   })  : _campusStatusService = campusStatusService ?? CampusStatusService(),
//         _dataAnalyticsService = dataAnalyticsService ?? DataAnalyticsService(),
//         _chartBuilderService = chartBuilderService ?? ChartBuilderService();

//   /// Builds the campus status card with real-time status updates
//   Widget buildCampusStatusSection(User? user) {
//     return StreamBuilder<CampusStatus>(
//       stream: _campusStatusService.getStatusStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildCampusStatusCard(
//             status: 'Loading...',
//             statusLevel: CampusStatusLevel.safe,
//             reason: 'Fetching current status',
//             lastUpdated: 'Just now',
//             onStatusChange: (newStatus, reason) {},
//             isAdmin: false,
//             context: context,
//           );
//         }

//         if (snapshot.hasError || !snapshot.hasData) {
//           return _buildCampusStatusCard(
//             status: 'Safe',
//             statusLevel: CampusStatusLevel.safe,
//             reason: 'Default status',
//             lastUpdated: 'Now',
//             onStatusChange: (newStatus, reason) {
//               _campusStatusService.updateStatus(newStatus, reason);
//             },
//             isAdmin: user != null,
//             context: context,
//           );
//         }

//         // Extract data from snapshot
//         final status = snapshot.data!;
//         final formattedTime = _getFormattedTimeAgo(status.timestamp);

//         return _buildCampusStatusCard(
//           status: status.level.name.toUpperCase(),
//           statusLevel: status.level,
//           reason: status.reason,
//           lastUpdated: 'Updated: $formattedTime',
//           onStatusChange: (newStatus, reason) {
//             _campusStatusService.updateStatus(newStatus, reason);
//           },
//           isAdmin: user != null,
//           context: context,
//         );
//       },
//     );
//   }

//   /// Builds the statistics section showing counts of reports, alerts, and detections
//   Widget buildStatisticsSection(User? user) {
//     return Row(
//       children: [
//         // Active Reports Card
//         user != null
//             ? _buildActiveReportsCard()
//             : _chartBuilderService.buildStatCard(
//                 'Active Incidents',
//                 'Loading...',
//                 Icons.warning_rounded,
//                 const Color(0xFFFF9800),
//               ),
//         const SizedBox(width: 16),
//         // Alerts Card
//         _buildAlertsCard(),
//         const SizedBox(width: 16),
//         // Alcohol Detections Card
//         _buildAlcoholDetectionsCard(),
//       ],
//     );
//   }

//   /// Builds the active reports card with real-time data
//   Widget _buildActiveReportsCard() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _dataAnalyticsService.getCollectionStream(
//           DatabasePaths.reportsCollection, DatabasePaths.timestampField),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _chartBuilderService.buildStatCard(
//             'Active Incidents',
//             'Error',
//             Icons.warning_rounded,
//             const Color(0xFFEA4335),
//           );
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _chartBuilderService.buildStatCard(
//             'Active Incidents',
//             'Loading...',
//             Icons.assessment_rounded,
//             const Color(0xFFFF9800),
//           );
//         }

//         // Count unique reports
//         final docs = snapshot.data?.docs ?? [];
//         final count = _dataAnalyticsService.countUniqueReports(docs);

//         return _chartBuilderService.buildStatCard(
//           'Active Reports',
//           count.toString(),
//           Icons.report_rounded,
//           const Color(0xFFFF9800),
//         );
//       },
//     );
//   }

//   /// Builds the alerts card with real-time data
//   Widget _buildAlertsCard() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _dataAnalyticsService.getCollectionStream(
//           DatabasePaths.alertsCollection, DatabasePaths.timestampField),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _chartBuilderService.buildStatCard(
//             'Alerts',
//             'Loading...',
//             Icons.warning_rounded,
//             const Color.fromARGB(255, 227, 26, 32),
//           );
//         }

//         if (snapshot.hasError) {
//           return _chartBuilderService.buildStatCard(
//             'Alerts',
//             'Error',
//             Icons.assessment_rounded,
//             const Color(0xFF0F9D58),
//           );
//         }

//         final count = snapshot.data?.docs.length ?? 0;
//         return _chartBuilderService.buildStatCard(
//           'Alerts',
//           count.toString(),
//           Icons.warning_rounded,
//           const Color.fromARGB(255, 227, 26, 32),
//         );
//       },
//     );
//   }

//   /// Builds the alcohol detections card with real-time data
//   Widget _buildAlcoholDetectionsCard() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _dataAnalyticsService.getCollectionStream(
//           DatabasePaths.alcoholDetectionCollection,
//           DatabasePaths.timestampField),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _chartBuilderService.buildStatCard(
//             'Alcohol Detections',
//             'Loading...',
//             Icons.assessment_rounded,
//             const Color(0xFF0F9D58),
//           );
//         }

//         if (snapshot.hasError) {
//           return _chartBuilderService.buildStatCard(
//             'Alcohol Detections',
//             'Error',
//             Icons.assessment_rounded,
//             const Color(0xFF0F9D58),
//           );
//         }

//         final count = snapshot.data?.docs.length ?? 0;
//         return _chartBuilderService.buildStatCard(
//           'Alcohol Detections',
//           count.toString(),
//           Icons.assessment_rounded,
//           const Color(0xFF0F9D58),
//         );
//       },
//     );
//   }

//   /// Builds the reports analysis section with chart
//   Widget buildReportsAnalysisSection(BuildContext context,
//       {VoidCallback? onSeeAllPressed}) {
//     return Container(
//       height: 500,
//       decoration: _buildCardDecoration(),
//       child: _chartBuilderService.buildReportsAnalysisWidget(
//         context: context,
//         title: 'Reports Analysis',
//         icon: Icons.bar_chart,
//         buttonText: 'See All Reports',
//         routeName: '/reports',
//         collectionName: DatabasePaths.reportsCollection,
//         orderByField: DatabasePaths.timestampField,
//         buildChartFunction: (documents) =>
//             _chartBuilderService.buildMonthlyReportChart(
//           documents,
//           timestampField: DatabasePaths.timestampField,
//           chartTitle: 'Monthly Report Trends',
//           yAxisTitle: 'Number of Reports',
//           chartColor: Colors.blue,
//           insightTitle: 'Report Analytics Insights',
//           itemLabel: 'report',
//         ),
//         onButtonPressed: onSeeAllPressed,
//       ),
//     );
//   }

//   /// Builds the alcohol detection analysis section with chart
//   Widget buildAlcoholDetectionSection(BuildContext context,
//       {VoidCallback? onSeeAllPressed}) {
//     return Container(
//       height: 500,
//       decoration: _buildCardDecoration(),
//       child: _chartBuilderService.buildReportsAnalysisWidget(
//         context: context,
//         title: 'Alcohol Detection Analysis',
//         icon: Icons.local_bar,
//         buttonText: 'See All Detections',
//         routeName: '/reports',
//         collectionName: DatabasePaths.alcoholDetectionCollection,
//         orderByField: DatabasePaths.timestampField,
//         descending: true,
//         buildChartFunction: (documents) {
//           // Find the most appropriate timestamp field
//           final timestampField =
//               _dataAnalyticsService.determineTimestampField(documents);

//           return _chartBuilderService.buildMonthlyReportChart(
//             documents,
//             timestampField: timestampField,
//             chartTitle: 'Monthly Alcohol Detection Trends',
//             yAxisTitle: 'Number of Detections',
//             chartColor: Colors.green,
//             insightTitle: 'Alcohol Detection Insights',
//             itemLabel: 'detection',
//             includeAllMonths: true,
//           );
//         },
//         onButtonPressed: onSeeAllPressed,
//       ),
//     );
//   }

//   /// Builds the alerts analysis section with chart
//   Widget buildAlertsAnalysisSection(BuildContext context,
//       {VoidCallback? onSeeAllPressed}) {
//     return Container(
//       height: 500,
//       decoration: _buildCardDecoration(),
//       child: _chartBuilderService.buildReportsAnalysisWidget(
//         context: context,
//         title: 'Alerts Analysis',
//         icon: Icons.warning_outlined,
//         buttonText: 'See All Alerts',
//         routeName: '/reports',
//         collectionName: DatabasePaths.alertsCollection,
//         orderByField: DatabasePaths.timestampField,
//         descending: true,
//         buildChartFunction: (documents) {
//           return _chartBuilderService.buildMonthlyReportChart(
//             documents,
//             timestampField: DatabasePaths.timestampField,
//             chartTitle: 'Monthly Alert Trends',
//             yAxisTitle: 'Number of Alerts',
//             chartColor: Colors.red,
//             insightTitle: 'Alert Pattern Insights',
//             itemLabel: 'alert',
//             includeAllMonths: true,
//             countUniqueIds: true,
//           );
//         },
//         onButtonPressed: onSeeAllPressed,
//       ),
//     );
//   }

//   /// Builds a campus status card with current status and update controls
//   Widget _buildCampusStatusCard({
//     required String status,
//     required CampusStatusLevel statusLevel,
//     required String reason,
//     required String lastUpdated,
//     required Function(String, String) onStatusChange,
//     required bool isAdmin,
//     required BuildContext context,
//   }) {
//     final color = statusLevel.color;
//     final icon = statusLevel.icon;

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//         border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Status header
//           _buildStatusHeader(status, color, icon, lastUpdated),

//           // Status details and admin controls
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   reason,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[800],
//                   ),
//                 ),

//                 // Show dropdown for admin users
//                 if (isAdmin) ...[
//                   const SizedBox(height: 16),
//                   const Divider(),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Update Campus Status:',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildStatusDropdown(
//                           currentStatus: status,
//                           onStatusChange: onStatusChange,
//                           context: context,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds the status header part of the campus status card
//   Widget _buildStatusHeader(
//       String status, Color color, IconData icon, String lastUpdated) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(15),
//           topRight: Radius.circular(15),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(width: 12),
//           Text(
//             'Campus Status: $status',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             lastUpdated,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Builds the status dropdown control for admins to update campus status
//   Widget _buildStatusDropdown({
//     required String currentStatus,
//     required Function(String, String) onStatusChange,
//     required BuildContext context,
//   }) {
//     final TextEditingController reasonController = TextEditingController();
//     String selectedStatus = currentStatus.toLowerCase();

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status dropdown
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//                 color: Colors.grey.shade50,
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String>(
//                   isExpanded: true,
//                   value: selectedStatus,
//                   items: _buildStatusDropdownItems(),
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         selectedStatus = value;
//                       });
//                     }
//                   },
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),

//             // Reason text field
//             TextField(
//               controller: reasonController,
//               decoration: InputDecoration(
//                 hintText: 'Reason for status change',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               ),
//               maxLines: 2,
//             ),

//             const SizedBox(height: 12),

//             // Update button
//             ElevatedButton(
//               onPressed: () => _handleStatusUpdate(
//                   selectedStatus, reasonController, onStatusChange, context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _getColorForStatus(selectedStatus),
//                 foregroundColor: Colors.white,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text('Update Status'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// Handles the status update when the admin clicks the update button
//   void _handleStatusUpdate(
//       String selectedStatus,
//       TextEditingController reasonController,
//       Function(String, String) onStatusChange,
//       BuildContext context) {
//     final reason = reasonController.text.trim();
//     if (reason.isNotEmpty) {
//       onStatusChange(selectedStatus, reason);
//       reasonController.clear();
//     } else {
//       // Show error
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Please provide a reason for the status change')),
//       );
//     }
//   }

//   /// Builds the dropdown items for the status dropdown
//   List<DropdownMenuItem<String>> _buildStatusDropdownItems() {
//     return [
//       _buildDropdownItem('safe', 'Safe', Colors.green, Icons.check_circle),
//       _buildDropdownItem('caution', 'Caution', Colors.orange, Icons.warning),
//       _buildDropdownItem('emergency', 'Emergency', Colors.red, Icons.emergency),
//     ];
//   }

//   /// Builds a single dropdown item with icon and label
//   DropdownMenuItem<String> _buildDropdownItem(
//     String value,
//     String label,
//     Color color,
//     IconData icon,
//   ) {
//     return DropdownMenuItem<String>(
//       value: value,
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 10),
//           Text(
//             label,
//             style: TextStyle(color: color),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Gets the color for a given status
//   Color _getColorForStatus(String status) {
//     switch (status.toLowerCase()) {
//       case 'caution':
//         return Colors.orange;
//       case 'emergency':
//         return Colors.red;
//       case 'safe':
//       default:
//         return Colors.green;
//     }
//   }

//   /// Builds card decoration for analysis sections
//   BoxDecoration _buildCardDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.grey.withOpacity(0.1),
//           spreadRadius: 0,
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     );
//   }

//   /// Helper function to format time ago
//   String _getFormattedTimeAgo(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inSeconds < 60) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
//     } else if (difference.inDays < 30) {
//       return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
//     } else {
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     }
//   }
// }
