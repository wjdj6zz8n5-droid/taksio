import '../services/places_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/taxi_controller.dart';
import '../models/taxi_vehicle.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/driver_arrival_card.dart';
import '../widgets/map_widget.dart';
import '../widgets/searching_taxi_sheet.dart';
import 'destination_search_screen.dart';
import 'map_picker_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  LatLng? currentLocation;

  LatLng? pickupLocation;
  String? pickupAddress;

  LatLng? destinationLocation;
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

  Future<void> loadLocation() async {
    final location = await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      currentLocation = location;
      pickupLocation = location;
      pickupAddress =
          location == null ? 'Konum alınamadı' : 'Mevcut konumum';
    });
  }

  List<TaxiVehicle> getNearbyTaxiVehicles(LatLng center) {
    return [
      TaxiVehicle(
        id: 'taxi_1',
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
        id: 'taxi_2',
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
        id: 'taxi_3',
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
      TaxiVehicle(
        id: 'taxi_4',
        plate: '59 T 3551',
        brand: 'Hyundai',
        model: 'i20',
        color: 'Sarı',
        location: LatLng(
          center.latitude - 0.0024,
          center.longitude - 0.0013,
        ),
        available: true,
      ),
      TaxiVehicle(
        id: 'taxi_5',
        plate: '59 T 4182',
        brand: 'Ford',
        model: 'Focus',
        color: 'Sarı',
        location: LatLng(
          center.latitude + 0.0030,
          center.longitude + 0.0004,
        ),
        available: true,
      ),
    ];
  }

  Future<void> calculateTripInfo(LatLng destination) async {
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
        destinationAddress = 'Haritadan seçilen konum';
        routePoints = [];
        distanceKm = null;
        durationMinutes = null;
        estimatedPrice = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rota hesaplanamadı. Lütfen tekrar deneyin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      destinationLocation = destination;
      destinationAddress = 'Haritadan seçilen konum';
      routePoints = result.points;
      distanceKm = result.distanceKm;
      durationMinutes = result.durationMinutes;

      // Geçici demo tarifesi:
      // 175 TL açılış + kilometre başına 25 TL.
      estimatedPrice = (175 + (result.distanceKm * 25)).ceil();
    });
  }

  Future<void> recalculateRouteIfNeeded() async {
    final destination = destinationLocation;

    if (destination != null) {
      await calculateTripInfo(destination);
    }
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
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    if (currentLocation == null) {
                      await loadLocation();
                    }

                    if (!mounted) return;

                    if (currentLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mevcut konum alınamadı.',
                          ),
                        ),
                      );
                      return;
                    }

                    await context
                        .read<TaxiController>()
                        .cancelTaxi();

                    setState(() {
                      pickupLocation = currentLocation;
                      pickupAddress = 'Mevcut konumum';
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
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selectedLocation =
                        await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: pickupLocation ??
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

                    await context
                        .read<TaxiController>()
                        .cancelTaxi();

                    setState(() {
                      pickupLocation = selectedLocation;
                      pickupAddress =
                          'Haritadan seçilen alınacak konum';
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
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selection =
    await Navigator.push<PlaceSelection>(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const DestinationSearchScreen(),
  ),
);

if (!mounted || selection == null) {
  return;
}

await context
    .read<TaxiController>()
    .cancelTaxi();

setState(() {
  destinationAddress = selection.address;
});

await calculateTripInfo(
  selection.location,
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
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final selectedLocation =
                        await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
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

                    await context
                        .read<TaxiController>()
                        .cancelTaxi();

                    await calculateTripInfo(
                      selectedLocation,
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

    if (pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce alınacak konumu seçin.',
          ),
        ),
      );
      return;
    }

    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce gidilecek konumu haritadan seçin.',
          ),
        ),
      );
      return;
    }

    final taxis = getNearbyTaxiVehicles(pickup);

    await context.read<TaxiController>().callTaxi(
          taxis: taxis,
          pickupLocation: pickup,
        );
  }

  void callDriver() {
    final controller = context.read<TaxiController>();
    final phone = controller.currentDriver?.phone;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          phone == null
              ? 'Şoför telefon bilgisi bulunamadı.'
              : 'Şoför aranıyor: $phone',
        ),
      ),
    );
  }

  void messageDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mesajlaşma özelliği yakında eklenecek.',
        ),
      ),
    );
  }

  void shareTrip() {
    final controller = context.read<TaxiController>();

    final driverName =
        controller.currentDriver?.shortName ?? 'Şoför';
    final plate =
        controller.currentTaxi?.plate ?? 'Plaka bilinmiyor';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Yolculuk paylaşımı hazırlandı: '
          '$driverName • $plate',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taxiController = context.watch<TaxiController>();

    final mapCenter = pickupLocation ??
        currentLocation ??
        const LatLng(41.2862, 27.9994);

    final taxiVehicles =
        getNearbyTaxiVehicles(mapCenter);

    final mapTaxiLocations = taxiVehicles
        .where(
          (taxi) =>
              taxi.id != taxiController.currentTaxi?.id,
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
            destinationLocation: destinationLocation,
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
                  padding: const EdgeInsets.symmetric(
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
                      fontWeight: FontWeight.w900,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(
    TaxiController controller,
  ) {
    if (controller.isSearching) {
      return SearchingTaxiSheet(
        onCancel: () {
          controller.cancelTaxi();
        },
      );
    }

    final driver = controller.currentDriver;
    final vehicle = controller.currentTaxi;

    if (controller.driverAccepted &&
        driver != null &&
        vehicle != null) {
     return DriverArrivalCard(
  driver: driver,
  vehicle: vehicle,
  arrivalMinutes: controller.arrivalMinutes,
  remainingDistanceKm: controller.remainingDistanceKm,
  driverArrived: controller.driverArrived,
  onCall: callDriver,
  onMessage: messageDriver,
  onShareTrip: shareTrip,
);
    }

    return BottomPanel(
      hasCurrentLocation:
          pickupLocation != null,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
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