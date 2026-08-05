import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_request.dart';
import '../services/route_service.dart';
import '../theme/app_colors.dart';

class NewRideRequestCard extends StatefulWidget {
  const NewRideRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    this.isLoading = false,
  });

  final RideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isLoading;

  @override
  State<NewRideRequestCard> createState() =>
      _NewRideRequestCardState();
}

class _NewRideRequestCardState
    extends State<NewRideRequestCard> {
  List<LatLng> routePoints = [];
  bool isRouteLoading = true;

  @override
  void initState() {
    super.initState();
    loadRoute();
  }

  @override
  void didUpdateWidget(
    covariant NewRideRequestCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.request.id != widget.request.id) {
      loadRoute();
    }
  }

  Future<void> loadRoute() async {
    setState(() {
      isRouteLoading = true;
      routePoints = [];
    });

    final result = await RouteService.getRoute(
      origin: widget.request.pickupLocation,
      destination:
          widget.request.destinationLocation,
    );

    if (!mounted) return;

    setState(() {
      routePoints = result?.points ??
          [
            widget.request.pickupLocation,
            widget.request.destinationLocation,
          ];
      isRouteLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.yellow.withValues(
              alpha: 0.35,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_taxi,
                  color: AppColors.yellow,
                  size: 38,
                ),
                SizedBox(width: 10),
                Text(
                  'Yeni Yolculuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _tripMap(request),
            const SizedBox(height: 18),
            _info(
              Icons.my_location,
              'Alınacak Konum',
              request.pickupAddress,
              Colors.greenAccent,
            ),
            const SizedBox(height: 14),
            _info(
              Icons.flag,
              'Gidilecek Konum',
              request.destinationAddress,
              Colors.redAccent,
            ),
            const Divider(
              color: Colors.white12,
              height: 30,
            ),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    Icons.route,
                    '${request.distanceKm.toStringAsFixed(1)} km',
                    'Mesafe',
                  ),
                ),
                Expanded(
                  child: _stat(
                    Icons.schedule,
                    '${request.durationMinutes} dk',
                    'Tahmini süre',
                  ),
                ),
                Expanded(
                  child: _stat(
                    Icons.payments,
                    '${request.estimatedPrice} ₺',
                    'Tahmini tutar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading
                        ? null
                        : widget.onReject,
                    style:
                        OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      foregroundColor:
                          Colors.redAccent,
                      minimumSize: const Size(
                        double.infinity,
                        56,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading
                        ? null
                        : widget.onAccept,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.yellow,
                      foregroundColor:
                          Colors.black,
                      minimumSize: const Size(
                        double.infinity,
                        56,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Kabul Et',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripMap(RideRequest request) {
    final center = LatLng(
      (request.pickupLocation.latitude +
              request.destinationLocation.latitude) /
          2,
      (request.pickupLocation.longitude +
              request.destinationLocation.longitude) /
          2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.5,
                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.taksio',
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 5,
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: request.pickupLocation,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.greenAccent,
                        size: 34,
                      ),
                    ),
                    Marker(
                      point:
                          request.destinationLocation,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isRouteLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: AppColors.yellow,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.yellow,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
