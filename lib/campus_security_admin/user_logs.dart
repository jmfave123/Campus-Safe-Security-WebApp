// ignore_for_file: unused_local_variable, deprecated_member_use, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../reusable_widget.dart';

class UserLogsPage extends StatefulWidget {
  const UserLogsPage({super.key});

  @override
  State<UserLogsPage> createState() => _UserLogsPageState();
}

class _UserLogsPageState extends State<UserLogsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedDateFilter = "Today"; // Default filter
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  DateTimeRange? _selectedDateRange; // Used for custom range display

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a LayoutBuilder for the full screen
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        // Use a full-height SingleChildScrollView to allow scrolling to the bottom
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Set minimum height to ensure content fills the entire screen
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title and Filter Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.manage_history_rounded,
                                  color: Colors.blue,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'User Activity Logs',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                          _buildDateFilterButton(), // Filter Button
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Display Selected Date Range Info
                      if (_selectedDateFilter != 'All')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                _getDateRangeLabel(), // Display the active filter range
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 15),
                              ),
                            ],
                          ),
                        ),

                      // Stats Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return constraints.maxWidth <
                                  700 // Adjusted breakpoint
                              ? Column(
                                  children: [
                                    _buildStatCard(
                                      'Total Activities',
                                      Icons.history,
                                      const Color(0xFF4285F4), // Blue
                                      'users_log',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatCard(
                                      'Login Events',
                                      Icons.login,
                                      const Color(0xFF0F9D58), // Green
                                      'users_log',
                                      field: 'action',
                                      value: 'login',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatCard(
                                      'Reports Filed',
                                      Icons.report,
                                      const Color(0xFFFF9800), // Orange
                                      'users_log',
                                      field: 'action',
                                      value: 'report_submitted',
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Activities',
                                        Icons.history,
                                        const Color(0xFF4285F4), // Blue
                                        'users_log',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Login Events',
                                        Icons.login,
                                        const Color(0xFF0F9D58), // Green
                                        'users_log',
                                        field: 'action',
                                        value: 'login',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Reports Filed',
                                        Icons.report,
                                        const Color(0xFFFF9800), // Orange
                                        'users_log',
                                        field: 'action',
                                        value: 'report_submitted',
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Logs Table Card - Takes remaining space and extends to bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list_alt,
                                      size: 24, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Activity Logs',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Table Area - Now has a minimum height to fill space
                        Container(
                          constraints: const BoxConstraints(
                            minHeight:
                                500, // Minimum height to ensure it's big enough
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildLogsTable(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTable() {
    return StreamBuilder<QuerySnapshot?>(
      stream: _getFilteredLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Skeleton loader for logs table
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                          width: 100, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 24),
                      Container(
                          width: 100, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 24),
                      Container(
                          width: 160, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 24),
                      Container(
                          width: 80, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 24),
                      Container(
                          width: 120, height: 20, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data available.'));
        }

        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return const Center(
            child: Text('No logs found for the selected period.'),
          );
        }

        // Simple, wide scrollable table
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  // Make sure table is at least as wide as the available space
                  width:
                      constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _enrichLogsWithUserData(logs),
                      builder: (context, enrichedSnapshot) {
                        if (enrichedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Skeleton loader for enriched logs
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: List.generate(
                                6,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 100,
                                          height: 20,
                                          color: Colors.grey.shade300),
                                      const SizedBox(width: 24),
                                      Container(
                                          width: 100,
                                          height: 20,
                                          color: Colors.grey.shade300),
                                      const SizedBox(width: 24),
                                      Container(
                                          width: 160,
                                          height: 20,
                                          color: Colors.grey.shade300),
                                      const SizedBox(width: 24),
                                      Container(
                                          width: 80,
                                          height: 20,
                                          color: Colors.grey.shade300),
                                      const SizedBox(width: 24),
                                      Container(
                                          width: 120,
                                          height: 20,
                                          color: Colors.grey.shade300),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final enrichedLogs = enrichedSnapshot.data ?? [];

                        return DataTable(
                          columnSpacing: 24,
                          headingRowColor:
                              WidgetStateProperty.all(Colors.grey.shade100),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          dataRowHeight: 60,
                          columns: const [
                            DataColumn(
                                label: Expanded(child: Text('User Type'))),
                            DataColumn(
                                label: Expanded(child: Text('ID Number'))),
                            DataColumn(label: Expanded(child: Text('Email'))),
                            DataColumn(label: Expanded(child: Text('Action'))),
                            DataColumn(
                                label: Expanded(child: Text('Date & Time'))),
                          ],
                          rows: enrichedLogs.map((logData) {
                            final timestamp =
                                logData['timestamp'] as Timestamp?;
                            final formattedDate = timestamp != null
                                ? DateFormat('MMM dd, yyyy HH:mm')
                                    .format(timestamp.toDate())
                                : 'Unknown';

                            return DataRow(
                              cells: [
                                DataCell(Row(children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(logData['userType'] ?? 'N/A',
                                          overflow: TextOverflow.ellipsis)),
                                ])),
                                DataCell(Text(logData['idNumber'] ?? 'N/A',
                                    overflow: TextOverflow.ellipsis)),
                                DataCell(Text(logData['email'] ?? 'N/A',
                                    overflow: TextOverflow.ellipsis)),
                                DataCell(_buildActionChip(
                                    logData['action'] ?? 'Unknown')),
                                DataCell(Text(formattedDate,
                                    overflow: TextOverflow.ellipsis)),
                              ],
                            );
                          }).toList(),
                        );
                      }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to fetch user data and enrich logs
  Future<List<Map<String, dynamic>>> _enrichLogsWithUserData(
      List<QueryDocumentSnapshot> logs) async {
    // Create a map to store unique ID numbers
    Map<String, String> userTypeCache = {};
    Set<String> idNumbersToFetch = {};
    List<Map<String, dynamic>> enrichedLogs = [];

    // First, collect all unique ID numbers that need to be fetched
    for (var log in logs) {
      final logData = log.data() as Map<String, dynamic>;
      final idNumber = logData['idNumber'] as String?;

      if (idNumber != null && idNumber.isNotEmpty) {
        idNumbersToFetch.add(idNumber);
      }
    }

    // Fetch user data for all unique ID numbers in batches
    if (idNumbersToFetch.isNotEmpty) {
      try {
        // Firestore doesn't support large IN queries, so we need to batch them
        // Process in batches of 10 (Firestore limitation for 'in' queries)
        List<String> idNumbersList = idNumbersToFetch.toList();

        for (int i = 0; i < idNumbersList.length; i += 10) {
          int end =
              (i + 10 < idNumbersList.length) ? i + 10 : idNumbersList.length;
          List<String> batchIds = idNumbersList.sublist(i, end);

          // Query users collection for this batch of IDs
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('idNumber', whereIn: batchIds)
              .get();

          // Add results to our cache
          for (var userDoc in usersSnapshot.docs) {
            final userData = userDoc.data();
            final userIdNumber = userData['idNumber'] as String?;
            if (userIdNumber != null) {
              userTypeCache[userIdNumber] = userData['userType'] ?? 'Unknown';
            }
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    // Now enrich all logs with the cached user data
    for (var log in logs) {
      final logData = log.data() as Map<String, dynamic>;
      final idNumber = logData['idNumber'] as String?;

      if (idNumber != null && idNumber.isNotEmpty) {
        // Use the cached user type if available
        logData['userType'] = userTypeCache[idNumber] ?? 'User not found';
      } else {
        logData['userType'] = 'N/A';
      }

      enrichedLogs.add(logData);
    }

    return enrichedLogs;
  }

  // Date Filter PopupMenuButton (consistent UI with other screens)
  Widget _buildDateFilterButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A1851).withOpacity(0.3), // kPrimaryColor
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter logs by date',
        onSelected: (String result) async {
          if (result != 'Custom') {
            setState(() {
              _selectedDateFilter = result;
              _customStartDate = null;
              _customEndDate = null;
              _selectedDateRange = null;
            });
            return;
          }

          // Use the shared compact custom date-range picker from reusable_widget.dart
          final res = await showCustomDateRangePicker(context);
          if (res != null &&
              res.containsKey('start') &&
              res.containsKey('end')) {
            final DateTime? start = res['start'] as DateTime?;
            final DateTime? end = res['end'] as DateTime?;
            if (start != null && end != null) {
              setState(() {
                _selectedDateFilter = 'Custom';
                _customStartDate = start;
                // Preserve existing logic: store end as start of next day for exclusive queries
                _customEndDate = DateTime(end.year, end.month, end.day + 1);
                _selectedDateRange = DateTimeRange(start: start, end: end);
              });
            }
          }
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        itemBuilder: (BuildContext context) {
          final options = [
            {'value': 'Today', 'icon': Icons.today},
            {'value': 'Yesterday', 'icon': Icons.history},
            {'value': 'Last Week', 'icon': Icons.date_range},
            {'value': 'Last Month', 'icon': Icons.calendar_month},
            {'value': 'All', 'icon': Icons.all_inclusive},
            {'value': 'Custom', 'icon': Icons.calendar_today},
          ];

          return options.map((option) {
            final isSelected = _selectedDateFilter == option['value'];
            return PopupMenuItem<String>(
              value: option['value'] as String,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A1851).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF1A1851)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option['value'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A1851)
                            : Colors.grey.shade600,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: const Color(0xFF1A1851),
              ),
              const SizedBox(width: 4),
              Text(
                _getFilterButtonLabel(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A1851),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: const Color(0xFF1A1851),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get the label for the filter button itself
  String _getFilterButtonLabel() {
    if (_selectedDateFilter == 'Custom' && _selectedDateRange != null) {
      final start = DateFormat('MMM d').format(_selectedDateRange!.start);
      final end = DateFormat('MMM d').format(_selectedDateRange!.end);
      return 'Custom ($start - $end)';
    } else if (_selectedDateFilter == 'All') {
      return 'All Time';
    } else if (_selectedDateFilter == 'Last Week') {
      return 'Last Week';
    }
    return _selectedDateFilter;
  }

  // Helper to get the descriptive label shown below the header
  String _getDateRangeLabel() {
    DateTime now = DateTime.now();
    switch (_selectedDateFilter) {
      case 'Today':
        return 'Showing logs for: Today (${DateFormat('MMM dd, yyyy').format(now)})';
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return 'Showing logs for: Yesterday (${DateFormat('MMM dd, yyyy').format(yesterday)})';
      case 'Last Week':
        // Calculate Monday to Sunday of the *previous* week
        DateTime firstDayOfThisWeek =
            now.subtract(Duration(days: now.weekday - 1));
        DateTime lastDayOfLastWeek =
            firstDayOfThisWeek.subtract(const Duration(days: 1));
        DateTime firstDayOfLastWeek =
            lastDayOfLastWeek.subtract(const Duration(days: 6));
        return 'Showing logs for: Last Week (${DateFormat('MMM dd').format(firstDayOfLastWeek)} - ${DateFormat('MMM dd, yyyy').format(lastDayOfLastWeek)})';
      case 'Last Month':
        DateTime firstDayCurrentMonth = DateTime(now.year, now.month, 1);
        DateTime lastDayLastMonth =
            firstDayCurrentMonth.subtract(const Duration(days: 1));
        DateTime firstDayLastMonth =
            DateTime(lastDayLastMonth.year, lastDayLastMonth.month, 1);
        return 'Showing logs for: Last Month (${DateFormat('MMM yyyy').format(firstDayLastMonth)})';
      case 'Custom':
        if (_selectedDateRange != null) {
          final start =
              DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start);
          final end =
              DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end);
          return 'Showing logs for: $start - $end';
        }
        return 'Showing logs for: Custom Range';
      // No label needed for 'All' as it's implicit
      // case 'All':
      //    return 'Showing all logs';
      default:
        return 'Selected: $_selectedDateFilter'; // Fallback
    }
  }

  // Stream for the main logs table
  Stream<QuerySnapshot?> _getFilteredLogsStream() {
    Query query = FirebaseFirestore.instance
        .collection('users_log')
        .orderBy('timestamp', descending: true)
        .limit(200); // Apply ordering and limit first

    // Calculate date range based on filter
    final range = _calculateDateRange();

    // If range is null (e.g., 'All Time'), return the base query stream
    if (range == null) {
      return query.snapshots();
    }

    // Handle invalid custom range (should ideally be prevented by picker)
    if (range.start.isAfter(range.end)) {
      print("Error: Start date is after end date.");
      // Return a stream with an error or an empty stream
      return Stream.error("Invalid date range selected.");
    }

    // Apply date range filtering
    query = query
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('timestamp',
            isLessThan:
                Timestamp.fromDate(range.end)); // Use isLessThan for end date

    return query.snapshots();
  }

  // Stream for the stat cards, respecting date filter
  Stream<QuerySnapshot?> _getFilteredStreamForStatCard(
      String collection, String? field, String? value) {
    // Calculate the active date range first
    final range = _calculateDateRange();

    // Start with base query to the collection
    Query query = FirebaseFirestore.instance.collection(collection);

    // If no range (All Time), only apply the field filter if needed
    if (range == null) {
      if (field != null && value != null) {
        query = query.where(field, isEqualTo: value);
      }
      return query.snapshots();
    }

    // Handle invalid custom range
    if (range.start.isAfter(range.end)) {
      return Stream.value(
          null); // Return empty results for cards on invalid range
    }

    // For date-filtered queries, we need to handle them differently based on whether
    // we have a field filter or not, due to Firestore compound query limitations

    if (field != null && value != null) {
      // For field-filtered queries (e.g., action='login'), we need to fetch all documents
      // in the date range and then count only those matching our field filter
      return FirebaseFirestore.instance
          .collection(collection)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('timestamp', isLessThan: Timestamp.fromDate(range.end))
          .snapshots()
          .map((snapshot) {
        // Count the documents that match our field filter
        final count = snapshot.docs
            .where(
                (doc) => (doc.data() as Map<String, dynamic>)[field] == value)
            .length;

        // We're only using the count for stat cards, so we can just return the original
        // snapshot - the stat card will count the filtered docs client-side
        return snapshot;
      });
    } else {
      // If we only need date filtering (no field filter), we can use the standard query
      return query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('timestamp', isLessThan: Timestamp.fromDate(range.end))
          .snapshots();
    }
  }

  // Helper to calculate the effective DateTimeRange based on the selected filter
  DateTimeRange? _calculateDateRange() {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(
            now.year, now.month, now.day + 1); // Up to start of next day
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate =
            DateTime(now.year, now.month, now.day); // Up to start of today
        break;
      case 'Last Week':
        // Monday to Sunday of the *previous* week
        DateTime firstDayOfThisWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        endDate = firstDayOfThisWeek; // Up to start of this Monday
        startDate = endDate
            .subtract(const Duration(days: 7)); // Start of previous Monday
        break;
      case 'Last Month':
        DateTime firstDayCurrentMonth = DateTime(now.year, now.month, 1);
        endDate = firstDayCurrentMonth; // Up to start of this month
        startDate =
            DateTime(now.year, now.month - 1, 1); // Start of previous month
        break;
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate =
              _customEndDate!; // Use the stored end date (start of day after selection)
          // Basic validation
          if (startDate.isAfter(endDate)) return null; // Or handle error
        } else {
          return null; // No range if custom isn't fully selected
        }
        break;
      default: // 'All'
        return null; // No date range for 'All Time'
    }
    return DateTimeRange(start: startDate, end: endDate);
  }

  // Updated Stat Card Widget
  Widget _buildStatCard(
    String title,
    IconData icon,
    Color color,
    String collection, {
    String? field,
    String? value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot?>(
        stream: _getFilteredStreamForStatCard(collection, field, value),
        builder: (context, snapshot) {
          // Handle loading state
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          // Get count, default to 0 if no data/error
          int count = 0;
          if (snapshot.hasData && snapshot.data != null) {
            if (field != null && value != null) {
              // For field-filtered queries, count only docs that match our field filter
              count = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data[field] == value;
              }).length;
            } else {
              // For non-filtered queries, use the total doc count
              count = snapshot.data!.docs.length;
            }
          }

          return Column(
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
              if (isLoading)
                Container(
                  width: 60,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                )
              else
                Text(
                  count.toString(),
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
          );
        },
      ),
    );
  }

  // Updated Action Chip Widget
  Widget _buildActionChip(String action) {
    Color chipColor;
    IconData icon;

    switch (action.toLowerCase()) {
      case 'login':
        chipColor = const Color(0xFF0F9D58); // Green
        icon = Icons.login;
        break;
      case 'logout':
        chipColor = const Color(0xFF4285F4); // Blue
        icon = Icons.logout;
        break;
      case 'report_submitted':
      case 'report': // Handle both possible values
        chipColor = const Color(0xFFFF9800); // Orange
        icon = Icons.flag_outlined; // Different icon for report
        break;
      default:
        chipColor = Colors.grey.shade600;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep chip tight
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            action, // Keep original case
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
