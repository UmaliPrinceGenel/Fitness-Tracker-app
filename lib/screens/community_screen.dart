import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'community_member_profile_screen.dart';
import 'photo_editing_screen.dart';
import '../widgets/chatbot_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_dialog.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.showChatbot = true});

  final bool showChatbot;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  late final Stream<QuerySnapshot> _postsStream;

  // Add user data state
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _postsStream = _firestore
        .collection('community_posts')
        .orderBy('timePosted', descending: true)
        .snapshots();
    _loadCurrentUserData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _commentController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when the app resumes
      _refreshCommunityData();
    }
  }

  /// ✅ Load current user data for the avatar
  Future<void> _loadCurrentUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
            _profileImageUrl = _userData?['photoURL'];
          });
        }
      }
    } catch (e) {
      print('Error loading current user data: $e');
    } finally {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _likePost(String postId, bool isLiking) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      if (isLiking) {
        // Like the post - add user ID, increment likes, default reaction to ❤️
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'reactions.${user.uid}': '❤️',
        });
      } else {
        // Unlike the post - remove user ID, decrement likes, and clear reaction
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'reactions.${user.uid}': FieldValue.delete(),
        });
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> _addComment(String postId, String comment) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final commentData = {
        'userId': user.uid,
        'username': userData?['displayName'] ?? 'User',
        'profileImage': userData?['photoURL'],
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add comment to subcollection
      await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      // Update comment count
      await _firestore.collection('community_posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  /// ✅ Delete post and associated media
  Future<void> _deletePost(String postId, List<String> mediaUrls) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return PremiumDialog(
            title: "Delete Post",
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFFF4B4B),
            content: const Text(
              "Are you sure you want to delete this post? This action cannot be undone.",
            ),
            actions: [
              PremiumCancelButton(
                onPressed: () => Navigator.of(context).pop(false),
              ),
              PremiumConfirmButton(
                label: "Delete",
                gradientColors: const [Color(0xFFFF4B4B), Color(0xFFFF7B7B)],
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) return;

      // Delete media from Supabase storage
      for (final mediaUrl in mediaUrls) {
        try {
          final uri = Uri.parse(mediaUrl);
          final pathSegments = uri.path.split('/');
          final bucketIndex = pathSegments.indexOf('community-posts');

          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await _supabase.storage.from('community-posts').remove([filePath]);
            print('🗑️ Deleted media from Supabase: $filePath');
          }
        } catch (e) {
          print('❌ Error deleting media from storage: $e');
        }
      }

      // Delete comments subcollection
      final commentsSnapshot = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .get();

      final batch = _firestore.batch();
      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }
      await batch.commit();

      // Delete the main post document
      await _firestore.collection('community_posts').doc(postId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Show image zoom overlay
  void _showImageZoom(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImageZoomOverlay(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  /// ✅ Show video player overlay
  void _showVideoPlayer(String videoUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerOverlay(videoUrl: videoUrl),
      ),
    );
  }

  /// ✅ NEW: Show likes bottom sheet
  void _showLikesBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LikesBottomSheet(
          postId: postId,
          onOpenProfile: _openMemberProfile,
        );
      },
    );
  }

  void _openMemberProfile(
    String userId,
    String? username,
    String? profileImageUrl,
  ) {
    if (userId.trim().isEmpty) return;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null && currentUser.uid == userId.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That is your profile. Open it from the Profile tab.'),
          backgroundColor: Color(0xFF191919),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMemberProfileScreen(
          userId: userId,
          initialDisplayName: username,
          initialProfileImageUrl: profileImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            "Community",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshCommunityData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWideWeb = kIsWeb && constraints.maxWidth >= 980;

                  if (!isWideWeb) {
                    return Column(
                      children: [
                        // Post input card
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // ✅ Profile avatar with glowing gradient border
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3EA6FF),
                                        Color(0xFFFF6B6B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3EA6FF).withOpacity(0.35),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _isLoadingUser
                                        ? const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.white),
                                              ),
                                            ),
                                          )
                                        : _profileImageUrl != null
                                            ? ClipOval(
                                                child: Image.network(
                                                  _profileImageUrl!,
                                                  fit: BoxFit.cover,
                                                  width: 44,
                                                  height: 44,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                                            Color(0xFF3EA6FF)),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.person,
                                                      color: Colors.white70,
                                                      size: 20,
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                color: Colors.white70,
                                                size: 20,
                                              ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Text input with premium design
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PhotoEditingScreen(),
                                        ),
                                      );

                                      if (result != null && result['success'] == true) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 13.0,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.04),
                                            Colors.white.withOpacity(0.01),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.06),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white.withOpacity(0.4),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "What's on your mind?",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.65),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                          // Gallery / Image Icon
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF3EA6FF).withOpacity(0.18),
                                                  const Color(0xFF3EA6FF).withOpacity(0.08),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF3EA6FF).withOpacity(0.25),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Color(0xFF3EA6FF),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Video Icon
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFFFF6B6B).withOpacity(0.18),
                                                  const Color(0xFFFF6B6B).withOpacity(0.08),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFFF6B6B).withOpacity(0.25),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.videocam_outlined,
                                              color: Color(0xFFFF6B6B),
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Posts list from Firestore
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _postsStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange,
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final post = snapshot.data!.docs[index];
                                  final postData =
                                      post.data() as Map<String, dynamic>;
                                  return PostCard(
                                    postId: post.id,
                                    postData: postData,
                                    onLike: _likePost,
                                    onComment: _showCommentsBottomSheet,
                                    onDelete: _deletePost,
                                    onImageTap: _showImageZoom,
                                    onVideoTap: _showVideoPlayer,
                                    onShowLikes: _showLikesBottomSheet,
                                    onOpenProfile: _openMemberProfile,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 980),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.08),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PhotoEditingScreen(),
                                            ),
                                          );

                                          if (result != null &&
                                              result['success'] == true) {
                                            setState(() {});
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 54,
                                                    height: 54,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.grey[800],
                                                      border: Border.all(
                                                        color: Colors.white12,
                                                      ),
                                                    ),
                                                    child: _isLoadingUser
                                                        ? const Center(
                                                            child: SizedBox(
                                                              width: 22,
                                                              height: 22,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      Colors
                                                                          .white,
                                                                    ),
                                                              ),
                                                            ),
                                                          )
                                                        : _profileImageUrl !=
                                                              null
                                                        ? ClipOval(
                                                            child: Image.network(
                                                              _profileImageUrl!,
                                                              fit: BoxFit.cover,
                                                              width: 54,
                                                              height: 54,
                                                            ),
                                                          )
                                                        : const Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                            size: 24,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: const [
                                                        Text(
                                                          'Share something with the community',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        Text(
                                                          'Add a photo, video, or update. Your friends will see it in the feed.',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 18),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 14.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.06),
                                                      Colors.white.withOpacity(0.02),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.08),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      blurRadius: 18,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit_outlined,
                                                      color: Colors.white.withOpacity(0.4),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        "What's on your mind?",
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.65),
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          letterSpacing: 0.1,
                                                        ),
                                                      ),
                                                    ),
                                                    // Gallery / Image Icon
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            const Color(0xFF3EA6FF).withOpacity(0.18),
                                                            const Color(0xFF3EA6FF).withOpacity(0.08),
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color(0xFF3EA6FF).withOpacity(0.25),
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: Color(
                                                          0xFF3EA6FF,
                                                        ),
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    // Video Icon
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            const Color(0xFFFF6B6B).withOpacity(0.18),
                                                            const Color(0xFFFF6B6B).withOpacity(0.08),
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color(0xFFFF6B6B).withOpacity(0.25),
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.videocam_outlined,
                                                        color: Color(
                                                          0xFFFF6B6B,
                                                        ),
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: _postsStream,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.orange,
                                                  ),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 40,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No posts yet',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            final post =
                                                snapshot.data!.docs[index];
                                            final postData =
                                                post.data()
                                                    as Map<String, dynamic>;
                                            return PostCard(
                                              postId: post.id,
                                              postData: postData,
                                              onLike: _likePost,
                                              onComment:
                                                  _showCommentsBottomSheet,
                                              onDelete: _deletePost,
                                              onImageTap: _showImageZoom,
                                              onVideoTap: _showVideoPlayer,
                                              onShowLikes:
                                                  _showLikesBottomSheet,
                                              onOpenProfile: _openMemberProfile,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showChatbot)
            const ChatbotLauncher(title: 'Community Chat'),
        ],
      ),
    );
  }

  // Refresh function for community data
  Future<void> _refreshCommunityData() async {
    // Reload user data for avatar
    await _loadCurrentUserData();
    // The StreamBuilder will automatically refresh the posts list
    // We don't need to manually reload the posts since they are handled by the StreamBuilder
  }

  void _showCommentsBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentsBottomSheet(
          postId: postId,
          commentController: _commentController,
          onAddComment: _addComment,
          onOpenProfile: _openMemberProfile,
        );
      },
    );
  }
}

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;
  final Function(String, bool) onLike;
  final Function(BuildContext, String) onComment;
  final Function(String, List<String>) onDelete;
  final Function(List<String>, int) onImageTap;
  final Function(String) onVideoTap;
  final Function(BuildContext, String) onShowLikes;
  final Function(String, String?, String?) onOpenProfile;

  const PostCard({
    super.key,
    required this.postId,
    required this.postData,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
    required this.onImageTap,
    required this.onVideoTap,
    required this.onShowLikes,
    required this.onOpenProfile,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  int _currentMediaIndex = 0;
  bool _likePulseActive = false;
  bool _showReactionPanel = false;
  late final AnimationController _likeAnimationController;
  late final Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.22,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.22,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_likeAnimationController);
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    final DateTime postTime = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.parse(timestamp.toString());
    final Duration difference = DateTime.now().difference(postTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  String? _getUserReaction() {
    final user = fbAuth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final reactions = widget.postData['reactions'] as Map<String, dynamic>?;
    return reactions?[user.uid] as String?;
  }

  Future<void> _reactToPost(fbAuth.User? user, String emoji, bool isLiked) async {
    if (user == null) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.postId);
      if (!isLiked) {
        await docRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'reactions.${user.uid}': emoji,
        });
      } else {
        await docRef.update({
          'reactions.${user.uid}': emoji,
        });
      }
    } catch (e) {
      print('Error reacting to post: $e');
    }
  }

  bool _getIsLiked() {
    final user = fbAuth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final likedBy = widget.postData['likedBy'] as List<dynamic>? ?? [];
    return likedBy.contains(user.uid);
  }

  int _getLikesCount() {
    return widget.postData['likes'] ?? 0;
  }

  List<String> _getPostImages() {
    final postImages = widget.postData['postImages'] as List<dynamic>?;
    if (postImages != null && postImages.isNotEmpty) {
      return postImages.cast<String>();
    }
    return [];
  }

  List<String> _getPostVideos() {
    final postVideos = widget.postData['postVideos'] as List<dynamic>?;
    if (postVideos != null && postVideos.isNotEmpty) {
      return postVideos.cast<String>();
    }
    return [];
  }

  List<String> _getAllMedia() {
    return [..._getPostImages(), ..._getPostVideos()];
  }

  bool _isCurrentUserPost() {
    final user = fbAuth.FirebaseAuth.instance.currentUser;
    return user != null && widget.postData['userId'] == user.uid;
  }

  bool _isVideo(int index) {
    final images = _getPostImages();
    return index >= images.length;
  }

  void _openProfileFromPost() {
    final userId = widget.postData['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    widget.onOpenProfile(
      userId,
      widget.postData['username']?.toString(),
      widget.postData['profileImage']?.toString(),
    );
  }

  void _handleLikeTap({required fbAuth.User? user, required bool isLiked}) {
    if (user == null) return;

    final newLikeStatus = !isLiked;
    widget.onLike(widget.postId, newLikeStatus);

    if (newLikeStatus) {
      setState(() {
        _likePulseActive = true;
      });
      _likeAnimationController.forward(from: 0);
      _likeAnimationController.addStatusListener(_handleLikeAnimationStatus);
    } else if (_likePulseActive) {
      setState(() {
        _likePulseActive = false;
      });
    }
  }

  void _handleLikeAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _likeAnimationController.removeStatusListener(_handleLikeAnimationStatus);
      setState(() {
        _likePulseActive = false;
      });
    }
  }

  Widget _buildActionChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPanel(fbAuth.User? user) {
    final isLiked = _getIsLiked();
    final emojis = ['❤️', '💪', '🔥', '👏', '👑', '🎯'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withOpacity(0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _showReactionPanel = false;
                  });
                  _reactToPost(user, emoji, isLiked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLikeChip({
    required fbAuth.User? user,
    required bool isLiked,
    required int likesCount,
  }) {
    final showFilledHeart = isLiked || _likePulseActive;
    final userReaction = _getUserReaction();

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleLikeTap(user: user, isLiked: isLiked),
            onLongPress: () {
              setState(() {
                _showReactionPanel = true;
              });
            },
            child: AnimatedBuilder(
              animation: _likeScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likePulseActive ? _likeScaleAnimation.value : 1.0,
                  child: child,
                );
              },
              child: userReaction != null
                  ? Text(
                      userReaction,
                      style: const TextStyle(fontSize: 20),
                    )
                  : Icon(
                      showFilledHeart ? Icons.favorite : Icons.favorite_border,
                      color: showFilledHeart ? Colors.red : Colors.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (likesCount > 0) {
                widget.onShowLikes(context, widget.postId);
              }
            },
            child: Text(
              '$likesCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionWithHashtags(String caption) {
    final List<InlineSpan> spans = [];
    final words = caption.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final spacing = i == words.length - 1 ? "" : " ";

      if (word.startsWith('#') && word.length > 1) {
        spans.add(
          TextSpan(
            text: '$word$spacing',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: '$word$spacing'));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.55,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = fbAuth.FirebaseAuth.instance.currentUser;
    final isLiked = _getIsLiked();
    final likesCount = _getLikesCount();
    final postImages = _getPostImages();
    final postVideos = _getPostVideos();
    final allMedia = _getAllMedia();
    final isCurrentUserPost = _isCurrentUserPost();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Post header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _openProfileFromPost,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: widget.postData['profileImage'] != null
                        ? ClipOval(
                            child: Image.network(
                              widget.postData['profileImage'],
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _openProfileFromPost,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.postData['username'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(widget.postData['timePosted']),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete button for post owner
                if (isCurrentUserPost)
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                    color: Colors.grey[800],
                    onSelected: (String result) {
                      if (result == 'delete') {
                        widget.onDelete(widget.postId, allMedia);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red[300]),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Post',
                                  style: TextStyle(color: Colors.red[300]),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
              ],
            ),
          ),
          // Post caption
          if (widget.postData['caption'] != null &&
              widget.postData['caption'].isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _buildCaptionWithHashtags(widget.postData['caption']),
            ),
          // Post media
          if (allMedia.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  width: double.infinity,
                  height: 300.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.black,
                  ),
              child: Stack(
                children: [
                  // Show media gallery
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      pageSnapping: true,
                      itemCount: allMedia.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentMediaIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final mediaUrl = allMedia[index];
                        final isVideo = _isVideo(index);

                        if (isVideo) {
                          return GestureDetector(
                            onTap: () {
                              // Use a Future.delayed to ensure build completes
                              Future.delayed(Duration.zero, () {
                                widget.onVideoTap(mediaUrl);
                              });
                            },
                            child: VideoThumbnailWidget(videoUrl: mediaUrl),
                          );
                        } else {
                          // Image
                          return GestureDetector(
                            onTap: () {
                              widget.onImageTap(postImages, index);
                            },
                            child: Image.network(
                              mediaUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.blue,
                                            ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // Media counter for multiple media
                  if (allMedia.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_currentMediaIndex + 1}/${allMedia.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Media type indicator
                  if (allMedia.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                if (_isVideo(_currentMediaIndex))
                                  const Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                if (_isVideo(_currentMediaIndex))
                                  const SizedBox(width: 4),
                                if (_isVideo(_currentMediaIndex))
                                  const Text(
                                    "VIDEO",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (!_isVideo(_currentMediaIndex))
                                  const Icon(
                                    Icons.photo,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                if (!_isVideo(_currentMediaIndex))
                                  const SizedBox(width: 4),
                                if (!_isVideo(_currentMediaIndex))
                                  const Text(
                                    "PHOTO",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
                );
              },
            ),
          // Engagement metrics
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
            child: Row(
              children: [
                _buildLikeChip(
                  user: user,
                  isLiked: isLiked,
                  likesCount: likesCount,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.white,
                  label: (widget.postData['commentCount'] ?? 0).toString(),
                  onTap: () {
                    widget.onComment(context, widget.postId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      if (_showReactionPanel)
        Positioned(
          bottom: 48,
          left: 12,
          child: _buildReactionPanel(user),
        ),
    ],
  ),
);
  }
}

// ✅ Video Player Overlay
class VideoPlayerOverlay extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerOverlay({super.key, required this.videoUrl});

  @override
  State<VideoPlayerOverlay> createState() => _VideoPlayerOverlayState();
}

class _VideoPlayerOverlayState extends State<VideoPlayerOverlay>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController.pause();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.videoUrl);

      // Listen for initialization
      _videoController.addListener(() {
        if (_videoController.value.hasError) {
          print(
            'Video player error: ${_videoController.value.errorDescription}',
          );
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      });

      // Initialize video
      await _videoController.initialize();

      // Ensure video is ready
      if (_videoController.value.isInitialized) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.orange,
            handleColor: Colors.orange,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade500,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          ),
          autoInitialize: true,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Error loading video: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );

        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retryVideo() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _initializeVideoPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video player or loading/error state
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.orange)
                  : _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load video',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _retryVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : const Text(
                      'Video not ready',
                      style: TextStyle(color: Colors.white),
                    ),
            ),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: Likes Bottom Sheet
class LikesBottomSheet extends StatefulWidget {
  final String postId;
  final Function(String, String?, String?) onOpenProfile;

  const LikesBottomSheet({
    super.key,
    required this.postId,
    required this.onOpenProfile,
  });

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Likes",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .doc(widget.postId)
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

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "No likes yet",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                final postData = snapshot.data!.data() as Map<String, dynamic>;
                final likedBy = postData['likedBy'] as List<dynamic>? ?? [];

                if (likedBy.isEmpty) {
                  return const Center(
                    child: Text(
                      "No likes yet",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getUsersData(likedBy.cast<String>()),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      );
                    }

                    if (!usersSnapshot.hasData || usersSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No likes yet",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    final users = usersSnapshot.data!;

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData = users[index];

                        return GestureDetector(
                          onTap: () {
                            final userId = userData['userId']?.toString() ?? '';
                            final username = userData['username']?.toString();
                            final profileImage = userData['profileImage']
                                ?.toString();
                            Navigator.of(context).pop();
                            Future.delayed(Duration.zero, () {
                              widget.onOpenProfile(
                                userId,
                                username,
                                profileImage,
                              );
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[700],
                                  ),
                                  child: userData['profileImage'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            userData['profileImage'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 16,
                                                  );
                                                },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData['username'] ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Liked this post",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
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
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> _getUsersData(List<String> userIds) async {
  final usersData = <Map<String, dynamic>>[];
  final firestore = FirebaseFirestore.instance; // Create instance here
  for (final userId in userIds) {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        usersData.add({
          'userId': userId,
          'username': userData['displayName'] ?? 'User',
          'profileImage': userData['photoURL'],
        });
      }
    } catch (e) {
      print('Error fetching user data for $userId: $e');
    }
  }

  return usersData;
}

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final TextEditingController commentController;
  final Function(String, String) onAddComment;
  final Function(String, String?, String?) onOpenProfile;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.commentController,
    required this.onAddComment,
    required this.onOpenProfile,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _thumbnailController;
  bool _thumbnailLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void dispose() {
    _thumbnailController?.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    try {
      _thumbnailController = VideoPlayerController.network(widget.videoUrl);
      await _thumbnailController!.initialize();
      setState(() {
        _thumbnailLoading = false;
      });
    } catch (e) {
      print('Error loading thumbnail: $e');
      setState(() {
        _thumbnailLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_thumbnailController != null &&
            _thumbnailController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _thumbnailController!.value.size.width,
                height: _thumbnailController!.value.size.height,
                child: VideoPlayer(_thumbnailController!),
              ),
            ),
          ),

        // Play button overlay
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
          ),
        ),

        // Video indicator
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  "VIDEO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<DocumentSnapshot> _postStream;
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _postStream = _firestore
        .collection('community_posts')
        .doc(widget.postId)
        .snapshots();
    _commentsStream = _firestore
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _toggleCommentLike(String commentId, List<dynamic> likedBy, String currentUserId) async {
    final postRef = _firestore.collection('community_posts').doc(widget.postId);
    final isLiked = likedBy.contains(currentUserId);

    try {
      if (isLiked) {
        await postRef.update({
          'reactions.comment_${commentId}_$currentUserId': FieldValue.delete(),
        });
      } else {
        await postRef.update({
          'reactions.comment_${commentId}_$currentUserId': true,
        });
      }
    } catch (e) {
      print('Error liking comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // Sheet takes up to 80% of screen, but shrinks to make room for keyboard
    final sheetHeight = (screenHeight * 0.8)
        .clamp(0.0, screenHeight - keyboardHeight - 60);

    return Padding(
      // Pushes the whole sheet up when keyboard appears
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: sheetHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Comments",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _postStream,
                builder: (context, postSnapshot) {
                  final postData = postSnapshot.data?.data() as Map<String, dynamic>?;
                  final reactions = postData?['reactions'] as Map<String, dynamic>? ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: _commentsStream,
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
                            "No comments yet",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final comment = snapshot.data!.docs[index];
                          final commentData = comment.data() as Map<String, dynamic>;
                          final currentUserId = fbAuth.FirebaseAuth.instance.currentUser?.uid ?? '';
                          
                          final likedBy = <String>[];
                          reactions.forEach((key, value) {
                            final prefix = 'comment_${comment.id}_';
                            if (key.startsWith(prefix) && value == true) {
                              likedBy.add(key.substring(prefix.length));
                            }
                          });
                          final isCommentLiked = likedBy.contains(currentUserId);
                          final commentLikesCount = likedBy.length;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final userId = commentData['userId']?.toString() ?? '';
                                    final username = commentData['username']?.toString();
                                    final profileImage = commentData['profileImage']?.toString();
                                    Navigator.of(context).pop();
                                    Future.delayed(Duration.zero, () {
                                      widget.onOpenProfile(userId, username, profileImage);
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[800],
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: commentData['profileImage'] != null
                                        ? ClipOval(
                                            child: Image.network(
                                              commentData['profileImage'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 16,
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            commentData['username'] ?? 'User',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => _toggleCommentLike(comment.id, likedBy, currentUserId),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isCommentLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isCommentLiked ? Colors.red : Colors.white60,
                                                  size: 16,
                                                ),
                                                if (commentLikesCount > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$commentLikesCount',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        commentData['comment'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: widget.commentController,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onAddComment(widget.postId, value.trim());
                        widget.commentController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A00), Color(0xFFFF5200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5200).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  onPressed: () {
                    final comment = widget.commentController.text.trim();
                    if (comment.isNotEmpty) {
                      widget.onAddComment(widget.postId, comment);
                      widget.commentController.clear();
                    }
                  },
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),  // Container
    );  // Padding
  }
}

// ✅ Image Zoom Overlay
class ImageZoomOverlay extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageZoomOverlay({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImageZoomOverlay> createState() => _ImageZoomOverlayState();
}

class _ImageZoomOverlayState extends State<ImageZoomOverlay> {
  late PageController _pageController;
  late TransformationController _transformationController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    if (_isZoomed) {
      setState(() {
        _isZoomed = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          // PageView for multiple images
          PageView.builder(
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            pageSnapping: true,
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _resetZoom();
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onDoubleTap: () {
                  if (_isZoomed) {
                    _resetZoom();
                  } else {
                    _transformationController.value = Matrix4.identity()
                      ..scale(2.0);
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: _isZoomed,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          if (kIsWeb && widget.imageUrls.length > 1)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverlayArrow(
                      icon: Icons.arrow_back_ios_new,
                      enabled: _currentIndex > 0,
                      onTap: () {
                        if (_currentIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                    _buildOverlayArrow(
                      icon: Icons.arrow_forward_ios,
                      enabled: _currentIndex < widget.imageUrls.length - 1,
                      onTap: () {
                        if (_currentIndex < widget.imageUrls.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Image counter for multiple images
          if (widget.imageUrls.length > 1)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Swipe instructions hint
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Swipe to view more images',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.2,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
