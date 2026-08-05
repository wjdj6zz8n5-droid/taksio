import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

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
  double tripRemainingDistanceKm = 0;

  int arrivalMinutes = 0;
  int tripRemainingMinutes = 0;

  bool isSearching = false;
  bool driverAccepted = false;
  bool driverArrived = false;
  bool tripStarted = false;
  bool tripCompleted = false;

  StreamSubscription<LatLng>? _arrivalMovementSubscription;
  Timer? _tripMovementTimer;

  List<LatLng> _activeTripRoute = [];
  List<double> _remainingDistanceByPoint = [];

  int _currentTripPointIndex = 0;
  int _initialTripDurationMinutes = 0;

  Future<void> callTaxi({
    required List<TaxiVehicle> taxis,
    required LatLng pickupLocation,
  }) async {
    await cancelTaxi(notify: false);

    isSearching = true;
    driverAccepted = false;
    driverArrived = false;
    tripStarted = false;
    tripCompleted = false;

    arrivalMinutes = 0;
    remainingDistanceKm = 0;

    notifyListeners();

    await Future<void>.delayed(
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
    driverArrived = false;

    arrivalMinutes = _calculateArrivalMinutes(
      remainingDistanceKm,
    );

    notifyListeners();

    _startArrivalMovement(
      pickupLocation: pickupLocation,
    );
  }

  void _startArrivalMovement({
    required LatLng pickupLocation,
  }) {
    final start = movingTaxiLocation;

    if (start == null) {
      return;
    }

    _arrivalMovementSubscription?.cancel();

    _arrivalMovementSubscription = _simulationService
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
      onDone: () async {
        movingTaxiLocation = pickupLocation;
        remainingDistanceKm = 0;
        arrivalMinutes = 0;
        driverArrived = true;

        notifyListeners();

        final hasVibrator = await Vibration.hasVibrator();

        if (hasVibrator) {
          await Vibration.vibrate(
            pattern: [0, 250, 150, 250],
          );
        }
      },
      onError: (Object error) {
        isSearching = false;
        notifyListeners();
      },
    );
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

    _activeTripRoute = List<LatLng>.from(routePoints);
    _remainingDistanceByPoint =
        _calculateRemainingDistances(_activeTripRoute);

    _currentTripPointIndex = 0;
    _initialTripDurationMinutes = totalDurationMinutes;

    tripStarted = true;
    tripCompleted = false;

    tripRemainingDistanceKm = totalDistanceKm;
    tripRemainingMinutes = totalDurationMinutes;

    movingTaxiLocation = _activeTripRoute.first;

    notifyListeners();

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
            _activeTripRoute[_currentTripPointIndex];

        tripRemainingDistanceKm =
            _remainingDistanceByPoint[_currentTripPointIndex];

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
      movingTaxiLocation = _activeTripRoute.last;
    }

    tripRemainingDistanceKm = 0;
    tripRemainingMinutes = 0;

    tripStarted = false;
    tripCompleted = true;

    notifyListeners();

    final hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator) {
      await Vibration.vibrate(
        pattern: [0, 180, 100, 180, 100, 350],
      );
    }
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
    await _arrivalMovementSubscription?.cancel();
    _arrivalMovementSubscription = null;

    _tripMovementTimer?.cancel();
    _tripMovementTimer = null;

    await Vibration.cancel();

    currentDriver = null;
    currentTaxi = null;
    movingTaxiLocation = null;

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
    _arrivalMovementSubscription?.cancel();
    _tripMovementTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }
}