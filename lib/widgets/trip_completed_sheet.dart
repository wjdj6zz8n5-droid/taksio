import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TripCompletedSheet extends StatefulWidget {
  final int finalPrice;
  final Future<void> Function(
    int rating,
    List<String> reasons,
    String comment,
  ) onFinish;

  const TripCompletedSheet({
    super.key,
    required this.finalPrice,
    required this.onFinish,
  });

  @override
  State<TripCompletedSheet> createState() =>
      _TripCompletedSheetState();
}

class _TripCompletedSheetState
    extends State<TripCompletedSheet> {
  final TextEditingController commentController =
      TextEditingController();

  int selectedRating = 5;
  final Set<String> selectedReasons = {};
  bool isSubmitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  List<String> get reasons {
    switch (selectedRating) {
      case 5:
        return const [
          'Araç çok temizdi',
          'Şoför nazik ve hoşgörülüydü',
          'Güvenli sürüş yaptı',
          'Hızlı ve zamanında ulaştı',
          'İletişimi çok iyiydi',
          'Rotayı doğru kullandı',
        ];

      case 4:
        return const [
          'Araç temizdi',
          'Şoför nazikti',
          'Güvenli sürüş yaptı',
          'Küçük bir gecikme oldu',
          'Genel olarak memnun kaldım',
        ];

      case 3:
        return const [
          'Araç temizliği ortalamaydı',
          'Şoförün iletişimi zayıftı',
          'Biraz geç geldi',
          'Sürüş ortalamaydı',
          'Rota beklediğimden uzundu',
        ];

      case 2:
        return const [
          'Araç temiz değildi',
          'Şoför geç geldi',
          'Sürüş rahatsızdı',
          'Şoför yeterince ilgili değildi',
          'Yanlış veya uzun rota kullandı',
          'Araçta kötü koku vardı',
        ];

      default:
        return const [
          'Güvensiz sürüş yaptı',
          'Şoför kaba davrandı',
          'Araç çok kirliydi',
          'Çok geç geldi',
          'Yanlış rota kullandı',
          'Araç bilgileri uyuşmuyordu',
          'Kendimi güvende hissetmedim',
        ];
    }
  }

  String get questionTitle {
    if (selectedRating == 5) {
      return 'Neden 5 yıldız verdiniz?';
    }

    if (selectedRating == 4) {
      return 'Nelerden memnun kaldınız?';
    }

    if (selectedRating == 3) {
      return 'Deneyiminizi nasıl geliştirebiliriz?';
    }

    return 'Neden düşük puan verdiniz?';
  }

  void selectRating(int rating) {
    setState(() {
      selectedRating = rating;
      selectedReasons.clear();
    });
  }

  Future<void> submitRating() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await widget.onFinish(
        selectedRating,
        selectedReasons.toList(),
        commentController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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

              const Icon(
                Icons.flag_circle,
                color: Colors.greenAccent,
                size: 62,
              ),

              const SizedBox(height: 14),

              const Text(
                'Varış Noktasına Geldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Yolculuğunuz tamamlandı.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tahmini Tutar',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.finalPrice} ₺',
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Şoförü değerlendir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  final isSelected = star <= selectedRating;

                  return IconButton(
                    onPressed: () => selectRating(star),
                    iconSize: 38,
                    icon: Icon(
                      isSelected
                          ? Icons.star
                          : Icons.star_border,
                      color: isSelected
                          ? AppColors.yellow
                          : Colors.white38,
                    ),
                  );
                }),
              ),

              Text(
                '$selectedRating yıldız',
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  questionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: reasons.map((reason) {
                    final isSelected =
                        selectedReasons.contains(reason);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(reason),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedReasons.add(reason);
                          } else {
                            selectedReasons.remove(reason);
                          }
                        });
                      },
                      selectedColor:
                          AppColors.yellow.withValues(alpha: 0.9),
                      backgroundColor:
                          const Color(0xFF242424),
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.yellow
                            : Colors.white12,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 250,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Eklemek istediğiniz bir yorum var mı?',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF171717),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ? null : submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Değerlendir ve Yolculuğu Bitir',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}