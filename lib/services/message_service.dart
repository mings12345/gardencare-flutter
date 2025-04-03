/*import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessageService {
  final String baseUrl = dotenv.get('BASE_URL'); 
  late PusherClient pusher;
  late Channel channel;
  final Function(List<dynamic>) onMessagesReceived;
  final String authToken; // Your JWT or auth token

  MessageService({required this.onMessagesReceived, required this.authToken});

  Future<void> initPusher() async {
    try {
      pusher = PusherClient(
        "9b6cf6a0eecc032de3a0",
        PusherOptions(
          cluster: "ap1",
          auth: PusherAuth(
            '$baseUrl/broadcasting/auth',
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          ),
        ),
        enableLogging: true,
      );

      await pusher.connect();

      channel = pusher.subscribe('user.3');
      
      channel.bind('App\\Events\\NewMessage', (event) {
        // When new message arrives, trigger GET request
        fetchMessages();
      });
    } catch (e) {
      print("Pusher error: $e");
    }
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final messages = json.decode(response.body);
        onMessagesReceived(messages);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print("HTTP GET error: $e");
    }
  }

  void dispose() {
    pusher.disconnect();
  }

}*/