import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import '../data/exercise_data2.dart'; // Import the workout data
import '../data/fitness_journey_workouts.dart';
import 'workout_goal_service.dart';

class ProgressTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Workout> _knownWorkouts = [
    ...exerciseWorkouts,
    ...fitnessJourneyWorkoutsById.values.expand((workouts) => workouts),
  ];

  // Get user's completed workout dates
  Future<List<DateTime>> getCompletedWorkoutDates() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('doneInfos')
          .get();

      final dates = <DateTime>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['completedAt'] != null && (data['isCheated'] != true)) {
          final timestamp = data['completedAt'] as Timestamp;
          dates.add(timestamp.toDate());
        }
      }
      return dates;
    } catch (e) {
      print('Error getting completed workout dates: $e');
      return [];
    }
  }

  // Get user's exercise records
  Future<List<ExerciseRecord>> getExerciseRecords() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_records')
          .get();

      final records = <ExerciseRecord>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        var record = ExerciseRecord(
          exerciseName: data['exerciseName'] ?? doc.id,
          weightUsed: (data['weightUsed'] ?? 0.0).toDouble(),
          repsPerformed: (data['repsPerformed'] ?? 0).toInt(),
          setsPerformed: (data['setsPerformed'] ?? 0).toInt(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
          workoutId: data['workoutId'] ?? '',
          bodyFocus: (data['bodyFocus'] ?? '').toString(),
          level: (data['level'] ?? '').toString(),
          journeyId: (data['journeyId'] ?? '').toString(),
          journeyName: (data['journeyName'] ?? '').toString(),
          primaryGoal: (data['primaryGoal'] ?? '').toString(),
          goalTags: ((data['goalTags'] as List<dynamic>? ?? const [])
                  .map((goal) => normalizeGoalType(goal.toString()))
                  .toSet()
                  .toList())
              .cast<String>(),
        );
        record = _enrichRecord(record);
        records.add(record);
      }
      records.sort((a, b) {
        final aTime = a.timestamp;
        final bTime = b.timestamp;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });
      return records;
    } catch (e) {
      print('Error getting exercise records: $e');
      return [];
    }
  }

 // Calculate the longest consecutive workout streak
  Future<int> getLongestStreak() async {
    final dates = await getCompletedWorkoutDates();
    if (dates.isEmpty) return 0;

    // Sort dates in descending order (most recent first)
    dates.sort((a, b) => b.compareTo(a));

    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 0; i < dates.length - 1; i++) {
      final current = dates[i];
      final next = dates[i + 1];

      // Calculate the difference in days
      final diff = current.difference(next).inDays;

      if (diff == 1) {
        // Consecutive day
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (diff > 1) {
        // Gap in days, reset streak
        currentStreak = 1;
      }
      // If diff == 0, it means same day, continue without changing streak
    }

    return maxStreak;
  }

  // Get the exercise with the highest weight
  Future<ExerciseRecord?> getHighestWeightRecord() async {
    final records = await getExerciseRecords();
    if (records.isEmpty) return null;

    ExerciseRecord? highestRecord;
    for (final record in records) {
      if (highestRecord == null || record.weightUsed > highestRecord.weightUsed) {
        highestRecord = record;
      }
    }

    return highestRecord;
  }

  Future<String?> getRecommendedGoalType() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return resolvePreferredGoalFromUserData(userDoc.data());
    } catch (e) {
      print('Error getting recommended goal type: $e');
      return null;
    }
  }

  // Get exercise records by category (from workout data)
  Future<List<ExerciseRecord>> getExerciseRecordsByCategory(String category) async {
    final allRecords = await getExerciseRecords();
    
    // If "All" is selected, return all records
    if (category == 'All') return allRecords;
    
    return allRecords
        .where((record) => _matchesCategory(record, category))
        .toList(growable: false);
  }

  // Get exercise records by difficulty (from workout data)
  Future<List<ExerciseRecord>> getExerciseRecordsByDifficulty(String difficulty) async {
    final allRecords = await getExerciseRecords();
    
    // If "All" is selected, return all records
    if (difficulty == 'All') return allRecords;
    
    return allRecords
        .where((record) => _matchesDifficulty(record, difficulty))
        .toList(growable: false);
  }

  Future<List<ExerciseRecord>> getExerciseRecordsByGoal(String goalType) async {
    final allRecords = await getExerciseRecords();

    if (goalType == 'All') {
      return allRecords;
    }

    final normalizedGoal = normalizeGoalType(goalType);
    return allRecords
        .where((record) => _matchesGoal(record, normalizedGoal))
        .toList(growable: false);
  }
  
  // Get all unique exercise names that the user has completed
  Future<List<String>> getCompletedExerciseNames() async {
    final records = await getExerciseRecords();
    final uniqueNames = <String>{};
    
    for (final record in records) {
      uniqueNames.add(record.exerciseName);
    }
    
    return uniqueNames.toList();
  }

  ExerciseRecord _enrichRecord(ExerciseRecord record) {
    final workout = _findWorkoutForRecord(record);
    if (workout == null) {
      final normalizedPrimaryGoal = record.primaryGoal.trim().isNotEmpty
          ? normalizeGoalType(record.primaryGoal)
          : generalFitnessGoal;
      final normalizedGoalTags = record.goalTags.isNotEmpty
          ? record.goalTags.map(normalizeGoalType).toSet().toList()
          : <String>[normalizedPrimaryGoal];

      return record.copyWith(
        primaryGoal: normalizedPrimaryGoal,
        goalTags: normalizedGoalTags,
      );
    }

    final resolvedBodyFocus =
        record.bodyFocus.trim().isNotEmpty ? record.bodyFocus : workout.bodyFocus;
    final resolvedLevel =
        record.level.trim().isNotEmpty ? record.level : workout.level;
    final resolvedJourneyId = record.journeyId.trim().isNotEmpty
        ? record.journeyId
        : (workout.journeyId ?? '');
    final resolvedJourneyName = record.journeyName.trim().isNotEmpty
        ? record.journeyName
        : (workout.journeyName ?? '');
    final resolvedGoalTags = inferGoalTagsForWorkout(workout);
    final resolvedPrimaryGoal = inferPrimaryGoalForWorkout(workout);

    return record.copyWith(
      bodyFocus: resolvedBodyFocus,
      level: resolvedLevel,
      journeyId: resolvedJourneyId,
      journeyName: resolvedJourneyName,
      primaryGoal: resolvedPrimaryGoal,
      goalTags: resolvedGoalTags,
    );
  }

  Workout? _findWorkoutForRecord(ExerciseRecord record) {
    for (final workout in _knownWorkouts) {
      if (workout.id == record.workoutId) {
        return workout;
      }
    }

    for (final workout in _knownWorkouts) {
      final hasExerciseMatch = workout.exerciseList.any(
        (exercise) => exercise.name == record.exerciseName,
      );
      if (hasExerciseMatch) {
        return workout;
      }
    }

    return null;
  }

  bool _matchesCategory(ExerciseRecord record, String category) {
    final normalizedCategory = category.toLowerCase().trim();
    final normalizedFocus = record.bodyFocus.toLowerCase().trim();

    if (normalizedFocus.contains(normalizedCategory) ||
        normalizedCategory.contains(normalizedFocus)) {
      return true;
    }

    if (normalizedCategory == 'arms') {
      return normalizedFocus == 'arm' ||
          normalizedFocus == 'arms' ||
          normalizedFocus == 'triceps' ||
          normalizedFocus == 'biceps' ||
          normalizedFocus == 'forearms';
    }

    if (normalizedCategory == 'abs') {
      return normalizedFocus == 'abs' || normalizedFocus == 'core';
    }

    return false;
  }

  bool _matchesDifficulty(ExerciseRecord record, String difficulty) {
    final normalizedDifficulty = difficulty.toLowerCase().trim();
    final normalizedLevel = record.level.toLowerCase().trim();

    return normalizedLevel.contains(normalizedDifficulty) ||
        normalizedDifficulty.contains(normalizedLevel);
  }

  bool _matchesGoal(ExerciseRecord record, String goalType) {
    if (record.primaryGoal.trim().isNotEmpty &&
        normalizeGoalType(record.primaryGoal) == goalType) {
      return true;
    }

    return record.goalTags.map(normalizeGoalType).contains(goalType);
  }
}

