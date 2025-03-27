import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  final String baseUrl;
  final String publicKey;
  
  PaymentService({
    required this.baseUrl,
    required this.publicKey,
  });

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    required String bookingId,
    required String authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payment/intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: json.encode({
        'amount': amount,
        'description': description,
        'booking_id': bookingId,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required String paymentIntentId,
    required Map<String, dynamic> paymentMethod,
    required String returnUrl,
    required String authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payment/process'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: json.encode({
        'payment_intent_id': paymentIntentId,
        'payment_method': paymentMethod,
        'return_url': returnUrl,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process payment: ${response.body}');
    }
  }
}