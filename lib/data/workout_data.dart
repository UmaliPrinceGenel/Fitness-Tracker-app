import '../models/workout_model.dart';

List<Workout> workouts = [
  // Abs Workouts
  Workout(
    title: "Abs Workout Routine",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Beginner",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/abs_workout.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
  ),
  Workout(
    title: "Core Strength Training",
    duration: "30 min",
    exercises: "15 exercises",
    level: "Intermediate",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/core_strength.mp4", // Placeholder path
    thumbnailAsset: "assets/aabs_workout.mp4",
  ),
  Workout(
    title: "6-Pack Abs Challenge",
    duration: "40 min",
    exercises: "20 exercises",
    level: "Hard",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/six_pack_challenge.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
  ),
  Workout(
    title: "Beginner Core Workout",
    duration: "20 min",
    exercises: "10 exercises",
    level: "Beginner",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/beginner_core.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
  ),
  Workout(
    title: "Advanced Abs Training",
    duration: "35 min",
    exercises: "18 exercises",
    level: "Hard",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/advanced_abs.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
  ),
  
  // Arm Workouts
  Workout(
    title: "Arm Strength Training",
    duration: "30 min",
    exercises: "14 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
  ),
  Workout(
    title: "Bicep and Tricep Blast",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
  ),
  Workout(
    title: "Beginner Arm Workout",
    duration: "20 min",
    exercises: "10 exercises",
    level: "Beginner",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
  ),
  Workout(
    title: "Upper Body Power",
    duration: "35 min",
    exercises: "16 exercises",
    level: "Hard",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
  ),
  Workout(
    title: "Dumbbell Arm Routine",
    duration: "28 min",
    exercises: "13 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
  ),
  
  // Chest Workouts
  Workout(
    title: "Chest Power Training",
    duration: "32 min",
    exercises: "15 exercises",
    level: "Intermediate",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
  ),
  Workout(
    title: "Beginner Chest Workout",
    duration: "22 min",
    exercises: "11 exercises",
    level: "Beginner",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
  ),
  Workout(
    title: "Pectoral Muscle Builder",
    duration: "38 min",
    exercises: "19 exercises",
    level: "Hard",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
  ),
  Workout(
    title: "Push Up Challenge",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Intermediate",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
  ),
  Workout(
    title: "Chest and Shoulders",
    duration: "35 min",
    exercises: "17 exercises",
    level: "Hard",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
  ),
  
  // Leg Workouts
  Workout(
    title: "Leg Day Challenge",
    duration: "40 min",
    exercises: "20 exercises",
    level: "Hard",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
  ),
  Workout(
    title: "Beginner Leg Workout",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Beginner",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
  ),
  Workout(
    title: "Squat and Deadlift",
    duration: "35 min",
    exercises: "16 exercises",
    level: "Intermediate",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
  ),
  Workout(
    title: "Lower Body Burn",
    duration: "30 min",
    exercises: "14 exercises",
    level: "Intermediate",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
  ),
  Workout(
    title: "Quadriceps Focus",
    duration: "32 min",
    exercises: "15 exercises",
    level: "Hard",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
  ),
];
