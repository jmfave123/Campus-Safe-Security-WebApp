import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/audit_log_service.dart';
import '../reusable_widget.dart';

class AuditUi extends StatefulWidget {
  const AuditUi({super.key});

  @override
  State<AuditUi> createState() => _AuditUiState();
}

class _AuditUiState extends State<AuditUi> {
  final AuditLogService _auditService = AuditLogService();
  List<Map<String, dynamic>> _auditLogs = [];
  Map<String, dynamic> _auditStats = {};
  bool _isLoading = true;
  String? _selectedAction;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAuditData();
  }

  Future<void> _loadAuditData() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _auditService.getAuditLogs(
        limit: 100,
        filterByAction: _selectedAction,
        filterByStatus: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );

      final stats = await _auditService.getAuditStats();
      // ADD THIS LINE:
      print('AUDIT LOGS: $logs');
      setState(() {
        _auditLogs = logs;
        _auditStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audit logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(8),
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
                                              color: Colors.grey.shade300),
                                          const SizedBox(width: 18),
                                          Container(
                                              width: 100,
                                              height: 20,
                                              color: Colors.grey.shade300),
                                          const SizedBox(width: 18),
                                          Container(
                                              width: 80,
                                              height: 20,
                                              color: Colors.grey.shade300),
                                          const SizedBox(width: 18),
                                          Container(
                                              width: 100,
                                              height: 20,
                                              color: Colors.grey.shade300),
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildFiltersSection(),
                  const SizedBox(height: 24),
                  _buildAuditTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
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
              'Track backup operations and system activities',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _loadAuditData,
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

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Logs',
            '${_auditStats['total_logs'] ?? 0}',
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Successful',
            '${_auditStats['successful_backups'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Failed',
            '${_auditStats['failed_backups'] ?? 0}',
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Success Rate',
            _calculateSuccessRate(),
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

  Widget _buildFiltersSection() {
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
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  'Action',
                  _selectedAction,
                  ['backup_created', 'backup_failed'],
                  (value) => setState(() {
                    _selectedAction = value;
                    _loadAuditData();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownFilter(
                  'Status',
                  _selectedStatus,
                  ['success', 'failed'],
                  (value) => setState(() {
                    _selectedStatus = value;
                    _loadAuditData();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateFilter(),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedAction = null;
                    _selectedStatus = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadAuditData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          hint: Text('All ${label.toLowerCase()}s'),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(
            _startDate != null && _endDate != null
                ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
                : 'Select dates',
          ),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTable() {
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
          _auditLogs.isEmpty
              ? const Padding(
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
                )
              : _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    // Make the table fill the entire width of the parent container
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
        columnSpacing: 18, // Reduce spacing for a compact fit
        columns: const [
          DataColumn(
            label: Text(
              'Timestamp',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DataColumn(
            label: Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DataColumn(
            label: Text(
              'Platform',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        rows: _auditLogs.map((log) => _buildDataRow(log)).toList(),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> log) {
    return DataRow(
      cells: [
        DataCell(Text(_formatTimestamp(log['timestamp']))),
        DataCell(_buildActionChip(log['action'])),
        DataCell(_buildStatusChip(log['status'])),
        DataCell(_buildPlatformChip(log['platform'])),
      ],
    );
  }

  Widget _buildActionChip(String? action) {
    if (action == null) return const Text('N/A');

    Color color = action.contains('failed') ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
    if (platform == null || platform.isEmpty) return const Text('N/A');
    Color color;
    switch (platform.toLowerCase()) {
      case 'web':
        color = Colors.blue;
        break;
      case 'android':
        color = Colors.green;
        break;
      case 'ios':
        color = Colors.purple;
        break;
      case 'windows':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        platform.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == null) return const Text('N/A');

    Color color = status == 'success' ? Colors.green : Colors.red;
    IconData icon = status == 'success' ? Icons.check_circle : Icons.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        dateTime = timestamp as DateTime;
      }
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return 'N/A';

    try {
      int ms = duration is int ? duration : int.parse(duration.toString());
      if (ms < 1000) {
        return '${ms}ms';
      } else {
        double seconds = ms / 1000;
        return '${seconds.toStringAsFixed(1)}s';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculateSuccessRate() {
    final total = _auditStats['total_logs'] ?? 0;
    final successful = _auditStats['successful_backups'] ?? 0;

    if (total == 0) return '0%';

    final rate = (successful / total * 100).round();
    return '$rate%';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAuditData();
    }
  }
}
