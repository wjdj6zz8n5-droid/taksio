import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final LatLng currentLocation;
  final LatLng? destinationLocation;
  final List<LatLng> taxis;
  final List<LatLng> routePoints;

  const MapWidget({
    super.key,
    required this.center,
    required this.currentLocation,
    required this.destinationLocation,
    required this.taxis,
    required this.routePoints,
  });

  gm.LatLng _toGoogleLatLng(LatLng point) {
    return gm.LatLng(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: _toGoogleLatLng(center),
        zoom: 15,
      ),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        gm.Marker(
          markerId: const gm.MarkerId('current_location'),
          position: _toGoogleLatLng(currentLocation),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueAzure,
          ),
        ),
        if (destinationLocation != null)
          gm.Marker(
            markerId: const gm.MarkerId('destination'),
            position: _toGoogleLatLng(destinationLocation!),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueYellow,
            ),
          ),
        ...taxis.map(
          (taxi) => gm.Marker(
            markerId: gm.MarkerId(
              'taxi_${taxi.latitude}_${taxi.longitude}',
            ),
            position: _toGoogleLatLng(taxi),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueOrange,
            ),
          ),
        ),
      },
      polylines: {
        if (routePoints.isNotEmpty)
          gm.Polyline(
            polylineId: const gm.PolylineId('route'),
            points: routePoints.map(_toGoogleLatLng).toList(),
            color: AppColors.yellow,
            width: 6,
          ),
      },
    );
  }
}