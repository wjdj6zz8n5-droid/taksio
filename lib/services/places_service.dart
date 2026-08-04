import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

class PlaceSelection {
  final String address;
  final LatLng location;

  const PlaceSelection({
    required this.address,
    required this.location,
  });
}

class PlacesServiceException implements Exception {
  final int statusCode;
  final String message;

  const PlacesServiceException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'PlacesServiceException($statusCode): $message';
  }
}

class PlacesService {
  static const String apiKey = 'AIzaSyAkV68vqqxfzcdYc1CWi6dBgWdU4kEFBYE';

  static const String _autocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';

  static Future<List<PlaceSuggestion>> autocomplete(
    String input,
  ) async {
    final cleanedInput = input.trim();

    if (cleanedInput.length < 2) {
      return [];
    }

    final response = await http.post(
      Uri.parse(_autocompleteUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,'
            'suggestions.placePrediction.text.text',
      },
      body: jsonEncode({
        'input': cleanedInput,
        'languageCode': 'tr',
        'regionCode': 'tr',
        'includedRegionCodes': ['tr'],
        'locationBias': {
          'circle': {
            'center': {
              'latitude': 41.2862,
              'longitude': 27.9994,
            },
            'radius': 50000.0,
          },
        },
      }),
    );

    debugPrint(
      'PLACES AUTOCOMPLETE STATUS: ${response.statusCode}',
    );
    debugPrint(
      'PLACES AUTOCOMPLETE BODY: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw PlacesServiceException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const PlacesServiceException(
        statusCode: 500,
        message: 'Google Places geçersiz yanıt döndürdü.',
      );
    }

    final rawSuggestions =
        decoded['suggestions'] as List<dynamic>? ?? [];

    return rawSuggestions
        .map((item) {
          if (item is! Map<String, dynamic>) {
            return null;
          }

          final prediction =
              item['placePrediction'] as Map<String, dynamic>?;

          if (prediction == null) {
            return null;
          }

          final placeId = prediction['placeId'] as String?;
          final text =
              prediction['text'] as Map<String, dynamic>?;
          final description = text?['text'] as String?;

          if (placeId == null ||
              placeId.isEmpty ||
              description == null ||
              description.isEmpty) {
            return null;
          }

          return PlaceSuggestion(
            placeId: placeId,
            description: description,
          );
        })
        .whereType<PlaceSuggestion>()
        .toList();
  }

  static Future<PlaceSelection?> getPlaceDetails(
    PlaceSuggestion suggestion,
  ) async {
    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places/${suggestion.placeId}',
      {
        'languageCode': 'tr',
        'regionCode': 'tr',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'formattedAddress,location',
      },
    );

    debugPrint(
      'PLACE DETAILS STATUS: ${response.statusCode}',
    );
    debugPrint(
      'PLACE DETAILS BODY: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw PlacesServiceException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const PlacesServiceException(
        statusCode: 500,
        message: 'Konum bilgisi geçersiz biçimde döndü.',
      );
    }

    final location =
        decoded['location'] as Map<String, dynamic>?;

    if (location == null) {
      return null;
    }

    final latitude =
        (location['latitude'] as num?)?.toDouble();
    final longitude =
        (location['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      return null;
    }

    return PlaceSelection(
      address:
          decoded['formattedAddress'] as String? ??
          suggestion.description,
      location: LatLng(
        latitude,
        longitude,
      ),
    );
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final error =
            decoded['error'] as Map<String, dynamic>?;

        final message = error?['message'] as String?;

        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // JSON değilse ham yanıt kullanılacak.
    }

    return body.isEmpty
        ? 'Google Places isteği başarısız oldu.'
        : body;
  }
}