class RiskyPlace {
  final String id;
  final String label;
  final String note;
  final bool isTopRisk;
  final int radiusMeters;
  final bool locationAlertsEnabled;

  const RiskyPlace({
    required this.id,
    required this.label,
    required this.note,
    required this.isTopRisk,
    required this.radiusMeters,
    this.locationAlertsEnabled = false,
  });

  RiskyPlace copyWith({
    String? id,
    String? label,
    String? note,
    bool? isTopRisk,
    int? radiusMeters,
    bool? locationAlertsEnabled,
  }) {
    return RiskyPlace(
      id: id ?? this.id,
      label: label ?? this.label,
      note: note ?? this.note,
      isTopRisk: isTopRisk ?? this.isTopRisk,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      locationAlertsEnabled:
          locationAlertsEnabled ?? this.locationAlertsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'note': note,
      'isTopRisk': isTopRisk,
      'radiusMeters': radiusMeters,
      'locationAlertsEnabled': locationAlertsEnabled,
    };
  }

  factory RiskyPlace.fromJson(Map<String, dynamic> json) {
    return RiskyPlace(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      isTopRisk: json['isTopRisk'] == true,
      radiusMeters: (json['radiusMeters'] as num?)?.toInt() ?? 300,
      locationAlertsEnabled: json['locationAlertsEnabled'] == true,
    );
  }
}
