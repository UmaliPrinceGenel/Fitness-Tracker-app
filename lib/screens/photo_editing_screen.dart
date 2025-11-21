import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';

class PhotoEditingScreen extends StatefulWidget {
  final String? initialImagePath;
  final String? initialCaption;

  const PhotoEditingScreen({
    super.key,
    this.initialImagePath,
    this.initialCaption,
  });

  @override
  State<PhotoEditingScreen> createState() => _PhotoEditingScreenState();
}

class _PhotoEditingScreenState extends State<PhotoEditingScreen> {
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  String _caption = '';
  TextEditingController _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.initialImagePath;
    _caption = widget.initialCaption ?? '';
    _captionController.text = _caption;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read as bytes for web compatibility
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read as bytes for web compatibility
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      _showErrorSnackBar('Failed to take photo');
    }
  }

  /// ✅ USE THE SAME APPROACH AS MY_PROFILE.DART - Uint8List upload
  Future<String> _uploadImageToSupabase(Uint8List imageBytes) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'community-posts/${user.uid}/$fileName';

      print('📤 Uploading post image bytes: $filePath');

      // ✅ USE THE SAME METHOD AS YOUR WORKING MY_PROFILE SCREEN
      // Try direct upload with bytes first
      try {
        await _supabase.storage
            .from('community-posts')
            .uploadBinary(filePath, imageBytes);

        final String publicURL = _supabase.storage
            .from('community-posts')
            .getPublicUrl(filePath);

        print('✅ Post image uploaded successfully with bytes: $publicURL');
        return publicURL;
      } catch (e) {
        print('❌ Binary upload failed, trying alternative: $e');

        // Fallback for mobile
        try {
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(imageBytes);

          await _supabase.storage
              .from('community-posts')
              .upload(filePath, tempFile);

          final String publicURL = _supabase.storage
              .from('community-posts')
              .getPublicUrl(filePath);

          // Clean up temp file
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }

          print('✅ Post image uploaded successfully with file: $publicURL');
          return publicURL;
        } catch (e2) {
          print('❌ All upload methods failed: $e2');
          throw e;
        }
      }
    } catch (e) {
      print('❌ Error uploading post image: $e');
      throw e;
    }
  }

  Future<void> _createPostInFirestore(String imageUrl) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // Create post document
      final postData = {
        'userId': user.uid,
        'username': userData?['displayName'] ?? 'User',
        'profileImage': userData?['photoURL'],
        'caption': _captionController.text.trim(),
        'postImage': imageUrl,
        'timePosted': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      };

      await _firestore.collection('community_posts').add(postData);
    } catch (e) {
      print('Error creating post in Firestore: $e');
      throw e;
    }
  }

  Future<void> _handlePost() async {
    if (_selectedImageBytes == null || _captionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add an image and caption');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image to Supabase using bytes (like my_profile.dart)
      final String imageUrl = await _uploadImageToSupabase(
        _selectedImageBytes!,
      );

      // Create post in Firestore
      await _createPostInFirestore(imageUrl);

      // Return success
      Navigator.pop(context, {
        'image': _selectedImagePath,
        'caption': _captionController.text.trim(),
        'success': true,
      });

      _showSuccessSnackBar('Post created successfully!');
    } catch (e) {
      print('Error creating post: $e');
      _showErrorSnackBar('Failed to create post: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// ✅ FIXED: Web-compatible image display
  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      // Use MemoryImage for web compatibility
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.error, color: Colors.grey[600], size: 60),
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[800],
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.grey[600], size: 60),
            const SizedBox(height: 16),
            Text(
              "No image selected",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _showDiscardDialog(context);
          },
        ),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _handlePost,
                  child: const Text(
                    "Post",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image selection area
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // ✅ FIXED: Use web-compatible image display
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          color: Colors.grey[800],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: _buildImagePreview(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF191919),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEditButton(
                              icon: Icons.image,
                              label: "Gallery",
                              onTap: _selectImageFromGallery,
                            ),
                            _buildEditButton(
                              icon: Icons.camera_alt,
                              label: "Camera",
                              onTap: _takePhotoWithCamera,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Caption input
                const Text(
                  "Caption",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _caption = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: const Text(
            "Discard Post",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to discard this post?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Continue Editing",
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text("Discard", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
