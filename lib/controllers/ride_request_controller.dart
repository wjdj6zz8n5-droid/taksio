import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_request.dart';
import '../repositories/ride_request_repository.dart';

class RideRequestController extends ChangeNotifier {
  RideRequestController({
    RideRequestRepository? rideRequestRepository,
  }) : _rideRequestRepository =
            rideRequestRepository ?? RideRequestRepository();

  final RideRequestRepository _rideRequestRepository;

  RideRequest? currentRequest;
  RideRequest? acceptedDriverRequest;

  List<RideRequest> searchingRequests = [];

  bool isCreatingRequest = false;
  bool isAcceptingRequest = false;
  bool isListeningForRequests = false;

  String? errorMessage;

  final Set<String> rejectedRequestIds = {};

  StreamSubscription<RideRequest?>? _currentRequestSubscription;
  StreamSubscription<List<RideRequest>>? _searchingRequestsSubscription;

  Future<bool> createRequest({
    required String customerId,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required double distanceKm,
    required int durationMinutes,
    required int estimatedPrice,
  }) async {
    if (isCreatingRequest) {
      return false;
    }

    isCreatingRequest = true;
    errorMessage = null;
    notifyListeners();

    try {
      final request =
          await _rideRequestRepository.createRideRequest(
        customerId: customerId,
        pickupLocation: pickupLocation,
        pickupAddress: pickupAddress,
        destinationLocation: destinationLocation,
        destinationAddress: destinationAddress,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        estimatedPrice: estimatedPrice,
      );

      currentRequest = request;
      _watchCurrentRequest(request.id);

      return true;
    } catch (error) {
      errorMessage =
          'Taksi çağrısı oluşturulamadı: $error';
      return false;
    } finally {
      isCreatingRequest = false;
      notifyListeners();
    }
  }

  void _watchCurrentRequest(String requestId) {
    _currentRequestSubscription?.cancel();

    _currentRequestSubscription =
        _rideRequestRepository
            .watchRideRequest(requestId)
            .listen(
      (request) {
        currentRequest = request;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage =
            'Çağrı durumu alınamadı: $error';
        notifyListeners();
      },
    );
  }

  void startListeningForSearchingRequests() {
    if (isListeningForRequests) {
      return;
    }

    isListeningForRequests = true;
    errorMessage = null;
    notifyListeners();

    _searchingRequestsSubscription =
        _rideRequestRepository
            .watchSearchingRequests()
            .listen(
      (requests) {
        searchingRequests = requests
            .where(
              (request) =>
                  !rejectedRequestIds.contains(request.id),
            )
            .toList();

        notifyListeners();
      },
      onError: (Object error) {
        isListeningForRequests = false;
        errorMessage =
            'Yeni yolculuk istekleri alınamadı: $error';
        notifyListeners();
      },
    );
  }

  Future<bool> acceptRequest({
    required String requestId,
    required String driverId,
    required String vehicleId,
  }) async {
    if (isAcceptingRequest) {
      return false;
    }

    isAcceptingRequest = true;
    errorMessage = null;
    notifyListeners();

    try {
      RideRequest? requestToAccept;

      for (final request in searchingRequests) {
        if (request.id == requestId) {
          requestToAccept = request;
          break;
        }
      }

      final accepted =
          await _rideRequestRepository.acceptRideRequest(
        requestId: requestId,
        driverId: driverId,
        vehicleId: vehicleId,
      );

      if (!accepted) {
        errorMessage =
            'Bu yolculuk başka bir şoför tarafından alındı.';
        return false;
      }

      if (requestToAccept != null) {
        acceptedDriverRequest = requestToAccept.copyWith(
          status: 'accepted',
          acceptedDriverId: driverId,
          acceptedVehicleId: vehicleId,
          acceptedAt: DateTime.now(),
        );
      }

      searchingRequests = searchingRequests
          .where((request) => request.id != requestId)
          .toList();

      return true;
    } catch (error) {
      errorMessage =
          'Yolculuk kabul edilemedi: $error';
      return false;
    } finally {
      isAcceptingRequest = false;
      notifyListeners();
    }
  }

