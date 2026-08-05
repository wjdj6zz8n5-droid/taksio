import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

import '../models/driver.dart';
import '../models/taxi_vehicle.dart';

class TaxiController extends ChangeNotifier {
  Driver? currentDriver;
  TaxiVehicle? currentTaxi;

  LatLng? movingTaxiLocation;
  LatLng? activePickupLocation;

  double remainingDistanceKm = 0;
  double tripRemainingDistanceKm = 0;

  int arrivalMinutes = 0;
  int tripRemainingMinutes = 0;

  bool isSearching = false;
  bool driverAccepted = false;
  bool driverArrived = false;
  bool tripStarted = false;
  bool tripCompleted = false;

  Timer? _tripMovementTimer;

  List<LatLng> _activeTripRoute = [];
  List<double> _remainingDistanceByPoint = [];

  int _currentTripPointIndex = 0;
  int _initialTripDurationMinutes = 0;

  void startSearching() {
    isSearching = true;
    driverAccepted = false;
    driverArrived = false;
    tripStarted = false;
    tripCompleted = false;

    currentDriver = null;
    currentTaxi = null;
    movingTaxiLocation = null;
    activePickupLocation = null;

    remainingDistanceKm = 0;
    arrivalMinutes = 0;

    notifyListeners();
  }

  void assignAcceptedDriver({
    required Driver driver,
    required TaxiVehicle vehicle,
    required LatLng pickupLocation,
  }) {
    currentDriver = driver;
    currentTaxi = vehicle;

    activePickupLocation = pickupLocation;
    movingTaxiLocation = vehicle.location;

    remainingDistanceKm = const Distance().as(
      LengthUnit.Kilometer,
      vehicle.location,
      pickupLocation,
    );

    arrivalMinutes = _calculateArrivalMinutes(
      remainingDistanceKm,
    );

    isSearching = false;
    driverAccepted = true;
    driverArrived = false;
    tripStarted = false;
    tripCompleted = false;

    notifyListeners();
  }

  void updateDriverLocation(
    LatLng newLocation,
  ) {
    movingTaxiLocation = newLocation;

    final pickup = activePickupLocation;

    if (pickup != null && !driverArrived) {
      remainingDistanceKm = const Distance().as(
        LengthUnit.Kilometer,
        newLocation,
        pickup,
      );

      arrivalMinutes = _calculateArrivalMinutes(
        remainingDistanceKm,
      );

      if (remainingDistanceKm <= 0.05) {
        markDriverArrived();
        return;
      }
    }

    notifyListeners();
  }

  Future<void> markDriverArrived() async {
    final pickup = activePickupLocation;

    if (pickup != null) {
      movingTaxiLocation = pickup;
    }

    remainingDistanceKm = 0;
    arrivalMinutes = 0;

    isSearching = false;
    driverAccepted = true;
    driverArrived = true;

    notifyListeners();

    final hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator) {
      await Vibration.vibrate(
        pattern: [0, 250, 150, 250],
      );
    }
  }

  void startTrip({
    required List<LatLng> routePoints,
    required double totalDistanceKm,
    required int totalDurationMinutes,
  }) {
    if (!driverArrived ||
        currentTaxi == null ||
        routePoints.length < 2) {
      return;
    }

    _tripMovementTimer?.cancel();

    _activeTripRoute =
        List<LatLng>.from(routePoints);

    _remainingDistanceByPoint =
        _calculateRemainingDistances(
      _activeTripRoute,
    );

    _currentTripPointIndex = 0;
    _initialTripDurationMinutes =
        totalDurationMinutes;

    tripStarted = true;
    tripCompleted = false;

    tripRemainingDistanceKm =
        totalDistanceKm;

    tripRemainingMinutes =
        totalDurationMinutes;

    movingTaxiLocation =
        _activeTripRoute.first;

    notifyListeners();

    // Yolculuk kısmındaki hareket şimdilik demo olarak kalıyor.
    // Şoförün gerçek konum paylaşımını bağladığımızda bu timer kalkacak.
    _tripMovementTimer = Timer.periodic(
      const Duration(milliseconds: 650),
      (timer) {
        _currentTripPointIndex++;

        if (_currentTripPointIndex >=
            _activeTripRoute.length) {
          timer.cancel();
          _completeTrip();
          return;
        }

        movingTaxiLocation =
            _activeTripRoute[
                _currentTripPointIndex];

        tripRemainingDistanceKm =
            _remainingDistanceByPoint[
                _currentTripPointIndex];

        final completedRatio =
            _currentTripPointIndex /
                (_activeTripRoute.length - 1);

        tripRemainingMinutes =
            (_initialTripDurationMinutes *
                    (1 - completedRatio))
                .ceil();

        notifyListeners();
      },
    );
  }

  List<double> _calculateRemainingDistances(
    List<LatLng> points,
  ) {
    final remaining = List<double>.filled(
      points.length,
      0,
    );

    double accumulatedKm = 0;

    for (int index = points.length - 2;
        index >= 0;
        index--) {
      accumulatedKm += const Distance().as(
        LengthUnit.Kilometer,
        points[index],
        points[index + 1],
      );

      remaining[index] = accumulatedKm;
    }

    return remaining;
  }

  Future<void> _completeTrip() async {
    if (_activeTripRoute.isNotEmpty) {
      movingTaxiLocation =
          _activeTripRoute.last;
    }

    tripRemainingDistanceKm = 0;
    tripRemainingMinutes = 0;

    tripStarted = false;
    tripCompleted = true;

    notifyListeners();

    final hasVibrator =
        await Vibration.hasVibrator();

    if (hasVibrator) {
      await Vibration.vibrate(
        pattern: [
          0,
          180,
          100,
          180,
          100,
          350,
        ],
      );
    }
  }

  int _calculateArrivalMinutes(
    double distanceKm,
  ) {
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
    _tripMovementTimer?.cancel();
    _tripMovementTimer = null;

    await Vibration.cancel();

    currentDriver = null;
    currentTaxi = null;

    movingTaxiLocation = null;
    activePickupLocation = null;

    remainingDistanceKm = 0;
    tripRemainingDistanceKm = 0;

    arrivalMinutes = 0;
    tripRemainingMinutes = 0;

    isSearching = false;
    driverAccepted = false;
    driverArrived = false;
    tripStarted = false;
    tripCompleted = false;

    _activeTripRoute = [];
    _remainingDistanceByPoint = [];

    _currentTripPointIndex = 0;
    _initialTripDurationMinutes = 0;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tripMovementTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }
}