import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

import 'admin_dashboard_screen.dart';
import 'admin_community_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_users_screen.dart';
import 'admin_route_utils.dart';
import 'login_screen.dart';

class AdminCustomWorkoutScreen extends StatefulWidget {
  const AdminCustomWorkoutScreen({super.key});

  @override
  State<AdminCustomWorkoutScreen> createState() =>
      _AdminCustomWorkoutScreenState();
}

class CustomExerciseEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? videoAsset;
  bool requiresWeightInput = true;

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}

class _AdminCustomWorkoutScreenState extends State<AdminCustomWorkoutScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<CustomExerciseEntry> _exercises = [CustomExerciseEntry()];

  String _selectedLevel = 'Easy';
  final List<String> _levels = ['Easy', 'Medium', 'Hard'];

  String _selectedBodyFocus = 'Chest';
  final List<String> _bodyFocusOptions = [
    'Chest',
    'Arms',
    'Core',
    'Lower Body',
    'Shoulders',
    'Back'
  ];
  final List<String> _videoAssets = [
    'assets/videos/Back/Lats/lat_pulldowns.mp4',
    'assets/videos/Back/Lats/pull_ups_chin_ups.mp4',
    'assets/videos/Back/Lats/single_arm_dumbbell_rows.mp4',
    'assets/videos/Back/Mid-Back/barbell_rows.mp4',
    'assets/videos/Back/Mid-Back/face_pulls_back.mp4',
    'assets/videos/Back/Mid-Back/seated_cable_rows.mp4',
    'assets/videos/Back/Mid-Back/t_bar_row_machine_row.mp4',
    'assets/videos/Biceps/barbell_dumbbell_bicep_curls.mp4',
    'assets/videos/Biceps/ccncentration_curls.mp4',
    'assets/videos/Biceps/hammer_curls.mp4',
    'assets/videos/Biceps/preacher_curls.mp4',
    'assets/videos/Calves/seated_calf_raises.mp4',
    'assets/videos/Calves/standing_calf_raises.mp4',
    'assets/videos/Chest/barbel_bench_press.mp4',
    'assets/videos/Chest/cable_crossover.mp4',
    'assets/videos/Chest/decline_bench_press.mp4',
    'assets/videos/Chest/dumbbell_bench_press.mp4',
    'assets/videos/Chest/dumbbell_flyes.mp4',
    'assets/videos/Chest/incline_bench_press.mp4',
    'assets/videos/Chest/incline_dumbbell_bench_press.mp4',
    'assets/videos/Chest/push_ups.mp4',
    'assets/videos/Forearms/wrist_curls_palms_up_down.mp4',
    'assets/videos/Glutes & Hamstrings/barbell_deadlift_glutes.mp4',
    'assets/videos/Glutes & Hamstrings/glute_bridges_hip_thrusts.mp4',
    'assets/videos/Glutes & Hamstrings/hip_thrusts.mp4',
    'assets/videos/Glutes & Hamstrings/lying_seated_leg_curls.mp4',
    'assets/videos/Glutes & Hamstrings/romanian_deadlifts_rdls.mp4',
    'assets/videos/Quads/barbell_forward_lunge.mp4',
    'assets/videos/Quads/barbell_squat.mp4',
    'assets/videos/Quads/leg_extensions.mp4',
    'assets/videos/Quads/leg_press.mp4',
    'assets/videos/Quads/lunges.mp4',
    'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/pallof_press.mp4',
    'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/russian_twists.mp4',
    'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/side_plank.mp4',
    'assets/videos/Rotational - Anti-Rotation (Obliques-Deep Core)/wood_chops.mp4',
    'assets/videos/Shoulder/Anterior/dumbbell_front_raises.mp4',
    'assets/videos/Shoulder/Anterior/overhead_press.mp4',
    'assets/videos/Shoulder/Anterior/standing_barbell_shoulder_press.mp4',
    'assets/videos/Shoulder/Medial/barbell_upright_row.mp4',
    'assets/videos/Shoulder/Medial/cable_lateral_raises.mp4',
    'assets/videos/Shoulder/Medial/dumbbell_cable_lateral_raises.mp4',
    'assets/videos/Shoulder/Medial/upright_rows.mp4',
    'assets/videos/Shoulder/Posterior/face_pulls_back.mp4',
    'assets/videos/Shoulder/Posterior/rear_delt_fly.mp4',
    'assets/videos/Spinal Flexion (Rectus Abdominis)/ab_wheel_rollouts.mp4',
    'assets/videos/Spinal Flexion (Rectus Abdominis)/cable_crunches.mp4',
    'assets/videos/Spinal Flexion (Rectus Abdominis)/hanging_leg_raises.mp4',
    'assets/videos/Spinal Flexion (Rectus Abdominis)/reverse_crunches.mp4',
    'assets/videos/Traps/barbell_deadlift.mp4',
    'assets/videos/Traps/barbell_dumbbell_shrugs.mp4',
    'assets/videos/Traps/rack_pulls.mp4',
    'assets/videos/Triceps/dumbbell_skull_crusher_opex_exercise_library.mp4',
    'assets/videos/Triceps/overhead_tricep_extension.mp4',
    'assets/videos/Triceps/tricep_pushdowns.mp4',
    // Fitness Journey Assets
    'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Rowing_Machine_Intervals_.mp4',
    'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stair_Master_Climbing.mp4',
    'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stationary_Bike_Sprints.mp4',
    'assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Treadmill_Sprints.mp4',
    'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Elliptical_Machine.mp4',
    'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Incline_Treadmill_Walk.mp4',
    'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Recumbent_Bike.mp4',
    'assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Rowing_Machine_at_Moderate_Pace.mp4',
    'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/High_Knees.mp4',
    'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jumping_Squats.mp4',
    'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jump_Rope.mp4',
    'assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Skater_Jumps.mp4',
    'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Assault_Bike.mp4',
    'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Brisk_Walking_Cooldown.mp4',
    'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Rowing_Machine_at_Moderate_Pace_.mp4',
    'assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/SkiErg_.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Chest_Press.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Leg_Press.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Bird_Dog.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Cat_-_Cow_Stretch.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Forearm_Plank.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Bodyweight_Squats.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Light_Stationary_Bike.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Standing_Stretch_Routine.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Swiss_Ball_Crunch.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Dumbbell_Bicep_Curls.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Light_Dumbbell_Romanian_Deadlift_.mp4',
    'assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Triceps_Dumbbell_Kickbacks.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Box_Step_up.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Goblet_Squats.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Walking_Lunge.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Wall_Sits.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Inverted_Row.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Light_Dumbbell_Shoulder_Press_.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Jumping_Lunges_.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Kettlebell_Swings.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Lightweight_Barbell_Squats.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/TRX_Rows.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Farmer\'s_Carries.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Hollow_Body_Hold.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Plank_Holds.mp4',
    'assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Suitcase_Carries.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Back_Squat.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Conventional_Deadlift_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Barbell_Overhead_Press.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Close_Grip_Barbell_Bench_Press_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Dumbbell_Weighted_Dip.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Incline_Barbell_Press_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Barbell_Pendlay_Rows_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Heavy_Dumbbell_Shrugs.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Weighted_Pull-Ups.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Kettlebell_Swing.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Medicine_Ball_Throws_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Power_Cleans.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Push_Press.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Good_Mornings.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Romanian_Deadlift_.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Farmers_Walk.mp4',
    'assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Glute-Ham_Raises.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Burpees.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Jumping_Jacks_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Kettlebell_Swings_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Mountain_Climbers.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Alternating_Dumbbell_Lunges.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Snatch_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Thrusters.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Renegade_Rows_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Battle_Ropes.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Box_Jumps.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Jump_Rope_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Medicine_Ball_Slams_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Bear_Crawls_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/High_Knees_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Plank_Jacks_.mp4',
    'assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Squat_Jumps_.mp4',
  ];

  XFile? _thumbnailImage;
  String? _selectedTemplatePath;
  List<Map<String, dynamic>> _users = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _assignToAll = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs
          .where((doc) => doc.data()['emailVerified'] == true)
          .map((doc) {
        final data = doc.data();
        final profileMap = data['profile'] is Map<String, dynamic>
            ? data['profile']
            : <String, dynamic>{};
        return {
          'id': doc.id,
          'email': (data['email'] ?? '').toString(),
          'displayName': (data['displayName'] ??
                  profileMap['displayName'] ??
                  profileMap['name'] ??
                  'Unknown')
              .toString(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading users: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _thumbnailImage = image;
          _selectedTemplatePath = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showThumbnailSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191919),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Thumbnail Source',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Upload from Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view, color: Colors.orange),
                title: const Text('Choose Template',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showTemplateSelector();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateSelector() {
    final templates = [
      'assets/thumbnails/Abs/abs_training_easy.png',
      'assets/thumbnails/Abs/abs_training_hard.png',
      'assets/thumbnails/Abs/abs_training_medium.png',
      'assets/thumbnails/Biceps/biceps_training_easy.png',
      'assets/thumbnails/Biceps/biceps_training_hard.png',
      'assets/thumbnails/Biceps/biceps_training_medium.png',
      'assets/thumbnails/Calves/calves_training_easy.png',
      'assets/thumbnails/Calves/calves_training_medium.png',
      'assets/thumbnails/Chest/chest_training_easy.png',
      'assets/thumbnails/Chest/chest_training_hard.png',
      'assets/thumbnails/Chest/chest_training_medium.png',
      'assets/thumbnails/Forearms/forearms_training_medium.png',
      'assets/thumbnails/Glutes & Hamstrings/glutes_hamstrings_training_easy.png',
      'assets/thumbnails/Glutes & Hamstrings/glutes_hamstrings_training_hard.png',
      'assets/thumbnails/Glutes & Hamstrings/glutes_hamstrings_training_medium.png',
      'assets/thumbnails/Quads/quads_training_easy.png',
      'assets/thumbnails/Quads/quads_training_hard.png',
      'assets/thumbnails/Quads/quads_training_medium.png',
      'assets/thumbnails/Rotational Core/rotational_core_training_easy.png',
      'assets/thumbnails/Rotational Core/rotational_core_training_hard.png',
      'assets/thumbnails/Rotational Core/rotational_core_training_medium.png',
      'assets/thumbnails/Shoulders/shoulders_training_easy.png',
      'assets/thumbnails/Shoulders/shoulders_training_hard.png',
      'assets/thumbnails/Shoulders/shoulders_training_medium.png',
      'assets/thumbnails/Traps/traps_training_easy.png',
      'assets/thumbnails/Traps/traps_training_hard.png',
      'assets/thumbnails/Triceps/triceps_training_easy.png',
      'assets/thumbnails/Triceps/triceps_training_hard.png',
      'assets/thumbnails/Triceps/triceps_training_medium.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191919),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Template',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTemplatePath = templates[index];
                        _thumbnailImage = null;
                      });
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        templates[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadThumbnail() async {
    if (_thumbnailImage == null) return null;

    try {
      final fileExtension = _thumbnailImage!.name.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final path = 'thumbnails/$fileName';

      if (kIsWeb) {
        final bytes = await _thumbnailImage!.readAsBytes();
        await _supabase.storage.from('community-posts').uploadBinary(
              path,
              bytes,
              fileOptions:
                  FileOptions(contentType: 'image/$fileExtension'),
            );
      } else {
        await _supabase.storage.from('community-posts').upload(
              path,
              File(_thumbnailImage!.path),
              fileOptions:
                  FileOptions(contentType: 'image/$fileExtension'),
            );
      }

      final urlResponse =
          _supabase.storage.from('community-posts').getPublicUrl(path);
      return urlResponse;
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload thumbnail');
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    
    for (int i = 0; i < _exercises.length; i++) {
      if (_exercises[i].videoAsset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select a video asset for Exercise ${i + 1}'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }
    if (_thumbnailImage == null && _selectedTemplatePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a thumbnail image or template'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? thumbnailUrl = _selectedTemplatePath;
      if (_thumbnailImage != null) {
        thumbnailUrl = await _uploadThumbnail();
        if (thumbnailUrl == null) {
          throw Exception("Thumbnail upload returned null.");
        }
      }

      final exercisesData = _exercises.map((e) => {
        'name': e.nameController.text.trim(),
        'description': e.descriptionController.text.trim(),
        'videoAsset': e.videoAsset,
        'requiresWeightInput': e.requiresWeightInput,
      }).toList();

      final workoutData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'level': _selectedLevel,
        'bodyFocus': _selectedBodyFocus,
        'exercises': exercisesData,
        'thumbnailUrl': thumbnailUrl,
        'assignToAll': _assignToAll,
        'assignedUserIds': _assignToAll ? [] : _selectedUserIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('custom_workouts').add(workoutData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Workout customized and saved successfully!'),
              backgroundColor: Colors.green),
        );
        // Clear form
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _thumbnailImage = null;
          _exercises.clear();
          _exercises.add(CustomExerciseEntry());
          _assignToAll = true;
          _selectedUserIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving workout: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============== SIDEBAR NAVIGATION ==============
  void _onNavTapped(int index) {
    if (index == 4) return; // Currently on Custom Workout screen

    final Widget page;
    if (index == 0) {
      page = const AdminDashboardScreen();
    } else if (index == 1) {
      page = const AdminUsersScreen();
    } else if (index == 2) {
      page = const AdminCommunityScreen();
    } else {
      page = const AdminFeedbackScreen();
    }

    Navigator.pushReplacement(
      context,
      buildAdminRoute(page),
    );
  }

  Future<void> _logoutAdmin() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: const Text('Logout Admin',
                style: TextStyle(color: Colors.white)),
            content: const Text(
                'Are you sure you want to log out of the admin panel?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldLogout) return;

    await _firebaseAuth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSidebarNavItem(String label, int index, IconData icon) {
    final isSelected = index == 4;

    return InkWell(
      onTap: () => _onNavTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.orange.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.white54,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSidebarNavigation() {
    return Container(
      width: 280,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings,
                    size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rockies Fitness Admin',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          _buildSidebarNavItem('Overview', 0, Icons.dashboard_outlined),
          _buildSidebarNavItem('Users', 1, Icons.people_outline),
          _buildSidebarNavItem('Community', 2, Icons.forum_outlined),
          _buildSidebarNavItem('Feedback', 3, Icons.rate_review_outlined),
          _buildSidebarNavItem('Custom Workout', 4, Icons.fitness_center),
          const Spacer(),
          InkWell(
            onTap: _logoutAdmin,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.red, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== UI COMPONENTS ==============

  Widget _buildTextField(
      String label, TextEditingController controller, int maxLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showSelectionBottomSheet(String title, String currentValue, List<String> items, Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191919),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select $title',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const Divider(color: Colors.white10, height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      final isSelected = item == currentValue;
                      return ListTile(
                        title: Text(item, style: TextStyle(color: isSelected ? Colors.orange : Colors.white)),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
                        onTap: () {
                          onChanged(item);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSelectionBottomSheet(label, value, items, onChanged),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select $label' : value,
                    style: TextStyle(
                      color: value.isEmpty ? Colors.white54 : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExerciseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Exercises',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _exercises.add(CustomExerciseEntry());
                });
              },
              icon: const Icon(Icons.add, color: Colors.orange),
              label: const Text('Add Exercise', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._exercises.asMap().entries.map((entry) {
          int index = entry.key;
          CustomExerciseEntry exercise = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exercise ${index + 1}',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                    if (_exercises.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            exercise.dispose();
                            _exercises.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Exercise Name', exercise.nameController, 1),
                _buildTextField('Description', exercise.descriptionController, 3),
                _buildVideoSelector(exercise),
                SwitchListTile(
                  title: const Text('Requires Weight Input',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text(
                      'Turn off if this is a bodyweight exercise.',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  activeColor: Colors.orange,
                  value: exercise.requiresWeightInput,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      exercise.requiresWeightInput = val;
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showVideoSelectionBottomSheet(CustomExerciseEntry exercise) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191919),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredAssets = _videoAssets
                .where((asset) => asset
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search video assets...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.orange),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = filteredAssets[index];
                          final fileName = asset.split('/').last;
                          return ListTile(
                            title: Text(fileName, style: const TextStyle(color: Colors.white)),
                            leading: const Icon(Icons.video_library, color: Colors.orange),
                            onTap: () {
                              setState(() {
                                exercise.videoAsset = asset;
                                if (exercise.nameController.text.trim().isEmpty) {
                                  final name = fileName.replaceAll('.mp4', '');
                                  final formattedName = name.split('_').map((word) {
                                    if (word.isEmpty) return '';
                                    return word[0].toUpperCase() + word.substring(1);
                                  }).join(' ');
                                  exercise.nameController.text = formattedName;
                                }
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVideoSelector(CustomExerciseEntry exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Video Asset',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showVideoSelectionBottomSheet(exercise),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.videoAsset?.split('/').last ?? 'Select a Video',
                    style: TextStyle(
                      color: exercise.videoAsset != null ? Colors.white : Colors.white54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUserSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assign to Users',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Assign to All Users',
              style: TextStyle(color: Colors.white)),
          activeColor: Colors.orange,
          value: _assignToAll,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              _assignToAll = val;
            });
          },
        ),
        if (!_assignToAll) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isSelected = _selectedUserIds.contains(user['id']);
                      return CheckboxListTile(
                        title: Text(user['displayName'],
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(user['email'],
                            style: const TextStyle(color: Colors.white54)),
                        value: isSelected,
                        activeColor: Colors.orange,
                        checkColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(user['id']);
                            } else {
                              _selectedUserIds.remove(user['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Workout Title', _titleController, 1),
          _buildTextField('Description', _descriptionController, 3),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Level',
                  _selectedLevel,
                  _levels,
                  (val) => setState(() => _selectedLevel = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Body Focus',
                  _selectedBodyFocus,
                  _bodyFocusOptions,
                  (val) => setState(() => _selectedBodyFocus = val!),
                ),
              ),
            ],
          ),
          _buildExerciseSection(),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thumbnail Image',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('(Recommended: 16:9 ratio e.g. 1280x720)',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: (_thumbnailImage == null && _selectedTemplatePath == null)
                ? _showThumbnailSourceModal
                : null,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: (_thumbnailImage != null || _selectedTemplatePath != null)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: _thumbnailImage != null
                                            ? (kIsWeb
                                                ? Image.network(_thumbnailImage!.path)
                                                : Image.file(File(_thumbnailImage!.path)))
                                            : Image.asset(_selectedTemplatePath!),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: _thumbnailImage != null
                                ? (kIsWeb
                                    ? Image.network(_thumbnailImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(_thumbnailImage!.path), fit: BoxFit.cover))
                                : Image.asset(_selectedTemplatePath!, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _thumbnailImage = null;
                                _selectedTemplatePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 40, color: Colors.white54),
                        SizedBox(height: 8),
                        Text('Tap to select thumbnail',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _buildUserSelection(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _saveWorkout,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Workout',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _deleteWorkout(String workoutId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191919),
        title: const Text('Delete Workout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this custom workout? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('custom_workouts').doc(workoutId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildManageTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('custom_workouts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No custom workouts found.', style: TextStyle(color: Colors.white54)),
          );
        }

        final workouts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final doc = workouts[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              color: const Color(0xFF191919),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: data['thumbnailUrl'] != null 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(data['thumbnailUrl'], width: 60, height: 60, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.fitness_center, color: Colors.orange, size: 40),
                title: Text(data['title'] ?? 'Unknown Workout', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${data['bodyFocus'] ?? ''} • ${data['level'] ?? ''}', style: const TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteWorkout(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildBody() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Workouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your custom workouts or create new ones.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white54,
            dividerColor: Colors.white10,
            tabs: [
              Tab(text: 'Create Workout'),
              Tab(text: 'Manage Workouts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCreateTab(),
                _buildManageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Row(
          children: [
            _buildWebSidebarNavigation(),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Customize Workout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
        ],
      ),
    );
  }
}