class ExerciseRecord {
  final String exerciseName;
  final double weightUsed;
  final int repsPerformed;
  final int setsPerformed;
  final DateTime? timestamp;
  final String workoutId;
  final String bodyFocus;
  final String level;
  final String journeyId;
  final String journeyName;
  final String primaryGoal;
  final List<String> goalTags;

  ExerciseRecord({
    required this.exerciseName,
    required this.weightUsed,
    required this.repsPerformed,
    required this.setsPerformed,
    this.timestamp,
    required this.workoutId,
    this.bodyFocus = '',
    this.level = '',
    this.journeyId = '',
    this.journeyName = '',
    this.primaryGoal = '',
    this.goalTags = const [],
 });

  ExerciseRecord copyWith({
    String? exerciseName,
    double? weightUsed,
    int? repsPerformed,
    int? setsPerformed,
    DateTime? timestamp,
    String? workoutId,
    String? bodyFocus,
    String? level,
    String? journeyId,
    String? journeyName,
    String? primaryGoal,
    List<String>? goalTags,
  }) {
    return ExerciseRecord(
      exerciseName: exerciseName ?? this.exerciseName,
      weightUsed: weightUsed ?? this.weightUsed,
      repsPerformed: repsPerformed ?? this.repsPerformed,
      setsPerformed: setsPerformed ?? this.setsPerformed,
      timestamp: timestamp ?? this.timestamp,
      workoutId: workoutId ?? this.workoutId,
      bodyFocus: bodyFocus ?? this.bodyFocus,
      level: level ?? this.level,
      journeyId: journeyId ?? this.journeyId,
      journeyName: journeyName ?? this.journeyName,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      goalTags: goalTags ?? this.goalTags,
    );
  }
}
