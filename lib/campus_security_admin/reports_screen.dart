// ignore_for_file: use_build_context_synchronously, unused_local_variable, avoid_web_libraries_in_flutter, unnecessary_import, unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../services/notify_services.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedDateFilter = "Today";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and filter button
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
                          Icons.summarize_rounded,
                          color: Colors.blue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  // Action buttons
                  Row(
                    children: [
                      _buildGenerateReportButton(),
                      const SizedBox(width: 12),
                      // Date filter button
                      _buildDateFilterButton(),
                    ],
                  ),
                ],
              ),

              // Active filters display
              if (_selectedDateFilter == 'Custom' &&
                  _customStartDate != null &&
                  _customEndDate != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range,
                          size: 18, color: Colors.blue.shade700),
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
                ),

              const SizedBox(height: 24),

              // Wrap the Stats Cards and Reports Table in a StreamBuilder
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getFilteredReportsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading reports: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    final reports = snapshot.data?.docs ?? [];

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats Cards with data from the stream
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final totalReports = reports.length;
                                  final pendingReports = reports
                                      .where((doc) =>
                                          (doc.data() as Map<String, dynamic>)[
                                                  'status']
                                              ?.toLowerCase() ==
                                          'pending')
                                      .length;
                                  final resolvedReports = reports
                                      .where((doc) =>
                                          (doc.data() as Map<String, dynamic>)[
                                                  'status']
                                              ?.toLowerCase() ==
                                          'resolved')
                                      .length;

                                  return constraints.maxWidth < 600
                                      ? Column(
                                          children: [
                                            _buildStatCardDirect(
                                              'Total Reports',
                                              Icons.report,
                                              const Color(0xFF4285F4),
                                              totalReports.toString(),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildStatCardDirect(
                                              'Pending Reports',
                                              Icons.pending_actions,
                                              const Color(0xFFFF9800),
                                              pendingReports.toString(),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildStatCardDirect(
                                              'Resolved Reports',
                                              Icons.task_alt,
                                              const Color(0xFF0F9D58),
                                              resolvedReports.toString(),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            _buildStatCardDirect(
                                              'Total Reports',
                                              Icons.report,
                                              const Color(0xFF4285F4),
                                              totalReports.toString(),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildStatCardDirect(
                                              'Pending Reports',
                                              Icons.pending_actions,
                                              const Color(0xFFFF9800),
                                              pendingReports.toString(),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildStatCardDirect(
                                              'Resolved Reports',
                                              Icons.task_alt,
                                              const Color(0xFF0F9D58),
                                              resolvedReports.toString(),
                                            ),
                                          ],
                                        );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Reports Table
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 0,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        children: [
                                          Icon(Icons.list_alt,
                                              color: Colors.blue.shade700,
                                              size: 24),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Reports List',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: Colors.blue.shade100),
                                            ),
                                            child: Text(
                                              _selectedDateFilter,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SizedBox(
                                        height: 450,
                                        child:
                                            _buildReportsTableDirect(reports),
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
                  },
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildStatusFilterButton() {
    return Container();
  }

  Widget _buildStatCardDirect(
      String title, IconData icon, Color color, String count) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
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
                      count,
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

  Widget _buildReportsTableDirect(List<QueryDocumentSnapshot> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No reports found for the selected time period',
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
              label: const Text('View all reports'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index].data() as Map<String, dynamic>;
        final timestamp = report['timestamp'] as Timestamp?;
        final formattedDate = timestamp != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
            : 'Unknown';
        final status = report['status'] ?? 'pending';
        final userId = report['userId'];
        final remarks = report['resolveRemarks'];
        final falseInfoRemarks = report['falseInfoRemarks'];
        final hasRemarks = status.toLowerCase() == 'resolved' &&
            remarks != null &&
            remarks.isNotEmpty;
        final hasFalseInfoRemarks =
            status.toLowerCase() == 'false information' &&
                falseInfoRemarks != null &&
                falseInfoRemarks.isNotEmpty;

        return Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _showReportDetails(report),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    status.toLowerCase() == 'resolved'
                        ? Colors.green.shade50
                        : status.toLowerCase() == 'in progress'
                            ? Colors.blue.shade50
                            : status.toLowerCase() == 'false information'
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                  ],
                  stops: const [0.85, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User profile image
                        FutureBuilder<String?>(
                          future: _getUserProfileImage(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            }

                            final imageUrl = snapshot.data;

                            if (imageUrl != null && imageUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(imageUrl),
                                backgroundColor: Colors.grey.shade200,
                                onBackgroundImageError: (_, __) {},
                              );
                            }

                            return CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              radius: 20,
                              child: Text(
                                _getInitials(report['userName'] ?? 'NA'),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Report information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      report['userName'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Incident type: ',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getIncidentColor(
                                          report['incidentType']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    report['incidentType'] ?? 'N/A',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report['description'] ?? 'No description provided',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Add remarks if resolved with remarks
                    if (hasRemarks) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Resolution Remarks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              remarks,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.grey.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Add false information remarks if they exist
                    if (hasFalseInfoRemarks) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'False Information Notes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              falseInfoRemarks,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.grey.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Location and Actions
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    report['location'] ?? 'Unknown location',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            // View Button
                            OutlinedButton(
                              onPressed: () => _showReportDetails(report),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.shade200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Details'),
                            ),
                            const SizedBox(width: 8),
                            // Update Status Button
                            FilledButton.icon(
                              onPressed: () => _updateReportStatus(
                                  reports[index].id, report),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Status'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(
              start: _customStartDate!,
              end: _customEndDate!,
            )
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'resolved':
        chipColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'in progress':
        chipColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'false information':
        chipColor = Colors.red.shade700;
        statusIcon = Icons.report_problem;
        break;
      default:
        chipColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIncidentColor(String? incidentType) {
    if (incidentType == null) return Colors.grey;

    switch (incidentType.toLowerCase()) {
      case 'theft':
        return Colors.red;
      case 'vandalism':
        return Colors.orange;
      case 'assault':
        return Colors.purple;
      case 'suspicious activity':
        return Colors.amber;
      case 'harassment':
        return Colors.pink;
      case 'other':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Stream<QuerySnapshot> _getFilteredReportsStream() {
    Query query =
        FirebaseFirestore.instance.collection('reports_to_campus_security');

    // Apply date filters
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Week':
        startDate = DateTime(now.year, now.month, now.day - 7);
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
        }
        break;
      default: // 'All'
        break;
    }

    // Date filter
    if (startDate != null && endDate != null) {
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Add ordering
    return query.orderBy('timestamp', descending: true).limit(100).snapshots();
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final timestamp = report['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final resolveRemarks = report['resolveRemarks'];
    final falseInfoRemarks = report['falseInfoRemarks'];
    final isResolved = (report['status'] ?? '').toLowerCase() == 'resolved';
    final isFalseInfo =
        (report['status'] ?? '').toLowerCase() == 'false information';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
              stops: const [0.7, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Report Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: Colors.blue.shade100, height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool useHorizontalLayout =
                            constraints.maxWidth > 600;

                        if (useHorizontalLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(top: 8, right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Report Information',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildInfoTile(
                                            icon: Icons.person,
                                            label: 'Reporter',
                                            value: report['userName'] ?? 'N/A',
                                          ),
                                          _buildInfoTile(
                                            icon: Icons.category,
                                            label: 'Type',
                                            value:
                                                report['incidentType'] ?? 'N/A',
                                          ),
                                          _buildInfoTile(
                                            icon: Icons.location_on,
                                            label: 'Location',
                                            value: report['location'] ?? 'N/A',
                                          ),
                                          _buildInfoTile(
                                            icon: Icons.access_time,
                                            label: 'Date Reported',
                                            value: formattedDate,
                                          ),
                                          _buildInfoTile(
                                            icon: Icons.flag,
                                            label: 'Status',
                                            customWidget: _buildStatusChip(
                                                report['status'] ?? 'pending'),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Description',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[200]!),
                                            ),
                                            child: Text(
                                              report['description'] ??
                                                  'No description provided',
                                              style:
                                                  const TextStyle(height: 1.5),
                                            ),
                                          ),
                                          if (isResolved &&
                                              resolveRemarks != null &&
                                              resolveRemarks.isNotEmpty) ...[
                                            const SizedBox(height: 24),
                                            AnimatedOpacity(
                                              opacity: isResolved ? 1.0 : 0.0,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.note_add,
                                                          size: 16,
                                                          color: Colors.green),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Resolution Remarks',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .green.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: Colors
                                                              .green.shade200),
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          TextEditingController(
                                                              text:
                                                                  resolveRemarks),
                                                      maxLines: 3,
                                                      decoration:
                                                          const InputDecoration(
                                                        hintText:
                                                            'Enter details about how this report was resolved...',
                                                        contentPadding:
                                                            EdgeInsets.all(12),
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (report['imageUrl'] != null &&
                                  report['imageUrl'].toString().isNotEmpty)
                                Expanded(
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(top: 8, left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Attached Image',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            height: 300,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[200]!),
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _viewFullImage(
                                                  report['imageUrl']),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7),
                                                    child: Image.network(
                                                      report['imageUrl'],
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .error_outline,
                                                                color:
                                                                    Colors.grey,
                                                                size: 40,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Error loading image',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: 24,
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
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Report Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoTile(
                                        icon: Icons.person,
                                        label: 'Reporter',
                                        value: report['userName'] ?? 'N/A',
                                      ),
                                      _buildInfoTile(
                                        icon: Icons.category,
                                        label: 'Type',
                                        value: report['incidentType'] ?? 'N/A',
                                      ),
                                      _buildInfoTile(
                                        icon: Icons.location_on,
                                        label: 'Location',
                                        value: report['location'] ?? 'N/A',
                                      ),
                                      _buildInfoTile(
                                        icon: Icons.access_time,
                                        label: 'Date Reported',
                                        value: formattedDate,
                                      ),
                                      _buildInfoTile(
                                        icon: Icons.flag,
                                        label: 'Status',
                                        customWidget: _buildStatusChip(
                                            report['status'] ?? 'pending'),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Text(
                                          report['description'] ??
                                              'No description provided',
                                          style: const TextStyle(height: 1.5),
                                        ),
                                      ),
                                      if (isResolved &&
                                          resolveRemarks != null &&
                                          resolveRemarks.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        AnimatedOpacity(
                                          opacity: isResolved ? 1.0 : 0.0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.note_add,
                                                      size: 16,
                                                      color: Colors.green),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Resolution Remarks',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors
                                                          .green.shade200),
                                                ),
                                                child: TextField(
                                                  controller:
                                                      TextEditingController(
                                                          text: resolveRemarks),
                                                  maxLines: 3,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        'Enter details about how this report was resolved...',
                                                    contentPadding:
                                                        EdgeInsets.all(12),
                                                    border: InputBorder.none,
                                                  ),
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (report['imageUrl'] != null &&
                                  report['imageUrl'].toString().isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Attached Image',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => _viewFullImage(
                                                report['imageUrl']),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  child: Image.network(
                                                    report['imageUrl'],
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return const Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color:
                                                                  Colors.grey,
                                                              size: 40,
                                                            ),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              'Error loading image',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.zoom_in,
                                                    color: Colors.white,
                                                    size: 24,
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
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade700,
                        side: BorderSide(color: Colors.blueGrey.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildInfoTile({
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
            child: Icon(
              icon,
              size: 20,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                customWidget ??
                    Text(
                      value ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateReportStatus(String reportId, Map<String, dynamic> report) {
    String selectedStatus = report['status'] ?? 'pending';
    final TextEditingController remarksController = TextEditingController();
    remarksController.text = report['resolveRemarks'] ?? '';
    final TextEditingController falseInfoRemarksController =
        TextEditingController();
    falseInfoRemarksController.text = report['falseInfoRemarks'] ?? '';

    // Get current status to implement restrictions
    final currentStatus = report['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        // Determine which status options are available based on current status
        List<Map<String, dynamic>> availableStatusOptions =
            _getAvailableStatusOptions(currentStatus);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 600,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Update Report Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Wrap the content in a SingleChildScrollView
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Current Status:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusChip(report['status'] ?? 'pending'),
                          const SizedBox(height: 24),
                          const Text(
                            'Select New Status:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: availableStatusOptions.map((option) {
                              return Column(
                                children: [
                                  _buildSimpleStatusOption(
                                    context,
                                    option['value'],
                                    option['label'],
                                    option['icon'],
                                    option['color'],
                                    selectedStatus,
                                    option['disabled'] == true
                                        ? null // Pass null for onChanged to disable the option
                                        : (value) {
                                            setState(() {
                                              selectedStatus = value;
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                          ),

                          // Remarks field for resolved status
                          if (selectedStatus == 'resolved') ...[
                            const SizedBox(height: 24),
                            AnimatedOpacity(
                              opacity: selectedStatus == 'resolved' ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.note_add,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Resolution Remarks',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: TextField(
                                      controller: remarksController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Enter details about how this report was resolved...',
                                        contentPadding: EdgeInsets.all(12),
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Remarks field for false information status
                          if (selectedStatus == 'false information') ...[
                            const SizedBox(height: 24),
                            AnimatedOpacity(
                              opacity: selectedStatus == 'false information'
                                  ? 1.0
                                  : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber,
                                          size: 16, color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'False Information Details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red.shade200),
                                    ),
                                    child: TextField(
                                      controller: falseInfoRemarksController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Explain why this report is considered false information...',
                                        contentPadding: EdgeInsets.all(12),
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Validation for both resolved and false information remarks
                          if (selectedStatus == 'resolved' &&
                              remarksController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Please add resolution remarks'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }

                          if (selectedStatus == 'false information' &&
                              falseInfoRemarksController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Please provide details about the false information'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }

                          String? remarks;
                          if (selectedStatus == 'resolved') {
                            remarks = remarksController.text;
                          } else if (selectedStatus == 'false information') {
                            remarks = falseInfoRemarksController.text;
                          }

                          // Show confirmation dialog before applying change
                          _showStatusUpdateConfirmation(
                            context: context,
                            reportId: reportId,
                            currentStatus: currentStatus,
                            newStatus: selectedStatus,
                            remarks: remarks,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Update Status'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Define available status options based on current status
  List<Map<String, dynamic>> _getAvailableStatusOptions(String currentStatus) {
    final List<Map<String, dynamic>> allOptions = [
      {
        'value': 'pending',
        'label': 'Pending',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
      },
      {
        'value': 'in progress',
        'label': 'In Progress',
        'icon': Icons.engineering,
        'color': Colors.blue,
      },
      {
        'value': 'resolved',
        'label': 'Resolved',
        'icon': Icons.task_alt,
        'color': Colors.green,
      },
      {
        'value': 'false information',
        'label': 'False Information',
        'icon': Icons.report_problem,
        'color': Colors.red.shade700,
      },
    ];

    // Apply restrictions based on current status
    switch (currentStatus.toLowerCase()) {
      case 'in progress':
        // Can't go back to pending from in progress
        return allOptions.map((option) {
          if (option['value'] == 'pending') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      case 'resolved':
        // Can't change from resolved to any other status
        return allOptions.map((option) {
          if (option['value'] != 'resolved') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      case 'false information':
        // Can't change from false information to any other status
        return allOptions.map((option) {
          if (option['value'] != 'false information') {
            return {...option, 'disabled': true};
          }
          return option;
        }).toList();

      default:
        // No restrictions for pending status
        return allOptions;
    }
  }

  // Show confirmation dialog before applying status changes
  void _showStatusUpdateConfirmation({
    required BuildContext context,
    required String reportId,
    required String currentStatus,
    required String newStatus,
    String? remarks,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400, // Constrain dialog width
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Confirm Status Update',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Are you sure you want to change the status from "$currentStatus" to "$newStatus"?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This action will notify the user and cannot be easily undone.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: BorderSide(color: Colors.blue.shade100),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Close the confirmation dialog
                          Navigator.of(dialogContext).pop();

                          // Close the status update dialog (parent)
                          Navigator.of(context).pop();

                          // Apply the status change
                          _changeStatus(reportId, newStatus, remarks);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update the simple status option to support disabled state
  Widget _buildSimpleStatusOption(
    BuildContext context,
    String value,
    String title,
    IconData icon,
    Color color,
    String selectedStatus,
    Function(String)? onChanged,
  ) {
    final isSelected = selectedStatus == value;
    final isDisabled = onChanged == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                onChanged(value);
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: selectedStatus,
                onChanged: isDisabled
                    ? null
                    : (newValue) {
                        if (newValue != null) {
                          onChanged(newValue);
                        }
                      },
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isDisabled) ...[
                Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Not allowed',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeStatus(String reportId, String newStatus,
      [String? remarks]) async {
    try {
      // First, get the current report data to access the reporter's userId
      final reportDoc = await FirebaseFirestore.instance
          .collection('reports_to_campus_security')
          .doc(reportId)
          .get();

      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final reporterId = reportData['userId'];
      final reportTitle = reportData['incidentType'] ?? 'Report';
      final userName = reportData['userName'] ?? 'User';

      // Prepare update data for the report
      final Map<String, dynamic> updateData = {'status': newStatus};

      // Add or remove remarks based on status
      if (newStatus == 'resolved' && remarks != null) {
        updateData['resolveRemarks'] = remarks;
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'false information' && remarks != null) {
        updateData['falseInfoRemarks'] = remarks;
        updateData['falseInfoMarkedAt'] = FieldValue.serverTimestamp();
      }

      // Update the report
      await FirebaseFirestore.instance
          .collection('reports_to_campus_security')
          .doc(reportId)
          .update(updateData);

      // Create notification for the user
      if (reporterId != null) {
        // Create Firestore notification entry
        await _createUserNotification(
          reporterId: reporterId,
          reportId: reportId,
          reportTitle: reportTitle,
          newStatus: newStatus,
          remarks: remarks,
        );

        // Send push notification to user device
        try {
          // Generate notification message
          final String message =
              _generateNotificationMessage(reportTitle, newStatus);

          // Get user data to determine user type
          // final userDoc = await FirebaseFirestore.instance
          //     .collection('users')
          //     .doc(reporterId)
          //     .get();

          // if (userDoc.exists) {
          //   final userData = userDoc.data() as Map<String, dynamic>;
          //   final userType = userData['userType'] ??
          //       "Student"; // Default to Student if no type found

          //   // Send push notification to the user
          //   await NotifServices.sendGroupNotification(
          //     userType: userType,
          //     heading: "Report Status Update",
          //     content: message,
          //   );

          await NotifServices.sendNotificationToSpecificUser(
            userId: reporterId,
            heading: "Report Status Update",
            content: message,
          );

          print(
              'Push notification sent to $userName (ID: $reportId) about report status update');
        } catch (e) {
          // Log error but don't stop the process if push notification fails
          print('Error sending push notification: $e');
        }
      }

      // Show success dialog instead of just a snackbar
      if (mounted) {
        _showSuccessDialog(newStatus);
      }
    } catch (e) {
      print('Error updating status: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method to show a success dialog after updating status
  void _showSuccessDialog(String newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 360, // Constrain dialog width
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 38),
                ),
                const SizedBox(height: 24),
                Text(
                  'Status Updated Successfully',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'The report status has been updated to "$newStatus".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Push notification has been sent to the reporter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
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
        );
      },
    );
  }

  Future<void> _createUserNotification({
    required String reporterId,
    required String reportId,
    required String reportTitle,
    required String newStatus,
    String? remarks,
  }) async {
    try {
      // Generate notification message based on status
      final String message =
          _generateNotificationMessage(reportTitle, newStatus);

      // Create notification document
      await FirebaseFirestore.instance
          .collection('reports_notifications_for_users')
          .add({
        'userId': reporterId,
        'reportId': reportId,
        'message': message,
        'status': newStatus,
        'remarks': remarks,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Silent error - don't prevent status update if notification fails
    }
  }

  String _generateNotificationMessage(String reportTitle, String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return 'Your report about "$reportTitle" is now being processed by our security team. We\'ll keep you updated on its progress.';
      case 'resolved':
        return 'Good news! Your report about "$reportTitle" has been resolved. You can check the details in the app.';
      case 'false information':
        return 'Your report about "$reportTitle" has been marked as containing incorrect information. Please check the app for more details.';
      default:
        return 'Your report about "$reportTitle" has been updated to "$status". Please check the app for more information.';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _viewFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.grey,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Error loading image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.download),
                  onPressed: () => _downloadImage(imageUrl),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download image: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build Generate Report Button
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
        // First check if there's data available
        try {
          final querySnapshot = await _getFilteredReportsQuery().get();
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
                        'There are no reports for the selected time period. Please adjust your filter or try again.',
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

          // If there is data, proceed with generating the report
          _generateAndDownloadReport();
        } catch (e) {
          // Handle errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking data: $e')),
          );
        }
      },
    );
  }

  // Generate and download report
  Future<void> _generateAndDownloadReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
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
                    'Gathering Report Data...',
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
          );
        },
      );

      // Get reports data based on current filter
      final QuerySnapshot reportsSnapshot =
          await _getFilteredReportsQuery().get();
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

      // Close loading dialog
      Navigator.of(context).pop();

      // Generate PDF
      await _generatePDF(reportsData);
    } catch (e) {
      // Close loading dialog if there's an error
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
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
  }

  // Generate PDF Report
  Future<void> _generatePDF(List<Map<String, dynamic>> reportsData) async {
    try {
      // Show loading indicator for image downloading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                      'Preparing Images...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading images for PDF report',
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
            );
          },
        );
      }

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

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

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
                        'Filter: $_selectedDateFilter',
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
      final bytes = await pdf.save();

      // Show confirmation dialog before downloading
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400, // Constrain dialog width
              padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 24),
                  Text(
                    'PDF Report Ready',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your report has been generated. Would you like to download it now?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey,
                            side: BorderSide(color: Colors.blue.shade100),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          onPressed: () {
                            Navigator.pop(context);
                            _downloadPDF(bytes);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
    } catch (e) {
      // Show error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('Error generating PDF: $e')),
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

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text('PDF report downloaded successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('Error downloading PDF: $e')),
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

  // Helper method to get the filtered query (not stream) for reports
  Query _getFilteredReportsQuery() {
    Query query =
        FirebaseFirestore.instance.collection('reports_to_campus_security');

    // Apply date filters
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Week':
        startDate = DateTime(now.year, now.month, now.day - 7);
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
        }
        break;
      default: // 'All'
        break;
    }

    // Date filter
    if (startDate != null && endDate != null) {
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Add ordering
    return query.orderBy('timestamp', descending: true);
  }

  // Helper function to get user profile image URL
  Future<String?> _getUserProfileImage(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          return userData['profileImage'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile image: $e');
      return null;
    }
  }

  // Keep the _getInitials helper as fallback
  String _getInitials(String name) {
    if (name.isEmpty) return 'NA';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
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
