import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'health_dashboard.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String gender = "Male";
  double height = 170;
  int weight = 60;
  DateTime dob = DateTime(2005, 1, 1);
  bool _isLoading = false;
  late TextEditingController heightController;
  late TextEditingController weightController;

  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController(text: height.toStringAsFixed(0));
    weightController = TextEditingController(text: weight.toString());
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
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
                                if (value.isNotEmpty) {
                                  setState(() {
                                    height = double.tryParse(value) ?? 170;
                                    heightController.text = height
                                        .toStringAsFixed(0);
                                  });
                                }
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
                                setState(() {
                                  if (value.isNotEmpty) {
                                    int? parsedValue = int.tryParse(value);
                                    if (parsedValue != null) {
                                      weight = parsedValue;
                                    }
                                  } else {
                                    weight = 0;
                                  }
                                  if (value.isNotEmpty) {
                                    int? parsedValue = int.tryParse(value);
                                    if (parsedValue != null) {
                                      weightController.text = weight.toString();
                                      weightController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                          offset: weightController.text.length,
                                        ),
                                      );
                                    }
                                  }
                                });
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
                    ],
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