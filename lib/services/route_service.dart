import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  static const String apiKey = "AIzaSyAkV68vqqxfzcdYc1CWi6dBgWdU4kEFBYE";

  static Future<RouteResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json"
      "?origin=${origin.latitude},${origin.longitude}"
      "&destination=${destination.latitude},${destination.longitude}"
      "&mode=driving"
      "&key=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    print("ROUTE RESPONSE: $data");
    
    print(data);

    if (data["status"] != "OK") {
      return null;
    }

    final route = data["routes"][0];
    final leg = route["legs"][0];

    final encodedPolyline = route["overview_polyline"]["points"];
    final distanceMeters = leg["distance"]["value"];
    final durationSeconds = leg["duration"]["value"];

    return RouteResult(
      points: _decodePolyline(encodedPolyline),
      distanceKm: distanceMeters / 1000.0,
      durationMinutes: (durationSeconds / 60).ceil(),
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(
        LatLng(
          lat / 100000.0,
          lng / 100000.0,
        ),
      );
    }

    return poly;
  }
}