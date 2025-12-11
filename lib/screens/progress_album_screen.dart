import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // Add this import
import 'photo_editing_screen.dart'; // Add this import

class ProgressAlbumScreen extends StatefulWidget {
  const ProgressAlbumScreen({super.key});

  @override
  State<ProgressAlbumScreen> createState() => _ProgressAlbumScreenState();
}

class _ProgressAlbumScreenState extends State<ProgressAlbumScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Store progress images with date as key and list of image URLs
  Map<String, List<String>> _progressImages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProgressImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ Get current user ID from Firebase Auth
  String? get _currentUserId {
    return _firebaseAuth.currentUser?.uid;
  }

  /// ✅ Get reference to progress images subcollection
  CollectionReference get _progressImagesRef {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progressImages');
  }

  /// ✅ Load progress images from Firebase Firestore subcollection
  Future<void> _loadProgressImages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No user logged in with Firebase Auth');
        return;
      }

      print(
        '👤 Loading progress images from Firestore subcollection for user: $userId',
      );

      // Load from Firestore subcollection
      final querySnapshot = await _progressImagesRef.get();

      print('📄 Found ${querySnapshot.docs.length} documents in subcollection');

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, List<String>> loadedImages = {};

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = doc.id; // Use document ID as date
          final images = data['urls'] as List<dynamic>?;

          if (images != null) {
            loadedImages[date] = List<String>.from(images);
            print('📅 Date: $date, Images: ${images.length}');
          }
        }

        setState(() {
          _progressImages = loadedImages;
        });

        print(
          '📷 Loaded ${_progressImages.length} date groups from Firestore subcollection',
        );
      } else {
        print('ℹ️ No progress images found in Firestore subcollection');
        // Also try to load from Supabase storage for backward compatibility
        await _loadFromSupabaseStorage();
      }
    } catch (e) {
      print('❌ Error loading progress images from Firestore subcollection: $e');
      // Fallback to loading from Supabase storage
      await _loadFromSupabaseStorage();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Fallback: Load images from Supabase storage (for backward compatibility)
  Future<void> _loadFromSupabaseStorage() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      print('🔄 Loading from Supabase storage as fallback');

      final response = await _supabase.storage
          .from('progress-images')
          .list(path: userId);

      print('📷 Found ${response.length} images in Supabase storage');
      _groupImagesByDate(response);

      // Save to Firestore subcollection for future use
      await _saveProgressImagesToFirestore();
        } catch (e) {
      print('❌ Error loading from Supabase storage: $e');
    }
  }

  /// ✅ Group images by date for display
  void _groupImagesByDate(List<FileObject> files) {
    Map<String, List<String>> newProgressImages = {};

    for (final file in files) {
      try {
        final userId = _currentUserId;
        if (userId == null) continue;

        final publicUrl = _supabase.storage
            .from('progress-images')
            .getPublicUrl('$userId/${file.name}');

        // Use today's date for grouping (you might want to extract from filename)
        final today = DateTime.now();
        final formattedDate = _formatDate(today);

        if (!newProgressImages.containsKey(formattedDate)) {
          newProgressImages[formattedDate] = [];
        }
        newProgressImages[formattedDate]!.add(publicUrl);

        print('🖼️ Added image: ${file.name} for date: $formattedDate');
      } catch (e) {
        print('❌ Error processing file ${file.name}: $e');
      }
    }

    setState(() {
      _progressImages = newProgressImages;
    });
  }

  /// ✅ Save progress images to Firebase Firestore subcollection
  Future<void> _saveProgressImagesToFirestore() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Save each date as a separate document in the subcollection
      final batch = _firestore.batch();

      for (final entry in _progressImages.entries) {
        final date = entry.key;
        final urls = entry.value;

        final docRef = _progressImagesRef.doc(date);
        batch.set(docRef, {
          'urls': urls,
          'updatedAt': FieldValue.serverTimestamp(),
          'count': urls.length,
        });
      }

      await batch.commit();
      print('💾 Progress images saved to Firestore subcollection');
    } catch (e) {
      print('❌ Error saving progress images to Firestore subcollection: $e');
    }
  }

  /// ✅ Save a single date's images to Firestore subcollection
  Future<void> _saveDateToFirestore(String date, List<String> urls) async {
    try {
      await _progressImagesRef.doc(date).set({
        'urls': urls,
        'updatedAt': FieldValue.serverTimestamp(),
        'count': urls.length,
      });
      print(
        '💾 Saved date $date with ${urls.length} images to Firestore subcollection',
      );
    } catch (e) {
      print('❌ Error saving date $date to Firestore: $e');
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// ✅ Upload image to Supabase and save URL to Firebase subcollection
  Future<void> _uploadProgressImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        final userId = _currentUserId;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to upload images'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print('👤 Uploading for user: $userId');

        // Convert to bytes
        final Uint8List imageBytes = await pickedFile.readAsBytes();

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'progress_$timestamp.jpg';
        final filePath = '$userId/$fileName';

        print('📤 Uploading progress image: $filePath');

        // Upload to Supabase
        await _supabase.storage
            .from('progress-images')
            .uploadBinary(filePath, imageBytes);

        // Get public URL
        final publicUrl = _supabase.storage
            .from('progress-images')
            .getPublicUrl(filePath);

        print('✅ Progress image uploaded: $publicUrl');

        // Update local state with new image
        final today = DateTime.now();
        final formattedDate = _formatDate(today);

        setState(() {
          if (!_progressImages.containsKey(formattedDate)) {
            _progressImages[formattedDate] = [];
          }
          _progressImages[formattedDate]!.insert(0, publicUrl);
        });

        // Save to Firebase Firestore subcollection
        await _saveDateToFirestore(
          formattedDate,
          _progressImages[formattedDate]!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading progress image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Delete progress image
  Future<void> _deleteProgressImage(String date, int index) async {
    try {
      final imageUrl = _progressImages[date]![index];

      // Extract filename from URL for Supabase deletion
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.path.split('/');
      final bucketIndex = pathSegments.indexOf('progress-images');

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('progress-images').remove([filePath]);
        print('🗑️ Deleted image from Supabase: $filePath');
      }

      // Update local state
      setState(() {
        _progressImages[date]!.removeAt(index);
        if (_progressImages[date]!.isEmpty) {
          _progressImages.remove(date);
          // Remove the entire document from Firestore if no images left
          _progressImagesRef.doc(date).delete();
        }
      });

      // Update Firebase Firestore subcollection
      if (_progressImages.containsKey(date)) {
        await _saveDateToFirestore(date, _progressImages[date]!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ NEW: Handle share to community - navigate to PhotoEditingScreen with selected images
  Future<void> _handleShareToCommunity(String date) async {
    final images = _progressImages[date] ?? [];

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images to share from this date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image URLs to Uint8List for the photo editor
      List<Uint8List> imageBytesList = [];

      for (final imageUrl in images) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytesList.add(response.bodyBytes);
          }
        } catch (e) {
          print('Error loading image: $e');
        }
      }

      if (imageBytesList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load images for sharing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to PhotoEditingScreen with the images
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressPhotoEditingScreen(
            progressImages: imageBytesList,
            initialCaption: "My progress from $date 💪",
          ),
        ),
      );
    } catch (e) {
      print('Error sharing to community: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Progress Album",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: _isLoading ? null : _uploadProgressImage,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Tab bar with Recent and Old tabs
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                        _tabController.animateTo(0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Recent',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                        _tabController.animateTo(1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Old',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab content with scrollable date cards
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRecentContent(), _buildOldContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    final dates = _progressImages.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = 0; i < dates.length; i++) ...[
            if (_progressImages[dates[i]]!.isNotEmpty) ...[
              _buildDateCard(dates[i]),
              if (i < dates.length - 1) const SizedBox(height: 16),
            ],
          ],
          if (_progressImages.isEmpty ||
              _progressImages.values.every((list) => list.isEmpty))
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildOldContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    final dates = _progressImages.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = dates.length - 1; i >= 0; i--) ...[
            if (_progressImages[dates[i]]!.isNotEmpty) ...[
              _buildDateCard(dates[i]),
              if (i > 0) const SizedBox(height: 16),
            ],
          ],
          if (_progressImages.isEmpty ||
              _progressImages.values.every((list) => list.isEmpty))
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            "No progress images yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first progress photo",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String date) {
    final images = _progressImages[date] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  color: Colors.grey[800],
                  onSelected: (String result) {
                    if (result == 'share_community') {
                      _handleShareToCommunity(date);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'share_community',
                          child: Text(
                            'Share to Community',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Share",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: _buildImagesGrid(images, date),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid(List<String> imageUrls, String date) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPress: () => _showDeleteDialog(date, index),
          onTap: () => _showImageZoom(imageUrls[index]),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 32);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String date, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Delete Image",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this image?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProgressImage(date, index);
              },
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
  }

  void _showImageZoom(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ImageZoomOverlay(imageUrl: imageUrl),
      ),
    );
  }
}

class _ImageZoomOverlay extends StatelessWidget {
  final String imageUrl;

  const _ImageZoomOverlay({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Hero(
                    tag: 'zoomImage',
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 64,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
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

// NEW: Custom PhotoEditingScreen for progress images
class ProgressPhotoEditingScreen extends StatefulWidget {
  final List<Uint8List> progressImages;
  final String initialCaption;

  const ProgressPhotoEditingScreen({
    super.key,
    required this.progressImages,
    this.initialCaption = '',
  });

  @override
  State<ProgressPhotoEditingScreen> createState() =>
      _ProgressPhotoEditingScreenState();
}

class _ProgressPhotoEditingScreenState
    extends State<ProgressPhotoEditingScreen> {
  final List<Uint8List> _selectedImages = [];
  final TextEditingController _captionController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  bool _isUploading = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption;
    _selectedImages.addAll(widget.progressImages);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
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

      _showSuccessSnackBar('Progress shared to community successfully!');
    } catch (e) {
      print('Error creating post: $e');
      _showErrorSnackBar('Failed to share progress: ${e.toString()}');
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
          "Share Progress",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
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
                  child: Column(children: [_buildImagePreview()]),
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
                      hintText: "Share your progress story...",
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
}
