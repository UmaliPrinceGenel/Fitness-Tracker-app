import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';

class PhotoEditingScreen extends StatefulWidget {
  const PhotoEditingScreen({super.key});

  @override
  State<PhotoEditingScreen> createState() => _PhotoEditingScreenState();
}

class _PhotoEditingScreenState extends State<PhotoEditingScreen> {
  final List<Uint8List> _selectedImages = [];
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  bool _isUploading = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _selectImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        for (final pickedFile in pickedFiles) {
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          _selectedImages.add(imageBytes);
        }
        setState(() {});
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Failed to pick images');
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
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        _selectedImages.add(imageBytes);
        setState(() {});
      }
    } catch (e) {
      print('Error taking photo: $e');
      _showErrorSnackBar('Failed to take photo');
    }
  }

  Future<List<String>> _uploadImagesToSupabase() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      List<String> imageUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final String fileName =
            'post_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String filePath = 'community-posts/${user.uid}/$fileName';

        try {
          await _supabase.storage
              .from('community-posts')
              .uploadBinary(filePath, _selectedImages[i]);

          final String publicURL = _supabase.storage
              .from('community-posts')
              .getPublicUrl(filePath);

          imageUrls.add(publicURL);
        } catch (e) {
          print('❌ Binary upload failed for image $i: $e');
          rethrow;
        }
      }

      return imageUrls;
    } catch (e) {
      print('❌ Error uploading images: $e');
      rethrow;
    }
  }

  Future<void> _createPostInFirestore(List<String> imageUrls) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final postData = {
        'userId': user.uid,
        'username': userData?['displayName'] ?? 'User',
        'profileImage': userData?['photoURL'],
        'caption': _captionController.text.trim(),
        'postImages': imageUrls,
        'timePosted': FieldValue.serverTimestamp(),
        'likes': 0,
        'commentCount': 0,
        'likedBy': [],
      };

      await _firestore.collection('community_posts').add(postData);
    } catch (e) {
      print('Error creating post in Firestore: $e');
      rethrow;
    }
  }

  Future<void> _handlePost() async {
    if (_selectedImages.isEmpty || _captionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add images and caption');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final List<String> imageUrls = await _uploadImagesToSupabase();
      await _createPostInFirestore(imageUrls);

      Navigator.pop(context, {'success': true});

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

  void _removeCurrentImage() {
    if (_selectedImages.isNotEmpty) {
      setState(() {
        _selectedImages.removeAt(_currentPage);
        if (_currentPage >= _selectedImages.length &&
            _selectedImages.isNotEmpty) {
          _currentPage = _selectedImages.length - 1;
        } else if (_selectedImages.isEmpty) {
          _currentPage = 0;
        }
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

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
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
            Icon(Icons.photo_library, color: Colors.grey[600], size: 60),
            const SizedBox(height: 16),
            Text(
              "No images selected",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey[800],
      ),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _selectedImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.memory(
                _selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.error, color: Colors.grey[600], size: 60),
                  );
                },
              );
            },
          ),

          // Image counter
          if (_selectedImages.length > 1)
            Positioned(
              top: 16,
              right: 16,
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
                  '${_currentPage + 1}/${_selectedImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Single close button for current image
          if (_selectedImages.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: _removeCurrentImage,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildImagePreview(),
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
                              icon: Icons.photo_library,
                              label: "Gallery",
                              onTap: _selectImagesFromGallery,
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
                Navigator.of(context).pop();
              },
              child: const Text(
                "Continue Editing",
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Discard", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
