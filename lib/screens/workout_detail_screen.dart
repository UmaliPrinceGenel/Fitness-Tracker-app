import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import 'exercise_detail_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final VoidCallback? onWorkoutCompleted; // Add callback for when workout is completed
  final VoidCallback? onWorkoutReset; // Add callback for when workout is reset
  const WorkoutDetailScreen({Key? key, required this.workout, this.onWorkoutCompleted, this.onWorkoutReset}) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
   bool _isWorkoutCompleted = false;
  String _currentButtonState = 'start'; // 'start', 'done', 'again'
  DateTime? _workoutStartTime;
  Set<int> _viewedExercises = {}; // Track which exercises have been viewed
  Set<int> _exercisesWithWeightInput = {}; // Track which exercises have had weight input
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkWorkoutCompletionStatus();
  }

  // Check if the workout has already been completed by the user today
 Future<void> _checkWorkoutCompletionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check both collections for workout completion status
        final completedWorkoutsRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('completed_workouts')
            .doc(widget.workout.title);

        final doneInfosRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .doc(widget.workout.title);

        // Check both documents
        final completedWorkoutsDoc = await completedWorkoutsRef.get();
        final doneInfosDoc = await doneInfosRef.get();

        bool isCompletedToday = false;

        // Check if either collection has the workout completed today
        if (completedWorkoutsDoc.exists) {
          final data = completedWorkoutsDoc.data();
          if (data != null && data['completedAt'] != null) {
            final completedAt = (data['completedAt'] as Timestamp).toDate();
            final today = DateTime.now();
            isCompletedToday = completedAt.year == today.year &&
                completedAt.month == today.month &&
                completedAt.day == today.day;
          }
        }

        // Also check doneInfos collection if not already found in completed_workouts
        if (!isCompletedToday && doneInfosDoc.exists) {
          final data = doneInfosDoc.data();
          if (data != null && data['completedAt'] != null) {
            final completedAt = (data['completedAt'] as Timestamp).toDate();
            final today = DateTime.now();
            isCompletedToday = completedAt.year == today.year &&
                completedAt.month == today.month &&
                completedAt.day == today.day;
          }
        }

        setState(() {
          _isWorkoutCompleted = isCompletedToday;
          _currentButtonState = isCompletedToday ? 'again' : 'start';
        });
      }
    } catch (e) {
      print('Error checking workout completion status: $e');
      setState(() {
        _isWorkoutCompleted = false;
        _currentButtonState = 'start';
      });
    }
  }

  @override
 Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              bool shouldPop = await _onBackPressed();
              if (shouldPop) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.workout.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              onSelected: (String choice) {
                if (choice == 'reset') {
                  _showResetConfirmationDialog();
                }
              },
              itemBuilder: (BuildContext context) {
                return {
                  if (_isWorkoutCompleted) // Only show reset option if workout is completed
                    'reset': 'Reset Workout Status',
                }.entries.map((entry) {
                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList();
              },
              icon: Icon(Icons.more_vert, color: Colors.white),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Image/Thumbnail
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        widget.workout.thumbnailAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 60,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Workout Info
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
                          Text(
                            widget.workout.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildInfoItem(
                                icon: Icons.fitness_center,
                                label: "${widget.workout.exerciseList.length} exercises",
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(widget.workout.level).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getLevelColor(widget.workout.level).withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  widget.workout.level,
                                  style: TextStyle(
                                    color: _getLevelColor(widget.workout.level),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  widget.workout.bodyFocus,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Workout Description
                  const Text(
                    "About this workout",
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
                        "This ${widget.workout.level.toLowerCase()} level ${widget.workout.bodyFocus.toLowerCase()} workout is designed to help you build strength and improve your fitness. The routine includes ${widget.workout.exerciseList.length} exercises that target various muscle groups in the ${widget.workout.bodyFocus.toLowerCase()} area.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Exercise List
                  const Text(
                    "Exercises",
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
                        children: _buildExerciseList(),
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
          child: ElevatedButton(
            onPressed: _getButtonAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _getButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handle back button press to properly manage workout state
  Future<bool> _onBackPressed() async {
    // If the workout is in progress (timer running) but not all exercises viewed, ask for confirmation
    if (_workoutStartTime != null && !areAllExercisesViewed()) {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Workout in Progress",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "You have a workout in progress. Are you sure you want to exit? Your progress will not be saved.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Don't pop the screen
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Reset the workout state before exiting
                  setState(() {
                    _currentButtonState = 'start';
                    _workoutStartTime = null;
                  });
                  Navigator.of(context).pop(true); // Pop the screen
                },
                child: const Text(
                  "Exit",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      ) ?? false; // Return false if dialog is dismissed
    }

    // If no workout is in progress, allow normal exit
    return true;
  }

  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

 List<Widget> _buildExerciseList() {
    // Use the exerciseList from the workout model instead of calculating count
    List<Widget> exercises = [];
    for (int i = 0; i < widget.workout.exerciseList.length; i++) {
      final exercise = widget.workout.exerciseList[i];
      double caloriesBurned = exercise.getCaloriesBurned();
      
      exercises.add(
        GestureDetector(
          onTap: () {
            // Navigate to exercise detail screen when exercise is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(
                  exerciseNumber: i + 1, // Use 1-based indexing for display
                  workout: widget.workout,
                  onExerciseViewed: markExerciseAsViewed, // Pass the callback to mark exercises as viewed
                  onWeightInput: markExerciseWithWeightInput, // Pass the callback to mark exercises as having weight input
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white10,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (i + 1).toString(), // Use 1-based indexing for display
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white30,
                ),
              ],
            ),
          ),
        ),
      );

      if (i < widget.workout.exerciseList.length - 1) {
        exercises.add(const Divider(height: 1, color: Colors.white10));
      }
    }

    return exercises;
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper methods to determine button text, color, and action based on state
 String _getButtonText() {
    switch (_currentButtonState) {
      case 'start':
        return 'Start Workout';
      case 'done':
        return 'Done';
      case 'again':
        return 'Again';
      default:
        return 'Start Workout';
    }
 }

  Color _getButtonColor() {
    // Always show orange color for active buttons, grey when disabled
    if (_currentButtonState == 'start') {
      return Colors.orange;
    } else if (_currentButtonState == 'done') {
      return Colors.orange;
    } else if (_currentButtonState == 'again') {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  VoidCallback? _getButtonAction() {
    if (_currentButtonState == 'start') {
      return _onStartWorkoutPressed;
    } else if (_currentButtonState == 'done') {
      return _onDoneWorkoutPressed;
    } else if (_currentButtonState == 'again') {
      return _onAgainWorkoutPressed;
    } else {
      return null;
    }
  }

   // Helper method to convert duration string to seconds
  int _parseDurationToSeconds(String duration) {
    // Expected format: "X min" or "X mins" or "X minutes"
    // For example: "25 mins", "30 min", "45 minutes"
    final List<String> parts = duration.split(' ');
    if (parts.length >= 2) {
      try {
        final int minutes = int.parse(parts[0]);
        return minutes * 60; // Convert to seconds
      } catch (e) {
        print('Error parsing duration: $e');
        return 0; // Default to 0 seconds if parsing fails
      }
    }
    return 0; // Default to 0 seconds if format is unexpected
  }

   // Method to mark an exercise as viewed
  void markExerciseAsViewed(int exerciseIndex) {
    setState(() {
      _viewedExercises.add(exerciseIndex);
      // Check if all exercises have been viewed
      if (_viewedExercises.length == widget.workout.exerciseList.length) {
        _currentButtonState = 'done';
      }
    });
  }

  // Check if all exercises have been viewed
  bool areAllExercisesViewed() {
    return _viewedExercises.length == widget.workout.exerciseList.length;
  }

  // New methods for handling the different button states with popups
  void _onStartWorkoutPressed() {
    // Record start time and navigate to the first exercise
    setState(() {
      _workoutStartTime = DateTime.now();
      _viewedExercises.clear(); // Reset viewed exercises when starting
      _exercisesWithWeightInput.clear(); // Reset weight input tracking when starting
      _currentButtonState = 'start'; // Keep as start initially, will change when all exercises are viewed
    });

    // Navigate to the first exercise
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseNumber: 1, // Always start with the first exercise
          workout: widget.workout,
          onExerciseViewed: markExerciseAsViewed, // Pass the callback to mark exercises as viewed
          onWeightInput: markExerciseWithWeightInput, // Pass the callback to mark exercises as having weight input
        ),
      ),
    ).then((_) {
      // When returning from exercises, check if all exercises have been viewed to update button state
      if (mounted && areAllExercisesViewed()) {
        setState(() {
          _currentButtonState = 'done';
        });
      }
    });
  }

  // Check if all exercises have had weight input
  bool areAllExercisesWithWeightInput() {
    return _exercisesWithWeightInput.length == widget.workout.exerciseList.length;
  }

  // Mark an exercise as having weight input
  void markExerciseWithWeightInput(int exerciseIndex) {
    setState(() {
      _exercisesWithWeightInput.add(exerciseIndex);
    });
  }

  void _onDoneWorkoutPressed() async {
    // Check if all exercises have weight input before allowing completion
    if (!areAllExercisesWithWeightInput()) {
      // Show notification that not all exercises have weight input
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Weight Input Required",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Please input weight for all exercises before completing the workout. ${widget.workout.exerciseList.length - _exercisesWithWeightInput.length} exercises still need weight input.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
      return; // Don't proceed with completion
    }

    // Check if workout was started to calculate duration
    int actualDurationSeconds = 0;
    if (_workoutStartTime != null) {
      actualDurationSeconds = DateTime.now().difference(_workoutStartTime!).inSeconds;
    }

    // Set expected workout duration to 30 minutes (1800 seconds) for anti-cheating
    int expectedDurationSeconds = 30 * 60; // 30 minutes in seconds

    // Determine if user might be cheating based on time
    bool isCheating = expectedDurationSeconds > 0 && actualDurationSeconds < expectedDurationSeconds;

    if (isCheating) {
      // Show "Are you sure you are not cheating?" popup
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Are you sure?",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Are you sure you are not cheating? The ${widget.workout.title} workout is expected to take at least 30 minutes, but you completed it in ${_formatSecondsToMinutes(actualDurationSeconds)}.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog and do nothing
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // User confirms they're not cheating, save workout completion
                  Navigator.of(context).pop(); // Close dialog
                  await _saveWorkoutCompletion();
                },
                child: const Text(
                  "Yes, I'm sure",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Show congratulations popup if workout was completed in expected time or more
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Congratulations!",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Great job completing the ${widget.workout.title} workout in ${_formatSecondsToMinutes(actualDurationSeconds)}! Your progress has been saved.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  await _saveWorkoutCompletion();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _onAgainWorkoutPressed() {
    // Show "Are you sure you want to do this again?" popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: const Text(
            "Do Again?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to do this again?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog and do nothing
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                // User confirms, reset workout start time and keep "Done" button
                setState(() {
                  _workoutStartTime = DateTime.now(); // Start timing for the new session
                  _currentButtonState = 'done';
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to format seconds to minutes for display
  String _formatSecondsToMinutes(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    if (remainingSeconds > 0) {
      return "${minutes}m ${remainingSeconds}s";
    } else {
      return "${minutes}m";
    }
  }

  // Helper method to save workout completion to Firebase
  Future<void> _saveWorkoutCompletion() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check if workout was completed too quickly (potential cheating)
        int actualDurationSeconds = 0;
        if (_workoutStartTime != null) {
          actualDurationSeconds = DateTime.now().difference(_workoutStartTime!).inSeconds;
        }

        // Set expected workout duration to 30 minutes (1800 seconds) for anti-cheating
        int expectedDurationSeconds = 30 * 60; // 30 minutes in seconds
        bool isCheated = expectedDurationSeconds > 0 && actualDurationSeconds < expectedDurationSeconds;

        // Update workout completion status in Firebase under "doneInfos" collection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .doc(widget.workout.title)
            .set({
          'title': widget.workout.title,
          'duration': widget.workout.duration,
          'exercises': widget.workout.exercises,
          'level': widget.workout.level,
          'bodyFocus': widget.workout.bodyFocus,
          'completedAt': FieldValue.serverTimestamp(),
          'actualDuration': actualDurationSeconds, // Store actual duration for reference
          'expectedDuration': expectedDurationSeconds, // Store expected duration for reference
          'isCheated': isCheated, // Flag to indicate if workout was potentially cheated
        });

        setState(() {
          _isWorkoutCompleted = true;
          _currentButtonState = 'again';
        });

        // Call the callback if provided to notify parent screen of completion
        if (widget.onWorkoutCompleted != null) {
          widget.onWorkoutCompleted!();
        }
      }
    } catch (e) {
      print('Error saving workout completion: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text(
              "Error",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "There was an error saving your workout progress. Please try again.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // Helper method to reset workout completion status in Firebase
  Future<void> _resetWorkoutCompletion() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete the workout completion document from both collections
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('completed_workouts')
            .doc(widget.workout.title)
            .delete();

        // Also delete from doneInfos collection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .doc(widget.workout.title)
            .delete();

        setState(() {
          _isWorkoutCompleted = false;
          _currentButtonState = 'start';
        });

        // Call the callback if provided to notify parent screen of reset
        if (widget.onWorkoutReset != null) {
          widget.onWorkoutReset!();
        }

        // Show success message
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF191919),
                title: const Text(
                  "Workout Reset",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Workout status has been reset successfully.",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error resetting workout completion: $e');
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF191919),
              title: const Text(
                "Error",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "There was an error resetting your workout progress. Please try again.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Show confirmation dialog for resetting workout status
  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: const Text(
            "Reset Workout Status",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to reset the status for ${widget.workout.title}? This will mark the workout as not completed.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without resetting
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _resetWorkoutCompletion(); // Reset the workout status
              },
              child: const Text(
                "Reset",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  // Calculate total duration from all exercises in the workout
  String _getTotalExerciseDuration() {
    int totalSeconds = 0;
    
    // Sum up the duration of all exercises
    for (Exercise exercise in widget.workout.exerciseList) {
      totalSeconds += exercise.duration;
    }
    
    // Convert total seconds to minutes and format as "X min" or "X mins"
    int totalMinutes = totalSeconds ~/ 60;
    
    // Handle edge cases: if total minutes is 0, return "0 min", otherwise format appropriately
    if (totalMinutes == 0) {
      // If there are exercises but total is 0 minutes, at least show 1 min to avoid confusion
      if (widget.workout.exerciseList.isNotEmpty) {
        // Check if there are any exercises with duration less than 60 seconds
        bool hasShortExercises = widget.workout.exerciseList.any((exercise) => exercise.duration > 0);
        return hasShortExercises ? "1 min" : "0 min";
      }
      return "0 min";
    }
    
    return totalMinutes > 1 ? "${totalMinutes} mins" : "${totalMinutes} min";
  }

  // Original _startWorkout method is now replaced by the new methods above
}
