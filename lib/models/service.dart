class Service {
  final String name;
  final String description;
  final double price;
  final String imageUrl; // Optional: if you have images of services

  Service({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0.0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}
