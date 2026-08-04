import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'trip_info_card.dart';

class BottomPanel extends StatelessWidget {
  final bool hasCurrentLocation;
  final String? pickupAddress;
  final String? destinationAddress;

  final double? distanceKm;
  final int? durationMinutes;
  final int? estimatedPrice;

  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onCallTaxiTap;

  const BottomPanel({
    super.key,
    required this.hasCurrentLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedPrice,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onCallTaxiTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTripInfo = distanceKm != null &&
        durationMinutes != null &&
        estimatedPrice != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.93),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nereye gitmek istiyorsun?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onPickupTap,
            child: _locationField(
              icon: Icons.my_location,
              title: 'Alınacak konum',
              subtitle: pickupAddress ??
                  (hasCurrentLocation
                      ? 'Mevcut konumun seçildi'
                      : 'Konum alınıyor...'),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onDestinationTap,
            child: _locationField(
              icon: Icons.location_on,
              title: 'Gidilecek yer',
              subtitle: destinationAddress ?? 'Adres veya konum seç',
            ),
          ),
          if (hasTripInfo) ...[
            const SizedBox(height: 14),
            TripInfoCard(
              distanceKm: distanceKm!,
              durationMinutes: durationMinutes!,
              estimatedPrice: estimatedPrice!,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onCallTaxiTap,
              child: const Text(
                'Taksi Çağır',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
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
          Icon(
            icon,
            color: AppColors.yellow,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white38,
          ),
        ],
      ),
    );
  }
}