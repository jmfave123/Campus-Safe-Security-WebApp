import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/alcohol_detection_services.dart';

class AlcoholDetectionProvider extends ChangeNotifier {
  // State variables
  String _selectedDateFilter = "Today";
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = false;
  String? _error;

  // Getters
  String get selectedDateFilter => _selectedDateFilter;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream getter for filtered alcohol detections
  Stream<QuerySnapshot> getDetectionsStream() {
    // Check if user is authenticated before returning stream
    if (FirebaseAuth.instance.currentUser == null) {
      return const Stream.empty();
    }

    final dateRange = AlcoholDetectionService.getDateRangeForFilter(
      _selectedDateFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );

    return AlcoholDetectionService.getFilteredDetectionsStream(
      dateRange: dateRange,
    );
  }

  // Get filtered detections with caching
  List<QueryDocumentSnapshot> getFilteredDetections(
      List<QueryDocumentSnapshot> docs) {
    final dateRange = AlcoholDetectionService.getDateRangeForFilter(
      _selectedDateFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );

    return AlcoholDetectionService.filterDetectionsByDateRange(docs, dateRange);
  }

  // Get statistics for filtered data
  Map<String, int> getStatistics(
      List<QueryDocumentSnapshot> filteredDetections) {
    int totalCount = filteredDetections.length;
    int activeCount = filteredDetections.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status =
          data['status'] as String? ?? AlcoholDetectionService.statusActive;
      return status == AlcoholDetectionService.statusActive;
    }).length;
    int resolvedCount = filteredDetections.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status =
          data['status'] as String? ?? AlcoholDetectionService.statusActive;
      return status == AlcoholDetectionService.statusResolved;
    }).length;

    return {
      'total': totalCount,
      'active': activeCount,
      'resolved': resolvedCount,
    };
  }

  // Update date filter
  void updateDateFilter(String filter) {
    if (_selectedDateFilter != filter) {
      _selectedDateFilter = filter;
      // Clear custom dates when switching away from custom
      if (filter != 'Custom') {
        _customStartDate = null;
        _customEndDate = null;
      }
      _clearError();
      notifyListeners();
    }
  }

  // Update custom date range
  void updateCustomDateRange(DateTime? start, DateTime? end) {
    if (_customStartDate != start || _customEndDate != end) {
      _customStartDate = start;
      _customEndDate = end;
      _selectedDateFilter = 'Custom';
      _clearError();
      notifyListeners();
    }
  }

  // Update detection status
  Future<void> updateDetectionStatus(String docId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      await AlcoholDetectionService.updateDetectionStatus(docId, isActive);
      // Status update success - UI will automatically update via stream
    } catch (e) {
      _setError('Failed to update status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Generate report - TODO: Implement report generation in service
  Future<void> generateReport() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Add generateDetectionReport method to AlcoholDetectionService
      // final dateRange = AlcoholDetectionService.getDateRangeForFilter(
      //   _selectedDateFilter,
      //   customStartDate: _customStartData,
      //   customEndDate: _customEndDate,
      // );
      // await AlcoholDetectionService.generateDetectionReport(dateRange);

      // For now, just indicate that this feature needs implementation
      throw UnimplementedError(
          'Report generation not yet implemented in service');
    } catch (e) {
      _setError('Failed to generate report: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Clear all filters (reset to default)
  void clearFilters() {
    _selectedDateFilter = "Today";
    _customStartDate = null;
    _customEndDate = null;
    _clearError();
    notifyListeners();
  }

  // Dispose method to clean up resources
}
