import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login_screen.dart';
import '../screens/terms_and_conditions_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocument(
    String uid,
  ) async {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<File> _convertToFile(Uint8List bytes, String fileName) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<String> _uploadDefaultProfilePicture(String userId) async {
    try {
      final byteData = await rootBundle.load('assets/default_picture.jpg');
      final imageBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final filePath =
          '$userId/default_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageFile = await _convertToFile(imageBytes, 'default_picture.jpg');

      await _supabase.storage.from('profile-pictures').upload(filePath, imageFile);
      final publicUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(filePath);

      await imageFile.delete();
      return publicUrl;
    } catch (e) {
      return 'https://via.placeholder.com/150/CCCCCC/000000?text=Profile';
    }
  }

  Future<void> _syncUserWithFirestore(fbAuth.User fbUser) async {
    final userDoc = await _getUserDocument(fbUser.uid).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'Firestore operation timed out. Please check your connection and try again.',
        );
      },
    );

    final photoUrl = await _uploadDefaultProfilePicture(fbUser.uid);
    final userData = <String, dynamic>{
      'uid': fbUser.uid,
      'email': fbUser.email,
      'displayName': fbUser.displayName ?? fbUser.email!.split('@')[0],
      'photoURL': photoUrl,
      'provider': 'password',
      'emailVerified': fbUser.emailVerified,
      'hasCompletedProfile': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (userDoc.exists) {
      await _firestore.collection('users').doc(fbUser.uid).update(userData);
      return;
    }

    await _firestore.collection('users').doc(fbUser.uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<fbAuth.UserCredential> _performEmailSignUp() async {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _signUpWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _performEmailSignUp().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw fbAuth.FirebaseAuthException(
            code: 'timeout',
            message:
                'Authentication operation timed out. Please check your connection and try again.',
          );
        },
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Signup failed. No user returned.');
      }

      await fbUser.updateDisplayName(_emailController.text.trim().split('@')[0]);
      await fbUser.sendEmailVerification();

      await _syncUserWithFirestore(fbUser).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            'Firestore operation timed out. Please check your connection and try again.',
          );
        },
      );

      await _firebaseAuth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Check your email for verification.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(prefilledEmail: fbUser.email),
        ),
        (route) => false,
      );
    } on fbAuth.FirebaseAuthException catch (e) {
      var errorMessage = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'timeout') {
        errorMessage =
            e.message ??
            'Operation timed out. Please check your connection and try again.';
      } else {
        errorMessage = 'Signup failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
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
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create Your Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Are you ready to join the Rockies Fitness Gym Community? Set up your account now!',
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
                              borderRadius: BorderRadius.all(Radius.circular(30)),
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
                                        keyboardType: TextInputType.emailAddress,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: 'Email',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }

                                          final trimmedValue =
                                              value.trim().toLowerCase();
                                          if (!RegExp(
                                            r'^[^@]+@[^@]+\.[^@]+',
                                          ).hasMatch(trimmedValue)) {
                                            return 'Please enter a valid email';
                                          }

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
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: 'Password',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
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
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          labelText: 'Confirm Password',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
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
                                          if (value != _passwordController.text) {
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
                                        onPressed:
                                            _isLoading ? null : _signUpWithEmail,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
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
                                                'Register',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'By clicking this button, you agree with our ',
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
                                        'Terms and Conditions',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account?',
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
                                            'Log In',
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
