import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/pusher_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final int currentUserId;  // 👈 Your logged-in user
  final int otherUserId; 
  final String authToken;
  final String? otherUserName; // Added parameter for the other user's name

  const ChatScreen({
    required this.userId,
    required this.authToken,
    required this.currentUserId,
    required this.otherUserId,
    this.otherUserName, // Optional parameter for name
    Key? key,
  }) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  late PusherService _pusherService;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  late ScrollController _scrollController;
  final TextEditingController _messageController = TextEditingController();
  String _otherUserName = ''; // Store the name here

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initialize the name if provided
    if (widget.otherUserName != null && widget.otherUserName!.isNotEmpty) {
      _otherUserName = widget.otherUserName!;
    }
    _initializeChat();
    _markMessagesAsRead();
  }

  // Add this to your ChatScreen's initState
  Future<void> _markMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('${dotenv.get('BASE_URL')}/api/messages/mark-read'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender_id': widget.otherUserId,
          'receiver_id': widget.currentUserId,
        }),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);
      
      _pusherService = PusherService(
        authToken: widget.authToken,
        currentUserId: widget.currentUserId.toString(),
        onMessagesFetched: (messages) {
          print('Messages fetched: $messages');
          final safeMessages = messages.map((message) {
            // If we don't have the name yet, try to get it from the messages
            if (_otherUserName.isEmpty && 
                message['sender_id'] == widget.otherUserId &&
                message['sender']['name'] != null) {
              _otherUserName = message['sender']['name'];
            } else if (_otherUserName.isEmpty && 
                message['receiver_id'] == widget.otherUserId &&
                message['receiver']['name'] != null) {
              _otherUserName = message['receiver']['name'];
            }
            
            return {
              'id': message['id'],
              'sender_id': message['sender_id'],
              'receiver_id': message['receiver_id'],
              'message': message['message'] ?? '', // Handle null message
              'is_read': message['is_read'] ?? false, // Handle null is_read
              'read_at': message['read_at'] ?? '', // Handle null read_at
              'created_at': message['created_at'] ?? '', // Handle null created_at
              'sender': {
                'id': message['sender']['id'],
                'name': message['sender']['name'] ?? 'Unknown',
                'profile_picture_url': message['sender']['profile_picture_url'] ?? '',
              },
              'receiver': {
                'id': message['receiver']['id'],
                'name': message['receiver']['name'] ?? 'Unknown',
              },
            };
          }).toList();
          
          setState(() {
            _messages = safeMessages;
            _isLoading = false;
            _hasError = false;
          });
          _scrollToBottom();
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      );

      await _pusherService.initPusher(widget.currentUserId.toString());
      await _pusherService.fetchMessages(
        widget.currentUserId.toString(), 
        widget.otherUserId.toString(),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Initialization error: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    try {
      await _pusherService.sendMessage(
        widget.otherUserId.toString(),
        message,
      );
      // Optional: Refresh messages after sending
      await _pusherService.fetchMessages(
        widget.currentUserId.toString(),
        widget.otherUserId.toString(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _pusherService.disconnect(widget.userId.toString());
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create the app bar title based on available information
    final String appBarTitle = _otherUserName.isNotEmpty 
        ? 'Chat with $_otherUserName' 
        : 'Chat';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _pusherService.fetchMessages(
                widget.currentUserId.toString(), 
                widget.otherUserId.toString(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Failed to load messages'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _initializeChat();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return MessageBubble(
                                content: message['message'] ?? '',
                                timestamp: message['created_at'] ?? '',
                                isMe: message['sender_id'] == widget.currentUserId,
                              );
                            },
                          ),
          ),
          _buildMessageInput(),
        ],
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
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String content;
  final String timestamp;
  final bool isMe;

  const MessageBubble({
    required this.content,
    required this.timestamp,
    required this.isMe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}