import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../models/workout_model.dart';
import '../services/video_mapping_service.dart';

class ExerciseTrackingDraft {
  final String weight;
  final String reps;
  final String sets;

  const ExerciseTrackingDraft({
    required this.weight,
    required this.reps,
    required this.sets,
  });

  int? _parsePositiveWholeNumber(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final value = int.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  bool get hasValidWeight => _parsePositiveWholeNumber(weight) != null;
  bool get hasValidReps => _parsePositiveWholeNumber(reps) != null;
  bool get hasValidSets => _parsePositiveWholeNumber(sets) != null;
}

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseNumber;
  final Workout workout;
  final bool isPreviewMode;
  final bool isReadOnlyMode;
  final ExerciseTrackingDraft? initialDraft;
  final ExerciseTrackingDraft? Function(int)? draftForExercise;
  final Function(int)? onExerciseViewed; // Callback to mark exercise as viewed
  final Function(int)? onWeightInput; // Callback to mark exercise as having weight input
  final void Function(int exerciseIndex, ExerciseTrackingDraft draft)? onDraftChanged;
  final VoidCallback? onWorkoutCancelled;

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseNumber,
    required this.workout,
    this.isPreviewMode = false,
    this.isReadOnlyMode = false,
    this.initialDraft,
    this.draftForExercise,
    this.onExerciseViewed,
    this.onWeightInput,
    this.onDraftChanged,
    this.onWorkoutCancelled,
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
  int _recommendedTotalDurationSeconds = 0;
  int _remainingTimerSeconds = 0;
  bool _isTimerRunning = false;
  bool _isTimerCompleted = false;
  
  Timer? _exerciseTimer;
  VideoPlayerController? _controller;
  bool _isLoadingData = true;
  bool _isVideoMuted = false;

