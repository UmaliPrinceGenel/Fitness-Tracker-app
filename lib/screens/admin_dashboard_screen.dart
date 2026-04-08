import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_community_screen.dart';
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
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';

  int get _bannedUsersCount =>
      _users.where((user) => user['isBanned'] == true).length;

  int get _deletedUsersCount =>
      _users.where((user) => user['isDeleted'] == true).length;

  void _onNavTapped(int index) {
    if (index == 0) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            index == 1 ? const AdminUsersScreen() : const AdminCommunityScreen(),
      ),
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
      final usersSnapshot = await _firestore.collection('users').get();
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .orderBy('timePosted', descending: true)
          .get();

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

  Future<void> _deleteAccount(String userId, String userEmail) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Account',
      'Soft-delete "$userEmail"? This marks the account as deleted in Firestore.',
    );
    if (!confirmed) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      await _loadDashboardData(showLoader: false);
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

  Widget _buildQuickLinkCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
          ],
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

  Widget _buildPostCard(Map<String, dynamic> post) {
    final imageUrls = (post['postImages'] as List<String>);
    final videoUrls = (post['postVideos'] as List<String>);
    final previewUrl = imageUrls.isNotEmpty
        ? imageUrls.first
        : (videoUrls.isNotEmpty ? videoUrls.first : null);

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
          if (previewUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.perm_media, color: Colors.white38, size: 40),
                    ),
                  ),
                ),
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
                  'username': post['username'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _loadDashboardData(showLoader: false),
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
                                  'Overview only. Use the admin bottom navigation to open the Users and Community panels.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF191919),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings_outlined,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'This dashboard stays focused on totals so the layout remains clean on any screen size.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                icon: Icons.delete_outline,
                                iconColor: Colors.red,
                                label: 'Deleted Users',
                                value: _deletedUsersCount.toString(),
                                subtitle: 'Soft-deleted accounts',
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
        ],
      ),
    );
  }
}
