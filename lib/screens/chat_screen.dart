import 'package:flutter/material.dart';
import '../services/pusher_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String authToken;

  const ChatScreen({
    required this.userId,
    required this.authToken,
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
  try {
    setState(() => _isLoading = true);
    
    _pusherService = PusherService(
      authToken: widget.authToken,
      onMessagesFetched: (messages) {
        // Ensure messages is never null
        final safeMessages = messages ?? [];
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
          SnackBar(content: Text('Error: ${error ?? "Unknown error"}')),
        );
      },
    );

    await _pusherService!.initPusher(widget.userId.toString());
    await _pusherService!.fetchMessages();
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
        widget.userId.toString(),
        message,
      );
      // Message will be added via Pusher update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _pusherService.fetchMessages();
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
                                content: message['content'],
                                timestamp: message['created_at'],
                                isMe: message['sender_id'] == widget.userId,
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