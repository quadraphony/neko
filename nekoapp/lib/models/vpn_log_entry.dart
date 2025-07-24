import 'package:flutter/foundation.dart';

class VpnLogEntry {
  final String message;
  final DateTime timestamp;

  VpnLogEntry({
    required this.message,
    required this.timestamp,
  });

  factory VpnLogEntry.fromJson(Map<String, dynamic> json) {
    return VpnLogEntry(
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}


