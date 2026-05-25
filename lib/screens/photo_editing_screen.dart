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
import '../widgets/premium_dialog.dart';

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
      builder: (context) => PremiumDialog(
        title: "Select Media Type",
        icon: Icons.perm_media_rounded,
        iconColor: const Color(0xFF3EA6FF),
        content: const Text(
          "Choose what type of media you want to select:",
        ),
        actions: [
          PremiumCancelButton(
            label: "Cancel",
            onPressed: () => Navigator.pop(context, 'cancel'),
          ),
          PremiumConfirmButton(
            label: "Photos",
            onPressed: () => Navigator.pop(context, 'image'),
          ),
          PremiumConfirmButton(
            label: "Videos",
            gradientColors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
            onPressed: () => Navigator.pop(context, 'video'),
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
        height: 280,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.02),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.deepOrange.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.15),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.orange,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Add photos or videos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Supports multiple high-quality images and videos",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                "Max video size: 30MB",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        color: Color(0xFF1A1A1A),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: PageView.builder(
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
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  '${_currentPage + 1}/$totalMedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    if (_currentPage < _selectedImages.length)
                      const Icon(Icons.photo_rounded, color: Color(0xFF3EA6FF), size: 16),
                    if (_currentPage < _selectedImages.length)
                      const SizedBox(width: 6),
                    if (_currentPage < _selectedImages.length)
                      const Text(
                        "PHOTO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    if (_currentPage >= _selectedImages.length)
                      const Icon(Icons.videocam_rounded, color: Color(0xFFFF6B6B), size: 16),
                    if (_currentPage >= _selectedImages.length)
                      const SizedBox(width: 6),
                    if (_currentPage >= _selectedImages.length)
                      const Text(
                        "VIDEO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
              right: totalMedia > 1 ? 64 : 16, // Adjust layout based on sibling visibility
              child: GestureDetector(
                onTap: _removeCurrentMedia,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
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
        toolbarHeight: 80,
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () {
              _showDiscardDialog(context);
            },
          ),
        ),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 16, top: 18, bottom: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A00), Color(0xFFFF5200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5200).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _handlePost,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Post",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.12),
                            Colors.deepOrange.withOpacity(0.04),
                            Colors.black.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Share your workout moment",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Add photos or videos, then write a short caption for your community post.",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMediaPreview(),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: _buildMediaButton(
                              icon: Icons.photo_library_rounded,
                              label: "Gallery",
                              subLabel: "Select photos and videos\nMax 30MB per video",
                              onTap: _selectMediaFromGallery,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notes_rounded,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Caption",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _captionController,
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.text.length} chars',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: TextField(
                              controller: _captionController,
                              decoration: const InputDecoration(
                                hintText: "Write a caption...",
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              maxLines: 4,
                              minLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selected Media",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildSummaryPill(
                                    icon: Icons.photo_rounded,
                                    label: '${_selectedImages.length} photo(s)',
                                    accent: const Color(0xFF3EA6FF),
                                  ),
                                  _buildSummaryPill(
                                    icon: Icons.videocam_rounded,
                                    label: '${_selectedVideos.length} video(s)',
                                    accent: const Color(0xFFFF6B6B),
                                  ),
                                ],
                              ),
                              if (kIsWeb) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lightbulb_outline_rounded,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          "Tip: You can select multiple files at once in the explorer window.",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9A00), Color(0xFFFF5200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5200).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.orange,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
        return PremiumDialog(
          title: "Discard Post",
          icon: Icons.delete_sweep_rounded,
          iconColor: const Color(0xFFFF4B4B),
          content: const Text(
            "Are you sure you want to discard this post?",
          ),
          actions: [
            PremiumCancelButton(
              label: "Keep Editing",
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            PremiumConfirmButton(
              label: "Discard",
              gradientColors: const [Color(0xFFFF4B4B), Color(0xFFFF7B7B)],
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
