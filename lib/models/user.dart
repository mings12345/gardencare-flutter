class User {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String userType;
  final String account;
  final int id;
  final String? profilePictureUrl; // Nullable field
   final String? bio;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.account,
    required this.address,
    required this.userType,
    required this.id,
    this.profilePictureUrl,
     this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      userType: json['user_type'] ?? '',
      account: json['account'] ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      profilePictureUrl: json['profile_picture_url'],
       bio: json['bio'],
    );
  }
}
