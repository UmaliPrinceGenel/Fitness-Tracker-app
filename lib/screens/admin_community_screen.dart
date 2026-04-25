// admin_community_screen.dart (Complete with Sidebar Navigation and Logout)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_dashboard_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_route_utils.dart';
import 'admin_users_screen.dart';
import 'community_screen.dart';
import 'community_member_profile_screen.dart';
import 'login_screen.dart';

class AdminCommunityScreen extends StatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  State<AdminCommunityScreen> createState() => _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends State<AdminCommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';
  
  // Web-specific state variables
  String _selectedFilter = 'all'; // all, images, videos, mostLiked
  int _selectedPostIndex = -1; // For desktop split view

  void _onNavTapped(int index) {
    if (index == 2) return;

    final Widget page;
    if (index == 0) {
      page = const AdminDashboardScreen();
    } else if (index == 1) {
      page = const AdminUsersScreen();
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

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final snapshot = await _firestore
          .collection('community_posts')
          .orderBy('timePosted', descending: true)
          .get();

      final posts = snapshot.docs.map((doc) {
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
        _posts = posts;
        _applyFilter(_query, notify: false);
        _isLoading = false;
        _isRefreshing = false;
        _selectedPostIndex = -1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilter(String query, {bool notify = true}) {
    final normalized = query.trim().toLowerCase();
    var filtered = _posts.where((post) {
      return normalized.isEmpty ||
          post['username'].toString().toLowerCase().contains(normalized) ||
          post['caption'].toString().toLowerCase().contains(normalized);
    }).toList();
    
    // Apply type filter for web
    if (_selectedFilter == 'images') {
      filtered = filtered.where((post) => (post['postImages'] as List).isNotEmpty).toList();
    } else if (_selectedFilter == 'videos') {
      filtered = filtered.where((post) => (post['postVideos'] as List).isNotEmpty).toList();
    } else if (_selectedFilter == 'mostLiked') {
      filtered = List.from(filtered);
      filtered.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
    }

    if (notify) {
      setState(() {
        _query = query;
        _filteredPosts = filtered;
        if (_selectedPostIndex >= _filteredPosts.length) {
          _selectedPostIndex = -1;
        }
      });
    } else {
      _query = query;
      _filteredPosts = filtered;
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('MMM d, yyyy - hh:mm a').format(value.toDate());
    }
    return 'Unknown date';
  }

  void _openUserProfile(Map<String, dynamic> post) {
    final userId = post['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMemberProfileScreen(
          userId: userId,
          initialDisplayName: post['username']?.toString(),
          initialProfileImageUrl:
              (post['profileImage']?.toString().isNotEmpty ?? false)
                  ? post['profileImage']?.toString()
                  : null,
        ),
      ),
    );
  }

  void _showImageGallery(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImageZoomOverlay(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerOverlay(videoUrl: videoUrl),
      ),
    );
  }

  void _showLikesBottomSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LikesBottomSheet(
        postId: postId,
        onOpenProfile: (userId, username, profileImageUrl) {
          Navigator.of(context).pop();
          Future.delayed(Duration.zero, () {
            _openUserProfile({
              'userId': userId,
              'username': username,
              'profileImage': profileImageUrl,
            });
          });
        },
      ),
    );
  }

  void _showCommentsBottomSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AdminCommentsBottomSheet(
        postId: postId,
        onOpenProfile: (userId, username, profileImageUrl) {
          Navigator.of(context).pop();
          Future.delayed(Duration.zero, () {
            _openUserProfile({
              'userId': userId,
              'username': username,
              'profileImage': profileImageUrl,
            });
          });
        },
      ),
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    if (!await _showConfirmationDialog(
      'Delete Post',
      'Delete this community post by "${post['username']}"?',
    )) {
      return;
    }

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
      await _loadPosts(showLoader: false);
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

  // ============== MOBILE UI METHODS ==============
  
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
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
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
                      child: GestureDetector(
                        onTap: () => _showImageGallery(imageUrls, index),
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
                    ),
                  for (int index = 0; index < videoUrls.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == videoUrls.length - 1 ? 0 : 10,
                      ),
                      child: GestureDetector(
                        onTap: () => _showVideoPlayer(videoUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 210,
                            child: VideoThumbnailWidget(
                              videoUrl: videoUrls[index],
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
              GestureDetector(
                onTap: () => _showLikesBottomSheet(post['id'].toString()),
                child: _buildStatusPill('${post['likes']} likes', Colors.orange),
              ),
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(post['id'].toString()),
                child: _buildStatusPill(
                  '${post['commentCount']} comments',
                  Colors.blue,
                ),
              ),
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
                onTap: () => _openUserProfile(post),
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

  // Web-specific compact post card
  Widget _buildWebPostCard(Map<String, dynamic> post, {bool compact = false}) {
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
                radius: compact ? 20 : 22,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(post['timePosted']),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 13 : 14,
                height: 1.45,
              ),
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
            ),
          ],
          if (allMediaCount > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: compact ? 120 : 168,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int index = 0; index < imageUrls.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => _showImageGallery(imageUrls, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: compact ? 160 : 210,
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
                    ),
                  for (int index = 0; index < videoUrls.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == videoUrls.length - 1 ? 0 : 10,
                      ),
                      child: GestureDetector(
                        onTap: () => _showVideoPlayer(videoUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: compact ? 160 : 210,
                            child: VideoThumbnailWidget(
                              videoUrl: videoUrls[index],
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
              GestureDetector(
                onTap: () => _showLikesBottomSheet(post['id'].toString()),
                child: _buildStatusPill('${post['likes']} likes', Colors.orange),
              ),
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(post['id'].toString()),
                child: _buildStatusPill(
                  '${post['commentCount']} comments',
                  Colors.blue,
                ),
              ),
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
                onTap: () => _openUserProfile(post),
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

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Community',
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
                    onRefresh: () => _loadPosts(showLoader: false),
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
                                  'Community Moderation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Review feed activity, open member profiles, and remove posts that should not stay visible.',
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    onChanged: _applyFilter,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search posts or usernames...',
                                      hintStyle:
                                          TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStatsGrid(
                                  [
                                    _buildStatChip(
                                      'Total Posts',
                                      _posts.length.toString(),
                                      Colors.blue,
                                    ),
                                    _buildStatChip(
                                      'Image Posts',
                                      _posts
                                          .where((post) =>
                                              (post['postImages'] as List<String>)
                                                  .isNotEmpty)
                                          .length
                                          .toString(),
                                      Colors.green,
                                    ),
                                    _buildStatChip(
                                      'Video Posts',
                                      _posts
                                          .where((post) =>
                                              (post['postVideos'] as List<String>)
                                                  .isNotEmpty)
                                          .length
                                          .toString(),
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_filteredPosts.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No community posts matched your search.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: _filteredPosts
                                  .map(
                                    (post) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildPostCard(post),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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

  // ============== WEB UI METHODS WITH SIDEBAR NAVIGATION ==============

  Widget _buildSidebarNavItem(String label, int index, IconData icon) {
    final isSelected = index == 2; // Community is selected (index 2)
    
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
                  'Community Management',
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
          
          // Logout section (matching Admin Dashboard style)
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

  Widget _buildWebStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                onChanged: (value) {
                  _query = value;
                  _applyFilter(_query);
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search posts or users...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildWebFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildWebFilterChip('Images', 'images'),
          const SizedBox(width: 8),
          _buildWebFilterChip('Videos', 'videos'),
          const SizedBox(width: 8),
          _buildWebFilterChip('Most Liked', 'mostLiked'),
        ],
      ),
    );
  }

  Widget _buildWebFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilter(_query);
        });
      },
      backgroundColor: const Color(0xFF1A1A1A),
      selectedColor: Colors.orange.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? Colors.orange : Colors.white10),
    );
  }

  Widget _buildWebStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildWebStatCard(
              'Total Posts',
              _posts.length.toString(),
              Icons.post_add,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebStatCard(
              'Media Posts',
              _posts
                  .where((p) =>
                      (p['postImages'] as List).isNotEmpty ||
                      (p['postVideos'] as List).isNotEmpty)
                  .length
                  .toString(),
              Icons.photo_library,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebStatCard(
              'Total Likes',
              _posts
                  .fold<int>(0, (sum, p) => sum + (p['likes'] as int))
                  .toString(),
              Icons.favorite,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPostList({bool compact = false}) {
    if (_filteredPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No posts found',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () {
          if (compact) {
            setState(() => _selectedPostIndex = index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWebPostCard(_filteredPosts[index], compact: compact),
        ),
      ),
    );
  }

  Widget _buildWebDesktopSplitView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final showDetailPanel = screenWidth >= 1200 &&
        _selectedPostIndex >= 0 &&
        _selectedPostIndex < _filteredPosts.length;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: showDetailPanel ? 1 : 2,
          child: _buildWebPostList(compact: true),
        ),
        if (showDetailPanel)
          Container(
            width: 500,
            color: const Color(0xFF0A0A0A),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => setState(() => _selectedPostIndex = -1),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildWebPostCard(
                      _filteredPosts[_selectedPostIndex],
                      compact: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWebLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
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
                // Sidebar navigation (always visible on web)
                _buildWebSidebarNavigation(),
                
                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      _buildWebSearchBar(),
                      _buildWebStatsRow(),
                      Expanded(
                        child: isDesktop
                            ? _buildWebDesktopSplitView()
                            : _buildWebPostList(compact: false),
                      ),
                    ],
                  ),
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

class _AdminCommentsBottomSheet extends StatelessWidget {
  final String postId;
  final Function(String, String?, String?) onOpenProfile;

  const _AdminCommentsBottomSheet({
    required this.postId,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('community_posts')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final username = commentData['username']?.toString() ?? 'User';
                    final comment = commentData['comment']?.toString() ?? '';
                    final profileImage = commentData['profileImage']?.toString();
                    final userId = commentData['userId']?.toString() ?? '';

                    return GestureDetector(
                      onTap: () => onOpenProfile(userId, username, profileImage),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[700],
                              ),
                              child: profileImage != null && profileImage.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}