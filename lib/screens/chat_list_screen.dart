import 'package:flutter/material.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/screens/chat_screen.dart';
import 'package:gardencare_app/models/user.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(
          appBarTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[800],
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
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
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
        ),
      );
    }

    return Column(
      children: [
        if (infoMessage != null)
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[800]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    infoMessage!,
                    style: GoogleFonts.poppins(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
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
                      Icon(Icons.people_alt_outlined, 
                          size: 64, 
                          color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "No users available",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchChatUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Refresh',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final unreadCount = unreadCounts[user.id] ?? 0;
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.green[100],
                            backgroundImage: user.profilePictureUrl != null
                                ? NetworkImage(user.profilePictureUrl!)
                                : null,
                            child: user.profilePictureUrl == null
                                ? Text(
                                    user.name[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            user.userType == 'gardener' 
                                ? 'Gardener' 
                                : user.userType == 'service_provider'
                                  ? 'Service Provider'
                                  : 'Homeowner',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          trailing: _buildNotificationBadge(unreadCount),
                          onTap: () async {
                            // [Keep all existing onTap code exactly the same]
                            final prefs = await SharedPreferences.getInstance();
                            final currentToken = prefs.getString('token') ?? '';
                            final currentUserId = prefs.getInt('userId');
                            
                            if (currentToken.isEmpty || currentUserId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Authentication required'))
                              );
                              return;
                            }

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
                              _checkForNewMessages();
                            });
                          },
                        ),
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
      return Icon(Icons.chat_bubble_outline, color: Colors.grey[500]);
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.chat_bubble, color: Colors.green[700]),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }
}