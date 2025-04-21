import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class PusherService {
  final String baseUrl = dotenv.get('BASE_URL');
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final String authToken;
  final Function(List<dynamic>) onMessagesFetched;
  final Function(Map<String, dynamic>)? onBookingReceived; 
  final Function(Map<String, dynamic>)? onBookingUpdated;
  final Function(String)? onError;
  // Define _channel field
  late PusherChannel _channel;
  late String _currentUserId; 

  PusherService({
    required this.authToken,
    required this.onMessagesFetched,
    this.onError,
    this.onBookingReceived,
     this.onBookingUpdated, 
    required String currentUserId,
  }) : _currentUserId = currentUserId;
  
  Future<void> initPusher(String userId) async {

    print('Initializing Pusher with user ID: $userId');
    try {

    if (userId.isEmpty) {
      throw Exception("User ID cannot be empty");
    }
      // Initialize Pusher
      await pusher.init(
        apiKey: '9b6cf6a0eecc032de3a0',
        cluster: 'ap1',
        onAuthorizer: (String channelName, String socketId, dynamic options) async {
        print("Authorizing channel: $channelName, socket: $socketId");
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/api/broadcasting/auth'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'socket_id': socketId,
              'channel_name': channelName,
            }),
          );
          
          // If we get a redirect, it's likely an auth issue
    if (response.statusCode == 302) {
      throw Exception("Authentication token expired or invalid");
    }
          print("Auth response: ${response.statusCode}, Body: ${response.body}");

          if (response.statusCode != 200) {
            throw Exception("Auth failed: ${response.statusCode}");
          }

          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['auth'] == null) {
            throw Exception("Missing 'auth' key in response");
          }

          return jsonResponse; // Must include 'auth' key
        } catch (e) {
          print("⚠️ Authorization error: $e");
          rethrow;
        }
      },
       onSubscriptionError: (String message, dynamic e) {
          print('Subscription error: $message, $e');
        },
        onConnectionStateChange: (currentState, previousState) {
          print('Pusher connection state: $previousState -> $currentState');
        if (currentState == 'CONNECTED') {
          print('Successfully connected to Pusher!');
        } else if (currentState == 'FAILED') {
          print('Connection failed - check credentials and network');
        }
        },
        onError: (String message, int? code, dynamic e) {
          print('Pusher error: $message (code: $code, exception: $e)');
          onError?.call(message);
        },
        onEvent: (event) {
          print('All Pusher events: ${event.eventName} - ${event.data}');
        },
      );

      // Connect to Pusher
      await pusher.connect();

    // Subscribe to private channel and bind events
        _channel = await pusher.subscribe(
          channelName: 'private-user.$userId',
          onEvent: (event) {
            // Handle all events
            _handleEvent(event);
            print(event);
            // Specifically handle NewMessage events
             switch (event.eventName) {
      case 'NewMessage':
        _handleMessageEvent(event);
        break;
      case 'NewBooking':
        _handleBookingEvent(event);
        break;
      case 'BookingUpdated':
        _handleBookingUpdateEvent(event);
        break;
      default:
        print('Unhandled event type: ${event.eventName}');
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

  void _handleBookingUpdateEvent(PusherEvent event) {
  try {
    final updatedBooking = json.decode(event.data);
    print('Booking update received: $updatedBooking');
    
    if (onBookingUpdated != null) {
      onBookingUpdated!(updatedBooking);
    }
  } catch (e) {
    print('Error handling booking update: $e');
    onError?.call('Failed to process booking update: ${e.toString()}');
  }
}
      void _handleMessageEvent(PusherEvent event) {
        print('New message event: ${event.data}');
        
    try {
      // Parse the event data (which comes from broadcastWith() in PHP)
      final Map<String, dynamic> messageData = json.decode(event.data);
      
      // Extract sender and receiver IDs from the message
      final String senderId = messageData['sender_id']?.toString() ?? '';
      final String receiverId = messageData['receiver_id']?.toString() ?? '';
      
      if (senderId.isEmpty || receiverId.isEmpty) {
        throw Exception('Missing sender_id or receiver_id in message data');
      }
      
      // Fetch the updated conversation
      fetchMessages(senderId, receiverId);
      
    } catch (e) {
      print('Error handling message event: $e');
      onError?.call('Failed to process new message: ${e.toString()}');
    }
      }

       // New method to handle booking events
  void _handleBookingEvent(PusherEvent event) {
    print('Booking event received: ${event.eventName} - ${event.data}');
    
    try {
      // Parse the event data
      final Map<String, dynamic> bookingData = json.decode(event.data);
      
      // Notify using the callback
      if (onBookingReceived != null) {
        onBookingReceived!(bookingData);
      }
      
    } catch (e) {
      print('Error handling booking event: $e');
      onError?.call('Failed to process booking event: ${e.toString()}');
    }
  }

   Future<List<dynamic>> fetchMessages(String senderId, String recipientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$senderId/$recipientId'), // Use dynamic IDs
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('messages') && jsonResponse['messages'] is List) {
          final List<dynamic> messages = jsonResponse['messages'];
          
          onMessagesFetched(messages);
          return messages;
        } else {
          throw Exception('Unexpected response structure: ${response.body}');
        }
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      onError?.call('Failed to fetch messages: ${e.toString()}');
      rethrow;
    }
  }

    Future<List<dynamic>> fetchUserBookings(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/get_pending_bookings/$userId'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (jsonResponse.containsKey('bookings') && jsonResponse['bookings'] is List) {
        return jsonResponse['bookings'];
      } else {
        throw Exception('Unexpected response structure: ${response.body}');
      }
    } else {
      throw Exception('Failed to load bookings: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching user bookings: $e');
    onError?.call('Failed to fetch bookings: ${e.toString()}');
    rethrow;
  }
}

     // New method to fetch booking details
  Future<Map<String, dynamic>> fetchBookingDetails(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/$bookingId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load booking details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching booking details: $e');
      onError?.call('Failed to fetch booking details: ${e.toString()}');
      rethrow;
    }
  }

     // Method to update a booking status
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/bookings/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update booking status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating booking status: $e');
      onError?.call('Failed to update booking status: ${e.toString()}');
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
        'sender_id': _currentUserId.toString(), // Use the initialized field
        'receiver_id': recipientId, // Changed from 'recipient_id'
        'message': content, // Ensure this matches Laravel's expected key
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
    // Store the channel name before unsubscribing if needed
    final channelName = 'private-user.$userId'; // Use the same pattern you used in initPusher()
    
    // No need to explicitly unbind in most cases - unsubscribing handles it
    await pusher.unsubscribe(channelName: channelName);
    print('Unsubscribed from channel: $channelName');
    await pusher.disconnect();
    print('Pusher disconnected successfully');
  } catch (e) {
    print('Error disconnecting Pusher: $e');
    rethrow;
  }
}
}