import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

class TaxiMarkers extends StatelessWidget {
  final LatLng currentLocation;
  final LatLng? destinationLocation;
  final List<LatLng> taxis;

  const TaxiMarkers({
    super.key,
    required this.currentLocation,
    required this.destinationLocation,
    required this.taxis,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        // Kullanıcının konumu
        Marker(
          point: currentLocation,
          width: 48,
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.18),
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

        // Hedef konumu
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

        // Taksiler
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
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_taxi,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}