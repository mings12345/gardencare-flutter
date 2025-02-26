import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../services/pusher_service.dart';

class MessagingScreen extends StatefulWidget {
  final String gardenerName;

  const MessagingScreen({Key? key, required this.gardenerName}) : super(key: key);

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final List<Map<String, dynamic>> _homeowners = [
    {
      'name': 'John Doe',
      'lastMessage': 'Can you come tomorrow?',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'image': 'assets/images/homeowner1.jpg',
    },
    {
      'name': 'Jane Smith',
      'lastMessage': 'Thank you for the help!',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'image': 'assets/images/homeowner2.jpg',
    },
    {
      'name': 'Michael Lee',
      'lastMessage': 'Please send the estimate.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'image': 'assets/images/homeowner3.jpg',
    },
  ];

  String _searchQuery = '';

  // Helper to format the timestamp
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      return DateFormat('h:mm a').format(time); // "3:45 PM"
    } else {
      return DateFormat('MMM d').format(time); // "Apr 23"
    }
  }

  void _openChat(String homeownerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          homeownerName: homeownerName,
          gardenerName: widget.gardenerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHomeowners = _homeowners.where((homeowner) {
      return homeowner['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search homeowners...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredHomeowners.length,
              itemBuilder: (context, index) {
                final homeowner = filteredHomeowners[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(homeowner['image']),
                  ),
                  title: Text(
                    homeowner['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    homeowner['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    _formatTime(homeowner['time']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _openChat(homeowner['name']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Separate Chat Screen for a specific homeowner
class ChatScreen extends StatefulWidget {
  final String homeownerName;
  final String gardenerName;

  const ChatScreen({Key? key, required this.homeownerName, required this.gardenerName})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  // final PusherService _pusherService = PusherService();

  @override
  void initState() {
    super.initState();
    // _pusherService.subscribe('chat-${widget.homeownerName}-${widget.gardenerName}', (data) {
    //   final message = json.decode(data);
    //   setState(() {
    //     _messages.add({
    //       'sender': message['sender'],
    //       'message': message['message'],
    //       'time': DateTime.parse(message['time']),
    //     });
    //   });
    // });
  }

  @override
  void dispose() {
    // _pusherService.unsubscribe('chat-${widget.homeownerName}-${widget.gardenerName}');
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'gardener',
          'message': message,
          'time': DateTime.now(),
        });
      });
      _messageController.clear();
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time); // Format as "3:45 PM"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.homeownerName}'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isGardener = message['sender'] == 'gardener';
                return Align(
                  alignment: isGardener ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isGardener ? Colors.green.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isGardener
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message['time']),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
