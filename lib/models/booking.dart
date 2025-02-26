class Booking {
  final String id;  // ✅ Unique ID
  final String gardener;
  String date;
  final String time;
  final String address;
  final List<String> services;
  final String? specialInstructions;
  String status;
  final double totalPrice; 

  Booking({
    required this.id,  // ✅ Generate a unique ID when creating a booking
    required this.gardener,
    required this.date,
    required this.time,
    required this.address,
    required this.services,
    this.specialInstructions,
    this.status = 'Pending',
    required this.totalPrice, 
  });
}
