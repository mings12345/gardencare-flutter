import 'package:flutter/material.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/screens/chat_screen.dart';
import 'package:gardencare_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<User> users = [];
  bool isLoading = true;
  String? infoMessage; // Changed from errorMessage to infoMessage
  int? currentUserId;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _fetchChatUsers();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('userId');
    });
  }

  Future<void> _fetchChatUsers() async {
    try {
      setState(() {
        isLoading = true;
        infoMessage = null;
      });

      List<User> allUsers = [];
      bool serviceProvidersAvailable = true;

      // Fetch gardeners
      try {
        final gardeners = await _authService.fetchGardeners();
        allUsers.addAll(gardeners);
      } catch (e) {
        print('Error fetching gardeners: $e');
        setState(() {
          infoMessage = 'Unable to load gardeners at this time';
        });
      }

      // Fetch service providers
      try {
        final providers = await _authService.fetchServiceProviders();
        allUsers.addAll(providers);
      } catch (e) {
        print('Service providers not available: $e');
        serviceProvidersAvailable = false;
      }

      // Filter current user and duplicates
      final filteredUsers = allUsers
          .where((user) => user.id != currentUserId)
          .toList();

      setState(() {
        users = filteredUsers;
        isLoading = false;
        
        if (users.isEmpty) {
          infoMessage = 'No professionals available for chat';
        } else if (!serviceProvidersAvailable) {
          infoMessage = 'Showing gardeners (service providers unavailable)';
        }
      });
    } catch (e) {
      setState(() {
        infoMessage = 'Error loading professionals';
        isLoading = false;
      });
      print('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Professionals"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchChatUsers,
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
                      Text("No professionals available"),
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
                              : 'Service Provider',
                        ),
                        trailing: Icon(Icons.chat_bubble_outline),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(user: user),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}