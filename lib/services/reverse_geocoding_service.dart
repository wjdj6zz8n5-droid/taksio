import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ReverseGeocodingService {
  const ReverseGeocodingService._();

  static Future<String> getAddress(
    LatLng location,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'tr',
      },
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'TAKSIO-Flutter-Development/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        return _coordinateFallback(location);
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final address =
          data['address'] as Map<String, dynamic>?;

      if (address == null) {
        return data['display_name'] as String? ??
            _coordinateFallback(location);
      }

      final road = _firstNonEmpty([
        address['road'],
        address['pedestrian'],
        address['residential'],
        address['neighbourhood'],
      ]);

      final district = _firstNonEmpty([
        address['suburb'],
        address['quarter'],
        address['town'],
        address['city_district'],
      ]);

      final city = _firstNonEmpty([
        address['city'],
        address['town'],
        address['county'],
        address['province'],
      ]);

      final parts = <String>[
        if (road != null) road,
        if (district != null && district != road) district,
        if (city != null &&
            city != district &&
            city != road)
          city,
      ];

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }

      return data['display_name'] as String? ??
          _coordinateFallback(location);
    } catch (_) {
      return _coordinateFallback(location);
    }
  }

  static String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static String _coordinateFallback(
    LatLng location,
  ) {
    return '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }
}
