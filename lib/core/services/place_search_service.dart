import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class PlaceSearchSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;

  const PlaceSearchSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });
}

class PlaceSearchSelection {
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  const PlaceSearchSelection({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class PlaceSearchService {
  PlaceSearchService._();

  static final PlaceSearchService instance = PlaceSearchService._();

  static const String _apiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  String? _sessionToken;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  void beginSession() {
    _sessionToken =
        'sl-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
  }

  Future<List<PlaceSearchSuggestion>> autocomplete(String query) async {
    final trimmed = query.trim();
    if (!isConfigured || trimmed.length < 2) {
      return const <PlaceSearchSuggestion>[];
    }

    final token = _sessionToken ??= 
        'sl-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

    final response = await http.post(
      Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,'
            'suggestions.placePrediction.text.text,'
            'suggestions.placePrediction.structuredFormat.mainText.text,'
            'suggestions.placePrediction.structuredFormat.secondaryText.text',
      },
      body: jsonEncode(
        <String, dynamic>{
          'input': trimmed,
          'sessionToken': token,
          'regionCode': 'us',
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Place search failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions =
        (decoded['suggestions'] as List?) ?? const <dynamic>[];

    return suggestions
        .map((raw) => raw as Map<String, dynamic>)
        .map((item) => item['placePrediction'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((prediction) {
      final structured =
          prediction['structuredFormat'] as Map<String, dynamic>?;
      final mainText =
          (structured?['mainText'] as Map<String, dynamic>?)?['text']
                  ?.toString() ??
              (prediction['text'] as Map<String, dynamic>?)?['text']
                  ?.toString() ??
              'Unnamed place';
      final secondaryText =
          (structured?['secondaryText'] as Map<String, dynamic>?)?['text']
                  ?.toString() ??
              '';

      return PlaceSearchSuggestion(
        placeId: prediction['placeId']?.toString() ?? '',
        primaryText: mainText,
        secondaryText: secondaryText,
      );
    }).where((item) => item.placeId.isNotEmpty).toList(growable: false);
  }

  Future<PlaceSearchSelection> fetchPlaceSelection(String placeId) async {
    if (!isConfigured) {
      throw Exception('Places search is not configured.');
    }

    final token = _sessionToken;
    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places/$placeId',
      token == null ? null : <String, String>{'sessionToken': token},
    );

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Place details failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final displayName =
        (decoded['displayName'] as Map<String, dynamic>?)?['text']
                ?.toString() ??
            'Selected place';
    final formattedAddress =
        decoded['formattedAddress']?.toString() ?? '';
    final location = decoded['location'] as Map<String, dynamic>?;

    final latitude = (location?['latitude'] as num?)?.toDouble();
    final longitude = (location?['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw Exception('Selected place did not return coordinates.');
    }

    _sessionToken = null;

    return PlaceSearchSelection(
      label: displayName,
      address: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
