import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../models/workout_model.dart';
import '../services/video_mapping_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseNumber;
  final Workout workout;
  final Function(int)? onExerciseViewed; // Callback to mark exercise as viewed
  final Function(int)? onWeightInput; // Callback to mark exercise as having weight input

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseNumber,
    required this.workout,
    this.onExerciseViewed,
    this.onWeightInput,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Exercise exercise;
  late TextEditingController weightController;
  late TextEditingController repsController;
  late TextEditingController setsController;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State variables for calculations
  String displayTotalDuration = "0 min";
  String displayTotalCalories = "0 cal";
  
  VideoPlayerController? _controller;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    exercise = widget.workout.exerciseList[widget.exerciseNumber - 1];
    
    // Initialize controllers with computed defaults based on exercise properties
    weightController = TextEditingController(text: "");
    repsController = TextEditingController(text: _computeDefaultReps().toString()); 
    setsController = TextEditingController(text: _computeDefaultSets().toString()); 
    
    // Add listeners to controllers to automatically recalculate when values change
    weightController.addListener(_calculateValues);
    repsController.addListener(_calculateValues);
    setsController.addListener(_calculateValues);
    
    // Add listener to automatically save when values change
    weightController.addListener(_autoSave);
    repsController.addListener(_autoSave);
    setsController.addListener(_autoSave);
    
    // Initialize video
    _initializeVideoPlayer();
    
    // Load saved user data
    _loadUserData();
  }

  // Method to compute default reps based on exercise properties
  int _computeDefaultReps() {
    // Default to 8 reps, but could be adjusted based on exercise type or difficulty
    // For now, using a simple approach - could be enhanced based on exercise characteristics
    if (exercise.name.toLowerCase().contains('beginner') || exercise.name.toLowerCase().contains('easy')) {
      return 6; // Lower reps for beginner exercises
    } else if (exercise.name.toLowerCase().contains('hard') || exercise.name.toLowerCase().contains('advanced')) {
      return 12; // Higher reps for advanced exercises
    } else {
      return 8; // Standard reps for intermediate exercises
    }
  }

  // Method to compute default sets based on exercise properties
  int _computeDefaultSets() {
    // Default to 3 sets, but could be adjusted based on exercise type or difficulty
    if (exercise.name.toLowerCase().contains('beginner') || exercise.name.toLowerCase().contains('easy')) {
      return 2; // Fewer sets for beginner exercises
    } else if (exercise.name.toLowerCase().contains('hard') || exercise.name.toLowerCase().contains('advanced')) {
      return 4; // More sets for advanced exercises
    } else {
      return 3; // Standard sets for intermediate exercises
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('exercise_records')
            .doc(exercise.name)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          
          // Check if the data is from today
          bool isToday = false;
          if (data['timestamp'] != null) {
            final Timestamp timestamp = data['timestamp'];
            final DateTime date = timestamp.toDate();
            final DateTime now = DateTime.now();
            isToday = date.year == now.year && 
                      date.month == now.month && 
                      date.day == now.day;
          }

          if (isToday) {
            // Restore inputs if from today
            setState(() {
              weightController.text = (data['weightUsed'] ?? 0.0).toString();
              repsController.text = (data['repsPerformed'] ?? 8).toString();
              setsController.text = (data['setsPerformed'] ?? 3).toString();
              
              // Restore calculated displays
              if (data['totalDurationString'] != null) {
                displayTotalDuration = data['totalDurationString'];
              }
              if (data['totalCaloriesString'] != null) {
                displayTotalCalories = data['totalCaloriesString'];
              }
            });
          } else {
             // Reset inputs if not from today (new day, new start)
             // We keep the defaults set in initState (empty weight, computed reps, computed sets)
             // and don't load the old values into the controllers.
             setState(() {
               weightController.text = "";
               repsController.text = _computeDefaultReps().toString();
               setsController.text = _computeDefaultSets().toString();
               displayTotalDuration = "0 min";
               displayTotalCalories = "0 cal";
             });
          }
        } else {
          // If no data exists for this exercise, use computed default values
          setState(() {
            weightController.text = "";
            repsController.text = _computeDefaultReps().toString();
            setsController.text = _computeDefaultSets().toString();
            displayTotalDuration = "0 min";
            displayTotalCalories = "0 cal";
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        _isLoadingData = false;
      });
      // Perform initial calculation after loading data
      _calculateValues();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      String? videoPath = VideoMappingService.getVideoPath(exercise.name);
      if (videoPath != null) {
        _controller = VideoPlayerController.asset(videoPath);
        await _controller!.initialize();
        setState(() {});
      }
    } catch (e) {
      print("Error initializing video player: $e");
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    weightController.removeListener(_calculateValues);
    repsController.removeListener(_calculateValues);
    setsController.removeListener(_calculateValues);
    
    _controller?.dispose();
    weightController.dispose();
    repsController.dispose();
    setsController.dispose();
    super.dispose();
  }

  // Automatic calculation method
  void _calculateValues() {
    // Get current values from controllers
    double weight = double.tryParse(weightController.text) ?? 0.0;
    int reps;
    int sets;
    
    // Use computed defaults if text fields are empty or invalid
    if (repsController.text.isEmpty || int.tryParse(repsController.text) == null) {
      reps = _computeDefaultReps();
    } else {
      reps = int.tryParse(repsController.text)!;
    }
    
    if (setsController.text.isEmpty || int.tryParse(setsController.text) == null) {
      sets = _computeDefaultSets();
    } else {
      sets = int.tryParse(setsController.text)!;
    }

    // Perform Calculations
    // Duration: Sets * Duration Per Set (exercise.duration is in seconds)
    int totalDurationSeconds = sets * exercise.duration;
    double totalDurationMinutes = totalDurationSeconds / 60;
    String durationString = "${totalDurationMinutes.toStringAsFixed(1)} min";

    // Calories: Sets * Calories Per Set (exercise.getCaloriesBurned returns base calories)
    double baseCalories = exercise.getCaloriesBurned();
    double totalCalories = sets * baseCalories;
    String caloriesString = "${totalCalories.toStringAsFixed(1)} cal";

    setState(() {
      displayTotalDuration = durationString;
      displayTotalCalories = caloriesString;
    });

    // Check if weight has been entered and notify the workout screen if needed
    if (weight > 0 && widget.onWeightInput != null) {
      widget.onWeightInput!(widget.exerciseNumber - 1); // Convert to 0-based index
    }
  }

  // Automatic save method
  void _autoSave() {
    // Only save if the exercise has been viewed for the first time in this session
    // This prevents excessive saves during user input
    _saveExerciseRecord();
  }

  // Calculate and Save Data
 Future<void> _saveExerciseRecord() async {
    // 1. Get Inputs
    double weight = double.tryParse(weightController.text) ?? 0.0;
    int reps;
    int sets;
    
    // Use computed defaults if text fields are empty or invalid
    if (repsController.text.isEmpty || int.tryParse(repsController.text) == null) {
      reps = _computeDefaultReps();
    } else {
      reps = int.tryParse(repsController.text)!;
    }
    
    if (setsController.text.isEmpty || int.tryParse(setsController.text) == null) {
      sets = _computeDefaultSets();
    } else {
      sets = int.tryParse(setsController.text)!;
    }

    // 2. Perform Calculations
    // Duration: Sets * Duration Per Set (exercise.duration is in seconds)
    int totalDurationSeconds = sets * exercise.duration;
    double totalDurationMinutes = totalDurationSeconds / 60;
    String durationString = "${totalDurationMinutes.toStringAsFixed(1)} min";

    // Calories: Sets * Calories Per Set (exercise.getCaloriesBurned returns base calories)
    double baseCalories = exercise.getCaloriesBurned();
    double totalCalories = sets * baseCalories;
    String caloriesString = "${totalCalories.toStringAsFixed(1)} cal";

    setState(() {
      displayTotalDuration = durationString;
      displayTotalCalories = caloriesString;
    });

    // 3. Save to Firestore
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('exercise_records')
            .doc(exercise.name)
            .set({
          'exerciseName': exercise.name,
          'workoutId': widget.workout.id,
          'weightUsed': weight,
          'repsPerformed': reps,
          'setsPerformed': sets,
          'timestamp': FieldValue.serverTimestamp(),
          'totalDurationString': durationString,
          'totalCaloriesString': caloriesString,
          'calculatedSeconds': totalDurationSeconds,
          'calculatedCalories': totalCalories,
        }, SetOptions(merge: true));

        // Removed notification - data saved silently
      }
    } catch (e) {
      print("Error saving user data: $e");
      // Removed error notification - errors handled silently
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mark this exercise as viewed when the screen is built (user accesses it)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onExerciseViewed != null) {
        widget.onExerciseViewed!(widget.exerciseNumber - 1); // Convert to 0-based index
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            // Check if weight has been input before allowing exit
            if (weightController.text.isEmpty || double.tryParse(weightController.text) == null || double.tryParse(weightController.text)! <= 0) {
              bool shouldExit = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF191919),
                    title: const Text(
                      "Input Required",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "Please input the weight you used for this exercise before exiting.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Don't exit
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Allow exit
                        },
                        child: const Text(
                          "Exit Anyway",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  );
                },
              );
              
              if (!shouldExit) {
                return; // Don't exit if user chooses to stay
              }
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Player Section
                  if (_controller != null && _controller!.value.isInitialized)
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                            const SizedBox(height: 12),
                            IconButton(
                              icon: Icon(
                                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_controller!.value.isPlaying) {
                                    _controller!.pause();
                                  } else {
                                    _controller!.play();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.videocam_off,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Video not available for ${exercise.name}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

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
                          Text(
                            exercise.name,
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

                  // Performance Tracking
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    labelStyle: TextStyle(color: Colors.orange),
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.orange),
                                    ),
                                  ),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    labelStyle: TextStyle(color: Colors.orange),
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.orange),
                                    ),
                                  ),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Sets',
                                    labelStyle: TextStyle(color: Colors.orange),
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.orange),
                                    ),
                                  ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Exercise Info (Updated to show Calculated Results)
                  const Text(
                    "Result Details",
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
                          // Changed label and value to dynamic calculation
                          _buildInfoRow(Icons.timer, "Total Duration", displayTotalDuration), 
                          const Divider(height: 20, color: Colors.white38),
                          // Changed label and value to dynamic calculation
                          _buildInfoRow(Icons.local_fire_department, "Total Calories", displayTotalCalories), 
                          const Divider(height: 20, color: Colors.white38),
                          _buildInfoRow(Icons.repeat, "Rec. Reps/Sets", "3-4 sets × 8-12 reps"),
                          const Divider(height: 20, color: Colors.white38),
                          _buildInfoRow(Icons.directions_run, "Rest Period", "60-90 seconds"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
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
                        exercise.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tips
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
                        children: [
                          _buildTip(Icons.check_circle, "Maintain proper posture throughout the exercise"),
                          const SizedBox(height: 8),
                          _buildTip(Icons.check_circle, "Breathe consistently - exhale on exertion"),
                          const SizedBox(height: 8),
                          _buildTip(Icons.check_circle, "Start with lighter weights and progress gradually"),
                          const SizedBox(height: 8),
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
                onPressed: () async {
                  // Check if weight has been input before allowing navigation
                  if (weightController.text.isEmpty || double.tryParse(weightController.text) == null || double.tryParse(weightController.text)! <= 0) {
                    bool shouldNavigate = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF191919),
                          title: const Text(
                            "Input Required",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            "Please input the weight you used for this exercise before navigating.",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false); // Don't navigate
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true); // Allow navigation
                              },
                              child: const Text(
                                "Continue Anyway",
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (!shouldNavigate) {
                      return; // Don't navigate if user chooses to stay
                    }
                  }
                  
                  // Mark current exercise as viewed and with weight input before navigating
                  if (widget.onExerciseViewed != null) {
                    widget.onExerciseViewed!(widget.exerciseNumber - 1); // Convert to 0-based index
                  }
                  
                  double weight = double.tryParse(weightController.text) ?? 0.0;
                  if (weight > 0 && widget.onWeightInput != null) {
                    widget.onWeightInput!(widget.exerciseNumber - 1); // Convert to 0-based index
                  }
                  
                  // For previous button, save before navigating
                  if (widget.exerciseNumber > 1) {
                    await _saveExerciseRecord();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          exerciseNumber: widget.exerciseNumber - 1,
                          workout: widget.workout,
                          onExerciseViewed: widget.onExerciseViewed,
                          onWeightInput: widget.onWeightInput,
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
                onPressed: () async {
                  int totalExercises = widget.workout.exerciseList.length;
                  
                  // Check if weight has been input before allowing navigation (except for the last exercise)
                  if (widget.exerciseNumber < totalExercises) {
                    if (weightController.text.isEmpty || double.tryParse(weightController.text) == null || double.tryParse(weightController.text)! <= 0) {
                      bool shouldNavigate = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF191919),
                            title: const Text(
                              "Input Required",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "Please input the weight you used for this exercise before navigating.",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false); // Don't navigate
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true); // Allow navigation
                                },
                                child: const Text(
                                  "Continue Anyway",
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (!shouldNavigate) {
                        return; // Don't navigate if user chooses to stay
                      }
                    }
                    
                    // Mark current exercise as viewed and with weight input before navigating
                    if (widget.onExerciseViewed != null) {
                      widget.onExerciseViewed!(widget.exerciseNumber - 1); // Convert to 0-based index
                    }
                    
                    double weight = double.tryParse(weightController.text) ?? 0.0;
                    if (weight > 0 && widget.onWeightInput != null) {
                      widget.onWeightInput!(widget.exerciseNumber - 1); // Convert to 0-based index
                    }
                  }
                  
                  // For the last exercise, don't save automatically when pressing "Done"
                  if (widget.exerciseNumber < totalExercises) {
                    // Save before navigating to next exercise
                    await _saveExerciseRecord();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          exerciseNumber: widget.exerciseNumber + 1,
                          workout: widget.workout,
                          onExerciseViewed: widget.onExerciseViewed,
                          onWeightInput: widget.onWeightInput,
                        ),
                      ),
                    );
                  } else {
                    // This is the last exercise, so just go back to workout detail screen
                    // The workout will be saved when the user presses the "Done" button on the workout screen
                    // Mark this exercise as viewed and with weight input before going back
                    if (widget.onExerciseViewed != null) {
                      widget.onExerciseViewed!(widget.exerciseNumber - 1); // Convert to 0-based index
                    }
                    
                    double weight = double.tryParse(weightController.text) ?? 0.0;
                    if (weight > 0 && widget.onWeightInput != null) {
                      widget.onWeightInput!(widget.exerciseNumber - 1); // Convert to 0-based index
                    }
                    
                    Navigator.pop(context); // Go back to workout detail screen
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
                  widget.exerciseNumber < widget.workout.exerciseList.length
                      ? "Next" 
                      : "Done", // Changed from "Finish Workout" to "Done"
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

  // Fixed function instead of class
  Widget _buildTip(IconData icon, String text) {
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
