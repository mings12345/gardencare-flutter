import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gardencare_app/models/user.dart';
import 'package:gardencare_app/models/message.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({required this.user, Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final int currentUserId = 1;
  late PusherChannelsFlutter _pusher;

  @override
  void initState() {
    super.initState();
    _initPusher();
    fetchMessages();
  }

  Future<void> _initPusher() async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      
      await _pusher.init(
        apiKey: '9b6cf6a0eecc032de3a0',
        cluster: 'ap1',
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
      );

      await _pusher.connect();
      await _pusher.subscribe(channelName: 'private-user.$currentUserId');
    } catch (e) {
      debugPrint('Pusher init error: $e');
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint('Connection state changed from $previousState to $currentState');
  }

  dynamic _onError(String message, int? code, dynamic error) {
    debugPrint('Pusher error: $message, code: $code, details: $error');
    return null;
  }

  void _onEvent(PusherEvent event) {
    try {
      if (event.data == null) return;
      
      final messageData = json.decode(event.data!);
      final newMessage = Message.fromJson(messageData);
      
      if (newMessage.senderId == widget.user.id || 
          newMessage.receiverId == widget.user.id) {
        setState(() {
          messages.insert(0, newMessage);
        });
      }
    } catch (e) {
      debugPrint('Message handling error: $e');
    }
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('Successfully subscribed to $channelName');
  }

  void _onMemberAdded(String channelName, dynamic member) {
    debugPrint('Member added to $channelName: $member');
  }

  void _onMemberRemoved(String channelName, dynamic member) {
    debugPrint('Member removed from $channelName: $member');
  }

  Future<void> fetchMessages() async {
  try {
    final response = await http.get(
      Uri.parse('http://192.168.2.34/api/messages/$currentUserId/${widget.user.id}'),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> messageList = responseData['messages'] ?? [];
      
      setState(() {
        messages = messageList.map((msg) => Message.fromJson(msg)).toList();
      });
    } else {
      debugPrint('Failed to fetch messages: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Failed to fetch messages: $e');
  }
}

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.2.34/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': currentUserId,
          'receiver_id': widget.user.id,
          'message': _controller.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _controller.clear();
      }
    } catch (e) {
      debugPrint('Failed to send message: $e');
    }
  }

  @override
  void dispose() {
    _pusher.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.user.name}')),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}