  @override
  void initState() {
    super.initState();
    exercise = widget.workout.exerciseList[widget.exerciseNumber - 1];
    
    // Initialize controllers with computed defaults based on exercise properties
    weightController = TextEditingController(text: "");
    repsController = TextEditingController(text: _computeDefaultReps().toString()); 
    setsController = TextEditingController(text: _computeDefaultSets().toString()); 
    
    // Add listeners to controllers to automatically recalculate when values change
    if (!widget.isPreviewMode && !widget.isReadOnlyMode) {
      weightController.addListener(_calculateValues);
      repsController.addListener(_calculateValues);
      setsController.addListener(_calculateValues);

      // Keep the current exercise inputs in memory while the workout is in progress
      weightController.addListener(_autoSave);
      repsController.addListener(_autoSave);
      setsController.addListener(_autoSave);
    }
    
    // Initialize video
    _initializeVideoPlayer();
    
    // Load saved user data for active tracking and completed-workout review.
    if (widget.initialDraft != null) {
      weightController.text = widget.initialDraft!.weight;
      repsController.text = widget.initialDraft!.reps;
      setsController.text = widget.initialDraft!.sets;
      _isLoadingData = false;
      _calculateValues();
      _scheduleDraftSync();
    } else if (widget.isPreviewMode) {
      _isLoadingData = false;
      _calculateValues();
    } else {
      _loadUserData();
    }
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

  String _exerciseRecordDocId(String exerciseName) {
    final sanitized = exerciseName
        .trim()
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    return sanitized.isEmpty ? 'exercise_record' : sanitized;
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('exercise_records')
            .doc(_exerciseRecordDocId(exercise.name))
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
              final num savedWeight = (data['weightUsed'] ?? 0) as num;
              weightController.text =
                  savedWeight > 0 ? savedWeight.toInt().toString() : "";
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
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingData = false;
      });
      // Perform initial calculation after loading data
      _calculateValues();
      _scheduleDraftSync();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    VideoPlayerController? initializedController;
    try {
      final candidatePaths = await _resolveVideoCandidatePaths();

      for (final videoPath in candidatePaths) {
        try {
          final controller = kIsWeb
              ? VideoPlayerController.networkUrl(
                  Uri.base.resolve(Uri.encodeFull(videoPath)),
                )
              : VideoPlayerController.asset(videoPath);
          await controller.initialize();
          await controller.setVolume(_isVideoMuted ? 0.0 : 1.0);
          initializedController = controller;
          break;
        } catch (error) {
          print("Failed video candidate '$videoPath' for '${exercise.name}': $error");
        }
      }

      if (!mounted) {
        await initializedController?.dispose();
        return;
      }

      if (initializedController != null) {
        setState(() {
          _controller = initializedController;
        });
      }
    } catch (e) {
      print("Error initializing video player: $e");
    }
  }

  String _normalizeAssetText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<List<String>> _resolveVideoCandidatePaths() async {
    final candidates = <String>[];

    void addCandidate(String? path) {
      if (path == null || path.isEmpty || candidates.contains(path)) {
        return;
      }
      candidates.add(path);
    }

    final mappedCandidates = VideoMappingService.getVideoCandidatePaths(
      exercise.name,
      journeyName: widget.workout.journeyName,
      workoutTitle: widget.workout.title,
    );
    for (final path in mappedCandidates) {
      addCandidate(path);
    }

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
      final normalizedExercise = _normalizeAssetText(exercise.name);
      final normalizedWorkout = _normalizeAssetText(widget.workout.title);
      final normalizedJourney = _normalizeAssetText(
        widget.workout.journeyName ?? '',
      );

      final manifestMatches = manifest.keys
          .where((key) => key.toLowerCase().endsWith('.mp4'))
          .map((key) {
            final normalizedKey = _normalizeAssetText(key);
            int score = 0;

            if (normalizedKey.contains(normalizedExercise)) {
              score += 100;
            }
            if (normalizedWorkout.isNotEmpty &&
                normalizedKey.contains(normalizedWorkout)) {
              score += 60;
            }
            if (normalizedJourney.isNotEmpty &&
                normalizedKey.contains(normalizedJourney)) {
              score += 40;
            }
            if ((widget.workout.journeyName ?? '').isNotEmpty &&
                normalizedKey.contains('fitness journey')) {
              score += 20;
            }

            return MapEntry(key, score);
          })
          .where((entry) => entry.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in manifestMatches) {
        addCandidate(entry.key);
      }
    } catch (e) {
      print("Error reading asset manifest for '${exercise.name}': $e");
    }

    return candidates;
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    if (!widget.isPreviewMode && !widget.isReadOnlyMode) {
      weightController.removeListener(_calculateValues);
      repsController.removeListener(_calculateValues);
      setsController.removeListener(_calculateValues);
    }
    
    _exerciseTimer?.cancel();
    _controller?.dispose();
    weightController.dispose();
    repsController.dispose();
    setsController.dispose();
    super.dispose();
  }

  int? _parsePositiveWholeNumber(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final value = int.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  bool _hasValidWeight() => _parsePositiveWholeNumber(weightController.text) != null;

  bool _hasValidReps() => _parsePositiveWholeNumber(repsController.text) != null;

  bool _hasValidSets() => _parsePositiveWholeNumber(setsController.text) != null;

  bool get _requiresWeightInput => exercise.requiresWeightInput;

  Future<void> _showInputRequiredDialog(String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: const Text(
            "Input Required",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  Future<bool> _validateTrackingInputs() async {
    if (_requiresWeightInput && !_hasValidWeight()) {
      await _showInputRequiredDialog(
        "Please enter the weight you used as a whole number greater than 0.",
      );
      return false;
    }

    if (!_hasValidReps()) {
      await _showInputRequiredDialog(
        "Please enter reps as a whole number greater than 0.",
      );
      return false;
    }

    if (!_hasValidSets()) {
      await _showInputRequiredDialog(
        "Please enter sets as a whole number greater than 0.",
      );
      return false;
    }

    return true;
  }

  void _notifyValidWeightInput() {
    if (!widget.isPreviewMode &&
        !widget.isReadOnlyMode &&
        widget.onWeightInput != null &&
        (!_requiresWeightInput || _hasValidWeight())) {
      widget.onWeightInput!(widget.exerciseNumber - 1);
    }
  }

  void _notifyDraftChanged() {
    if (widget.isPreviewMode ||
        widget.isReadOnlyMode ||
        widget.onDraftChanged == null) {
      return;
    }

    widget.onDraftChanged!(
      widget.exerciseNumber - 1,
      ExerciseTrackingDraft(
        weight: weightController.text,
        reps: repsController.text,
        sets: setsController.text,
      ),
    );
  }

  void _scheduleDraftSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _notifyDraftChanged();
    });
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');
    return '$minuteText:$secondText';
  }

  void _syncTimerWithRecommendation() {
    if (_isTimerRunning) {
      return;
    }

    _exerciseTimer?.cancel();
    _remainingTimerSeconds = _recommendedTotalDurationSeconds;
    _isTimerCompleted = _recommendedTotalDurationSeconds == 0;
  }

  void _toggleTimer() {
    if (_recommendedTotalDurationSeconds <= 0) {
      return;
    }

    if (_isTimerRunning) {
      _exerciseTimer?.cancel();
      setState(() {
        _isTimerRunning = false;
      });
      return;
    }

    if (_remainingTimerSeconds <= 0) {
      _remainingTimerSeconds = _recommendedTotalDurationSeconds;
      _isTimerCompleted = false;
    }

    setState(() {
      _isTimerRunning = true;
    });

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingTimerSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingTimerSeconds = 0;
          _isTimerRunning = false;
          _isTimerCompleted = true;
        });
        return;
      }

      setState(() {
        _remainingTimerSeconds--;
      });
    });
  }

  void _cancelTimer() {
    _exerciseTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isTimerCompleted = false;
      _remainingTimerSeconds = _recommendedTotalDurationSeconds;
    });
  }

  void _completeTimer() {
    _exerciseTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isTimerCompleted = true;
      _remainingTimerSeconds = 0;
    });
  }

  void _markExerciseAsViewed() {
    if (!widget.isPreviewMode &&
        !widget.isReadOnlyMode &&
        widget.onExerciseViewed != null) {
      widget.onExerciseViewed!(widget.exerciseNumber - 1);
    }
  }

  Future<void> _openExercise(int exerciseNumber) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseNumber: exerciseNumber,
          workout: widget.workout,
          isPreviewMode: widget.isPreviewMode,
          isReadOnlyMode: widget.isReadOnlyMode,
          initialDraft: widget.draftForExercise?.call(exerciseNumber - 1),
          draftForExercise: widget.draftForExercise,
          onExerciseViewed: widget.onExerciseViewed,
          onWeightInput: widget.onWeightInput,
          onDraftChanged: widget.onDraftChanged,
          onWorkoutCancelled: widget.onWorkoutCancelled,
        ),
      ),
    );
  }

  Future<bool> _handleBackNavigation() async {
    if (widget.isPreviewMode || widget.isReadOnlyMode) {
      return true;
    }

    if (widget.exerciseNumber > 1) {
      _notifyDraftChanged();

      if (!mounted) {
        return false;
      }

      await _openExercise(widget.exerciseNumber - 1);
      return false;
    }

    _notifyDraftChanged();
    return true;
  }

  // Automatic calculation method
  void _calculateValues() {
    // Get current values from controllers
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

    // Perform calculations based on both sets and reps
    int totalDurationSeconds = exercise.getEstimatedTotalDurationSeconds(
      sets: sets,
      reps: reps,
    );
    double totalDurationMinutes = totalDurationSeconds / 60;
    String durationString = "${totalDurationMinutes.toStringAsFixed(1)} min";

    double totalCalories = exercise.getCaloriesBurned(
      sets: sets,
      reps: reps,
    );
    String caloriesString = "${totalCalories.toStringAsFixed(1)} cal";

    setState(() {
      displayTotalDuration = durationString;
      displayTotalCalories = caloriesString;
      _recommendedTotalDurationSeconds = totalDurationSeconds;
      _syncTimerWithRecommendation();
    });
  }

  // Automatic save method
  void _autoSave() {
    _notifyDraftChanged();
  }

  // Calculate and Save Data
 Future<void> _saveExerciseRecord() async {
    _notifyDraftChanged();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          leading: widget.isPreviewMode ||
                  widget.isReadOnlyMode ||
                  widget.exerciseNumber == 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    final shouldPop = await _handleBackNavigation();
                    if (shouldPop && mounted) {
                      Navigator.pop(context);
                    }
                  },
                )
              : null,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
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
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    _isVideoMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () async {
                                    final controller = _controller;
                                    if (controller == null) {
                                      return;
                                    }

                                    final nextMutedState = !_isVideoMuted;
                                    await controller.setVolume(
                                      nextMutedState ? 0.0 : 1.0,
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {
                                      _isVideoMuted = nextMutedState;
                                    });
                                  },
                                ),
                              ],
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

                  if (!widget.isPreviewMode && !widget.isReadOnlyMode) ...[
                    const Text(
                      "Exercise Timer",
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
                          children: [
                            Text(
                              _formatCountdown(_remainingTimerSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isTimerCompleted
                                  ? "Timer completed"
                                  : "Recommended time updates with your reps and sets",
                              style: TextStyle(
                                color: _isTimerCompleted
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _toggleTimer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isTimerRunning ? "Pause" : "Start",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelTimer,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _completeTimer,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.greenAccent,
                                      side: const BorderSide(
                                        color: Colors.greenAccent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Done"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (widget.isPreviewMode) ...[
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
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Preview only. Start the workout from the previous screen to log weight, reps, and sets.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (widget.isReadOnlyMode) ...[
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
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Completed workout review. Inputs are locked after finishing. Tap Again on the previous screen to log a new session.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
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
                  Text(
                    _requiresWeightInput
                        ? "Input the weight, sets and reps you have done"
                        : "Input the sets and reps you have done. Weight is locked for this bodyweight exercise.",
                    style: const TextStyle(
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
                          if (_requiresWeightInput)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: weightController,
                                    enabled: !widget.isReadOnlyMode,
                                    readOnly: widget.isReadOnlyMode,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: widget.isReadOnlyMode
                                        ? null
                                        : (_) {
                                            _notifyValidWeightInput();
                                          },
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Weight (kg)',
                                      helperText: 'Whole numbers only',
                                      helperStyle: TextStyle(color: Colors.white54),
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
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.accessibility_new,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Weight (kg)',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Bodyweight only',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'No manual weight entry needed for this exercise.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          // Reps Input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: repsController,
                                  enabled: !widget.isReadOnlyMode,
                                  readOnly: widget.isReadOnlyMode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    helperText: 'Whole numbers only',
                                    helperStyle: TextStyle(color: Colors.white54),
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
                                  enabled: !widget.isReadOnlyMode,
                                  readOnly: widget.isReadOnlyMode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Sets',
                                    helperText: 'Whole numbers only',
                                    helperStyle: TextStyle(color: Colors.white54),
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
                          _buildInfoRow(Icons.repeat, "Rec. Reps/Sets", "3-4 sets x 8-12 reps"),
                          const Divider(height: 20, color: Colors.white38),
                          _buildInfoRow(Icons.directions_run, "Rest Period", "60-90 seconds"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ],

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
        bottomNavigationBar: widget.isPreviewMode
            ? null
            : Container(
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
                        onPressed: widget.exerciseNumber > 1
                            ? () async {
                                if (widget.isReadOnlyMode) {
                                  await _openExercise(widget.exerciseNumber - 1);
                                } else {
                                  await _handleBackNavigation();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[900],
                          disabledForegroundColor: Colors.white38,
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

                          if (widget.isReadOnlyMode) {
                            if (widget.exerciseNumber < totalExercises) {
                              await _openExercise(widget.exerciseNumber + 1);
                            } else if (mounted) {
                              Navigator.pop(context);
                            }
                            return;
                          }

                          if (!await _validateTrackingInputs()) {
                            return;
                          }

                          _markExerciseAsViewed();
                          _notifyValidWeightInput();

                          // For the last exercise, don't save automatically when pressing "Done"
                          if (widget.exerciseNumber < totalExercises) {
                            // Save before navigating to next exercise
                            await _saveExerciseRecord();
                            await _openExercise(widget.exerciseNumber + 1);
                          } else {
                            // This is the last exercise, so just go back to workout detail screen
                            // The workout will be saved when the user presses the "Done" button on the workout screen
                            await _saveExerciseRecord();
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
                          widget.isReadOnlyMode
                              ? (widget.exerciseNumber < widget.workout.exerciseList.length
                                  ? "Next"
                                  : "Back")
                              : widget.exerciseNumber < widget.workout.exerciseList.length
                                  ? "Next"
                                  : "Done",
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
