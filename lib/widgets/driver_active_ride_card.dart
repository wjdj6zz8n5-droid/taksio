import 'package:flutter/material.dart';

import '../models/ride_request.dart';
import '../theme/app_colors.dart';

class DriverActiveRideCard extends StatelessWidget {
  const DriverActiveRideCard({
    super.key,
    required this.request,
    required this.onOpenNavigation,
    required this.onArrived,
    required this.onStartTrip,
    required this.onCompleteTrip,
    this.isLoading = false,
  });

  final RideRequest request;

  final VoidCallback onOpenNavigation;
  final VoidCallback onArrived;
  final VoidCallback onStartTrip;
  final VoidCallback onCompleteTrip;

  final bool isLoading;

  bool get driverArrived =>
      request.status == 'driver_arrived';

  bool get tripStarted =>
      request.status == 'trip_started';

  bool get tripCompleted =>
      request.status == 'trip_completed';

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tripCompleted
                      ? Icons.check_circle
                      : tripStarted
                          ? Icons.local_taxi
                          : driverArrived
                              ? Icons.person_pin_circle
                              : Icons.navigation,
                  color: tripCompleted
                      ? Colors.greenAccent
                      : AppColors.yellow,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tripCompleted
                        ? 'Yolculuk Tamamlandı'
                        : tripStarted
                            ? 'Yolculuk Devam Ediyor'
                            : driverArrived
                                ? 'Yolcu Bekleniyor'
                                : 'Yolcuya Gidiliyor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _info(
              Icons.my_location,
              'Alınacak Konum',
              request.pickupAddress,
            ),

            const SizedBox(height: 14),

            _info(
              Icons.flag,
              'Gidilecek Konum',
              request.destinationAddress,
            ),

            const Divider(
              color: Colors.white12,
              height: 32,
            ),

            Row(
              children: [
                Expanded(
                  child: _stat(
                    Icons.route,
                    '${request.distanceKm.toStringAsFixed(1)} km',
                  ),
                ),
                Expanded(
                  child: _stat(
                    Icons.schedule,
                    '${request.durationMinutes} dk',
                  ),
                ),
                Expanded(
                  child: _stat(
                    Icons.payments,
                    '${request.estimatedPrice} ₺',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (!tripCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : onOpenNavigation,
                  icon: const Icon(
                    Icons.navigation,
                  ),
                  label: const Text(
                    'Navigasyonu Aç',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.yellow,
                    side: const BorderSide(
                      color: AppColors.yellow,
                    ),
                  ),
                ),
              ),

            if (!tripCompleted)
              const SizedBox(height: 12),

            if (!driverArrived &&
                !tripStarted &&
                !tripCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : onArrived,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                  child: const Text(
                    'Yolcunun Yanına Geldim',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),

            if (driverArrived &&
                !tripStarted &&
                !tripCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : onStartTrip,
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text(
                    'Yolculuğu Başlat',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.greenAccent,
                    foregroundColor:
                        Colors.black,
                  ),
                ),
              ),

            if (tripStarted && !tripCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : onCompleteTrip,
                  icon: const Icon(
                    Icons.stop_circle,
                  ),
                  label: const Text(
                    'Yolculuğu Bitir',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                ),
              ),

            if (tripCompleted)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Colors.greenAccent,
                  ),
                ),
                child: const Text(
                  'Yolculuk başarıyla tamamlandı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight:
                        FontWeight.w800,
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
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.yellow,
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w700,
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
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.yellow,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }
}