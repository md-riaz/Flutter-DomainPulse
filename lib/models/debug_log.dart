enum LogLevel {
  info,
  success,
  error,
  warning,
}

class DebugLog {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? details;

  DebugLog({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'details': details,
    };
  }

  factory DebugLog.fromJson(Map<String, dynamic> json) {
    return DebugLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String,
      details: json['details'] as String?,
    );
  }
}
