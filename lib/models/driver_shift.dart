import 'package:latlong2/latlong.dart';

class DriverShift {
  final String id;
  final String driverId;
  final String vehicleId;

  final DateTime startedAt;
  final DateTime? endedAt;

  final bool isActive;
  final LatLng? currentLocation;

  const DriverShift({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.startedAt,
    required this.endedAt,
    required this.isActive,
    required this.currentLocation,
  });

  DriverShift copyWith({
    String? id,
    String? driverId,
    String? vehicleId,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isActive,
    LatLng? currentLocation,
  }) {
    return DriverShift(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  factory DriverShift.fromMap(
    Map<String, dynamic> map,
  ) {
    final location = map['currentLocation'];

    return DriverShift(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      vehicleId: map['vehicleId'] as String,
      startedAt: DateTime.parse(
        map['startedAt'] as String,
      ),
      endedAt: map['endedAt'] == null
          ? null
          : DateTime.parse(
              map['endedAt'] as String,
            ),
      isActive: map['isActive'] as bool,
      currentLocation: location == null
          ? null
          : LatLng(
              (location['latitude'] as num).toDouble(),
              (location['longitude'] as num).toDouble(),
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'isActive': isActive,
      'currentLocation': currentLocation == null
          ? null
          : {
              'latitude': currentLocation!.latitude,
              'longitude': currentLocation!.longitude,
            },
    };
  }
}   