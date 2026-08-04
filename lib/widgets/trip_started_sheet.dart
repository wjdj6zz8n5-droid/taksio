import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TripStartedSheet extends StatelessWidget {
  final String destination;
  final int etaMinutes;
  final int estimatedPrice;

  const TripStartedSheet({
    super.key,
    required this.destination,
    required this.etaMinutes,
    required this.estimatedPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
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
            const SizedBox(height: 24),

            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),

            const SizedBox(height: 18),

            const Text(
              "Yolculuk Başladı",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              destination,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.schedule,
                    "$etaMinutes dk",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.payments,
                    "$estimatedPrice ₺",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.yellow,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}