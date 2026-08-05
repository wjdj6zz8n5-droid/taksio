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

  bool get isSearching => status == 'searching';

  bool get isAccepted => status == 'accepted';

  bool get isCancelled => status == 'cancelled';

  RideRequest copyWith({
    String? id,
    String? customerId,
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? destinationLocation,
    String? destinationAddress,
    double? distanceKm,
    int? durationMinutes,
    int? estimatedPrice,
    String? status,
    String? acceptedDriverId,
    String? acceptedVehicleId,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      pickupLocation:
          pickupLocation ?? this.pickupLocation,
      pickupAddress:
          pickupAddress ?? this.pickupAddress,
      destinationLocation:
          destinationLocation ?? this.destinationLocation,
      destinationAddress:
          destinationAddress ?? this.destinationAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      estimatedPrice:
          estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      acceptedDriverId:
          acceptedDriverId ?? this.acceptedDriverId,
      acceptedVehicleId:
          acceptedVehicleId ?? this.acceptedVehicleId,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}