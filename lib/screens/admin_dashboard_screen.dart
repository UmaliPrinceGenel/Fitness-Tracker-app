import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_community_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_route_utils.dart';
import 'admin_users_screen.dart';
import 'community_member_profile_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  int _totalFeedbackCount = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';

  int get _bannedUsersCount =>
      _users.where((user) => user['isBanned'] == true).length;

  void _onNavTapped(int index) {
    if (index == 0) return;

    final Widget page;
    if (index == 1) {
      page = const AdminUsersScreen();
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore
            .collection('community_posts')
            .orderBy('timePosted', descending: true)
            .get(),
        _firestore.collection('user_feedback').get(),
      ]);

      final usersSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final postsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final feedbackSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;

      final users = usersSnapshot.docs.map((doc) {
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

      final posts = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'userId': (data['userId'] ?? '').toString(),
          'username': (data['username'] ?? 'Unknown user').toString(),
          'caption': (data['caption'] ?? '').toString(),
          'profileImage': (data['profileImage'] ?? '').toString(),
          'postImages': (data['postImages'] as List<dynamic>? ?? []).cast<String>(),
          'postVideos': (data['postVideos'] as List<dynamic>? ?? []).cast<String>(),
          'likes': (data['likes'] as num?)?.toInt() ?? 0,
          'commentCount': (data['commentCount'] as num?)?.toInt() ?? 0,
          'timePosted': data['timePosted'],
        };
      }).toList();

      setState(() {
        _users = users;
        _posts = posts;
        _totalFeedbackCount = feedbackSnapshot.size;
        _applySearchFilter(_searchQuery, notify: false);
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
          content: Text('Error loading admin dashboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applySearchFilter(String query, {bool notify = true}) {
    final normalized = query.trim().toLowerCase();
    final filteredUsers = _users.where((user) {
      return normalized.isEmpty ||
          user['email'].toString().toLowerCase().contains(normalized) ||
          user['displayName'].toString().toLowerCase().contains(normalized);
    }).toList();

    final filteredPosts = _posts.where((post) {
      return normalized.isEmpty ||
          post['username'].toString().toLowerCase().contains(normalized) ||
          post['caption'].toString().toLowerCase().contains(normalized);
    }).toList();

    if (notify) {
      setState(() {
        _searchQuery = query;
        _filteredUsers = filteredUsers;
        _filteredPosts = filteredPosts;
      });
    } else {
      _searchQuery = query;
      _filteredUsers = filteredUsers;
      _filteredPosts = filteredPosts;
    }
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
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.orange),
                ),
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
    final userId = user['id']?.toString() ?? user['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMemberProfileScreen(
          userId: userId,
          initialDisplayName: user['displayName']?.toString() ??
              user['username']?.toString(),
          initialProfileImageUrl:
              (user['photoURL']?.toString().isNotEmpty ?? false)
                  ? user['photoURL']?.toString()
                  : ((user['profileImage']?.toString().isNotEmpty ?? false)
                      ? user['profileImage']?.toString()
                      : null),
        ),
      ),
    );
  }

  Future<void> _banAccount(String userId, String userEmail) async {
    final confirmed = await _showConfirmationDialog(
      'Ban Account',
      'Are you sure you want to ban "$userEmail"?',
    );
    if (!confirmed) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      });
      await _loadDashboardData(showLoader: false);
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
    final confirmed = await _showConfirmationDialog(
      'Unban Account',
      'Allow "$userEmail" to use the app again?',
    );
    if (!confirmed) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'bannedAt': FieldValue.delete(),
      });
      await _loadDashboardData(showLoader: false);
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

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Post',
      'Delete this community post by "${post['username']}"?',
    );
    if (!confirmed) return;

    try {
      final mediaUrls = <String>[
        ...(post['postImages'] as List<String>),
        ...(post['postVideos'] as List<String>),
      ];

      for (final mediaUrl in mediaUrls) {
        try {
          final uri = Uri.parse(mediaUrl);
          final pathSegments = uri.path.split('/');
          final bucketIndex = pathSegments.indexOf('community-posts');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await _supabase.storage.from('community-posts').remove([filePath]);
          }
        } catch (_) {}
      }

      final commentsSnapshot = await _firestore
          .collection('community_posts')
          .doc(post['id'])
          .collection('comments')
          .get();
      final batch = _firestore.batch();
      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }
      await batch.commit();

      await _firestore.collection('community_posts').doc(post['id']).delete();
      await _loadDashboardData(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildSummaryCard({
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final imageUrls = (post['postImages'] as List<String>);
    final videoUrls = (post['postVideos'] as List<String>);
    final allMediaCount = imageUrls.length + videoUrls.length;

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
                radius: 22,
                backgroundColor: Colors.orange.withOpacity(0.15),
                backgroundImage:
                    (post['profileImage']?.toString().isNotEmpty ?? false)
                        ? NetworkImage(post['profileImage'].toString())
                        : null,
                child: (post['profileImage']?.toString().isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['username']?.toString() ?? 'Unknown user',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(post['timePosted']),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deletePost(post),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          if ((post['caption']?.toString().trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Text(
              post['caption'].toString(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          if (allMediaCount > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 168,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int index = 0; index < imageUrls.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 210,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.white38,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Image ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (int index = 0; index < videoUrls.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == videoUrls.length - 1 ? 0 : 10,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 210,
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(Icons.videocam, color: Colors.white38, size: 34),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill('${post['likes']} likes', Colors.orange),
              _buildStatusPill('${post['commentCount']} comments', Colors.blue),
              if (imageUrls.isNotEmpty)
                _buildStatusPill('${imageUrls.length} image(s)', Colors.green),
              if (videoUrls.isNotEmpty)
                _buildStatusPill('${videoUrls.length} video(s)', Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionChip(
                label: 'View Profile',
                icon: Icons.person_outline,
                color: Colors.blue,
                onTap: () => _openUserProfile({
                  'userId': post['userId'],
                  'displayName': post['username'],
                  'profileImage': post['profileImage'],
                }),
              ),
              _buildActionChip(
                label: 'Delete Post',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () => _deletePost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== WEB UI METHODS WITH SIDEBAR NAVIGATION ==============

  Widget _buildSidebarNavItem(String label, int index, IconData icon) {
    final isSelected = index == 0; // Dashboard is selected (index 0)
    
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
          // Logo and header
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rockies Fitness Admin',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          
          // Navigation items
          const SizedBox(height: 20),
          _buildSidebarNavItem('Overview', 0, Icons.dashboard_outlined),
          _buildSidebarNavItem('Users', 1, Icons.people_outline),
          _buildSidebarNavItem('Community', 2, Icons.forum_outlined),
          _buildSidebarNavItem('Feedback', 3, Icons.rate_review_outlined),
          
          const Spacer(),
          
          // Admin logout section with exit icon
          InkWell(
            onTap: _logoutAdmin,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
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
          onChanged: (value) {
            _searchQuery = value;
            _applySearchFilter(_searchQuery);
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users or posts...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.orange),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildWebStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.people_alt_outlined,
              iconColor: Colors.blue,
              label: 'Total Users',
              value: _users.length.toString(),
              subtitle: 'All user documents',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.block,
              iconColor: Colors.orange,
              label: 'Banned Users',
              value: _bannedUsersCount.toString(),
              subtitle: 'Users currently blocked',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.forum_outlined,
              iconColor: Colors.green,
              label: 'Community Posts',
              value: _posts.length.toString(),
              subtitle: 'Posts available for review',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.rate_review_outlined,
              iconColor: Colors.amber,
              label: 'Total Feedback',
              value: _totalFeedbackCount.toString(),
              subtitle: 'User ratings and comments received',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebUsersSection() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildUserCard(_filteredUsers[index]),
      ),
    );
  }

  Widget _buildWebPostsSection() {
    if (_filteredPosts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No posts found',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildPostCard(_filteredPosts[index]),
      ),
    );
  }

  Widget _buildWebContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Users'),
                Tab(text: 'Posts'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWebUsersSection(),
                _buildWebPostsSection(),
              ],
            ),
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
              children: [
                // Sidebar navigation
                _buildWebSidebarNavigation(),
                
                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      _buildWebSearchBar(),
                      _buildWebStatsRow(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadDashboardData(showLoader: false),
                          child: _buildWebContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============== MOBILE UI ==============

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Dashboard',
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
                  final statsColumns = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 2
                          : 1;
                  final statsAspectRatio = statsColumns == 1
                      ? 1.6
                      : statsColumns == 2
                          ? 1.32
                          : 1.16;

                  return RefreshIndicator(
                    onRefresh: () => _loadDashboardData(showLoader: false),
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
                                  'Rockies Fitness Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Use the admin bottom navigation to open the Users, Community, and Feedback panels.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: statsColumns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: statsAspectRatio,
                            children: [
                              _buildSummaryCard(
                                icon: Icons.people_alt_outlined,
                                iconColor: Colors.blue,
                                label: 'Total Users',
                                value: _users.length.toString(),
                                subtitle: 'All user documents',
                              ),
                              _buildSummaryCard(
                                icon: Icons.block,
                                iconColor: Colors.orange,
                                label: 'Banned Users',
                                value: _bannedUsersCount.toString(),
                                subtitle: 'Users currently blocked',
                              ),
                              _buildSummaryCard(
                                icon: Icons.forum_outlined,
                                iconColor: Colors.green,
                                label: 'Community Posts',
                                value: _posts.length.toString(),
                                subtitle: 'Posts available for review',
                              ),
                              _buildSummaryCard(
                                icon: Icons.rate_review_outlined,
                                iconColor: Colors.amber,
                                label: 'Total Feedback',
                                value: _totalFeedbackCount.toString(),
                                subtitle: 'User ratings and comments received',
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            'Admin Session',
                            'Securely end the current admin session.',
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF191919),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Use this button when you are done moderating users and community content.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _logoutAdmin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.logout),
                                    label: const Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
    
    // Use web layout for web platform with large screens
    if (isWeb && isLargeScreen) {
      return _buildWebLayout();
    }
    
    // Use mobile layout for mobile devices or small screens
    return _buildMobileLayout();
  }
}