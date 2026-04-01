import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import 'exercise_detail_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final VoidCallback? onWorkoutCompleted; // Add callback for when workout is completed
  final VoidCallback? onWorkoutReset; // Add callback for when workout is reset
  const WorkoutDetailScreen({
    Key? key,
    required this.workout,
    this.onWorkoutCompleted,
    this.onWorkoutReset,
  }) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isWorkoutCompleted = false;
  String _currentButtonState = 'start'; // 'start', 'done', 'again'
  DateTime? _workoutStartTime;
  Set<int> _viewedExercises = {}; // Track which exercises have been viewed
  Set<int> _exercisesWithWeightInput = {}; // Track which exercises have had weight input
  final Map<int, ExerciseTrackingDraft> _exerciseDrafts = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _endOfToday() {
    return _startOfToday().add(const Duration(days: 1));
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DateTime _dateFromKey(String dateKey) {
    return DateTime.tryParse(dateKey) ?? DateTime.now();
  }

  String? _resolveStoredDayKey(Map<String, dynamic> data) {
    final lastResetValue = data['lastDailyResetDate'];
    if (lastResetValue is String && lastResetValue.isNotEmpty) {
      return lastResetValue;
    }
    if (lastResetValue is Timestamp) {
      return _dateKey(lastResetValue.toDate());
    }
    if (lastResetValue is DateTime) {
      return _dateKey(lastResetValue);
    }

    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      return _dateKey(updatedAt.toDate());
    }
    if (updatedAt is DateTime) {
      return _dateKey(updatedAt);
    }
    if (updatedAt is String) {
      final parsed = DateTime.tryParse(updatedAt);
      if (parsed != null) {
        return _dateKey(parsed);
      }
    }
    return null;
  }

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
        final completedWorkoutsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('completed_workouts')
            .doc(widget.workout.title);
        final latestStatusDoc = await completedWorkoutsDoc.get();

        bool isCompletedToday = false;

        if (latestStatusDoc.exists) {
          final data = latestStatusDoc.data();
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
                  Text(
                    _isWorkoutSessionActive()
                        ? "Tap any exercise to continue the active workout."
                        : "Tap any exercise to preview it. Workout tracking only starts after pressing Start Workout.",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
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

  bool _isWorkoutSessionActive() {
    return _workoutStartTime != null;
  }

  Future<void> _openWorkoutExercise(int exerciseIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseNumber: exerciseIndex + 1,
          workout: widget.workout,
          isPreviewMode: false,
          initialDraft: _getExerciseDraft(exerciseIndex),
          draftForExercise: _getExerciseDraft,
          onExerciseViewed: markExerciseAsViewed,
          onWeightInput: markExerciseWithWeightInput,
          onDraftChanged: _updateExerciseDraft,
          onWorkoutCancelled: _cancelWorkoutSession,
        ),
      ),
    );
  }

 List<Widget> _buildExerciseList() {
    // Use the exerciseList from the workout model instead of calculating count
    List<Widget> exercises = [];
    for (int i = 0; i < widget.workout.exerciseList.length; i++) {
      final exercise = widget.workout.exerciseList[i];
      
      exercises.add(
        GestureDetector(
          onTap: () async {
            if (_isWorkoutSessionActive()) {
              await _openWorkoutExercise(i);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(
                  exerciseNumber: i + 1, // Use 1-based indexing for display
                  workout: widget.workout,
                  isPreviewMode: true,
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

  Future<void> _beginWorkoutSession() async {
    setState(() {
      _workoutStartTime = DateTime.now();
      _viewedExercises.clear(); // Reset viewed exercises when starting
      _exercisesWithWeightInput.clear(); // Reset weight input tracking when starting
      _exerciseDrafts.clear(); // Reset exercise drafts when starting
      _currentButtonState = 'start'; // Keep as start initially, will change when all exercises are viewed
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseNumber: 1, // Always start with the first exercise
          workout: widget.workout,
          isPreviewMode: false,
          initialDraft: _getExerciseDraft(0),
          draftForExercise: _getExerciseDraft,
          onExerciseViewed: markExerciseAsViewed, // Pass the callback to mark exercises as viewed
          onWeightInput: markExerciseWithWeightInput, // Pass the callback to mark exercises as having weight input
          onDraftChanged: _updateExerciseDraft,
          onWorkoutCancelled: _cancelWorkoutSession,
        ),
      ),
    );

    // When returning from exercises, check if all exercises have been viewed to update button state
    if (mounted && areAllExercisesViewed()) {
      setState(() {
        _currentButtonState = 'done';
      });
    }
  }

  // New methods for handling the different button states with popups
  void _onStartWorkoutPressed() {
    _beginWorkoutSession();
  }

  // Check if all exercises have had weight input
  bool areAllExercisesWithWeightInput() {
    if (_exerciseDrafts.length != widget.workout.exerciseList.length) {
      return false;
    }

    return List.generate(widget.workout.exerciseList.length, (index) => index)
        .every((index) {
      final draft = _exerciseDrafts[index];
      return draft != null &&
          draft.hasValidWeight &&
          draft.hasValidReps &&
          draft.hasValidSets;
    });
  }

  int _completedExerciseDraftCount() {
    return _exerciseDrafts.values.where((draft) {
      return draft.hasValidWeight &&
          draft.hasValidReps &&
          draft.hasValidSets;
    }).length;
  }

  // Mark an exercise as having weight input
  void markExerciseWithWeightInput(int exerciseIndex) {
    setState(() {
      _exercisesWithWeightInput.add(exerciseIndex);
    });
  }

  void _updateExerciseDraft(int exerciseIndex, ExerciseTrackingDraft draft) {
    setState(() {
      _exerciseDrafts[exerciseIndex] = draft;
      if (draft.hasValidWeight) {
        _exercisesWithWeightInput.add(exerciseIndex);
      } else {
        _exercisesWithWeightInput.remove(exerciseIndex);
      }
    });
  }

  ExerciseTrackingDraft? _getExerciseDraft(int exerciseIndex) {
    return _exerciseDrafts[exerciseIndex];
  }

  void _cancelWorkoutSession() {
    if (!mounted) {
      return;
    }

    setState(() {
      _workoutStartTime = null;
      _currentButtonState = _isWorkoutCompleted ? 'again' : 'start';
      _viewedExercises.clear();
      _exercisesWithWeightInput.clear();
      _exerciseDrafts.clear();
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
              "Exercise Input Required",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Please complete weight, reps, and sets for all exercises before finishing the workout. ${widget.workout.exerciseList.length - _completedExerciseDraftCount()} exercises are still incomplete.",
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

    final int parsedDurationSeconds = _parseDurationToSeconds(widget.workout.duration);
    final int draftExpectedDurationSeconds = _calculateExpectedWorkoutDurationFromDrafts();
    final int expectedDurationSeconds = draftExpectedDurationSeconds > 0
        ? draftExpectedDurationSeconds
        : (parsedDurationSeconds > 0 ? parsedDurationSeconds : 30 * 60);
    final int minimumLegitDurationSeconds = ((expectedDurationSeconds * 0.75)
                .round()
                .clamp(60, expectedDurationSeconds)
            as num)
        .toInt();

    // Determine if user might be cheating based on time
    bool isCheating = expectedDurationSeconds > 0 &&
        actualDurationSeconds < minimumLegitDurationSeconds;

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
              "Are you sure you are not cheating? Based on your exercise inputs, ${widget.workout.title} should take about ${_formatSecondsToMinutes(expectedDurationSeconds)}. We usually expect at least ${_formatSecondsToMinutes(minimumLegitDurationSeconds)}, but this run finished in ${_formatSecondsToMinutes(actualDurationSeconds)}.",
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
                Navigator.of(context).pop(); // Close dialog
                _beginWorkoutSession();
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

  int _calculateExpectedWorkoutDurationFromDrafts() {
    int totalSeconds = 0;

    for (int index = 0; index < widget.workout.exerciseList.length; index++) {
      final draft = _exerciseDrafts[index];
      final exercise = widget.workout.exerciseList[index];
      if (draft == null ||
          !draft.hasValidWeight ||
          !draft.hasValidReps ||
          !draft.hasValidSets) {
        continue;
      }

      final int reps = int.parse(draft.reps);
      final int sets = int.parse(draft.sets);
      final int activeSeconds = exercise.getEstimatedTotalDurationSeconds(
        sets: sets,
        reps: reps,
      );
      totalSeconds += activeSeconds;
    }

    return totalSeconds;
  }

  int _calculateWorkoutCaloriesFromDrafts() {
    double totalCalories = 0;

    for (int index = 0; index < widget.workout.exerciseList.length; index++) {
      final draft = _exerciseDrafts[index];
      final exercise = widget.workout.exerciseList[index];
      if (draft == null ||
          !draft.hasValidWeight ||
          !draft.hasValidReps ||
          !draft.hasValidSets) {
        continue;
      }

      final int reps = int.parse(draft.reps);
      final int sets = int.parse(draft.sets);
      totalCalories += exercise.getCaloriesBurned(
        sets: sets,
        reps: reps,
      );
    }

    return totalCalories.round();
  }

  int _calculateWorkoutMinutesFromDrafts() {
    final expectedSeconds = _calculateExpectedWorkoutDurationFromDrafts();
    if (expectedSeconds <= 0) {
      return 0;
    }

    return (expectedSeconds / 60).ceil();
  }

  int _calculateFallbackWorkoutCalories() {
    double totalCalories = 0;

    for (final exercise in widget.workout.exerciseList) {
      totalCalories += exercise.getCaloriesBurned(
        sets: 1,
        reps: 10,
      );
    }

    return totalCalories.round();
  }

  int _parseStoredMetric(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ??
          double.tryParse(value)?.round() ??
          0;
    }
    return 0;
  }

  Future<void> _updateHealthDashboardMetrics({
    required User user,
    required int workoutCalories,
    required int workoutMinutes,
    required int workoutCountChange,
  }) async {
    final healthRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current');

    final healthSnapshot = await healthRef.get();
    final healthData = healthSnapshot.data() ?? <String, dynamic>{};

    final currentCalories = _parseStoredMetric(healthData['weeklyCalories']);
    final currentMinutes = _parseStoredMetric(healthData['weeklyMinutes']);
    final currentWorkouts =
        _parseStoredMetric(healthData['weeklyWorkoutsCount']);
    final todayKey = _dateKey(DateTime.now());
    final storedDayKey = _resolveStoredDayKey(healthData);

    int baseCalories = currentCalories;
    int baseMinutes = currentMinutes;
    int baseWorkouts = currentWorkouts;

    if (storedDayKey != null && storedDayKey != todayKey) {
      final archivedDate = _dateFromKey(storedDayKey);
      if (currentCalories > 0 || currentMinutes > 0 || currentWorkouts > 0) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_activity')
            .doc(storedDayKey)
            .set({
          'date': archivedDate,
          'weeklyMinutes': currentMinutes,
          'weeklyCalories': currentCalories,
          'weeklyWorkoutsCount': currentWorkouts,
        }, SetOptions(merge: true));
      }

      baseCalories = 0;
      baseMinutes = 0;
      baseWorkouts = 0;
    }

    await healthRef.set({
      'weeklyCalories': (baseCalories + workoutCalories).clamp(0, 999999),
      'weeklyMinutes': (baseMinutes + workoutMinutes).clamp(0, 999999),
      'weeklyWorkoutsCount':
          (baseWorkouts + workoutCountChange).clamp(0, 999999),
      'lastDailyResetDate': todayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveExerciseDraftsToFirebase(User user) async {
    for (int index = 0; index < widget.workout.exerciseList.length; index++) {
      final draft = _exerciseDrafts[index];
      final exercise = widget.workout.exerciseList[index];
      if (draft == null ||
          !draft.hasValidWeight ||
          !draft.hasValidReps ||
          !draft.hasValidSets) {
        continue;
      }

      final int weight = int.parse(draft.weight);
      final int reps = int.parse(draft.reps);
      final int sets = int.parse(draft.sets);
      final int totalDurationSeconds = exercise.getEstimatedTotalDurationSeconds(
        sets: sets,
        reps: reps,
      );
      final double totalDurationMinutes = totalDurationSeconds / 60;
      final String durationString =
          "${totalDurationMinutes.toStringAsFixed(1)} min";
      final double totalCalories = exercise.getCaloriesBurned(
        sets: sets,
        reps: reps,
      );
      final String caloriesString = "${totalCalories.toStringAsFixed(1)} cal";

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_records')
          .doc(exercise.name)
          .set({
        'exerciseName': exercise.name,
        'workoutId': widget.workout.id,
        'weightUsed': weight.toDouble(),
        'repsPerformed': reps,
        'setsPerformed': sets,
        'timestamp': FieldValue.serverTimestamp(),
        'totalDurationString': durationString,
        'totalCaloriesString': caloriesString,
        'calculatedSeconds': totalDurationSeconds,
        'calculatedCalories': totalCalories,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _syncLatestWorkoutStatusDocument({
    required User user,
    required Map<String, dynamic>? latestEntryData,
  }) async {
    final latestStatusRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('completed_workouts')
        .doc(widget.workout.title);

    if (latestEntryData == null) {
      await latestStatusRef.delete();
      return;
    }

    await latestStatusRef.set(latestEntryData);
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

        final int parsedDurationSeconds = _parseDurationToSeconds(widget.workout.duration);
        final int draftExpectedDurationSeconds =
            _calculateExpectedWorkoutDurationFromDrafts();
        final int expectedDurationSeconds = draftExpectedDurationSeconds > 0
            ? draftExpectedDurationSeconds
            : (parsedDurationSeconds > 0 ? parsedDurationSeconds : 30 * 60);
        final int minimumLegitDurationSeconds = ((expectedDurationSeconds * 0.75)
                    .round()
                    .clamp(60, expectedDurationSeconds)
                as num)
            .toInt();
        final int workoutCalories =
            _calculateWorkoutCaloriesFromDrafts() > 0
                ? _calculateWorkoutCaloriesFromDrafts()
                : _calculateFallbackWorkoutCalories();
        final int workoutMinutes =
            _calculateWorkoutMinutesFromDrafts() > 0
                ? _calculateWorkoutMinutesFromDrafts()
                : (expectedDurationSeconds / 60).ceil();
        const int workoutCount = 1;
        bool isCheated = expectedDurationSeconds > 0 &&
            actualDurationSeconds < minimumLegitDurationSeconds;

        await _saveExerciseDraftsToFirebase(user);

        final completionEntry = {
          'title': widget.workout.title,
          'duration': widget.workout.duration,
          'exercises': widget.workout.exercises,
          'level': widget.workout.level,
          'bodyFocus': widget.workout.bodyFocus,
          'completedAt': FieldValue.serverTimestamp(),
          'actualDuration': actualDurationSeconds, // Store actual duration for reference
          'expectedDuration': expectedDurationSeconds, // Store expected duration for reference
          'minimumLegitDuration': minimumLegitDurationSeconds,
          'isCheated': isCheated, // Flag to indicate if workout was potentially cheated
          'recordedCalories': workoutCalories,
          'recordedMinutes': workoutMinutes,
          'recordedWorkoutCount': workoutCount,
        };

        // Keep append-only workout history so clean and cheated runs are both preserved.
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .add(completionEntry);

        // Keep one latest-status document per workout for card/detail UI.
        await _syncLatestWorkoutStatusDocument(
          user: user,
          latestEntryData: completionEntry,
        );

        await _updateHealthDashboardMetrics(
          user: user,
          workoutCalories: workoutCalories,
          workoutMinutes: workoutMinutes,
          workoutCountChange: workoutCount,
        );

        setState(() {
          _isWorkoutCompleted = true;
          _workoutStartTime = null;
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
        final todayStart = _startOfToday();
        final todayEnd = _endOfToday();
        final doneInfosRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos');

        final latestTodayEntries = await doneInfosRef
            .where('completedAt', isGreaterThanOrEqualTo: todayStart)
            .where('completedAt', isLessThan: todayEnd)
            .get();

        final matchingTodayEntries = latestTodayEntries.docs.where((doc) {
          final data = doc.data();
          return data['title'] == widget.workout.title;
        }).toList()
          ..sort((a, b) {
            final aTime = (a.data()['completedAt'] as Timestamp?)?.toDate();
            final bTime = (b.data()['completedAt'] as Timestamp?)?.toDate();
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        if (matchingTodayEntries.isNotEmpty) {
          final deletedEntryData = matchingTodayEntries.first.data();
          final int recordedCalories =
              (deletedEntryData['recordedCalories'] as num?)?.toInt() ?? 0;
          final int recordedMinutes =
              (deletedEntryData['recordedMinutes'] as num?)?.toInt() ?? 0;
          final int recordedWorkoutCount =
              (deletedEntryData['recordedWorkoutCount'] as num?)?.toInt() ?? 1;

          await matchingTodayEntries.first.reference.delete();

          await _updateHealthDashboardMetrics(
            user: user,
            workoutCalories: -recordedCalories,
            workoutMinutes: -recordedMinutes,
            workoutCountChange: -recordedWorkoutCount,
          );
        }

        final replacementLatestEntry = await doneInfosRef
            .orderBy('completedAt', descending: true)
            .get();

        Map<String, dynamic>? replacementData;
        for (final doc in replacementLatestEntry.docs) {
          final data = doc.data();
          if (data['title'] == widget.workout.title) {
            replacementData = data;
            break;
          }
        }

        await _syncLatestWorkoutStatusDocument(
          user: user,
          latestEntryData: replacementData,
        );

        bool hasCompletionToday = false;
        if (replacementData != null && replacementData['completedAt'] != null) {
          final completedAt = (replacementData['completedAt'] as Timestamp).toDate();
          final today = DateTime.now();
          hasCompletionToday = completedAt.year == today.year &&
              completedAt.month == today.month &&
              completedAt.day == today.day;
        }

        setState(() {
          _isWorkoutCompleted = hasCompletionToday;
          _currentButtonState = hasCompletionToday ? 'again' : 'start';
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
