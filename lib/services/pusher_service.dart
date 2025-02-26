/*import 'package:pusher_client/pusher_client.dart';

class PusherService {
  late PusherClient pusher;
  late Channel channel;

  PusherService() {
    pusher = PusherClient(
      'YOUR_PUSHER_APP_KEY',
      PusherOptions(
        cluster: 'YOUR_PUSHER_APP_CLUSTER',
        encrypted: true,
      ),
      autoConnect: false,
    );

    pusher.connect();
  }

  void subscribe(String channelName, Function onEvent) {
    channel = pusher.subscribe(channelName);
    channel.bind('new-message', (event) {
      if (event?.data != null) {
        onEvent(event!.data);
      }
    });
  }

  void unsubscribe(String channelName) {
    pusher.unsubscribe(channelName);
  }
}
*/