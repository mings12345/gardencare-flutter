import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  late PusherChannelsFlutter pusher;

  Future<void> initPusher({String? channelName}) async {
    pusher = PusherChannelsFlutter.getInstance();

    try {
      await pusher.init(
        apiKey: "30c5136a5ba9d5617c54", // Replace with your actual Pusher App Key
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

      // Listen for events on the channel
      channel.onEvent!((event) {
        if (event != null) {
          print("🔔 Event received: ${event.eventName}, Data: ${event.data}");
        } else {
          print("⚠️ Received a null event");
        }
      });
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