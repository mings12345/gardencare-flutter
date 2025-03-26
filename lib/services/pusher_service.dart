import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  // Initialize Pusher connection
  Future<void> initPusher({required String channelName, String? userId}) async {
    try {
      await _pusher.init(
        apiKey: '9b6cf6a0eecc032de3a0', // Replace with your actual key
        cluster: 'ap1',
      );
      await _pusher.connect();
      await _subscribeToChannel(channelName);
    } catch (e) {
      print("Pusher Error: $e");
      rethrow;
    }
  }

  // Subscribe to a channel
  Future<void> _subscribeToChannel(String channelName) async {
    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        print("Pusher Event: ${event.data}");
      },
    );
  }

  // Corrected method to trigger events
  Future<void> triggerEvent({
    required String channelName,
    required String eventName,
    required dynamic data,
  }) async {
    try {
      // The correct way to trigger events in pusher_channels_flutter
      await _pusher.trigger(PusherEvent(
        channelName: channelName,
        eventName: eventName,
        data: data,
      ));
      print("✅ Event '$eventName' triggered on channel '$channelName'");
    } catch (e) {
      print("❌ Error triggering event: $e");
      rethrow;
    }
  }

  // Getter for the Pusher instance
  PusherChannelsFlutter get pusher => _pusher;

  // Disconnect Pusher
  Future<void> disconnect() async {
    await _pusher.disconnect();
  }
}