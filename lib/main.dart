import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/health_dashboard.dart';
import 'screens/permissions_screen.dart';
import 'screens/my_profile.dart';
import 'widgets/icon_sequence_animation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';

// Remove the duplicate main function - keeping only one

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://jaoxexqnfwvhmuxusigt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imphb3hleHFuZnd2aG11eHVzaWd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMzIwNjEsImV4cCI6MjA3MzYwODA2MX0.Yv-lpZKq3kdPejvMe1KoMHAPNylEfc2J-rA37Kb-Q9c',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  fbAuth.User? _firebaseUser;
  bool _isLoading = true;
  bool _hasCompletedProfile = false;

  late StreamSubscription<fbAuth.User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        // User is logged in, check if they have completed profile
        await _checkUserProfileStatus(user);
      } else {
        // User is not logged in
        setState(() {
          _firebaseUser = null;
          _hasCompletedProfile = false;
          _isLoading = false;
        });
      }
    });
  }

  /// ✅ Check if user has completed their profile
  Future<void> _checkUserProfileStatus(fbAuth.User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final bool hasCompletedProfile = userData['hasCompletedProfile'] ?? false;
        
        setState(() {
          _firebaseUser = user;
          _hasCompletedProfile = hasCompletedProfile;
          _isLoading = false;
        });
      } else {
        // User exists in Firebase Auth but not in Firestore (first time login)
        setState(() {
          _firebaseUser = user;
          _hasCompletedProfile = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking user profile status: $e');
      // On error, assume profile is not completed
      setState(() {
        _firebaseUser = user;
        _hasCompletedProfile = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isLoading ? _buildLoadingScreen() : _buildHomeScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', height: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    if (_firebaseUser != null) {
      if (_hasCompletedProfile) {
        // User is logged in AND has completed profile - go to Health Dashboard
        return const HealthDashboard();
      } else {
        // User is logged in but hasn't completed profile - go to Permissions Screen
        return const PermissionsScreen();
      }
    } else {
      // User is not logged in - show Welcome Screen
      return const WelcomeScreen();
    }
  }
}

// Your existing WelcomeScreen remains exactly the same...
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 2.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              "Welcome",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const IconSequenceAnimation(),
            const SizedBox(height: 40),

            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value,
                    child: Image.asset('assets/logo.jpg', height: 150),
                  );
                },
              ),
            ),

            const SizedBox(height: 50),

            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 250,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Log In",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
