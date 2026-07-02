import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TaksioLogo extends StatelessWidget {
  const TaksioLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.local_taxi,
            color: Colors.black,
            size: 62,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'TAKSIO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'En Yakın Taksi, Tek Dokunuş.',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}