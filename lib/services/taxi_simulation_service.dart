import 'dart:async';
import 'package:latlong2/latlong.dart';

import '../models/taxi_vehicle.dart';

class TaxiSimulationService {
  final Distance _distance = const Distance();

  TaxiVehicle? findNearestTaxi({
    required List<TaxiVehicle> taxis,
    required LatLng pickup,
  }) {
    if (taxis.isEmpty) return null;

    TaxiVehicle nearest = taxis.first;
    double nearestDistance = double.infinity;

    for (final taxi in taxis) {
      if (!taxi.available) continue;

      final d = _distance.as(
        LengthUnit.Meter,
        taxi.location,
        pickup,
      );

      if (d < nearestDistance) {
        nearestDistance = d;
        nearest = taxi;
      }
    }

    return nearest;
  }

  Stream<LatLng> simulateTaxiMovement({
    required LatLng start,
    required LatLng destination,
    Duration interval = const Duration(milliseconds: 800),
    int steps = 40,
  }) {
    final controller = StreamController<LatLng>();

    double latStep =
        (destination.latitude - start.latitude) / steps;

    double lngStep =
        (destination.longitude - start.longitude) / steps;

    int currentStep = 0;

    Timer.periodic(interval, (timer) {
      currentStep++;

      controller.add(
        LatLng(
          start.latitude + (latStep * currentStep),
          start.longitude + (lngStep * currentStep),
        ),
      );

      if (currentStep >= steps) {
        timer.cancel();
        controller.close();
      }
    });

    return controller.stream;
  }
}