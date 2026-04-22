class VideoMappingService {
  // New journey-specific videos should win when present.
  static final Map<String, String> _journeyVideoMapping = {
    // Weight Loss
    'Burpees':
        'assets/Fitness Journey/Weight Loss/Workout 1 Full Body HIIT Circuit/Burpees.mp4',
    'Mountain Climbers':
        'assets/Fitness Journey/Weight Loss/Workout 1 Full Body HIIT Circuit/Mountain Climbers.mp4',
    'Kettlebell Swings':
        'assets/Fitness Journey/Weight Loss/Workout 1 Full Body HIIT Circuit/Kettlebell Swings_.mp4',
    'Jumping Jacks':
        'assets/Fitness Journey/Weight Loss/Workout 1 Full Body HIIT Circuit/Jumping Jacks_.mp4',
    'Dumbbell Thrusters':
        'assets/Fitness Journey/Weight Loss/Workout 2 Dumbbell Fat Burner/Dumbbell Thrusters.mp4',
    'Renegade Rows':
        'assets/Fitness Journey/Weight Loss/Workout 2 Dumbbell Fat Burner/Renegade Rows_.mp4',
    'Alternating Dumbbell Lunges':
        'assets/Fitness Journey/Weight Loss/Workout 2 Dumbbell Fat Burner/Alternating Dumbbell Lunges.mp4',
    'Dumbbell Snatch':
        'assets/Fitness Journey/Weight Loss/Workout 2 Dumbbell Fat Burner/Dumbbell Snatch_.mp4',
    'Battle Ropes':
        'assets/Fitness Journey/Weight Loss/Workout 3 Metabolic Conditioning/Battle Ropes.mp4',
    'Medicine Ball Slams':
        'assets/Fitness Journey/Weight Loss/Workout 3 Metabolic Conditioning/Medicine Ball Slams_.mp4',
    'Box Jumps':
        'assets/Fitness Journey/Weight Loss/Workout 3 Metabolic Conditioning/Box Jumps.mp4',
    'Jump Rope':
        'assets/Fitness Journey/Weight Loss/Workout 3 Metabolic Conditioning/Jump Rope_.mp4',
    'Squat Jumps':
        'assets/Fitness Journey/Weight Loss/Workout 4 Bodyweight Calorie Crusher/Squat Jumps_.mp4',
    'Plank Jacks':
        'assets/Fitness Journey/Weight Loss/Workout 4 Bodyweight Calorie Crusher/Plank Jacks_.mp4',
    'High Knees':
        'assets/Fitness Journey/Weight Loss/Workout 4 Bodyweight Calorie Crusher/High Knees_.mp4',
    'Bear Crawls':
        'assets/Fitness Journey/Weight Loss/Workout 4 Bodyweight Calorie Crusher/Bear Crawls_.mp4',

    // Cardio
    'Treadmill Sprints':
        'assets/Fitness Journey/Cardio/Workout 1 Gym Machine Intervals/Treadmill Sprints.mp4',
    'StairMaster Climbing':
        'assets/Fitness Journey/Cardio/Workout 1 Gym Machine Intervals/Stair Master Climbing.mp4',
    'Stair Master Climbing':
        'assets/Fitness Journey/Cardio/Workout 1 Gym Machine Intervals/Stair Master Climbing.mp4',
    'Rowing Machine Intervals':
        'assets/Fitness Journey/Cardio/Workout 1 Gym Machine Intervals/Rowing Machine Intervals_.mp4',
    'Stationary Bike Sprints':
        'assets/Fitness Journey/Cardio/Workout 1 Gym Machine Intervals/Stationary Bike Sprints.mp4',
    'Incline Treadmill Walk':
        'assets/Fitness Journey/Cardio/Workout 2 Steady-State Cardio/Incline Treadmill Walk.mp4',
    'Elliptical Machine':
        'assets/Fitness Journey/Cardio/Workout 2 Steady-State Cardio/Elliptical Machine.mp4',
    'Recumbent Bike':
        'assets/Fitness Journey/Cardio/Workout 2 Steady-State Cardio/Recumbent Bike.mp4',
    'Rowing Machine at Moderate Pace':
        'assets/Fitness Journey/Cardio/Workout 2 Steady-State Cardio/Rowing Machine at Moderate Pace.mp4',
    'Jump Squats':
        'assets/Fitness Journey/Cardio/Workout 3 Bodyweight Cardio Blast/Jumping Squats.mp4',
    'Jumping Squats':
        'assets/Fitness Journey/Cardio/Workout 3 Bodyweight Cardio Blast/Jumping Squats.mp4',
    'Skater Jumps':
        'assets/Fitness Journey/Cardio/Workout 3 Bodyweight Cardio Blast/Skater Jumps.mp4',
    '5K Row':
        'assets/Fitness Journey/Cardio/Workout 4 Endurance Cardio Circuit/Rowing Machine at Moderate Pace_.mp4',
    'Assault Bike':
        'assets/Fitness Journey/Cardio/Workout 4 Endurance Cardio Circuit/Assault Bike.mp4',
    'Brisk Walking Cooldown':
        'assets/Fitness Journey/Cardio/Workout 4 Endurance Cardio Circuit/Brisk Walking Cooldown.mp4',
    'SkiErg':
        'assets/Fitness Journey/Cardio/Workout 4 Endurance Cardio Circuit/SkiErg_.mp4',
    'SkiErg Intervals':
        'assets/Fitness Journey/Cardio/Workout 4 Endurance Cardio Circuit/SkiErg_.mp4',

    // Strength & Power
    'Barbell Back Squat':
        'assets/Fitness Journey/Strength & Power/Workout 1 The Big Three/Barbell Back Squat.mp4',
    'Barbell Conventional Deadlift':
        'assets/Fitness Journey/Strength & Power/Workout 1 The Big Three/Barbell Conventional Deadlift_.mp4',
    'Barbell Overhead Press':
        'assets/Fitness Journey/Strength & Power/Workout 2 Upper Body Push Strength/Barbell Overhead Press.mp4',
    'Close-Grip Bench Press':
        'assets/Fitness Journey/Strength & Power/Workout 2 Upper Body Push Strength/Close Grip Barbell Bench Press_.mp4',
    'Close Grip Barbell Bench Press':
        'assets/Fitness Journey/Strength & Power/Workout 2 Upper Body Push Strength/Close Grip Barbell Bench Press_.mp4',
    'Weighted Dips':
        'assets/Fitness Journey/Strength & Power/Workout 2 Upper Body Push Strength/Dumbbell Weighted Dip.mp4',
    'Incline Barbell Press':
        'assets/Fitness Journey/Strength & Power/Workout 2 Upper Body Push Strength/Incline Barbell Press_.mp4',
    'Weighted Pull-Ups':
        'assets/Fitness Journey/Strength & Power/Workout 3 Upper Body Pull Strength/Weighted Pull-Ups.mp4',
    'Barbell Pendlay Rows':
        'assets/Fitness Journey/Strength & Power/Workout 3 Upper Body Pull Strength/Barbell Pendlay Rows_.mp4',
    'Heavy Dumbbell Shrugs':
        'assets/Fitness Journey/Strength & Power/Workout 3 Upper Body Pull Strength/Heavy Dumbbell Shrugs.mp4',
    'Power Cleans':
        'assets/Fitness Journey/Strength & Power/Workout 4 Explosive Power/Power Cleans.mp4',
    'Push Press':
        'assets/Fitness Journey/Strength & Power/Workout 4 Explosive Power/Push Press.mp4',
    'Heavy Kettlebell Swings':
        'assets/Fitness Journey/Strength & Power/Workout 4 Explosive Power/Heavy Kettlebell Swing.mp4',
    'Heavy Kettlebell Swing':
        'assets/Fitness Journey/Strength & Power/Workout 4 Explosive Power/Heavy Kettlebell Swing.mp4',
    'Heavy Medicine Ball Throws':
        'assets/Fitness Journey/Strength & Power/Workout 4 Explosive Power/Heavy Medicine Ball Throws_.mp4',
    'Barbell Romanian Deadlift':
        'assets/Fitness Journey/Strength & Power/Workout 5 Posterior Chain Strength/Barbell Romanian Deadlift_.mp4',
    'Barbell Good Mornings':
        'assets/Fitness Journey/Strength & Power/Workout 5 Posterior Chain Strength/Barbell Good Mornings.mp4',
    "Farmer's Walk":
        'assets/Fitness Journey/Strength & Power/Workout 5 Posterior Chain Strength/Farmers Walk.mp4',
    'Glute-Ham Raises':
        'assets/Fitness Journey/Strength & Power/Workout 5 Posterior Chain Strength/Glute-Ham Raises.mp4',

    // Muscular Endurance
    'Walking Lunges':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Walking Lunge.mp4',
    'Walking Lunge':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Walking Lunge.mp4',
    'Goblet Squats':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Goblet Squats.mp4',
    'Wall Sits':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Wall Sits.mp4',
    'Box Step-Ups':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Box Step up.mp4',
    'Box Step up':
        'assets/Fitness Journey/Muscular Endurance/Workout 1 Lower Body Stamina/Box Step up.mp4',
    'Inverted Rows':
        'assets/Fitness Journey/Muscular Endurance/Workout 2 Upper Body Endurance/Inverted Row.mp4',
    'Inverted Row':
        'assets/Fitness Journey/Muscular Endurance/Workout 2 Upper Body Endurance/Inverted Row.mp4',
    'Light Dumbbell Shoulder Press':
        'assets/Fitness Journey/Muscular Endurance/Workout 2 Upper Body Endurance/Light Dumbbell Shoulder Press_.mp4',
    'Lightweight Barbell Squats':
        'assets/Fitness Journey/Muscular Endurance/Workout 3 High-Rep Full Body Challenge/Lightweight Barbell Squats.mp4',
    'TRX Rows':
        'assets/Fitness Journey/Muscular Endurance/Workout 3 High-Rep Full Body Challenge/TRX Rows.mp4',
    'Jumping Lunges':
        'assets/Fitness Journey/Muscular Endurance/Workout 3 High-Rep Full Body Challenge/Jumping Lunges_.mp4',
    'Plank Holds':
        'assets/Fitness Journey/Muscular Endurance/Workout 4 Core and Carry Endurance/Plank Holds.mp4',
    'Suitcase Carries':
        'assets/Fitness Journey/Muscular Endurance/Workout 4 Core and Carry Endurance/Suitcase Carries.mp4',
    "Farmer's Carries":
        'assets/Fitness Journey/Muscular Endurance/Workout 4 Core and Carry Endurance/Farmer\u2019s Carries.mp4',
    'Hollow Body Holds':
        'assets/Fitness Journey/Muscular Endurance/Workout 4 Core and Carry Endurance/Hollow Body Hold.mp4',
    'Hollow Body Hold':
        'assets/Fitness Journey/Muscular Endurance/Workout 4 Core and Carry Endurance/Hollow Body Hold.mp4',

    // General Health & Wellness
    'Machine Chest Press':
        'assets/Fitness Journey/General Health & Wellness/Workout 1 Beginner Machine Circuit/Machine Chest Press.mp4',
    'Machine Leg Press':
        'assets/Fitness Journey/General Health & Wellness/Workout 1 Beginner Machine Circuit/Machine Leg Press.mp4',
    'Forearm Plank':
        'assets/Fitness Journey/General Health & Wellness/Workout 2 Core Stability and Mobility/Forearm Plank.mp4',
    'Cat-Cow Stretch':
        'assets/Fitness Journey/General Health & Wellness/Workout 2 Core Stability and Mobility/Cat - Cow Stretch.mp4',
    'Cat Cow Stretch':
        'assets/Fitness Journey/General Health & Wellness/Workout 2 Core Stability and Mobility/Cat - Cow Stretch.mp4',
    'Bird-Dog':
        'assets/Fitness Journey/General Health & Wellness/Workout 2 Core Stability and Mobility/Bird Dog.mp4',
    'Bird Dog':
        'assets/Fitness Journey/General Health & Wellness/Workout 2 Core Stability and Mobility/Bird Dog.mp4',
    'Light Stationary Bike':
        'assets/Fitness Journey/General Health & Wellness/Workout 3 Active Recovery/Light Stationary Bike.mp4',
    'Swiss Ball Crunches':
        'assets/Fitness Journey/General Health & Wellness/Workout 3 Active Recovery/Swiss Ball Crunch.mp4',
    'Swiss Ball Crunch':
        'assets/Fitness Journey/General Health & Wellness/Workout 3 Active Recovery/Swiss Ball Crunch.mp4',
    'Standing Stretch Routine':
        'assets/Fitness Journey/General Health & Wellness/Workout 3 Active Recovery/Standing Stretch Routine.mp4',
    'Dumbbell Bicep Curls':
        'assets/Fitness Journey/General Health & Wellness/Workout 4 Light Free Weights Introduction/Dumbbell Bicep Curls.mp4',
    'Light Dumbbell Romanian Deadlift':
        'assets/Fitness Journey/General Health & Wellness/Workout 4 Light Free Weights Introduction/Light Dumbbell Romanian Deadlift_.mp4',
    'Triceps Dumbbell Kickbacks':
        'assets/Fitness Journey/General Health & Wellness/Workout 4 Light Free Weights Introduction/Triceps Dumbbell Kickbacks.mp4',
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
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
  }
}
