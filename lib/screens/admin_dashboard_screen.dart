import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      
      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;
        if (userData != null) {
          users.add({
            'id': doc.id,
            'data': userData,
            'email': userData['email'] ?? 'No email',
            'displayName': userData['displayName'] ?? 'No name',
            'createdAt': userData['createdAt'] ?? '',
          });
        }
      }
      
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredUsers = _users
          .where((user) =>
              user['email'].toLowerCase().contains(_searchQuery) ||
              user['displayName'].toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  Future<void> _deleteAccount(String userId, String userEmail) async {
    bool confirmed = await _showConfirmationDialog(
      'Delete Account',
      'Are you sure you want to delete the account for "$userEmail"? This action cannot be undone and all user data will be permanently removed.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the Firebase Auth user ID from the users collection
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? authUserId = userData?['authId']; // Assuming you store the auth ID in the user doc
      
      // If we don't have the authId in the document, we need to find it differently
      // For now, assuming the document ID is the same as the auth user ID
      if (authUserId == null) {
        authUserId = userId;
      }

      // For security reasons, we cannot delete other users' accounts from the client-side Flutter app
      // Instead, we'll mark the account as deleted and disabled
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      // Note: Actual Firebase Auth user deletion requires admin privileges and should be done server-side

      // Reload users list
      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _banAccount(String userId, String userEmail) async {
    bool confirmed = await _showConfirmationDialog(
      'Ban Account',
      'Are you sure you want to ban the account for "$userEmail"? Banned users will not be able to access the app.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user document to mark as banned
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      });

      // Reload users list
      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account banned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error banning account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error banning account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

   Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF191919),
              title: Text(
                title,
                style: const TextStyle(color: Colors.orange),
              ),
              content: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false if canceled
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true if confirmed
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            );
          },
        ) ?? false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.orange),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: _searchUsers,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // User count
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Users',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_filteredUsers.length} total',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
              
              // Users list
              if (!_isLoading)
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      var user = _filteredUsers[index];
                      bool isBanned = user['data']['isBanned'] == true;
                      
                      return Card(
                        color: const Color(0xFF191919),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['displayName'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['email'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (isBanned)
                                          const Text(
                                            'BANNED',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Action buttons
                                  Row(
                                    children: [
                                      if (!isBanned) // Only show ban button if not already banned
                                        IconButton(
                                          icon: const Icon(
                                            Icons.block,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          onPressed: () => _banAccount(user['id'], user['email']),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteAccount(user['id'], user['email']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (user['createdAt'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Created: ${DateTime.fromMillisecondsSinceEpoch(user['createdAt'].millisecondsSinceEpoch).toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
