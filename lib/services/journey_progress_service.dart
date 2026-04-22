import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/fitness_journey_workouts.dart';
import 'workout_goal_service.dart';

class JourneyProgressSnapshot {
  final int completedWorkoutsCount;
  final int cheatedWorkoutsCount;
  final int cleanWorkoutsCount;
  final int totalWorkoutsCount;
  final int completionCount;
  final int repeatCompletionCount;
  final double progressRatio;
  final double progressPercent;
  final String status;
  final bool hasStarted;
  final bool isCompleted;
  final DateTime? startedAt;
  final String? nextWorkoutId;

  const JourneyProgressSnapshot({
    required this.completedWorkoutsCount,
    required this.cheatedWorkoutsCount,
    required this.cleanWorkoutsCount,
    required this.totalWorkoutsCount,
    required this.completionCount,
    required this.repeatCompletionCount,
    required this.progressRatio,
    required this.progressPercent,
    required this.status,
    required this.hasStarted,
    required this.isCompleted,
    required this.startedAt,
    required this.nextWorkoutId,
  });
}

class JourneyProgressService {
  static String? _resolveJourneyWorkoutKey({
    required Map<String, dynamic> data,
    required Set<String> journeyWorkoutIds,
    required Map<String, String> workoutIdByTitle,
  }) {
    final workoutId = data['workoutId'] as String?;
    if (workoutId != null && journeyWorkoutIds.contains(workoutId)) {
      return workoutId;
    }

    final title = data['title'] as String?;
    if (title != null) {
      return workoutIdByTitle[title];
    }

    return null;
  }

