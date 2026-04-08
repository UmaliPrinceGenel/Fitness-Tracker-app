import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_community_screen.dart';
import 'admin_dashboard_screen.dart';
import 'community_member_profile_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';

  int get _bannedCount => _users.where((user) => user['isBanned'] == true).length;
  int get _deletedCount => _users.where((user) => user['isDeleted'] == true).length;

  void _onNavTapped(int index) {
    if (index == 1) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            index == 0 ? const AdminDashboardScreen() : const AdminCommunityScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        final profile = data['profile'];
        final profileMap =
            profile is Map<String, dynamic> ? profile : <String, dynamic>{};

        return <String, dynamic>{
          'id': doc.id,
          'email': (data['email'] ?? '').toString(),
          'displayName': (data['displayName'] ??
                  profileMap['displayName'] ??
                  profileMap['name'] ??
                  'No name')
              .toString(),
          'photoURL':
              (data['photoURL'] ?? profileMap['photoURL'] ?? '').toString(),
          'isBanned': data['isBanned'] == true,
          'isDeleted': data['isDeleted'] == true,
          'createdAt': data['createdAt'],
        };
      }).toList()
        ..sort((a, b) => a['displayName']
            .toString()
            .toLowerCase()
            .compareTo(b['displayName'].toString().toLowerCase()));

      setState(() {
        _users = users;
        _applyFilter(_query, notify: false);
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilter(String query, {bool notify = true}) {
    final normalized = query.trim().toLowerCase();
    final filtered = _users.where((user) {
      return normalized.isEmpty ||
          user['email'].toString().toLowerCase().contains(normalized) ||
          user['displayName'].toString().toLowerCase().contains(normalized);
    }).toList();

    if (notify) {
      setState(() {
        _query = query;
        _filteredUsers = filtered;
      });
    } else {
      _query = query;
      _filteredUsers = filtered;
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content:
                Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('MMM d, yyyy - hh:mm a').format(value.toDate());
    }
    return 'Unknown date';
  }

  void _openUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMemberProfileScreen(
          userId: user['id'].toString(),
          initialDisplayName: user['displayName']?.toString(),
          initialProfileImageUrl:
              (user['photoURL']?.toString().isNotEmpty ?? false)
                  ? user['photoURL']?.toString()
                  : null,
        ),
      ),
    );
  }

  Future<void> _banAccount(String userId, String userEmail) async {
    if (!await _confirm('Ban Account', 'Ban "$userEmail"?')) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      });
      await _loadUsers(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User banned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error banning user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unbanAccount(String userId, String userEmail) async {
    if (!await _confirm('Unban Account', 'Unban "$userEmail"?')) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'bannedAt': FieldValue.delete(),
      });
      await _loadUsers(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unbanned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unbanning user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount(String userId, String userEmail) async {
    if (!await _confirm(
      'Delete Account',
      'Soft-delete "$userEmail"? This marks the account as deleted in Firestore.',
    )) {
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      await _loadUsers(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User marked as deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isBanned = user['isBanned'] == true;
    final isDeleted = user['isDeleted'] == true;
    final email = user['email']?.toString().isNotEmpty == true
        ? user['email'].toString()
        : 'No email';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange.withOpacity(0.15),
                backgroundImage: (user['photoURL']?.toString().isNotEmpty ?? false)
                    ? NetworkImage(user['photoURL'].toString())
                    : null,
                child: (user['photoURL']?.toString().isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['displayName']?.toString() ?? 'No name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isBanned) _buildStatusPill('Banned', Colors.red),
                        if (isDeleted)
                          _buildStatusPill('Deleted', Colors.deepOrange),
                        _buildStatusPill(
                          'Joined ${_formatTimestamp(user['createdAt'])}',
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionChip(
                label: 'View Profile',
                icon: Icons.visibility_outlined,
                color: Colors.blue,
                onTap: () => _openUserProfile(user),
              ),
              _buildActionChip(
                label: isBanned ? 'Unban' : 'Ban',
                icon: isBanned ? Icons.lock_open : Icons.block,
                color: isBanned ? Colors.green : Colors.orange,
                onTap: () => isBanned
                    ? _unbanAccount(user['id'], email)
                    : _banAccount(user['id'], email),
              ),
              _buildActionChip(
                label: 'Delete',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () => _deleteAccount(user['id'], email),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Admin Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _loadUsers(showLoader: false),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.orange),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 2 : 1;
                  final cardAspectRatio = columns == 1 ? 0.88 : 1.28;
                  return RefreshIndicator(
                    onRefresh: () => _loadUsers(showLoader: false),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'User Management',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Monitor all users, open their profile, and control access with ban and unban actions.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF191919),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    onChanged: _applyFilter,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search users...',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildStatChip('Total', _users.length.toString(), Colors.blue),
                                    _buildStatChip('Banned', _bannedCount.toString(), Colors.orange),
                                    _buildStatChip('Deleted', _deletedCount.toString(), Colors.red),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_filteredUsers.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No users matched your search.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredUsers.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: cardAspectRatio,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildUserCard(_filteredUsers[index]),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
