class RiskyPlace {
  final String id;
  final String label;
  final String note;
  final bool isTopRisk;
  final int radiusMeters;
  final bool locationAlertsEnabled;
  final double? latitude;
  final double? longitude;
  final String locationSource;

  const RiskyPlace({
    required this.id,
    required this.label,
    required this.note,
    required this.isTopRisk,
    required this.radiusMeters,
    this.locationAlertsEnabled = false,
    this.latitude,
    this.longitude,
    this.locationSource = 'manual',
  });

  RiskyPlace copyWith({
    String? id,
    String? label,
    String? note,
    bool? isTopRisk,
    int? radiusMeters,
    bool? locationAlertsEnabled,
    double? latitude,
    double? longitude,
    String? locationSource,
  }) {
    return RiskyPlace(
      id: id ?? this.id,
      label: label ?? this.label,
      note: note ?? this.note,
      isTopRisk: isTopRisk ?? this.isTopRisk,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      locationAlertsEnabled:
          locationAlertsEnabled ?? this.locationAlertsEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationSource: locationSource ?? this.locationSource,
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
      'latitude': latitude,
      'longitude': longitude,
      'locationSource': locationSource,
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationSource: json['locationSource']?.toString() ?? 'manual',
    );
  }
}
