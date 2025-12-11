class VideoMappingService {
  // Mapping of exercise names to their corresponding video paths
  static final Map<String, String> _videoMapping = {
    // Chest exercises
    'Barbell Bench Press': 'assets/videos/Chest/barbel_bench_press.mp4',
    'Dumbbell Bench Press': 'assets/videos/Chest/dumbbell_bench_press.mp4',
    'Incline Bench Press': 'assets/videos/Chest/incline_bench_press.mp4',
    'Incline Dumbbell Bench Press': 'assets/videos/Chest/incline_dumbbell_bench_press.mp4',
    'Dumbbell Flyes': 'assets/videos/Chest/dumbbell_flyes.mp4',
    'Cable Fly Crossover (High to low)': 'assets/videos/Chest/cable_fly_crossover.mp4',
    'Push-ups': 'assets/videos/Chest/push_ups.mp4',
    
    // Biceps exercises
    'Barbell_Dumbbell Bicep Curls': 'assets/videos/Biceps/barbell_dumbbell_bicep_curls.mp4',
    'Hammer Curls (Dumbbell_Cable)': 'assets/videos/Biceps/hammer_curls.mp4',
    'Concentration Curls': 'assets/videos/Biceps/concentration_curls.mp4',
    'Preacher Curls': 'assets/videos/Biceps/preacher_curls.mp4',
    
    // Back exercises (Lats)
    'Lat Pulldowns (Wide_Medium Grip)': 'assets/videos/Back/Lats/lat_pulldowns.mp4',
    'Pull-ups_Chin-ups': 'assets/videos/Back/Lats/pull_ups_chin_ups.mp4',
    'Single-Arm Dumbbell Rows': 'assets/videos/Back/Lats/single_arm_dumbbell_rows.mp4',
    
    // Back exercises (Mid-Back)
    'Barbell Rows': 'assets/videos/Back/Mid-Back/barbell_rows.mp4',
    'Seated Cable Rows': 'assets/videos/Back/Mid-Back/seated_cable_rows.mp4',
    'T-Bar Rows': 'assets/videos/Back/Mid-Back/t_bar_rows.mp4',
    'Face Pulls': 'assets/videos/Back/Mid-Back/face_pulls_back.mp4',

    // Calves exercises
    'Standing Calf Raises': 'assets/videos/Calves/standing_calf_raises.mp4',
    'Seated Calf Raises': 'assets/videos/Calves/seated_calf_raises.mp4',
    
    // Forearms exercises
    'Wrist Curls (Palms Up_Down)': 'assets/videos/Forearms/wrist_curls_palms_up_down.mp4',
    
    // Glutes & Hamstrings exercises
    'Barbell Deadlift Glutes': 'assets/videos/Glutes & Hamstrings/barbell_deadlift_glutes.mp4',
    'Glute Bridges _ Hip Thrusts': 'assets/videos/Glutes & Hamstrings/glute_bridges_hip_thrusts.mp4',
    'Romanian Deadlifts': 'assets/videos/Glutes & Hamstrings/romanian_deadlifts_rdls.mp4',
    'Hip Thrusts': 'assets/videos/Glutes & Hamstrings/hip_thrusts.mp4',
    'Lying_Seated Leg Curls': 'assets/videos/Glutes & Hamstrings/lying_seated_leg_curls.mp4',

    
    // Quads exercises
    'Barbell Forward Lunge': 'assets/videos/Quads/barbell_forward_lunge.mp4',
    'Barbell Squat': 'assets/videos/Quads/barbell_squat.mp4',
    'Leg Extensions': 'assets/videos/Quads/leg_extensions.mp4',
    'Leg Press': 'assets/videos/Quads/leg_press.mp4',
    'Lunges': 'assets/videos/Quads/lunges.mp4',
    
    // Shoulder exercises
    //Anterior
    'Dumbbell Front Raises': 'assets/videos/Shoulder/Anterior/dumbbell_front_raises.mp4',
    'Overhead Press': 'assets/videos/Shoulder/Anterior/overhead_press.mp4',
    'Standing Barbell Shoulder Press': 'assets/videos/Shoulder/Anterior/standing_barbell_shoulder_press.mp4',

    //Medial
    'Barbell Upright Row': 'assets/videos/Shoulder/Medial/barbell_upright_row.mp4',
    'Cable Lateral Raises': 'assets/videos/Shoulder/Medial/cable_lateral_raises.mp4',
    'Dumbbell_Cable Lateral Raises': 'assets/videos/Shoulder/Medial/dumbbell_cable_lateral_raises.mp4',
    'Upright Rows': 'assets/videos/Shoulder/Medial/upright_rows.mp4',

    //Posterior
    'Face Pulls Back': 'assets/videos/Shoulder/Posterior/face_pulls_back.mp4',
    'Rear Delt Fly': 'assets/videos/Shoulder/Posterior/rear_delt_fly.mp4',

    // Traps exercises
    'Barbell_Dumbbell Shrugs': 'assets/videos/Traps/barbell_dumbbell_shrugs.mp4',
    'Barbell Deadlift': 'assets/videos/Traps/barbell_deadlift.mp4',
    'Rack Pulls': 'assets/videos/Traps/rack_pulls.mp4',
    
    // Triceps exercises
    'Skull Crusher': 'assets/videos/Triceps/dumbbell_skull_crusher_opex_exercise_library.mp4',
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
  };

  // Method to get video path for an exercise name
  static String? getVideoPath(String exerciseName) {
    print("Looking for video for exercise: '$exerciseName'"); // Debug log
    
    // First, try to find an exact match
    if (_videoMapping.containsKey(exerciseName)) {
      print("Found exact match for: '$exerciseName' -> '${_videoMapping[exerciseName]}'"); // Debug log
      return _videoMapping[exerciseName];
    }

    // If no exact match, try to find a partial match by normalizing the name
    String normalizedExerciseName = _normalizeName(exerciseName);
    print("Normalized exercise name: '$normalizedExerciseName'"); // Debug log
    
    for (String key in _videoMapping.keys) {
      String normalizedKey = _normalizeName(key);
      print("Checking against normalized key: '$normalizedKey'"); // Debug log
      
      if (normalizedKey.contains(normalizedExerciseName) || 
          normalizedExerciseName.contains(normalizedKey)) {
        print("Found partial match for: '$exerciseName' -> '$key' -> '${_videoMapping[key]}'"); // Debug log
        return _videoMapping[key];
      }
    }

    // If no match found, return null
    print("No video found for exercise: '$exerciseName'"); // Debug log
    return null;
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
