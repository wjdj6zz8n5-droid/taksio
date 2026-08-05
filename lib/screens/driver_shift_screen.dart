import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/ride_request_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/driver.dart';
import '../models/driver_shift.dart';
import '../models/taxi_vehicle.dart';
import '../repositories/driver_location_repository.dart';
import '../services/driver_shift_service.dart';
import '../theme/app_colors.dart';
import '../widgets/driver_active_ride_card.dart';
import '../widgets/new_ride_request_card.dart';

class DriverShiftScreen extends StatefulWidget {
  const DriverShiftScreen({super.key});

  @override
  State<DriverShiftScreen> createState() => _DriverShiftScreenState();
}

class _DriverShiftScreenState extends State<DriverShiftScreen> {
  final DriverShiftService shiftService = DriverShiftService();
  final DriverLocationRepository driverLocationRepository =
      DriverLocationRepository();

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  bool _isUploadingLocation = false;

  final Driver demoDriver = const Driver(
    id: 'driver_1',
    firstName: 'Mehmet',
    lastName: 'Sağlam',
    phone: '05550000000',
    photoUrl: '',
    rating: 4.9,
    tripCount: 2847,
    isOnline: true,
  );

  final List<TaxiVehicle> vehicles = const [
    TaxiVehicle(
      id: 'vehicle_1',
      plate: '59 ABC 47',
      brand: 'Toyota',
      model: 'Corolla',
      color: 'Sarı',
      location: LatLng(41.2862, 27.9994),
      available: true,
    ),
    TaxiVehicle(
      id: 'vehicle_2',
      plate: '59 T 1024',
      brand: 'Renault',
      model: 'Megane',
      color: 'Sarı',
      location: LatLng(41.2874, 28.0012),
      available: true,
    ),
    TaxiVehicle(
      id: 'vehicle_3',
      plate: '59 T 2047',
      brand: 'Fiat',
      model: 'Egea',
      color: 'Sarı',
      location: LatLng(41.2848, 27.9975),
      available: true,
    ),
  ];

  TaxiVehicle? selectedVehicle;
  DriverShift? activeShift;
  String? errorMessage;

