import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TripInfoCard extends StatelessWidget {
  final double distanceKm;
  final int durationMinutes;
  final int estimatedPrice;

  const TripInfoCard({
    super.key,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _info(
            Icons.route,
            "Mesafe",
            "${distanceKm.toStringAsFixed(1)} km",
          ),
          _info(
            Icons.schedule,
            "Süre",
            "$durationMinutes dk",
          ),
          _info(
            Icons.payments,
            "Tahmini",
            "$estimatedPrice TL",
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.yellow),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}