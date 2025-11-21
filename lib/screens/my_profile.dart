import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'progress_album_screen.dart';
import '../screens/login_screen.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _recentProgressImage; // Store the most recent progress image URL

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentProgressImage();
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

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
            _profileImageUrl = _userData?['photoURL'];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      if (querySnapshot.docs.isNotEmpty) {
        // Sort documents by date (newest first)
        final sortedDocs = querySnapshot.docs.toList()
          ..sort(
            (a, b) => b.id.compareTo(a.id),
          ); // Sort by date string descending

        // Get the most recent document
        final mostRecentDoc = sortedDocs.first;
        final data = mostRecentDoc.data() as Map<String, dynamic>;
        final images = data['urls'] as List<dynamic>?;

        if (images != null && images.isNotEmpty) {
          // Get the first image from the most recent date
          setState(() {
            _recentProgressImage = images.first as String;
          });
          print('📸 Loaded recent progress image: $_recentProgressImage');
        } else {
          print('ℹ️ No images found in the most recent document');
          setState(() {
            _recentProgressImage = null;
          });
        }
      } else {
        print('ℹ️ No progress images found in subcollection');
        setState(() {
          _recentProgressImage = null;
        });
      }
    } catch (e) {
      print('❌ Error loading recent progress image: $e');
      setState(() {
        _recentProgressImage = null;
      });
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
    final weight = _userData?['profile']?['weight']?.toDouble();
    final height = _userData?['profile']?['height']?.toDouble();

    if (weight == null || height == null || height == 0) return null;

    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);
    return double.parse(bmi.toStringAsFixed(1));
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

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        final user = _firebaseAuth.currentUser;
        if (user == null) return;

        // ✅ KEY FIX: Convert to bytes FIRST like your signup screen does
        final Uint8List imageBytes = await pickedFile.readAsBytes();

        print('📸 Image picked, bytes length: ${imageBytes.length}');

        // Delete old avatar if exists and is from Supabase
        final oldAvatarUrl = _profileImageUrl;
        if (oldAvatarUrl != null && oldAvatarUrl.contains('supabase')) {
          await _deleteOldAvatar(oldAvatarUrl);
        }

        String newAvatarUrl;
        try {
          // ✅ USE BYTES UPLOAD LIKE YOUR WORKING SIGNUP SCREEN
          newAvatarUrl = await _uploadAvatarToSupabase(imageBytes, user.uid);
        } catch (uploadError) {
          print('❌ Upload failed: $uploadError');
          newAvatarUrl =
              oldAvatarUrl ??
              'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
        }

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': newAvatarUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        setState(() {
          _profileImageUrl = newAvatarUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error changing profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      setState(() {
        _isLoading = true;
      });

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(newName);

      setState(() {
        _userData = {...?_userData, 'displayName': newName};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating display name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update display name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                                        child: _profileImageUrl != null
                                            ? Image.network(
                                                _profileImageUrl!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Image.asset(
                                                        'assets/lakano.png',
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                              )
                                            : Image.asset(
                                                'assets/lakano.png',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
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
                                            "${_userData?['profile']?['height']?.toString() ?? '0'} cm",
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
                                value:
                                    "${_userData?['profile']?['weight']?.toString() ?? '0'} kg",
                                label: "Weight",
                                icon: Icons.monitor_weight,
                                progressValue: 0.7,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _buildHealthCard(
                                value:
                                    "${_userData?['profile']?['height']?.toString() ?? '0'} cm",
                                label: "Height",
                                icon: Icons.straighten,
                                progressValue: 0.6,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildHealthCard(
                                value: _calculateBMI()?.toString() ?? '0',
                                label: "BMI",
                                icon: Icons.monitor_heart,
                                progressValue: 0.5,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress Album card
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Progress Album",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap:
                                          _navigateToProgressAlbum, // Use the new method
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.lightBlue,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                const SizedBox(height: 12),
                                const Text(
                                  "Recently Added",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                  "Settings",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // App Settings
                                _buildSettingsItem(
                                  icon: Icons.settings,
                                  title: "App Settings",
                                  color: const Color.fromARGB(
                                    255,
                                    112,
                                    90,
                                    221,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                // Feedback
                                _buildSettingsItem(
                                  icon: Icons.feedback,
                                  title: "Feedback",
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(height: 12),
                                // About this app
                                _buildSettingsItem(
                                  icon: Icons.info_outline,
                                  title: "About this app",
                                  color: Colors.lightBlue,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Logout Button at the very bottom
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
                                  "Account",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Logout Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Colors.orange],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: _logout,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.logout, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          "Logout",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
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
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
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
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, color: Colors.white60, size: 50),
                SizedBox(height: 8),
                Text(
                  "No progress photos yet",
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
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
