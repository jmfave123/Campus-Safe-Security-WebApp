import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/campus_status_service.dart';
import '../reusable_widget.dart';
import 'home_page.dart'; // Import to access _HomePageState

/// A simple class to hold status properties (color and icon)
class StatusProperties {
  final Color color;
  final IconData icon;

  StatusProperties(this.color, this.icon);
}

/// A dashboard that displays campus security information and statistics
///
/// Follows clean code principles:
/// 1. Single Responsibility: Each widget/method has a single responsibility
/// 2. Separation of concerns: UI, data fetching, and state management are separated
/// 3. Clear naming conventions: Methods and variables are named descriptively
/// 4. DRY (Don't Repeat Yourself): Common UI elements are extracted into reusable methods
class AdminDashboard extends StatelessWidget {
  final CampusStatusService _campusStatusService = CampusStatusService();

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            const SizedBox(height: 24),
            _buildCampusStatusSection(user),
            const SizedBox(height: 24),
            _buildStatisticsSection(user),
            const SizedBox(height: 24),
            _buildReportsAnalysisSection(context),
            const SizedBox(height: 24),
            _buildAlcoholDetectionSection(context),
            const SizedBox(height: 24),
            _buildAlertsAnalysisSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Builds the dashboard header with icon and title
  Widget _buildDashboardHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.dashboard,
            color: Colors.blue,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  /// Builds the campus status card with real-time status updates
  Widget _buildCampusStatusSection(User? user) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('campus_status').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCampusStatusCard(
            status: 'Loading...',
            color: Colors.grey,
            icon: Icons.hourglass_empty,
            reason: 'Fetching current status',
            lastUpdated: 'Just now',
            onStatusChange: (newStatus, reason) {},
            isAdmin: false,
            context: context,
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data?.snapshot.value == null) {
          return _buildCampusStatusCard(
            status: 'Safe',
            color: Colors.green,
            icon: Icons.check_circle,
            reason: 'Default status',
            lastUpdated: 'Now',
            onStatusChange: (newStatus, reason) {
              _updateCampusStatus(newStatus, reason);
            },
            isAdmin: user != null,
            context: context,
          );
        }

