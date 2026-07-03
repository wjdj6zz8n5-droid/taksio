import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DestinationSearchScreen extends StatelessWidget {
  const DestinationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addresses = [
      'Çerkezköy Center',
      'Tekirdağ Otogar',
      'Çorlu Havalimanı',
      'Kapaklı Merkez',
      'İstanbul Havalimanı',
    ];

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text('Gidilecek Yer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Adres ara...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: AppColors.yellow),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.yellow),
                    title: Text(
                      addresses[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context, addresses[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}