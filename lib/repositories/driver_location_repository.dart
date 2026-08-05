import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationRepository {
  DriverLocationRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _drivers =>
          _firestore.collection('drivers');

  Future<void> updateDriverLocation({
    required String driverId,
    required String rideRequestId,
    required LatLng location,
    required double heading,
    required double speedMetersPerSecond,
  }) async {
    await _drivers.doc(driverId).set(
      {
        'driverId': driverId,
        'activeRideRequestId': rideRequestId,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'heading': heading,
        'speedMetersPerSecond':
            speedMetersPerSecond,
        'isOnline': true,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Stream<LatLng?> watchDriverLocation(
    String driverId,
  ) {
    return _drivers
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      final rawLocation = data['location'];

      if (rawLocation is! Map) {
        return null;
      }

      final location =
          Map<String, dynamic>.from(rawLocation);

      final latitude =
          (location['latitude'] as num?)
              ?.toDouble();

      final longitude =
          (location['longitude'] as num?)
              ?.toDouble();

      if (latitude == null ||
          longitude == null) {
        return null;
      }

      return LatLng(
        latitude,
        longitude,
      );
    });
  }

  Future<void> clearActiveRide({
    required String driverId,
  }) async {
    await _drivers.doc(driverId).set(
      {
        'activeRideRequestId':
            FieldValue.delete(),
        'isOnline': true,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> setDriverOffline({
    required String driverId,
  }) async {
    await _drivers.doc(driverId).set(
      {
        'activeRideRequestId':
            FieldValue.delete(),
        'isOnline': false,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}