        // Extract data from snapshot
        final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map? ?? {});

        final currentStatus = data['current_status'] ?? 'safe';
        final reason = data['reason'] ?? 'No information provided';
        final lastUpdated = data['last_updated'] != null
            ? getFormattedTimeAgo(
                DateTime.fromMillisecondsSinceEpoch(data['last_updated']))
            : 'Unknown';

        // Get status properties
        final statusProperties =
            _getStatusProperties(currentStatus.toLowerCase());

        return _buildCampusStatusCard(
          status: currentStatus.toUpperCase(),
          color: statusProperties.color,
          icon: statusProperties.icon,
          reason: reason,
          lastUpdated: 'Updated: $lastUpdated',
          onStatusChange: (newStatus, reason) {
            _updateCampusStatus(newStatus, reason);
          },
          isAdmin: user != null,
          context: context,
        );
      },
    );
  }

  /// Builds the statistics cards section showing counts of reports, alerts, and detections
  Widget _buildStatisticsSection(User? user) {
    return Row(
      children: [
        // Active Reports Card
        user != null
            ? _buildActiveReportsCard()
            : _buildStatCard(
                'Active Incidents',
                'Loading...',
                Icons.warning_rounded,
                const Color(0xFFFF9800),
              ),
        const SizedBox(width: 16),
        // Alerts Card
        _buildAlertsCard(),
        const SizedBox(width: 16),
        // Alcohol Detections Card
        _buildAlcoholDetectionsCard(),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Builds the active reports card with real-time data
  Widget _buildActiveReportsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports_to_campus_security')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStatCard(
            'Active Incidents',
            'Error: ${snapshot.error.toString().substring(0, 20)}...',
            Icons.warning_rounded,
            const Color(0xFFEA4335),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Active Incidents',
            'Loading...',
            Icons.assessment_rounded,
            const Color(0xFFFF9800),
          );
        }

        // Count unique reports based on reportId
        final docs = snapshot.data?.docs ?? [];
        final Set<String> uniqueReportIds = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('reportId')) {
            uniqueReportIds.add(data['reportId'].toString());
          }
        }

        final count = uniqueReportIds.length;
        return _buildStatCard(
          'Active Reports',
          count.toString(),
          Icons.report_rounded,
          const Color(0xFFFF9800),
        );
      },
    );
  }

  /// Builds the alerts card with real-time data
  Widget _buildAlertsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts_data').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Alerts',
            'Loading...',
            Icons.warning_rounded,
            const Color.fromARGB(255, 227, 26, 32),
          );
        }

        if (snapshot.hasError) {
          return _buildStatCard(
            'Alerts',
            'Error',
            Icons.assessment_rounded,
            const Color(0xFF0F9D58),
          );
        }

        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatCard(
          'Alerts',
          count.toString(),
          Icons.warning_rounded,
          const Color.fromARGB(255, 227, 26, 32),
        );
      },
    );
  }

  /// Builds the alcohol detections card with real-time data
  Widget _buildAlcoholDetectionsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Alcohol Detections',
            'Loading...',
            Icons.assessment_rounded,
            const Color(0xFF0F9D58),
          );
        }

        if (snapshot.hasError) {
          return _buildStatCard(
            'Alcohol Detections',
            'Error',
            Icons.assessment_rounded,
            const Color(0xFF0F9D58),
          );
        }

        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatCard(
          'Alcohol Detections',
          count.toString(),
          Icons.assessment_rounded,
          const Color(0xFF0F9D58),
        );
      },
    );
  }

  Widget _buildUserCards() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
              'Users', 'Loading...', Icons.verified_user, Colors.blueAccent);
        }
        if (snapshot.hasError) {
          return _buildStatCard(
              'Users', 'Error', Icons.verified_user, Colors.blueAccent);
        }
        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatCard(
          'Users',
          count.toString(),
          Icons.verified_user,
          Colors.blueAccent,
        );
      },
    );
  }

  /// Builds the reports analysis section with chart
  Widget _buildReportsAnalysisSection(BuildContext context) {
    return Container(
      height: 500,
      decoration: boxDecoration2(
          Colors.white, 16, Colors.grey, 0.1, 0, 10, const Offset(0, 4)),
      child: buildReportsAnalysisWidget(
        context: context,
        title: 'Reports Analysis',
        icon: Icons.bar_chart,
        buttonText: 'See All Reports',
        routeName: '/reports',
        collectionName: 'reports_to_campus_security',
        orderByField: 'timestamp',
        buildChartFunction: (documents) => buildMonthlyReportChart(
          documents,
          timestampField: 'timestamp',
          chartTitle: 'Monthly Report Trends',
          yAxisTitle: 'Number of Reports',
          chartColor: Colors.blue,
          insightTitle: 'Report Analytics Insights',
          itemLabel: 'report',
        ),
        onButtonPressed: () => _navigateToTab(context, 5), // Reports tab
      ),
    );
  }

  /// Builds the alcohol detection analysis section with chart
  Widget _buildAlcoholDetectionSection(BuildContext context) {
    return Container(
      height: 500,
      decoration: boxDecoration2(
          Colors.white, 16, Colors.grey, 0.1, 0, 10, const Offset(0, 4)),
      child: buildReportsAnalysisWidget(
        context: context,
        title: 'Alcohol Detection Analysis',
        icon: Icons.local_bar,
        buttonText: 'See All Detections',
        routeName: '/reports',
        collectionName: 'alcohol_detection_data',
        orderByField: 'timestamp',
        descending: true,
        buildChartFunction: (documents) {
          // Find the most appropriate timestamp field
          final timestampField = _determineTimestampField(documents);

          return buildMonthlyReportChart(
            documents,
            timestampField: timestampField,
            chartTitle: 'Monthly Alcohol Detection Trends',
            yAxisTitle: 'Number of Detections',
            chartColor: Colors.green,
            insightTitle: 'Alcohol Detection Insights',
            itemLabel: 'detection',
            includeAllMonths: true,
          );
        },
        onButtonPressed: () =>
            _navigateToTab(context, 1), // Alcohol Detection tab
      ),
    );
  }

  /// Builds the alerts analysis section with chart
  Widget _buildAlertsAnalysisSection(BuildContext context) {
    return Container(
      height: 500,
      decoration: boxDecoration2(
          Colors.white, 16, Colors.grey, 0.1, 0, 10, const Offset(0, 4)),
      child: buildReportsAnalysisWidget(
        context: context,
        title: 'Alerts Analysis',
        icon: Icons.warning_outlined,
        buttonText: 'See All Alerts',
        routeName: '/reports',
        collectionName: 'alerts_data',
        orderByField: 'timestamp',
        descending: true,
        buildChartFunction: (documents) {
          return buildMonthlyReportChart(
            documents,
            timestampField: 'timestamp',
            chartTitle: 'Monthly Alert Trends',
            yAxisTitle: 'Number of Alerts',
            chartColor: Colors.red,
            insightTitle: 'Alert Pattern Insights',
            itemLabel: 'alert',
            includeAllMonths: true,
            countUniqueIds: true,
          );
        },
        onButtonPressed: () => _navigateToTab(context, 2), // Throw Alerts tab
      ),
    );
  }

  /// Helper method to navigate to a specific tab in the HomePage
  void _navigateToTab(BuildContext context, int tabIndex) {
    // Use dynamic type to avoid direct dependency on _HomePageState
    final homePageState = context.findAncestorStateOfType<State<HomePage>>();
    if (homePageState != null) {
      // Use reflection to access the _selectedIndex property
      try {
        // This is a safer approach than direct casting
        homePageState.setState(() {
          // Use reflection or dynamic to set the property
          (homePageState as dynamic)._selectedIndex = tabIndex;
        });
      } catch (e) {
        print('Error navigating to tab: $e');
      }
    }
  }

  /// Determines the most appropriate timestamp field from a collection of documents
  String _determineTimestampField(List<QueryDocumentSnapshot> documents) {
    final Set<String> timestampFields = {
      'timestamp',
      'dateDetected',
      'createdAt',
      'date',
      'detectedAt'
    };

    final Map<String, int> fieldCounts = {};
    for (String field in timestampFields) {
      fieldCounts[field] = 0;
    }

    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>;
      for (String field in timestampFields) {
        if (data.containsKey(field)) {
          fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
        }
      }
    }

    // Use the most common timestamp field or fallback to 'timestamp'
    String mostCommonField = 'timestamp';
    int maxCount = 0;
    fieldCounts.forEach((field, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonField = field;
      }
    });

    return mostCommonField;
  }

  /// Gets total reports count from both collections
  Future<int> _getTotalReportsCount() async {
    try {
      // Get reports count
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('reports_to_campus_security')
          .get();

      // Get alcohol detection data count
      final alcoholDataSnapshot = await FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .get();

      // Count unique reports based on reportId to avoid duplicates
      final Set<String> uniqueReportIds = {};

      // Add report IDs from reports_to_campus_security
      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('reportId')) {
          uniqueReportIds.add(data['reportId'].toString());
        } else {
          // If no reportId, use document ID
          uniqueReportIds.add(doc.id);
        }
      }

      // Add alcohol detection data count
      final alcoholCount = alcoholDataSnapshot.docs.length;

      // Return the combined total
      return uniqueReportIds.length + alcoholCount;
    } catch (e) {
      print('Error calculating total reports: $e');
      return 0;
    }
  }

  /// Builds a campus status card with current status and update controls
  Widget _buildCampusStatusCard({
    required String status,
    required Color color,
    required IconData icon,
    required String reason,
    required String lastUpdated,
    required Function(String, String) onStatusChange,
    required bool isAdmin,
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          _buildStatusHeader(status, color, icon, lastUpdated),

          // Status details and admin controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),

                // Show dropdown for admin users
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Update Campus Status:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusDropdown(
                          currentStatus: status,
                          onStatusChange: onStatusChange,
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the status header part of the campus status card
  Widget _buildStatusHeader(
      String status, Color color, IconData icon, String lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            'Campus Status: $status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            lastUpdated,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the status dropdown control for admins to update campus status
  Widget _buildStatusDropdown({
    required String currentStatus,
    required Function(String, String) onStatusChange,
    required BuildContext context,
  }) {
    final TextEditingController reasonController = TextEditingController();
    String selectedStatus = currentStatus.toLowerCase();

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedStatus,
                  items: _buildStatusDropdownItems(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reason text field
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for status change',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // Update button
            ElevatedButton(
              onPressed: () => _handleStatusUpdate(
                  selectedStatus, reasonController, onStatusChange, context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColorForStatus(selectedStatus),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update Status'),
            ),
          ],
        );
      },
    );
  }

  /// Handles the status update when the admin clicks the update button
  void _handleStatusUpdate(
      String selectedStatus,
      TextEditingController reasonController,
      Function(String, String) onStatusChange,
      BuildContext context) {
    final reason = reasonController.text.trim();
    if (reason.isNotEmpty) {
      onStatusChange(selectedStatus, reason);
      reasonController.clear();
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a reason for the status change')),
      );
    }
  }

  /// Builds the dropdown items for the status dropdown
  List<DropdownMenuItem<String>> _buildStatusDropdownItems() {
    return [
      _buildDropdownItem('safe', 'Safe', Colors.green, Icons.check_circle),
      _buildDropdownItem('caution', 'Caution', Colors.orange, Icons.warning),
      _buildDropdownItem('emergency', 'Emergency', Colors.red, Icons.emergency),
    ];
  }

  /// Builds a single dropdown item with icon and label
  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  /// Gets the appropriate color and icon for a given status
  StatusProperties _getStatusProperties(String status) {
    switch (status) {
      case 'caution':
        return StatusProperties(Colors.orange, Icons.warning);
      case 'emergency':
        return StatusProperties(Colors.red, Icons.emergency);
      case 'safe':
      default:
        return StatusProperties(Colors.green, Icons.check_circle);
    }
  }

  /// Gets the color for a given status
  Color _getColorForStatus(String status) {
    return _getStatusProperties(status).color;
  }

  /// Updates the campus status in Firebase Realtime Database
  Future<void> _updateCampusStatus(String status, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Cannot update status: User not authenticated');
        return;
      }

      final statusData = {
        'current_status': status,
        'reason': reason,
        'last_updated': ServerValue.timestamp,
        'updated_by': user.uid,
      };

      // Update current status
      await FirebaseDatabase.instance.ref('campus_status').update(statusData);

      // Add to history with unique key based on timestamp
      final historyRef =
          FirebaseDatabase.instance.ref('campus_status/history').push();

      await historyRef.set({
        'status': status,
        'reason': reason,
        'timestamp': ServerValue.timestamp,
        'updated_by': user.uid,
      });

      // Send notification to all users about the status change
      await _campusStatusService.sendStatusChangeNotification(status, reason);

      print('Campus status updated successfully to: $status');
    } catch (e) {
      print('Error updating campus status: $e');
    }
  }

  /// Builds a statistics card with icon and value
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
