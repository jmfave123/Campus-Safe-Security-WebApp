// ignore_for_file: unused_local_variable, avoid_web_libraries_in_flutter, unnecessary_import, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class AlcoholDetectionPage extends StatefulWidget {
  const AlcoholDetectionPage({super.key});

  @override
  State<AlcoholDetectionPage> createState() => _AlcoholDetectionPageState();
}

class _AlcoholDetectionPageState extends State<AlcoholDetectionPage> {
  String _selectedDateFilter = "Today";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Status constants for consistency
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusResolved = 'resolved';
  static const String statusCompleted = 'completed';
  static const String statusPending = 'pending';

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildCustomDateRangeBanner(),
                const SizedBox(height: 24),
                _buildStatisticsCards(),
                const SizedBox(height: 24),
                _buildDetectionsContainer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        _buildStatCard(
          'Total Detections',
          stream: _getFilteredDetectionsStream(countOnly: true),
          icon: Icons.science_rounded,
          color: const Color(0xFF4285F4),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Active Detections',
          // Use the specialized active cases stream
          stream: _getActiveCasesStream(),
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Resolved Detections',
          // Use the specialized resolved cases stream
          stream: _getResolvedCasesStream(),
          icon: Icons.check_circle_outline,
          color: const Color(0xFF0F9D58),
        ),
      ],
    );
  }

  Widget _buildDetectionsContainer() {
    return Container(
      height: 600,
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
          _buildDetectionsHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDetectionsTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionsHeader() {
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
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredDetectionsStream(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.size : 0;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(
                  '$count entries',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter by date',
        onSelected: (String value) {
          setState(() {
            _selectedDateFilter = value;
            if (value != 'Custom') {
              _customStartDate = null;
              _customEndDate = null;
            }
          });
          if (value == 'Custom') {
            _showDateRangePicker();
          }
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        itemBuilder: (BuildContext context) => [
          _buildPopupMenuItem('Today', Icons.today),
          _buildPopupMenuItem('Yesterday', Icons.history),
          _buildPopupMenuItem('Last Week', Icons.date_range),
          _buildPopupMenuItem('Last Month', Icons.calendar_month),
          _buildPopupMenuItem('All', Icons.all_inclusive),
          _buildPopupMenuItem('Custom', Icons.calendar_today),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Filter: $_selectedDateFilter',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon) {
    final isSelected = _selectedDateFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title, {
    required Stream<QuerySnapshot> stream,
    required IconData icon,
    required Color color,
  }) {
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
                    StreamBuilder<QuerySnapshot>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        }

                        final count = snapshot.data?.docs.length ?? 0;
                        return Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        );
                      },
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

  Widget _buildDetectionsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredDetectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorDisplay(snapshot.error);
        }

        // Apply client-side filtering
        final dateRange = _getDateRangeForFilter();
        final detections =
            _filterDetectionsByDateRange(snapshot.data?.docs ?? [], dateRange);

        if (detections.isEmpty) {
          return _buildEmptyState();
        }

        return _buildDataTable(detections);
      },
    );
  }

  // Extract client-side filtering to a separate method
  List<QueryDocumentSnapshot> _filterDetectionsByDateRange(
      List<QueryDocumentSnapshot> docs, DateRange dateRange) {
    if (dateRange.useAll) return docs;

    final startTimestamp = Timestamp.fromDate(dateRange.start);
    final endTimestamp = Timestamp.fromDate(dateRange.end);

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp == null) return false;

      // Check if timestamp is between start and end dates (inclusive)
      return timestamp.compareTo(startTimestamp) >= 0 &&
          timestamp.compareTo(endTimestamp) <= 0;
    }).toList();
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
    return SingleChildScrollView(
      child: Container(
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
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor:
                        WidgetStateProperty.all(Colors.grey.shade50),
                    dataRowHeight: 64,
                    headingRowHeight: 56,
                    horizontalMargin: 16,
                    showCheckboxColumn: false,
                    dividerThickness: 1,
                    columns: const [
                      DataColumn(
                          label: Text('Student Name',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Student ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Course',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Detection Time',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('BAC',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: detections.map((doc) => _buildDataRow(doc)).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Format timestamp
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : 'Unknown';

    return DataRow(
      onSelectChanged: (selected) {
        if (selected ?? false) {
          _showDetectionDetails({...data, 'id': doc.id});
        }
      },
      cells: [
        _buildDataCell(Icons.person, data['studentName'] ?? 'N/A'),
        _buildDataCell(Icons.badge, data['studentId'] ?? 'N/A'),
        _buildDataCell(Icons.school, data['studentCourse'] ?? 'N/A'),
        _buildDataCell(Icons.access_time, formattedDate),
        _buildDataCell(Icons.speed, '${data['bac'] ?? 'N/A'}'),
        DataCell(_buildStatusChip(data['status'] ?? statusActive)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusToggle(doc.id, data['status'] ?? statusActive),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _showDetectionDetails({...data, 'id': doc.id}),
                tooltip: 'View Details',
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataCell _buildDataCell(IconData icon, String text) {
    return DataCell(
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final StatusInfo statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 14, color: statusInfo.color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusInfo.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    final bool isActive =
        currentStatus == statusActive || currentStatus == statusResolved;

    return Tooltip(
      message: isActive ? 'Set Inactive' : 'Set Active',
      child: Switch(
        value: isActive,
        activeColor: Colors.green,
        activeTrackColor: Colors.green.shade100,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.shade300,
        onChanged: (bool value) => _updateDetectionStatus(docId, value),
      ),
    );
  }

  Future<void> _updateDetectionStatus(String docId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .doc(docId)
          .update({'status': isActive ? statusActive : 'inactive'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text('Status updated successfully'),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to update status: $e')),
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

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateFilter = 'Custom';
        _customStartDate = dateRange.start;
        _customEndDate = dateRange.end;
      });
    }
  }

  void _showDetectionDetails(Map<String, dynamic> detection) {
    final timestamp = detection['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : 'Unknown';

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
                        _buildDetectionInfoSection(detection, formattedDate),
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
      'Student Information',
      [
        _buildDetailTile(
          icon: Icons.person,
          label: 'Name',
          value: detection['studentName'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.badge,
          label: 'Student ID',
          value: detection['studentId'] ?? 'Unknown',
        ),
        _buildDetailTile(
          icon: Icons.school,
          label: 'Course',
          value: detection['studentCourse'] ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildDetectionInfoSection(
      Map<String, dynamic> detection, String formattedDate) {
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
          value: formattedDate,
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
                width: 360, // Constrain dialog width
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
      final dateRange = _getDateRangeForFilter();
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .orderBy('timestamp', descending: true)
          .get();

      // Filter by date range if needed
      final detections = _filterDetectionsByDateRange(snapshot.docs, dateRange);

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
                // Add logo image at the top left
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
            int otherCount = 0;

            for (var doc in detections) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? statusActive;

              if (status == statusActive) {
                activeCount++;
              } else if (status == statusResolved) {
                resolvedCount++;
              } else {
                otherCount++;
              }
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Add logo at the top left
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
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'alcohol_detection_report.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      // Close loading dialog
      Navigator.of(context).pop();

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

  // Helper method to format date range for report
  String _formatDateRangeForReport(DateRange range) {
    if (range.useAll) {
      return 'All Time';
    }
    return '${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}';
  }

  // Modern confirmation dialog that matches app aesthetic
  Future<bool?> _showReportConfirmationDialog(int detectionCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: Container(
          width: 400, // Constrain dialog width
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

  // Helper method to format date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Helper method to build PDF stat box
  pw.Widget _buildPdfStatBox(String title, String value) {
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

  // Helper method to build PDF detection table
  pw.Widget _buildPdfDetectionTable(List<QueryDocumentSnapshot> detections) {
    // Table headers
    final headers = [
      'Student Name',
      'Student ID',
      'Course',
      'Detection Time',
      'BAC',
      'Status'
    ];

    // Table data
    final data = detections.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      final formattedDate = timestamp != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
          : 'Unknown';

      return [
        data['studentName'] ?? 'N/A',
        data['studentId'] ?? 'N/A',
        data['studentCourse'] ?? 'N/A',
        formattedDate,
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
      },
    );
  }

  // Simplified, optimized query method
  Stream<QuerySnapshot> _getFilteredDetectionsStream({
    String? status,
    bool countOnly = false,
  }) {
    try {
      // Build query with consistent structure to avoid Firestore errors
      Query query = FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .orderBy('timestamp', descending: true);

      // Apply status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Get date constraints
      final dateRange = _getDateRangeForFilter();

      // Apply date range filters to the query (not client-side)
      if (!dateRange.useAll) {
        // Apply both start and end date filters to the query
        query = query
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
      }

      return query.limit(countOnly ? 100 : 50).snapshots();
    } catch (e) {
      print('Error in _getFilteredDetectionsStream: $e');
      // Return an empty stream on error
      return FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .limit(0)
          .snapshots();
    }
  }

  // Helper method to get active cases
  Stream<QuerySnapshot> _getActiveCasesStream() {
    try {
      return FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .where('status', whereIn: [statusActive, statusPending])
          .limit(100)
          .snapshots();
    } catch (e) {
      return FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .limit(0)
          .snapshots();
    }
  }

  // Helper method to get resolved cases
  Stream<QuerySnapshot> _getResolvedCasesStream() {
    try {
      return FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .where('status',
              whereIn: [statusResolved, statusCompleted, statusInactive])
          .limit(100)
          .snapshots();
    } catch (e) {
      return FirebaseFirestore.instance
          .collection('alcohol_detection_data')
          .limit(0)
          .snapshots();
    }
  }

  // Simplified date range helper
  DateRange _getDateRangeForFilter() {
    final now = DateTime.now();

    try {
      switch (_selectedDateFilter) {
        case 'Today':
          return DateRange(
            DateTime(now.year, now.month, now.day, 0, 0,
                0), // Start of today (midnight)
            DateTime(now.year, now.month, now.day, 23, 59, 59), // End of today
          );
        case 'Yesterday':
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          return DateRange(
            DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0,
                0), // Start of yesterday
            DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59,
                59), // End of yesterday
          );
        case 'Last Week':
          return DateRange(
            DateTime(now.year, now.month, now.day - 7, 0, 0, 0), // 7 days ago
            DateTime(now.year, now.month, now.day, 23, 59, 59), // End of today
          );
        case 'Last Month':
          // Handle edge cases for different month lengths
          DateTime oneMonthAgo;
          try {
            oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
          } catch (e) {
            oneMonthAgo = DateTime(now.year, now.month - 1, 1);
          }
          return DateRange(
            DateTime(
                oneMonthAgo.year, oneMonthAgo.month, oneMonthAgo.day, 0, 0, 0),
            DateTime(now.year, now.month, now.day, 23, 59, 59), // End of today
          );
        case 'Custom':
          if (_customStartDate != null && _customEndDate != null) {
            // Ensure full day coverage for custom dates
            return DateRange(
                DateTime(_customStartDate!.year, _customStartDate!.month,
                    _customStartDate!.day, 0, 0, 0),
                DateTime(_customEndDate!.year, _customEndDate!.month,
                    _customEndDate!.day, 23, 59, 59));
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
}

// Clean, well-documented DateRange class
class DateRange {
  final DateTime start;
  final DateTime end;
  final bool useAll;

  const DateRange._internal(this.start, this.end, this.useAll);

  /// Creates a date range with validation
  factory DateRange(DateTime start, DateTime end) {
    // Ensure start date is before end date
    if (start.isAfter(end)) {
      throw ArgumentError('Start date must be before end date');
    }
    return DateRange._internal(start, end, false);
  }

  /// Creates a date range for all dates (no filtering)
  factory DateRange.all() {
    return DateRange._internal(
      DateTime(2000), // Far past date
      DateTime.now().add(const Duration(days: 1)), // Include today
      true,
    );
  }
}

// Helper class for status display
class StatusInfo {
  final Color color;
  final IconData icon;

  const StatusInfo(this.color, this.icon);
}
