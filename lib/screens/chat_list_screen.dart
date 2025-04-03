import 'package:flutter/material.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/screens/chat_screen.dart';
import 'package:gardencare_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<User> users = [];
  bool isLoading = true;
  String? infoMessage;
  int? currentUserId;
  String? currentUserRole;
  String? authToken;
  final AuthService _authService = AuthService();
  
  // Track unread messages count for each user
  Map<int, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Start periodic checks for new messages
    _startMessageChecker();
  }

  @override
  void dispose() {
    // Cancel any ongoing timers or listeners
    _messageTimer?.cancel();
    super.dispose();
  }

  Timer? _messageTimer;
  
  void _startMessageChecker() {
  // Check immediately when screen loads
  _checkForNewMessages();
  
  // Then check every 30 seconds (adjust as needed)
  _messageTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    if (!mounted) return;
    _checkForNewMessages();
  });
}

  Future<void> _checkForNewMessages() async {
  if (currentUserId == null) return;
  
  try {
    final counts = await _authService.getUnreadCounts(currentUserId!);
    
    if (mounted) {
      setState(() {
        unreadCounts = counts;
      });
    }
  } catch (e) {
    print('Error checking messages: $e');
    // Optionally show a snackbar if you want to notify the user
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Failed to check for new messages')));
  }
}

  Future<void> _initializeData() async {
    await _loadCurrentUserData();
    await _fetchChatUsers();
    await _checkForNewMessages();
  }

  Future<void> _loadCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('userId');
      authToken = prefs.getString('token');
      currentUserRole = prefs.getString('userRole');
    });
  }

  Future<void> _fetchChatUsers() async {
    try {
      setState(() {
        isLoading = true;
        infoMessage = null;
      });

      final role = currentUserRole?.toLowerCase();
      List<User> filteredUsers = [];

      if (role == 'homeowner') {
        try {
          filteredUsers.addAll(await _authService.fetchGardeners());
        } catch (e) {
          print('Error fetching gardeners: $e');
        }

        try {
          filteredUsers.addAll(await _authService.fetchServiceProviders());
        } catch (e) {
          print('Error fetching service providers: $e');
        }
      } 
      else if (role == 'gardener' || role == 'service_provider') {
        try {
          filteredUsers.addAll(await _authService.fetchHomeowners());
        } catch (e) {
          print('Error fetching homeowners: $e');
        }
      }

      filteredUsers = filteredUsers
          .where((user) => user.id != currentUserId)
          .toSet()
          .toList();

      setState(() {
        users = filteredUsers;
        isLoading = false;
        
        if (users.isEmpty) {
          infoMessage = role == 'homeowner' 
              ? 'No professionals available for chat'
              : 'No homeowners available for chat';
        }
      });
    } catch (e) {
      setState(() {
        infoMessage = 'Error loading users';
        isLoading = false;
      });
      print('Error in _fetchChatUsers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = "Available ";
    appBarTitle += currentUserRole == 'homeowner' ? "Professionals" : "Homeowners";

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchChatUsers();
              _checkForNewMessages();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (infoMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    infoMessage!,
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("No users available"),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchChatUsers,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final unreadCount = unreadCounts[user.id] ?? 0;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profilePictureUrl != null
                              ? NetworkImage(user.profilePictureUrl!)
                              : AssetImage('assets/images/default_profile.png') 
                                  as ImageProvider,
                          child: user.profilePictureUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(
                          user.userType == 'gardener' 
                              ? 'Gardener' 
                              : user.userType == 'service_provider'
                                ? 'Service Provider'
                                : 'Homeowner',
                        ),
                        trailing: _buildNotificationBadge(unreadCount),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final currentToken = prefs.getString('token') ?? '';
                          final currentUserId = prefs.getInt('userId');
                          
                          if (currentToken.isEmpty || currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Authentication required'))
                            );
                            return;
                          }

                          // Clear unread count when opening chat
                          if (unreadCount > 0) {
                            setState(() {
                              unreadCounts[user.id] = 0;
                            });
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUserId: currentUserId,
                                otherUserId: user.id,
                                authToken: currentToken,
                                userId: user.id,
                              ),
                            ),
                          ).then((_) {
                            // When returning from chat screen, check for new messages
                            _checkForNewMessages();
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationBadge(int count) {
    if (count <= 0) {
      return Icon(Icons.chat_bubble_outline);
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.chat_bubble_outline),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
    ],
    );
  }
}