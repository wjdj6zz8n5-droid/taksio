import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';
import 'destination_search_screen.dart';
import 'map_picker_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  LatLng? currentLocation;
  LatLng? destinationLocation;
  String? destinationAddress;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => currentLocation = location);
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

  Future<void> openDestinationOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.search, color: AppColors.yellow),
                  title: const Text('Adres Ara', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final address = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
                    );

                    if (!mounted) return;

                    if (address != null) {
                      setState(() {
                        destinationAddress = address;
                        destinationLocation = null;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: AppColors.yellow),
                  title: const Text('Haritadan Konum Seç', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final location = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: currentLocation ?? const LatLng(41.2862, 27.9994),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (location != null) {
                      setState(() {
                        destinationLocation = location;
                        destinationAddress =
                            'Haritadan seçilen konum';
                      });
                    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.yellow),
              SizedBox(height: 24),
              Text(
                'En yakın taksi aranıyor...',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              Text(
                'Bölgenizdeki uygun taksicilere çağrı gönderiliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
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
    final center = currentLocation ?? const LatLng(41.2862, 27.9994);
    final taxis = getNearbyTaxis(center);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taksio',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (destinationLocation != null)
                    Marker(
                      point: destinationLocation!,
                      width: 58,
                      height: 58,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.yellow,
                        size: 56,
                      ),
                    ),

                  ...taxis.map(
                    (taxi) => Marker(
                      point: taxi,
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_taxi, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.82),
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
            child: _circleButton(Icons.my_location),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.93),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nereye gitmek istiyorsun?',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  _locationField(
                    icon: Icons.my_location,
                    title: 'Alınacak konum',
                    subtitle: currentLocation == null ? 'Konum alınıyor...' : 'Mevcut konumun seçildi',
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: openDestinationOptions,
                    child: _locationField(
                      icon: Icons.location_on,
                      title: 'Gidilecek yer',
                      subtitle: destinationAddress ?? 'Adres veya konum seç',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: showSearchingTaxiPanel,
                      child: const Text(
                        'Taksi Çağır',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
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
        color: Colors.black.withOpacity(0.82),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _locationField({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.yellow),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}