import 'package:latlong2/latlong.dart';

class TaxiVehicle {
  final String id;

  final String plate;

  final String brand;

  final String model;

  final String color;

  final LatLng location;

  final bool available;

  const TaxiVehicle({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.color,
    required this.location,
    required this.available,
  });
}