  Future<bool> _startLocationTracking() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          errorMessage =
              'Konum servisi kapalı. Lütfen telefondan konumu açın.';
        });
      }
      return false;
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          errorMessage = permission ==
                  LocationPermission.deniedForever
              ? 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.'
              : 'Vardiya için konum izni gereklidir.';
        });
      }
      return false;
    }

    await _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    try {
      final currentPosition =
          await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _lastPosition = currentPosition;
    } catch (_) {
      // İlk konum hemen alınamazsa stream güncellemesi beklenecek.
    }

    _positionSubscription = Geolocator
        .getPositionStream(
          locationSettings: locationSettings,
        )
        .listen(
      (position) {
        _lastPosition = position;
        _publishPositionForActiveRide(position);
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          errorMessage =
              'Canlı konum alınamadı: $error';
        });
      },
    );

    return true;
  }

  Future<void> _publishPositionForActiveRide(
    Position position,
  ) async {
    if (!mounted || _isUploadingLocation) {
      return;
    }

    final request = context
        .read<RideRequestController>()
        .acceptedDriverRequest;

    if (request == null) {
      return;
    }

    _isUploadingLocation = true;

    try {
      await driverLocationRepository
          .updateDriverLocation(
        driverId: demoDriver.id,
        rideRequestId: request.id,
        location: LatLng(
          position.latitude,
          position.longitude,
        ),
        heading: position.heading,
        speedMetersPerSecond: position.speed,
      );
    } finally {
      _isUploadingLocation = false;
    }
  }

  Future<void> _publishLastPosition(
    String rideRequestId,
  ) async {
    final position = _lastPosition;

    if (position == null) {
      return;
    }

    await driverLocationRepository
        .updateDriverLocation(
      driverId: demoDriver.id,
      rideRequestId: rideRequestId,
      location: LatLng(
        position.latitude,
        position.longitude,
      ),
      heading: position.heading,
      speedMetersPerSecond: position.speed,
    );
  }

  Future<void> _stopLocationTracking({
    required bool setOffline,
  }) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;

    if (setOffline) {
      await driverLocationRepository
          .setDriverOffline(
        driverId: demoDriver.id,
      );
    }
  }

  Future<void> startShift() async {
    final vehicle = selectedVehicle;

    if (vehicle == null) {
      setState(() {
        errorMessage = 'Lütfen vardiya başlatmak için bir araç seçin.';
      });
      return;
    }

    final locationReady =
        await _startLocationTracking();

    if (!locationReady) {
      return;
    }

    try {
      final shift = shiftService.startShift(
        driverId: demoDriver.id,
        vehicleId: vehicle.id,
        currentLocation: vehicle.location,
      );

      if (!mounted) return;

      setState(() {
        activeShift = shift;
        errorMessage = null;
      });

      context
          .read<RideRequestController>()
          .startListeningForSearchingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${vehicle.plate} plakalı araçla vardiya başladı.',
          ),
        ),
      );
    } on StateError catch (error) {
      await _stopLocationTracking(
        setOffline: true,
      );

      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    }
  }

  Future<void> endShift() async {
    final shift = activeShift;

    if (shift == null) return;

    shiftService.endShift(shiftId: shift.id);

    await context
        .read<RideRequestController>()
        .stopListeningForSearchingRequests();

    await _stopLocationTracking(
      setOffline: true,
    );

    if (!mounted) return;

    setState(() {
      activeShift = null;
      selectedVehicle = null;
      errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vardiya başarıyla kapatıldı.'),
      ),
    );
  }

  Future<void> acceptRideRequest() async {
    final shift = activeShift;
    final controller = context.read<RideRequestController>();
    final request = controller.nextSearchingRequest;

    if (shift == null || request == null) return;

    final accepted = await controller.acceptRequest(
      requestId: request.id,
      driverId: demoDriver.id,
      vehicleId: shift.vehicleId,
    );

    if (!mounted) return;

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ??
                'Yolculuk kabul edilemedi.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _publishLastPosition(
      request.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yolculuk kabul edildi.'),
      ),
    );
  }

  Future<void> rejectRideRequest() async {
    final controller = context.read<RideRequestController>();
    final request = controller.nextSearchingRequest;

    if (request == null) return;

    await controller.rejectRequest(
      requestId: request.id,
      driverId: demoDriver.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yolculuk isteği reddedildi.'),
      ),
    );
  }

  Future<void> openNavigation() async {
  final controller =
      context.read<RideRequestController>();

  final request =
      controller.acceptedDriverRequest;

  if (request == null) {
    return;
  }

  final isTripStarted =
      request.status == 'trip_started';

  final target = isTripStarted
      ? request.destinationLocation
      : request.pickupLocation;

  final googleMapsUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${target.latitude},${target.longitude}'
    '&travelmode=driving',
  );

  final appleMapsUri = Uri.parse(
    'https://maps.apple.com/'
    '?daddr=${target.latitude},${target.longitude}'
    '&dirflg=d',
  );

  final targetUri = Theme.of(context).platform ==
          TargetPlatform.iOS
      ? appleMapsUri
      : googleMapsUri;

  final opened = await launchUrl(
    targetUri,
    mode: LaunchMode.externalApplication,
  );

  if (!mounted) return;

  if (!opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Navigasyon uygulaması açılamadı.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  Future<void> markArrived() async {
  final controller =
      context.read<RideRequestController>();

  final request =
      controller.acceptedDriverRequest;

  if (request == null) {
    return;
  }

  final success =
      await controller.markDriverArrived(
    requestId: request.id,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Yolcuya ulaşıldı bilgisi gönderildi.'
            : controller.errorMessage ??
                'Bilgi gönderilemedi.',
      ),
      backgroundColor:
          success ? null : Colors.redAccent,
    ),
  );
}
Future<void> startActiveTrip() async {
  final controller =
      context.read<RideRequestController>();

  final request =
      controller.acceptedDriverRequest;

  if (request == null) {
    return;
  }

  final success = await controller.startTrip(
    requestId: request.id,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Yolculuk başlatıldı.'
            : controller.errorMessage ??
                'Yolculuk başlatılamadı.',
      ),
      backgroundColor:
          success ? null : Colors.redAccent,
    ),
  );
}
Future<void> completeActiveTrip() async {
  final controller =
      context.read<RideRequestController>();

  final request =
      controller.acceptedDriverRequest;

  if (request == null) {
    return;
  }

  final success = await controller.completeTrip(
    requestId: request.id,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Yolculuk tamamlandı.'
            : controller.errorMessage ??
                'Yolculuk tamamlanamadı.',
      ),
      backgroundColor:
          success ? null : Colors.redAccent,
    ),
  );

  if (!success) {
    return;
  }

  await driverLocationRepository.clearActiveRide(
    driverId: demoDriver.id,
  );

  await Future<void>.delayed(
    const Duration(milliseconds: 500),
  );

  if (!mounted) return;

  controller.clearAcceptedDriverRequest();
}

  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isShiftActive = activeShift?.isActive ?? false;
    final rideRequestController =
        context.watch<RideRequestController>();

    final acceptedRequest =
        rideRequestController.acceptedDriverRequest;

    final nextRequest =
        isShiftActive && acceptedRequest == null
            ? rideRequestController.nextSearchingRequest
            : null;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Şoför Vardiyası',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _driverCard(),
                const SizedBox(height: 20),
                if (acceptedRequest != null)
                  DriverActiveRideCard(
  request: acceptedRequest,
  onOpenNavigation: openNavigation,
  onArrived: markArrived,
  onStartTrip: startActiveTrip,
  onCompleteTrip: completeActiveTrip,
  isLoading:
      rideRequestController.isAcceptingRequest,
)
                else if (isShiftActive)
                  _activeShiftCard()
                else
                  _vehicleSelection(),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: acceptedRequest != null
                        ? null
                        : isShiftActive
                            ? endShift
                            : startShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isShiftActive
                          ? Colors.redAccent
                          : AppColors.yellow,
                      foregroundColor: isShiftActive
                          ? Colors.white
                          : Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      acceptedRequest != null
                          ? 'Aktif yolculuk var'
                          : isShiftActive
                              ? 'Vardiyayı Bitir'
                              : 'Vardiyayı Başlat',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (nextRequest != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: NewRideRequestCard(
                    request: nextRequest,
                    isLoading:
                        rideRequestController.isAcceptingRequest,
                    onAccept: acceptRideRequest,
                    onReject: rejectRideRequest,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _driverCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF242424),
            backgroundImage: demoDriver.photoUrl.isNotEmpty
                ? NetworkImage(demoDriver.photoUrl)
                : null,
            child: demoDriver.photoUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppColors.yellow,
                    size: 34,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  demoDriver.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.yellow,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      demoDriver.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${demoDriver.tripCount} yolculuk',
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kullanacağınız aracı seçin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Yolcuya bu vardiyada seçtiğiniz araç ve plaka gösterilecek.',
          style: TextStyle(
            color: Colors.white60,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        ...vehicles.map((vehicle) {
          final isSelected =
              selectedVehicle?.id == vehicle.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedVehicle = vehicle;
                  errorMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.yellow.withValues(
                          alpha: 0.14,
                        )
                      : const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.yellow
                        : Colors.white10,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.yellow
                            : const Color(0xFF242424),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_taxi,
                        color: isSelected
                            ? Colors.black
                            : AppColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.plate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.brand} ${vehicle.model} • ${vehicle.color}',
                            style: const TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.yellow
                          : Colors.white24,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _activeShiftCard() {
    final shift = activeShift;

    if (shift == null) {
      return const SizedBox.shrink();
    }

    final vehicle = vehicles.firstWhere(
      (item) => item.id == shift.vehicleId,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.greenAccent.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: Colors.greenAccent,
              ),
              SizedBox(width: 8),
              Text(
                'Vardiya Aktif',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            vehicle.plate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${vehicle.brand} ${vehicle.model} • ${vehicle.color}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: AppColors.yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Başlangıç: ${formatTime(shift.startedAt)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

}
