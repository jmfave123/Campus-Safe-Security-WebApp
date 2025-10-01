import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../reusable_widget.dart';
import '../providers/audit_provider.dart';

class AuditUi extends StatelessWidget {
  const AuditUi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuditProvider()..loadAuditData(),
      child: const _AuditUiContent(),
    );
  }
}

class _AuditUiContent extends StatelessWidget {
  const _AuditUiContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: provider.isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, provider),
                        const SizedBox(height: 24),
                        // Skeleton loader for stat cards
                        Row(
                          children: List.generate(
                              4,
                              (i) => Expanded(
                                    child: Container(
                                      margin: i < 3
                                          ? const EdgeInsets.only(right: 16)
                                          : null,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 60,
                                            height: 24,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 80,
                                            height: 16,
                                            color: Colors.grey.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                        ),
                        const SizedBox(height: 24),
                        // Skeleton loader for filters section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: List.generate(
                                4,
                                (i) => Expanded(
                                      child: Container(
                                        height: 48,
                                        margin: i < 3
                                            ? const EdgeInsets.only(right: 16)
                                            : null,
                                        color: Colors.grey.shade300,
                                      ),
                                    )),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Skeleton loader for audit table
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: SizedBox(
                                  width: 120,
                                  height: 20,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: List.generate(
                                      6,
                                      (index) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                    width: 120,
                                                    height: 20,
                                                    color:
                                                        Colors.grey.shade300),
                                                const SizedBox(width: 18),
                                                Container(
                                                    width: 100,
                                                    height: 20,
                                                    color:
                                                        Colors.grey.shade300),
                                                const SizedBox(width: 18),
                                                Container(
                                                    width: 80,
                                                    height: 20,
                                                    color:
                                                        Colors.grey.shade300),
                                                const SizedBox(width: 18),
                                                Container(
                                                    width: 100,
                                                    height: 20,
                                                    color:
                                                        Colors.grey.shade300),
                                              ],
                                            ),
                                          )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, provider),
                        const SizedBox(height: 24),
                        _buildStatsCards(context, provider),
                        const SizedBox(height: 24),
                        _buildFiltersSection(context, provider),

                        // Display Selected Date Range Info
                        if (provider.selectedDateFilter != 'All')
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 16.0, bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  _getDateRangeLabel(provider),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                        _buildAuditTable(context, provider),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuditProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: boxDecoration2(
            Colors.blue.withOpacity(0.1),
            12,
            Colors.blue,
            0.2,
            0,
            8,
            const Offset(0, 2),
          ),
          child: const Icon(
            Icons.history,
            color: Colors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Logs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Track all user and admin activities',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed:
              () {}, // Stream updates automatically with provider changes
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context, AuditProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Logs',
            '${provider.auditStats['total_logs'] ?? 0}',
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Successful',
            '${provider.auditStats['successful_operations'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Failed',
            '${provider.auditStats['failed_operations'] ?? 0}',
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Success Rate',
            _calculateSuccessRate(provider),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
    );
  }

  Widget _buildFiltersSection(BuildContext context, AuditProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filter by Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        _buildDateFilterButton(context, provider),
      ],
    );
  }

  Widget _buildDateFilterButton(BuildContext context, AuditProvider provider) {
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
            provider.updateDateFilter(value);
            return;
          }

          // For Custom, open the shared compact date-range picker from reusable_widget.dart
          final result = await showCustomDateRangePicker(context);
          if (result != null &&
              result.containsKey('start') &&
              result.containsKey('end')) {
            provider.updateCustomDateRange(result['start'], result['end']);
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
            final isSelected = provider.selectedDateFilter == option['value'];
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
                provider.selectedDateFilter,
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

  Widget _buildAuditTable(BuildContext context, AuditProvider provider) {
    return Container(
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: provider.getAuditLogsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                final errorString = snapshot.error.toString();

                // Check if it's a permission error (likely during logout)
                if (errorString.contains('permission-denied') ||
                    errorString.contains('insufficient permissions')) {
                  // Show a subtle message instead of alarming error
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Audit logs not accessible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show regular error for other types of errors
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading audit logs: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No audit logs found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final auditLogs = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();

              return _buildDataTable(context, auditLogs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(
      BuildContext context, List<Map<String, dynamic>> auditLogs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 48,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  'Timestamp',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 180,
                child: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 80,
                child: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 100,
                child: Text(
                  'Platform',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 200,
                child: Text(
                  'User Email',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 150,
                child: Text(
                  'User Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          rows: auditLogs.map((log) => _buildDataRow(log)).toList(),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 72,
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> log) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              _formatTimestamp(log['timestamp']),
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: _buildActionChip(log['action']),
          ),
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: _buildStatusChip(log['status']),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: _buildPlatformChip(log['platform']),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              log['user_email'] ?? 'N/A',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: _buildUserTypeChip(log['user_type']),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(String? action) {
    if (action == null)
      return const Text('N/A', style: TextStyle(fontSize: 12));

    Color color;
    String displayText;

    // Determine color and display text based on action
    switch (action.toLowerCase()) {
      case 'login':
        color = Colors.green;
        displayText = 'LOGIN';
        break;
      case 'logout':
        color = Colors.orange;
        displayText = 'LOGOUT';
        break;
      case 'report updated':
        color = Colors.blue;
        displayText = 'REPORT UPDATED';
        break;
      case 'announcement created':
        color = Colors.purple;
        displayText = 'ANNOUNCEMENT';
        break;
      case 'guard verified':
        color = Colors.teal;
        displayText = 'GUARD VERIFIED';
        break;
      case 'guard profile updated':
        color = Colors.indigo;
        displayText = 'GUARD UPDATED';
        break;
      case 'profile updated':
        color = Colors.amber;
        displayText = 'PROFILE UPDATED';
        break;
      case 'password changed':
        color = Colors.red;
        displayText = 'PASSWORD CHANGED';
        break;
      default:
        color = Colors.grey;
        displayText = action.replaceAll('_', ' ').toUpperCase();
        if (displayText.length > 20) {
          displayText = displayText.substring(0, 20) + '...';
        }
    }

    return Tooltip(
      message: action, // Show the full original action text on hover
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // Widget _buildFileTypeChip(String? fileType) {
  //   if (fileType == null) return const Text('N/A');

  //   Color color = switch (fileType.toLowerCase()) {
  //     'json' => Colors.orange,
  //     'csv' => Colors.green,
  //     'excel' => Colors.purple,
  //     _ => Colors.grey,
  //   };

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       fileType.toUpperCase(),
  //       style: TextStyle(
  //         color: color,
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPlatformChip(String? platform) {
    if (platform == null || platform.isEmpty)
      return const Text('N/A', style: TextStyle(fontSize: 11));

    Color color;
    String displayText;

    if (platform.toLowerCase().contains('web')) {
      color = Colors.blue;
      displayText = 'WEB';
    } else if (platform.toLowerCase().contains('mobile')) {
      color = Colors.green;
      displayText = 'MOBILE';
    } else if (platform.toLowerCase().contains('android')) {
      color = Colors.green;
      displayText = 'ANDROID';
    } else if (platform.toLowerCase().contains('ios')) {
      color = Colors.purple;
      displayText = 'iOS';
    } else {
      color = Colors.grey;
      displayText = platform.length > 8
          ? platform.substring(0, 8).toUpperCase()
          : platform.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildUserTypeChip(String? userType) {
    if (userType == null || userType.isEmpty)
      return const Text('N/A', style: TextStyle(fontSize: 11));

    Color color;
    String displayText;

    switch (userType.toLowerCase()) {
      case 'campus security administrator':
        color = Colors.red;
        displayText = 'Admin';
        break;
      case 'campus security guard':
        color = Colors.orange;
        displayText = 'Guard';
        break;
      case 'student':
        color = Colors.blue;
        displayText = 'Student';
        break;
      case 'faculty':
        color = Colors.green;
        displayText = 'Faculty';
        break;
      case 'staff':
        color = Colors.green;
        displayText = 'Staff';
        break;
      default:
        color = Colors.grey;
        displayText =
            userType.length > 10 ? userType.substring(0, 10) : userType;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == null)
      return const Text('N/A', style: TextStyle(fontSize: 11));

    Color color = status == 'success' ? Colors.green : Colors.red;
    IconData icon = status == 'success' ? Icons.check_circle : Icons.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      // Handle human-readable formats like:
      // "October 1, 2025 at 8:45 AM UTC+8" or with seconds
      if (timestamp is String) {
        final raw = timestamp.trim();

        // Extract UTC offset if present: matches 'UTC+8', 'UTC+08:00', etc.
        final offsetMatch =
            RegExp(r'UTC([+-]\d{1,2})(?::(\d{2}))?').firstMatch(raw);
        int offsetHours = 0;
        int offsetMinutes = 0;
        if (offsetMatch != null) {
          offsetHours = int.parse(offsetMatch.group(1)!);
          if (offsetMatch.group(2) != null) {
            offsetMinutes = int.parse(offsetMatch.group(2)!);
          }
        }

        // Remove the ' at ' and the UTC part to get a clean date-time string
        String clean = raw.replaceAll(' at ', ' ');
        clean = clean.replaceAll(RegExp(r'\s*UTC[+-]\d{1,2}(:\d{2})?\s*'), '');

        // Try parsing with seconds first, then without
        DateTime parsed;
        try {
          parsed = DateFormat('MMMM d, yyyy h:mm:ss a').parseLoose(clean);
        } catch (_) {
          parsed = DateFormat('MMMM d, yyyy h:mm a').parseLoose(clean);
        }

        // If we found an offset, interpret 'parsed' as being in that offset timezone
        // and convert it to local time. For example, 'UTC+8' means local = parsed - 8h (to get UTC) then toLocal.
        if (offsetMatch != null) {
          final absHours = offsetHours.abs();
          final offsetDuration = Duration(
              hours: absHours * (offsetHours >= 0 ? 1 : -1),
              minutes: offsetMinutes * (offsetHours >= 0 ? 1 : -1));

          // The parsed DateTime has no timezone; treat it as if it were in the offset timezone -> to get UTC subtract offset
          final asUtc = parsed.subtract(offsetDuration);
          final local = asUtc.toLocal();
          return DateFormat('MMM dd, yyyy HH:mm').format(local);
        }

        // No offset present, assume parsed is local
        return DateFormat('MMM dd, yyyy HH:mm').format(parsed);
      }

      // Handle DateTime objects directly
      if (timestamp is Timestamp) {
        final DateTime dt = timestamp.toDate();
        return DateFormat('MMM dd, yyyy HH:mm').format(dt);
      }

      final DateTime dateTime = timestamp as DateTime;
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _calculateSuccessRate(AuditProvider provider) {
    final total = provider.auditStats['total_logs'] ?? 0;
    final successful = provider.auditStats['successful_operations'] ?? 0;

    if (total == 0) return '0%';

    final rate = (successful / total * 100).round();
    return '$rate%';
  }

  // Helper to get the descriptive label shown below the header
  String _getDateRangeLabel(AuditProvider provider) {
    DateTime now = DateTime.now();
    switch (provider.selectedDateFilter) {
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
        if (provider.customStartDate != null &&
            provider.customEndDate != null) {
          final start =
              DateFormat('MMM dd, yyyy').format(provider.customStartDate!);
          final end =
              DateFormat('MMM dd, yyyy').format(provider.customEndDate!);
          return 'Showing logs for: $start - $end';
        }
        return 'Showing logs for: Custom Range';
      // No label needed for 'All' as it's implicit
      default:
        return 'Selected: ${provider.selectedDateFilter}'; // Fallback
    }
  }
}
