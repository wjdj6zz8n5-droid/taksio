import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/taxi_vehicle.dart';

class VehicleRepository {
  VehicleRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _firestore.collection('vehicles');

  Future<void> createOrUpdateVehicle(
    TaxiVehicle vehicle, {
    String? ownerDriverId,
  }) async {
    await _vehicles.doc(vehicle.id).set(
      {
        'id': vehicle.id,
        'plate': vehicle.plate,
        'brand': vehicle.brand,
        'model': vehicle.model,
        'color': vehicle.color,
        'available': vehicle.available,
        'ownerDriverId': ownerDriverId,
        'location': {
          'latitude': vehicle.location.latitude,
          'longitude': vehicle.location.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<TaxiVehicle?> getVehicle(
    String vehicleId,
  ) async {
    final snapshot = await _vehicles.doc(vehicleId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return _fromMap(
      id: snapshot.id,
      data: data,
    );
  }

  Stream<TaxiVehicle?> watchVehicle(
    String vehicleId,
  ) {
    return _vehicles.doc(vehicleId).snapshots().map(
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

  Stream<List<TaxiVehicle>> watchAvailableVehicles() {
    return _vehicles
        .where('available', isEqualTo: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (document) => _fromMap(
                id: document.id,
                data: document.data(),
              ),
            )
            .toList();
      },
    );
  }

  Future<void> updateAvailability({
    required String vehicleId,
    required bool available,
  }) async {
    await _vehicles.doc(vehicleId).update(
      {
        'available': available,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> updateLocation({
    required String vehicleId,
    required LatLng location,
  }) async {
    await _vehicles.doc(vehicleId).update(
      {
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  TaxiVehicle _fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawLocation =
        data['location'] as Map<String, dynamic>?;

    final latitude =
        (rawLocation?['latitude'] as num?)?.toDouble() ??
            0;

    final longitude =
        (rawLocation?['longitude'] as num?)?.toDouble() ??
            0;

    return TaxiVehicle(
      id: data['id'] as String? ?? id,
      plate: data['plate'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      color: data['color'] as String? ?? '',
      location: LatLng(
        latitude,
        longitude,
      ),
      available: data['available'] as bool? ?? false,
    );
  }
}