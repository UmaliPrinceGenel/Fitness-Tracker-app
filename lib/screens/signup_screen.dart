import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
// Add this at the top of the file if not already present
import 'package:flutter/foundation.dart' show kIsWeb;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final SupabaseClient _supabase = Supabase.instance.client;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<fbAuth.User?>? _authStateSubscription;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    // Start checking for verification immediately for any existing users
    _startVerificationChecker();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authStateSubscription?.cancel();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  /// ✅ Start automatic verification checking
  void _startVerificationChecker() {
    // Check every 3 seconds if there's a logged-in user who needs verification
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      _checkForVerifiedUser();
    });
  }

  /// ✅ Check if current user is verified
  Future<void> _checkForVerifiedUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        // Reload user to get latest status
        await user.reload();
        final updatedUser = _firebaseAuth.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          // User just got verified!
          print(
            '🎉 Auto-detected email verification for: ${updatedUser.email}',
          );
          await _handleVerifiedUser(updatedUser);
        }
      }
    } catch (e) {
      print('Error in auto verification check: $e');
    }
  }

  /// ✅ Handle verified user - FIXED VERSION
  Future<void> _handleVerifiedUser(fbAuth.User user) async {
    try {
      // Update Firestore
      await _updateUserVerificationStatus(user);

      // Stop the timer
      _verificationCheckTimer?.cancel();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ FIXED: Sign out user first, then navigate to login
        await _firebaseAuth.signOut();

        // Navigate to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error handling verified user: $e');
    }
  }

  /// ✅ Download image from URL and convert to bytes
  Future<Uint8List> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading image: $e');
      rethrow;
    }
  }

  /// ✅ Convert Uint8List to temporary File
  Future<File> _convertToFile(Uint8List bytes, String fileName) async {
    // Create a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// ✅ Upload image to Supabase bucket
  Future<String> _uploadImageToSupabase(
    Uint8List imageBytes,
    String userId,
    String imageType,
  ) async {
    try {
      final String fileExtension = 'jpg';
      final String fileName = imageType == 'google'
          ? 'google_avatar'
          : 'default_picture';
      final String filePath =
          '$userId/${fileName}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Convert Uint8List to File
      final File imageFile = await _convertToFile(
        imageBytes,
        '$fileName.$fileExtension',
      );

      // Upload to Supabase storage
      await _supabase.storage
          .from('profile-pictures')
          .upload(filePath, imageFile);

      // Get public URL
      final String publicURL = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(filePath);

      print('✅ Image uploaded to Supabase: $publicURL');

      // Clean up temporary file
      await imageFile.delete();

      return publicURL;
    } catch (e) {
      print('❌ Error uploading image to Supabase: $e');
      return 'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
    }
  }

  /// ✅ Direct upload without file conversion
  Future<String> _directUploadToSupabase(
    Uint8List imageBytes,
    String userId,
    String imageType,
  ) async {
    try {
      final String fileExtension = 'jpg';
      final String fileName = imageType == 'google'
          ? 'google_avatar'
          : 'default_picture';
      final String filePath =
          '$userId/${fileName}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Try uploadBinary method which accepts Uint8List directly
      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final String publicURL = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(filePath);

      print('✅ Image uploaded to Supabase (direct): $publicURL');
      return publicURL;
    } catch (e) {
      print('❌ Error in direct upload: $e');
      return 'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
    }
  }

  /// ✅ Upload default profile picture from assets to Supabase
  Future<String> _uploadDefaultProfilePicture(String userId) async {
    try {
      // Load default profile picture from assets
      final ByteData byteData = await rootBundle.load(
        'assets/default_picture.jpg',
      );
      final Uint8List imageBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // Try direct upload first, fallback to file upload
      try {
        return await _directUploadToSupabase(imageBytes, userId, 'default');
      } catch (e) {
        print('Direct upload failed, trying file upload: $e');
        return await _uploadImageToSupabase(imageBytes, userId, 'default');
      }
    } catch (e) {
      print('Error uploading default profile: $e');
      return 'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
    }
  }

  /// ✅ Download and upload Google profile picture to Supabase
  Future<String> _uploadGoogleProfilePicture(
    String googlePhotoUrl,
    String userId,
  ) async {
    try {
      // Download Google profile picture
      final Uint8List imageBytes = await _downloadImage(googlePhotoUrl);

      // Try direct upload first, fallback to file upload
      try {
        return await _directUploadToSupabase(imageBytes, userId, 'google');
      } catch (e) {
        print('Direct upload failed, trying file upload: $e');
        return await _uploadImageToSupabase(imageBytes, userId, 'google');
      }
    } catch (e) {
      print('Error uploading Google profile: $e');
      return await _uploadDefaultProfilePicture(userId);
    }
  }

  /// ✅ Get user photo URL
  Future<String> _getUserPhotoURL(fbAuth.User user) async {
    try {
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        print('🔄 Downloading Google profile picture: ${user.photoURL}');
        return await _uploadGoogleProfilePicture(user.photoURL!, user.uid);
      }

      print('🔄 Using default profile picture');
      return await _uploadDefaultProfilePicture(user.uid);
    } catch (e) {
      print('❌ Error getting user photo URL: $e');
      return 'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
    }
  }

  /// ✅ Sync Firebase user to Firestore with Supabase photo URLs
  Future<void> _syncUserWithFirestore(fbAuth.User fbUser) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .get();

      String photoURL = await _getUserPhotoURL(fbUser);

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(fbUser.uid).set({
          'uid': fbUser.uid,
          'email': fbUser.email,
          'displayName': fbUser.displayName ?? fbUser.email!.split('@')[0],
          'photoURL': photoURL,
          'provider': fbUser.providerData.first.providerId,
          'emailVerified': fbUser.emailVerified,
          'hasCompletedProfile': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User created in Firestore: ${fbUser.email}');
        print('✅ Profile picture saved to: $photoURL');
      } else {
        await _firestore.collection('users').doc(fbUser.uid).update({
          'photoURL': photoURL,
          'emailVerified': fbUser.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('ℹ️ User updated in Firestore: ${fbUser.email}');
      }
    } catch (e) {
      print('❌ Error syncing user to Firestore: $e');
      rethrow;
    }
  }

  /// ✅ Update user verification status in Firestore
  Future<void> _updateUserVerificationStatus(fbAuth.User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        '✅ Updated verification status for ${user.email}: ${user.emailVerified}',
      );
    } catch (e) {
      print('❌ Error updating verification status: $e');
    }
  }

  /// ✅ Check email verification status manually
  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _firebaseAuth.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          await _updateUserVerificationStatus(updatedUser);
          await _firebaseAuth.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email not verified yet. Please check your inbox.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        _showEmailVerificationDialog();
      }
    } catch (e) {
      print('Error checking verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ Show dialog for email verification check
  void _showEmailVerificationDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Check Email Verification',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter your email address to check verification status:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Gmail-only validation
                  final trimmedValue = value.trim().toLowerCase();
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmedValue)) {
                    return 'Please enter a valid email';
                  }
                  if (!trimmedValue.endsWith('@gmail.com')) {
                    return 'Only @gmail.com addresses are allowed';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email address'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _checkVerificationByEmail(email);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Check Status',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Check verification by email
  Future<void> _checkVerificationByEmail(String email) async {
    setState(() => _isLoading = true);
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userDoc = usersQuery.docs.first;
        final userData = userDoc.data();
        final bool isVerified = userData['emailVerified'] ?? false;
        _showVerificationResultDialog(email, isVerified);
      } else {
        _showVerificationResultDialog(email, false, userExists: false);
      }
    } catch (e) {
      print('Error checking verification by email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking verification status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Show verification result dialog
  void _showVerificationResultDialog(
    String email,
    bool isVerified, {
    bool userExists = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Verification Status',
            style: TextStyle(color: isVerified ? Colors.green : Colors.orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: $email',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (!userExists) ...[
                const Text(
                  '❌ No account found with this email address.',
                  style: TextStyle(color: Colors.red),
                ),
              ] else if (isVerified) ...[
                const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '✅ Email is verified!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can now log in to your account.',
                  style: TextStyle(color: Colors.white70),
                ),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      '⏳ Email not verified yet',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your inbox for the verification link and click it to verify your email.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
          actions: [
            if (isVerified && userExists) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(prefilledEmail: email),
                    ),
                  );
                },
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                isVerified && userExists ? 'Stay Here' : 'OK',
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Sign up with email and password
  Future<void> _signUpWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      
      // Additional Gmail validation before Firebase call
      if (!email.endsWith('@gmail.com')) {
        throw fbAuth.FirebaseAuthException(
          code: 'invalid-email',
          message: 'Only @gmail.com addresses are allowed',
        );
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final fbUser = credential.user;
      if (fbUser != null) {
        await fbUser.updateDisplayName(
          email.split('@')[0],
        );

        await fbUser.sendEmailVerification();
        await _syncUserWithFirestore(fbUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Check your email for verification.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        _showVerificationDialog(fbUser);
      }
    } on fbAuth.FirebaseAuthException catch (e) {
      print('Firebase signup error: $e');
      String errorMessage = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address. Only @gmail.com addresses are allowed.';
      } else {
        errorMessage = 'Signup failed: ${e.message}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      print('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Show verification dialog after signup
  void _showVerificationDialog(fbAuth.User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Verify Your Email',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We sent a verification link to your email. Please check your inbox and verify your email address to continue.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We\'ll automatically detect when you verify your email',
                        style: TextStyle(
                          color: Colors.orange[100],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Auto-verification detection is active. You can verify your email anytime.',
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkEmailVerification();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Check Now',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ FIXED: Google sign-up with platform-specific implementation
  /// ✅ IMPROVED: Google sign-up with better mobile support
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final fbAuth.GoogleAuthProvider googleProvider =
          fbAuth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      fbAuth.UserCredential userCredential;

      if (kIsWeb) {
        // For web platforms
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms (Android/iOS) - use signInWithProvider
        // This is the correct approach for mobile platforms
        userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      // Wait a moment for the auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the current user
      final fbUser = _firebaseAuth.currentUser;

      if (fbUser != null) {
        // ✅ Check if this Google account has a Gmail email
        final userEmail = fbUser.email?.toLowerCase() ?? '';
        if (!userEmail.endsWith('@gmail.com')) {
          await _firebaseAuth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only @gmail.com accounts are allowed for Google sign-up'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // ✅ Check if this Google account is already registered in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(fbUser.uid)
            .get();

        if (userDoc.exists) {
          // Google account is already registered - show detailed dialog
          await _firebaseAuth.signOut();
          await _showAccountAlreadyRegisteredDialog(
            fbUser.email ?? 'this Google account',
          );
          return;
        }

        // ✅ New Google account - proceed with registration
        await _syncUserWithFirestore(fbUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed up successfully with Google!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        throw Exception('Google sign-in failed: No user returned');
      }
    } on fbAuth.FirebaseAuthException catch (e) {
      await _handleGoogleSignUpError(e);
    } catch (e) {
      print('Google Sign-In error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign up with Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Handle Google sign-in result
  Future<void> _handleGoogleSignInResult(fbAuth.User? fbUser) async {
    if (fbUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Google'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check Gmail requirement for Google sign-in
    final userEmail = fbUser.email?.toLowerCase() ?? '';
    if (!userEmail.endsWith('@gmail.com')) {
      await _firebaseAuth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only @gmail.com accounts are allowed for Google sign-up'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user already exists
    final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();

    if (userDoc.exists) {
      // User already exists - show message and go to login
      await _firebaseAuth.signOut(); // Only sign out from Firebase
      await _showAccountAlreadyRegisteredDialog(
        fbUser.email ?? 'this Google account',
      );
      return;
    }
    // New user - sync with Firestore
    await _syncUserWithFirestore(fbUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed up successfully with Google!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  /// ✅ Show dialog for already registered account
  Future<void> _showAccountAlreadyRegisteredDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Account Already Exists',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'The Google account $email is already registered with our app.\n\nPlease use the login screen to access your account.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'GO TO LOGIN',
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

  /// ✅ Handle Google sign-up errors
  Future<void> _handleGoogleSignUpError(fbAuth.FirebaseAuthException e) async {
    print('Google Sign-In error: $e');

    String errorMessage = 'Failed to sign up with Google';
    String errorDetails = '';

    if (e.code == 'account-exists-with-different-credential') {
      errorMessage = 'Account Already Exists';
      errorDetails =
          'This email is already registered with a different sign-in method. Please try logging in with your original method.';
    } else if (e.code == 'email-already-in-use') {
      errorMessage = 'Email Already Registered';
      errorDetails =
          'This email address is already associated with an account. Please log in instead.';
    } else if (e.code == 'operation-not-allowed') {
      errorMessage = 'Sign-in Method Not Available';
      errorDetails =
          'Google sign-in is currently not available. Please try another method or contact support.';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'Account Disabled';
      errorDetails =
          'This account has been disabled. Please contact support for assistance.';
    } else {
      errorMessage = 'Sign-up Failed';
      errorDetails = 'Failed to sign up with Google: ${e.message}';
    }

    // Show error dialog for important errors
    if (e.code == 'account-exists-with-different-credential' ||
        e.code == 'email-already-in-use') {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              errorDetails,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'GO TO LOGIN',
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorDetails),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF191919),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Create Your Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Are you ready to join the Rockies Fitness Gym Community? Set Up your account now!!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            decoration: const BoxDecoration(
                              color: Color(0xFF191919),
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        controller: _emailController,
                                        enabled: !_isLoading,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: "Email",
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          hintText: "example@gmail.com",
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          
                                          // Check if it's a valid email format
                                          final trimmedValue = value.trim().toLowerCase();
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmedValue)) {
                                            return 'Please enter a valid email';
                                          }
                                          
                                          // Gmail-only validation
                                          if (!trimmedValue.endsWith('@gmail.com')) {
                                            return 'Only @gmail.com addresses are allowed';
                                          }
                                          
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        controller: _passwordController,
                                        enabled: !_isLoading,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: "Password",
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.white70,
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    });
                                                  },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        enabled: !_isLoading,
                                        obscureText: _obscureConfirmPassword,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: "Confirm Password",
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.white70,
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _obscureConfirmPassword =
                                                          !_obscureConfirmPassword;
                                                    });
                                                  },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _signUpWithEmail,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.black),
                                                ),
                                              )
                                            : const Text(
                                                "Register",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),

                                    // Updated verification check button
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _checkEmailVerification,
                                      child: const Text(
                                        "Check Email Verification Status",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    const Text(
                                      "By clicking this button, you agree with our ",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const TermsAndConditionsScreen(),
                                                ),
                                              );
                                            },
                                      child: const Text(
                                        "Terms and Conditions",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: Colors.white38,
                                            thickness: 1,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            "Sign Up with",
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: Colors.white38,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    InkWell(
                                      onTap: _isLoading
                                          ? null
                                          : _signUpWithGoogle,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          "assets/google.png",
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Already have an account?",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const LoginScreen(),
                                                    ),
                                                  );
                                                },
                                          child: const Text(
                                            "Log In",
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
