import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gardencare_app/models/message.dart'; // Make sure to import your Message model

class MessageService {
  final String baseUrl = 'http://192.168.2.34/api';

  Future<void> sendMessage(Message message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message');
    }
  }

  Future<List<Message>> getMessages(int userId1, int userId2) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/$userId1/$userId2'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((message) => Message.fromJson(message)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }
}