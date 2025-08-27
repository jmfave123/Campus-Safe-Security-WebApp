// ignore_for_file: use_build_context_synchronously, unused_local_variable, avoid_web_libraries_in_flutter, unnecessary_import, unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../reusable_widget.dart';
import '../services/user_reports_service.dart';
import '../services/reports_pdf_service.dart';
import '../services/image_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Services
  final UserReportsService _reportsService = UserReportsService();
  final ReportsPDFService _pdfService = ReportsPDFService();
  final ImageService _imageService = ImageService();

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
                        'Date range: ${_reportsService.formatDate(_customStartDate)} - ${_reportsService.formatDate(_customEndDate)}',
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
                  stream: _reportsService.getFilteredReportsStream(
                    _selectedDateFilter,
                    _customStartDate,
                    _customEndDate,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Skeleton loader for reports table and stat cards
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  3,
                                  (i) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Container(
                                          width: 60,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      )),
                            ),
                            const SizedBox(height: 32),
                            Column(
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
                          ],
                        ),
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
                                  final inProgressReports = reports
                                      .where((doc) =>
                                          (doc.data() as Map<String, dynamic>)[
                                                  'status']
                                              ?.toLowerCase() ==
                                          'in progress')
                                      .length;
                                  final falseReportCount = reports
                                      .where((doc) =>
                                          (doc.data() as Map<String, dynamic>)[
                                                  'status']
                                              ?.toLowerCase() ==
                                          'false report')
                                      .length;

                                  if (constraints.maxWidth < 600) {
                                    return Column(
                                      children: [
                                        buildStatCardAlerts(
                                          'Total Reports',
                                          Text(
                                            totalReports.toString(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icons.report,
                                          const Color(0xFF4285F4),
                                        ),
                                        const SizedBox(height: 16),
                                        buildStatCardAlerts(
                                          'Pending Reports',
                                          Text(
                                            pendingReports.toString(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icons.pending_actions,
                                          const Color(0xFFFF9800),
                                        ),
                                        const SizedBox(height: 16),
                                        buildStatCardAlerts(
                                          'Resolved Reports',
                                          Text(
                                            resolvedReports.toString(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icons.task_alt,
                                          const Color(0xFF0F9D58),
                                        ),
                                        const SizedBox(height: 16),
                                        buildStatCardAlerts(
                                          'In Progress Reports',
                                          Text(
                                            inProgressReports.toString(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icons.engineering,
                                          Colors.blue,
                                        ),
                                        const SizedBox(height: 16),
                                        buildStatCardAlerts(
                                          'False Reports',
                                          Text(
                                            falseReportCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icons.report_problem,
                                          Colors.red.shade700,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: buildStatCardAlerts(
                                            'Total Reports',
                                            Text(
                                              totalReports.toString(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icons.report,
                                            const Color(0xFF4285F4),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildStatCardAlerts(
                                            'Pending Reports',
                                            Text(
                                              pendingReports.toString(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icons.pending_actions,
                                            const Color(0xFFFF9800),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildStatCardAlerts(
                                            'Resolved Reports',
                                            Text(
                                              resolvedReports.toString(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icons.task_alt,
                                            const Color(0xFF0F9D58),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildStatCardAlerts(
                                            'In Progress Reports',
                                            Text(
                                              inProgressReports.toString(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icons.engineering,
                                            Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildStatCardAlerts(
                                            'False Reports',
                                            Text(
                                              falseReportCount.toString(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icons.report_problem,
                                            Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A1851).withOpacity(0.3), // kPrimaryColor
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter by date',
        onSelected: (String value) async {
          // Non-custom options: apply immediately and clear any custom dates
          if (value != 'Custom') {
            setState(() {
              _selectedDateFilter = value;
              _customStartDate = null;
              _customEndDate = null;
            });
            return;
          }

          // For Custom, open the shared compact date-range picker from reusable_widget.dart
          final result = await showCustomDateRangePicker(context);
          if (result != null &&
              result.containsKey('start') &&
              result.containsKey('end')) {
            setState(() {
              _selectedDateFilter = 'Custom';
              _customStartDate = result['start'];
              _customEndDate = result['end'];
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

  Widget _buildStatusFilterButton() {
    return Container();
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
        final falseInfoRemarks = report['falseReportRemarks'];
        final hasRemarks = status.toLowerCase() == 'resolved' &&
            remarks != null &&
            remarks.isNotEmpty;
        final hasFalseInfoRemarks = status.toLowerCase() == 'false reports' &&
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
                            : status.toLowerCase() == 'false report'
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
                          future: _reportsService.getUserProfileImage(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // Skeleton loader for profile image
                              return const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person,
                                    color: Colors.white, size: 20),
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
                                _reportsService
                                    .getInitials(report['userName'] ?? 'NA'),
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
                                  'False Report Notes',
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
      case 'false report':
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

  void _showReportDetails(Map<String, dynamic> report) {
    final timestamp = report['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final resolveRemarks = report['resolveRemarks'];
    final falseInfoRemarks = report['falseInfoRemarks'];
    final isResolved = (report['status'] ?? '').toLowerCase() == 'resolved';
    final isFalseInfo =
        (report['status'] ?? '').toLowerCase() == 'false report';

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
    falseInfoRemarksController.text = report['falseInfoRemarks  '] ?? '';

    // Get current status to implement restrictions
    final currentStatus = report['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        // Determine which status options are available based on current status
        List<Map<String, dynamic>> availableStatusOptions =
            _reportsService.getAvailableStatusOptions(currentStatus);

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

                          // Remarks field for false report status
                          if (selectedStatus == 'false report') ...[
                            const SizedBox(height: 24),
                            AnimatedOpacity(
                              opacity:
                                  selectedStatus == 'false report' ? 1.0 : 0.0,
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
                                        'False Report Details',
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
                                            'Explain why this report is considered false report...',
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

                          if (selectedStatus == 'false report' &&
                              falseInfoRemarksController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Please provide details about the false report'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }

                          String? remarks;
                          if (selectedStatus == 'resolved') {
                            remarks = remarksController.text;
                          } else if (selectedStatus == 'false report') {
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

                          // Apply the status change using the service
                          _changeStatusWithService(
                              reportId, newStatus, remarks);
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

  // Change status using the service
  Future<void> _changeStatusWithService(String reportId, String newStatus,
      [String? remarks]) async {
    try {
      await _reportsService.updateReportStatus(reportId, newStatus, remarks);

      // Show success dialog
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
    await _imageService.downloadImage(
      imageUrl,
      onSuccess: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
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
          final querySnapshot = await _reportsService
              .getFilteredReportsQuery(
                _selectedDateFilter,
                _customStartDate,
                _customEndDate,
              )
              .get();
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

  // Generate and download report using the service
  Future<void> _generateAndDownloadReport() async {
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
                  'Generating Report...',
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

    try {
      await _pdfService.generateAndDownloadReport(
        reportsQuery: _reportsService.getFilteredReportsQuery(
          _selectedDateFilter,
          _customStartDate,
          _customEndDate,
        ),
        selectedDateFilter: _selectedDateFilter,
        onError: (error) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 5),
            ),
          );
        },
        onSuccess: () {
          Navigator.of(context).pop(); // Close loading dialog
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
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
