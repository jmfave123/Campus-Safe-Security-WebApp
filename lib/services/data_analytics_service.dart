import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class DataAnalyticsService {
  // Simple in-memory cache for AI insights to avoid repeated API calls.
  static final Map<String, String> _aiInsightsCache = {};
  static const int _maxCacheSize =
      100; // Limit cache size to prevent memory issues

  // Rate limiting variables
  static DateTime _lastRequestTime =
      DateTime.now().subtract(Duration(minutes: 1));
  static const Duration _minRequestInterval =
      Duration(seconds: 2); // Increased from 500ms
  static int _consecutiveErrors = 0;
  static DateTime? _lastErrorTime;

  /// Manages cache size to prevent memory issues
  static void _manageCacheSize() {
    if (_aiInsightsCache.length > _maxCacheSize) {
      // Remove oldest entries (simple approach - remove first 20 entries)
      final keysToRemove = _aiInsightsCache.keys.take(20).toList();
      for (final key in keysToRemove) {
        _aiInsightsCache.remove(key);
      }
    }
  }

  /// Clears the AI insights cache (useful for testing or manual refresh)
  static void clearCache() {
    _aiInsightsCache.clear();
    _consecutiveErrors = 0;
    _lastErrorTime = null;
  }

  /// Fetches AI-powered insights from Gemini API, with enhanced rate limiting and caching.
  Future<String> getAIInsights({
    required List<double> values,
    required List<String> months,
    String itemLabel = 'report',
    String? customPrompt,
  }) async {
    // Generate a unique key for the cache based on the request parameters.
    final cacheKey =
        '$itemLabel|${months.join(',')}|${values.join(',')}|$customPrompt';

    // If a cached result exists, return it immediately.
    if (_aiInsightsCache.containsKey(cacheKey)) {
      return _aiInsightsCache[cacheKey]!;
    }

    // Manage cache size before adding new entries
    _manageCacheSize();

    // Implement rate limiting before making the request
    await _waitForRateLimit();

    // Make the API request directly with improved error handling
    return await _makeAPIRequest(
        cacheKey, itemLabel, months, values, customPrompt);
  }

  /// Implements adaptive rate limiting based on recent errors
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);

    // Calculate required delay based on consecutive errors
    Duration requiredDelay = _minRequestInterval;

    if (_consecutiveErrors > 0) {
      // Exponential backoff: 2s, 4s, 8s, 16s, max 60s
      final backoffSeconds = math.min(
        math.pow(2, _consecutiveErrors + 1).round(),
        60,
      );
      requiredDelay = Duration(seconds: backoffSeconds);
    }

    // Add extra delay if recent errors occurred
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!).inMinutes < 5) {
      requiredDelay = Duration(
        milliseconds: requiredDelay.inMilliseconds + 3000, // Extra 3s delay
      );
    }

    if (timeSinceLastRequest < requiredDelay) {
      final waitTime = requiredDelay - timeSinceLastRequest;
      await Future.delayed(waitTime);
    }

    _lastRequestTime = DateTime.now();
  }

  /// Makes the actual API request with improved error handling
  static Future<String> _makeAPIRequest(
    String cacheKey,
    String itemLabel,
    List<String> months,
    List<double> values,
    String? customPrompt,
  ) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'AI API key not found.';
    }

    // Prepare the prompt for Gemini (very concise, straight to the point)
    String prompt = customPrompt ??
        'In 2 sentences, state the main trend or anomaly for these $itemLabel values by month: '
            '${months.join(', ')}: ${values.map((v) => v.toInt()).join(', ')}. '
            'Then, in one short sentence, give one actionable recommendation.';

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    const int maxRetries = 5; // Increased from 3
    final rnd = math.Random();

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text is String && text.isNotEmpty) {
            final insight = text.trim();
            // Cache the successful result before returning.
            _aiInsightsCache[cacheKey] = insight;
            // Reset consecutive errors on success
            _consecutiveErrors = 0;
            return insight;
          } else {
            return 'AI analysis is processing. Please refresh in a moment.';
          }
        }

        // Enhanced rate limit handling
        if (response.statusCode == 429) {
          _consecutiveErrors++;
          _lastErrorTime = DateTime.now();

          if (attempt == maxRetries) {
            return 'AI insights temporarily unavailable due to high demand. Data analysis is still functional without AI insights.';
          }

          // More aggressive exponential backoff for 429 errors
          final backoffMs =
              (math.pow(3, attempt) * 1000).round() + rnd.nextInt(2000);
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        // Server errors: retry with longer backoff
        if (response.statusCode >= 500 && response.statusCode < 600) {
          _consecutiveErrors++;
          _lastErrorTime = DateTime.now();

          if (attempt == maxRetries) {
            return 'AI service experiencing issues. Basic analytics remain available.';
          }

          final backoffMs =
              (math.pow(2, attempt) * 2000).round() + rnd.nextInt(1000);
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        // Client errors - don't retry these
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return 'AI service configuration issue. Please contact administrator.';
        }

        // Other errors
        return 'AI analysis temporarily unavailable. Core functionality remains operational.';
      } catch (e) {
        _consecutiveErrors++;
        _lastErrorTime = DateTime.now();

        if (attempt == maxRetries) {
          return 'Network connectivity issue affecting AI insights. Dashboard data remains accurate.';
        }

        // Progressive backoff for network errors
        final jitter = rnd.nextInt(1000) + 1000;
        await Future.delayed(
            Duration(milliseconds: 2000 + (attempt * 1000) + jitter));
        continue;
      }
    }

    return 'AI insights temporarily unavailable. Please refresh the page in a few moments.';
  }

  /// Aggregates monthly counts from Firestore documents
  Map<String, int> getMonthlyCounts(
      List<QueryDocumentSnapshot> documents, String timestampField,
      {bool includeAllMonths = false, bool countUniqueIds = false}) {
    final Map<String, int> monthlyReportCounts = {};
    final Map<String, Set<String>> monthlyUniqueDocIds = {};
    final now = DateTime.now();
    final List<String> monthKeys = [];

    // Initialize all months in the current year with zero counts
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, i + 1, 1);
      final monthKey = DateFormat('MMM yyyy').format(month);
      monthKeys.add(monthKey);
      monthlyReportCounts[monthKey] = 0;
    }

    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey(timestampField)) {
        final dynamic timestampData = data[timestampField];
        DateTime date;
        if (timestampData is Timestamp) {
          date = timestampData.toDate();
        } else if (timestampData is int) {
          date = DateTime.fromMillisecondsSinceEpoch(timestampData);
        } else if (timestampData is String) {
          try {
            date = DateTime.parse(timestampData);
          } catch (e) {
            continue;
          }
        } else {
          continue;
        }

        if (date.year == now.year || includeAllMonths) {
          final monthKey =
              DateFormat('MMM yyyy').format(DateTime(date.year, date.month, 1));
          if (!monthlyReportCounts.containsKey(monthKey) && includeAllMonths) {
            if (monthKeys.length < 12) {
              monthKeys.add(monthKey);
              monthlyReportCounts[monthKey] = 0;
              if (countUniqueIds) {
                monthlyUniqueDocIds[monthKey] = <String>{};
              }
            }
          }
          if (countUniqueIds) {
            if (!monthlyUniqueDocIds.containsKey(monthKey)) {
              monthlyUniqueDocIds[monthKey] = <String>{};
            }
            if (!monthlyUniqueDocIds[monthKey]!.contains(doc.id)) {
              monthlyUniqueDocIds[monthKey]!.add(doc.id);
              monthlyReportCounts[monthKey] =
                  (monthlyReportCounts[monthKey] ?? 0) + 1;
            }
          } else {
            monthlyReportCounts[monthKey] =
                (monthlyReportCounts[monthKey] ?? 0) + 1;
          }
        }
      }
    }
    return monthlyReportCounts;
  }

  /// Returns a list of monthly values in order (Jan-Dec)
  List<double> getMonthlyValues(
      Map<String, int> monthlyCounts, List<String> monthKeys) {
    return monthKeys.map((key) => monthlyCounts[key]?.toDouble() ?? 0).toList();
  }

  /// Returns standard month abbreviations (Jan-Dec)
  List<String> getMonthAbbr() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = DateTime(now.year, i + 1, 1);
      return DateFormat('MMM').format(month).toUpperCase();
    });
  }

  /// Manual insight generation (same as getInsightsFromData)
  String getInsightsFromData(List<double> values, List<String> months,
      {String itemLabel = 'report'}) {
    if (values.isEmpty) return 'No data available for analysis.';
    int highestMonth = 0;
    int lowestMonth = 0;
    double highestValue = values[0];
    double lowestValue = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > highestValue) {
        highestValue = values[i];
        highestMonth = i;
      }
      if (values[i] < lowestValue) {
        lowestValue = values[i];
        lowestMonth = i;
      }
    }
    String trend = 'stable';
    if (values.length > 3) {
      double recentAvg = (values[values.length - 1] +
              values[values.length - 2] +
              values[values.length - 3]) /
          3;
      double earlierAvg = (values[0] + values[1] + values[2]) / 3;
      if (recentAvg > earlierAvg * 1.2) {
        trend = 'increasing';
      } else if (recentAvg < earlierAvg * 0.8) {
        trend = 'decreasing';
      }
    }
    return 'The highest number of ${itemLabel}s (${highestValue.toInt()}) was in ${months[highestMonth]}, '
        'while the lowest (${lowestValue.toInt()}) was in ${months[lowestMonth]}. '
        'Overall, $itemLabel submissions show a $trend trend over the last year.';
  }

  /// Helper for y-axis interval
  double calculateAppropriateInterval(int maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 4;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return (maxValue / 5).ceilToDouble();
  }

  /// Aggregates user counts by userType
  Map<String, int> getUserTypeCounts(List<QueryDocumentSnapshot> documents) {
    final Map<String, int> userTypeCounts = {};

    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>;
      final userType = data['userType'] as String? ?? 'Unknown';
      userTypeCounts[userType] = (userTypeCounts[userType] ?? 0) + 1;
    }

    return userTypeCounts;
  }

  /// Aggregates incident counts by incidentType
  Map<String, int> getIncidentTypeCounts(
      List<QueryDocumentSnapshot> documents) {
    final Map<String, int> incidentTypeCounts = {};

    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>;
      final incidentType = data['incidentType'] as String? ?? 'Others';
      incidentTypeCounts[incidentType] =
          (incidentTypeCounts[incidentType] ?? 0) + 1;
    }

    return incidentTypeCounts;
  }

  /// Filters documents by date range
  List<QueryDocumentSnapshot> filterDocumentsByDateRange(
    List<QueryDocumentSnapshot> documents,
    DateTime? startDate,
    DateTime? endDate, {
    String timestampField = 'createdAt',
  }) {
    if (startDate == null && endDate == null) {
      return documents;
    }

    return documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      DateTime? docDate;
      if (data.containsKey(timestampField)) {
        final dynamic timestampData = data[timestampField];
        if (timestampData is Timestamp) {
          docDate = timestampData.toDate();
        } else if (timestampData is int) {
          docDate = DateTime.fromMillisecondsSinceEpoch(timestampData);
        } else if (timestampData is String) {
          try {
            docDate = DateTime.parse(timestampData);
          } catch (e) {
            return false;
          }
        }
      }

      if (docDate == null) return false;

      if (startDate != null && docDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && docDate.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Gets date range based on filter selection
  Map<String, DateTime?> getDateRangeFromFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case 'Today':
        return {
          'startDate': today,
          'endDate': today.add(const Duration(days: 1)),
        };
      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'startDate': yesterday,
          'endDate': today,
        };
      case 'Last Week':
        final lastWeek = today.subtract(const Duration(days: 7));
        return {
          'startDate': lastWeek,
          'endDate': today.add(const Duration(days: 1)),
        };
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, now.day);
        return {
          'startDate': lastMonth,
          'endDate': today.add(const Duration(days: 1)),
        };
      case 'All':
      default:
        return {
          'startDate': null,
          'endDate': null,
        };
    }
  }
}
