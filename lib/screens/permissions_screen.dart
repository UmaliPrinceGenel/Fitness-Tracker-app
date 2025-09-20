import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool agreePolicy = false;
  bool joinProgram = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Title
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 15),

              // Description
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

              // Permissions
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

              // Small note
              const Text(
                "You can always adjust your permissions preferences in the Settings",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 20),

              // Checkboxes
              Row(
                children: [
                  Checkbox(
                    value: agreePolicy,
                    onChanged: (value) {
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
                    onChanged: (value) {
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

              // Buttons
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
                      onPressed: () {
                        if (agreePolicy) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyProfileScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "You must agree to the User Agreement first.",
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
