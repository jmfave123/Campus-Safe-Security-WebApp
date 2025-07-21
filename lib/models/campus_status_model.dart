// campus_status_model.dart
import 'package:flutter/material.dart';

enum CampusStatusLevel {
  safe,
  caution,
  emergency,
}

extension CampusStatusLevelExtension on CampusStatusLevel {
  String get name {
    switch (this) {
      case CampusStatusLevel.safe:
        return 'Safe';
      case CampusStatusLevel.caution:
        return 'Caution';
      case CampusStatusLevel.emergency:
        return 'Emergency';
    }
  }

  Color get color {
    switch (this) {
      case CampusStatusLevel.safe:
        return Colors.green;
      case CampusStatusLevel.caution:
        return Colors.orange;
      case CampusStatusLevel.emergency:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case CampusStatusLevel.safe:
        return Icons.check_circle;
      case CampusStatusLevel.caution:
        return Icons.warning;
      case CampusStatusLevel.emergency:
        return Icons.emergency;
    }
  }
}

class CampusStatus {
  final CampusStatusLevel level;
  final DateTime timestamp;
  final String updatedBy;
  final String reason;

  CampusStatus({
    required this.level,
    required this.timestamp,
    required this.updatedBy,
    required this.reason,
  });

  factory CampusStatus.fromMap(Map<dynamic, dynamic> map) {
    return CampusStatus(
      level: _levelFromString(map['current_status'] ?? 'safe'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['last_updated'] ?? 0),
      updatedBy: map['updated_by'] ?? '',
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_status': level.name.toLowerCase(),
      'last_updated': timestamp.millisecondsSinceEpoch,
      'updated_by': updatedBy,
      'reason': reason,
    };
  }

  static CampusStatusLevel _levelFromString(String level) {
    switch (level.toLowerCase()) {
      case 'caution':
        return CampusStatusLevel.caution;
      case 'emergency':
        return CampusStatusLevel.emergency;
      case 'safe':
      default:
        return CampusStatusLevel.safe;
    }
  }
}
