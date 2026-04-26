class VideoMappingService {
  // New journey-specific videos should win when present.
  static final Map<String, String> _journeyVideoMapping = {
    // Weight Loss
    'Burpees':
        'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Burpees.mp4',
    'Mountain Climbers':
        'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Mountain_Climbers.mp4',
    'Kettlebell Swings':
        'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Kettlebell_Swings_.mp4',
    'Jumping Jacks':
        'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Jumping_Jacks_.mp4',
    'Dumbbell Thrusters':
        'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Thrusters.mp4',
    'Renegade Rows':
        'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Renegade_Rows_.mp4',
    'Alternating Dumbbell Lunges':
        'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Alternating_Dumbbell_Lunges.mp4',
    'Dumbbell Snatch':
        'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Snatch_.mp4',
    'Battle Ropes':
        'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Battle_Ropes.mp4',
    'Medicine Ball Slams':
        'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Medicine_Ball_Slams_.mp4',
    'Box Jumps':
        'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Box_Jumps.mp4',
    'Jump Rope':
        'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Jump_Rope_.mp4',
    'Squat Jumps':
        'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Squat_Jumps_.mp4',
    'Plank Jacks':
        'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Plank_Jacks_.mp4',
    'High Knees':
        'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/High_Knees_.mp4',
    'Bear Crawls':
        'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Bear_Crawls_.mp4',

    // Cardio
    'Treadmill Sprints':
        'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Treadmill_Sprints.mp4',
    'StairMaster Climbing':
        'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stair_Master_Climbing.mp4',
    'Stair Master Climbing':
        'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stair_Master_Climbing.mp4',
    'Rowing Machine Intervals':
        'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Rowing_Machine_Intervals_.mp4',
    'Stationary Bike Sprints':
        'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stationary_Bike_Sprints.mp4',
    'Incline Treadmill Walk':
        'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Incline_Treadmill_Walk.mp4',
    'Elliptical Machine':
        'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Elliptical_Machine.mp4',
    'Recumbent Bike':
        'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Recumbent_Bike.mp4',
    'Rowing Machine at Moderate Pace':
        'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Rowing_Machine_at_Moderate_Pace.mp4',
    'Jump Squats':
        'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jumping_Squats.mp4',
    'Jumping Squats':
        'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jumping_Squats.mp4',
    'Skater Jumps':
        'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Skater_Jumps.mp4',
    '5K Row':
        'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Rowing_Machine_at_Moderate_Pace_.mp4',
    'Assault Bike':
        'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Assault_Bike.mp4',
    'Brisk Walking Cooldown':
        'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Brisk_Walking_Cooldown.mp4',
    'SkiErg':
        'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/SkiErg_.mp4',
    'SkiErg Intervals':
        'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/SkiErg_.mp4',

    // Strength & Power
    'Barbell Back Squat':
        'assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Back_Squat.mp4',
    'Barbell Conventional Deadlift':
        'assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Conventional_Deadlift_.mp4',
    'Barbell Overhead Press':
        'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Barbell_Overhead_Press.mp4',
    'Close-Grip Bench Press':
        'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Close_Grip_Barbell_Bench_Press_.mp4',
    'Close Grip Barbell Bench Press':
        'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Close_Grip_Barbell_Bench_Press_.mp4',
    'Weighted Dips':
        'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Dumbbell_Weighted_Dip.mp4',
    'Incline Barbell Press':
        'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Incline_Barbell_Press_.mp4',
    'Weighted Pull-Ups':
        'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Weighted_Pull-Ups.mp4',
    'Barbell Pendlay Rows':
        'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Barbell_Pendlay_Rows_.mp4',
    'Heavy Dumbbell Shrugs':
        'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Heavy_Dumbbell_Shrugs.mp4',
    'Power Cleans':
        'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Power_Cleans.mp4',
    'Push Press':
        'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Push_Press.mp4',
    'Heavy Kettlebell Swings':
        'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Kettlebell_Swing.mp4',
    'Heavy Kettlebell Swing':
        'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Kettlebell_Swing.mp4',
    'Heavy Medicine Ball Throws':
        'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Medicine_Ball_Throws_.mp4',
    'Barbell Romanian Deadlift':
        'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Romanian_Deadlift_.mp4',
    'Barbell Good Mornings':
        'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Good_Mornings.mp4',
    "Farmer's Walk":
        'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Farmers_Walk.mp4',
    'Glute-Ham Raises':
        'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Glute-Ham_Raises.mp4',

    // Muscular Endurance
    'Walking Lunges':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Walking_Lunge.mp4',
    'Walking Lunge':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Walking_Lunge.mp4',
    'Goblet Squats':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Goblet_Squats.mp4',
    'Wall Sits':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Wall_Sits.mp4',
    'Box Step-Ups':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Box_Step_up.mp4',
    'Box Step up':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Box_Step_up.mp4',
    'Inverted Rows':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Inverted_Row.mp4',
    'Inverted Row':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Inverted_Row.mp4',
    'Light Dumbbell Shoulder Press':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Light_Dumbbell_Shoulder_Press_.mp4',
    'Lightweight Barbell Squats':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Lightweight_Barbell_Squats.mp4',
    'TRX Rows':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/TRX_Rows.mp4',
    'Jumping Lunges':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Jumping_Lunges_.mp4',
    'Plank Holds':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Plank_Holds.mp4',
    'Suitcase Carries':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Suitcase_Carries.mp4',
    "Farmer's Carries":
        'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Farmer\u2019s_Carries.mp4',
    'Hollow Body Holds':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Hollow_Body_Hold.mp4',
    'Hollow Body Hold':
        'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Hollow_Body_Hold.mp4',

    // General Health & Wellness
    'Machine Chest Press':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Chest_Press.mp4',
    'Machine Leg Press':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Leg_Press.mp4',
    'Forearm Plank':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Forearm_Plank.mp4',
    'Cat-Cow Stretch':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Cat_-_Cow_Stretch.mp4',
    'Cat Cow Stretch':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Cat_-_Cow_Stretch.mp4',
    'Bird-Dog':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Bird_Dog.mp4',
    'Bird Dog':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Bird_Dog.mp4',
    'Light Stationary Bike':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Light_Stationary_Bike.mp4',
    'Swiss Ball Crunches':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Swiss_Ball_Crunch.mp4',
    'Swiss Ball Crunch':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Swiss_Ball_Crunch.mp4',
    'Standing Stretch Routine':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Standing_Stretch_Routine.mp4',
    'Dumbbell Bicep Curls':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Dumbbell_Bicep_Curls.mp4',
    'Light Dumbbell Romanian Deadlift':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Light_Dumbbell_Romanian_Deadlift_.mp4',
    'Triceps Dumbbell Kickbacks':
        'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Triceps_Dumbbell_Kickbacks.mp4',
  };

  static final Map<String, String> _fallbackVideoMapping = {
    // Chest exercises
    'Barbell Bench Press': 'assets/videos/Chest/barbel_bench_press.mp4',
    'Dumbbell Bench Press': 'assets/videos/Chest/dumbbell_bench_press.mp4',
    'Incline Bench Press': 'assets/videos/Chest/incline_bench_press.mp4',
    'Incline Dumbbell Bench Press': 'assets/videos/Chest/incline_dumbbell_bench_press.mp4',
    'Dumbbell Flyes': 'assets/videos/Chest/dumbbell_flyes.mp4',
    'Cable Crossover': 'assets/videos/Chest/cable_crossover.mp4',
    'Decline Bench Press': 'assets/videos/Chest/decline_bench_press.mp4',
    'Push-ups': 'assets/videos/Chest/push_ups.mp4',
    
    // Biceps exercises
    'Barbell/Dumbbell Bicep Curls': 'assets/videos/Biceps/barbell_dumbbell_bicep_curls.mp4',
    'Hammer Curls': 'assets/videos/Biceps/hammer_curls.mp4',
    'Concentration Curls': 'assets/videos/Biceps/ccncentration_curls.mp4',
    'Preacher Curls': 'assets/videos/Biceps/preacher_curls.mp4',
    'Cable Bicep Curls': 'assets/videos/Biceps/barbell_dumbbell_bicep_curls.mp4',
    
    // Back exercises (Lats)
    'Lat Pulldowns': 'assets/videos/Back/Lats/lat_pulldowns.mp4',
    'Pull-ups Chin-ups': 'assets/videos/Back/Lats/pull_ups_chin_ups.mp4',
    'Single-Arm Dumbbell Rows': 'assets/videos/Back/Lats/single_arm_dumbbell_rows.mp4',
    
    // Back exercises (Mid-Back)
    'Barbell Rows': 'assets/videos/Back/Mid-Back/barbell_rows.mp4',
    'Seated Cable Rows': 'assets/videos/Back/Mid-Back/seated_cable_rows.mp4',
    'T-Bar Rows': 'assets/videos/Back/Mid-Back/t_bar_row_machine_row.mp4',
    'Face Pulls': 'assets/videos/Back/Mid-Back/face_pulls_back.mp4',

    // Calves exercises
    'Standing Calf Raises': 'assets/videos/Calves/standing_calf_raises.mp4',
    'Seated Calf Raises': 'assets/videos/Calves/seated_calf_raises.mp4',
    
    // Forearms exercises
    'Wrist Curls': 'assets/videos/Forearms/wrist_curls_palms_up_down.mp4',
    
    // Glutes & Hamstrings exercises
    'Barbell Deadlift Glutes': 'assets/videos/Glutes & Hamstrings/barbell_deadlift_glutes.mp4',
    'Glute Bridges': 'assets/videos/Glutes & Hamstrings/glute_bridges_hip_thrusts.mp4',
    'Romanian Deadlifts': 'assets/videos/Glutes & Hamstrings/romanian_deadlifts_rdls.mp4',
    'Hip Thrusts': 'assets/videos/Glutes & Hamstrings/hip_thrusts.mp4',
    'Lying Leg Curls': 'assets/videos/Glutes & Hamstrings/lying_seated_leg_curls.mp4',

    
    // Quads exercises
    'Barbell Squat': 'assets/videos/Quads/barbell_squat.mp4',
    'Leg Extensions': 'assets/videos/Quads/leg_extensions.mp4',
    'Leg Press': 'assets/videos/Quads/leg_press.mp4',
    'Lunges': 'assets/videos/Quads/lunges.mp4',
    'Bodyweight Squats': 'assets/videos/Quads/barbell_squat.mp4',
    'Calf Press': 'assets/videos/Calves/standing_calf_raises.mp4',
    
    // Shoulder exercises
    //Anterior
    'Dumbbell Front Raises': 'assets/videos/Shoulder/Anterior/dumbbell_front_raises.mp4',
    'Overhead Press': 'assets/videos/Shoulder/Anterior/overhead_press.mp4',


    //Medial
    'Dumbbell_Cable Lateral Raises': 'assets/videos/Shoulder/Medial/dumbbell_cable_lateral_raises.mp4',
    'Dumbbell Lateral Raises': 'assets/videos/Shoulder/Medial/dumbbell_cable_lateral_raises.mp4',
    'Upright Rows': 'assets/videos/Shoulder/Medial/upright_rows.mp4',

    //Posterior
    'Face Pulls Back': 'assets/videos/Shoulder/Posterior/face_pulls_back.mp4',
    'Rear Delt Fly': 'assets/videos/Shoulder/Posterior/rear_delt_fly.mp4',

    // Traps exercises
    'Barbell/Dumbbell Shrugs': 'assets/videos/Traps/barbell_dumbbell_shrugs.mp4',
    'Barbell Deadlift': 'assets/videos/Traps/barbell_deadlift.mp4',
    'Rack Pulls': 'assets/videos/Traps/rack_pulls.mp4',
    
    // Triceps exercises
    'Skull Crusher': 'assets/videos/Triceps/dumbbell_skull_crusher_opex_exercise_library.mp4',
    'Skull Crushers': 'assets/videos/Triceps/dumbbell_skull_crusher_opex_exercise_library.mp4',
    'Tricep Pushdowns': 'assets/videos/Triceps/tricep_pushdowns.mp4',
    'Overhead Tricep Extension': 'assets/videos/Triceps/overhead_tricep_extension.mp4',
    
    // Abs/Spinal Flexion exercises
    'Cable Crunches': 'assets/videos/Spinal Flexion (Rectus Abdominis)/cable_crunches.mp4',
    'Reverse Crunches': 'assets/videos/Spinal Flexion (Rectus Abdominis)/reverse_crunches.mp4',
    'Hanging Leg Raises': 'assets/videos/Spinal Flexion (Rectus Abdominis)/hanging_leg_raises.mp4',
    'Ab Wheel Rollouts': 'assets/videos/Spinal Flexion (Rectus Abdominis)/ab_wheel_rollouts.mp4',
    
    // Rotational - Anti-Rotation exercises
    'Russian Twists': 'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/russian_twists.mp4',
    'Cable Woodchopper': 'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/wood_chops.mp4',
    'Pallof Press': 'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/pallof_press.mp4',
    'Side Plank': 'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/side_plank.mp4',
    'Plank': 'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/side_plank.mp4',
  };

  // Journey videos override old library mappings when both exist.
  static final Map<String, String> _videoMapping = {
    ..._fallbackVideoMapping,
    ..._journeyVideoMapping,
    // Helpful singular/plural aliases for older assets
    'Lat Pulldown': 'assets/videos/Back/Lats/lat_pulldowns.mp4',
    'Machine Lat Pulldown': 'assets/videos/Back/Lats/lat_pulldowns.mp4',
    'Seated Cable Row': 'assets/videos/Back/Mid-Back/seated_cable_rows.mp4',
    'Triceps Pushdowns': 'assets/videos/Triceps/tricep_pushdowns.mp4',
    'Push Ups': 'assets/videos/Chest/push_ups.mp4',
    'Push-Ups': 'assets/videos/Chest/push_ups.mp4',
  };

  static final Map<String, String> _normalizedVideoMapping = {
    for (final entry in _videoMapping.entries) _normalizeName(entry.key): entry.value,
  };

  static bool _normalizedTextContains(String source, String candidate) {
    if (candidate.isEmpty) {
      return true;
    }
    return _normalizeName(source).contains(_normalizeName(candidate));
  }

  static List<String> getVideoCandidatePaths(
    String exerciseName, {
    String? journeyName,
    String? workoutTitle,
  }) {
    final candidates = <String>[];

    void addCandidate(String? path) {
      if (path == null || path.isEmpty || candidates.contains(path)) {
        return;
      }
      candidates.add(path);
    }

    if (journeyName != null && workoutTitle != null) {
      for (final entry in _journeyVideoMapping.entries) {
        final normalizedKey = _normalizeName(entry.key);
        final normalizedExerciseName = _normalizeName(exerciseName);
        final keyMatches = normalizedKey == normalizedExerciseName ||
            normalizedKey.contains(normalizedExerciseName) ||
            normalizedExerciseName.contains(normalizedKey);

        if (!keyMatches) {
          continue;
        }

        final path = entry.value;
        final pathMatchesJourney = _normalizedTextContains(path, journeyName);
        final pathMatchesWorkout = _normalizedTextContains(path, workoutTitle);

        if (pathMatchesJourney && pathMatchesWorkout) {
          addCandidate(path);
        }
      }
    }

    addCandidate(_videoMapping[exerciseName]);

    final normalizedExerciseName = _normalizeName(exerciseName);
    addCandidate(_normalizedVideoMapping[normalizedExerciseName]);

    for (final key in _videoMapping.keys) {
      final normalizedKey = _normalizeName(key);
      if (normalizedKey.contains(normalizedExerciseName) ||
          normalizedExerciseName.contains(normalizedKey)) {
        addCandidate(_videoMapping[key]);
      }
    }

    return candidates;
  }

  // Method to get video path for an exercise name
  static String? getVideoPath(
    String exerciseName, {
    String? journeyName,
    String? workoutTitle,
  }) {
    print("Looking for video for exercise: '$exerciseName'"); // Debug log
    final candidates = getVideoCandidatePaths(
      exerciseName,
      journeyName: journeyName,
      workoutTitle: workoutTitle,
    );
    if (candidates.isEmpty) {
      print("No video found for exercise: '$exerciseName'"); // Debug log
      return null;
    }

    print("Using video candidate for '$exerciseName' -> '${candidates.first}'");
    return candidates.first;
  }

  // Helper method to normalize names for comparison
  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll('_', ' ') // Treat underscores as spaces
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
  }
}
