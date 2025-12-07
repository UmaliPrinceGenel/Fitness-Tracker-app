import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'photo_editing_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();

  // Add user data state
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
        // Like the post - add user ID and increment likes
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        // Unlike the post - remove user ID and decrement likes
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
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
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Delete Post",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to delete this post? This action cannot be undone.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "DELETE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        return LikesBottomSheet(postId: postId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Community",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Post input card
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PhotoEditingScreen(),
                    ),
                  );

                  if (result != null && result['success'] == true) {
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // ✅ Profile avatar with user's photoURL
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[700],
                            ),
                            child: _isLoadingUser
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                : _profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 40,
                                      height: 40,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
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
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Colors.blue),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                          const SizedBox(width: 12),
                          // Text input with gallery icon inside
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

                                if (result != null &&
                                    result['success'] == true) {
                                  setState(() {});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "What's on your mind?",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.image,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Posts list from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('community_posts')
                    .orderBy('timePosted', descending: true)
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final post = snapshot.data!.docs[index];
                      final postData = post.data() as Map<String, dynamic>;
                      return PostCard(
                        postId: post.id,
                        postData: postData,
                        onLike: _likePost,
                        onComment: _showCommentsBottomSheet,
                        onDelete: _deletePost,
                        onImageTap: _showImageZoom,
                        onVideoTap: _showVideoPlayer,
                        onShowLikes: _showLikesBottomSheet,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentMediaIndex = 0;

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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Container(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[700],
                  ),
                  child: widget.postData['profileImage'] != null
                      ? ClipOval(
                          child: Image.network(
                            widget.postData['profileImage'],
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.postData['username'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Delete button for post owner
                if (isCurrentUserPost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
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
                Text(
                  _formatTimestamp(widget.postData['timePosted']),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Post caption
          if (widget.postData['caption'] != null &&
              widget.postData['caption'].isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Text(
                widget.postData['caption'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          // Post media
          if (allMedia.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: Stack(
                children: [
                  // Show media gallery
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PageView.builder(
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
                              height: 250,
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
                          borderRadius: BorderRadius.circular(12),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
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
                ],
              ),
            ),
          // Engagement metrics
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Like button with long press
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (user == null) return;
                        final newLikeStatus = !isLiked;
                        widget.onLike(widget.postId, newLikeStatus);
                      },
                      onLongPress: () {
                        if (_getLikesCount() > 0) {
                          widget.onShowLikes(context, widget.postId);
                        }
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        if (_getLikesCount() > 0) {
                          widget.onShowLikes(context, widget.postId);
                        }
                      },
                      child: Text(
                        likesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.onComment(context, widget.postId);
                      },
                      child: const Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (widget.postData['commentCount'] ?? 0).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
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

  const LikesBottomSheet({super.key, required this.postId});

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
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.commentController,
    required this.onAddComment,
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
          VideoPlayer(_thumbnailController!),

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
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .doc(widget.postId)
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
                      "No comments yet",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index];
                    final commentData = comment.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(12),
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
                            child: commentData['profileImage'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      commentData['profileImage'],
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commentData['username'] ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  commentData['comment'],
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
                    color: Colors.grey[800],
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
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black, size: 18),
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
    );
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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
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
}
