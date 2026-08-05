import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver_shift.dart';

class DriverShiftRepository {
  DriverShiftRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shifts =>
      _firestore.collection('driver_shifts');

  Future<void> createShift(
    DriverShift shift,
  ) async {
    await _shifts.doc(shift.id).set(
      {
        'id': shift.id,
        'driverId': shift.driverId,
        'vehicleId': shift.vehicleId,
        'startedAt': Timestamp.fromDate(
          shift.startedAt,
        ),
        'endedAt': shift.endedAt == null
            ? null
            : Timestamp.fromDate(
                shift.endedAt!,
              ),
        'isActive': shift.isActive,
        'currentLocation': shift.currentLocation == null
            ? null
            : {
                'latitude': shift.currentLocation!.latitude,
                'longitude': shift.currentLocation!.longitude,
              },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<DriverShift?> getShift(
    String shiftId,
  ) async {
    final snapshot = await _shifts.doc(shiftId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return _fromMap(
      id: snapshot.id,
      data: data,
    );
  }

  Stream<DriverShift?> watchShift(
    String shiftId,
  ) {
    return _shifts.doc(shiftId).snapshots().map(
      (snapshot) {
        final data = snapshot.data();

        if (!snapshot.exists || data == null) {
          return null;
        }

        return _fromMap(
          id: snapshot.id,
          data: data,
        );
      },
    );
  }

  Stream<DriverShift?> watchActiveShiftForDriver(
    String driverId,
  ) {
    return _shifts
        .where(
          'driverId',
          isEqualTo: driverId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .snapshots()
        .map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        final document = snapshot.docs.first;

        return _fromMap(
          id: document.id,
          data: document.data(),
        );
      },
    );
  }

  Stream<DriverShift?> watchActiveShiftForVehicle(
    String vehicleId,
  ) {
    return _shifts
        .where(
          'vehicleId',
          isEqualTo: vehicleId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .snapshots()
        .map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        final document = snapshot.docs.first;

        return _fromMap(
          id: document.id,
          data: document.data(),
        );
      },
    );
  }

  Future<void> updateLocation({
    required String shiftId,
    required LatLng location,
  }) async {
    await _shifts.doc(shiftId).update(
      {
        'currentLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> endShift({
    required String shiftId,
  }) async {
    await _shifts.doc(shiftId).update(
      {
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  DriverShift _fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawLocation =
        data['currentLocation'] as Map<String, dynamic>?;

    final startedAt = data['startedAt'];
    final endedAt = data['endedAt'];

    return DriverShift(
      id: data['id'] as String? ?? id,
      driverId: data['driverId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      startedAt: startedAt is Timestamp
          ? startedAt.toDate()
          : DateTime.now(),
      endedAt: endedAt is Timestamp
          ? endedAt.toDate()
          : null,
      isActive: data['isActive'] as bool? ?? false,
      currentLocation: rawLocation == null
          ? null
          : LatLng(
              (rawLocation['latitude'] as num?)?.toDouble() ?? 0,
              (rawLocation['longitude'] as num?)?.toDouble() ?? 0,
            ),
    );
  }
}