import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  late PusherChannelsFlutter pusher;

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  Future<void> initPusher({String? channelName}) async {
    pusher = PusherChannelsFlutter.getInstance();

    try {
      await pusher.init(
        apiKey: "9b6cf6a0eecc032de3a0", // Replace with your actual Pusher App Key
        cluster: "ap1", // Replace with your Pusher Cluster
        onConnectionStateChange: (currentState, previousState) {
          print("Connection state changed: $currentState");
        },
        onError: (message, code, e) {
          print("Pusher Error: $message");
        },
      );

      await pusher.connect();
      print("✅ Pusher connected successfully!");

      // Subscribe to a channel if channelName is provided
      if (channelName != null) {
        await subscribeToChannel(channelName);
      }
    } catch (e) {
      print("❌ Pusher Exception: $e");
    }
  }

  Future<void> subscribeToChannel(String channelName) async {
    try {
      final channel = await pusher.subscribe(channelName: channelName);
      print("✅ Subscribed to channel: $channelName");

      // Check if onEvent is not null before using it
      if (channel.onEvent != null) {
        channel.onEvent!((event) {
          if (event != null) {
            print("🔔 Event received: ${event.eventName}, Data: ${event.data}");
          } else {
            print("⚠️ Received a null event");
          }
        });
      } else {
        print("⚠️ onEvent is null for channel: $channelName");
      }
    } catch (e) {
      print("❌ Error subscribing to channel: $e");
    }
  }

  Future<void> triggerEvent({
    required String channelName,
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Create a PusherEvent object
      final pusherEvent = PusherEvent(
        eventName: eventName,
        channelName: channelName,
        data: jsonEncode(data), // Encode data as a JSON string
      );

      // Trigger the event
      await pusher.trigger(pusherEvent);

      print("✅ Event triggered: $eventName on channel: $channelName");
    } catch (e) {
      print("❌ Error triggering event: $e");
    }
  }

  Future<void> unsubscribe(String channelName) async {
    try {
      await pusher.unsubscribe(channelName: channelName);
      print("✅ Unsubscribed from channel: $channelName");
    } catch (e) {
      print("❌ Error unsubscribing from channel: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await pusher.disconnect();
      print("✅ Pusher disconnected successfully!");
    } catch (e) {
      print("❌ Error disconnecting Pusher: $e");
    }
  }
}