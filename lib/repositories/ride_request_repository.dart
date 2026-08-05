import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_request.dart';

class RideRequestRepository {
  RideRequestRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _rideRequests =>
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

    await document.set({
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
      'status': 'searching',
      'acceptedDriverId': null,
      'acceptedVehicleId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
      'driverArrivedAt': null,
      'tripStartedAt': null,
      'tripCompletedAt': null,
      'cancelledAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

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
    return _rideRequests
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return _fromMap(
        id: snapshot.id,
        data: data,
      );
    });
  }

  Stream<List<RideRequest>>
      watchSearchingRequests() {
    return _rideRequests
        .where(
          'status',
          isEqualTo: 'searching',
        )
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map(
            (document) => _fromMap(
              id: document.id,
              data: document.data(),
            ),
          )
          .toList();

      requests.sort(
        (first, second) =>
            first.createdAt.compareTo(
          second.createdAt,
        ),
      );

      return requests;
    });
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
            'acceptedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  Future<void> rejectRideRequest({
    required String requestId,
    required String driverId,
  }) async {
    await _rideRequests
        .doc(requestId)
        .collection('rejections')
        .doc(driverId)
        .set({
      'driverId': driverId,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'driver_arrived') {
      updates['driverArrivedAt'] =
          FieldValue.serverTimestamp();
    }

    if (status == 'trip_started') {
      updates['tripStartedAt'] =
          FieldValue.serverTimestamp();
    }

    if (status == 'trip_completed') {
      updates['tripCompletedAt'] =
          FieldValue.serverTimestamp();
    }

    if (status == 'cancelled') {
      updates['cancelledAt'] =
          FieldValue.serverTimestamp();
    }

    await _rideRequests.doc(requestId).update(
          updates,
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
    final pickupData =
        data['pickupLocation'];

    final destinationData =
        data['destinationLocation'];

    final pickup = pickupData is Map
        ? Map<String, dynamic>.from(pickupData)
        : <String, dynamic>{};

    final destination = destinationData is Map
        ? Map<String, dynamic>.from(destinationData)
        : <String, dynamic>{};

    return RideRequest(
      id: data['id'] as String? ?? id,
      customerId:
          data['customerId'] as String? ?? '',
      pickupLocation: LatLng(
        (pickup['latitude'] as num?)
                ?.toDouble() ??
            0,
        (pickup['longitude'] as num?)
                ?.toDouble() ??
            0,
      ),
      pickupAddress:
          data['pickupAddress'] as String? ?? '',
      destinationLocation: LatLng(
        (destination['latitude'] as num?)
                ?.toDouble() ??
            0,
        (destination['longitude'] as num?)
                ?.toDouble() ??
            0,
      ),
      destinationAddress:
          data['destinationAddress']
                  as String? ??
              '',
      distanceKm:
          (data['distanceKm'] as num?)
                  ?.toDouble() ??
              0,
      durationMinutes:
          (data['durationMinutes'] as num?)
                  ?.toInt() ??
              0,
      estimatedPrice:
          (data['estimatedPrice'] as num?)
                  ?.toInt() ??
              0,
      status:
          data['status'] as String? ??
              'searching',
      acceptedDriverId:
          data['acceptedDriverId'] as String?,
      acceptedVehicleId:
          data['acceptedVehicleId'] as String?,
      createdAt: _toDateTime(
            data['createdAt'],
          ) ??
          DateTime.now(),
      acceptedAt: _toDateTime(
        data['acceptedAt'],
      ),
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}