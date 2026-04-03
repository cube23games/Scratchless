class DistanceFormatterService {
  static String usPlaceRadiusLabel(int meters) {
    final feet = meters * 3.28084;

    if (feet < 1000) {
      final roundedFeet = ((feet / 50).round() * 50).clamp(50, 950);
      return '${roundedFeet.toInt()} ft';
    }

    final miles = meters / 1609.344;
    if (miles < 10) {
      return '${miles.toStringAsFixed(1)} mi';
    }

    return '${miles.toStringAsFixed(0)} mi';
  }
}
