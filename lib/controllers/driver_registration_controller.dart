import 'package:flutter/foundation.dart';

import '../models/driver.dart';
import '../repositories/driver_repository.dart';

class DriverRegistrationController extends ChangeNotifier {
  DriverRegistrationController({
    DriverRepository? driverRepository,
  }) : _driverRepository =
            driverRepository ?? DriverRepository();

  final DriverRepository _driverRepository;

  bool isSubmitting = false;
  String? errorMessage;
  Driver? registeredDriver;

  Future<bool> registerDriver({
    required String firstName,
    required String lastName,
    required String phone,
    required String identityNumber,
    required String licenseNumber,
    required bool documentsAccepted,
  }) async {
    if (isSubmitting) {
      return false;
    }

    errorMessage = null;

    final validationError = _validate(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      identityNumber: identityNumber,
      licenseNumber: licenseNumber,
      documentsAccepted: documentsAccepted,
    );

    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final normalizedPhone =
          phone.replaceAll(RegExp(r'\D'), '');

      final driverId = 'driver_$normalizedPhone';

      final driver = Driver(
        id: driverId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: normalizedPhone,
        photoUrl: '',
        rating: 0,
        tripCount: 0,
        isOnline: false,
      );

      await _driverRepository.createOrUpdateDriver(
        driver,
      );

      registeredDriver = driver;
      errorMessage = null;

      return true;
    } catch (error) {
      errorMessage =
          'Şoför kaydı tamamlanamadı: $error';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) {
      return;
    }

    errorMessage = null;
    notifyListeners();
  }

  String? _validate({
    required String firstName,
    required String lastName,
    required String phone,
    required String identityNumber,
    required String licenseNumber,
    required bool documentsAccepted,
  }) {
    if (firstName.trim().isEmpty) {
      return 'Ad alanı zorunludur.';
    }

    if (lastName.trim().isEmpty) {
      return 'Soyad alanı zorunludur.';
    }

    final phoneDigits =
        phone.replaceAll(RegExp(r'\D'), '');

    if (phoneDigits.length < 10) {
      return 'Geçerli bir telefon numarası girin.';
    }

    final identityDigits =
        identityNumber.replaceAll(RegExp(r'\D'), '');

    if (identityDigits.length != 11) {
      return 'T.C. kimlik numarası 11 haneli olmalıdır.';
    }

    if (licenseNumber.trim().isEmpty) {
      return 'Ehliyet belge numarası zorunludur.';
    }

    if (!documentsAccepted) {
      return 'Beyan ve onay kutusunu işaretleyin.';
    }

    return null;
  }
}