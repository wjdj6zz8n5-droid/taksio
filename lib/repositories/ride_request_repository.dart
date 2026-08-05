import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RideRequest {
  final String id;
  final String customerId;

  final LatLng pickupLocation;
  final String pickupAddress;

  final LatLng destinationLocation;
  final String destinationAddress;

  final double distanceKm;
  final int durationMinutes;
  final int estimatedPrice;

  final String status;
  final String? acceptedDriverId;
  final String? acceptedVehicleId;

  final DateTime createdAt;
  final DateTime? acceptedAt;

  const RideRequest({
    required this.id,
    required this.customerId,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.destinationLocation,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedPrice,
    required this.status,
    required this.acceptedDriverId,
    required this.acceptedVehicleId,
    required this.createdAt,
    required this.acceptedAt,
  });
}

class RideRequestRepository {
  RideRequestRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rideRequests =>
      _firestore.collection('ride_requests');

  Future<RideRequest> createRideRequest({
    required String customerId,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required double distanceKm,
    required int durationMinutes,
    required int estimatedPrice,
  }) async {
    final document = _rideRequests.doc();
    final now = DateTime.now();

    final request = RideRequest(
      id: document.id,
      customerId: customerId,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      destinationLocation: destinationLocation,
      destinationAddress: destinationAddress,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      estimatedPrice: estimatedPrice,
      status: 'searching',
      acceptedDriverId: null,
      acceptedVehicleId: null,
      createdAt: now,
      acceptedAt: null,
    );

    await document.set(
      {
        'id': request.id,
        'customerId': request.customerId,
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
        'status': request.status,
        'acceptedDriverId': null,
        'acceptedVehicleId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    return request;
  }

  Future<RideRequest?> getRideRequest(
    String requestId,
  ) async {
    final snapshot =
        await _rideRequests.doc(requestId).get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return _fromMap(
      id: snapshot.id,
      data: data,
    );
  }

  Stream<RideRequest?> watchRideRequest(
    String requestId,
  ) {
    return _rideRequests.doc(requestId).snapshots().map(
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

  Stream<List<RideRequest>> watchSearchingRequests() {
    return _rideRequests
        .where(
          'status',
          isEqualTo: 'searching',
        )
        .orderBy(
          'createdAt',
          descending: false,
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

  Future<bool> acceptRideRequest({
    required String requestId,
    required String driverId,
    required String vehicleId,
  }) async {
    final requestReference =
        _rideRequests.doc(requestId);

    return _firestore.runTransaction<bool>(
      (transaction) async {
        final snapshot =
            await transaction.get(requestReference);

        final data = snapshot.data();

        if (!snapshot.exists || data == null) {
          return false;
        }

        final currentStatus =
            data['status'] as String? ?? '';

        if (currentStatus != 'searching') {
          return false;
        }

        transaction.update(
          requestReference,
          {
            'status': 'accepted',
            'acceptedDriverId': driverId,
            'acceptedVehicleId': vehicleId,
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    await _rideRequests.doc(requestId).update(
      {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> cancelRideRequest({
    required String requestId,
  }) async {
    await updateStatus(
      requestId: requestId,
      status: 'cancelled',
    );
  }

  RideRequest _fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final pickup =
        data['pickupLocation'] as Map<String, dynamic>?;

    final destination =
        data['destinationLocation'] as Map<String, dynamic>?;

    final rawCreatedAt = data['createdAt'];
    final rawAcceptedAt = data['acceptedAt'];

    return RideRequest(
      id: data['id'] as String? ?? id,
      customerId:
          data['customerId'] as String? ?? '',
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
      status:
          data['status'] as String? ?? 'searching',
      acceptedDriverId:
          data['acceptedDriverId'] as String?,
      acceptedVehicleId:
          data['acceptedVehicleId'] as String?,
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
      acceptedAt: rawAcceptedAt is Timestamp
          ? rawAcceptedAt.toDate()
          : null,
    );
  }
}