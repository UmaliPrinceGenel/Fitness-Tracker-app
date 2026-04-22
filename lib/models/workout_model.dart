class Exercise {
  final String name;
  final int baseCaloriesPerMinute; // Base calories burned per minute for this exercise without additional factors
  final int duration; // Duration in seconds for this specific exercise
  final String description; // Description of the exercise
  final bool? requiresWeightInputOverride;

  Exercise({
    required this.name,
    required this.baseCaloriesPerMinute,
    required this.duration,
    required this.description,
    this.requiresWeightInputOverride,
  });

  bool get requiresWeightInput {
    if (requiresWeightInputOverride != null) {
      return requiresWeightInputOverride!;
    }

    final normalizedText = '${name.toLowerCase()} ${description.toLowerCase()}';

    const bodyweightKeywords = <String>[
      'bodyweight',
      'without added weight',
      'push-up',
      'push up',
      'pushups',
      'push-ups',
      'pull-up',
      'pull up',
      'pullups',
      'pull-ups',
      'chin-up',
      'chin up',
      'chinups',
      'chin-ups',
      'plank',
      'side plank',
      'hanging leg raise',
      'hanging leg raises',
      'reverse crunch',
      'reverse crunches',
      'glute bridge',
      'glute bridges',
      'ab wheel rollout',
      'ab wheel rollouts',
    ];

    return !bodyweightKeywords.any(normalizedText.contains);
  }

  // Calculate calories burned for this exercise based on duration and additional factors
  double getCaloriesBurned({double weightFactor = 1.0, int sets = 1, int reps = 1}) {
    double minutes = duration / 60.0;
    // Base calculation
    double baseCalories = baseCaloriesPerMinute * minutes;
    
    // Apply factors for weight, sets, and reps
    // Weight factor: increases calorie burn based on weight used (1.0 = bodyweight/no extra weight)
    // Sets and reps: increase calorie burn proportionally to volume
    double volumeFactor = (sets * reps) / 10.0; // Normalize by 10 as a baseline
    if (volumeFactor < 0.5) volumeFactor = 0.5; // Minimum factor to avoid very low values

    return baseCalories * weightFactor * volumeFactor;
  }

  int getEstimatedTotalDurationSeconds({required int sets, required int reps}) {
    final safeSets = sets < 1 ? 1 : sets;
    final safeReps = reps < 1 ? 1 : reps;
    final repFactor = (safeReps / 8.0).clamp(0.5, 2.5);

    return (safeSets * duration * repFactor).round();
  }
}

class Workout {
  final String id;
  final String title;
  final String duration;
  final String exercises; // This will now indicate the number of exercises
  final String level;
  final String bodyFocus;
  final String videoAsset;
  final String thumbnailAsset;
  final String? journeyId;
  final String? journeyName;
  final int? journeyOrder;
  final List<Exercise> exerciseList; // List of individual exercises with calorie info

  Workout({
    required this.id,
    required this.title,
    required this.duration,
    required this.exercises,
    required this.level,
    required this.bodyFocus,
    required this.videoAsset,
    required this.thumbnailAsset,
    this.journeyId,
    this.journeyName,
    this.journeyOrder,
    required this.exerciseList, // Add the exercise list parameter
  });
}
