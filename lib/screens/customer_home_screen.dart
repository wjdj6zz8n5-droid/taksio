import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/route_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/map_widget.dart';
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

  List<LatLng> getNearbyTaxis(LatLng center) {
    return [
      LatLng(center.latitude + 0.0020, center.longitude + 0.0015),
      LatLng(center.latitude - 0.0018, center.longitude + 0.0022),
      LatLng(center.latitude + 0.0012, center.longitude - 0.0020),
      LatLng(center.latitude - 0.0024, center.longitude - 0.0013),
      LatLng(center.latitude + 0.0030, center.longitude + 0.0004),
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
          content: Text('Rota hesaplanamadı. Lütfen tekrar deneyin.'),
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
                          content: Text('Mevcut konum alınamadı.'),
                        ),
                      );
                      return;
                    }

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

                    final selectedLocation = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: pickupLocation ??
                              currentLocation ??
                              const LatLng(41.2862, 27.9994),
                        ),
                      ),
                    );

                    if (!mounted || selectedLocation == null) return;

                    setState(() {
                      pickupLocation = selectedLocation;
                      pickupAddress = 'Haritadan seçilen alınacak konum';
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

                    final address = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DestinationSearchScreen(),
                      ),
                    );

                    if (!mounted || address == null) return;

                    setState(() {
                      destinationAddress = address;

                      // Adres arama ekranı henüz koordinat döndürmediği için
                      // gerçek rota hesaplanamıyor.
                      destinationLocation = null;
                      routePoints = [];
                      distanceKm = null;
                      durationMinutes = null;
                      estimatedPrice = null;
                    });
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

                    final selectedLocation = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: destinationLocation ??
                              pickupLocation ??
                              currentLocation ??
                              const LatLng(41.2862, 27.9994),
                        ),
                      ),
                    );

                    if (!mounted || selectedLocation == null) return;

                    await calculateTripInfo(selectedLocation);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showSearchingTaxiPanel() {
    if (pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce alınacak konumu seçin.'),
        ),
      );
      return;
    }

    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce gidilecek konumu haritadan seçin.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.yellow,
              ),
              SizedBox(height: 24),
              Text(
                'En yakın taksi aranıyor...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Bölgenizdeki uygun taksicilere çağrı gönderiliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = pickupLocation ??
        currentLocation ??
        const LatLng(41.2862, 27.9994);

    final taxis = getNearbyTaxis(mapCenter);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          MapWidget(
            center: mapCenter,
            currentLocation: mapCenter,
            destinationLocation: destinationLocation,
            taxis: taxis,
            routePoints: routePoints,
          ),
          Positioned(
            top: 58,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(Icons.menu),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(18),
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
              onTap: () async {
                await loadLocation();
              },
              child: _circleButton(Icons.my_location),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomPanel(
              hasCurrentLocation: pickupLocation != null,
              pickupAddress: pickupAddress,
              destinationAddress: destinationAddress,
              distanceKm: distanceKm,
              durationMinutes: durationMinutes,
              estimatedPrice: estimatedPrice,
              onPickupTap: openPickupOptions,
              onDestinationTap: openDestinationOptions,
              onCallTaxiTap: showSearchingTaxiPanel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}