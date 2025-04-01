import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class PusherService {
  final String baseUrl = dotenv.get('BASE_URL');
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final String authToken;
  final Function(List<dynamic>) onMessagesFetched;
  final Function(String)? onError;
  late PusherChannel _channel;

  PusherService({
    required this.authToken,
    required this.onMessagesFetched,
    this.onError,
  });

  Future<void> initPusher(String userId) async {
    try {

    if (userId.isEmpty) {
      throw Exception("User ID cannot be empty");
    }
      // Initialize Pusher
      await pusher.init(
        apiKey: '9b6cf6a0eecc032de3a0',
        cluster: 'ap1',
        onConnectionStateChange: (currentState, previousState) {
          print('Connection state changed: $currentState (previous: $previousState)');
        },
        onError: (String message, int? code, dynamic e) {
          print('Pusher error: $message (code: $code, exception: $e)');
          onError?.call(message);
        },
      );

      // Connect to Pusher
      await pusher.connect();

    // Subscribe to private channel and bind events
        _channel = await pusher.subscribe(
          channelName: 'user.$userId',
          onEvent: (event) {
            // Handle all events
            _handleEvent(event);
            print(event);
            // Specifically handle NewMessage events
            if (event.eventName == 'App\\Events\\NewMessage') {
              _handleMessageEvent(event);
            }
          },
        );

      print('Pusher initialized successfully');
    } catch (e) {
      print('Pusher initialization error: $e');
      onError?.call('Failed to initialize Pusher: ${e.toString()}');
      rethrow;
    }
  }

  void _handleEvent(PusherEvent event) {
    print('Event received: ${event.eventName} - ${event.data}');
  }

  void _handleMessageEvent(PusherEvent event) {
    print('New message event: ${event.data}');
    fetchMessages();
  }

  Future<List<dynamic>> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/2/3'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final messages = json.decode(response.body) as List<dynamic>;
        onMessagesFetched(messages);
        return messages;
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      onError?.call('Failed to fetch messages: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> sendMessage(String recipientId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'recipient_id': recipientId,
          'content': content,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      onError?.call('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

Future<void> disconnect(String userId) async {
  try {
    if (_channel != null) {
      // Store the channel name before unsubscribing if needed
      final channelName = 'user.$userId'; // Use the same pattern you used in initPusher()
      
      // No need to explicitly unbind in most cases - unsubscribing handles it
      await pusher.unsubscribe(channelName: channelName);
      print('Unsubscribed from channel: $channelName');
    } else {
      print('No channel to unsubscribe from');
    } 
    await pusher.disconnect();
    print('Pusher disconnected successfully');
  } catch (e) {
    print('Error disconnecting Pusher: $e');
    rethrow;
  }
}
}