enum MonitoringMode {
  expiryOnly,
  availabilityOnly,
  both,
}

class Domain {
  final String id;
  final String url;
  final Duration checkInterval;
  final DateTime? lastChecked;
  final DateTime? expiryDate;
  final int alarmId;
  final Duration notifyBeforeExpiry;
  final bool? isAvailable;
  final DateTime? lastAvailabilityCheck;
  final MonitoringMode monitoringMode;

  Domain({
    required this.id,
    required this.url,
    required this.checkInterval,
    this.lastChecked,
    this.expiryDate,
    required this.alarmId,
    this.notifyBeforeExpiry = const Duration(hours: 1),
    this.isAvailable,
    this.lastAvailabilityCheck,
    this.monitoringMode = MonitoringMode.both,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'checkInterval': checkInterval.inSeconds,
      'lastChecked': lastChecked?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'alarmId': alarmId,
      'notifyBeforeExpiry': notifyBeforeExpiry.inSeconds,
      'isAvailable': isAvailable,
      'lastAvailabilityCheck': lastAvailabilityCheck?.toIso8601String(),
      'monitoringMode': monitoringMode.name,
    };
  }

  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      id: json['id'] as String,
      url: json['url'] as String,
      checkInterval: Duration(seconds: json['checkInterval'] as int),
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      alarmId: json['alarmId'] as int,
      notifyBeforeExpiry: json['notifyBeforeExpiry'] != null
          ? Duration(seconds: json['notifyBeforeExpiry'] as int)
          : const Duration(hours: 1),
      isAvailable: json['isAvailable'] as bool?,
      lastAvailabilityCheck: json['lastAvailabilityCheck'] != null
          ? DateTime.parse(json['lastAvailabilityCheck'] as String)
          : null,
      monitoringMode: json['monitoringMode'] != null
          ? MonitoringMode.values.firstWhere(
              (e) => e.name == json['monitoringMode'],
              orElse: () => MonitoringMode.both,
            )
          : MonitoringMode.both,
    );
  }

  Domain copyWith({
    String? id,
    String? url,
    Duration? checkInterval,
    DateTime? lastChecked,
    DateTime? expiryDate,
    int? alarmId,
    Duration? notifyBeforeExpiry,
    bool? isAvailable,
    DateTime? lastAvailabilityCheck,
    MonitoringMode? monitoringMode,
  }) {
    return Domain(
      id: id ?? this.id,
      url: url ?? this.url,
      checkInterval: checkInterval ?? this.checkInterval,
      lastChecked: lastChecked ?? this.lastChecked,
      expiryDate: expiryDate ?? this.expiryDate,
      alarmId: alarmId ?? this.alarmId,
      notifyBeforeExpiry: notifyBeforeExpiry ?? this.notifyBeforeExpiry,
      isAvailable: isAvailable ?? this.isAvailable,
      lastAvailabilityCheck: lastAvailabilityCheck ?? this.lastAvailabilityCheck,
      monitoringMode: monitoringMode ?? this.monitoringMode,
    );
  }
}
