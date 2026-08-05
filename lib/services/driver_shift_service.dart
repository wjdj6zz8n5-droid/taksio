import 'package:latlong2/latlong.dart';

import '../models/driver_shift.dart';

class DriverShiftService {
  final List<DriverShift> _shifts = [];

  List<DriverShift> get shifts =>
      List<DriverShift>.unmodifiable(_shifts);

  DriverShift? getActiveShiftForDriver(
    String driverId,
  ) {
    for (final shift in _shifts.reversed) {
      if (shift.driverId == driverId &&
          shift.isActive) {
        return shift;
      }
    }

    return null;
  }

  DriverShift? getActiveShiftForVehicle(
    String vehicleId,
  ) {
    for (final shift in _shifts.reversed) {
      if (shift.vehicleId == vehicleId &&
          shift.isActive) {
        return shift;
      }
    }

    return null;
  }

  DriverShift startShift({
    required String driverId,
    required String vehicleId,
    required LatLng currentLocation,
  }) {
    final activeDriverShift =
        getActiveShiftForDriver(driverId);

    if (activeDriverShift != null) {
      throw StateError(
        'Bu şoförün zaten aktif bir vardiyası var.',
      );
    }

    final activeVehicleShift =
        getActiveShiftForVehicle(vehicleId);

    if (activeVehicleShift != null) {
      throw StateError(
        'Bu araç başka bir şoför tarafından kullanılıyor.',
      );
    }

    final now = DateTime.now();

    final shift = DriverShift(
      id: 'shift_${now.microsecondsSinceEpoch}',
      driverId: driverId,
      vehicleId: vehicleId,
      startedAt: now,
      endedAt: null,
      isActive: true,
      currentLocation: currentLocation,
    );

    _shifts.add(shift);

    return shift;
  }

  DriverShift updateLocation({
    required String shiftId,
    required LatLng location,
  }) {
    final index = _shifts.indexWhere(
      (shift) => shift.id == shiftId,
    );

    if (index == -1) {
      throw StateError(
        'Vardiya bulunamadı.',
      );
    }

    final shift = _shifts[index];

    if (!shift.isActive) {
      throw StateError(
        'Kapalı vardiyanın konumu güncellenemez.',
      );
    }

    final updatedShift = shift.copyWith(
      currentLocation: location,
    );

    _shifts[index] = updatedShift;

    return updatedShift;
  }

  DriverShift endShift({
    required String shiftId,
  }) {
    final index = _shifts.indexWhere(
      (shift) => shift.id == shiftId,
    );

    if (index == -1) {
      throw StateError(
        'Vardiya bulunamadı.',
      );
    }

    final shift = _shifts[index];

    if (!shift.isActive) {
      return shift;
    }

    final endedShift = DriverShift(
      id: shift.id,
      driverId: shift.driverId,
      vehicleId: shift.vehicleId,
      startedAt: shift.startedAt,
      endedAt: DateTime.now(),
      isActive: false,
      currentLocation: shift.currentLocation,
    );

    _shifts[index] = endedShift;

    return endedShift;
  }
}