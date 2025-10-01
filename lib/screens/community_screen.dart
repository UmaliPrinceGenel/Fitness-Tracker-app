import 'package:flutter/material.dart';
import 'photo_editing_screen.dart'; // Import the photo editing screen

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Post> posts = [
    Post(
      username: "John Fitness",
      profileImage: "assets/logo.jpg",
      caption:
          "Just completed my morning run! Feeling great and ready for the day. #fitness #morningrun",
      postImage: "assets/album.jpg",
      timePosted: "2 hours ago",
      likes: 24,
      comments: 5,
    ),
    Post(
      username: "Sarah Workout",
      profileImage: "assets/lakano.png",
      caption:
          "New personal record in deadlifts today! Consistency is key. Keep pushing forward! 💪",
      postImage: "assets/figurines.png",
      timePosted: "5 hours ago",
      likes: 42,
      comments: 8,
    ),
    Post(
      username: "Mike Health",
      profileImage: "assets/mog.jpg",
      caption:
          "Healthy meal prep for the week. Good nutrition is the foundation of fitness success!",
      postImage: "assets/abs.png",
      timePosted: "1 day ago",
      likes: 18,
      comments: 3,
    ),
  ];

  final TextEditingController _postController = TextEditingController();
  String? _selectedImage;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
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
        // Removed the redundant plus button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    // Navigate to photo editing screen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhotoEditingScreen(),
                      ),
                    );

                    // If user returns with image and caption, update the fields
                    if (result != null) {
                      setState(() {
                        _selectedImage = result['image'];
                        _postController.text = result['caption'];
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Profile icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[700],
                              ),
                              child: Icon(
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
                                  // Navigate to photo editing screen
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PhotoEditingScreen(),
                                    ),
                                  );

                                  // If user returns with image and caption, update the fields
                                  if (result != null) {
                                    setState(() {
                                      _selectedImage = result['image'];
                                      _postController.text = result['caption'];
                                    });
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
                                  child: Row(
                                    children: [
                                      // Text input
                                      Expanded(
                                        child: TextField(
                                          controller: _postController,
                                          decoration: const InputDecoration(
                                            hintText: "What's on your mind?",
                                            hintStyle: TextStyle(
                                              color: Colors.white70,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          maxLines: null,
                                          readOnly:
                                              true, // Make it read-only since tap navigates
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Gallery icon inside the text field
                                      Icon(
                                        Icons.image,
                                        color: Colors
                                            .blue, // Changed to blue color
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Display selected image preview if available
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[800],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Posts list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: posts[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectImage() {
    // In a real app, this would open the image picker
    // For now, we'll just use a placeholder
    setState(() {
      _selectedImage = "assets/album.jpg"; // Using a placeholder image
    });
  }

  void _createPost() {
    if (_postController.text.trim().isNotEmpty) {
      // Create a new post
      Post newPost = Post(
        username:
            "Current User", // In a real app, this would be the actual user
        profileImage:
            "assets/logo.jpg", // In a real app, this would be the user's profile image
        caption: _postController.text.trim(),
        postImage: _selectedImage,
        timePosted: "Just now",
        likes: 0,
        comments: 0,
        isLiked: false,
      );

      // Add the new post to the beginning of the list
      setState(() {
        posts.insert(0, newPost);
        _postController.clear();
        _selectedImage = null;
      });
    }
  }
}

// Post model
class Post {
  final String username;
  final String profileImage;
  final String caption;
  final String? postImage;
  final String timePosted;
  int likes;
  int comments;
  bool isLiked;

  Post({
    required this.username,
    required this.profileImage,
    required this.caption,
    this.postImage,
    required this.timePosted,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}

// Post card widget
class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header (username and profile icon)
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
                  child: _post.profileImage != null
                      ? ClipOval(
                          child: Image.asset(
                            _post.profileImage,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        )
                      : Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _post.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _post.timePosted,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Post caption
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              _post.caption,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          // Post image
          if (_post.postImage != null)
            Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(_post.postImage!, fit: BoxFit.cover),
              ),
            )
          else
            const SizedBox.shrink(),
          // Engagement metrics (likes and comments)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _post.isLiked = !_post.isLiked;
                          if (_post.isLiked) {
                            _post.likes++;
                          } else {
                            _post.likes--;
                          }
                        });
                      },
                      child: Icon(
                        _post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _post.isLiked ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_post.likes}",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to comments screen
                        _showCommentsBottomSheet(context);
                      },
                      child: Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_post.comments}",
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

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
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
                  Text(
                    "Comments",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _post.comments,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[700],
                                ),
                                child: Icon(
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
                                      "User ${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "This is comment ${index + 1} for the post.",
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
                            decoration: const InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                setState(() {
                                  _post.comments++;
                                });
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2.0), // Smaller padding
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.black,
                            size: 18, // Increased icon size
                          ),
                          onPressed: () {
                            // Handle comment submission
                          },
                          constraints: BoxConstraints.tightFor(
                            width: 30,
                            height: 30, // Increased button size
                          ), // Make button bigger with smaller circle
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
