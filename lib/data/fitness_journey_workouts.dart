import '../models/workout_model.dart';
import '../services/workout_goal_service.dart';

const String weightLossJourneyId = 'weight_loss';
const String cardioJourneyId = 'cardio';
const String strengthPowerJourneyId = 'strength_power';
const String muscularEnduranceJourneyId = 'muscular_endurance';
const String healthWellnessJourneyId = 'health_wellness';

Exercise _exercise(
  String name,
  int caloriesPerMinute,
  int durationSeconds,
  String description, {
  bool? requiresWeightInputOverride,
}) {
  return Exercise(
    name: name,
    baseCaloriesPerMinute: caloriesPerMinute,
    duration: durationSeconds,
    description: description,
    requiresWeightInputOverride: requiresWeightInputOverride,
  );
}

Workout _journeyWorkout({
  required String id,
  required String title,
  required String duration,
  required String level,
  required String journeyId,
  required String journeyName,
  required int journeyOrder,
  required String thumbnailAsset,
  required List<Exercise> exercises,
}) {
  return Workout(
    id: id,
    title: title,
    duration: duration,
    exercises: '${exercises.length} exercises',
    level: level,
    bodyFocus: journeyName,
    videoAsset: 'assets/defaultVid.jpg',
    thumbnailAsset: thumbnailAsset,
    journeyId: journeyId,
    journeyName: journeyName,
    journeyOrder: journeyOrder,
    primaryGoal: goalForJourneyId(journeyId),
    goalTags: [goalForJourneyId(journeyId)],
    exerciseList: exercises,
  );
}

