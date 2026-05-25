import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import '../services/journey_progress_service.dart';
import '../services/workout_goal_service.dart';
import 'exercise_detail_screen.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/premium_back_button.dart';

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
  bool _isSavingWorkoutCompletion = false;
  String _currentButtonState = 'start'; // 'start', 'done', 'again'
  DateTime? _workoutStartTime;
  bool _isJourneyAccessLoading = false;
  bool _isJourneyStarted = true;
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

  String _exerciseRecordDocId(String exerciseName) {
    final sanitized = exerciseName
        .trim()
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    return sanitized.isEmpty ? 'exercise_record' : sanitized;
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
    _isJourneyStarted = widget.workout.journeyId == null;
    _checkWorkoutCompletionStatus();
    _loadJourneyAccessStatus();
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

  Future<void> _loadJourneyAccessStatus() async {
    if (widget.workout.journeyId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJourneyStarted = true;
        _isJourneyAccessLoading = false;
      });
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isJourneyStarted = false;
          _isJourneyAccessLoading = false;
        });
        return;
      }

      setState(() {
        _isJourneyAccessLoading = true;
      });

      final journeyDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journey_progress')
          .doc(widget.workout.journeyId)
          .get();

      final data = journeyDoc.data();
      final status = data?['status'] as String?;

      if (!mounted) {
        return;
      }

      setState(() {
        _isJourneyStarted = status == 'in_progress' || status == 'completed';
        _isJourneyAccessLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJourneyStarted = widget.workout.journeyId == null;
        _isJourneyAccessLoading = false;
      });
    }
  }

  @override
 Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTabletLayout = screenWidth >= 700;
    final bool isWideLayout = screenWidth >= 1100;
    final double contentMaxWidth = isWideLayout
        ? 1280
        : (isTabletLayout ? 920 : double.infinity);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.black,
          leading: _isSavingWorkoutCompletion
              ? null
              : PremiumBackButton(
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
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: isWideLayout
                  ? _buildDesktopContent()
                  : SingleChildScrollView(
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
                      child: widget.workout.thumbnailAsset.startsWith('http')
                          ? Image.network(
                              widget.workout.thumbnailAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 60,
                                );
                              },
                            )
                          : Image.asset(
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
                        widget.workout.description != null && widget.workout.description!.isNotEmpty
                            ? widget.workout.description!
                            : "This ${widget.workout.level.toLowerCase()} level ${widget.workout.bodyFocus.toLowerCase()} workout is designed to help you build strength and improve your fitness. The routine includes ${widget.workout.exerciseList.length} exercises that target various muscle groups in the ${widget.workout.bodyFocus.toLowerCase()} area.",
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
                        : _isWorkoutCompleted
                            ? "Tap any exercise to review this completed workout. Inputs are locked after finishing."
                            : (!_isJourneyStarted && widget.workout.journeyId != null)
                                ? "Preview only. Start this journey first to unlock workout tracking."
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
          ),
        ),
        bottomNavigationBar: isWideLayout ? null : Container(
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
          child: (!_isJourneyStarted && widget.workout.journeyId != null)
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isJourneyAccessLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Preview mode only. Tap Start Journey on the previous screen to unlock Start Workout.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _getButtonAction() == null
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _getButtonAction() == null ? Colors.grey[800] : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _getButtonAction() != null
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _getButtonAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.workout.thumbnailAsset.startsWith('http')
                          ? Image.network(
                              widget.workout.thumbnailAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 60,
                                );
                              },
                            )
                          : Image.asset(
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            children: [
                              _buildInfoItem(
                                icon: Icons.fitness_center,
                                label:
                                    "${widget.workout.exerciseList.length} exercises",
                              ),
                              _buildInfoItem(
                                icon: Icons.timer_outlined,
                                label: _getTotalExerciseDuration(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(widget.workout.level)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getLevelColor(widget.workout.level)
                                        .withOpacity(0.4),
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
                        widget.workout.description != null && widget.workout.description!.isNotEmpty
                            ? widget.workout.description!
                            : "This ${widget.workout.level.toLowerCase()} level ${widget.workout.bodyFocus.toLowerCase()} workout is designed to help you build strength and improve your fitness. The routine includes ${widget.workout.exerciseList.length} exercises that target various muscle groups in the ${widget.workout.bodyFocus.toLowerCase()} area.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        : _isWorkoutCompleted
                            ? "Tap any exercise to review this completed workout. Inputs are locked after finishing."
                            : (!_isJourneyStarted && widget.workout.journeyId != null)
                                ? "Preview only. Start this journey first to unlock workout tracking."
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: (!_isJourneyStarted && widget.workout.journeyId != null)
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (_isJourneyAccessLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Preview mode only. Tap Start Journey on the previous screen to unlock Start Workout.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: _getButtonAction() == null
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _getButtonAction() == null ? Colors.grey[800] : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _getButtonAction() != null
                                  ? [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: _getButtonAction(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle back button press to properly manage workout state
  Future<bool> _onBackPressed() async {
    if (_isSavingWorkoutCompletion) {
      return false;
    }

    // Keep the cancel confirmation active until the workout is actually saved.
    if (_isWorkoutSessionActive() && !_isWorkoutCompleted) {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return PremiumDialog(
            title: "Workout in Progress",
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF9800),
            content: const Text(
              "You have a workout in progress. Are you sure you want to exit? Your progress will not be saved.",
            ),
            actions: [
              PremiumCancelButton(
                label: "Cancel",
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              PremiumConfirmButton(
                label: "Exit",
                gradientColors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
                onPressed: () {
                  _cancelWorkoutSession();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ?? false;
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

  Future<void> _openWorkoutExercise(
    int exerciseIndex, {
    bool isReadOnlyMode = false,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseNumber: exerciseIndex + 1,
          workout: widget.workout,
          isPreviewMode: false,
          isReadOnlyMode: isReadOnlyMode,
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

            if (_isWorkoutCompleted) {
              await _openWorkoutExercise(i, isReadOnlyMode: true);
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (i + 1).toString(), // Use 1-based indexing for display
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
    if (_isSavingWorkoutCompletion) {
      return 'Saving...';
    }
    switch (_currentButtonState) {
      case 'start':
        return 'Start Workout';
      case 'done':
        return 'Done';
      case 'again':
        return 'Start Workout Again';
      default:
        return 'Start Workout';
    }
 }

  Color _getButtonColor() {
    if (_isSavingWorkoutCompletion) {
      return Colors.grey;
    }
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
    if (_isSavingWorkoutCompletion) {
      return null;
    }
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

  bool _draftHasRequiredInputs(int exerciseIndex, ExerciseTrackingDraft? draft) {
    if (draft == null) {
      return false;
    }

    final exercise = widget.workout.exerciseList[exerciseIndex];
    final hasRequiredWeight = !exercise.requiresWeightInput || draft.hasValidWeight;

    return hasRequiredWeight && draft.hasValidReps && draft.hasValidSets;
  }

  // Check if all exercises have had weight input
  bool areAllExercisesWithWeightInput() {
    if (_exerciseDrafts.length != widget.workout.exerciseList.length) {
      return false;
    }

    return List.generate(widget.workout.exerciseList.length, (index) => index)
        .every((index) {
      final draft = _exerciseDrafts[index];
      return _draftHasRequiredInputs(index, draft);
    });
  }

  int _completedExerciseDraftCount() {
    return _exerciseDrafts.entries.where((entry) {
      return _draftHasRequiredInputs(entry.key, entry.value);
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
      if (_draftHasRequiredInputs(exerciseIndex, draft)) {
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
    if (_isSavingWorkoutCompletion) {
      return;
    }

    // Check if all exercises have weight input before allowing completion
    if (!areAllExercisesWithWeightInput()) {
      // Show notification that not all exercises have weight input
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return PremiumDialog(
            title: "Exercise Input Required",
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF3EA6FF),
            content: Text(
              "Please complete reps, sets, and weight where needed before finishing the workout. ${widget.workout.exerciseList.length - _completedExerciseDraftCount()} exercises are still incomplete.",
            ),
            actions: [
              PremiumConfirmButton(
                label: "OK",
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
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

    // Show congratulations popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PremiumDialog(
          title: "Congratulations!",
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFFFD700),
          content: Text(
            "Great job completing the ${widget.workout.title} workout in ${_formatSecondsToMinutes(actualDurationSeconds)}! Your progress has been saved.",
          ),
          actions: [
            PremiumConfirmButton(
              label: "OK",
              gradientColors: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
              onPressed: _isSavingWorkoutCompletion
                  ? null
                  : () async {
                      if (mounted) {
                        setState(() {
                          _isSavingWorkoutCompletion = true;
                        });
                      }
                      Navigator.of(context).pop(); // Close dialog
                      await _saveWorkoutCompletion();
                    },
            ),
          ],
        );
      },
    );
  }

  void _onAgainWorkoutPressed() {
    // Show "Are you sure you want to do this again?" popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PremiumDialog(
          title: "Start Workout Again?",
          icon: Icons.refresh_rounded,
          iconColor: const Color(0xFF3EA6FF),
          content: const Text(
            "Are you sure you want to start this workout again?",
          ),
          actions: [
            PremiumCancelButton(
              label: "Cancel",
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog and do nothing
              },
            ),
            PremiumConfirmButton(
              label: "Yes",
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _beginWorkoutSession();
              },
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
      if (!_draftHasRequiredInputs(index, draft)) {
        continue;
      }

      final safeDraft = draft!;
      final int reps = int.parse(safeDraft.reps);
      final int sets = int.parse(safeDraft.sets);
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
      if (!_draftHasRequiredInputs(index, draft)) {
        continue;
      }

      final safeDraft = draft!;
      final int reps = int.parse(safeDraft.reps);
      final int sets = int.parse(safeDraft.sets);
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

    final currentCalories = _parseStoredMetric(
      healthData['dailyCalories'] ?? healthData['weeklyCalories'],
    );
    final currentMinutes = _parseStoredMetric(
      healthData['dailyMinutes'] ?? healthData['weeklyMinutes'],
    );
    final currentWorkouts =
        _parseStoredMetric(
          healthData['dailyWorkoutsCount'] ?? healthData['weeklyWorkoutsCount'],
        );
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
          'dailyMinutes': currentMinutes,
          'dailyCalories': currentCalories,
          'dailyWorkoutsCount': currentWorkouts,
        }, SetOptions(merge: true));
      }

      baseCalories = 0;
      baseMinutes = 0;
      baseWorkouts = 0;
    }

    await healthRef.set({
      'dailyCalories': (baseCalories + workoutCalories).clamp(0, 999999),
      'dailyMinutes': (baseMinutes + workoutMinutes).clamp(0, 999999),
      'dailyWorkoutsCount':
          (baseWorkouts + workoutCountChange).clamp(0, 999999),
      'lastDailyResetDate': todayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await healthRef.update({
        'weeklyCalories': FieldValue.delete(),
        'weeklyMinutes': FieldValue.delete(),
        'weeklyWorkoutsCount': FieldValue.delete(),
      });
    } catch (_) {
      // Keep workout completion successful even if legacy key cleanup fails.
    }
  }

  Future<void> _saveExerciseDraftsToFirebase(User user) async {
    for (int index = 0; index < widget.workout.exerciseList.length; index++) {
      final draft = _exerciseDrafts[index];
      final exercise = widget.workout.exerciseList[index];
      if (!_draftHasRequiredInputs(index, draft)) {
        continue;
      }

      final safeDraft = draft!;
      final int weight =
          exercise.requiresWeightInput ? int.parse(safeDraft.weight) : 0;
      final int reps = int.parse(safeDraft.reps);
      final int sets = int.parse(safeDraft.sets);
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
      final primaryGoal = inferPrimaryGoalForWorkout(widget.workout);
      final goalTags = inferGoalTagsForWorkout(widget.workout);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_records')
          .doc(_exerciseRecordDocId(exercise.name))
          .set({
        'exerciseName': exercise.name,
        'workoutId': widget.workout.id,
        'weightUsed': weight.toDouble(),
        'repsPerformed': reps,
        'setsPerformed': sets,
        'timestamp': FieldValue.serverTimestamp(),
        'bodyFocus': widget.workout.bodyFocus,
        'level': widget.workout.level,
        'journeyId': widget.workout.journeyId,
        'journeyName': widget.workout.journeyName,
        'isPartOfJourney': widget.workout.journeyId != null,
        'primaryGoal': primaryGoal,
        'goalTags': goalTags,
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
        // Calculate duration
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

        final int workoutCalories =
            _calculateWorkoutCaloriesFromDrafts() > 0
                ? _calculateWorkoutCaloriesFromDrafts()
                : _calculateFallbackWorkoutCalories();
        final int workoutMinutes =
            _calculateWorkoutMinutesFromDrafts() > 0
                ? _calculateWorkoutMinutesFromDrafts()
                : (expectedDurationSeconds / 60).ceil();
        const int workoutCount = 1;
        final primaryGoal = inferPrimaryGoalForWorkout(widget.workout);
        final goalTags = inferGoalTagsForWorkout(widget.workout);

        await _saveExerciseDraftsToFirebase(user);

        final completionEntry = {
          'title': widget.workout.title,
          'workoutId': widget.workout.id,
          'duration': widget.workout.duration,
          'exercises': widget.workout.exercises,
          'level': widget.workout.level,
          'bodyFocus': widget.workout.bodyFocus,
          'journeyId': widget.workout.journeyId,
          'journeyName': widget.workout.journeyName,
          'journeyOrder': widget.workout.journeyOrder,
          'isPartOfJourney': widget.workout.journeyId != null,
          'primaryGoal': primaryGoal,
          'goalTags': goalTags,
          'completedAt': FieldValue.serverTimestamp(),
          'actualDuration': actualDurationSeconds, // Store actual duration for reference
          'expectedDuration': expectedDurationSeconds, // Store expected duration for reference
          'isCheated': false, // Flag disabled as cheating detection is removed
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

        if (widget.workout.journeyId != null && widget.workout.journeyName != null) {
          await JourneyProgressService.syncJourneyProgressForUser(
            firestore: _firestore,
            uid: user.uid,
            journeyId: widget.workout.journeyId!,
            journeyName: widget.workout.journeyName!,
            isSelected: true,
            markStarted: true,
          );
        }

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

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        setState(() {
          _isSavingWorkoutCompletion = false;
        });
      }
    } catch (e) {
      print('Error saving workout completion: $e');
      if (mounted) {
        setState(() {
          _isSavingWorkoutCompletion = false;
        });
      }
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PremiumDialog(
            title: "Error",
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFFF4B4B),
            content: const Text(
              "There was an error saving your workout progress. Please try again.",
            ),
            actions: [
              PremiumConfirmButton(
                label: "OK",
                gradientColors: const [Color(0xFFFF4B4B), Color(0xFFFF7B7B)],
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
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

        if (widget.workout.journeyId != null && widget.workout.journeyName != null) {
          await JourneyProgressService.syncJourneyProgressForUser(
            firestore: _firestore,
            uid: user.uid,
            journeyId: widget.workout.journeyId!,
            journeyName: widget.workout.journeyName!,
            isSelected: true,
          );
        }

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
              return PremiumDialog(
                title: "Workout Reset",
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF3EA6FF),
                content: const Text(
                  "Workout status has been reset successfully.",
                ),
                actions: [
                  PremiumConfirmButton(
                    label: "OK",
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
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
            return PremiumDialog(
              title: "Error",
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFFF4B4B),
              content: const Text(
                "There was an error resetting your workout progress. Please try again.",
              ),
              actions: [
                PremiumConfirmButton(
                  label: "OK",
                  gradientColors: const [Color(0xFFFF4B4B), Color(0xFFFF7B7B)],
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
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
        return PremiumDialog(
          title: "Reset Workout Status",
          icon: Icons.restart_alt_rounded,
          iconColor: const Color(0xFFFF9800),
          content: Text(
            "Are you sure you want to reset the status for ${widget.workout.title}? This will mark the workout as not completed.",
          ),
          actions: [
            PremiumCancelButton(
              label: "Cancel",
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without resetting
              },
            ),
            PremiumConfirmButton(
              label: "Reset",
              gradientColors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _resetWorkoutCompletion(); // Reset the workout status
              },
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
