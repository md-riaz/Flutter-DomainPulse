class Domain {
  final String id;
  final String url;
  final Duration checkInterval;
  final DateTime? lastChecked;
  final DateTime? expiryDate;
  final int alarmId;

  Domain({
    required this.id,
    required this.url,
    required this.checkInterval,
    this.lastChecked,
    this.expiryDate,
    required this.alarmId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'checkInterval': checkInterval.inSeconds,
      'lastChecked': lastChecked?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'alarmId': alarmId,
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
    );
  }

  Domain copyWith({
    String? id,
    String? url,
    Duration? checkInterval,
    DateTime? lastChecked,
    DateTime? expiryDate,
    int? alarmId,
  }) {
    return Domain(
      id: id ?? this.id,
      url: url ?? this.url,
      checkInterval: checkInterval ?? this.checkInterval,
      lastChecked: lastChecked ?? this.lastChecked,
      expiryDate: expiryDate ?? this.expiryDate,
      alarmId: alarmId ?? this.alarmId,
    );
  }
}
