import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audit_log_service.dart';

class AuditProvider extends ChangeNotifier {
  final AuditLogService _auditService = AuditLogService();

  // State variables (migrated from _AuditUiState)
  Map<String, dynamic> _auditStats = {};
  bool _isLoading = true;
  String _selectedDateFilter = "Today";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Getters
  Map<String, dynamic> get auditStats => _auditStats;
  bool get isLoading => _isLoading;
  String get selectedDateFilter => _selectedDateFilter;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  // Stream getter for filtered audit logs
  Stream<QuerySnapshot> getAuditLogsStream() {
    // Check if user is authenticated before returning stream
    if (FirebaseAuth.instance.currentUser == null) {
      return const Stream.empty();
    }

    Query query = FirebaseFirestore.instance.collection('audit_logs');

    // Calculate date range based on selected filter
    final dateRange = _getDateRange();

    // Apply date range filter if we have dates
    if (dateRange['start'] != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange['start']!));
    }

    if (dateRange['end'] != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(dateRange['end']!));
    }

    // Order by timestamp
    query = query.orderBy('timestamp', descending: true);

    // Limit results
    query = query.limit(100);

    return query.snapshots();
  }

  // Load audit stats (async operation)
  Future<void> loadAuditData() async {
    // Check if user is authenticated before loading data
    if (FirebaseAuth.instance.currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _auditService.getAuditStats();
      _auditStats = stats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Re-throw to let UI handle error display
      rethrow;
    }
  }

  // Update date filter
  void updateDateFilter(String filter) {
    _selectedDateFilter = filter;
    // Clear custom dates when switching away from custom
    if (filter != 'Custom') {
      _customStartDate = null;
      _customEndDate = null;
    }
    notifyListeners();
  }

  // Update custom date range
  void updateCustomDateRange(DateTime? start, DateTime? end) {
    _customStartDate = start;
    _customEndDate = end;
    _selectedDateFilter = 'Custom';
    notifyListeners();
  }

  // Calculate date range based on filter (private method)
  Map<String, DateTime?> _getDateRange() {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedDateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'Last Week':
        startDate = now.subtract(Duration(days: now.weekday - 1 + 7));
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Custom':
        startDate = _customStartDate;
        endDate = _customEndDate != null
            ? DateTime(_customEndDate!.year, _customEndDate!.month,
                _customEndDate!.day, 23, 59, 59)
            : null;
        break;
      case 'All':
      default:
        startDate = null;
        endDate = null;
        break;
    }

    return {'start': startDate, 'end': endDate};
  }
}
