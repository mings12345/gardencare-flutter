import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingService {
  static const String baseUrl = 'http://192.168.1.107/api';

  static Future<void> createBooking({
    required String type,
    required int homeownerId,
    required int gardenerId,
    required List<int> serviceIds,
    required String address,
    required String date,
    required String time,
    required double totalPrice,
    String? specialInstructions,
  }) async {
    final url = Uri.parse('$baseUrl/bookings');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'type': type,
        'homeowner_id': homeownerId,
        'gardener_id': gardenerId,
        'service_ids': serviceIds,
        'address': address,
        'date': date,
        'time': time,
        'total_price': totalPrice,
        'special_instructions': specialInstructions,
      }),
    );

    if (response.statusCode == 201) {
      print('Booking created successfully');
      print(json.decode(response.body));
    } else {
      print('Failed to create booking');
      print(json.decode(response.body));
    }
  }
}