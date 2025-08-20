import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DataAnalyticsService {
  /// Fetches AI-powered insights from Gemini API
  Future<String> getAIInsights({
    required List<double> values,
    required List<String> months,
    String itemLabel = 'report',
    String? customPrompt,
  }) async {
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
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

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text is String && text.isNotEmpty) {
          return text.trim();
        } else {
          return 'AI did not return any insight.';
        }
      } else {
        return 'AI request failed: ${response.statusCode}';
      }
    } catch (e) {
      return 'AI request error: $e';
    }
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
}
