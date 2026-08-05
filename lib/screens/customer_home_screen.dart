import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../controllers/ride_request_controller.dart';
import '../controllers/taxi_controller.dart';
import '../models/driver.dart';
import '../models/taxi_vehicle.dart';
import '../repositories/driver_location_repository.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/route_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/driver_arrival_card.dart';
import '../widgets/map_widget.dart';
import '../widgets/searching_taxi_sheet.dart';
import '../widgets/trip_completed_sheet.dart';
import '../widgets/trip_started_sheet.dart';
import 'destination_search_screen.dart';
import 'map_picker_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState
    extends State<CustomerHomeScreen> {
  static const String demoCustomerId =
      'customer_demo_1';

  RideRequestController? rideRequestController;
  final DriverLocationRepository driverLocationRepository =
      DriverLocationRepository();
  StreamSubscription<LatLng?>? driverLocationSubscription;

  bool acceptedRequestHandled = false;
  bool driverArrivedHandled = false;

  LatLng? currentLocation;
  LatLng? pickupLocation;
  LatLng? destinationLocation;

  String? pickupAddress;
  String? destinationAddress;

  double? distanceKm;
  int? durationMinutes;
  int? estimatedPrice;

  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextController =
        context.read<RideRequestController>();

    if (rideRequestController == nextController) {
      return;
    }

    rideRequestController?.removeListener(
      handleRideRequestChange,
    );

    rideRequestController = nextController;

    rideRequestController?.addListener(
      handleRideRequestChange,
    );
  }

  @override
  void dispose() {
    rideRequestController?.removeListener(
      handleRideRequestChange,
    );
    driverLocationSubscription?.cancel();

    super.dispose();
  }

  void handleRideRequestChange() {
    final request =
        rideRequestController?.currentRequest;

    if (request == null) {
      acceptedRequestHandled = false;
      driverArrivedHandled = false;
      driverLocationSubscription?.cancel();
      driverLocationSubscription = null;
      return;
    }

    if (request.status == 'accepted' &&
        !acceptedRequestHandled) {
      acceptedRequestHandled = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          if (!mounted) return;

          final pickup = pickupLocation;

          if (pickup == null) {
            _showMessage(
              'Şoför kabul etti ancak alınacak konum bulunamadı.',
              isError: true,
            );
            return;
          }

          final acceptedVehicleId =
              request.acceptedVehicleId;
          final acceptedDriverId =
              request.acceptedDriverId;

          if (acceptedVehicleId == null ||
              acceptedDriverId == null) {
            _showMessage(
              'Şoför veya araç bilgisi eksik.',
              isError: true,
            );
            return;
          }

          final vehicles =
              getNearbyTaxiVehicles(pickup);

          final vehicle = vehicles.firstWhere(
            (item) => item.id == acceptedVehicleId,
            orElse: () => vehicles.first,
          );

          final driver = Driver(
            id: acceptedDriverId,
            firstName: 'Mehmet',
            lastName: 'Sağlam',
            phone: '05550000000',
            photoUrl: '',
            rating: 4.9,
            tripCount: 2847,
            isOnline: true,
          );

          if (!mounted) return;

          context
              .read<TaxiController>()
              .assignAcceptedDriver(
                driver: driver,
                vehicle: vehicle,
                pickupLocation: pickup,
              );

          _startWatchingDriverLocation(
            driverId: acceptedDriverId,
          );
        },
      );

      return;
    }

    if (request.status == 'driver_arrived' &&
        !driverArrivedHandled) {
      driverArrivedHandled = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          if (!mounted) return;

          await context
              .read<TaxiController>()
              .markDriverArrived();

          if (!mounted) return;

          final hasVibrator =
              await Vibration.hasVibrator();

          if (hasVibrator) {
            await Vibration.vibrate(
              pattern: [
                0,
                250,
                150,
                250,
                150,
                500,
              ],
            );
          }

          if (!mounted) return;

          await showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor:
                    const Color(0xFF171717),
                icon: const Icon(
                  Icons.local_taxi,
                  color: AppColors.yellow,
                  size: 48,
                ),
                title: const Text(
                  'Şoförünüz Geldi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: const Text(
                  'Şoförünüz alınacak konumda sizi bekliyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      return;
    }

    if (request.status == 'trip_started') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;

          final distance = distanceKm;
          final duration = durationMinutes;

          if (routePoints.length < 2 ||
              distance == null ||
              duration == null) {
            _showMessage(
              'Yolculuk rotası hazır değil.',
              isError: true,
            );
            return;
          }

          final taxiController =
              context.read<TaxiController>();

          if (taxiController.tripStarted) {
            return;
          }

          taxiController.startTrip(
            routePoints: routePoints,
            totalDistanceKm: distance,
            totalDurationMinutes: duration,
          );

          _showMessage(
            'Yolculuğunuz başladı.',
          );
        },
      );

      return;
    }

    if (request.status == 'trip_completed') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;

          _showMessage(
            'Yolculuk tamamlandı.',
          );
        },
      );
    }
  }

  void _startWatchingDriverLocation({
    required String driverId,
  }) {
    driverLocationSubscription?.cancel();

    driverLocationSubscription =
        driverLocationRepository
            .watchDriverLocation(driverId)
            .listen(
      (location) {
        if (!mounted || location == null) {
          return;
        }

        context
            .read<TaxiController>()
            .updateDriverLocation(location);
      },
      onError: (Object error) {
        if (!mounted) return;

        _showMessage(
          'Şoförün canlı konumu alınamadı: $error',
          isError: true,
        );
      },
    );
  }

  Future<void> _stopWatchingDriverLocation() async {
    await driverLocationSubscription?.cancel();
    driverLocationSubscription = null;
  }

  Future<void> loadLocation() async {
    final location =
        await LocationService.getCurrentLocation();

    if (!mounted) return;

    final resolvedAddress = location == null
        ? 'Konum alınamadı'
        : await ReverseGeocodingService.getAddress(
            location,
          );

    if (!mounted) return;

    setState(() {
      currentLocation = location;
      pickupLocation ??= location;
      pickupAddress ??= resolvedAddress;
    });
  }

  List<TaxiVehicle> getNearbyTaxiVehicles(
    LatLng center,
  ) {
    return [
      TaxiVehicle(
        id: 'vehicle_1',
        plate: '59 ABC 47',
        brand: 'Toyota',
        model: 'Corolla',
        color: 'Sarı',
        location: LatLng(
          center.latitude + 0.0020,
          center.longitude + 0.0015,
        ),
        available: true,
      ),
      TaxiVehicle(
        id: 'vehicle_2',
        plate: '59 T 1024',
        brand: 'Renault',
        model: 'Megane',
        color: 'Sarı',
        location: LatLng(
          center.latitude - 0.0018,
          center.longitude + 0.0022,
        ),
        available: true,
      ),
      TaxiVehicle(
        id: 'vehicle_3',
        plate: '59 T 2047',
        brand: 'Fiat',
        model: 'Egea',
        color: 'Sarı',
        location: LatLng(
          center.latitude + 0.0012,
          center.longitude - 0.0020,
        ),
        available: true,
      ),
    ];
  }

  Future<void> calculateTripInfo(
    LatLng destination, {
    String? address,
  }) async {
    final start = pickupLocation ??
        currentLocation ??
        const LatLng(41.2862, 27.9994);

    final result = await RouteService.getRoute(
      origin: start,
      destination: destination,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        destinationLocation = destination;
        destinationAddress = address ??
            destinationAddress ??
            'Haritadan seçilen konum';
        routePoints = [];
        distanceKm = null;
        durationMinutes = null;
        estimatedPrice = null;
      });

      _showMessage(
        'Rota hesaplanamadı. Lütfen tekrar deneyin.',
        isError: true,
      );
      return;
    }

    setState(() {
      destinationLocation = destination;
      destinationAddress = address ??
          destinationAddress ??
          'Haritadan seçilen konum';
      routePoints = result.points;
      distanceKm = result.distanceKm;
      durationMinutes = result.durationMinutes;
      estimatedPrice =
          (175 + (result.distanceKm * 25)).ceil();
    });
  }

  Future<void> recalculateRouteIfNeeded() async {
    final destination = destinationLocation;

    if (destination == null) return;

    await calculateTripInfo(
      destination,
      address: destinationAddress,
    );
  }

  Future<void> openPickupOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: AppColors.yellow,
                  ),
                  title: const Text(
                    'Mevcut konumumu kullan',
                    style:
                        TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    if (currentLocation == null) {
                      await loadLocation();
                    }

                    if (!mounted) return;

                    final location = currentLocation;

                    if (location == null) {
                      _showMessage(
                        'Mevcut konum alınamadı.',
                        isError: true,
                      );
                      return;
                    }

                    await _cancelActiveTaxiFlow();

                    if (!mounted) return;

                    final address =
                        await ReverseGeocodingService
                            .getAddress(location);

                    if (!mounted) return;

                    setState(() {
                      pickupLocation = location;
                      pickupAddress = address;
                    });

                    await recalculateRouteIfNeeded();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.map,
                    color: AppColors.yellow,
                  ),
                  title: const Text(
                    'Haritadan alınacak konum seç',
                    style:
                        TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selectedLocation =
                        await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MapPickerScreen(
                          initialLocation:
                              pickupLocation ??
                                  currentLocation ??
                                  const LatLng(
                                    41.2862,
                                    27.9994,
                                  ),
                        ),
                      ),
                    );

                    if (!mounted ||
                        selectedLocation == null) {
                      return;
                    }

                    await _cancelActiveTaxiFlow();

                    final address =
                        await ReverseGeocodingService
                            .getAddress(
                      selectedLocation,
                    );

                    if (!mounted) return;

                    setState(() {
                      pickupLocation =
                          selectedLocation;
                      pickupAddress = address;
                    });

                    await recalculateRouteIfNeeded();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> openDestinationOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.search,
                    color: AppColors.yellow,
                  ),
                  title: const Text(
                    'Adres Ara',
                    style:
                        TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selection = await Navigator
                        .push<PlaceSelection>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const DestinationSearchScreen(),
                      ),
                    );

                    if (!mounted ||
                        selection == null) {
                      return;
                    }

                    await _cancelActiveTaxiFlow();

                    if (!mounted) return;

                    await calculateTripInfo(
                      selection.location,
                      address: selection.address,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.map,
                    color: AppColors.yellow,
                  ),
                  title: const Text(
                    'Haritadan konum seç',
                    style:
                        TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selectedLocation =
                        await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MapPickerScreen(
                          initialLocation:
                              destinationLocation ??
                                  pickupLocation ??
                                  currentLocation ??
                                  const LatLng(
                                    41.2862,
                                    27.9994,
                                  ),
                        ),
                      ),
                    );

                    if (!mounted ||
                        selectedLocation == null) {
                      return;
                    }

                    await _cancelActiveTaxiFlow();

                    final address =
                        await ReverseGeocodingService
                            .getAddress(
                      selectedLocation,
                    );

                    if (!mounted) return;

                    await calculateTripInfo(
                      selectedLocation,
                      address: address,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> callTaxi() async {
    final pickup = pickupLocation;
    final destination = destinationLocation;
    final tripDistance = distanceKm;
    final tripDuration = durationMinutes;
    final tripPrice = estimatedPrice;

    if (pickup == null) {
      _showMessage(
        'Önce alınacak konumu seçin.',
      );
      return;
    }

    if (destination == null) {
      _showMessage(
        'Önce gidilecek konumu seçin.',
      );
      return;
    }

    if (tripDistance == null ||
        tripDuration == null ||
        tripPrice == null) {
      _showMessage(
        'Rota bilgileri henüz hazır değil.',
      );
      return;
    }

    acceptedRequestHandled = false;
    driverArrivedHandled = false;

    final requestController =
        context.read<RideRequestController>();

    final requestCreated =
        await requestController.createRequest(
      customerId: demoCustomerId,
      pickupLocation: pickup,
      pickupAddress:
          pickupAddress ?? 'Alınacak konum',
      destinationLocation: destination,
      destinationAddress:
          destinationAddress ?? 'Gidilecek konum',
      distanceKm: tripDistance,
      durationMinutes: tripDuration,
      estimatedPrice: tripPrice,
    );

    if (!mounted) return;

    if (!requestCreated) {
      _showMessage(
        requestController.errorMessage ??
            'Taksi çağrısı oluşturulamadı.',
        isError: true,
      );
      return;
    }

    _showMessage(
      'Taksi çağrınız oluşturuldu. Şoför bekleniyor.',
    );
  }

  Future<void> _cancelActiveTaxiFlow() async {
    await _stopWatchingDriverLocation();
    await context
        .read<RideRequestController>()
        .cancelCurrentRequest();

    await context
        .read<TaxiController>()
        .cancelTaxi();

    acceptedRequestHandled = false;
    driverArrivedHandled = false;
  }

  void callDriver() {
    final phone = context
        .read<TaxiController>()
        .currentDriver
        ?.phone;

    _showMessage(
      phone == null
          ? 'Şoför telefon bilgisi bulunamadı.'
          : 'Şoför aranıyor: $phone',
    );
  }

  void messageDriver() {
    _showMessage(
      'Mesajlaşma özelliği yakında eklenecek.',
    );
  }

  void shareTrip() {
    final controller =
        context.read<TaxiController>();

    final driverName =
        controller.currentDriver?.shortName ??
            'Şoför';

    final plate =
        controller.currentTaxi?.plate ??
            'Plaka bilinmiyor';

    _showMessage(
      'Yolculuk paylaşımı hazırlandı: '
      '$driverName • $plate',
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.redAccent : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taxiController =
        context.watch<TaxiController>();

    final requestController =
        context.watch<RideRequestController>();

    final mapCenter = pickupLocation ??
        currentLocation ??
        const LatLng(41.2862, 27.9994);

    final taxiVehicles =
        getNearbyTaxiVehicles(mapCenter);

    final mapTaxiLocations = taxiVehicles
        .where(
          (taxi) =>
              taxi.id !=
              taxiController.currentTaxi?.id,
        )
        .map((taxi) => taxi.location)
        .toList();

    final movingTaxi =
        taxiController.movingTaxiLocation;

    if (movingTaxi != null) {
      mapTaxiLocations.add(movingTaxi);
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          MapWidget(
            center: mapCenter,
            currentLocation: mapCenter,
            destinationLocation:
                destinationLocation,
            taxis: mapTaxiLocations,
            routePoints: routePoints,
          ),
          Positioned(
            top: 58,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(Icons.menu),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.82,
                    ),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'TAKSIO',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _circleButton(Icons.person),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 245,
            child: GestureDetector(
              onTap: loadLocation,
              child: _circleButton(
                Icons.my_location,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomContent(
              taxiController,
              requestController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(
    TaxiController taxiController,
    RideRequestController requestController,
  ) {
    final request =
        requestController.currentRequest;

    if (request?.status == 'searching') {
      return SearchingTaxiSheet(
        onCancel: _cancelActiveTaxiFlow,
      );
    }

    if (taxiController.isSearching) {
      return SearchingTaxiSheet(
        onCancel: _cancelActiveTaxiFlow,
      );
    }

    if (taxiController.tripCompleted) {
      return TripCompletedSheet(
        finalPrice: estimatedPrice ?? 0,
        onFinish: (
          int rating,
          List<String> reasons,
          String comment,
        ) async {
          debugPrint('PUAN: $rating');
          debugPrint('NEDENLER: $reasons');
          debugPrint('YORUM: $comment');

          await _stopWatchingDriverLocation();
          await taxiController.cancelTaxi();

          if (!mounted) return;

          await requestController
              .clearCurrentRequest();

          if (!mounted) return;

          setState(() {
            destinationLocation = null;
            destinationAddress = null;
            routePoints = [];
            distanceKm = null;
            durationMinutes = null;
            estimatedPrice = null;
          });

          acceptedRequestHandled = false;
          driverArrivedHandled = false;

          _showMessage(
            'Değerlendirmeniz için teşekkür ederiz.',
          );
        },
      );
    }

    if (taxiController.tripStarted) {
      return TripStartedSheet(
        destination:
            destinationAddress ??
                'Gidilecek konum',
        etaMinutes:
            taxiController.tripRemainingMinutes,
        estimatedPrice:
            estimatedPrice ?? 0,
      );
    }

    final driver =
        taxiController.currentDriver;
    final vehicle =
        taxiController.currentTaxi;

    if (taxiController.driverAccepted &&
        driver != null &&
        vehicle != null) {
      return DriverArrivalCard(
        driver: driver,
        vehicle: vehicle,
        arrivalMinutes:
            taxiController.arrivalMinutes,
        remainingDistanceKm:
            taxiController.remainingDistanceKm,
        driverArrived:
            taxiController.driverArrived,
        onCall: callDriver,
        onMessage: messageDriver,
        onShareTrip: shareTrip,
        onStartTrip: () {
          final route = routePoints;
          final distance = distanceKm;
          final duration = durationMinutes;

          if (route.length < 2 ||
              distance == null ||
              duration == null) {
            _showMessage(
              'Yolculuk rotası hazır değil.',
              isError: true,
            );
            return;
          }

          taxiController.startTrip(
            routePoints: route,
            totalDistanceKm: distance,
            totalDurationMinutes: duration,
          );
        },
      );
    }

    return BottomPanel(
      hasCurrentLocation:
          pickupLocation != null,
      pickupAddress: pickupAddress,
      destinationAddress:
          destinationAddress,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      estimatedPrice: estimatedPrice,
      onPickupTap: openPickupOptions,
      onDestinationTap:
          openDestinationOptions,
      onCallTaxiTap: callTaxi,
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.82,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
