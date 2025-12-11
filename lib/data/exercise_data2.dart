import '../models/workout_model.dart';

List<Workout> exerciseWorkouts = [
  // Chest Workouts
  Workout(
    id: "chest_001",
    title: "Chest Power Training",
    duration: "30 min",
    exercises: "8 exercises",
    level: "Hard",
    bodyFocus: "Chest",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Overall Strength & Thickness",
      ),
      Exercise(
        name: "Incline Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Upper Chest Development",
      ),
      Exercise(
        name: "Dumbbell Flyes",
        baseCaloriesPerMinute: 6,
        duration: 180, // 3 minutes
        description: "Chest Stretch & Isolation",
      ),
      Exercise(
        name: "Push-ups",
        baseCaloriesPerMinute: 7,
        duration: 180, // 3 minutes
        description: "Overall Chest, Shoulders, Triceps, and Core",
      ),
      Exercise(
        name: "Dumbbell Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Overall Strength & Symmetrical Development",
      ),
      Exercise(
        name: "Decline Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Lower Chest Focus",
      ),
      Exercise(
        name: "Cable Crossover",
        baseCaloriesPerMinute: 6,
        duration: 180, // 3 minutes
        description: "Lower/Inner Chest Focus (Adduction)",
      ),
    ],
  ),
 Workout(
    id: "chest_002",
    title: "Chest Power Training MEDIUM",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Medium",
    bodyFocus: "Chest",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Dumbbell Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Overall Strength & Symmetrical Development",
      ),
      Exercise(
        name: "Incline Bench Press",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Upper Chest Development",
      ),
      Exercise(
        name: "Dumbbell Flyes",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Chest Stretch & Isolation",
      ),
      Exercise(
        name: "Push-ups",
        baseCaloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Overall Chest, Shoulders, Triceps, and Core",
      ),
      Exercise(
        name: "Cable Crossover",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Lower/Inner Chest Focus (Adduction)",
      ),
    ],
  ),
  Workout(
    id: "chest_003",
    title: "Chest Power Training EASY",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Easy",
    bodyFocus: "Chest",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Push-ups",
        baseCaloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Overall Chest, Shoulders, Triceps, and Core",
      ),
      Exercise(
        name: "Dumbbell Flyes",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Chest Stretch & Isolation",
      ),
      Exercise(
        name: "Cable Crossover",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Lower/Inner Chest Focus (Adduction)",
      ),
    ],
  ),

  // Back (Lats) Workouts
  Workout(
    id: "back_lats_001",
    title: "Back Lats Training HARD",
    duration: "25 min",
    exercises: "5 exercises",
    level: "Hard",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Pull-ups / Chin-ups",
        baseCaloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Back Width (Lat Activation)",
      ),
      Exercise(
        name: "Lat Pulldowns",
        baseCaloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Lat Isolation (Width)",
      ),
      Exercise(
        name: "Single-Arm Dumbbell Rows",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Lats & Full Back Thickness",
      ),
      Exercise(
        name: "Barbell Deadlift",
        baseCaloriesPerMinute: 10,
        duration: 150, // 2.5 minutes
        description: "Full Body Strength (Targets Lats, Traps, Spinal Erectors)",
      ),
    ],
  ),
  Workout(
    id: "back_lats_002",
    title: "Back Lats Training MEDIUM",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Medium",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Lat Pulldowns",
        baseCaloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Lat Isolation (Width)",
      ),
      Exercise(
        name: "Single-Arm Dumbbell Rows",
        baseCaloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Lats & Full Back Thickness",
      ),
      Exercise(
        name: "Pull-ups / Chin-ups",
        baseCaloriesPerMinute: 9,
        duration: 120, // 2 minutes
        description: "Back Width (Lat Activation)",
      ),
    ],
  ),
  Workout(
    id: "back_lats_003",
    title: "Back Lats Training EASY",
    duration: "15 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Lat Pulldowns",
        baseCaloriesPerMinute: 7,
        duration: 90, // 1.5 minutes
        description: "Lat Isolation (Width)",
      ),
      Exercise(
        name: "Single-Arm Dumbbell Rows",
        baseCaloriesPerMinute: 8,
        duration: 90, // 1.5 minutes
        description: "Lats & Full Back Thickness",
      ),
    ],
  ),

  // Back (Mid-Back) Workouts
  Workout(
    id: "back_mid_01",
    title: "Mid-Back Training HARD",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Rows",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Overall Thickness & Strength",
      ),
      Exercise(
        name: "Seated Cable Rows",
        baseCaloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Horizontal Pull for Mid/Upper Back Thickness",
      ),
      Exercise(
        name: "T-Bar Row",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Mid-Back & Traps Thickness",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Rear Delts & Upper Back/Rotator Cuff Health",
      ),
      Exercise(
        name: "Rack Pulls",
        baseCaloriesPerMinute: 10,
        duration: 150, // 2.5 minutes
        description: "Upper Back Strength & Partial Deadlift",
      ),
    ],
  ),
  Workout(
    id: "back_mid_02",
    title: "Mid-Back Training MEDIUM",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Medium",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Rows",
        baseCaloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Overall Thickness & Strength",
      ),
      Exercise(
        name: "Seated Cable Rows",
        baseCaloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Horizontal Pull for Mid/Upper Back Thickness",
      ),
      Exercise(
        name: "T-Bar Row",
        baseCaloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Mid-Back & Traps Thickness",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Rear Delts & Upper Back/Rotator Cuff Health",
      ),
    ],
  ),
  Workout(
    id: "back_mid_03",
    title: "Mid-Back Training EASY",
    duration: "15 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Back",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Seated Cable Rows",
        baseCaloriesPerMinute: 7,
        duration: 90, // 1.5 minutes
        description: "Horizontal Pull for Mid/Upper Back Thickness",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Rear Delts & Upper Back/Rotator Cuff Health",
      ),
    ],
  ),

  // Traps Workouts
 Workout(
    id: "traps_001",
    title: "Traps Training HARD",
    duration: "20 min",
    exercises: "3 exercises",
    level: "Hard",
    bodyFocus: "Traps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Deadlift",
        baseCaloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Full Body Strength (Targets Lats, Traps, Spinal Erectors)",
      ),
      Exercise(
        name: "Rack Pulls",
        baseCaloriesPerMinute: 10,
        duration: 120, // 2 minutes
        description: "Upper Back Strength & Partial Deadlift",
      ),
      Exercise(
        name: "Barbell/Dumbbell Shrugs",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Upper Traps (Height)",
      ),
    ],
  ),
  Workout(
    id: "traps_002",
    title: "Traps Training EASY",
    duration: "15 min",
    exercises: "2 exercises",
    level: "Easy",
    bodyFocus: "Traps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell/Dumbbell Shrugs",
        baseCaloriesPerMinute: 6,
        duration: 90, // 1.5 minutes
        description: "Upper Traps (Height)",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Rear Delts & Upper Back",
      ),
    ],
  ),

  // Shoulders Workouts
 Workout(
    id: "shoulders_001",
    title: "Shoulders Training HARD",
    duration: "30 min",
    exercises: "8 exercises",
    level: "Hard",
    bodyFocus: "Shoulders",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Overhead Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Overall Shoulder Strength & Anterior/Medial Delts",
      ),
      Exercise(
        name: "Dumbbell Lateral Raises",
        baseCaloriesPerMinute: 5,
        duration: 180, // 3 minutes
        description: "Medial Delts (Shoulder Width)",
      ),
      Exercise(
        name: "Rear Delt Fly",
        baseCaloriesPerMinute: 5,
        duration: 180, // 3 minutes
        description: "Posterior Delt Isolation (Shoulder Health)",
      ),
      Exercise(
        name: "Dumbbell Front Raises",
        baseCaloriesPerMinute: 5,
        duration: 180, // 3 minutes
        description: "Anterior Delt Isolation",
      ),
      Exercise(
        name: "Upright Rows",
        baseCaloriesPerMinute: 7,
        duration: 180, // 3 minutes
        description: "Medial Delts & Upper Traps",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 180, // 3 minutes
        description: "Rear Delts & Upper Back",
      ),
    ],
  ),
  Workout(
    id: "shoulders_002",
    title: "Shoulders Training MEDIUM",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Medium",
    bodyFocus: "Shoulders",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Overhead Press",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Overall Shoulder Strength & Anterior/Medial Delts",
      ),
      Exercise(
        name: "Dumbbell Lateral Raises",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Medial Delts (Shoulder Width)",
      ),
      Exercise(
        name: "Rear Delt Fly",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Posterior Delt Isolation (Shoulder Health)",
      ),
      Exercise(
        name: "Dumbbell Front Raises",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Anterior Delt Isolation",
      ),
      Exercise(
        name: "Face Pulls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Rear Delts & Upper Back",
      ),
    ],
  ),
  Workout(
    id: "shoulders_003",
    title: "Shoulders Training EASY",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Easy",
    bodyFocus: "Shoulders",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Dumbbell Lateral Raises",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Medial Delts (Shoulder Width)",
      ),
      Exercise(
        name: "Dumbbell Front Raises",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Anterior Delt Isolation",
      ),
      Exercise(
        name: "Rear Delt Fly",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Posterior Delt Isolation (Shoulder Health)",
      ),
    ],
  ),

  // Triceps Workouts
 Workout(
    id: "triceps_001",
    title: "Triceps Training HARD",
    duration: "25 min",
    exercises: "5 exercises",
    level: "Hard",
    bodyFocus: "Triceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Overhead Tricep Extension",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Long Head (Stretch) Focus",
      ),
      Exercise(
        name: "Skull Crushers",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Long Head (Stretch) & Overall Mass",
      ),
      Exercise(
        name: "Tricep Pushdowns",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Overall Tricep (Medial/Lateral Heads)",
      ),
      Exercise(
        name: "Overhead Press",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Overall Shoulder Strength & Anterior/Medial Delts",
      ),
    ],
  ),
  Workout(
    id: "triceps_02",
    title: "Triceps Training MEDIUM",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Medium",
    bodyFocus: "Triceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Tricep Pushdowns",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Overall Tricep (Medial/Lateral Heads)",
      ),
      Exercise(
        name: "Skull Crushers",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Long Head (Stretch) & Overall Mass",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Long Head (Stretch) Focus",
      ),
    ],
  ),
  Workout(
    id: "triceps_003",
    title: "Triceps Training EASY",
    duration: "15 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Triceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Tricep Pushdowns",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Overall Tricep (Medial/Lateral Heads)",
      ),
      Exercise(
        name: "Overhead Tricep Extension",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Long Head (Stretch) Focus",
      ),
    ],
  ),

  // Biceps Workouts
 Workout(
    id: "biceps_001",
    title: "Biceps Training HARD",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Biceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell/Dumbbell Bicep Curls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Overall Bicep Mass",
      ),
      Exercise(
        name: "Hammer Curls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Bicep and Brachialis/Forearm Development",
      ),
      Exercise(
        name: "Preacher Curls",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Bicep Isolation (Focus on Peak)",
      ),
      Exercise(
        name: "Concentration Curls",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Bicep Peak & Isolation",
      ),
      Exercise(
        name: "Cable Bicep Curls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Use cable machine for constant tension",
      ),
    ],
  ),
  Workout(
    id: "biceps_002",
    title: "Biceps Training MEDIUM",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Medium",
    bodyFocus: "Biceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell/Dumbbell Bicep Curls",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Overall Bicep Mass",
      ),
      Exercise(
        name: "Hammer Curls",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Bicep and Brachialis/Forearm Development",
      ),
      Exercise(
        name: "Preacher Curls",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Bicep Isolation (Focus on Peak)",
      ),
      Exercise(
        name: "Concentration Curls",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Bicep Peak & Isolation",
      ),
    ],
  ),
  Workout(
    id: "biceps_003",
    title: "Biceps Training EASY",
    duration: "15 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Biceps",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell/Dumbbell Bicep Curls",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Overall Bicep Mass",
      ),
      Exercise(
        name: "Hammer Curls",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Bicep and Brachialis/Forearm Development",
      ),
    ],
  ),

  // Forearms Workouts
  Workout(
    id: "forearms_001",
    title: "Forearms Training MEDIUM",
    duration: "15 min",
    exercises: "2 exercises",
    level: "Medium",
    bodyFocus: "Forearms",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Wrist Curls",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Forearm Flexors/Extensors",
      ),
      Exercise(
        name: "Hammer Curls",
        baseCaloriesPerMinute: 5,
        duration: 90, // 1.5 minutes
        description: "Bicep and Brachialis/Forearm Development",
      ),
    ],
  ),

  // Quads Workouts
  Workout(
    id: "quads_001",
    title: "Quads Training HARD",
    duration: "30 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Squat",
        baseCaloriesPerMinute: 10,
        duration: 180, // 3 minutes
        description: "Overall Leg Strength & Quad Dominance",
      ),
      Exercise(
        name: "Leg Press",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Quad & Glute Mass (Adjustable Foot Placement)",
      ),
      Exercise(
        name: "Leg Extensions",
        baseCaloriesPerMinute: 4,
        duration: 180, // 3 minutes
        description: "Quad Isolation & Teardrop Muscle (VMO)",
      ),
      Exercise(
        name: "Lunges",
        baseCaloriesPerMinute: 7,
        duration: 180, // 3 minutes
        description: "Single-Leg Strength & Quad/Glute Focus",
      ),
      Exercise(
        name: "Goblet Squats",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Squat holding weight at chest level, good quad activation",
      ),
    ],
  ),
  Workout(
    id: "quads_002",
    title: "Quads Training MEDIUM",
    duration: "25 min",
    exercises: "5 exercises",
    level: "Medium",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Leg Press",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Quad & Glute Mass (Adjustable Foot Placement)",
      ),
      Exercise(
        name: "Leg Extensions",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Quad Isolation & Teardrop Muscle (VMO)",
      ),
      Exercise(
        name: "Lunges",
        baseCaloriesPerMinute: 7,
        duration: 150, // 2.5 minutes
        description: "Single-Leg Strength & Quad/Glute Focus",
      ),
      Exercise(
        name: "Bodyweight Squats",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Basic squat without added weight",
      ),
    ],
  ),
  Workout(
    id: "quads_003",
    title: "Quads Training EASY",
    duration: "20 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Bodyweight Squats",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Basic squat without added weight",
      ),
      Exercise(
        name: "Leg Extensions",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Quad Isolation & Teardrop Muscle (VMO)",
      ),
      Exercise(
        name: "Lunges",
        baseCaloriesPerMinute: 7,
        duration: 120, // 2 minutes
        description: "Single-Leg Strength & Quad/Glute Focus",
      ),
    ],
  ),

  // Glutes & Hamstrings Workouts
  Workout(
    id: "glutes_hamstrings_001",
    title: "Glutes & Hamstrings Training HARD",
    duration: "30 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Barbell Deadlift",
        baseCaloriesPerMinute: 10,
        duration: 180, // 3 minutes
        description: "Full Posterior Chain Strength",
      ),
      Exercise(
        name: "Romanian Deadlifts",
        baseCaloriesPerMinute: 9,
        duration: 180, // 3 minutes
        description: "Hamstring & Glute Stretch/Mass",
      ),
      Exercise(
        name: "Glute Bridges",
        baseCaloriesPerMinute: 6,
        duration: 180, // 3 minutes
        description: "Glute Isolation & Peak Contraction",
      ),
      Exercise(
        name: "Lying Leg Curls",
        baseCaloriesPerMinute: 5,
        duration: 180, // 3 minutes
        description: "Hamstring Isolation & Contraction",
      ),
      Exercise(
        name: "Hip Thrusts",
        baseCaloriesPerMinute: 8,
        duration: 180, // 3 minutes
        description: "Exercise for glutes and hamstrings",
      ),
    ],
  ),
  Workout(
    id: "glutes_hamstrings_002",
    title: "Glutes & Hamstrings Training MEDIUM",
    duration: "25 min",
    exercises: "5 exercises",
    level: "Medium",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Romanian Deadlifts",
        baseCaloriesPerMinute: 9,
        duration: 150, // 2.5 minutes
        description: "Hamstring & Glute Stretch/Mass",
      ),
      Exercise(
        name: "Glute Bridges",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Glute Isolation & Peak Contraction",
      ),
      Exercise(
        name: "Lying Leg Curls",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Hamstring Isolation & Contraction",
      ),
      Exercise(
        name: "Hip Thrusts",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Exercise for glutes and hamstrings",
      ),
    ],
  ),
  Workout(
    id: "glutes_hamstrings_003",
    title: "Glutes & Hamstrings Training EASY",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Easy",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Glute Bridges",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Glute Isolation & Peak Contraction",
      ),
      Exercise(
        name: "Lying Leg Curls",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Hamstring Isolation & Contraction",
      ),
      Exercise(
        name: "Hip Thrusts",
        baseCaloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Exercise for glutes and hamstrings",
      ),
    ],
  ),

  // Calves Workouts
  Workout(
    id: "calves_001",
    title: "Calves Training MEDIUM",
    duration: "20 min",
    exercises: "3 exercises",
    level: "Medium",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Standing Calf Raises",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Gastrocnemius (Upper, visible calf)",
      ),
      Exercise(
        name: "Seated Calf Raises",
        baseCaloriesPerMinute: 3,
        duration: 120, // 2 minutes
        description: "Soleus (Deeper muscle, crucial for ankle stability)",
      ),
      Exercise(
        name: "Calf Press",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Machine exercise for calf muscles",
      ),
    ],
  ),
  Workout(
    id: "calves_002",
    title: "Calves Training EASY",
    duration: "15 min",
    exercises: "2 exercises",
    level: "Easy",
    bodyFocus: "Legs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Standing Calf Raises",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Gastrocnemius (Upper, visible calf)",
      ),
      Exercise(
        name: "Seated Calf Raises",
        baseCaloriesPerMinute: 3,
        duration: 90, // 1.5 minutes
        description: "Soleus (Deeper muscle, crucial for ankle stability)",
      ),
    ],
  ),

  // Abs Workouts
  Workout(
    id: "abs_001",
    title: "Abs Training HARD",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Abs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Cable Crunches",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Upper Abs (Hypertrophy/Mass)",
      ),
      Exercise(
        name: "Hanging Leg Raises",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Lower Abs (Requires high grip strength)",
      ),
      Exercise(
        name: "Reverse Crunches",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Lower Abs (Pelvic tilt and lift)",
      ),
      Exercise(
        name: "Ab Wheel Rollouts",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Spinal Extension (High Anti-Extension Strength)",
      ),
      Exercise(
        name: "Plank",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Hold a plank position to strengthen your core",
      ),
    ],
  ),
  Workout(
    id: "abs_02",
    title: "Abs Training MEDIUM",
    duration: "20 min",
    exercises: "5 exercises",
    level: "Medium",
    bodyFocus: "Abs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Cable Crunches",
        baseCaloriesPerMinute: 5,
        duration: 120, // 2 minutes
        description: "Upper Abs (Hypertrophy/Mass)",
      ),
      Exercise(
        name: "Reverse Crunches",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Lower Abs (Pelvic tilt and lift)",
      ),
      Exercise(
        name: "Russian Twists",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Rotational Power (Dynamic Obliques)",
      ),
      Exercise(
        name: "Plank",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Hold a plank position to strengthen your core",
      ),
    ],
  ),
  Workout(
    id: "abs_03",
    title: "Abs Training EASY",
    duration: "15 min",
    exercises: "4 exercises",
    level: "Easy",
    bodyFocus: "Abs",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Reverse Crunches",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Lower Abs (Pelvic tilt and lift)",
      ),
      Exercise(
        name: "Russian Twists",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Rotational Power (Dynamic Obliques)",
      ),
      Exercise(
        name: "Plank",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Hold a plank position to strengthen your core",
      ),
    ],
  ),

  // Rotational / Anti-Rotation Workouts
 Workout(
    id: "rotational_001",
    title: "Rotational Core Training HARD",
    duration: "25 min",
    exercises: "6 exercises",
    level: "Hard",
    bodyFocus: "Core",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Russian Twists",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Rotational Power (Dynamic Obliques)",
      ),
      Exercise(
        name: "Side Plank",
        baseCaloriesPerMinute: 8,
        duration: 150, // 2.5 minutes
        description: "Anti-Lateral Flexion (Lateral Stability/Obliques)",
      ),
      Exercise(
        name: "Pallof Press",
        baseCaloriesPerMinute: 4,
        duration: 150, // 2.5 minutes
        description: "Anti-Rotation (Prevents twisting; excellent for stability)",
      ),
      Exercise(
        name: "Cable Woodchopper",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Rotational Power (Cross-body movement)",
      ),
      Exercise(
        name: "Cable Crunches",
        baseCaloriesPerMinute: 5,
        duration: 150, // 2.5 minutes
        description: "Upper Abs (Hypertrophy/Mass)",
      ),
      Exercise(
        name: "Hanging Leg Raises",
        baseCaloriesPerMinute: 6,
        duration: 150, // 2.5 minutes
        description: "Lower Abs (Requires high grip strength)",
      ),
    ],
  ),
  Workout(
    id: "rotational_002",
    title: "Rotational Core Training MEDIUM",
    duration: "20 min",
    exercises: "4 exercises",
    level: "Medium",
    bodyFocus: "Core",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Russian Twists",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Rotational Power (Dynamic Obliques)",
      ),
      Exercise(
        name: "Side Plank",
        baseCaloriesPerMinute: 8,
        duration: 120, // 2 minutes
        description: "Anti-Lateral Flexion (Lateral Stability/Obliques)",
      ),
      Exercise(
        name: "Pallof Press",
        baseCaloriesPerMinute: 4,
        duration: 120, // 2 minutes
        description: "Anti-Rotation (Prevents twisting; excellent for stability)",
      ),
      Exercise(
        name: "Cable Woodchopper",
        baseCaloriesPerMinute: 6,
        duration: 120, // 2 minutes
        description: "Rotational Power (Cross-body movement)",
      ),
    ],
  ),
  Workout(
    id: "rotational_003",
    title: "Rotational Core Training EASY",
    duration: "15 min",
    exercises: "3 exercises",
    level: "Easy",
    bodyFocus: "Core",
    videoAsset: "assets/defaultVid.jpg",
    thumbnailAsset: "assets/abs.png",
    exerciseList: [
      Exercise(
        name: "Russian Twists",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Rotational Power (Dynamic Obliques)",
      ),
      Exercise(
        name: "Pallof Press",
        baseCaloriesPerMinute: 4,
        duration: 90, // 1.5 minutes
        description: "Anti-Rotation (Prevents twisting; excellent for stability)",
      ),
    ],
  ),
];
