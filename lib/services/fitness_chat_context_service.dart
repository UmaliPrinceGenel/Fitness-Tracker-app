import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'progress_tracking_service.dart';
import 'workout_goal_service.dart';
import 'workout_history_service.dart';

class FitnessChatContext {
  const FitnessChatContext({
    required this.displayName,
    required this.goalLabel,
    required this.summaryLines,
  });

  final String? displayName;
  final String goalLabel;
  final List<String> summaryLines;

  String toPromptBlock() {
    final buffer = StringBuffer();
    buffer.writeln('User context:');
    if (displayName != null && displayName!.trim().isNotEmpty) {
      buffer.writeln('- name: ${displayName!.trim()}');
    }
    buffer.writeln('- primary_goal: $goalLabel');
    for (final line in summaryLines) {
      buffer.writeln('- $line');
    }
    return buffer.toString().trimRight();
  }
}

class FitnessChatContextService {
  FitnessChatContextService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ProgressTrackingService? progressTrackingService,
    WorkoutHistoryService? workoutHistoryService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _progressTrackingService =
           progressTrackingService ?? ProgressTrackingService(),
       _workoutHistoryService =
           workoutHistoryService ?? WorkoutHistoryService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ProgressTrackingService _progressTrackingService;
  final WorkoutHistoryService _workoutHistoryService;

  Future<FitnessChatContext> buildContext() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const FitnessChatContext(
        displayName: null,
        goalLabel: 'General Fitness',
        summaryLines: ['user is not signed in'],
      );
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final goalType = resolvePreferredGoalFromUserData(userData);
    final summaryLines = <String>[];

    final age = _extractAge(userData);
    if (age != null) {
      summaryLines.add('age: $age');
    }

    final heightCm = _extractNumber(userData, 'height');
    if (heightCm != null) {
      summaryLines.add('height_cm: ${_formatNumber(heightCm)}');
    }

    final weightKg = _extractNumber(userData, 'weight');
    if (weightKg != null) {
      summaryLines.add('weight_kg: ${_formatNumber(weightKg)}');
    }

    final bmi = _calculateBmi(heightCm, weightKg);
    if (bmi != null) {
      summaryLines.add('bmi: ${bmi.toStringAsFixed(1)}');
    }

    final longestStreak = await _progressTrackingService.getLongestStreak();
    if (longestStreak > 0) {
      summaryLines.add('longest_streak_days: $longestStreak');
    }

    final highestWeightRecord =
        await _progressTrackingService.getHighestWeightRecord();
    if (highestWeightRecord != null && highestWeightRecord.weightUsed > 0) {
      summaryLines.add(
        'highest_weight_record: ${highestWeightRecord.exerciseName} ${_formatNumber(highestWeightRecord.weightUsed)} kg',
      );
    }

    final recentWorkouts = await _workoutHistoryService.getWorkoutHistory();
    for (final workout in recentWorkouts.take(3)) {
      summaryLines.add(
        'recent_workout: ${workout.workout.title} on ${_formatDate(workout.completedAt)}',
      );
    }

    if (summaryLines.isEmpty) {
      summaryLines.add('limited user history available');
    }

    return FitnessChatContext(
      displayName: _extractDisplayName(userData, user),
      goalLabel: goalLabel(goalType ?? generalFitnessGoal),
      summaryLines: summaryLines,
    );
  }

  String? _extractDisplayName(
    Map<String, dynamic> userData,
    User user,
  ) {
    final profile = userData['profile'];
    final nestedName =
        profile is Map<String, dynamic> ? profile['displayName'] : null;
    final rawName = [
      userData['displayName'],
      nestedName,
      user.displayName,
    ].whereType<String>().map((value) => value.trim()).firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );

    return rawName.isEmpty ? null : rawName;
  }

  int? _extractAge(Map<String, dynamic> userData) {
    final rawBirthdate = _extractRawValue(userData, 'birthdate') ??
        _extractRawValue(userData, 'dateOfBirth');
    if (rawBirthdate == null) {
      return null;
    }

    DateTime? birthDate;
    if (rawBirthdate is Timestamp) {
      birthDate = rawBirthdate.toDate();
    } else if (rawBirthdate is String) {
      birthDate = DateTime.tryParse(rawBirthdate);
    }

    if (birthDate == null) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  double? _extractNumber(Map<String, dynamic> userData, String key) {
    final rawValue = _extractRawValue(userData, key);
    if (rawValue is num) {
      return rawValue.toDouble();
    }
    if (rawValue is String) {
      return double.tryParse(rawValue);
    }
    return null;
  }

  dynamic _extractRawValue(Map<String, dynamic> userData, String key) {
    final profile = userData['profile'];
    if (profile is Map<String, dynamic> && profile.containsKey(key)) {
      return profile[key];
    }
    if (userData.containsKey('profile.$key')) {
      return userData['profile.$key'];
    }
    return userData[key];
  }

  double? _calculateBmi(double? heightCm, double? weightKg) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return null;
    }

    final heightMeters = heightCm / 100;
    final bmi = weightKg / (heightMeters * heightMeters);
    return bmi.isFinite ? bmi : null;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
