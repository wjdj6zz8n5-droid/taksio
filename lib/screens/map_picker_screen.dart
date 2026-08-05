import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    required this.initialLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng cerkezkoyCenter = LatLng(
    41.2862,
    27.9994,
  );

  late final MapController mapController;
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();

    mapController = MapController();

    // iOS Simulator San Francisco konumu gönderse bile
    // test aşamasında haritayı Çerkezköy'de açıyoruz.
    selectedLocation = cerkezkoyCenter;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: cerkezkoyCenter,
              initialZoom: 16,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  selectedLocation = position.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taksio',
              ),
            ],
          ),

          const Center(
            child: Icon(
              Icons.location_on,
              color: AppColors.yellow,
              size: 54,
            ),
          ),

          Positioned(
            top: 56,
            left: 18,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            right: 18,
            top: 56,
            child: GestureDetector(
              onTap: () {
                mapController.move(
                  cerkezkoyCenter,
                  16,
                );

                setState(() {
                  selectedLocation = cerkezkoyCenter;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.yellow,
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    selectedLocation,
                  );
                },
                child: const Text(
                  'Konumu Onayla',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}