  Future<bool> markDriverArrived({
    required String requestId,
  }) async {
    errorMessage = null;

    try {
      await _rideRequestRepository.updateStatus(
        requestId: requestId,
        status: 'driver_arrived',
      );

      final driverRequest = acceptedDriverRequest;

      if (driverRequest != null &&
          driverRequest.id == requestId) {
        acceptedDriverRequest = driverRequest.copyWith(
          status: 'driver_arrived',
        );
      }

      final customerRequest = currentRequest;

      if (customerRequest != null &&
          customerRequest.id == requestId) {
        currentRequest = customerRequest.copyWith(
          status: 'driver_arrived',
        );
      }

      notifyListeners();
      return true;
    } catch (error) {
      errorMessage =
          'Yolcuya ulaşıldı bilgisi gönderilemedi: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> startTrip({
    required String requestId,
  }) async {
    errorMessage = null;

    try {
      await _rideRequestRepository.updateStatus(
        requestId: requestId,
        status: 'trip_started',
      );

      final driverRequest = acceptedDriverRequest;

      if (driverRequest != null &&
          driverRequest.id == requestId) {
        acceptedDriverRequest = driverRequest.copyWith(
          status: 'trip_started',
        );
      }

      final customerRequest = currentRequest;

      if (customerRequest != null &&
          customerRequest.id == requestId) {
        currentRequest = customerRequest.copyWith(
          status: 'trip_started',
        );
      }

      notifyListeners();
      return true;
    } catch (error) {
      errorMessage =
          'Yolculuk başlatılamadı: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTrip({
    required String requestId,
  }) async {
    errorMessage = null;

    try {
      await _rideRequestRepository.updateStatus(
        requestId: requestId,
        status: 'trip_completed',
      );

      final driverRequest = acceptedDriverRequest;

      if (driverRequest != null &&
          driverRequest.id == requestId) {
        acceptedDriverRequest = driverRequest.copyWith(
          status: 'trip_completed',
        );
      }

      final customerRequest = currentRequest;

      if (customerRequest != null &&
          customerRequest.id == requestId) {
        currentRequest = customerRequest.copyWith(
          status: 'trip_completed',
        );
      }

      notifyListeners();
      return true;
    } catch (error) {
      errorMessage =
          'Yolculuk tamamlanamadı: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> rejectRequest({
    required String requestId,
    required String driverId,
  }) async {
    rejectedRequestIds.add(requestId);

    searchingRequests = searchingRequests
        .where((request) => request.id != requestId)
        .toList();

    notifyListeners();

    try {
      await _rideRequestRepository.rejectRideRequest(
        requestId: requestId,
        driverId: driverId,
      );
    } catch (error) {
      errorMessage =
          'Yolculuk reddedilemedi: $error';
      notifyListeners();
    }
  }

  Future<void> cancelCurrentRequest() async {
    final request = currentRequest;

    if (request == null) {
      return;
    }

    try {
      if (request.status == 'searching' ||
          request.status == 'accepted' ||
          request.status == 'driver_arrived') {
        await _rideRequestRepository.cancelRideRequest(
          requestId: request.id,
        );
      }

      await clearCurrentRequest();
    } catch (error) {
      errorMessage =
          'Taksi çağrısı iptal edilemedi: $error';
      notifyListeners();
    }
  }

  Future<void> clearCurrentRequest() async {
    await _currentRequestSubscription?.cancel();

    _currentRequestSubscription = null;
    currentRequest = null;
    errorMessage = null;

    notifyListeners();
  }

  Future<void> stopListeningForSearchingRequests() async {
    await _searchingRequestsSubscription?.cancel();

    _searchingRequestsSubscription = null;
    searchingRequests = [];
    isListeningForRequests = false;
    acceptedDriverRequest = null;

    notifyListeners();
  }

  void clearAcceptedDriverRequest() {
    acceptedDriverRequest = null;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) {
      return;
    }

    errorMessage = null;
    notifyListeners();
  }

  bool get hasActiveRequest {
    final status = currentRequest?.status;

    return status == 'searching' ||
        status == 'accepted' ||
        status == 'driver_arrived' ||
        status == 'trip_started';
  }

  bool get requestAccepted =>
      currentRequest?.status == 'accepted';

  bool get driverHasArrived =>
      currentRequest?.status == 'driver_arrived';

  bool get tripIsStarted =>
      currentRequest?.status == 'trip_started';

  bool get tripIsCompleted =>
      currentRequest?.status == 'trip_completed';

  RideRequest? get nextSearchingRequest {
    if (searchingRequests.isEmpty) {
      return null;
    }

    return searchingRequests.first;
  }

  @override
  void dispose() {
    _currentRequestSubscription?.cancel();
    _searchingRequestsSubscription?.cancel();
    super.dispose();
  }
}
