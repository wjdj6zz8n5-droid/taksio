import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver.dart';
import '../models/taxi_vehicle.dart';
import '../services/taxi_simulation_service.dart';

class TaxiController extends ChangeNotifier {
  final TaxiSimulationService _simulationService =
      TaxiSimulationService();

  Driver? currentDriver;
  TaxiVehicle? currentTaxi;

  LatLng? movingTaxiLocation;

  double remainingDistanceKm = 0;

  bool isSearching = false;
  bool driverAccepted = false;
  bool driverArrived = false;

  int arrivalMinutes = 0;

  StreamSubscription<LatLng>? _movementSubscription;

  Future<void> callTaxi({
    required List<TaxiVehicle> taxis,
    required LatLng pickupLocation,
  }) async {
    await cancelTaxi(notify: false);

    isSearching = true;
    driverAccepted = false;
    driverArrived = false;
    arrivalMinutes = 0;
    remainingDistanceKm = 0;

    notifyListeners();

    await Future.delayed(
      const Duration(seconds: 3),
    );

    currentTaxi = _simulationService.findNearestTaxi(
      taxis: taxis,
      pickup: pickupLocation,
    );

    if (currentTaxi == null) {
      isSearching = false;
      notifyListeners();
      return;
    }

    currentDriver = const Driver(
      id: 'driver_1',
      firstName: 'Mehmet',
      lastName: 'Sağlam',
      phone: '05550000000',
      photoUrl: '',
      rating: 4.9,
      tripCount: 2847,
      isOnline: true,
    );

    movingTaxiLocation = currentTaxi!.location;

    remainingDistanceKm = const Distance().as(
      LengthUnit.Kilometer,
      movingTaxiLocation!,
      pickupLocation,
    );

    isSearching = false;
    driverAccepted = true;

    arrivalMinutes = _calculateArrivalMinutes(
      remainingDistanceKm,
    );

    notifyListeners();

    _startTaxiMovement(
      pickupLocation: pickupLocation,
    );
  }

  void _startTaxiMovement({
    required LatLng pickupLocation,
  }) {
    final start = movingTaxiLocation;

    if (start == null) return;

    _movementSubscription?.cancel();

    _movementSubscription = _simulationService
        .simulateTaxiMovement(
          start: start,
          destination: pickupLocation,
          interval: const Duration(milliseconds: 700),
          steps: 35,
        )
        .listen(
      (location) {
        movingTaxiLocation = location;

        final remainingMeters = const Distance().as(
          LengthUnit.Meter,
          location,
          pickupLocation,
        );

        remainingDistanceKm = remainingMeters / 1000;

        arrivalMinutes = _calculateArrivalMinutes(
          remainingDistanceKm,
        );

        notifyListeners();
      },
      onDone: () {
        movingTaxiLocation = pickupLocation;
        remainingDistanceKm = 0;
        arrivalMinutes = 0;
        driverArrived = true;

        notifyListeners();
      },
      onError: (_) {
        isSearching = false;
        notifyListeners();
      },
    );
  }

  int _calculateArrivalMinutes(double distanceKm) {
    if (distanceKm <= 0.05) {
      return 0;
    }

    if (distanceKm <= 0.5) {
      return 1;
    }

    if (distanceKm <= 1.5) {
      return 2;
    }

    return (distanceKm * 2).ceil();
  }

  Future<void> cancelTaxi({
    bool notify = true,
  }) async {
    await _movementSubscription?.cancel();
    _movementSubscription = null;

    currentDriver = null;
    currentTaxi = null;
    movingTaxiLocation = null;

    remainingDistanceKm = 0;

    isSearching = false;
    driverAccepted = false;
    driverArrived = false;

    arrivalMinutes = 0;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _movementSubscription?.cancel();
    super.dispose();
  }
}