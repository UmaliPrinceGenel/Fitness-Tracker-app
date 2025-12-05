class Exercise {
  final String name;
  final int caloriesPerMinute; // Average calories burned per minute for this exercise
  final int duration; // Duration in seconds for this specific exercise
  final String description; // Description of the exercise

  Exercise({
    required this.name,
    required this.caloriesPerMinute,
    required this.duration,
    required this.description,
  });

  // Calculate calories burned for this exercise based on duration
  double getCaloriesBurned() {
    double minutes = duration / 60.0;
    return caloriesPerMinute * minutes;
  }
}

class Workout {
  final String title;
  final String duration;
  final String exercises; // This will now indicate the number of exercises
  final String level;
  final String bodyFocus;
  final String videoAsset;
  final String thumbnailAsset;
  final List<Exercise> exerciseList; // List of individual exercises with calorie info

  Workout({
    required this.title,
    required this.duration,
    required this.exercises,
    required this.level,
    required this.bodyFocus,
    required this.videoAsset,
    required this.thumbnailAsset,
    required this.exerciseList, // Add the exercise list parameter
  });
}
