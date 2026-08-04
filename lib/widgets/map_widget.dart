import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

class MapWidget extends StatefulWidget {
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

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  gm.BitmapDescriptor? taxiIcon;
  gm.GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    createTaxiIcon();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.center != widget.center) {
      mapController?.animateCamera(
        gm.CameraUpdate.newLatLng(
          toGoogleLatLng(widget.center),
        ),
      );
    }
  }

  gm.LatLng toGoogleLatLng(LatLng point) {
    return gm.LatLng(
      point.latitude,
      point.longitude,
    );
  }

  Future<void> createTaxiIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const size = 120.0;

  final backgroundPaint = Paint()
    ..color = AppColors.yellow;

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2,
    backgroundPaint,
  );

  final borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 3,
    borderPaint,
  );

  const taxiIconData = Icons.local_taxi;

  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(taxiIconData.codePoint),
      style: TextStyle(
        fontFamily: taxiIconData.fontFamily,
        package: taxiIconData.fontPackage,
        fontSize: 66,
        color: Colors.black,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();

  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();

  final image = await picture.toImage(
    size.toInt(),
    size.toInt(),
  );

  final byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  if (byteData == null || !mounted) return;

  setState(() {
    taxiIcon = gm.BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      imagePixelRatio: 3,
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: toGoogleLatLng(widget.center),
        zoom: 15,
      ),
      onMapCreated: (controller) {
        mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        if (widget.destinationLocation != null)
          gm.Marker(
            markerId: const gm.MarkerId('destination'),
            position: toGoogleLatLng(
              widget.destinationLocation!,
            ),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueYellow,
            ),
          ),
        ...widget.taxis.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final taxi = entry.value;

            return gm.Marker(
              markerId: gm.MarkerId('taxi_$index'),
              position: toGoogleLatLng(taxi),
              icon: taxiIcon ??
                  gm.BitmapDescriptor.defaultMarkerWithHue(
                    gm.BitmapDescriptor.hueOrange,
                  ),
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 10,
            );
          },
        ),
      },
      polylines: {
        if (widget.routePoints.isNotEmpty)
          gm.Polyline(
            polylineId: const gm.PolylineId('route'),
            points: widget.routePoints
                .map(toGoogleLatLng)
                .toList(),
            color: AppColors.yellow,
            width: 6,
          ),
      },
    );
  }
}