final Map<String, List<Workout>> fitnessJourneyWorkoutsById = {
  weightLossJourneyId: [
    _journeyWorkout(
      id: 'journey_weight_loss_01',
      title: 'Full Body HIIT Circuit',
      duration: '24 min',
      level: 'Hard',
      journeyId: weightLossJourneyId,
      journeyName: 'Weight Loss',
      journeyOrder: 1,
      thumbnailAsset:
          'assets/thumbnails/Abs/abs_training_hard.png',
      exercises: [
        _exercise('Burpees', 12, 150, 'Full-body explosive conditioning', requiresWeightInputOverride: false),
        _exercise('Mountain Climbers', 10, 150, 'Core-driven cardio finisher', requiresWeightInputOverride: false),
        _exercise('Kettlebell Swings', 11, 150, 'Powerful hip hinge for calorie burn'),
        _exercise('Jumping Jacks', 8, 120, 'Fast-paced bodyweight warm-up', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_weight_loss_02',
      title: 'Dumbbell Fat Burner',
      duration: '26 min',
      level: 'Medium',
      journeyId: weightLossJourneyId,
      journeyName: 'Weight Loss',
      journeyOrder: 2,
      thumbnailAsset:
          'assets/thumbnails/Shoulders/shoulders_training_medium.png',
      exercises: [
        _exercise('Dumbbell Thrusters', 10, 150, 'Leg drive into overhead press'),
        _exercise('Renegade Rows', 9, 150, 'Row variation that challenges the core'),
        _exercise('Alternating Dumbbell Lunges', 9, 150, 'Alternating lower-body burner'),
        _exercise('Dumbbell Snatch', 10, 150, 'Explosive single-arm power lift'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_weight_loss_03',
      title: 'Metabolic Conditioning',
      duration: '20 min',
      level: 'Hard',
      journeyId: weightLossJourneyId,
      journeyName: 'Weight Loss',
      journeyOrder: 3,
      thumbnailAsset:
          'assets/thumbnails/Rotational Core/rotational_core_training_hard.png',
      exercises: [
        _exercise('Battle Ropes', 11, 120, 'Fast arm-driven metabolic finisher'),
        _exercise('Medicine Ball Slams', 10, 120, 'Explosive total-body power work'),
        _exercise('Box Jumps', 10, 120, 'Plyometric leg power and conditioning', requiresWeightInputOverride: false),
        _exercise('Jump Rope', 9, 120, 'Quick cadence cardio work', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_weight_loss_04',
      title: 'Bodyweight Calorie Crusher',
      duration: '18 min',
      level: 'Medium',
      journeyId: weightLossJourneyId,
      journeyName: 'Weight Loss',
      journeyOrder: 4,
      thumbnailAsset:
          'assets/thumbnails/Quads/quads_training_hard.png',
      exercises: [
        _exercise('Squat Jumps', 10, 120, 'Explosive squat variation', requiresWeightInputOverride: false),
        _exercise('Plank Jacks', 8, 120, 'Plank stability with cardio demand', requiresWeightInputOverride: false),
        _exercise('High Knees', 9, 120, 'Quick turnover cardio drill', requiresWeightInputOverride: false),
        _exercise('Bear Crawls', 9, 120, 'Full-body crawling endurance', requiresWeightInputOverride: false),
      ],
    ),
  ],
  cardioJourneyId: [
    _journeyWorkout(
      id: 'journey_cardio_01',
      title: 'Gym Machine Intervals',
      duration: '28 min',
      level: 'Medium',
      journeyId: cardioJourneyId,
      journeyName: 'Cardio',
      journeyOrder: 1,
      thumbnailAsset: 'assets/thumbnails/Calves/calves_training_medium.png',
      exercises: [
        _exercise('Treadmill Sprints', 11, 180, 'Short high-intensity sprint intervals', requiresWeightInputOverride: false),
        _exercise('StairMaster Climbing', 10, 180, 'Continuous climbing for endurance', requiresWeightInputOverride: false),
        _exercise('Rowing Machine Intervals', 10, 180, 'Alternating rowing intervals', requiresWeightInputOverride: false),
        _exercise('Stationary Bike Sprints', 10, 180, 'Fast pedal bursts with recovery', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_cardio_02',
      title: 'Steady-State Cardio',
      duration: '30 min',
      level: 'Easy',
      journeyId: cardioJourneyId,
      journeyName: 'Cardio',
      journeyOrder: 2,
      thumbnailAsset: 'assets/thumbnails/Calves/calves_training_easy.png',
      exercises: [
        _exercise('Incline Treadmill Walk', 7, 240, 'Sustained incline walking pace', requiresWeightInputOverride: false),
        _exercise('Elliptical Machine', 7, 240, 'Low-impact machine cardio', requiresWeightInputOverride: false),
        _exercise('Recumbent Bike', 6, 240, 'Seated endurance ride', requiresWeightInputOverride: false),
        _exercise('Rowing Machine at Moderate Pace', 8, 240, 'Controlled moderate rowing pace', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_cardio_03',
      title: 'Bodyweight Cardio Blast',
      duration: '18 min',
      level: 'Medium',
      journeyId: cardioJourneyId,
      journeyName: 'Cardio',
      journeyOrder: 3,
      thumbnailAsset:
          'assets/thumbnails/Rotational Core/rotational_core_training_medium.png',
      exercises: [
        _exercise('High Knees', 9, 120, 'Quick pace cardio drill', requiresWeightInputOverride: false),
        _exercise('Jump Rope', 9, 120, 'Light-footed cardio rhythm', requiresWeightInputOverride: false),
        _exercise('Skater Jumps', 8, 120, 'Lateral plyometric cardio movement', requiresWeightInputOverride: false),
        _exercise('Jump Squats', 10, 120, 'Explosive lower-body cardio work', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_cardio_04',
      title: 'Endurance Cardio Circuit',
      duration: '26 min',
      level: 'Hard',
      journeyId: cardioJourneyId,
      journeyName: 'Cardio',
      journeyOrder: 4,
      thumbnailAsset: 'assets/thumbnails/Abs/abs_training_medium.png',
      exercises: [
        _exercise('5K Row', 9, 180, 'Extended rowing endurance piece', requiresWeightInputOverride: false),
        _exercise('SkiErg', 9, 180, 'Upper-body dominant cardio machine', requiresWeightInputOverride: false),
        _exercise('Assault Bike', 10, 180, 'Full-body air bike conditioning', requiresWeightInputOverride: false),
        _exercise('Brisk Walking Cooldown', 5, 180, 'Lower-intensity recovery cardio', requiresWeightInputOverride: false),
      ],
    ),
  ],
  strengthPowerJourneyId: [
    _journeyWorkout(
      id: 'journey_strength_power_01',
      title: 'The Big Three',
      duration: '30 min',
      level: 'Hard',
      journeyId: strengthPowerJourneyId,
      journeyName: 'Strength & Power',
      journeyOrder: 1,
      thumbnailAsset:
          'assets/thumbnails/Chest/chest_training_hard.png',
      exercises: [
        _exercise('Barbell Back Squat', 8, 210, 'Foundational lower-body barbell lift'),
        _exercise('Barbell Bench Press', 8, 210, 'Heavy horizontal pressing movement'),
        _exercise('Barbell Conventional Deadlift', 9, 210, 'Full-body strength builder from the floor'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_strength_power_02',
      title: 'Upper Body Push Strength',
      duration: '26 min',
      level: 'Hard',
      journeyId: strengthPowerJourneyId,
      journeyName: 'Strength & Power',
      journeyOrder: 2,
      thumbnailAsset:
          'assets/thumbnails/Shoulders/shoulders_training_hard.png',
      exercises: [
        _exercise('Barbell Overhead Press', 8, 180, 'Strict overhead pressing strength'),
        _exercise('Incline Barbell Press', 8, 180, 'Upper-chest pressing focus'),
        _exercise('Weighted Dips', 9, 180, 'Loaded pushing for chest and triceps'),
        _exercise('Close-Grip Bench Press', 8, 180, 'Bench variation emphasizing triceps'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_strength_power_03',
      title: 'Upper Body Pull Strength',
      duration: '26 min',
      level: 'Hard',
      journeyId: strengthPowerJourneyId,
      journeyName: 'Strength & Power',
      journeyOrder: 3,
      thumbnailAsset:
          'assets/thumbnails/Traps/traps_training_hard.png',
      exercises: [
        _exercise('Weighted Pull-Ups', 9, 180, 'Loaded vertical pulling strength', requiresWeightInputOverride: false),
        _exercise('Barbell Pendlay Rows', 8, 180, 'Explosive row from the floor'),
        _exercise('Heavy Dumbbell Shrugs', 7, 150, 'Trap-focused overload work'),
        _exercise('T-Bar Rows', 8, 180, 'Heavy rowing for upper-back thickness'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_strength_power_04',
      title: 'Explosive Power',
      duration: '24 min',
      level: 'Hard',
      journeyId: strengthPowerJourneyId,
      journeyName: 'Strength & Power',
      journeyOrder: 4,
      thumbnailAsset:
          'assets/thumbnails/Shoulders/shoulders_training_medium.png',
      exercises: [
        _exercise('Power Cleans', 10, 150, 'Explosive pull from the floor'),
        _exercise('Push Press', 9, 150, 'Dip-and-drive overhead press'),
        _exercise('Heavy Kettlebell Swings', 9, 150, 'Explosive hip extension power work'),
        _exercise('Heavy Medicine Ball Throws', 9, 150, 'Powerful throwing pattern for total-body speed', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_strength_power_05',
      title: 'Posterior Chain Strength',
      duration: '26 min',
      level: 'Hard',
      journeyId: strengthPowerJourneyId,
      journeyName: 'Strength & Power',
      journeyOrder: 5,
      thumbnailAsset:
          'assets/thumbnails/Glutes & Hamstrings/glutes_hamstrings_training_hard.png',
      exercises: [
        _exercise('Barbell Romanian Deadlift', 8, 180, 'Hip-hinge strength for hamstrings and glutes'),
        _exercise('Barbell Good Mornings', 8, 180, 'Posterior-chain barbell accessory'),
        _exercise("Farmer's Walk", 8, 180, 'Heavy loaded carry for total-body stability'),
        _exercise('Glute-Ham Raises', 7, 180, 'Posterior-chain bodyweight strength', requiresWeightInputOverride: false),
      ],
    ),
  ],
  muscularEnduranceJourneyId: [
    _journeyWorkout(
      id: 'journey_muscular_endurance_01',
      title: 'Lower Body Stamina',
      duration: '22 min',
      level: 'Medium',
      journeyId: muscularEnduranceJourneyId,
      journeyName: 'Muscular Endurance',
      journeyOrder: 1,
      thumbnailAsset:
          'assets/thumbnails/Quads/quads_training_medium.png',
      exercises: [
        _exercise('Walking Lunges', 8, 150, 'Continuous lower-body lunge pattern', requiresWeightInputOverride: false),
        _exercise('Goblet Squats', 8, 150, 'Front-loaded squat for high reps'),
        _exercise('Wall Sits', 6, 120, 'Static lower-body endurance hold', requiresWeightInputOverride: false),
        _exercise('Box Step-Ups', 7, 150, 'Repetitive step pattern for stamina', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_muscular_endurance_02',
      title: 'Upper Body Endurance',
      duration: '20 min',
      level: 'Medium',
      journeyId: muscularEnduranceJourneyId,
      journeyName: 'Muscular Endurance',
      journeyOrder: 2,
      thumbnailAsset:
          'assets/thumbnails/Triceps/triceps_training_medium.png',
      exercises: [
        _exercise('Push-Ups', 7, 150, 'Bodyweight pressing endurance', requiresWeightInputOverride: false),
        _exercise('Inverted Rows', 7, 150, 'Horizontal pulling endurance', requiresWeightInputOverride: false),
        _exercise('Light Dumbbell Shoulder Press', 7, 150, 'High-rep shoulder pressing'),
        _exercise('Triceps Pushdowns', 6, 150, 'Controlled triceps isolation work'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_muscular_endurance_03',
      title: 'High-Rep Full Body Challenge',
      duration: '24 min',
      level: 'Hard',
      journeyId: muscularEnduranceJourneyId,
      journeyName: 'Muscular Endurance',
      journeyOrder: 3,
      thumbnailAsset:
          'assets/thumbnails/Rotational Core/rotational_core_training_hard.png',
      exercises: [
        _exercise('Lightweight Barbell Squats', 8, 150, 'Barbell squat sets for muscular stamina'),
        _exercise('Kettlebell Swings', 9, 150, 'Rhythmic hinge work for conditioning'),
        _exercise('TRX Rows', 7, 150, 'Suspension-based pulling endurance', requiresWeightInputOverride: false),
        _exercise('Jumping Lunges', 9, 150, 'Plyometric lunge endurance work', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_muscular_endurance_04',
      title: 'Core and Carry Endurance',
      duration: '18 min',
      level: 'Medium',
      journeyId: muscularEnduranceJourneyId,
      journeyName: 'Muscular Endurance',
      journeyOrder: 4,
      thumbnailAsset:
          'assets/thumbnails/Abs/abs_training_easy.png',
      exercises: [
        _exercise('Plank Holds', 5, 120, 'Core bracing under fatigue', requiresWeightInputOverride: false),
        _exercise('Suitcase Carries', 7, 150, 'Unilateral loaded carry endurance'),
        _exercise("Farmer's Carries", 8, 150, 'Bilateral loaded carry stamina'),
        _exercise('Hollow Body Holds', 5, 120, 'Static anterior-core endurance', requiresWeightInputOverride: false),
      ],
    ),
  ],
  healthWellnessJourneyId: [
    _journeyWorkout(
      id: 'journey_health_wellness_01',
      title: 'Beginner Machine Circuit',
      duration: '20 min',
      level: 'Easy',
      journeyId: healthWellnessJourneyId,
      journeyName: 'Health & Wellness',
      journeyOrder: 1,
      thumbnailAsset:
          'assets/thumbnails/Chest/chest_training_easy.png',
      exercises: [
        _exercise('Machine Chest Press', 6, 150, 'Guided machine pressing movement'),
        _exercise('Seated Cable Row', 6, 150, 'Stable machine-supported row'),
        _exercise('Machine Leg Press', 6, 150, 'Lower-body strength on a guided track'),
        _exercise('Machine Lat Pulldown', 6, 150, 'Beginner-friendly vertical pulling'),
      ],
    ),
    _journeyWorkout(
      id: 'journey_health_wellness_02',
      title: 'Core Stability and Mobility',
      duration: '18 min',
      level: 'Easy',
      journeyId: healthWellnessJourneyId,
      journeyName: 'Health & Wellness',
      journeyOrder: 2,
      thumbnailAsset:
          'assets/thumbnails/Rotational Core/rotational_core_training_easy.png',
      exercises: [
        _exercise('Forearm Plank', 5, 120, 'Core stability and bracing', requiresWeightInputOverride: false),
        _exercise('Cat-Cow Stretch', 4, 120, 'Gentle spinal mobility flow', requiresWeightInputOverride: false),
        _exercise('Glute Bridges', 5, 120, 'Posterior-chain activation', requiresWeightInputOverride: false),
        _exercise('Bird-Dog', 4, 120, 'Balance and core coordination', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_health_wellness_03',
      title: 'Active Recovery',
      duration: '16 min',
      level: 'Easy',
      journeyId: healthWellnessJourneyId,
      journeyName: 'Health & Wellness',
      journeyOrder: 3,
      thumbnailAsset:
          'assets/thumbnails/Calves/calves_training_easy.png',
      exercises: [
        _exercise('Light Stationary Bike', 5, 150, 'Low-impact recovery cardio', requiresWeightInputOverride: false),
        _exercise('Bodyweight Squats', 5, 120, 'Light movement practice', requiresWeightInputOverride: false),
        _exercise('Swiss Ball Crunches', 5, 120, 'Controlled abdominal work', requiresWeightInputOverride: false),
        _exercise('Standing Stretch Routine', 3, 150, 'Gentle flexibility sequence', requiresWeightInputOverride: false),
      ],
    ),
    _journeyWorkout(
      id: 'journey_health_wellness_04',
      title: 'Light Free Weights Introduction',
      duration: '18 min',
      level: 'Easy',
      journeyId: healthWellnessJourneyId,
      journeyName: 'Health & Wellness',
      journeyOrder: 4,
      thumbnailAsset:
          'assets/thumbnails/Biceps/biceps_training_easy.png',
      exercises: [
        _exercise('Dumbbell Bicep Curls', 5, 120, 'Introductory arm isolation work'),
        _exercise('Dumbbell Lateral Raises', 5, 120, 'Beginner shoulder raises'),
        _exercise('Light Dumbbell Romanian Deadlift', 6, 150, 'Light hip-hinge practice'),
        _exercise('Triceps Dumbbell Kickbacks', 5, 120, 'Light triceps accessory movement'),
      ],
    ),
  ],
};

List<Workout> getJourneyWorkouts(String journeyId) {
  return fitnessJourneyWorkoutsById[journeyId] ?? const [];
}
