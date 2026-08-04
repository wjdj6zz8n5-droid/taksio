class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String photoUrl;

  final double rating;
  final int tripCount;

  final bool isOnline;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.photoUrl,
    required this.rating,
    required this.tripCount,
    required this.isOnline,
  });

  String get fullName => '$firstName $lastName';

  String get shortName {
    if (lastName.isEmpty) return firstName;

    return '$firstName ${lastName[0]}.';
  }
}