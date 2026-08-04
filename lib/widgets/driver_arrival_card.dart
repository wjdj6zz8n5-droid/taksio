import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/taxi_vehicle.dart';
import '../theme/app_colors.dart';

class DriverArrivalCard extends StatelessWidget {
  final Driver driver;
  final TaxiVehicle vehicle;
  final int arrivalMinutes;
  final double remainingDistanceKm;
  final bool driverArrived;

  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onShareTrip;

  const DriverArrivalCard({
    super.key,
    required this.driver,
    required this.vehicle,
    required this.arrivalMinutes,
    required this.remainingDistanceKm,
    required this.driverArrived,
    required this.onCall,
    required this.onMessage,
    required this.onShareTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF242424),
                  backgroundImage: driver.photoUrl.isNotEmpty
                      ? NetworkImage(driver.photoUrl)
                      : null,
                  child: driver.photoUrl.isEmpty
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.yellow,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${driver.tripCount} yolculuk',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: driverArrived
                        ? Colors.green
                        : AppColors.yellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    driverArrived
                        ? 'Geldi'
                        : '$arrivalMinutes dk',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_taxi,
                    color: AppColors.yellow,
                    size: 30,
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.plate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.brand} ${vehicle.model} • ${vehicle.color}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          driverArrived
                              ? 'Şoför alınacak konumda'
                              : '${remainingDistanceKm.toStringAsFixed(2)} km kaldı',
                          style: TextStyle(
                            color: driverArrived
                                ? Colors.greenAccent
                                : AppColors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.call,
                    label: 'Ara',
                    onTap: onCall,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Mesaj',
                    onTap: onMessage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onShareTrip,
                icon: const Icon(
                  Icons.shield_outlined,
                ),
                label: const Text(
                  'Yolculuğumu Paylaş',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.yellow,
                  side: const BorderSide(
                    color: AppColors.yellow,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 20,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF242424),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}