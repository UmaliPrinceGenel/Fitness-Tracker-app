import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'health_dashboard.dart';
import 'admin_login_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with WidgetsBindingObserver {
  String gender = "Male";
  double height = 170;
  int weight = 60;
  DateTime dob = DateTime(2005, 1, 1);
  bool _isLoading = false;
  late TextEditingController heightController;
  late TextEditingController weightController;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController(text: height.toStringAsFixed(0));
    weightController = TextEditingController(text: weight.toString());
    
    // Add listeners to handle text changes without causing excessive rebuilds
    heightController.addListener(_handleHeightChange);
    weightController.addListener(_handleWeightChange);
    WidgetsBinding.instance.addObserver(this);
 }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when the app resumes
      _refreshProfileData();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
      });
    }
  }

  // Handle height changes without causing excessive rebuilds
  void _handleHeightChange() {
    String value = heightController.text;
    if (value.isNotEmpty) {
      double? parsedValue = double.tryParse(value);
      if (parsedValue != null) {
        height = parsedValue;
        // Format the value to remove decimals if needed
        String formattedValue = height.toStringAsFixed(0);
        if (heightController.text != formattedValue) {
          int selectionIndex = heightController.selection.base.offset;
          heightController.text = formattedValue;
          // Keep cursor at the same relative position
          int newSelectionIndex = selectionIndex <= formattedValue.length 
              ? selectionIndex 
              : formattedValue.length;
          heightController.selection = TextSelection.fromPosition(
            TextPosition(offset: newSelectionIndex)
          );
        }
      }
    }
  }

  // Handle weight changes without causing excessive rebuilds
  void _handleWeightChange() {
    String value = weightController.text;
    if (value.isNotEmpty) {
      int? parsedValue = int.tryParse(value);
      if (parsedValue != null) {
        weight = parsedValue;
        // Make sure the displayed value matches the stored value
        String formattedValue = weight.toString();
        if (weightController.text != formattedValue) {
          int selectionIndex = weightController.selection.base.offset;
          weightController.text = formattedValue;
          // Keep cursor at the same relative position
          int newSelectionIndex = selectionIndex <= formattedValue.length 
              ? selectionIndex 
              : formattedValue.length;
          weightController.selection = TextSelection.fromPosition(
            TextPosition(offset: newSelectionIndex)
          );
        }
      }
    } else {
      // If the field is empty, set weight to 0
      weight = 0;
    }
  }

  /// ✅ Save profile data to Firestore and mark profile as completed
  Future<void> _saveProfileData() async {
    setState(() => _isLoading = true);

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Calculate BMI
        double heightInMeters = height / 100;
        double bmi = weight / (heightInMeters * heightInMeters);

        // Save profile data to user document
        await _firestore.collection('users').doc(user.uid).update({
          'profile': {
            'gender': gender,
            'height': height,
            'weight': weight,
            'dateOfBirth': dob,
            'bmi': double.parse(bmi.toStringAsFixed(1)),
            'profileCompletedAt': FieldValue.serverTimestamp(),
          },
          'hasCompletedProfile': true, // Mark profile as completed
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Profile data saved for user: ${user.uid}');
        print('📊 BMI calculated: ${bmi.toStringAsFixed(1)}');

        // Navigate to main app (Health Dashboard)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HealthDashboard()),
        );
      }
    } catch (e) {
      print('❌ Error saving profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfileData,
          child: Stack(
            children: [
              // Back button with circular background
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF191919),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                    ),
                  ),
                ),
              ),

              // Grey card container
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF191919),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title inside the container
                        const Text(
                          "My Profile",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description text
                        const Text(
                          "Before you get started, fill out the following information to get more accurate body composition and calorie information.",
                          textAlign: TextAlign.left,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        const SizedBox(height: 20),

                        // Gender
                        const Text(
                          "Gender",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.male, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    "Male",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              selected: gender == "Male",
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.grey[800],
                              onSelected: _isLoading
                                  ? null
                                  : (selected) {
                                      setState(() => gender = "Male");
                                    },
                            ),
                            const SizedBox(width: 15),
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.female, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    "Female",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              selected: gender == "Female",
                              selectedColor: Colors.pink,
                              backgroundColor: Colors.grey[800],
                              onSelected: _isLoading
                                  ? null
                                  : (selected) {
                                      setState(() => gender = "Female");
                                    },
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Height
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Height",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                enabled: !_isLoading,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  hintText: "cm",
                                  hintStyle: const TextStyle(color: Colors.grey),
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
                                controller: heightController,
                                onChanged: (value) {
                                  // Changes are now handled by the controller listener
                                  // This callback is kept for compatibility but doesn't trigger setState
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Weight
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Weight",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                enabled: !_isLoading,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  hintText: "kg",
                                  hintStyle: const TextStyle(color: Colors.grey),
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
                                controller: weightController,
                                onChanged: (value) {
                                  // Changes are now handled by the controller listener
                                  // This callback is kept for compatibility but doesn't trigger setState
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Date of Birth
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Date of Birth",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _selectDate(context),
                              child: Text(
                                "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isLoading ? null : _saveProfileData,
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
                                    "Next",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                      // Version information at the bottom
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          // Reset tap count if more than 2 seconds have passed since the last tap
                          if (_lastTapTime != null && now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
                            _tapCount = 0;
                          }
                          
                          _tapCount++;
                          _lastTapTime = now;
                          
                          if (_tapCount == 7) {
                            // Show admin login screen after 7 taps
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                            );
                            // Reset the tap count after showing the admin screen
                            _tapCount = 0;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Version 1.0.1+2', // Using the version from pubspec.yaml
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Refresh function for profile data
  Future<void> _refreshProfileData() async {
    // Reload profile data from Firestore
    await _loadProfileData();
  }

  // Load profile data from Firestore
  Future<void> _loadProfileData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final profileData = userDoc.data()?['profile'];
          if (profileData != null) {
            setState(() {
              gender = profileData['gender'] ?? "Male";
              height = profileData['height']?.toDouble() ?? 170.0;
              weight = profileData['weight']?.toInt() ?? 60;
              dob = profileData['dateOfBirth']?.toDate() ?? DateTime(2005, 1, 1);
              
              // Update controllers with new values
              heightController.text = height.toStringAsFixed(0);
              weightController.text = weight.toString();
            });
          } else {
            // If no profile data exists, reset to default values
            setState(() {
              gender = "Male";
              height = 170.0;
              weight = 60;
              dob = DateTime(2005, 1, 1);
              
              // Update controllers with default values
              heightController.text = height.toStringAsFixed(0);
              weightController.text = weight.toString();
            });
          }
        } else {
          // If user document doesn't exist, create it with default values
          setState(() {
            gender = "Male";
            height = 170.0;
            weight = 60;
            dob = DateTime(2005, 1, 1);
            
            // Update controllers with default values
            heightController.text = height.toStringAsFixed(0);
            weightController.text = weight.toString();
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing profile data: $e')),
        );
      }
    }
  }
}
