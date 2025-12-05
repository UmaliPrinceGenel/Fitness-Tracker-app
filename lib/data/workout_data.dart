import '../models/workout_model.dart';

List<Workout> workouts = [
  // Abs Workouts
  Workout(
    id: "abs_001",
    title: "Abs Workout Routine",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Beginner",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/abs_workout.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
    exerciseList: [
      Exercise(
        name: "Crunches",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Classic abdominal crunch to target your abs",
      ),
      Exercise(
        name: "Plank",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Hold a plank position to strengthen your core",
      ),
      Exercise(
        name: "Bicycle Crunches",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Dynamic exercise that works your entire core",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Lie on your back and raise your legs to work lower abs",
      ),
      Exercise(
        name: "Russian Twists",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Seated twist to work obliques and core",
      ),
      Exercise(
        name: "Mountain Climbers",
        caloriesPerMinute: 10,
        duration: 60, // 1 minute
        description: "Fast-paced exercise that works your entire core",
      ),
      Exercise(
        name: "Dead Bug",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Core stability exercise that targets deep abs",
      ),
      Exercise(
        name: "Flutter Kicks",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Lying exercise to work lower abs and hip flexors",
      ),
      Exercise(
        name: "Hollow Body Hold",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Hold the hollow position to strengthen core",
      ),
      Exercise(
        name: "Toe Touches",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Sit and reach for your toes to work upper abs",
      ),
      Exercise(
        name: "Scissor Kicks",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Lying exercise alternating leg lifts",
      ),
      Exercise(
        name: "Tabletop Dead Bug",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Beginner-friendly core stability exercise",
      ),
    ],
  ),
  Workout(
    id: "abs_002",
    title: "Core Strength Training",
    duration: "30 min",
    exercises: "15 exercises",
    level: "Intermediate",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/core_strength.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
    exerciseList: [
      Exercise(
        name: "Plank",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Hold a plank position to strengthen your core",
      ),
      Exercise(
        name: "Side Plank Left",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Plank on your left side to work obliques",
      ),
      Exercise(
        name: "Side Plank Right",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Plank on your right side to work obliques",
      ),
      Exercise(
        name: "Dead Bug Left",
        caloriesPerMinute: 4,
        duration: 60, // 1 minute
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Dead Bug Right",
        caloriesPerMinute: 4,
        duration: 60, // 1 minute
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Hollow Body Rock",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Rock back and forth in hollow position for core strength",
      ),
      Exercise(
        name: "V-Ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Dynamic movement working entire core",
      ),
      Exercise(
        name: "Bicycle Crunches",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Dynamic exercise that works your entire core",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Lie on your back and raise your legs to work lower abs",
      ),
      Exercise(
        name: "Reverse Crunches",
        caloriesPerMinute: 6,
        duration: 90, // 1.5 minutes
        description: "Lift hips off ground to work lower abs",
      ),
      Exercise(
        name: "Russian Twists",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Seated twist to work obliques and core",
      ),
      Exercise(
        name: "Mountain Climbers",
        caloriesPerMinute: 10,
        duration: 90, // 1.5 minutes
        description: "Fast-paced exercise that works your entire core",
      ),
      Exercise(
        name: "Flutter Kicks",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Lying exercise to work lower abs and hip flexors",
      ),
      Exercise(
        name: "Plank Up-Downs",
        caloriesPerMinute: 8,
        duration: 90, // 1.5 minutes
        description: "Plank with alternating arm raises to increase intensity",
      ),
      Exercise(
        name: "Hanging Knee Raises",
        caloriesPerMinute: 7,
        duration: 60, // 1 minute
        description: "If equipment available, raise knees while hanging",
      ),
    ],
  ),
  Workout(
    id: "abs_003",
    title: "6-Pack Abs Challenge",
    duration: "40 min",
    exercises: "20 exercises",
    level: "Hard",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/six_pack_challenge.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
    exerciseList: [
      Exercise(
        name: "Plank",
        caloriesPerMinute: 4,
        duration: 180, // 3 minutes
        description: "Hold a plank position to strengthen your core",
      ),
      Exercise(
        name: "Side Plank Left",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Plank on your left side to work obliques",
      ),
      Exercise(
        name: "Side Plank Right",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Plank on your right side to work obliques",
      ),
      Exercise(
        name: "Dead Bug Left",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Dead Bug Right",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Hollow Body Hold",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Hold the hollow position to strengthen core",
      ),
      Exercise(
        name: "V-Ups",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Dynamic movement working entire core",
      ),
      Exercise(
        name: "Bicycle Crunches",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Dynamic exercise that works your entire core",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lie on your back and raise your legs to work lower abs",
      ),
      Exercise(
        name: "Reverse Crunches",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Lift hips off ground to work lower abs",
      ),
      Exercise(
        name: "Russian Twists",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Seated twist to work obliques and core",
      ),
      Exercise(
        name: "Mountain Climbers",
        caloriesPerMinute: 10,
        duration: 150, // 2.5 minutes
        description: "Fast-paced exercise that works your entire core",
      ),
      Exercise(
        name: "Flutter Kicks",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lying exercise to work lower abs and hip flexors",
      ),
      Exercise(
        name: "Plank Up-Downs",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Plank with alternating arm raises to increase intensity",
      ),
      Exercise(
        name: "Hanging Knee Raises",
        caloriesPerMinute: 7,
        duration: 90, // 1.5 minutes
        description: "If equipment available, raise knees while hanging",
      ),
      Exercise(
        name: "Hanging Leg Raises",
        caloriesPerMinute: 8,
        duration: 90, // 1.5 minutes
        description: "If equipment available, raise legs while hanging",
      ),
      Exercise(
        name: "Ab Rollouts",
        caloriesPerMinute: 6,
        duration: 90, // 1.5 minutes
        description: "Use ab wheel or stability ball to work core",
      ),
      Exercise(
        name: "Cable Wood Chops",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Rotational movement to work obliques and core",
      ),
      Exercise(
        name: "Medicine Ball Slams",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Explosive movement to work entire core",
      ),
      Exercise(
        name: "Turkish Get-ups",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Complex movement working stability and strength",
      ),
    ],
  ),
  Workout(
    id: "abs_004",
    title: "Beginner Core Workout",
    duration: "20 min",
    exercises: "10 exercises",
    level: "Beginner",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/beginner_core.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
    exerciseList: [
      Exercise(
        name: "Modified Plank",
        caloriesPerMinute: 3,
        duration: 60, // 1 minute
        description: "Plank on knees to reduce difficulty",
      ),
      Exercise(
        name: "Basic Crunches",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Classic abdominal crunch to target your abs",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Lie on your back and raise your legs to work lower abs",
      ),
      Exercise(
        name: "Dead Bug",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Core stability exercise that targets deep abs",
      ),
      Exercise(
        name: "Modified Side Plank",
        caloriesPerMinute: 4,
        duration: 45, // 45 seconds each side
        description: "Side plank on knees to reduce difficulty",
      ),
      Exercise(
        name: "Hollow Body Hold",
        caloriesPerMinute: 4,
        duration: 60, // 1 minute
        description: "Hold the hollow position to strengthen core",
      ),
      Exercise(
        name: "Toe Touches",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Sit and reach for your toes to work upper abs",
      ),
      Exercise(
        name: "Flutter Kicks",
        caloriesPerMinute: 5,
        duration: 60, // 1 minute
        description: "Lying exercise to work lower abs and hip flexors",
      ),
      Exercise(
        name: "Modified Bicycle Crunches",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Slower bicycle crunches for beginners",
      ),
      Exercise(
        name: "Tabletop Dead Bug",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Beginner-friendly core stability exercise",
      ),
    ],
  ),
  Workout(
    id: "abs_005",
    title: "Advanced Abs Training",
    duration: "35 min",
    exercises: "18 exercises",
    level: "Hard",
    bodyFocus: "Abs",
    videoAsset: "assets/videos/advanced_abs.mp4", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4",
    exerciseList: [
      Exercise(
        name: "Plank",
        caloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Hold a plank position to strengthen your core",
      ),
      Exercise(
        name: "Side Plank Left",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Plank on your left side to work obliques",
      ),
      Exercise(
        name: "Side Plank Right",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Plank on your right side to work obliques",
      ),
      Exercise(
        name: "Dead Bug Left",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Dead Bug Right",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Core stability exercise for deep abs",
      ),
      Exercise(
        name: "Hollow Body Hold",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Hold the hollow position to strengthen core",
      ),
      Exercise(
        name: "V-Ups",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Dynamic movement working entire core",
      ),
      Exercise(
        name: "Bicycle Crunches",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Dynamic exercise that works your entire core",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lie on your back and raise your legs to work lower abs",
      ),
      Exercise(
        name: "Reverse Crunches",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Lift hips off ground to work lower abs",
      ),
      Exercise(
        name: "Russian Twists",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Seated twist to work obliques and core",
      ),
      Exercise(
        name: "Mountain Climbers",
        caloriesPerMinute: 10,
        duration: 150, // 2.5 minutes
        description: "Fast-paced exercise that works your entire core",
      ),
      Exercise(
        name: "Flutter Kicks",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lying exercise to work lower abs and hip flexors",
      ),
      Exercise(
        name: "Plank Up-Downs",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Plank with alternating arm raises to increase intensity",
      ),
      Exercise(
        name: "Hanging Knee Raises",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "If equipment available, raise knees while hanging",
      ),
      Exercise(
        name: "Hanging Leg Raises",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "If equipment available, raise legs while hanging",
      ),
      Exercise(
        name: "Ab Rollouts",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Use ab wheel or stability ball to work core",
      ),
      Exercise(
        name: "Medicine Ball Slams",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Explosive movement to work entire core",
      ),
    ],
  ),
  
  // Arm Workouts
  Workout(
    id: "arm_001",
    title: "Arm Strength Training",
    duration: "30 min",
    exercises: "14 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
    exerciseList: [
      Exercise(
        name: "Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Classic exercise to work chest, shoulders and triceps",
      ),
      Exercise(
        name: "Bicep Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps with dumbbells or resistance bands",
      ),
      Exercise(
        name: "Tricep Dips",
        caloriesPerMinute: 6,
        duration: 90, // 1.5 minutes
        description: "Target triceps using bench or chair",
      ),
      Exercise(
        name: "Shoulder Press",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Press weights overhead to work shoulders and arms",
      ),
      Exercise(
        name: "Hammer Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps and forearms with neutral grip",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Extend arms overhead to work triceps",
      ),
      Exercise(
        name: "Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the side to work shoulders",
      ),
      Exercise(
        name: "Front Raises",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Raise arms to the front to work shoulders",
      ),
      Exercise(
        name: "Reverse Flyes",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work rear deltoids and upper back",
      ),
      Exercise(
        name: "Close-Grip Push-ups",
        caloriesPerMinute: 8,
        duration: 90, // 1.5 minutes
        description: "Push-ups with hands close together to target triceps",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Tricep Kickbacks",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Extend arms back to work triceps",
      ),
      Exercise(
        name: "Concentration Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Isolate biceps with single arm curls",
      ),
      Exercise(
        name: "Plank to Push-up",
        caloriesPerMinute: 9,
        duration: 90, // 1.5 minutes
        description: "Dynamic movement combining plank and push-up",
      ),
    ],
  ),
  Workout(
    id: "arm_002",
    title: "Bicep and Tricep Blast",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
    exerciseList: [
      Exercise(
        name: "Bicep Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps with dumbbells or resistance bands",
      ),
      Exercise(
        name: "Hammer Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps and forearms with neutral grip",
      ),
      Exercise(
        name: "Concentration Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Isolate biceps with single arm curls",
      ),
      Exercise(
        name: "Cable Bicep Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Use cable machine for constant tension",
      ),
      Exercise(
        name: "Tricep Dips",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Target triceps using bench or chair",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Extend arms overhead to work triceps",
      ),
      Exercise(
        name: "Tricep Kickbacks",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Extend arms back to work triceps",
      ),
      Exercise(
        name: "Close-Grip Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with hands close together to target triceps",
      ),
      Exercise(
        name: "Skull Crushers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lying tricep extension exercise",
      ),
      Exercise(
        name: "Bicep Hammer Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps and forearms with neutral grip",
      ),
      Exercise(
        name: "Cable Tricep Pushdowns",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Use cable machine to work triceps",
      ),
      Exercise(
        name: "Chin-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Pull-up with underhand grip to work biceps and back",
      ),
    ],
  ),
  Workout(
    id: "arm_003",
    title: "Beginner Arm Workout",
    duration: "20 min",
    exercises: "10 exercises",
    level: "Beginner",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
    exerciseList: [
      Exercise(
        name: "Wall Push-ups",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Beginner-friendly push-up against wall",
      ),
      Exercise(
        name: "Seated Bicep Curls",
        caloriesPerMinute: 3,
        duration: 120, // 2 minutes
        description: "Work biceps while seated for stability",
      ),
      Exercise(
        name: "Seated Shoulder Press",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Press weights overhead while seated",
      ),
      Exercise(
        name: "Assisted Tricep Dips",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Use bench with feet on ground for support",
      ),
      Exercise(
        name: "Arm Circles",
        caloriesPerMinute: 3,
        duration: 120, // 2 minutes
        description: "Circular motion to warm up and work shoulders",
      ),
      Exercise(
        name: "Isometric Bicep Hold",
        caloriesPerMinute: 3,
        duration: 60, // 1 minute
        description: "Hold bicep curl position to build endurance",
      ),
      Exercise(
        name: "Isometric Tricep Hold",
        caloriesPerMinute: 3,
        duration: 60, // 1 minute
        description: "Hold arms extended to work triceps",
      ),
      Exercise(
        name: "Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the side to work shoulders",
      ),
      Exercise(
        name: "Front Raises",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Raise arms to the front to work shoulders",
      ),
      Exercise(
        name: "Modified Push-ups",
        caloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Push-ups on knees for beginners",
      ),
    ],
  ),
  Workout(
    id: "arm_004",
    title: "Upper Body Power",
    duration: "35 min",
    exercises: "16 exercises",
    level: "Hard",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
    exerciseList: [
      Exercise(
        name: "Pull-ups",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Upper body compound movement for back and arms",
      ),
      Exercise(
        name: "Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Bodyweight exercise for triceps and chest",
      ),
      Exercise(
        name: "Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Classic exercise to work chest, shoulders and triceps",
      ),
      Exercise(
        name: "Bicep Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps with dumbbells or resistance bands",
      ),
      Exercise(
        name: "Tricep Dips",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Target triceps using bench or chair",
      ),
      Exercise(
        name: "Shoulder Press",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Press weights overhead to work shoulders and arms",
      ),
      Exercise(
        name: "Hammer Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps and forearms with neutral grip",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Extend arms overhead to work triceps",
      ),
      Exercise(
        name: "Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the side to work shoulders",
      ),
      Exercise(
        name: "Front Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the front to work shoulders",
      ),
      Exercise(
        name: "Reverse Flyes",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work rear deltoids and upper back",
      ),
      Exercise(
        name: "Close-Grip Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with hands close together to target triceps",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Tricep Kickbacks",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Extend arms back to work triceps",
      ),
      Exercise(
        name: "Concentration Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Isolate biceps with single arm curls",
      ),
      Exercise(
        name: "Plank to Push-up",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Dynamic movement combining plank and push-up",
      ),
    ],
  ),
  Workout(
    id: "arm_005",
    title: "Dumbbell Arm Routine",
    duration: "28 min",
    exercises: "13 exercises",
    level: "Intermediate",
    bodyFocus: "Arm",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual arm asset
    exerciseList: [
      Exercise(
        name: "Bicep Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps with dumbbells or resistance bands",
      ),
      Exercise(
        name: "Hammer Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work biceps and forearms with neutral grip",
      ),
      Exercise(
        name: "Preacher Curls",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Isolate biceps with preacher bench",
      ),
      Exercise(
        name: "Tricep Dips",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Target triceps using bench or chair",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Extend arms overhead to work triceps",
      ),
      Exercise(
        name: "Tricep Kickbacks",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Extend arms back to work triceps",
      ),
      Exercise(
        name: "Shoulder Press",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Press weights overhead to work shoulders and arms",
      ),
      Exercise(
        name: "Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the side to work shoulders",
      ),
      Exercise(
        name: "Front Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the front to work shoulders",
      ),
      Exercise(
        name: "Reverse Flyes",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work rear deltoids and upper back",
      ),
      Exercise(
        name: "Curls to Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Combine bicep curls with shoulder press",
      ),
      Exercise(
        name: "Skull Crushers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Lying tricep extension exercise",
      ),
      Exercise(
        name: "Dumbbell Rows",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Work back and biceps with rowing motion",
      ),
    ],
  ),
  
  // Chest Workouts
  Workout(
    id: "chest_001",
    title: "Chest Power Training",
    duration: "32 min",
    exercises: "15 exercises",
    level: "Intermediate",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
    exerciseList: [
      Exercise(
        name: "Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Classic exercise to work chest, shoulders and triceps",
      ),
      Exercise(
        name: "Chest Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press weights to work chest muscles",
      ),
      Exercise(
        name: "Incline Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press at incline angle to work upper chest",
      ),
      Exercise(
        name: "Decline Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press at decline angle to work lower chest",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Pec Deck",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Machine exercise to work chest muscles",
      ),
      Exercise(
        name: "Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Bodyweight exercise for chest and triceps",
      ),
      Exercise(
        name: "Dumbbell Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion with dumbbells to work chest",
      ),
      Exercise(
        name: "Incline Dumbbell Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion at incline to work upper chest",
      ),
      Exercise(
        name: "Push-up to Side Plank",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Dynamic movement combining push-up and core work",
      ),
      Exercise(
        name: "Wide Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Push-ups with wider hand placement for chest focus",
      ),
      Exercise(
        name: "Diamond Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with hands in diamond shape for tricep focus",
      ),
      Exercise(
        name: "Chest Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Dips focused on chest muscles",
      ),
      Exercise(
        name: "Plyometric Push-ups",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Explosive push-ups for power development",
      ),
      Exercise(
        name: "Single Arm Push-ups",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Advanced push-up for strength and stability",
      ),
    ],
  ),
  Workout(
    id: "chest_002",
    title: "Beginner Chest Workout",
    duration: "22 min",
    exercises: "11 exercises",
    level: "Beginner",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
    exerciseList: [
      Exercise(
        name: "Wall Push-ups",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Beginner-friendly push-up against wall",
      ),
      Exercise(
        name: "Knee Push-ups",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Push-ups on knees to reduce difficulty",
      ),
      Exercise(
        name: "Chest Press Machine",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Machine exercise to work chest muscles safely",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Seated Dumbbell Press",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Press weights while seated for stability",
      ),
      Exercise(
        name: "Incline Dumbbell Press",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Press at incline angle to work upper chest",
      ),
      Exercise(
        name: "Chest Stretch",
        caloriesPerMinute: 2,
        duration: 60, // 1 minute
        description: "Static stretch for chest muscles",
      ),
      Exercise(
        name: "Arm Circles",
        caloriesPerMinute: 3,
        duration: 120, // 2 minutes
        description: "Circular motion to warm up chest and shoulders",
      ),
      Exercise(
        name: "Modified Dips",
        caloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Dips using bench for support",
      ),
      Exercise(
        name: "Pec Deck Machine",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Machine exercise to work chest muscles",
      ),
      Exercise(
        name: "Chest Foam Rolling",
        caloriesPerMinute: 2,
        duration: 60, // 1 minute
        description: "Self-massage technique for chest muscles",
      ),
    ],
  ),
  Workout(
    id: "chest_003",
    title: "Pectoral Muscle Builder",
    duration: "38 min",
    exercises: "19 exercises",
    level: "Hard",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
    exerciseList: [
      Exercise(
        name: "Weighted Push-ups",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Push-ups with added weight for increased difficulty",
      ),
      Exercise(
        name: "Chest Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press weights to work chest muscles",
      ),
      Exercise(
        name: "Incline Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press at incline angle to work upper chest",
      ),
      Exercise(
        name: "Decline Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press at decline angle to work lower chest",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Pec Deck",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Machine exercise to work chest muscles",
      ),
      Exercise(
        name: "Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Bodyweight exercise for chest and triceps",
      ),
      Exercise(
        name: "Dumbbell Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion with dumbbells to work chest",
      ),
      Exercise(
        name: "Incline Dumbbell Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion at incline to work upper chest",
      ),
      Exercise(
        name: "Decline Dumbbell Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion at decline to work lower chest",
      ),
      Exercise(
        name: "Push-up to Side Plank",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Dynamic movement combining push-up and core work",
      ),
      Exercise(
        name: "Wide Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Push-ups with wider hand placement for chest focus",
      ),
      Exercise(
        name: "Diamond Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with hands in diamond shape for tricep focus",
      ),
      Exercise(
        name: "Chest Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Dips focused on chest muscles",
      ),
      Exercise(
        name: "Plyometric Push-ups",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Explosive push-ups for power development",
      ),
      Exercise(
        name: "Single Arm Push-ups",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Advanced push-up for strength and stability",
      ),
      Exercise(
        name: "Weighted Dips",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Dips with added weight for increased difficulty",
      ),
      Exercise(
        name: "Chest Press with Pause",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Chest press with pause at bottom for increased time under tension",
      ),
      Exercise(
        name: "JM Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Hybrid exercise combining chest press and skull crusher",
      ),
    ],
  ),
  Workout(
    id: "chest_004",
    title: "Push Up Challenge",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Intermediate",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
    exerciseList: [
      Exercise(
        name: "Standard Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Classic push-up position",
      ),
      Exercise(
        name: "Wide Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Push-ups with wider hand placement for chest focus",
      ),
      Exercise(
        name: "Diamond Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with hands in diamond shape for tricep focus",
      ),
      Exercise(
        name: "Plyometric Push-ups",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Explosive push-ups for power development",
      ),
      Exercise(
        name: "Incline Push-ups",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Push-ups with hands elevated to reduce difficulty",
      ),
      Exercise(
        name: "Decline Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with feet elevated to increase difficulty",
      ),
      Exercise(
        name: "Spiderman Push-ups",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Push-up with knee to elbow for core engagement",
      ),
      Exercise(
        name: "T-Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-up with rotation to side plank position",
      ),
      Exercise(
        name: "Archer Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-up with one arm extended to the side",
      ),
      Exercise(
        name: "One Arm Push-ups",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Advanced push-up on one arm",
      ),
      Exercise(
        name: "Push-up Plus",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Push-up with extra range of motion",
      ),
      Exercise(
        name: "Kneeling Push-ups",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Push-ups on knees for reduced difficulty",
      ),
    ],
  ),
  Workout(
    id: "chest_005",
    title: "Chest and Shoulders",
    duration: "35 min",
    exercises: "17 exercises",
    level: "Hard",
    bodyFocus: "Chest",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual chest asset
    exerciseList: [
      Exercise(
        name: "Chest Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press weights to work chest muscles",
      ),
      Exercise(
        name: "Shoulder Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Press weights overhead to work shoulders and arms",
      ),
      Exercise(
        name: "Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the side to work shoulders",
      ),
      Exercise(
        name: "Front Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Raise arms to the front to work shoulders",
      ),
      Exercise(
        name: "Reverse Flyes",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Work rear deltoids and upper back",
      ),
      Exercise(
        name: "Push-ups",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Classic exercise to work chest, shoulders and triceps",
      ),
      Exercise(
        name: "Dips",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Bodyweight exercise for chest and triceps",
      ),
      Exercise(
        name: "Cable Crossovers",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Crossover motion to work chest muscles",
      ),
      Exercise(
        name: "Upright Rows",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Pull weight up to work shoulders and traps",
      ),
      Exercise(
        name: "Arnold Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Shoulder press with rotation for full range of motion",
      ),
      Exercise(
        name: "Face Pulls",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Pull cable toward face to work rear delts",
      ),
      Exercise(
        name: "Chest Flyes",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Fly motion to work chest muscles",
      ),
      Exercise(
        name: "Military Press",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Overhead press to work shoulders and core",
      ),
      Exercise(
        name: "Pike Push-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Push-ups with elevated hips to target shoulders",
      ),
      Exercise(
        name: "Cable Lateral Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Lateral raises using cable machine",
      ),
      Exercise(
        name: "Cable Front Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Front raises using cable machine",
      ),
      Exercise(
        name: "Shoulder Shrugs",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Lift shoulders to work traps",
      ),
    ],
  ),
  
   // Leg Workouts
  Workout(
    id: "leg_001",
    title: "Leg Day Challenge",
    duration: "40 min",
    exercises: "20 exercises",
    level: "Hard",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
    exerciseList: [
      Exercise(
        name: "Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Compound movement working quads, glutes and hamstrings",
      ),
      Exercise(
        name: "Deadlifts",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Compound movement working posterior chain",
      ),
      Exercise(
        name: "Lunges",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Unilateral exercise for legs and balance",
      ),
      Exercise(
        name: "Leg Press",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Machine exercise for quads and glutes",
      ),
      Exercise(
        name: "Romanian Deadlifts",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Hamstring-focused deadlift variation",
      ),
      Exercise(
        name: "Bulgarian Split Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral squat with rear foot elevated",
      ),
      Exercise(
        name: "Leg Curls",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Machine exercise for hamstrings",
      ),
      Exercise(
        name: "Leg Extensions",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Machine exercise for quadriceps",
      ),
      Exercise(
        name: "Calf Raises",
        caloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Exercise for calf muscles",
      ),
      Exercise(
        name: "Hip Thrusts",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Exercise for glutes and hamstrings",
      ),
      Exercise(
        name: "Step-ups",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral exercise using bench or platform",
      ),
      Exercise(
        name: "Wall Sits",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Isometric exercise for quads and glutes",
      ),
      Exercise(
        name: "Single-leg Deadlifts",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral deadlift for balance and strength",
      ),
      Exercise(
        name: "Pistol Squats",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Single-leg squat for advanced athletes",
      ),
      Exercise(
        name: "Jump Squats",
        caloriesPerMinute: 11,
        duration: 150, // 2.5 minutes
        description: "Explosive squat for power development",
      ),
      Exercise(
        name: "Box Jumps",
        caloriesPerMinute: 12,
        duration: 150, // 2.5 minutes
        description: "Explosive jump for power and conditioning",
      ),
      Exercise(
        name: "Lateral Lunges",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Lunge to the side to work inner and outer thighs",
      ),
      Exercise(
        name: "Sumo Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Wide-stance squat to target inner thighs and glutes",
      ),
      Exercise(
        name: "Glute Bridges",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Exercise to activate glutes and hamstrings",
      ),
      Exercise(
        name: "Single-leg Glute Bridges",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Unilateral glute bridge for balance and strength",
      ),
    ],
  ),
  Workout(
    id: "leg_002",
    title: "Beginner Leg Workout",
    duration: "25 min",
    exercises: "12 exercises",
    level: "Beginner",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
    exerciseList: [
      Exercise(
        name: "Chair Squats",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Squat to chair and stand up, good for beginners",
      ),
      Exercise(
        name: "Bodyweight Squats",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Basic squat without added weight",
      ),
      Exercise(
        name: "Wall Sit",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Isometric exercise for legs and core",
      ),
      Exercise(
        name: "Lunges",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Unilateral exercise for legs and balance",
      ),
      Exercise(
        name: "Leg Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Lying exercise to work quadriceps",
      ),
      Exercise(
        name: "Calf Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Exercise for calf muscles",
      ),
      Exercise(
        name: "Glute Bridges",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Exercise to activate glutes and hamstrings",
      ),
      Exercise(
        name: "Step-ups",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Unilateral exercise using bench or platform",
      ),
      Exercise(
        name: "Leg Curls (Bodyweight)",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Bodyweight version of hamstring exercise",
      ),
      Exercise(
        name: "Standing Calf Raises",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Calf exercise standing upright",
      ),
      Exercise(
        name: "Marching in Place",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Simple cardio and leg exercise",
      ),
      Exercise(
        name: "Leg Swings",
        caloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Dynamic stretching exercise for legs",
      ),
    ],
  ),
  Workout(
    id: "leg_003",
    title: "Squat and Deadlift",
    duration: "35 min",
    exercises: "16 exercises",
    level: "Intermediate",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
    exerciseList: [
      Exercise(
        name: "Back Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Barbell squat with weight on back",
      ),
      Exercise(
        name: "Front Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Barbell squat with weight in front",
      ),
      Exercise(
        name: "Goblet Squats",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Squat holding weight at chest level",
      ),
      Exercise(
        name: "Bulgarian Split Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral squat with rear foot elevated",
      ),
      Exercise(
        name: "Sumo Deadlifts",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Deadlift with wide stance and outside grip",
      ),
      Exercise(
        name: "Romanian Deadlifts",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Hamstring-focused deadlift variation",
      ),
      Exercise(
        name: "Stiff-leg Deadlifts",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Deadlift with straighter legs to target hamstrings",
      ),
      Exercise(
        name: "Single-leg Deadlifts",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral deadlift for balance and strength",
      ),
      Exercise(
        name: "Trap Bar Deadlifts",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Deadlift using specialized hexagonal bar",
      ),
      Exercise(
        name: "Pause Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Squat with pause at bottom for strength",
      ),
      Exercise(
        name: "Jump Squats",
        caloriesPerMinute: 11,
        duration: 150, // 2.5 minutes
        description: "Explosive squat for power development",
      ),
      Exercise(
        name: "Pistol Squats",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Single-leg squat for advanced athletes",
      ),
      Exercise(
        name: "Overhead Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Squat with weight held overhead",
      ),
      Exercise(
        name: "Deficit Deadlifts",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Deadlift from elevated position for increased range",
      ),
      Exercise(
        name: "Dead Stop Deadlifts",
        caloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Deadlift with complete stop between reps",
      ),
      Exercise(
        name: "Squat Jumps",
        caloriesPerMinute: 11,
        duration: 150, // 2.5 minutes
        description: "Explosive jump from squat position",
      ),
    ],
  ),
  Workout(
    id: "leg_004",
    title: "Lower Body Burn",
    duration: "30 min",
    exercises: "14 exercises",
    level: "Intermediate",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
    exerciseList: [
      Exercise(
        name: "Squats",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Compound movement working quads, glutes and hamstrings",
      ),
      Exercise(
        name: "Lunges",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Unilateral exercise for legs and balance",
      ),
      Exercise(
        name: "Deadlifts",
        caloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Compound movement working posterior chain",
      ),
      Exercise(
        name: "Leg Press",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Machine exercise for quads and glutes",
      ),
      Exercise(
        name: "Romanian Deadlifts",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Hamstring-focused deadlift variation",
      ),
      Exercise(
        name: "Calf Raises",
        caloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Exercise for calf muscles",
      ),
      Exercise(
        name: "Hip Thrusts",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Exercise for glutes and hamstrings",
      ),
      Exercise(
        name: "Step-ups",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Unilateral exercise using bench or platform",
      ),
      Exercise(
        name: "Wall Sits",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Isometric exercise for quads and glutes",
      ),
      Exercise(
        name: "Jump Squats",
        caloriesPerMinute: 11,
        duration: 120, // 2 minutes
        description: "Explosive squat for power development",
      ),
      Exercise(
        name: "Box Jumps",
        caloriesPerMinute: 12,
        duration: 120, // 2 minutes
        description: "Explosive jump for power and conditioning",
      ),
      Exercise(
        name: "Lateral Lunges",
        caloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Lunge to the side to work inner and outer thighs",
      ),
      Exercise(
        name: "Sumo Squats",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Wide-stance squat to target inner thighs and glutes",
      ),
      Exercise(
        name: "Glute Bridges",
        caloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Exercise to activate glutes and hamstrings",
      ),
    ],
  ),
  Workout(
    id: "leg_005",
    title: "Quadriceps Focus",
    duration: "32 min",
    exercises: "15 exercises",
    level: "Hard",
    bodyFocus: "Leg",
    videoAsset: "assets/videos/defaultVid.jpg", // Placeholder path
    thumbnailAsset: "assets/abs_workout.mp4", // You can replace with actual leg asset
    exerciseList: [
      Exercise(
        name: "Back Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Barbell squat with weight on back, primary quad exercise",
      ),
      Exercise(
        name: "Front Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Barbell squat with weight in front, quad-focused",
      ),
      Exercise(
        name: "Leg Press",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Machine exercise for quads and glutes",
      ),
      Exercise(
        name: "Bulgarian Split Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Unilateral squat with rear foot elevated, intense quad burn",
      ),
      Exercise(
        name: "Lunges",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Unilateral exercise for legs and balance",
      ),
      Exercise(
        name: "Leg Extensions",
        caloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Machine exercise specifically for quadriceps",
      ),
      Exercise(
        name: "Goblet Squats",
        caloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Squat holding weight at chest level, good quad activation",
      ),
      Exercise(
        name: "Sissy Squats",
        caloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Quad isolation exercise with body leaning back",
      ),
      Exercise(
        name: "Jump Squats",
        caloriesPerMinute: 11,
        duration: 150, // 2.5 minutes
        description: "Explosive squat for power and quad development",
      ),
      Exercise(
        name: "Pistol Squats",
        caloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Single-leg squat for quad strength and balance",
      ),
      Exercise(
        name: "Hack Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Squat variation that targets quads specifically",
      ),
      Exercise(
        name: "Squat Jumps",
        caloriesPerMinute: 11,
        duration: 150, // 2.5 minutes
        description: "Explosive jump from squat position for quad power",
      ),
      Exercise(
        name: "Front Foot Elevated Split Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Split squat with front foot elevated for quad emphasis",
      ),
      Exercise(
        name: "Pause Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Squat with pause at bottom to increase quad time under tension",
      ),
      Exercise(
        name: "Overhead Squats",
        caloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Squat with weight held overhead, requires quad stability",
      ),
    ],
  ),
];
