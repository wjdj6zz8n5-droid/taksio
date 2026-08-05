import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Ride {
  final String id;
  final String rideRequestId;
  final String customerId;
  final String driverId;
  final String vehicleId;

  final LatLng pickupLocation;
  final String pickupAddress;

  final LatLng destinationLocation;
  final String destinationAddress;

  final double distanceKm;
  final int durationMinutes;
  final int estimatedPrice;
  final int? finalPrice;

  final String status;

  final DateTime createdAt;
  final DateTime? driverArrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const Ride({
    required this.id,
    required this.rideRequestId,
    required this.customerId,
    required this.driverId,
    required this.vehicleId,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.destinationLocation,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.status,
    required this.createdAt,
    required this.driverArrivedAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
  });
}

class RideRepository {
  RideRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  Future<Ride> createRide({
    required String rideRequestId,
    required String customerId,
    required String driverId,
    required String vehicleId,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required double distanceKm,
    required int durationMinutes,
    required int estimatedPrice,
  }) async {
    final document = _rides.doc();
    final now = DateTime.now();

    final ride = Ride(
      id: document.id,
      rideRequestId: rideRequestId,
      customerId: customerId,
      driverId: driverId,
      vehicleId: vehicleId,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      destinationLocation: destinationLocation,
      destinationAddress: destinationAddress,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      estimatedPrice: estimatedPrice,
      finalPrice: null,
      status: 'driver_assigned',
      createdAt: now,
      driverArrivedAt: null,
      startedAt: null,
      completedAt: null,
      cancelledAt: null,
    );

    await document.set(
      {
        'id': ride.id,
        'rideRequestId': ride.rideRequestId,
        'customerId': ride.customerId,
        'driverId': ride.driverId,
        'vehicleId': ride.vehicleId,
        'pickupLocation': {
          'latitude': pickupLocation.latitude,
          'longitude': pickupLocation.longitude,
        },
        'pickupAddress': pickupAddress,
        'destinationLocation': {
          'latitude': destinationLocation.latitude,
          'longitude': destinationLocation.longitude,
        },
        'destinationAddress': destinationAddress,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'estimatedPrice': estimatedPrice,
        'finalPrice': null,
        'status': ride.status,
        'createdAt': FieldValue.serverTimestamp(),
        'driverArrivedAt': null,
        'startedAt': null,
        'completedAt': null,
        'cancelledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    return ride;
  }

  Future<Ride?> getRide(
    String rideId,
  ) async {
    final snapshot = await _rides.doc(rideId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return _fromMap(
      id: snapshot.id,
      data: data,
    );
  }

  Stream<Ride?> watchRide(
    String rideId,
  ) {
    return _rides.doc(rideId).snapshots().map(
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

  Stream<List<Ride>> watchCustomerRides(
    String customerId,
  ) {
    return _rides
        .where(
          'customerId',
          isEqualTo: customerId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
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

  Stream<List<Ride>> watchDriverRides(
    String driverId,
  ) {
    return _rides
        .where(
          'driverId',
          isEqualTo: driverId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
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

  Future<void> markDriverArrived({
    required String rideId,
  }) async {
    await _rides.doc(rideId).update(
      {
        'status': 'driver_arrived',
        'driverArrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> startRide({
    required String rideId,
  }) async {
    await _rides.doc(rideId).update(
      {
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> completeRide({
    required String rideId,
    required int finalPrice,
  }) async {
    await _rides.doc(rideId).update(
      {
        'status': 'completed',
        'finalPrice': finalPrice,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> cancelRide({
    required String rideId,
  }) async {
    await _rides.doc(rideId).update(
      {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> updateDriverLocation({
    required String rideId,
    required LatLng location,
  }) async {
    await _rides.doc(rideId).update(
      {
        'driverLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Ride _fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final pickup =
        data['pickupLocation'] as Map<String, dynamic>?;

    final destination =
        data['destinationLocation'] as Map<String, dynamic>?;

    return Ride(
      id: data['id'] as String? ?? id,
      rideRequestId:
          data['rideRequestId'] as String? ?? '',
      customerId:
          data['customerId'] as String? ?? '',
      driverId:
          data['driverId'] as String? ?? '',
      vehicleId:
          data['vehicleId'] as String? ?? '',
      pickupLocation: LatLng(
        (pickup?['latitude'] as num?)?.toDouble() ?? 0,
        (pickup?['longitude'] as num?)?.toDouble() ?? 0,
      ),
      pickupAddress:
          data['pickupAddress'] as String? ?? '',
      destinationLocation: LatLng(
        (destination?['latitude'] as num?)?.toDouble() ?? 0,
        (destination?['longitude'] as num?)?.toDouble() ?? 0,
      ),
      destinationAddress:
          data['destinationAddress'] as String? ?? '',
      distanceKm:
          (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes:
          (data['durationMinutes'] as num?)?.toInt() ?? 0,
      estimatedPrice:
          (data['estimatedPrice'] as num?)?.toInt() ?? 0,
      finalPrice:
          (data['finalPrice'] as num?)?.toInt(),
      status:
          data['status'] as String? ?? 'driver_assigned',
      createdAt: _dateFromTimestamp(
        data['createdAt'],
      ) ?? DateTime.now(),
      driverArrivedAt: _dateFromTimestamp(
        data['driverArrivedAt'],
      ),
      startedAt: _dateFromTimestamp(
        data['startedAt'],
      ),
      completedAt: _dateFromTimestamp(
        data['completedAt'],
      ),
      cancelledAt: _dateFromTimestamp(
        data['cancelledAt'],
      ),
    );
  }

  DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}