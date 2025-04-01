class User {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String userType;
  final int id;
  final String? profilePictureUrl; // Nullable field

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.id,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      userType: json['user_type'] ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      profilePictureUrl: json['profile_picture_url'],
    );
  }
}