  static Future<JourneyProgressSnapshot> syncJourneyProgressForUser({
    required FirebaseFirestore firestore,
    required String uid,
    required String journeyId,
    required String journeyName,
    bool isSelected = true,
    bool markStarted = false,
    DateTime? startedAtOverride,
  }) async {
    final journeyWorkouts = getJourneyWorkouts(journeyId);
    final journeyWorkoutIds = journeyWorkouts
        .map((workout) => workout.id)
        .toSet();
    final workoutIdByTitle = {
      for (final workout in journeyWorkouts) workout.title: workout.id,
    };
    final totalWorkoutsCount = journeyWorkouts.length;

    final progressDocRef = firestore
        .collection('users')
        .doc(uid)
        .collection('journey_progress')
        .doc(journeyId);
    final progressDoc = await progressDocRef.get();
    final progressData = progressDoc.data();

    DateTime? storedStartedAt;
    final startedAtValue = progressData?['startedAt'];
    if (startedAtValue is Timestamp) {
      storedStartedAt = startedAtValue.toDate();
    }

    DateTime? storedActiveCycleStartedAt;
    final activeCycleStartedAtValue = progressData?['activeCycleStartedAt'];
    if (activeCycleStartedAtValue is Timestamp) {
      storedActiveCycleStartedAt = activeCycleStartedAtValue.toDate();
    }

    final previousStatus = (progressData?['status'] ?? 'not_started').toString();
    final restartingCompletedJourney =
        markStarted && previousStatus == 'completed';

    int completionCount =
        (progressData?['completionCount'] as num?)?.toInt() ??
            (previousStatus == 'completed' ? 1 : 0);

    DateTime? activeCycleStartedAt = storedActiveCycleStartedAt ?? storedStartedAt;
    if (restartingCompletedJourney) {
      activeCycleStartedAt = DateTime.now();
    } else if (markStarted && activeCycleStartedAt == null) {
      activeCycleStartedAt = startedAtOverride ?? DateTime.now();
    }

    final completedSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('completed_workouts')
        .get();
    final doneInfosSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('doneInfos')
        .get();

    final completedWorkoutKeys = <String>{};
    final cheatedWorkoutKeys = <String>{};
    final cleanWorkoutKeys = <String>{};

    void recordCompletion(Map<String, dynamic> data) {
      final completedAt = data['completedAt'];
      if (completedAt is! Timestamp) {
        return;
      }

      if (activeCycleStartedAt != null &&
          completedAt.toDate().isBefore(activeCycleStartedAt)) {
        return;
      }

      final workoutKey = _resolveJourneyWorkoutKey(
        data: data,
        journeyWorkoutIds: journeyWorkoutIds,
        workoutIdByTitle: workoutIdByTitle,
      );
      if (workoutKey == null) {
        return;
      }

      completedWorkoutKeys.add(workoutKey);

      if (data['isCheated'] == true) {
        cheatedWorkoutKeys.add(workoutKey);
      } else {
        cleanWorkoutKeys.add(workoutKey);
      }
    }

    for (final doc in completedSnapshot.docs) {
      recordCompletion(doc.data());
    }
    for (final doc in doneInfosSnapshot.docs) {
      recordCompletion(doc.data());
    }

    final completedWorkoutsCount = completedWorkoutKeys.length;
    final cheatedWorkoutsCount = cheatedWorkoutKeys.length;
    final cleanWorkoutsCount = cleanWorkoutKeys.length;

    final hasStarted = markStarted ||
        completedWorkoutsCount > 0 ||
        progressData?['status'] == 'in_progress' ||
        progressData?['status'] == 'completed';
    final isCompleted =
        totalWorkoutsCount > 0 && completedWorkoutsCount >= totalWorkoutsCount;
    if (isCompleted && (!restartingCompletedJourney && previousStatus != 'completed')) {
      completionCount++;
    }

    final resolvedStartedAt = startedAtOverride ??
        activeCycleStartedAt ??
        storedStartedAt ??
        (hasStarted ? DateTime.now() : null);
    final progressRatio = totalWorkoutsCount == 0
        ? 0.0
        : (completedWorkoutsCount / totalWorkoutsCount).clamp(0.0, 1.0);
    final progressPercent =
        double.parse((progressRatio * 100).toStringAsFixed(1));
    final status = isCompleted
        ? 'completed'
        : (hasStarted ? 'in_progress' : 'not_started');

    String? nextWorkoutId;
    for (final workout in journeyWorkouts) {
      if (!completedWorkoutKeys.contains(workout.id)) {
        nextWorkoutId = workout.id;
        break;
      }
    }

    final progressPayload = <String, dynamic>{
      'journeyId': journeyId,
      'journeyName': journeyName,
      'isSelected': isSelected,
      'isCompleted': isCompleted,
      'completedWorkoutsCount': completedWorkoutsCount,
      'cheatedWorkoutsCount': cheatedWorkoutsCount,
      'cleanWorkoutsCount': cleanWorkoutsCount,
      'totalWorkoutsCount': totalWorkoutsCount,
      'completionCount': completionCount,
      'repeatCompletionCount': completionCount > 0 ? completionCount - 1 : 0,
      'progressPercent': progressPercent,
      'status': status,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (resolvedStartedAt != null) {
      progressPayload['startedAt'] = Timestamp.fromDate(resolvedStartedAt);
      progressPayload['activeCycleStartedAt'] =
          Timestamp.fromDate(resolvedStartedAt);
    } else {
      progressPayload['startedAt'] = FieldValue.delete();
      progressPayload['activeCycleStartedAt'] = FieldValue.delete();
    }
    if (isCompleted) {
      progressPayload['completedAt'] = FieldValue.serverTimestamp();
    } else {
      progressPayload['completedAt'] = FieldValue.delete();
    }

    await progressDocRef.set(progressPayload, SetOptions(merge: true));

    if (isSelected) {
      final otherJourneyDocs = await firestore
          .collection('users')
          .doc(uid)
          .collection('journey_progress')
          .get();

      if (otherJourneyDocs.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in otherJourneyDocs.docs) {
          if (doc.id == journeyId) {
            continue;
          }
          batch.set(
            doc.reference,
            {
              'isSelected': false,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }

      final userPayload = <String, dynamic>{
        'selectedJourney': journeyName,
        'selectedJourneyId': journeyId,
        'selectedJourneyName': journeyName,
        'selectedGoalType': goalForJourneyId(journeyId),
        'selectedGoalLabel': goalLabel(goalForJourneyId(journeyId)),
        'journeyStatus': status,
        'journeyProgressPercent': progressPercent,
        'journeyCompletionCount': completionCount,
        'nextWorkoutId': isCompleted ? null : nextWorkoutId,
        'journeyUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (resolvedStartedAt != null) {
        userPayload['journeyStartedAt'] = Timestamp.fromDate(resolvedStartedAt);
      } else {
        userPayload['journeyStartedAt'] = FieldValue.delete();
      }

      await firestore
          .collection('users')
          .doc(uid)
          .set(userPayload, SetOptions(merge: true));
    }

    return JourneyProgressSnapshot(
      completedWorkoutsCount: completedWorkoutsCount,
      cheatedWorkoutsCount: cheatedWorkoutsCount,
      cleanWorkoutsCount: cleanWorkoutsCount,
      totalWorkoutsCount: totalWorkoutsCount,
      completionCount: completionCount,
      repeatCompletionCount: completionCount > 0 ? completionCount - 1 : 0,
      progressRatio: progressRatio,
      progressPercent: progressPercent,
      status: status,
      hasStarted: hasStarted,
      isCompleted: isCompleted,
      startedAt: resolvedStartedAt,
      nextWorkoutId: nextWorkoutId,
    );
  }
}
