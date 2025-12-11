import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import '../data/exercise_data2.dart';

class WorkoutHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get workout history for a specific period
  Future<List<WorkoutHistory>> getWorkoutHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completed_workouts');

      if (startDate != null && endDate != null) {
        query = query
            .where('completedAt', isGreaterThanOrEqualTo: startDate)
            .where('completedAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final history = <WorkoutHistory>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['completedAt'] as Timestamp?;
        
        if (timestamp != null) {
          // Find the corresponding workout from our data
          final workout = exerciseWorkouts.firstWhere(
            (workout) => workout.title == doc.id,
            orElse: () => Workout(
              id: 'unknown',
              title: doc.id,
              duration: data['duration'] ?? 'Unknown',
              exercises: data['exercises'] ?? 'Unknown',
              level: data['level'] ?? 'Unknown',
              bodyFocus: data['bodyFocus'] ?? 'Unknown',
              videoAsset: 'assets/defaultVid.jpg',
              thumbnailAsset: 'assets/abs.png',
              exerciseList: [],
            ),
          );

          history.add(WorkoutHistory(
            id: doc.id,
            workout: workout,
            completedAt: timestamp.toDate(),
            actualDuration: (data['actualDuration'] ?? 0).toInt(),
            expectedDuration: (data['expectedDuration'] ?? 0).toInt(),
            isCheated: (data['isCheated'] ?? false) as bool,
          ));
        }
      }

      // Sort by date, most recent first
      history.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      return history;
    } catch (e) {
      print('Error getting workout history: $e');
      return [];
    }
  }

  // Get exercise history for a specific exercise
 Future<List<ExerciseHistoryRecord>> getExerciseHistory(String exerciseName) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_inputs')
          .where('exerciseName', isEqualTo: exerciseName)
          .orderBy('date', descending: true)
          .get();

      final records = <ExerciseHistoryRecord>[];

      for (final doc in snapshot.docs) {
        final data = doc.data()!;
        final record = ExerciseHistoryRecord(
          exerciseName: data['exerciseName'] ?? exerciseName,
          weightUsed: (data['weight'] ?? 0.0).toDouble(),
          repsPerformed: (data['reps'] ?? 0).toInt(),
          setsPerformed: (data['sets'] ?? 0).toInt(),
          timestamp: (data['date'] as Timestamp?)?.toDate(),
          workoutId: data['workoutId'] ?? '',
        );
        records.add(record);
      }

      return records;
    } catch (e) {
      print('Error getting exercise history: $e');
      return [];
    }
  }

  // Get all exercise names that the user has performed
 Future<List<String>> getAllCompletedExercises() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_inputs')
          .get();

      final Set<String> exerciseNames = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data()!;
        final exerciseName = data['exerciseName'] as String?;
        if (exerciseName != null) {
          exerciseNames.add(exerciseName);
        }
      }

      return exerciseNames.toList();
    } catch (e) {
      print('Error getting completed exercises: $e');
      return [];
    }
 }
}

class WorkoutHistory {
  final String id;
  final Workout workout;
  final DateTime completedAt;
 final int actualDuration; // in seconds
 final int expectedDuration; // in seconds
  final bool isCheated;

  WorkoutHistory({
    required this.id,
    required this.workout,
    required this.completedAt,
    required this.actualDuration,
    required this.expectedDuration,
    required this.isCheated,
  });
}

class ExerciseHistoryRecord {
  final String exerciseName;
  final double weightUsed;
  final int repsPerformed;
  final int setsPerformed;
  final DateTime? timestamp;
  final String workoutId;

  ExerciseHistoryRecord({
    required this.exerciseName,
    required this.weightUsed,
    required this.repsPerformed,
    required this.setsPerformed,
    this.timestamp,
    required this.workoutId,
  });
}
