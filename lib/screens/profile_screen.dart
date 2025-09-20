import 'package:flutter/material.dart';
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
  late TextEditingController heightController;
  late TextEditingController weightController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // Enable keyboard handling
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),

            // Grey card container with flexible height and rounded corners on both top and bottom
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

                      // Description text aligned to the left
                      const Text(
                        "Before you get started, fill out the following information to get more accurate body composition and calorie information.",
                        textAlign: TextAlign.left, // Left aligned
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
                            onSelected: (selected) {
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
                            onSelected: (selected) {
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
                                    // Try to parse the value as integer
                                    int? parsedValue = int.tryParse(value);
                                    if (parsedValue != null) {
                                      weight = parsedValue;
                                    }
                                  } else {
                                    weight = 0; // Allow clearing the field
                                  }
                                  // Only format if value is not empty and is a valid number
                                  if (value.isNotEmpty) {
                                    int? parsedValue = int.tryParse(value);
                                    if (parsedValue != null) {
                                      weightController.text = weight.toString();
                                      // Move cursor to end to prevent cursor jumping
                                      weightController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  weightController.text.length,
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
                            onPressed: () => _selectDate(context),
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
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HealthDashboard(),
                              ),
                            );
                          },
                          child: const Text(
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
