// ignore_for_file: unused_local_variable, avoid_web_libraries_in_flutter, unnecessary_import, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../widgets/skeleton_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/alcohol_detection_services.dart';
import '../reusable_widget.dart';

class AlcoholDetectionPage extends StatefulWidget {
  const AlcoholDetectionPage({super.key});

  @override
  State<AlcoholDetectionPage> createState() => _AlcoholDetectionPageState();
}

class _AlcoholDetectionPageState extends State<AlcoholDetectionPage> {
  String _selectedDateFilter = "Today";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Collapsible section state
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getFilteredDetectionsStream(),
          builder: (context, snapshot) {
            // Apply filtering once at the top level
            List<QueryDocumentSnapshot> filteredDetections = [];
            if (snapshot.hasData) {
              final dateRange = AlcoholDetectionService.getDateRangeForFilter(
                _selectedDateFilter,
                customStartDate: _customStartDate,
                customEndDate: _customEndDate,
              );
              filteredDetections =
                  AlcoholDetectionService.filterDetectionsByDateRange(
                      snapshot.data!.docs, dateRange);
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(snapshot),
                    _buildCustomDateRangeBanner(),
                    const SizedBox(height: 16),

                    // Collapsible arrow button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCollapsed = !_isCollapsed;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isCollapsed
                                    ? 'Show Statistics'
                                    : 'Hide Statistics',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: _isCollapsed ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Collapsible content
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          _buildStatisticsCards(snapshot, filteredDetections),
                          const SizedBox(height: 16),
                        ],
                      ),
                      crossFadeState: _isCollapsed
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),

                    _buildDetectionsContainer(snapshot, filteredDetections),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncSnapshot<QuerySnapshot> snapshot) {
    return Row(
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
                Icons.science_rounded,
                color: Colors.blue,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Alcohol Detection',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildGenerateReportButton(),
            const SizedBox(width: 16),
            _buildDateFilterButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomDateRangeBanner() {
    if (_selectedDateFilter != 'Custom' ||
        _customStartDate == null ||
        _customEndDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            'Date range: ${_formatDate(_customStartDate)} - ${_formatDate(_customEndDate)}',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(AsyncSnapshot<QuerySnapshot> snapshot,
      List<QueryDocumentSnapshot> filteredDetections) {
    return Row(
      children: [
        _buildStatCard(
          'Total Detections',
          snapshot: snapshot,
          filteredDetections: filteredDetections,
          icon: Icons.science_rounded,
          color: const Color(0xFF4285F4),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Active Detections',
          snapshot: snapshot,
          filteredDetections: filteredDetections,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFFF9800),
          statusFilter: AlcoholDetectionService.statusActive,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Resolved Detections',
          snapshot: snapshot,
          filteredDetections: filteredDetections,
          icon: Icons.check_circle_outline,
          color: const Color(0xFF0F9D58),
          statusFilter: AlcoholDetectionService.statusResolved,
        ),
      ],
    );
  }

  Widget _buildDetectionsContainer(AsyncSnapshot<QuerySnapshot> snapshot,
      List<QueryDocumentSnapshot> filteredDetections) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.75, // Use 75% of screen height
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
              _buildDetectionsHeader(snapshot, filteredDetections),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                      8), // Reduced padding to give more space to table
                  child: _buildDetectionsTable(snapshot, filteredDetections),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetectionsHeader(AsyncSnapshot<QuerySnapshot> snapshot,
      List<QueryDocumentSnapshot> filteredDetections) {
    return Container(
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
              Icon(Icons.list_alt, size: 24, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Detection List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              '${filteredDetections.length} entries',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A1851).withOpacity(0.3), // kPrimaryColor
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter by date',
        onSelected: (String value) async {
          // Apply selection immediately for non-custom options
          if (value != 'Custom') {
            setState(() {
              _selectedDateFilter = value;
              _customStartDate = null;
              _customEndDate = null;
            });
            return;
          }

          // For Custom: open the shared compact date-range picker from reusable_widget.dart
          final result = await showCustomDateRangePicker(context);
          if (result != null &&
              result.containsKey('startDate') &&
              result.containsKey('endDate')) {
            setState(() {
              _selectedDateFilter = 'Custom';
              _customStartDate = result['startDate'];
              _customEndDate = result['endDate'];
            });
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A1851)
                          .withOpacity(0.1) // kPrimaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF1A1851) // kPrimaryColor
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option['value'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A1851) // kPrimaryColor
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list,
                size: 18,
                color: Color(0xFF1A1851), // kPrimaryColor
              ),
              const SizedBox(width: 4),
              Text(
                _selectedDateFilter,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A1851), // kPrimaryColor
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Color(0xFF1A1851), // kPrimaryColor
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title, {
    required AsyncSnapshot<QuerySnapshot> snapshot,
    required List<QueryDocumentSnapshot> filteredDetections,
    required IconData icon,
    required Color color,
    String? statusFilter,
  }) {
    return Expanded(
      child: Container(
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
            Builder(
              builder: (context) {
                if (snapshot.hasError) {
                  return const Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonStatCard();
                }

                // Calculate count from pre-filtered data
                int count = 0;
                if (statusFilter != null) {
                  // Filter by status from already filtered detections
                  count = filteredDetections.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ??
                        AlcoholDetectionService.statusActive;
                    return status == statusFilter;
                  }).length;
                } else {
                  // Total count from filtered detections
                  count = filteredDetections.length;
                }

                return Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
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

  Widget _buildDetectionsTable(AsyncSnapshot<QuerySnapshot> snapshot,
      List<QueryDocumentSnapshot> filteredDetections) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Show skeleton loaders for table rows
      return Column(
        children: List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SkeletonLoader(height: 40, borderRadius: 8),
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return _buildErrorDisplay(snapshot.error);
    }

    if (filteredDetections.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDataTable(filteredDetections);
  }

  Widget _buildErrorDisplay(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading detections: $error',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No detections found for the selected time period',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedDateFilter = 'All';
                _customStartDate = null;
                _customEndDate = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('View all detections'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> detections) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.grey.shade200,
          dataTableTheme: DataTableTheme.of(context).copyWith(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available width for flexible columns
            const fixedColumnsWidth = 120 +
                100 +
                100 +
                130 +
                70 +
                100 +
                120; // Sum of all fixed widths
            const totalSpacing = 24 * 6 +
                16 * 2; // columnSpacing * (columns-1) + horizontalMargin * 2
            final availableWidth = constraints.maxWidth;
            final shouldUseFlexible =
                availableWidth > fixedColumnsWidth + totalSpacing;

            return Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: shouldUseFlexible
                            ? availableWidth
                            : (fixedColumnsWidth + totalSpacing).toDouble(),
                      ),
                      child: DataTable(
                        columnSpacing: shouldUseFlexible
                            ? ((availableWidth - fixedColumnsWidth) / 6)
                                .toDouble()
                            : 24,
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey.shade50),
                        dataRowHeight: 60,
                        headingRowHeight: 50,
                        horizontalMargin: 16,
                        showCheckboxColumn: false,
                        dividerThickness: 1,
                        columns: [
                          DataColumn(
                            label: Container(
                              width: 120,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ID Number',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Department',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 130,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Detection Time',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 70,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'BAC',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 120,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: detections
                            .map((doc) => _buildDataRow(doc))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fallbackTimestampRaw = data['timestamp'];
    String syncedTimeLabel = 'No time applied';
    // Synced Time (timestamp)
    if (fallbackTimestampRaw != null) {
      DateTime? dt;
      if (fallbackTimestampRaw is String) {
        try {
          dt = DateTime.parse(fallbackTimestampRaw);
        } catch (_) {}
      } else if (fallbackTimestampRaw is Timestamp) {
        dt = fallbackTimestampRaw.toDate();
      }
      if (dt != null) {
        syncedTimeLabel = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      }
    }

    return DataRow(
      onSelectChanged: (selected) {
        if (selected ?? false) {
          _showDetectionDetails({...data, 'id': doc.id});
        }
      },
      cells: [
        _buildConstrainedDataCell(
            Icons.person, data['studentName'] ?? 'N/A', 120),
        _buildConstrainedDataCell(Icons.badge, data['studentId'] ?? 'N/A', 100),
        _buildConstrainedDataCell(
            Icons.school, data['studentCourse'] ?? 'N/A', 100),
        _buildConstrainedDataCell(Icons.sync, syncedTimeLabel, 130),
        _buildConstrainedDataCell(Icons.speed, '${data['bac'] ?? 'N/A'}', 70),
        DataCell(
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusChip(
                data['status'] ?? AlcoholDetectionService.statusActive,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusToggle(
                    doc.id,
                    data['status'] ?? AlcoholDetectionService.statusActive,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () =>
                        _showDetectionDetails({...data, 'id': doc.id}),
                    tooltip: 'View Details',
                    color: Colors.blue,
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataCell _buildConstrainedDataCell(IconData icon, String text, double width) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: text,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final StatusInfo statusInfo = _getStatusInfo(status);

    return Tooltip(
      message: 'Status: ${status.toUpperCase()}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusInfo.color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusInfo.icon,
              size: 12,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusInfo.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const StatusInfo(Colors.orange, Icons.warning_amber_rounded);
      case 'resolved':
        return const StatusInfo(Colors.green, Icons.check_circle);
      case 'inactive':
        return const StatusInfo(Colors.grey, Icons.do_not_disturb_on);
      default:
        return const StatusInfo(Colors.grey, Icons.help_outline);
    }
  }

  Widget _buildStatusToggle(String docId, String currentStatus) {
    // Only "resolved" status should show the toggle as ON
    // "active" and "inactive" should show toggle as OFF, so they can be marked as resolved
    final bool isResolved =
        currentStatus == AlcoholDetectionService.statusResolved;

    return Tooltip(
      message: isResolved ? 'Mark as Active' : 'Mark as Resolved',
      child: Switch(
        value: isResolved,
        activeColor: Colors.green,
        activeTrackColor: Colors.green.shade100,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.shade300,
        onChanged: (bool value) => _updateDetectionStatus(docId, value),
      ),
    );
  }

  Future<void> _updateDetectionStatus(String docId, bool markAsResolved) async {
    final success = await AlcoholDetectionService.updateDetectionStatus(
        docId, markAsResolved);

    if (mounted) {
      if (success) {
        final message = markAsResolved
            ? 'Detection marked as resolved successfully'
            : 'Detection marked as active successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(message),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text('Failed to update status'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDetectionDetails(Map<String, dynamic> detection) {
    final originalTimestampRaw = detection['originalTimestamp'];
    final fallbackTimestampRaw = detection['timestamp'];
    String detectionTimeLabel = 'No time applied';
    String syncedTimeLabel = 'No time applied';
    bool showNoTimeNote = false;
    // Detection Time (originalTimestamp)
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
        detectionTimeLabel = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } else {
        showNoTimeNote = true;
      }
    } else {
      showNoTimeNote = true;
    }
    // Synced Time (timestamp)
    if (fallbackTimestampRaw != null) {
      DateTime? dt;
      if (fallbackTimestampRaw is String) {
        try {
          dt = DateTime.parse(fallbackTimestampRaw);
        } catch (_) {}
      } else if (fallbackTimestampRaw is Timestamp) {
        dt = fallbackTimestampRaw.toDate();
      }
      if (dt != null) {
        syncedTimeLabel = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      }
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsHeader(),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentInfoSection(detection),
                        const SizedBox(height: 16),
                        _buildAddedByInfoSection(detection),
                        const SizedBox(height: 16),
                        _buildDetectionInfoSectionWithTime(
                            detection, detectionTimeLabel, syncedTimeLabel),
                        if (showNoTimeNote)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "If the data doesn't have detection time, the detection time was directly synced to the database.",
                                    style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (detection['notes'] != null)
                          _buildNotesSection(detection['notes']),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700]),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.science_rounded,
                  color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            const Text('Detection Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStudentInfoSection(Map<String, dynamic> detection) {
    return _buildInfoCard(
      'User Information',
      [
        _buildDetailTile(
          icon: Icons.person,
          label: 'Name',
          value: detection['studentName'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.badge,
          label: 'ID Number',
          value: detection['studentId'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.school,
          label: 'Department',
          value: detection['studentCourse'] ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildAddedByInfoSection(Map<String, dynamic> detection) {
    return _buildInfoCard(
      'Added By Information',
      [
        _buildDetailTile(
          icon: Icons.person_add,
          label: 'Added By Name',
          value: detection['addedByName'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.email,
          label: 'Added By Email',
          value: detection['addedByEmail'] ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildDetectionInfoSectionWithTime(
      Map<String, dynamic> detection, String detectionTimeLabel,
      [String? syncedTimeLabel]) {
    // Compute synced time label if not provided
    String syncedLabel = syncedTimeLabel ?? 'No time applied';
    final fallbackTimestampRaw = detection['timestamp'];
    if (syncedTimeLabel == null && fallbackTimestampRaw != null) {
      DateTime? dt;
      if (fallbackTimestampRaw is String) {
        try {
          dt = DateTime.parse(fallbackTimestampRaw);
        } catch (_) {}
      } else if (fallbackTimestampRaw is Timestamp) {
        dt = fallbackTimestampRaw.toDate();
      }
      if (dt != null) {
        syncedLabel = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      }
    }
    return _buildInfoCard(
      'Detection Information',
      [
        _buildDetailTile(
          icon: Icons.location_on,
          label: 'Location',
          value: detection['location'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.access_time,
          label: 'Detection Time',
          value: detectionTimeLabel,
        ),
        _buildDetailTile(
          icon: Icons.sync,
          label: 'Synced time to database',
          value: syncedLabel,
        ),
        _buildDetailTile(
          icon: Icons.speed,
          label: 'BAC Level',
          value: '${detection['bac'] ?? 'N/A'}',
        ),
        _buildDetailTile(
          icon: Icons.memory,
          label: 'Raw Sensor',
          value: '${detection['raw_sensor'] ?? 'N/A'}',
        ),
        _buildDetailTile(
          icon: Icons.smartphone,
          label: 'Device ID',
          value: detection['deviceId'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.numbers,
          label: 'Detection ID',
          value: '${detection['detectionId'] ?? 'N/A'}',
        ),
        _buildDetailTile(
          icon: Icons.flag,
          label: 'Status',
          customWidget: _buildStatusChip(detection['status'] ?? 'Unknown'),
        ),
      ],
    );
  }

  Widget _buildNotesSection(String notes) {
    return _buildInfoCard(
      'Notes',
      [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(notes, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    String? value,
    Widget? customWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                customWidget ??
                    Text(
                      value ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Generate PDF report button
  Widget _buildGenerateReportButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Generate Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        // Fetch filtered detections for the current filter
        final querySnapshot = await _getFilteredDetectionsStream().first;
        final docs = querySnapshot.docs;
        if (docs.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Colors.orange, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Text('No Data Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        )),
                    const SizedBox(height: 12),
                    const Text(
                      'There are no detections for the selected time period. Please adjust your filter or try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return;
        }
        // If there is data, show confirmation dialog
        final confirmed = await _showReportConfirmationDialog(docs.length);
        if (confirmed == true) {
          _generatePdfReport();
        }
      },
    );
  }

  // Generate and download PDF report
  Future<void> _generatePdfReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 300, // Constrain dialog width
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  'Generating PDF Report...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your report',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );

      // Get detection data
      final dateRange = AlcoholDetectionService.getDateRangeForFilter(
        _selectedDateFilter,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      );
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .orderBy('timestamp', descending: true)
          .get();

      // Filter by date range if needed
      final detections = AlcoholDetectionService.filterDetectionsByDateRange(
          snapshot.docs, dateRange);

      // Generate PDF using service
      final success = await AlcoholDetectionService.generatePdfReport(
        detections: detections,
        dateRange: dateRange,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text('Report generated successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to generate PDF report');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text('Error generating report: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Helper method to format date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Modern confirmation dialog that matches app aesthetic
  Future<bool?> _showReportConfirmationDialog(int detectionCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.blue, size: 38),
              ),
              const SizedBox(height: 16),
              Text('Generate Report?',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800)),
              const SizedBox(height: 12),
              Text(
                'This will generate a PDF report for $detectionCount detection${detectionCount == 1 ? '' : 's'} in the selected period.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        side: BorderSide(color: Colors.blue.shade100),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Generate'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simplified, optimized query method using service
  Stream<QuerySnapshot> _getFilteredDetectionsStream({
    String? status,
    bool countOnly = false,
  }) {
    final dateRange = AlcoholDetectionService.getDateRangeForFilter(
      _selectedDateFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );

    return AlcoholDetectionService.getFilteredDetectionsStream(
      status: status,
      countOnly: countOnly,
      dateRange: dateRange,
    );
  }
}

// Helper class for status display
class StatusInfo {
  final Color color;
  final IconData icon;

  const StatusInfo(this.color, this.icon);
}
