class RiskyPlace {
  final String id;
  final String label;
  final String note;
  final bool isTopRisk;
  final int radiusMeters;

  const RiskyPlace({
    required this.id,
    required this.label,
    required this.note,
    required this.isTopRisk,
    required this.radiusMeters,
  });

  RiskyPlace copyWith({
    String? id,
    String? label,
    String? note,
    bool? isTopRisk,
    int? radiusMeters,
  }) {
    return RiskyPlace(
      id: id ?? this.id,
      label: label ?? this.label,
      note: note ?? this.note,
      isTopRisk: isTopRisk ?? this.isTopRisk,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'note': note,
      'isTopRisk': isTopRisk,
      'radiusMeters': radiusMeters,
    };
  }

  factory RiskyPlace.fromJson(Map<String, dynamic> json) {
    return RiskyPlace(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      isTopRisk: json['isTopRisk'] == true,
      radiusMeters: (json['radiusMeters'] as num?)?.toInt() ?? 300,
    );
  }
}
