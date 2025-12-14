import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import '../data/exercise_data2.dart'; // Import the workout data

class ProgressTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 final FirebaseAuth _auth = FirebaseAuth.instance;

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
        final record = ExerciseRecord(
          exerciseName: data['exerciseName'] ?? doc.id,
          weightUsed: (data['weightUsed'] ?? 0.0).toDouble(),
          repsPerformed: (data['repsPerformed'] ?? 0).toInt(),
          setsPerformed: (data['setsPerformed'] ?? 0).toInt(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
          workoutId: data['workoutId'] ?? '',
        );
        records.add(record);
      }
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

  // Get exercise records by category (from workout data)
  Future<List<ExerciseRecord>> getExerciseRecordsByCategory(String category) async {
    final allRecords = await getExerciseRecords();
    
    // If "All" is selected, return all records
    if (category == 'All') return allRecords;
    
    // Filter records based on category by matching workout IDs
    final filteredRecords = <ExerciseRecord>[];
    
    for (final record in allRecords) {
      // Find the workout that contains this exercise
      final workout = exerciseWorkouts.firstWhere(
        (workout) => workout.id == record.workoutId,
        orElse: () => exerciseWorkouts.firstWhere(
          (workout) => workout.exerciseList.any((exercise) => exercise.name == record.exerciseName),
          orElse: () => exerciseWorkouts.first,
        ),
      );
      
      // Check if the workout's bodyFocus matches the category
      if (workout.bodyFocus.toLowerCase().contains(category.toLowerCase()) || 
          category.toLowerCase().contains(workout.bodyFocus.toLowerCase())) {
        filteredRecords.add(record);
      }
    }
    
    return filteredRecords;
  }

  // Get exercise records by difficulty (from workout data)
  Future<List<ExerciseRecord>> getExerciseRecordsByDifficulty(String difficulty) async {
    final allRecords = await getExerciseRecords();
    
    // If "All" is selected, return all records
    if (difficulty == 'All') return allRecords;
    
    // Filter records based on difficulty by matching workout IDs
    final filteredRecords = <ExerciseRecord>[];
    
    for (final record in allRecords) {
      // Find the workout that contains this exercise
      final workout = exerciseWorkouts.firstWhere(
        (workout) => workout.id == record.workoutId,
        orElse: () => exerciseWorkouts.firstWhere(
          (workout) => workout.exerciseList.any((exercise) => exercise.name == record.exerciseName),
          orElse: () => exerciseWorkouts.first,
        ),
      );
      
      // Check if the workout's level matches the difficulty
      if (workout.level.toLowerCase().contains(difficulty.toLowerCase()) || 
          difficulty.toLowerCase().contains(workout.level.toLowerCase())) {
        filteredRecords.add(record);
      }
    }
    
    return filteredRecords;
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
}

class ExerciseRecord {
  final String exerciseName;
  final double weightUsed;
  final int repsPerformed;
  final int setsPerformed;
  final DateTime? timestamp;
  final String workoutId;

  ExerciseRecord({
    required this.exerciseName,
    required this.weightUsed,
    required this.repsPerformed,
    required this.setsPerformed,
    this.timestamp,
    required this.workoutId,
 });
}
