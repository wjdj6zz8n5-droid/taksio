import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'driver_shift_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends State<DriverRegistrationScreen> {
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final identityNumberController = TextEditingController();

  bool documentsAccepted = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    licenseNumberController.dispose();
    identityNumberController.dispose();
    super.dispose();
  }

  Future<void> submitRegistration() async {
    FocusScope.of(context).unfocus();

    final isFormValid =
        formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    if (!documentsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Devam etmek için beyan ve onay kutusunu işaretleyin.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Başvuru Alındı',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Şoför bilgileriniz inceleme için kaydedildi. '
            'Demo sürümünde onay otomatik verilecektir.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Tamam',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverShiftScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Şoför Kaydı',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Sisteme Katıl',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vardiya başlatmadan önce şoför bilgilerinizi '
                've gerekli belgeleri kaydedin.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              _profilePhotoArea(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: firstNameController,
                      label: 'Ad',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: lastNameController,
                      label: 'Soyad',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _textField(
                controller: phoneController,
                label: 'Telefon numarası',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hintText: '5XX XXX XX XX',
                validator: (value) {
                  final digits = value
                          ?.replaceAll(RegExp(r'\D'), '') ??
                      '';

                  if (digits.length < 10) {
                    return 'Geçerli bir telefon numarası girin.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _textField(
                controller: identityNumberController,
                label: 'T.C. kimlik numarası',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                maxLength: 11,
                validator: (value) {
                  final digits = value?.trim() ?? '';

                  if (digits.length != 11) {
                    return 'T.C. kimlik numarası 11 haneli olmalı.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _textField(
                controller: licenseNumberController,
                label: 'Ehliyet belge numarası',
                icon: Icons.drive_eta_outlined,
              ),

              const SizedBox(height: 20),

              _documentCard(
                title: 'Ehliyet',
                subtitle: 'Ön ve arka yüz fotoğrafı',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 12),

              _documentCard(
                title: 'Şoför tanıtım kartı',
                subtitle: 'Belediye veya ilgili kurum belgesi',
                icon: Icons.assignment_ind_outlined,
              ),

              const SizedBox(height: 12),

              _documentCard(
                title: 'Adli sicil belgesi',
                subtitle: 'Güncel belge yüklenmelidir',
                icon: Icons.verified_user_outlined,
              ),

              const SizedBox(height: 20),

              CheckboxListTile(
                value: documentsAccepted,
                onChanged: (value) {
                  setState(() {
                    documentsAccepted = value ?? false;
                  });
                },
                activeColor: AppColors.yellow,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                controlAffinity:
                    ListTileControlAffinity.leading,
                title: const Text(
                  'Verdiğim bilgilerin doğru olduğunu ve '
                  'belgelerin incelemeye alınmasını kabul ediyorum.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ? null : submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Başvuruyu Tamamla',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
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

  Widget _profilePhotoArea() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 52,
                backgroundColor: Color(0xFF242424),
                child: Icon(
                  Icons.person,
                  color: AppColors.yellow,
                  size: 54,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.black,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Profil fotoğrafı ekle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
      ),
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bu alan zorunludur.';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: '',
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        hintStyle: const TextStyle(
          color: Colors.white30,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.yellow,
        ),
        filled: true,
        fillColor: const Color(0xFF171717),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.yellow,
          ),
        ),
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
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
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFF242424),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title yükleme özelliği Firebase Storage ile eklenecek.',
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.yellow,
              side: const BorderSide(
                color: AppColors.yellow,
              ),
            ),
            child: const Text(
              'Yükle',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}