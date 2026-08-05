import 'package:cloud_firestore/cloud_firestore.dart';

class RideRating {
  final String id;
  final String rideId;
  final String customerId;
  final String driverId;
  final int rating;
  final List<String> reasons;
  final String comment;
  final DateTime createdAt;

  const RideRating({
    required this.id,
    required this.rideId,
    required this.customerId,
    required this.driverId,
    required this.rating,
    required this.reasons,
    required this.comment,
    required this.createdAt,
  });
}

class RatingRepository {
  RatingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection('ratings');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  Future<RideRating> createRating({
    required String rideId,
    required String customerId,
    required String driverId,
    required int rating,
    required List<String> reasons,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError(
        'Puan 1 ile 5 arasında olmalıdır.',
      );
    }

    final ratingDocument = _ratings.doc();
    final driverReference = _drivers.doc(driverId);
    final now = DateTime.now();

    final rideRating = RideRating(
      id: ratingDocument.id,
      rideId: rideId,
      customerId: customerId,
      driverId: driverId,
      rating: rating,
      reasons: List<String>.unmodifiable(reasons),
      comment: comment.trim(),
      createdAt: now,
    );

    await _firestore.runTransaction<void>(
      (transaction) async {
        final driverSnapshot =
            await transaction.get(driverReference);

        final driverData = driverSnapshot.data();

        final currentRating =
            (driverData?['rating'] as num?)?.toDouble() ?? 0;

        final currentTripCount =
            (driverData?['tripCount'] as num?)?.toInt() ?? 0;

        final newTripCount = currentTripCount + 1;

        final newRating = currentTripCount == 0
            ? rating.toDouble()
            : ((currentRating * currentTripCount) + rating) /
                newTripCount;

        transaction.set(
          ratingDocument,
          {
            'id': rideRating.id,
            'rideId': rideRating.rideId,
            'customerId': rideRating.customerId,
            'driverId': rideRating.driverId,
            'rating': rideRating.rating,
            'reasons': rideRating.reasons,
            'comment': rideRating.comment,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          driverReference,
          {
            'rating': newRating,
            'tripCount': newTripCount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      },
    );

    return rideRating;
  }

  Future<RideRating?> getRatingForRide(
    String rideId,
  ) async {
    final snapshot = await _ratings
        .where(
          'rideId',
          isEqualTo: rideId,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return _fromMap(
      id: document.id,
      data: document.data(),
    );
  }

  Stream<List<RideRating>> watchDriverRatings(
    String driverId,
  ) {
    return _ratings
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

  RideRating _fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawReasons = data['reasons'];

    final reasons = rawReasons is List
        ? rawReasons.whereType<String>().toList()
        : <String>[];

    final rawCreatedAt = data['createdAt'];

    return RideRating(
      id: data['id'] as String? ?? id,
      rideId: data['rideId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      reasons: reasons,
      comment: data['comment'] as String? ?? '',
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
    );
  }
}