import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/driver.dart';

class DriverRepository {
  DriverRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  Future<void> createOrUpdateDriver(
    Driver driver,
  ) async {
    await _drivers.doc(driver.id).set(
      {
        'id': driver.id,
        'firstName': driver.firstName,
        'lastName': driver.lastName,
        'phone': driver.phone,
        'photoUrl': driver.photoUrl,
        'rating': driver.rating,
        'tripCount': driver.tripCount,
        'isOnline': driver.isOnline,
        'isApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<Driver?> getDriver(
    String driverId,
  ) async {
    final snapshot =
        await _drivers.doc(driverId).get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return Driver(
      id: data['id'] as String? ?? snapshot.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      rating:
          (data['rating'] as num?)?.toDouble() ?? 0,
      tripCount:
          (data['tripCount'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  Stream<Driver?> watchDriver(
    String driverId,
  ) {
    return _drivers.doc(driverId).snapshots().map(
      (snapshot) {
        final data = snapshot.data();

        if (!snapshot.exists || data == null) {
          return null;
        }

        return Driver(
          id: data['id'] as String? ?? snapshot.id,
          firstName:
              data['firstName'] as String? ?? '',
          lastName:
              data['lastName'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          photoUrl:
              data['photoUrl'] as String? ?? '',
          rating:
              (data['rating'] as num?)?.toDouble() ??
                  0,
          tripCount:
              (data['tripCount'] as num?)?.toInt() ??
                  0,
          isOnline:
              data['isOnline'] as bool? ?? false,
        );
      },
    );
  }

  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    await _drivers.doc(driverId).update(
      {
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> updateRating({
    required String driverId,
    required double rating,
    required int tripCount,
  }) async {
    await _drivers.doc(driverId).update(
      {
        'rating': rating,
        'tripCount': tripCount,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}