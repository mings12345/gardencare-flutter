import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/pusher_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final int otherUserId;
  final String authToken;
  final String? otherUserName;

  const ChatScreen({
    required this.userId,
    required this.authToken,
    required this.currentUserId,
    required this.otherUserId,
    this.otherUserName,
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
  String _otherUserName = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.otherUserName != null && widget.otherUserName!.isNotEmpty) {
      _otherUserName = widget.otherUserName!;
    }
    _initializeChat();
    _markMessagesAsRead();
  }

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
          final safeMessages = messages.map((message) {
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
              'message': message['message'] ?? '',
              'is_read': message['is_read'] ?? false,
              'read_at': message['read_at'] ?? '',
              'created_at': message['created_at'] ?? '',
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
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final appBarTitle = _otherUserName.isNotEmpty 
        ? 'Chat with $_otherUserName' 
        : 'Chat';
    
    return Scaffold(
      appBar: AppBar(
  title: Text(
    appBarTitle,
    style: GoogleFonts.poppins( // You can change 'roboto' to any other Google Font
      color: Colors.white,
      fontWeight: FontWeight.w500,
    ),
  ),
  backgroundColor: Colors.green[700], // Dark green
  elevation: 0,
  iconTheme: IconThemeData(color: Colors.white),
  actions: [
    IconButton(
      icon: Icon(Icons.refresh, color: Colors.white),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!, // Very light green
              Colors.green[100]!, // Light green
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _hasError
                  ? _buildErrorWidget(isLargeScreen)
                  : _isLoading
                      ? _buildLoadingWidget()
                      : _messages.isEmpty
                          ? _buildEmptyWidget(isLargeScreen)
                          : _buildMessageList(isLargeScreen),
            ),
            _buildMessageInput(isLargeScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isLargeScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.green[800], size: 48),
          SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 16,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 32 : 24,
                vertical: 12,
              ),
            ),
            onPressed: () {
              setState(() => _isLoading = true);
              _initializeChat();
            },
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isLargeScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nature, color: Colors.green[600], size: 48),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 16,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start your conversation about gardening!',
            style: TextStyle(
              fontSize: isLargeScreen ? 14 : 12,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isLargeScreen) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(
          content: message['message'] ?? '',
          timestamp: message['created_at'] ?? '',
          isMe: message['sender_id'] == widget.currentUserId,
          isLargeScreen: isLargeScreen,
        );
      },
    );
  }

  Widget _buildMessageInput(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.green[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.green[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.green[500]!),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 20 : 16,
                  vertical: isLargeScreen ? 16 : 12,
                ),
              ),
              minLines: 1,
              maxLines: 3,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: isLargeScreen ? 16 : 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[600],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              padding: EdgeInsets.all(isLargeScreen ? 12 : 8),
            ),
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
  final bool isLargeScreen;

  const MessageBubble({
    required this.content,
    required this.timestamp,
    required this.isMe,
    required this.isLargeScreen,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: isLargeScreen ? 16 : 8,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen 
                ? MediaQuery.of(context).size.width * 0.7 
                : MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
            decoration: BoxDecoration(
              color: isMe 
                  ? Colors.green[600] // Your messages - dark green
                  : Colors.green[100], // Their messages - light green
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.green[900],
                    fontSize: isLargeScreen ? 16 : 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.green[700],
                    fontSize: isLargeScreen ? 12 : 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}