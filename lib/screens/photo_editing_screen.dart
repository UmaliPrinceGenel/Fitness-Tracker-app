import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart'; // Added for video thumbnail

class PhotoEditingScreen extends StatefulWidget {
  const PhotoEditingScreen({super.key});

  @override
  State<PhotoEditingScreen> createState() => _PhotoEditingScreenState();
}

class _PhotoEditingScreenState extends State<PhotoEditingScreen> {
  final List<Uint8List> _selectedImages = [];
  final List<String> _selectedVideos = []; // Store video file paths
  final List<Uint8List> _videoBytes = []; // Store video bytes for web compatibility
  final List<VideoPlayerController?> _videoControllers = []; // Store video controllers for thumbnails
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  bool _isUploading = false;
  int _currentPage = 0;
  
  // Maximum video size in bytes (30MB)
  static const int _maxVideoSize = 30 * 1024 * 1024; // 30MB in bytes

  @override
  void dispose() {
    _captionController.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _selectMediaFromGallery() async {
    try {
      if (kIsWeb) {
        // For web, use HTML file input
        await _selectMediaWeb();
      } else {
        // For mobile, use image_picker
        await _selectMediaMobile();
      }
    } catch (e) {
      print('Error picking media: $e');
      _showErrorSnackBar('Failed to pick media: ${e.toString()}');
    }
  }

  Future<void> _selectMediaMobile() async {
    try {
      final List<XFile>? pickedFiles = await _imagePicker.pickMultipleMedia(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        await _processMediaFiles(pickedFiles);
      }
    } catch (e) {
      print('Error with pickMultipleMedia: $e');
      // Fallback to showing media type selection
      await _showMediaTypeSelection();
    }
  }

  Future<void> _selectMediaWeb() async {
    final completer = Completer<List<XFile>>();
    
    // Create a file input element
    final input = html.FileUploadInputElement()
      ..accept = 'image/*,video/*'
      ..multiple = true;
    
    input.click();
    
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final xFiles = <XFile>[];
        for (final file in files) {
          xFiles.add(XFile(html.Url.createObjectUrl(file), name: file.name));
        }
        completer.complete(xFiles);
      } else {
        completer.complete([]);
      }
    });

    final pickedFiles = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('File selection timed out');
      },
    );

    if (pickedFiles.isNotEmpty) {
      await _processMediaFiles(pickedFiles);
    }
  }

  Future<void> _showMediaTypeSelection() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191919),
        title: const Text(
          "Select Media Type",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Choose what type of media you want to select:",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'image'),
            child: const Text("Photos", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'video'),
            child: const Text("Videos", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (result == 'image') {
      await _selectImagesFromGallery();
    } else if (result == 'video') {
      await _selectVideosFromGallery();
    }
  }

  Future<void> _selectImagesFromGallery() async {
    try {
      if (kIsWeb) {
        await _selectImagesWeb();
        return;
      }

      final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (final pickedFile in pickedFiles) {
          final Uint8List? imageBytes = await pickedFile.readAsBytes();
          if (imageBytes != null) {
            _selectedImages.add(imageBytes);
          }
        }
        setState(() {});
        _showSuccessSnackBar('${pickedFiles.length} photo(s) added');
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Failed to pick images');
    }
  }

  Future<void> _selectImagesWeb() async {
    final completer = Completer<List<XFile>>();
    
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;
    
    input.click();
    
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final xFiles = <XFile>[];
        for (final file in files) {
          xFiles.add(XFile(html.Url.createObjectUrl(file), name: file.name));
        }
        completer.complete(xFiles);
      } else {
        completer.complete([]);
      }
    });

    final pickedFiles = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Image selection timed out');
      },
    );

    if (pickedFiles.isNotEmpty) {
      for (final pickedFile in pickedFiles) {
        final Uint8List? imageBytes = await pickedFile.readAsBytes();
        if (imageBytes != null) {
          _selectedImages.add(imageBytes);
        }
      }
      setState(() {});
      _showSuccessSnackBar('${pickedFiles.length} photo(s) added');
    }
  }

  Future<void> _selectVideosFromGallery() async {
    try {
      if (kIsWeb) {
        await _selectVideosWeb();
        return;
      }

      final XFile? videoFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (videoFile != null) {
        await _processVideoFile(videoFile);
        setState(() {});
        _showSuccessSnackBar('Video added successfully');
      }
    } catch (e) {
      print('Error picking video: $e');
      _showErrorSnackBar('Failed to pick video');
    }
  }

  Future<void> _selectVideosWeb() async {
    final completer = Completer<List<XFile>>();
    
    final input = html.FileUploadInputElement()
      ..accept = 'video/*'
      ..multiple = true;
    
    input.click();
    
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final xFiles = <XFile>[];
        for (final file in files) {
          xFiles.add(XFile(html.Url.createObjectUrl(file), name: file.name));
        }
        completer.complete(xFiles);
      } else {
        completer.complete([]);
      }
    });

    final pickedFiles = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Video selection timed out');
      },
    );

    if (pickedFiles.isNotEmpty) {
      for (final pickedFile in pickedFiles) {
        await _processVideoFile(pickedFile);
      }
      setState(() {});
      _showSuccessSnackBar('${pickedFiles.length} video(s) added');
    }
  }

  Future<void> _processMediaFiles(List<XFile> pickedFiles) async {
    int videoCount = 0;
    int imageCount = 0;

    for (final pickedFile in pickedFiles) {
      try {
        bool isVideo = false;
        
        if (kIsWeb) {
          // For web, check file name extension
          final fileName = pickedFile.name.toLowerCase();
          isVideo = fileName.endsWith('.mp4') || 
                    fileName.endsWith('.mov') ||
                    fileName.endsWith('.avi') ||
                    fileName.endsWith('.mkv') ||
                    fileName.endsWith('.wmv') ||
                    fileName.endsWith('.flv') ||
                    fileName.endsWith('.webm') ||
                    fileName.endsWith('.3gp') ||
                    fileName.endsWith('.m4v');
        } else {
          // For mobile, check file extension
          final extension = path.extension(pickedFile.path).toLowerCase();
          isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.3gp', '.m4v']
              .contains(extension);
        }

        if (isVideo) {
          await _processVideoFile(pickedFile);
          videoCount++;
        } else {
          // It's an image
          final Uint8List? imageBytes = await pickedFile.readAsBytes();
          if (imageBytes != null) {
            _selectedImages.add(imageBytes);
            imageCount++;
          }
        }
      } catch (e) {
        print('Error processing file: $e');
        // Try to add as image if video processing fails
        try {
          final Uint8List? imageBytes = await pickedFile.readAsBytes();
          if (imageBytes != null) {
            _selectedImages.add(imageBytes);
            imageCount++;
          }
        } catch (e2) {
          print('Failed to process as image either: $e2');
        }
      }
    }

    setState(() {});
    
    if (videoCount > 0 || imageCount > 0) {
      String message = '';
      if (imageCount > 0) message += '$imageCount photo(s) ';
      if (videoCount > 0) {
        if (imageCount > 0) message += 'and ';
        message += '$videoCount video(s) ';
      }
      message += 'added successfully';
      _showSuccessSnackBar(message);
    }
  }

  Future<void> _processVideoFile(XFile videoFile) async {
    try {
      // Read video bytes
      final videoBytes = await videoFile.readAsBytes();
      final fileSize = videoBytes.length;
      
      if (fileSize > _maxVideoSize) {
        _showErrorSnackBar(
          'Video exceeds 30MB limit (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Please select a smaller video.'
        );
        return;
      }
      
      // Store both path (for mobile) and bytes
      if (kIsWeb) {
        _selectedVideos.add(videoFile.name);
        // For web, store video URL if available
        if (videoFile.path.startsWith('blob:')) {
          _selectedVideos[_selectedVideos.length - 1] = videoFile.path;
        }
      } else {
        _selectedVideos.add(videoFile.path);
      }
      _videoBytes.add(videoBytes);
      
      // Create video controller for thumbnail (mobile only)
      VideoPlayerController? controller;
      if (!kIsWeb) {
        try {
          controller = VideoPlayerController.file(File(videoFile.path));
          await controller.initialize();
          // Set the controller to show first frame
          await controller.pause();
          await controller.seekTo(Duration.zero);
        } catch (e) {
          print('Error initializing video controller for thumbnail: $e');
          controller?.dispose();
          controller = null;
        }
      }
      
      _videoControllers.add(controller);
      setState(() {});
    } catch (e) {
      print('Error processing video: $e');
      _showErrorSnackBar('Failed to process video');
    }
  }

  Future<List<String>> _uploadMediaToSupabase() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      List<String> mediaUrls = [];

      // Upload images
      for (int i = 0; i < _selectedImages.length; i++) {
        final String fileName =
            'post_${DateTime.now().millisecondsSinceEpoch}_image_$i.jpg';
        final String filePath = 'community-posts/${user.uid}/$fileName';

        try {
          await _supabase.storage
              .from('community-posts')
              .uploadBinary(filePath, _selectedImages[i]);

          final String publicURL = _supabase.storage
              .from('community-posts')
              .getPublicUrl(filePath);

          mediaUrls.add(publicURL);
          print('✅ Image $i uploaded: $publicURL');
        } catch (e) {
          print('❌ Image upload failed: $e');
          throw Exception('Failed to upload image: $e');
        }
      }

      // Upload videos
      for (int i = 0; i < _selectedVideos.length; i++) {
        try {
          Uint8List videoData = _videoBytes[i];
          String extension;
          
          if (kIsWeb) {
            // For web, get extension from file name
            final fileName = _selectedVideos[i].toLowerCase();
            if (fileName.endsWith('.mp4')) {
              extension = '.mp4';
            } else if (fileName.endsWith('.mov')) {
              extension = '.mov';
            } else if (fileName.endsWith('.avi')) {
              extension = '.avi';
            } else if (fileName.endsWith('.mkv')) {
              extension = '.mkv';
            } else if (fileName.endsWith('.webm')) {
              extension = '.webm';
            } else {
              extension = '.mp4'; // Default
            }
          } else {
            // For mobile, get extension from file path
            extension = path.extension(_selectedVideos[i]).toLowerCase();
          }

          final fileSize = videoData.length;
          
          if (fileSize > _maxVideoSize) {
            throw Exception('Video $i exceeds 30MB limit');
          }
          
          final String fileName =
              'post_${DateTime.now().millisecondsSinceEpoch}_video_$i$extension';
          final String filePath = 'community-posts/${user.uid}/$fileName';

          await _supabase.storage
              .from('community-posts')
              .uploadBinary(filePath, videoData, fileOptions: FileOptions(
                upsert: false,
                contentType: _getMimeType(extension),
              ));

          final String publicURL = _supabase.storage
              .from('community-posts')
              .getPublicUrl(filePath);

          mediaUrls.add(publicURL);
          print('✅ Video $i uploaded: $publicURL');
        } catch (e) {
          print('❌ Video upload failed for video $i: $e');
          throw Exception('Video upload failed: ${e.toString()}');
        }
      }

      return mediaUrls;
    } catch (e) {
      print('❌ Error uploading media: $e');
      throw e;
    }
  }

  // Helper function to get MIME type
  String _getMimeType(String extension) {
    switch (extension) {
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.3gp':
        return 'video/3gpp';
      case '.m4v':
        return 'video/x-m4v';
      default:
        return 'video/mp4';
    }
  }

  Future<void> _createPostInFirestore(List<String> mediaUrls) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // Determine media types
      final List<String> imageUrls = [];
      final List<String> videoUrls = [];
      
      for (final url in mediaUrls) {
        final lowerUrl = url.toLowerCase();
        if (lowerUrl.contains('.jpg') || 
            lowerUrl.contains('.jpeg') || 
            lowerUrl.contains('.png')) {
          imageUrls.add(url);
        } else {
          videoUrls.add(url);
        }
      }

      final postData = {
        'userId': user.uid,
        'username': userData?['displayName'] ?? 'User',
        'profileImage': userData?['photoURL'],
        'caption': _captionController.text.trim(),
        'postImages': imageUrls,
        'postVideos': videoUrls,
        'mediaType': videoUrls.isNotEmpty && imageUrls.isNotEmpty 
            ? 'mixed' 
            : (imageUrls.isNotEmpty ? 'image' : 'video'),
        'timePosted': FieldValue.serverTimestamp(),
        'likes': 0,
        'commentCount': 0,
        'likedBy': [],
      };

      await _firestore.collection('community_posts').add(postData);
      print('✅ Post created in Firestore');
    } catch (e) {
      print('Error creating post in Firestore: $e');
      throw e;
    }
  }

  Future<void> _handlePost() async {
    if ((_selectedImages.isEmpty && _selectedVideos.isEmpty) || 
        _captionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add media and caption');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('📤 Starting upload process...');
      print('📸 Images to upload: ${_selectedImages.length}');
      print('🎥 Videos to upload: ${_selectedVideos.length}');

      final List<String> mediaUrls = await _uploadMediaToSupabase();
      print('✅ Media uploaded successfully: ${mediaUrls.length} files');
      
      await _createPostInFirestore(mediaUrls);

      Navigator.pop(context, {'success': true});
      _showSuccessSnackBar('Post created successfully!');
    } catch (e) {
      print('❌ Error creating post: $e');
      
      String errorMessage = 'Failed to create post';
      if (e.toString().contains('30MB')) {
        errorMessage = 'Video exceeds 30MB limit';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error: Check Supabase bucket permissions';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied: Check storage rules';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timeout: Check internet connection';
      }
      
      _showErrorSnackBar('$errorMessage: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeCurrentMedia() {
    final totalMedia = _selectedImages.length + _selectedVideos.length;
    
    if (totalMedia == 0) return;
    
    setState(() {
      if (_currentPage < _selectedImages.length) {
        // Remove image
        _selectedImages.removeAt(_currentPage);
      } else {
        // Remove video
        final videoIndex = _currentPage - _selectedImages.length;
        _selectedVideos.removeAt(videoIndex);
        if (_videoBytes.length > videoIndex) {
          _videoBytes.removeAt(videoIndex);
        }
        if (_videoControllers.length > videoIndex) {
          _videoControllers[videoIndex]?.dispose();
          _videoControllers.removeAt(videoIndex);
        }
      }
      
      if (_currentPage >= totalMedia - 1 && totalMedia > 1) {
        _currentPage = totalMedia - 2;
      } else if (totalMedia == 0) {
        _currentPage = 0;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildVideoPreview(int videoIndex) {
    final controller = _videoControllers.length > videoIndex 
        ? _videoControllers[videoIndex] 
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video thumbnail from controller or placeholder
        if (controller != null && controller.value.isInitialized)
          VideoPlayer(controller)
        else
          _buildVideoPlaceholderUI(),
        
        // Dark overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
        
        // Video overlay with play button
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        
        // Video info at bottom
        Positioned(
          bottom: 16,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Video indicator badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "VIDEO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Video size info
              if (!kIsWeb && _videoBytes.length > videoIndex)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(_videoBytes[videoIndex].length / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholderUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "VIDEO",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap to play",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final totalMedia = _selectedImages.length + _selectedVideos.length;
    
    if (totalMedia == 0) {
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
            const Icon(Icons.photo_library, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            const Text(
              "No media selected",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Max video size: 30MB",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Supports: .jpg, .png, .mp4, .mov, .avi",
                  style: TextStyle(color: Colors.orange, fontSize: 11),
                ),
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
            itemCount: totalMedia,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                // It's an image
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
              } else {
                // It's a video - get the video index
                final videoIndex = index - _selectedImages.length;
                return _buildVideoPreview(videoIndex);
              }
            },
          ),

          // Media counter
          if (totalMedia > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1}/$totalMedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Media type indicator
          if (totalMedia > 0)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_currentPage < _selectedImages.length)
                      const Icon(Icons.photo, color: Colors.white, size: 16),
                    if (_currentPage < _selectedImages.length)
                      const SizedBox(width: 4),
                    if (_currentPage < _selectedImages.length)
                      const Text(
                        "PHOTO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_currentPage >= _selectedImages.length)
                      const Icon(Icons.videocam, color: Colors.white, size: 16),
                    if (_currentPage >= _selectedImages.length)
                      const SizedBox(width: 4),
                    if (_currentPage >= _selectedImages.length)
                      const Text(
                        "VIDEO",
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

          // Remove button for current media
          if (totalMedia > 0)
            Positioned(
              top: 16,
              right: 60, // Moved to avoid overlap with type indicator
              child: GestureDetector(
                onTap: _removeCurrentMedia,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                      _buildMediaPreview(),
                      // Gallery button only
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF191919),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: _buildMediaButton(
                            icon: Icons.photo_library,
                            label: "Gallery",
                            subLabel: "Select Photos & Videos\nMax 30MB",
                            onTap: _selectMediaFromGallery,
                          ),
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
                // Media summary
                if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedImages.length} photo(s) and ${_selectedVideos.length} video(s) selected',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                if (kIsWeb)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Tip: You can select multiple files at once',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
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