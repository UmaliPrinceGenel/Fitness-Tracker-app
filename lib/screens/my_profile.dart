import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'progress_album_screen.dart';
import 'about_app_screen.dart';
import 'login_screen.dart';
import '../widgets/chatbot_launcher.dart';

class MyProfile extends StatefulWidget {
  final int refreshVersion;
  final bool showChatbot;

  const MyProfile({
    super.key,
    this.refreshVersion = 0,
    this.showChatbot = true,
  });

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  static const double _minValidHeightCm = 80.0;
  static const double _maxValidHeightCm = 250.0;
  static const double _minValidWeightKg = 20.0;
  static const double _maxValidWeightKg = 400.0;
  static const double _minDisplayBmi = 10.0;
  static const double _maxDisplayBmi = 80.0;

  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUpdatingProfile = false;
  String? _profileImageUrl;
  String? _recentProgressImage; // Store the most recent progress image URL
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedFeedbackRating = 0;
  bool _isSubmittingFeedback = false;
  bool _isFeedbackExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentProgressImage();
  }

  @override
  void didUpdateWidget(covariant MyProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      _loadUserData();
      _loadRecentProgressImage();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Widget _buildDefaultProfileImage(double size) {
    return Image.asset(
      'assets/default_picture.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  bool _isPlaceholderProfileUrl(String? url) {
    final normalizedUrl = url?.trim() ?? '';
    return normalizedUrl.isEmpty || normalizedUrl.contains('via.placeholder.com');
  }

  Widget _buildProfileAvatar(double size) {
    final profileImageUrl = _profileImageUrl?.trim();
    if (_isPlaceholderProfileUrl(profileImageUrl)) {
      return _buildDefaultProfileImage(size);
    }

    final imageUrl = profileImageUrl!;

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultProfileImage(size);
      },
    );
  }

  /// ✅ Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          final storedPhotoUrl =
              userData?['photoURL'] ?? userData?['profile']?['photoURL'];
          final hasPlaceholderPhoto =
              !_isPlaceholderProfileUrl(storedPhotoUrl) ? false : (storedPhotoUrl?.toString().trim().isNotEmpty ?? false);

          if (hasPlaceholderPhoto) {
            await _firestore.collection('users').doc(user.uid).update({
              'photoURL': '',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          setState(() {
            _userData = userData;
            _profileImageUrl =
                _isPlaceholderProfileUrl(storedPhotoUrl) ? null : storedPhotoUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ✅ Load the most recent progress image from Firestore subcollection
  Future<void> _loadRecentProgressImage() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      print('🔄 Loading recent progress image...');

      // Get reference to progress images subcollection
      final progressImagesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progressImages');

      // Get all documents from the subcollection
      final querySnapshot = await progressImagesRef.get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        // Sort documents by date (newest first)
        final sortedDocs = querySnapshot.docs.toList()
          ..sort(
            (a, b) => b.id.compareTo(a.id),
          ); // Sort by date string descending

        // Get the most recent document
        final mostRecentDoc = sortedDocs.first;
        final data = mostRecentDoc.data() as Map<String, dynamic>;
        final images = data['urls'] as List<dynamic>?;

        if (images != null && images.isNotEmpty && mounted) {
          // Get the first image from the most recent date
          setState(() {
            _recentProgressImage = images.first as String;
          });
          print('📸 Loaded recent progress image: $_recentProgressImage');
        } else {
          print('ℹ️ No images found in the most recent document');
          if (mounted) {
            setState(() {
              _recentProgressImage = null;
            });
          }
        }
      } else {
        print('ℹ️ No progress images found in subcollection');
        if (mounted) {
          setState(() {
            _recentProgressImage = null;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading recent progress image: $e');
      if (mounted) {
        setState(() {
          _recentProgressImage = null;
        });
      }
    }
  }

  /// ✅ Navigate to Progress Album and refresh when returning
  void _navigateToProgressAlbum() async {
    // Navigate to Progress Album screen and wait for result
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressAlbumScreen()),
    );

    // Refresh the recent progress image when returning from Progress Album
    print('🔄 Returning from Progress Album, refreshing recent image...');
    await _loadRecentProgressImage();
  }

  /// ✅ Calculate age from date of birth
  int? _calculateAge() {
    try {
      final birthdate =
          _userData?['profile']?['birthdate'] ??
          _userData?['profile']?['dateOfBirth'] ??
          _userData?['birthdate'];

      if (birthdate == null) return null;

      DateTime birthDate;
      if (birthdate is Timestamp) {
        birthDate = birthdate.toDate();
      } else if (birthdate is String) {
        birthDate = DateTime.parse(birthdate);
      } else {
        return null;
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      print('Error calculating age: $e');
      return null;
    }
  }

  /// ✅ Calculate BMI
  double? _calculateBMI() {
    final weight = _safeProfileNumber('weight');
    final height = _safeProfileNumber('height');

    if (weight < _minValidWeightKg ||
        weight > _maxValidWeightKg ||
        height < _minValidHeightCm ||
        height > _maxValidHeightCm) {
      return null;
    }

    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);
    if (bmi < _minDisplayBmi || bmi > _maxDisplayBmi) return null;
    return double.parse(bmi.toStringAsFixed(1));
  }

  double _safeProfileNumber(String key) {
    final dynamic nestedValue = _userData?['profile']?[key];
    if (nestedValue is num) return nestedValue.toDouble();
    if (nestedValue is String) return double.tryParse(nestedValue) ?? 0.0;

    final dynamic dottedValue = _userData?['profile.$key'];
    if (dottedValue is num) return dottedValue.toDouble();
    if (dottedValue is String) return double.tryParse(dottedValue) ?? 0.0;
    return 0.0;
  }

  String _formatProfileMetric(String key, String unit) {
    final value = _safeProfileNumber(key);
    final formatted =
        value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$formatted $unit';
  }

  double _weightProgress() {
    final weight = _safeProfileNumber('weight');
    if (weight <= 0) return 0.0;
    return (weight / 100).clamp(0.0, 1.0);
  }

  double _heightProgress() {
    final height = _safeProfileNumber('height');
    if (height <= 0) return 0.0;
    return (height / 220).clamp(0.0, 1.0);
  }

  double _bmiProgress() {
    final bmi = _calculateBMI() ?? 0.0;
    if (bmi <= 0) return 0.0;
    return (bmi / 40).clamp(0.0, 1.0);
  }

  /// ✅ Delete old avatar from Supabase
  Future<void> _deleteOldAvatar(String oldImageUrl) async {
    try {
      final uri = Uri.parse(oldImageUrl);
      final pathSegments = uri.path.split('/');
      final bucketIndex = pathSegments.indexOf('profile-pictures');

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from('profile-pictures').remove([filePath]);
      print('✅ Old avatar deleted');
    } catch (e) {
      print('❌ Error deleting old avatar: $e');
    }
  }

  /// ✅ FIXED: Use the SAME approach as signup_screen.dart - Uint8List upload
  Future<String> _uploadAvatarToSupabase(
    Uint8List imageBytes,
    String userId,
  ) async {
    try {
      final String fileExtension = 'jpg'; // Default to jpg
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String filePath = '$userId/$fileName';

      print('📤 Uploading avatar bytes: $filePath');

      // ✅ USE THE SAME METHOD AS YOUR WORKING SIGNUP SCREEN
      // Try direct upload with bytes first
      try {
        await _supabase.storage
            .from('profile-pictures')
            .uploadBinary(filePath, imageBytes);

        final String publicURL = _supabase.storage
            .from('profile-pictures')
            .getPublicUrl(filePath);

        print('✅ Avatar uploaded successfully with bytes: $publicURL');
        return publicURL;
      } catch (e) {
        print('❌ Binary upload failed, trying alternative: $e');

        // Fallback: Convert to File and upload (for mobile)
        try {
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(imageBytes);

          await _supabase.storage
              .from('profile-pictures')
              .upload(filePath, tempFile);

          final String publicURL = _supabase.storage
              .from('profile-pictures')
              .getPublicUrl(filePath);

          // Clean up temp file
          await tempFile.delete();

          print('✅ Avatar uploaded successfully with file: $publicURL');
          return publicURL;
        } catch (e2) {
          print('❌ All upload methods failed: $e2');
          throw e;
        }
      }
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      throw e;
    }
  }

  /// ✅ FIXED: Change profile picture - USE BYTES LIKE SIGNUP SCREEN
 Future<void> _changeProfilePicture() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _isUpdatingProfile = true;
        });

        final user = _firebaseAuth.currentUser;
        if (user == null) return;

        // ✅ KEY FIX: Convert to bytes FIRST like your signup screen does
        final Uint8List imageBytes = await pickedFile.readAsBytes();

        print('📸 Image picked, bytes length: ${imageBytes.length}');

        // Delete old avatar if exists and is from Supabase
        final oldAvatarUrl = _profileImageUrl;
        late final String newAvatarUrl;
        try {
          // ✅ USE BYTES UPLOAD LIKE YOUR WORKING SIGNUP SCREEN
          newAvatarUrl = await _uploadAvatarToSupabase(imageBytes, user.uid);
        } catch (uploadError) {
          print('❌ Upload failed: $uploadError');
          throw Exception('Profile picture upload failed: $uploadError');
        }

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': newAvatarUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (oldAvatarUrl != null && oldAvatarUrl.contains('supabase')) {
          await _deleteOldAvatar(oldAvatarUrl);
        }

        // Update local state
        if (mounted) {
          setState(() {
            _profileImageUrl = newAvatarUrl;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error changing profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  /// ✅ Change display name
  Future<void> _changeDisplayName() async {
    final TextEditingController nameController = TextEditingController(
      text: _userData?['displayName'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Change Display Name",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter your display name",
              hintStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a display name'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _updateDisplayName(newName);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                "SAVE",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Update display name in Firestore
  Future<void> _updateDisplayName(String newName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      if (mounted) {
        setState(() {
          _isUpdatingProfile = true;
        });
      }

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(newName);

      if (mounted) {
        setState(() {
          _userData = {...?_userData, 'displayName': newName};
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display name updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating display name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update display name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  /// ✅ Logout user
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                "LOGOUT",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Perform logout operations
  Future<void> _performLogout() async {
    try {
      await _firebaseAuth.signOut();
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Navigate to About This App screen
  void _navigateToAboutApp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutThisAppScreen(),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final user = _firebaseAuth.currentUser;
    final comment = _feedbackController.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to send feedback.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFeedbackRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a star rating first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment for your feedback.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingFeedback = true;
      });
    }

    try {
      final displayName =
          (_userData?['displayName'] ?? user.displayName ?? 'User').toString();
      final email = (_userData?['email'] ?? user.email ?? '').toString();

      await _firestore.collection('user_feedback').add({
        'userId': user.uid,
        'displayName': displayName,
        'email': email,
        'photoURL': _profileImageUrl ?? '',
        'rating': _selectedFeedbackRating,
        'comment': comment,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _feedbackController.clear();
        _selectedFeedbackRating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback sent successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              floating: false,
              snap: false,
              automaticallyImplyLeading: false,
              title: const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _changeProfilePicture,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.blue, Colors.purple],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _buildProfileAvatar(80),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    if (_isUpdatingProfile)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _changeDisplayName,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _userData?['displayName'] ??
                                                  'User',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _userData?['profile']?['gender'] ??
                                                'Not set',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Text(
                                            " | ",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            _formatProfileMetric('height', 'cm'),
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Text(
                                            " | ",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "${_calculateAge()?.toString() ?? '?'} yrs",
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Text(
                              "Health Stats",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildHealthCard(
                                value: _formatProfileMetric('weight', 'kg'),
                                label: "Weight",
                                icon: Icons.monitor_weight,
                                progressValue: _weightProgress(),
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _buildHealthCard(
                                value: _formatProfileMetric('height', 'cm'),
                                label: "Height",
                                icon: Icons.height,
                                progressValue: _heightProgress(),
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildHealthCard(
                                value: _calculateBMI()?.toString() ?? '0',
                                label: "BMI",
                                icon: Icons.monitor_heart,
                                progressValue: _bmiProgress(),
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress Album card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.14),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(0.22),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.photo_library_outlined,
                                            color: Colors.blue,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            "Progress Album",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ),
                                    GestureDetector(
                                      onTap: _navigateToProgressAlbum,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF3EA6FF), Color(0xFF67C3FF)],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF3EA6FF).withOpacity(0.22),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          "View",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Latest photo from your album",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 208,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF202020),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: _recentProgressImage != null
                                        ? Image.network(
                                            _recentProgressImage!,
                                            fit: BoxFit.cover,
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
                                                  return _buildFallbackImage();
                                                },
                                          )
                                        : _buildFallbackImage(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Settings card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF191919),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "App Information",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Version
                                _buildSettingsItem(
                                  icon: Icons.info,
                                  title: "Version",
                                  color: const Color.fromARGB(
                                    255,
                                    112,
                                    90,
                                    221,
                                  ),
                                  trailing: const Text(
                                    "DEV0.0.5",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // About this app
                                GestureDetector(
                                  onTap: _navigateToAboutApp,
                                  child: _buildSettingsItem(
                                    icon: Icons.info_outline,
                                    title: "About this app",
                                    color: Colors.lightBlue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isFeedbackExpanded = !_isFeedbackExpanded;
                                    });
                                  },
                                  child: _buildSettingsItem(
                                    icon: Icons.rate_review_outlined,
                                    title: "User Feedback",
                                    color: Colors.amber,
                                    trailing: AnimatedRotation(
                                      turns: _isFeedbackExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeInOut,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey[500],
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRect(
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 320),
                                    curve: Curves.easeInOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: AnimatedSlide(
                                      duration: const Duration(milliseconds: 320),
                                      curve: Curves.easeInOutCubic,
                                      offset: _isFeedbackExpanded
                                          ? Offset.zero
                                          : const Offset(0, -0.08),
                                      child: _isFeedbackExpanded
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: _buildFeedbackCard(),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // ✅ LOGOUT BUTTON - Mobile only
                          if (!kIsWeb) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: ElevatedButton(
                                onPressed: _logout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.85),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 10),
                        ],
                      ),
              ),
            ),
              ],
            ),
          ),
          if (widget.showChatbot)
            const ChatbotLauncher(title: 'Profile Chat'),
        ],
      ),
    );
  }

  /// ✅ Build fallback image when no progress image is available
  Widget _buildFallbackImage() {
    return Stack(
      children: [
        Image.asset(
          'assets/album.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          color: Colors.black.withOpacity(0.58),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.34),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, color: Colors.white70, size: 42),
                  SizedBox(height: 10),
                  Text(
                    "No progress photos yet",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.22)),
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rate your experience and send comments directly to admin.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Star Rating',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final isSelected = ratingValue <= _selectedFeedbackRating;

              return InkWell(
                onTap: _isSubmittingFeedback
                    ? null
                    : () {
                        setState(() {
                          _selectedFeedbackRating = ratingValue;
                        });
                      },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber.withOpacity(0.16)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.white12,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _feedbackController,
            enabled: !_isSubmittingFeedback,
            maxLines: 4,
            maxLength: 400,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your experience, suggestions, or any issue.',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              counterStyle: const TextStyle(color: Colors.white38),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingFeedback ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.orange.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSubmittingFeedback
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmittingFeedback ? 'Submitting...' : 'Submit',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Build health stat card
  Widget _buildHealthCard({
    required String value,
    required String label,
    required IconData icon,
    required double progressValue,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 8.0,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(icon, color: Colors.white, size: 30),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Build settings item
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          trailing ??
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
        ],
      ),
    );
  }
}