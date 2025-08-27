import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/campus_status_service.dart';
import '../services/backup_service.dart';
import '../services/data_analytics_service.dart';
import '../utils/errors_utils.dart';
import '../widgets/skeleton_loader.dart';

import '../reusable_widget.dart';
import 'home_page.dart'; // Import to access _HomePageState

// USTP palette
const Color kPrimaryColor = Color(0xFF1A1851); // deep indigo
const Color kAccentColor = Color(0xFFFBB215); // warm yellow

// Previously used colors in this file (commented for reference):
// Colors.blue.withOpacity(0.15)
// Colors.blue
// Colors.blueGrey
// Colors.blueAccent

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
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final CampusStatusService _campusStatusService = CampusStatusService();
  final DataAnalyticsService _analyticsService = DataAnalyticsService();
  bool _isRefreshing = false;
  // Controller for the reason input — keep in state to avoid recreation on rebuilds
  final TextEditingController _statusReasonController = TextEditingController();
  // Selected status stored in state so selection persists across rebuilds
  String? _selectedStatus;
  // Flag to indicate update in progress to prevent duplicate submissions
  bool _isUpdatingStatus = false;

  // User distribution filter state
  String _selectedUserFilter = 'All';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Incident type filter state
  String _selectedIncidentFilter = 'All';
  DateTime? _incidentCustomStartDate;
  DateTime? _incidentCustomEndDate;

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Force refresh all streams by triggering a rebuild
      setState(() {});

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            const SizedBox(height: 24),
            _buildCampusStatusSection(user),
            const SizedBox(height: 24),
            _buildIncidentTypeSection(user),
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

  @override
  void dispose() {
    _statusReasonController.dispose();
    super.dispose();
  }

  /// Builds the dashboard header with icon, title, refresh, and backup buttons
  Widget _buildDashboardHeader() {
    return Builder(
      builder: (BuildContext context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.15),
                    // previous: Colors.blue.withOpacity(0.15)
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: kPrimaryColor, // previous: Colors.blue
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor, // previous: Colors.blueGrey
                  ),
                ),
              ],
            ),

            // Right side: Action Buttons
            Row(
              children: [
                // Refresh Button
                Tooltip(
                  message: 'Refresh Dashboard',
                  child: IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 24),
                    onPressed: _onRefresh,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Backup Button
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final format = await showFormatSelectionDialog(context);
                      if (format != null) {
                        final backupService = BackupService();
                        final result = await backupService.createBackup(format);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Backup successful: $result'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorUtils.showErrorSnackBar(context, e);
                      }
                    }
                  },
                  icon: const Icon(Icons.backup, size: 20),
                  label: const Text('Backup Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor, // previous: Colors.blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Builds the campus status card with real-time status updates
  Widget _buildCampusStatusSection(User? user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campus Status Card - 2/3 width
        Expanded(
          flex: 2,
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('campus_status').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCampusStatusCard();
              }

              if (snapshot.hasError) {
                if (context.mounted) {
                  ErrorUtils.showErrorSnackBar(context, snapshot.error);
                }
                return _buildCampusStatusCard(
                  status: 'Error',
                  color: Colors.red,
                  icon: Icons.error_outline,
                  reason: 'Failed to load status',
                  lastUpdated: 'Now',
                  onStatusChange: (newStatus, reason, ctx) {
                    _updateCampusStatus(newStatus, reason, ctx);
                  },
                  isAdmin: user != null,
                  context: context,
                );
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return _buildCampusStatusCard(
                  status: 'Safe',
                  color: Colors.green,
                  icon: Icons.check_circle,
                  reason: 'Default status',
                  lastUpdated: 'Now',
                  onStatusChange: (newStatus, reason, ctx) {
                    _updateCampusStatus(newStatus, reason, ctx);
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
                onStatusChange: (newStatus, reason, ctx) {
                  _updateCampusStatus(newStatus, reason, ctx);
                },
                isAdmin: user != null,
                context: context,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        // User Type Pie Chart - 1/3 width
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Error loading user data',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final documents = snapshot.data?.docs ?? [];

                // Apply date filtering if needed
                List<QueryDocumentSnapshot> filteredDocuments = documents;

                if (_selectedUserFilter != 'All') {
                  DateTime? startDate;
                  DateTime? endDate;

                  if (_selectedUserFilter == 'Custom') {
                    startDate = _customStartDate;
                    endDate = _customEndDate;
                  } else {
                    final dateRange = _analyticsService
                        .getDateRangeFromFilter(_selectedUserFilter);
                    startDate = dateRange['startDate'];
                    endDate = dateRange['endDate'];
                  }

                  filteredDocuments =
                      _analyticsService.filterDocumentsByDateRange(
                    documents,
                    startDate,
                    endDate,
                    timestampField: 'createdAt',
                  );
                }

                final userTypeCounts = <String, int>{};
                for (var doc in filteredDocuments) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userType = data['userType'] as String? ?? 'Unknown';
                  userTypeCounts[userType] =
                      (userTypeCounts[userType] ?? 0) + 1;
                }

                return buildFilterableUserTypePieChart(
                  userTypeCounts: userTypeCounts,
                  selectedFilter: _selectedUserFilter,
                  onFilterChanged: (String filter) {
                    setState(() {
                      _selectedUserFilter = filter;
                      if (filter != 'Custom') {
                        _customStartDate = null;
                        _customEndDate = null;
                      }
                    });
                  },
                  onCustomDatePressed: () async {
                    final result = await showCustomDateRangePicker(context);
                    if (result != null) {
                      setState(() {
                        _selectedUserFilter = 'Custom';
                        _customStartDate = result['startDate'];
                        _customEndDate = result['endDate'];
                      });
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the incident type chart section
  Widget _buildIncidentTypeSection(User? user) {
    return SizedBox(
      height: 400,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports_to_campus_security')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          // Apply date filtering
          List<QueryDocumentSnapshot> filteredDocuments = documents;
          if (_selectedIncidentFilter != 'All') {
            final dateRange = _analyticsService
                .getDateRangeFromFilter(_selectedIncidentFilter);

            DateTime? startDate = dateRange['startDate'];
            DateTime? endDate = dateRange['endDate'];

            // Use custom dates if Custom filter is selected
            if (_selectedIncidentFilter == 'Custom') {
              startDate = _incidentCustomStartDate;
              endDate = _incidentCustomEndDate;
            }

            filteredDocuments = _analyticsService.filterDocumentsByDateRange(
              documents,
              startDate,
              endDate,
              timestampField: 'timestamp',
            );
          }

          final incidentTypeCounts =
              _analyticsService.getIncidentTypeCounts(filteredDocuments);

          return buildFilterableIncidentTypePieChart(
            incidentTypeCounts: incidentTypeCounts,
            selectedFilter: _selectedIncidentFilter,
            onFilterChanged: (String filter) {
              setState(() {
                _selectedIncidentFilter = filter;
                // Reset custom dates when changing from custom filter
                if (filter != 'Custom') {
                  _incidentCustomStartDate = null;
                  _incidentCustomEndDate = null;
                }
              });
            },
            onCustomDatePressed: () async {
              final result = await showCustomDateRangePicker(context);
              if (result != null) {
                setState(() {
                  _selectedIncidentFilter = 'Custom';
                  _incidentCustomStartDate = result['startDate'];
                  _incidentCustomEndDate = result['endDate'];
                });
              }
            },
          );
        },
      ),
    );
  }

  /// Builds the statistics cards section showing counts of reports, alerts, and detections
  Widget _buildStatisticsSection(User? user) {
    if (user == null) {
      // Show skeleton loaders when user is not logged in yet
      return Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 3 ? 16 : 0),
              child: const SkeletonStatCard(),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Active Reports Card
        _buildActiveReportsCard(),
        const SizedBox(width: 16),
        // Alerts Card
        _buildAlertsCard(),
        const SizedBox(width: 16),
        // Alcohol Detections Card
        _buildAlcoholDetectionsCard(),
        const SizedBox(width: 16),
        // Users Card
        _buildUserCards(),
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
          if (context.mounted) {
            ErrorUtils.showErrorSnackBar(context, snapshot.error);
          }
          return _buildStatCard(
            'Active Incidents',
            'Error',
            Icons.error_outline,
            const Color(0xFFEA4335),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Active Incidents',
            'Loading...',
            Icons.hourglass_empty,
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
          'Reports',
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
        if (snapshot.hasError) {
          if (context.mounted) {
            ErrorUtils.showErrorSnackBar(context, snapshot.error);
          }
          return _buildStatCard(
            'Announcements',
            'Error',
            Icons.error_outline,
            const Color(0xFFEA4335),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Announcements',
            'Loading...',
            Icons.hourglass_empty,
            const Color.fromARGB(255, 227, 26, 32),
          );
        }

        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatCard(
          'Announcements',
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
        if (snapshot.hasError) {
          if (context.mounted) {
            ErrorUtils.showErrorSnackBar(context, snapshot.error);
          }
          return _buildStatCard(
            'Alcohol Detections',
            'Error',
            Icons.error_outline,
            const Color(0xFFEA4335),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Alcohol Detections',
            'Loading...',
            Icons.hourglass_empty,
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
        if (snapshot.hasError) {
          if (context.mounted) {
            ErrorUtils.showErrorSnackBar(context, snapshot.error);
          }
          return _buildStatCard(
            'Users',
            'Error',
            Icons.error_outline,
            const Color(0xFFEA4335),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            'Users',
            'Loading...',
            Icons.hourglass_empty,
            Colors.blueAccent,
          );
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

  // Pagination state for reports analysis
  List<firestore.QueryDocumentSnapshot> _reportDocs = [];
  bool _isLoadingReports = false;
  bool _hasMoreReports = true;
  DocumentSnapshot? _lastReportDoc;
  static const int _reportsPageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchInitialReports();
  }

  Future<void> _fetchInitialReports() async {
    setState(() {
      _isLoadingReports = true;
    });
    firestore.QuerySnapshot snapshot = await firestore
        .FirebaseFirestore.instance
        .collection('reports_to_campus_security')
        .orderBy('timestamp', descending: true)
        .limit(_reportsPageSize)
        .get();
    setState(() {
      _reportDocs = snapshot.docs;
      _isLoadingReports = false;
      _hasMoreReports = snapshot.docs.length == _reportsPageSize;
      _lastReportDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    });
  }

  Future<void> _fetchMoreReports() async {
    if (!_hasMoreReports || _isLoadingReports) return;
    setState(() {
      _isLoadingReports = true;
    });
    firestore.Query query = firestore.FirebaseFirestore.instance
        .collection('reports_to_campus_security')
        .orderBy('timestamp', descending: true)
        .limit(_reportsPageSize);
    if (_lastReportDoc != null) {
      query = query.startAfterDocument(_lastReportDoc!);
    }
    firestore.QuerySnapshot snapshot = await query.get();
    setState(() {
      _reportDocs.addAll(snapshot.docs);
      _isLoadingReports = false;
      _hasMoreReports = snapshot.docs.length == _reportsPageSize;
      if (snapshot.docs.isNotEmpty) {
        _lastReportDoc = snapshot.docs.last;
      }
    });
  }

  /// Builds the reports analysis section with chart and pagination
  Widget _buildReportsAnalysisSection(BuildContext context) {
    return Container(
      height: 500,
      decoration: boxDecoration2(
          Colors.white, 16, Colors.grey, 0.1, 0, 10, const Offset(0, 4)),
      child: Column(
        children: [
          Expanded(
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
          ),
          if (_isLoadingReports)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_hasMoreReports && !_isLoadingReports)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _fetchMoreReports,
                child: const Text('Load More Reports'),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the alcohol detection analysis section with chart
  Widget _buildAlcoholDetectionSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonChartSection();
        }

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
      },
    );
  }

  /// Builds the alerts analysis section with chart
  Widget _buildAlertsAnalysisSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts_data')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonChartSection();
        }

        return Container(
          height: 500,
          decoration: boxDecoration2(
              Colors.white, 16, Colors.grey, 0.1, 0, 10, const Offset(0, 4)),
          child: buildReportsAnalysisWidget(
            context: context,
            title: 'Announcement Analysis',
            icon: Icons.warning_outlined,
            buttonText: 'See All Announcements',
            routeName: '/reports',
            collectionName: 'alerts_data',
            orderByField: 'timestamp',
            descending: true,
            buildChartFunction: (documents) {
              return buildMonthlyReportChart(
                documents,
                timestampField: 'timestamp',
                chartTitle: 'Monthly Announcement Trends',
                yAxisTitle: 'Number of Announcements',
                chartColor: Colors.red,
                insightTitle: 'Announcement Pattern Insights',
                itemLabel: 'announcement',
                includeAllMonths: true,
                countUniqueIds: true,
              );
            },
            onButtonPressed: () =>
                _navigateToTab(context, 2), // Throw Alerts tab
          ),
        );
      },
    );
  }

  /// Helper method to navigate to a specific tab in the HomePage
  void _navigateToTab(BuildContext context, int tabIndex) {
    final homePageState = context.findAncestorStateOfType<State<HomePage>>();
    if (homePageState != null) {
      try {
        // Use dynamic to call the public method `navigateToTab`
        (homePageState as dynamic).navigateToTab(tabIndex);
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
    required Function(String, String, BuildContext) onStatusChange,
    required bool isAdmin,
    required BuildContext context,
  }) {
    return Container(
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
    required Function(String, String, BuildContext) onStatusChange,
    required BuildContext context,
  }) {
    // initialize selected status if not set
    _selectedStatus ??= currentStatus.toLowerCase();

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
              value: _selectedStatus,
              items: _buildStatusDropdownItems(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Reason text field (use controller from state)
        TextField(
          controller: _statusReasonController,
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
          onPressed: _isUpdatingStatus
              ? null
              : () => _handleStatusUpdate(
                  _selectedStatus ?? currentStatus.toLowerCase(),
                  _statusReasonController,
                  onStatusChange,
                  context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColorForStatus(
                _selectedStatus ?? currentStatus.toLowerCase()),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isUpdatingStatus
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update Status'),
        ),
      ],
    );
  }

  /// Handles the status update when the admin clicks the update button
  Future<void> _handleStatusUpdate(
      String selectedStatus,
      TextEditingController reasonController,
      Function(String, String, BuildContext) onStatusChange,
      BuildContext context) async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a reason for the status change')),
      );
      return;
    }
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      // Call the provided update function and await if it returns a Future
      final result = onStatusChange(selectedStatus, reason, context);
      if (result is Future) {
        await result;
      }

      // Clear the reason input and reset local selection so UI re-initializes
      setState(() {
        reasonController.clear();
        _statusReasonController.clear();
        _selectedStatus = null;
      });
    } catch (e) {
      if (context.mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
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
  Future<void> _updateCampusStatus(
      String status, String reason, BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
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

      // Show success message if the context is still mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campus status updated to: $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
      // Re-throw the error to be handled by the caller if needed
      rethrow;
    }
  }

  /// Builds a statistics card with icon and value using modern design
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: boxDecoration2(
          Colors.white,
          12,
          Colors.grey,
          0.1,
          0,
          8,
          const Offset(0, 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
