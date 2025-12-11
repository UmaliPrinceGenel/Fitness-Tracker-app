import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseNumber;
  final Workout workout;

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseNumber,
    required this.workout,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Exercise exercise;
  late double caloriesBurned;
  late TextEditingController weightController;
  late TextEditingController repsController;
  late TextEditingController setsController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double weightFactor = 1.0; // Default to bodyweight or no extra weight
  int reps = 1;
  int sets = 1;

  @override
  void initState() {
    super.initState();
    exercise = widget.workout.exerciseList[widget.exerciseNumber - 1];
    caloriesBurned = exercise.getCaloriesBurned();
    weightController = TextEditingController(text: "");
    repsController = TextEditingController(text: "8"); // Default to recommended minimum reps
    setsController = TextEditingController(text: "3"); // Default to recommended minimum sets
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    setsController.dispose();
    super.dispose();
  }

  void updateCalories() {
    double weightValue = double.tryParse(weightController.text) ?? 0.0;
    int repsValue = int.tryParse(repsController.text) ?? 1;
    int setsValue = int.tryParse(setsController.text) ?? 1;
    
    // Calculate weight factor: 1.0 for bodyweight exercises, higher for weighted exercises
    // Assuming 0 weight means bodyweight exercise (factor of 1.0)
    double newWeightFactor = weightValue > 0 ? (1.0 + (weightValue / 100.0)) : 1.0;
    int newReps = repsValue > 0 ? repsValue : 1;
    int newSets = setsValue > 0 ? setsValue : 1;
    
    setState(() {
      weightFactor = newWeightFactor;
      reps = newReps;
      sets = newSets;
      caloriesBurned = exercise.getCaloriesBurned(
        weightFactor: weightFactor,
        reps: newReps,
        sets: newSets,
      );
    });
  }

  // Function to save user input data for future use
  void _saveExerciseRecord() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Record the user's inputs for this exercise
        await _firestore.collection('users').doc(user.uid)
            .collection('exercise_records').doc(exercise.name)
            .set({
          'exerciseName': exercise.name,
          'workoutId': widget.workout.id,
          'weightUsed': double.tryParse(weightController.text) ?? 0.0,
          'repsPerformed': int.tryParse(repsController.text) ?? 1,
          'setsPerformed': int.tryParse(setsController.text) ?? 1,
          'timestamp': FieldValue.serverTimestamp(),
          'recommendedReps': "8-12", // Static recommended value
          'recommendedSets': "3-4",   // Static recommended value
          'optimalRestTime': "60-90 seconds", // Static recommended value
          'durationPerSet': "30-45 seconds", // Static recommended value
          'caloriesPerSet': "8-12 cal", // Static recommended value
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  void _saveUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid)
            .collection('exercise_inputs').doc(exercise.name + '_' + DateTime.now().millisecondsSinceEpoch.toString())
            .set({
          'exerciseName': exercise.name,
          'workoutId': widget.workout.id,
          'weight': double.tryParse(weightController.text) ?? 0.0,
          'reps': int.tryParse(repsController.text) ?? 1,
          'sets': int.tryParse(setsController.text) ?? 1,
          'date': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _saveUserData(); // Save data when leaving the screen
            Navigator.pop(context);
          },
        ),
        title: Text(
          exercise.name, // Show the actual exercise name instead of "Exercise X"
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.4),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.exerciseNumber.toString(),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          exercise.name, // Show the actual exercise name
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.workout.title,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Weight, Reps, Sets Inputs
                const Text(
                  "Performance Tracking",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Input the weight, sets and reps you have done",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Weight Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white), // Set input text color to white
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  labelStyle: TextStyle(color: Colors.orange),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.orange),
                                  ),
                                ),
                                onChanged: (value) {
                                  updateCalories();
                                  _saveUserData(); // Save data when input changes
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "kg",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Reps Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: repsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white), // Set input text color to white
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  labelStyle: TextStyle(color: Colors.orange),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.orange),
                                  ),
                                ),
                                onChanged: (value) {
                                  updateCalories();
                                  _saveUserData(); // Save data when input changes
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "reps",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Sets Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: setsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white), // Set input text color to white
                                decoration: const InputDecoration(
                                  labelText: 'Sets',
                                  labelStyle: TextStyle(color: Colors.orange),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.orange),
                                  ),
                                ),
                                onChanged: (value) {
                                  updateCalories();
                                  _saveUserData(); // Save data when input changes
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "sets",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Save Button
                        ElevatedButton(
                          onPressed: () {
                            _saveUserData(); // Save the current values
                            // Show a confirmation message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exercise data saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Save Data",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exercise Info
                const Text(
                  "Recommended Exercise Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.fitness_center, "Exercise Type", exercise.name),
                        const Divider(height: 20, color: Colors.white38),
                        _buildInfoRow(Icons.timer, "Duration per Set", "30-45 seconds"), // Average time per set based on exercise type
                        const Divider(height: 20, color: Colors.white38),
                        _buildInfoRow(Icons.local_fire_department, "Calories per Set", "8-12 cal"), // Based on recommended sets
                        const Divider(height: 20, color: Colors.white38),
                        _buildInfoRow(Icons.repeat, "Recommended Reps/Sets", "3-4 sets × 8-12 reps"), // Static recommended values
                        const Divider(height: 20, color: Colors.white38),
                        _buildInfoRow(Icons.directions_run, "Rest Period", "60-90 seconds"), // Optimal rest time based on exercise type
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exercise Description
                const Text(
                  "Description",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      exercise.description, // Use the actual exercise description
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exercise Tips
                const Text(
                  "Tips",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _buildTip(Icons.check_circle, "Maintain proper posture throughout the exercise"),
                        SizedBox(height: 8),
                        _buildTip(Icons.check_circle, "Breathe consistently - exhale on exertion"),
                        SizedBox(height: 8),
                        _buildTip(Icons.check_circle, "Start with lighter weights and progress gradually"),
                        SizedBox(height: 8),
                        _buildTip(Icons.check_circle, "Focus on the muscle being worked"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                // Navigate to previous exercise if available
                if (widget.exerciseNumber > 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailScreen(
                        exerciseNumber: widget.exerciseNumber - 1,
                        workout: widget.workout,
                      ),
                    ),
                  );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Previous",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to next exercise if available
                  int totalExercises = widget.workout.exerciseList.length; // Use the actual length of exercise list
                  
                  if (widget.exerciseNumber < totalExercises) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          exerciseNumber: widget.exerciseNumber + 1,
                          workout: widget.workout,
                        ),
                      ),
                    );
                  } else {
                    // If this is the last exercise, go back to workout
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.exerciseNumber < widget.workout.exerciseList.length // Use the actual length of exercise list
                      ? "Next" 
                      : "Finish Workout",
                  style: const TextStyle(
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for tips
class _buildTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _buildTip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
