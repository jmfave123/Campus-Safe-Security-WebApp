import 'dart:async';
import '../services/data_analytics_service.dart';

/// A utility class to manage AI insights requests at the UI level
/// to further prevent rate limiting issues
class AIInsightsManager {
  static final Map<String, Timer> _pendingRequests = {};
  static const Duration _debounceDelay = Duration(milliseconds: 1000);

  /// Debounces AI insights requests to prevent rapid successive calls
  static Future<String> getInsightsWithDebounce({
    required String requestId,
    required List<double> values,
    required List<String> months,
    String itemLabel = 'report',
    String? customPrompt,
    required DataAnalyticsService analyticsService,
  }) async {
    // Cancel any existing timer for this request
    _pendingRequests[requestId]?.cancel();

    final completer = Completer<String>();

    // Create a new debounced request
    _pendingRequests[requestId] = Timer(_debounceDelay, () async {
      try {
        final result = await analyticsService.getAIInsights(
          values: values,
          months: months,
          itemLabel: itemLabel,
          customPrompt: customPrompt,
        );
        completer.complete(result);
      } catch (e) {
        completer.complete(
            'AI insights temporarily unavailable. Please try again later.');
      } finally {
        _pendingRequests.remove(requestId);
      }
    });

    return completer.future;
  }

  /// Cancels all pending requests (useful when navigating away from the dashboard)
  static void cancelAllRequests() {
    for (final timer in _pendingRequests.values) {
      timer.cancel();
    }
    _pendingRequests.clear();
  }

  /// Creates a user-friendly error message based on common API error patterns
  static String createUserFriendlyMessage(String apiResponse) {
    if (apiResponse.contains('429') ||
        apiResponse.toLowerCase().contains('too many requests')) {
      return 'AI insights are temporarily busy. Your data is still accurate and we\'ll retry automatically.';
    } else if (apiResponse.toLowerCase().contains('api key')) {
      return 'AI insights service is being configured. Basic analytics remain fully functional.';
    } else if (apiResponse.toLowerCase().contains('network') ||
        apiResponse.toLowerCase().contains('connectivity')) {
      return 'Connection issue detected. Your dashboard data is current and AI insights will resume when connectivity improves.';
    } else if (apiResponse.toLowerCase().contains('server error') ||
        apiResponse.contains('5')) {
      return 'AI service is experiencing temporary issues. All core dashboard features continue to work normally.';
    } else {
      return 'AI insights are temporarily processing. Your dashboard remains fully operational with manual insights.';
    }
  }
}
