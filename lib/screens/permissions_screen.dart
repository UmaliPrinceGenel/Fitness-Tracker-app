import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/web_auth_shell.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool agreePolicy = false;
  bool joinProgram = false;
  bool _isLoading = false;
  bool _showFullText = false;

  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _exitOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await _firebaseAuth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exiting setup: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePermissionData() async {
    if (!agreePolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must agree to the User Agreement first."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'permissions': {
            'agreedToPolicy': agreePolicy,
            'joinedUserExperienceProgram': joinProgram,
            'permissionsAcceptedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyProfileScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildWebPermissionScreen(BuildContext context) {
    return WebAuthShell(
      leftTitle: 'Welcome',
      leftSubtitle: 'Rockies Fitness Gym Tracker',
      rightChild: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Collapsible text section
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _showFullText 
                  ? CrossFadeState.showFirst 
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Rockies Fitness Gym Tracker. You can use this app to manage and track your workouts and view your progress data. We shall protect your information in accordance with relevant laws, regulations, and privacy policies. To be able to work normally, the app needs to connect to the internet.\n\nTo provide you with additional services while you\'re using the app, we might need the following permissions:',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Permission 1
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Color(0xFFFF7317), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access Location',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'For tracking your workout distance and routes',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Permission 2
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fitness_center, color: Color(0xFFFF7317), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access Activity Info',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'For recording your workouts and health information',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'You can always adjust your permissions preferences in the Settings',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Rockies Fitness Gym Tracker...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can always adjust your permissions preferences in the Settings',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            // Show More / Show Less button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showFullText = !_showFullText;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7317),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  _showFullText ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            // Checkbox 1
            Row(
              children: [
                Checkbox(
                  value: agreePolicy,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => agreePolicy = value ?? false);
                  },
                  activeColor: const Color(0xFFFF7317),
                ),
                const Expanded(
                  child: Text(
                    'Read and Agree to our User Agreement and Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Checkbox 2
            Row(
              children: [
                Checkbox(
                  value: joinProgram,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => joinProgram = value ?? false);
                  },
                  activeColor: const Color(0xFFFF7317),
                ),
                const Expanded(
                  child: Text(
                    'Enroll in User Experience Program to help us improve our products and services by sharing your stats with us',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePermissionData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7317),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Agree',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _exitOnboarding,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebPermissionScreen(context);
    }

    // MOBILE UI - UNTOUCHED
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Welcome to Rockies Fitness Gym Tracker. You can use this app to manage and track your workouts and view your progress data. We shall protect your information in accordance with relevant laws, regulations, and privacy policies. To be able to work normally, the app needs to connect to the internet.\n\n"
                "To provide you with additional services while you're using the app, we might need the following permissions:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.location_on, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Access Location\nFor tracking your workout distance and routes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.directions_run, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Access Activity Info\nFor recording your workouts and health information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "You can always adjust your permissions preferences in the Settings",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: agreePolicy,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => agreePolicy = value ?? false);
                          },
                    activeColor: Colors.orange,
                  ),
                  const Expanded(
                    child: Text(
                      "Read and Agree to our User Agreement and Privacy Policy",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: joinProgram,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => joinProgram = value ?? false);
                          },
                    activeColor: Colors.orange,
                  ),
                  const Expanded(
                    child: Text(
                      "Enroll in User Experience Program to help us improve our products and services by sharing your stats with us",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _savePermissionData,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Agree",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _exitOnboarding,
                      child: const Text(
                        "Exit",
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
            ],
          ),
        ),
      ),
    );
  }
}