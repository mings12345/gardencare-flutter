class User {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String userType;
  final int id;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Print for debugging
    print('User from JSON: ${json['user_type']}');  // Debugging line

    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      userType: json['user_type'] ?? '',  // Make sure this is being set correctly
      id: json['id'] ?? 0,
    );
  }
}
