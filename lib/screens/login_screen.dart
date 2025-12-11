import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import
import '../screens/signup_screen.dart';
import '../screens/permissions_screen.dart';
import '../screens/health_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;
  
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-fill email if provided
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
    _loadRememberedCredentials();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Load remembered email and password from SharedPreferences
  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      final shouldRemember = prefs.getBool('should_remember') ?? false;

      // Only load remembered credentials if no email was pre-filled
      if (widget.prefilledEmail == null && rememberedEmail != null && rememberedPassword != null) {
        setState(() {
          _emailController.text = rememberedEmail;
          _passwordController.text = rememberedPassword;
          _rememberMe = shouldRemember;
        });
      }
    } catch (e) {
      print('Error loading remembered credentials: $e');
    }
  }

  /// ✅ Save credentials to SharedPreferences if "Remember Me" is checked
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
        await prefs.setString('remembered_password', _passwordController.text.trim());
        await prefs.setBool('should_remember', true);
        print('✅ Credentials saved for remember me');
      } else {
        // Clear saved credentials if "Remember Me" is unchecked
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
        await prefs.remove('should_remember');
        print('✅ Credentials cleared');
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  /// ✅ Clear saved credentials (for logout or when user wants to forget)
  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.remove('should_remember');
      print('✅ Credentials cleared');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  /// ✅ Check if user already has an active session
  Future<void> _checkExistingSession() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _handlePostLogin(user);
    }
  }

  /// ✅ Handle navigation after successful login
  Future<void> _handlePostLogin(fbAuth.User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final bool hasCompletedProfile = userData['hasCompletedProfile'] ?? false;

        if (hasCompletedProfile) {
          _navigateToMainApp();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PermissionsScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        );
      }
    } catch (e) {
      print('Error checking user data: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionsScreen()),
      );
    }
  }

  /// ✅ Navigate to main app (Health Dashboard)
  void _navigateToMainApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HealthDashboard()),
    );
  }

  /// ✅ Forgot Password Functionality
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );

      // Show success dialog
      _showPasswordResetDialog();
    } on fbAuth.FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Show password reset success dialog
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Check Your Email',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Login with Email and Password - FIXED VERSION
  Future<void> _loginWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // ✅ CHECK IF EMAIL IS VERIFIED
        if (!user.emailVerified) {
          // User is not verified - sign them out and show message
          await _firebaseAuth.signOut();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please verify your email before logging in. Check your inbox for the verification link.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          
          return;
        }

        // ✅ EMAIL IS VERIFIED - PROCEED WITH LOGIN
        // Save credentials if "Remember Me" is checked
        await _saveCredentials();
        
        // Handle post-login navigation
        await _handlePostLogin(user);
      }
    } on fbAuth.FirebaseAuthException catch (e) {
      print('Firebase login error: $e');
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else {
        errorMessage = 'Login failed: invalid email or password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ IMPROVED: Login with Google - Works on both Web and Mobile
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final fbAuth.GoogleAuthProvider googleProvider = fbAuth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Force account selection prompt
      if (kIsWeb) {
        googleProvider.setCustomParameters({'prompt': 'select_account'});
      } else {
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      }

      fbAuth.UserCredential userCredential;

      if (kIsWeb) {
        // For web platforms - use signInWithPopup
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms (Android/iOS) - use signInWithProvider
        // This is the correct approach for mobile platforms
        userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      // Wait a moment for the auth state to update
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Get the current user
      final fbUser = _firebaseAuth.currentUser;

      if (fbUser != null) {
        // ✅ Check if this Google account has a Gmail email (based on your signup logic)
        final userEmail = fbUser.email?.toLowerCase() ?? '';
        if (!userEmail.endsWith('@gmail.com')) {
          await _firebaseAuth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only @gmail.com accounts are allowed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // ✅ Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();

        if (!userDoc.exists) {
          // User doesn't exist - show message to sign up first
          await _firebaseAuth.signOut();
          
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  'Account Not Found',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'The Google account ${fbUser.email} is not registered.\n\nPlease sign up first before logging in with Google.',
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
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text(
                      'GO TO SIGNUP',
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
          return;
        }

        // ✅ User exists - proceed with login
        await _handlePostLogin(fbUser);
      } else {
        throw Exception('Google sign-in failed: No user returned');
      }
    } on fbAuth.FirebaseAuthException catch (e) {
      await _handleGoogleLoginError(e);
    } catch (e) {
      print('Google Sign-In error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Handle Google login errors
  Future<void> _handleGoogleLoginError(fbAuth.FirebaseAuthException e) async {
    print('Google Sign-In error: $e');

    String errorMessage = 'Failed to sign in with Google';
    String errorDetails = '';

    if (e.code == 'account-exists-with-different-credential') {
      errorMessage = 'Account Already Exists';
      errorDetails = 
          'This email is already registered with a different sign-in method. Please try logging in with your original method.';
    } else if (e.code == 'user-not-found') {
      errorMessage = 'Account Not Found';
      errorDetails = 
          'No account found with this Google account. Please sign up first.';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'Account Disabled';
      errorDetails = 
          'This account has been disabled. Please contact support for assistance.';
    } else if (e.code == 'operation-not-allowed') {
      errorMessage = 'Sign-in Method Not Available';
      errorDetails = 
          'Google sign-in is currently not available. Please try another method or contact support.';
    } else if (e.code == 'invalid-credential') {
      errorMessage = 'Invalid Credentials';
      errorDetails = 
          'The authentication credentials are invalid. Please try again.';
    } else {
      errorMessage = 'Sign-in Failed';
      errorDetails = 'Failed to sign in with Google: ${e.message}';
    }

    // Show error dialog for important errors
    if (e.code == 'account-exists-with-different-credential' || 
        e.code == 'user-not-found') {
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
              if (e.code == 'user-not-found') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text(
                    'GO TO SIGNUP',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  e.code == 'user-not-found' ? 'CANCEL' : 'OK',
                  style: const TextStyle(color: Colors.grey),
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
                                : () {
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Ready to begin your fitness journey? Re-enter your email and password now!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      // // ✅ Show pre-filled email indicator if applicable
                      // if (widget.prefilledEmail != null) ...[
                      //   const SizedBox(height: 10),
                      //   Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.blue[900],
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(Icons.info, color: Colors.blue[100], size: 16),
                      //         const SizedBox(width: 8),
                      //         Text(
                      //           'Email pre-filled for verification check',
                      //           style: TextStyle(
                      //             color: Colors.blue[100],
                      //             fontSize: 12,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ],
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
                                          
                                          // Check if it's a valid email format
                                          final trimmedValue = value.trim().toLowerCase();
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmedValue)) {
                                            return 'Please enter a valid email';
                                          }
                                          
                                          // Gmail-only validation (matching your signup logic)
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
                                                      _obscurePassword = !_obscurePassword;
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
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: _isLoading
                                                  ? null
                                                  : (value) {
                                                      setState(() {
                                                        _rememberMe = value ?? false;
                                                      });
                                                    },
                                              checkColor: Colors.black,
                                              activeColor: Colors.orange,
                                            ),
                                            const Text(
                                              "Remember me",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _forgotPassword,
                                          child: const Text(
                                            "Forgot password?",
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _loginWithEmail,
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
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                ),
                                              )
                                            : const Text(
                                                "Log In",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: Colors.white38,
                                            thickness: 1,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            "Sign In with",
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
                                          : _loginWithGoogle,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
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
                                    const SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Don't have an account yet?",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const SignupScreen(),
                                                    ),
                                                  );
                                                },
                                          child: const Text(
                                            "Sign Up",
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
