import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

import 'admin_community_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_route_utils.dart';
import 'community_member_profile_screen.dart';
import 'login_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';

  int get _bannedCount => _users.where((user) => user['isBanned'] == true).length;
  
  void _onNavTapped(int index) {
    if (index == 1) return;

    final Widget page;
    if (index == 0) {
      page = const AdminDashboardScreen();
    } else if (index == 2) {
      page = const AdminCommunityScreen();
    } else {
      page = const AdminFeedbackScreen();
    }

    Navigator.pushReplacement(
      context,
      buildAdminRoute(page),
    );
  }

  Future<void> _logoutAdmin() async {
    final shouldLogout = await _showConfirmationDialog(
      'Logout Admin',
      'Are you sure you want to log out of the admin panel?',
    );
    if (!shouldLogout) return;

    await _firebaseAuth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
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
    if (!await _showConfirmationDialog('Ban Account', 'Ban "$userEmail"?')) return;

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
    if (!await _showConfirmationDialog('Unban Account', 'Unban "$userEmail"?')) return;

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

  // ============== WEB UI METHODS WITH SIDEBAR NAVIGATION ==============

  Widget _buildSidebarNavItem(String label, int index, IconData icon) {
    final isSelected = index == 1;
    
    return InkWell(
      onTap: () => _onNavTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: Colors.orange.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.white54,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSidebarNavigation() {
    return Container(
      width: 280,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Admin Users',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'User Management',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          
          const SizedBox(height: 20),
          _buildSidebarNavItem('Overview', 0, Icons.dashboard_outlined),
          _buildSidebarNavItem('Users', 1, Icons.people_outline),
          _buildSidebarNavItem('Community', 2, Icons.forum_outlined),
          _buildSidebarNavItem('Feedback', 3, Icons.rate_review_outlined),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _logoutAdmin,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.red, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWebStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildWebStatCard(
              icon: Icons.people_alt_outlined,
              iconColor: Colors.blue,
              label: 'Total Users',
              value: _users.length.toString(),
              subtitle: 'All registered users',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebStatCard(
              icon: Icons.block,
              iconColor: Colors.orange,
              label: 'Banned Users',
              value: _bannedCount.toString(),
              subtitle: 'Users currently blocked',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFF0F0F0F),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          onChanged: _applyFilter,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users by name or email...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.orange),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildWebUsersGrid() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your search query',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildUserCard(_filteredUsers[index]),
        );
      },
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
      width: double.infinity,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebSidebarNavigation(),
                Expanded(
                  child: Column(
                    children: [
                      _buildWebSearchBar(),
                      _buildWebStatsRow(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadUsers(showLoader: false),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: _filteredUsers.map((user) => 
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: _buildUserCard(user),
                                )
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============== MOBILE UI (UNCHANGED) ==============

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 560 ? 3 : width >= 320 ? 2 : 1;
        const spacing = 10.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserCardsGrid(List<Map<String, dynamic>> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 2 : 1;
        const spacing = 12.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: users
              .map(
                (user) => SizedBox(
                  width: cardWidth,
                  child: _buildUserCard(user),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                                _buildStatsGrid(
                                  [
                                    _buildStatChip(
                                      'Total Users',
                                      _users.length.toString(),
                                      Colors.blue,
                                    ),
                                    _buildStatChip(
                                      'Banned',
                                      _bannedCount.toString(),
                                      Colors.orange,
                                    ),
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
                            _buildUserCardsGrid(_filteredUsers),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 800;
    
    if (isWeb && isLargeScreen) {
      return _buildWebLayout();
    }
    
    return _buildMobileLayout();
  }
}