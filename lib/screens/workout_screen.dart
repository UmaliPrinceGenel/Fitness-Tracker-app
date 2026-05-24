import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/fitness_journey_workouts.dart';
import 'fitness_journey_detail_screen.dart';
import 'progress_tracking_screen.dart'; // Import the new progress tracking screen
import '../data/exercise_data2.dart'; // Import workout data
import '../models/workout_model.dart'; // Import workout model
import '../services/journey_progress_service.dart';
import '../services/workout_goal_service.dart';
import 'workout_detail_screen.dart'; // Import workout detail screen
import '../widgets/chatbot_launcher.dart';
import '../theme/app_colors.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    this.showChatbot = true,
    this.onDataChanged,
  });

  final bool showChatbot;
  final VoidCallback? onDataChanged;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  int _selectedJourneyIndex = 0;
  int _selectedMonthlyTrackingView = 0;
  int _recommendedJourneyIndex = 4;
  final ScrollController _journeyScrollController = ScrollController();
  String _recommendedGoalType = generalFitnessGoal;
  String _recommendationReason =
      'Begin with a balanced plan to build consistency.';
  Set<String> _completedJourneyIds = <String>{};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<int> _monthlyCategoryCounts = [
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // Total count for each category
  List<int> _monthlyCheatedCategoryCounts = [
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // Cheated count for each category
  List<int> _monthlyJourneyCounts = [0, 0, 0, 0, 0];
  List<int> _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
  bool _isLoading = true;
  List<Workout> _customWorkouts = [];

  // List of tab titles and corresponding colors
  final List<String> _tabTitles = [
    "Chest",
    "Arms",
    "Core",
    "Lower Body",
    "Shoulders",
    "Back",
  ];
  final List<Color> _categoryColors = [
    Colors.red,                    // Chest
    Colors.blue,                   // Arms
    Colors.green,                  // Core
    Colors.orange,                 // Lower Body
    Colors.purple,                 // Shoulders
    const Color(0xFF00BCD4),       // Back (cyan)
  ];
  final List<String> _monthlyJourneyTitles = const [
    'Weight Loss',
    'Cardio',
    'Strength & Power',
    'Muscular Endurance',
    'Health & Wellness',
  ];
  final List<String> _monthlyJourneyIds = const [
    weightLossJourneyId,
    cardioJourneyId,
    strengthPowerJourneyId,
    muscularEnduranceJourneyId,
    healthWellnessJourneyId,
  ];
  final List<Color> _monthlyJourneyColors = const [
    Color(0xFFFF6B35),
    Color(0xFF2EC4E6),
    Color(0xFF8FA3BF),
    Color(0xFF5BE7A9),
    Color(0xFFF4D58D),
  ];
  final List<FitnessJourneyPreview> _journeys = const [
    FitnessJourneyPreview(
      journeyId: weightLossJourneyId,
      title: 'Weight Loss',
      durationLabel: '4 WORKOUTS',
      headline: 'Burn\nLean',
      description: 'High-energy circuits that keep calories burning.',
      buttonLabel: 'Open Journey',
      icon: Icons.local_fire_department_rounded,
      accentColor: Color(0xFFFF6B35),
      buttonTextColor: Color(0xFFFF6B35),
      gradientStart: Color(0xFF5C2427),
      gradientEnd: Color(0xFF231318),
      thumbnailAsset:
          'assets/thumbnails/Journeys/journey_weight_loss_thumb.png',
    ),
    FitnessJourneyPreview(
      journeyId: cardioJourneyId,
      title: 'Cardio',
      durationLabel: '4 WORKOUTS',
      headline: 'Heart\nRush',
      description: 'Intervals and endurance sessions for stamina.',
      buttonLabel: 'Open Journey',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFF2EC4E6),
      buttonTextColor: Color(0xFF1EA7D1),
      gradientStart: Color(0xFF1C4461),
      gradientEnd: Color(0xFF0C1E2E),
      thumbnailAsset: 'assets/thumbnails/Journeys/journey_cardio_thumb.png',
    ),
    FitnessJourneyPreview(
      journeyId: strengthPowerJourneyId,
      title: 'Strength & Power',
      durationLabel: '5 WORKOUTS',
      headline: 'Raw\nPower',
      description: 'Compound lifts and explosive training sessions.',
      buttonLabel: 'Open Journey',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xFF8FA3BF),
      buttonTextColor: Color(0xFF5E7393),
      gradientStart: Color(0xFF2F3847),
      gradientEnd: Color(0xFF10151C),
      thumbnailAsset:
          'assets/thumbnails/Journeys/journey_strength_power_thumb.png',
    ),
    FitnessJourneyPreview(
      journeyId: muscularEnduranceJourneyId,
      title: 'Muscular Endurance',
      durationLabel: '4 WORKOUTS',
      headline: 'Keep\nGoing',
      description: 'High-rep plans built for stamina and control.',
      buttonLabel: 'Open Journey',
      icon: Icons.timelapse_rounded,
      accentColor: Color(0xFF5BE7A9),
      buttonTextColor: Color(0xFF35C98A),
      gradientStart: Color(0xFF24504B),
      gradientEnd: Color(0xFF102525),
      thumbnailAsset:
          'assets/thumbnails/Journeys/journey_muscular_endurance_thumb.png',
    ),
    FitnessJourneyPreview(
      journeyId: healthWellnessJourneyId,
      title: 'Health & Wellness',
      durationLabel: '4 WORKOUTS',
      headline: 'Daily\nReset',
      description: 'Beginner-friendly sessions for everyday fitness.',
      buttonLabel: 'Open Journey',
      icon: Icons.spa_rounded,
      accentColor: Color(0xFFF4D58D),
      buttonTextColor: Color(0xFF8E7340),
      gradientStart: Color(0xFF59604A),
      gradientEnd: Color(0xFF242A20),
      thumbnailAsset:
          'assets/thumbnails/Journeys/journey_health_wellness_thumb.png',
    ),
  ];

  String _currentMonthLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  int _journeyIndexForGoal(String goalType) {
    return _journeys.indexWhere(
      (journey) => goalForJourneyId(journey.journeyId) == normalizeGoalType(goalType),
    );
  }

  FitnessJourneyPreview get _recommendedJourney {
    if (_recommendedJourneyIndex >= 0 &&
        _recommendedJourneyIndex < _journeys.length) {
      return _journeys[_recommendedJourneyIndex];
    }
    final fallbackIndex = _journeyIndexForGoal(_recommendedGoalType);
    return _journeys[fallbackIndex >= 0 ? fallbackIndex : 0];
  }

  bool get _allJourneysCompleted =>
      _completedJourneyIds.length >= _journeys.length && _journeys.isNotEmpty;

  bool _isJourneyCompleted(String journeyId) =>
      _completedJourneyIds.contains(journeyId);

  int _defaultRecommendationIndex() {
    final generalFitnessIndex = _journeyIndexForGoal(generalFitnessGoal);
    if (generalFitnessIndex >= 0) {
      return generalFitnessIndex;
    }
    return _journeys.isEmpty ? 0 : 0;
  }

  ({int index, String goalType, String reason}) _resolveAutomaticRecommendation({
    required Map<String, dynamic>? userData,
    required QuerySnapshot<Map<String, dynamic>> journeyProgressSnapshot,
    required QuerySnapshot<Map<String, dynamic>> doneInfosSnapshot,
  }) {
    final selectedJourneyId = userData?['selectedJourneyId']?.toString();
    final selectedGoalType = normalizeGoalType(
      userData?['selectedGoalType']?.toString(),
    );
    final completedJourneyIds = journeyProgressSnapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['isCompleted'] == true ||
              (data['status']?.toString() == 'completed');
        })
        .map((doc) => doc.id)
        .toSet();
    final allJourneysCompleted =
        completedJourneyIds.length >= _journeys.length && _journeys.isNotEmpty;

    final activeJourneyDoc = journeyProgressSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
      (doc) => doc != null && doc.data()['status']?.toString() == 'in_progress',
      orElse: () => null,
    );
    if (activeJourneyDoc != null) {
      final activeIndex = _journeys.indexWhere(
        (journey) => journey.journeyId == activeJourneyDoc.id,
      );
      if (activeIndex >= 0) {
        return (
          index: activeIndex,
          goalType: goalForJourneyId(activeJourneyDoc.id),
          reason: 'Continue your active journey first.',
        );
      }
    }

    final cleanGoalCounts = <String, int>{};
    for (final doc in doneInfosSnapshot.docs) {
      final data = doc.data();
      if (data['isCheated'] == true) {
        continue;
      }
      final journeyId = data['journeyId']?.toString();
      if (journeyId == null || journeyId.trim().isEmpty) {
        continue;
      }

      final primaryGoal = normalizeGoalType(data['primaryGoal']?.toString());
      cleanGoalCounts[primaryGoal] = (cleanGoalCounts[primaryGoal] ?? 0) + 1;
    }

    String resolvedGoalType = selectedGoalType;
    if (cleanGoalCounts.isNotEmpty) {
      resolvedGoalType = cleanGoalCounts.entries
          .reduce((current, next) => current.value >= next.value ? current : next)
          .key;
    }

    final recommendedPool = _journeys
        .asMap()
        .entries
        .where(
          (entry) => goalForJourneyId(entry.value.journeyId) == resolvedGoalType,
        )
        .toList(growable: false);

    for (final entry in recommendedPool) {
      if (!completedJourneyIds.contains(entry.value.journeyId)) {
        return (
          index: entry.key,
          goalType: resolvedGoalType,
          reason: cleanGoalCounts.isNotEmpty
              ? 'Recommended from your workout history.'
              : 'Recommended from your current journey setup.',
        );
      }
    }

    if (selectedJourneyId != null && selectedJourneyId.isNotEmpty) {
      final selectedIndex = _journeys.indexWhere(
        (journey) => journey.journeyId == selectedJourneyId,
      );
      if (selectedIndex >= 0) {
        return (
          index: selectedIndex,
          goalType: goalForJourneyId(selectedJourneyId),
          reason: allJourneysCompleted
              ? 'All journeys are complete, so this is kept ready for replay.'
              : 'This matches your saved journey selection.',
        );
      }
    }

    if (recommendedPool.isNotEmpty) {
      return (
        index: recommendedPool.first.key,
        goalType: resolvedGoalType,
        reason: 'This is your closest match right now.',
      );
    }

    final fallbackIndex = _defaultRecommendationIndex();
    return (
      index: fallbackIndex,
      goalType: goalForJourneyId(_journeys[fallbackIndex].journeyId),
      reason: 'Start here for a balanced and beginner-friendly path.',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMonthlyCategoryData();
    _loadSelectedJourney();
    _loadCustomWorkouts();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _journeyScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when the app resumes (e.g., when returning from workout detail screen)
      _loadMonthlyCategoryData();
      _loadSelectedJourney();
      _loadCustomWorkouts();
    }
  }

  int? _getCategoryIndex(String bodyFocus) {
    final normalizedFocus = bodyFocus.toLowerCase().trim();
    if (normalizedFocus == "chest") {
      return 0;
    }
    if (normalizedFocus == "arm" ||
        normalizedFocus == "arms" ||
        normalizedFocus == "triceps" ||
        normalizedFocus == "biceps" ||
        normalizedFocus == "forearms") {
      return 1;
    }
    if (normalizedFocus == "abs" || normalizedFocus == "core") {
      return 2;
    }
    if (normalizedFocus == "legs" ||
        normalizedFocus == "lower body" ||
        normalizedFocus == "calves" ||
        normalizedFocus == "glutes & hamstrings") {
      return 3;
    }
    if (normalizedFocus == "shoulders" || normalizedFocus == "traps") {
      return 4;
    }
    if (normalizedFocus == "back" ||
        normalizedFocus == "lats" ||
        normalizedFocus == "mid-back") {
      return 5;
    }
    return null;
  }

  int? _getJourneyIndex({
    String? journeyId,
    String? journeyName,
    String? workoutTitle,
  }) {
    if (journeyId != null && journeyId.isNotEmpty) {
      final idIndex = _monthlyJourneyIds.indexOf(journeyId);
      if (idIndex >= 0) {
        return idIndex;
      }
    }

    if (journeyName != null && journeyName.isNotEmpty) {
      final normalizedName = journeyName.toLowerCase().trim();
      final nameIndex = _monthlyJourneyTitles.indexWhere(
        (title) => title.toLowerCase() == normalizedName,
      );
      if (nameIndex >= 0) {
        return nameIndex;
      }
    }

    if (workoutTitle != null && workoutTitle.isNotEmpty) {
      for (int i = 0; i < _monthlyJourneyIds.length; i++) {
        final workouts = getJourneyWorkouts(_monthlyJourneyIds[i]);
        final hasMatch = workouts.any((workout) => workout.title == workoutTitle);
        if (hasMatch) {
          return i;
        }
      }
    }

    return null;
  }

  List<String> get _activeMonthlyTitles => _selectedMonthlyTrackingView == 0
      ? _tabTitles
      : _monthlyJourneyTitles;

  List<Color> get _activeMonthlyColors => _selectedMonthlyTrackingView == 0
      ? _categoryColors
      : _monthlyJourneyColors;

  List<int> get _activeMonthlyCounts => _selectedMonthlyTrackingView == 0
      ? _monthlyCategoryCounts
      : _monthlyJourneyCounts;

  List<int> get _activeMonthlyCheatedCounts =>
      _selectedMonthlyTrackingView == 0
          ? _monthlyCheatedCategoryCounts
          : _monthlyJourneyCheatedCounts;

  List<PieChartSectionData> _buildMonthlyChartSections({
    required bool compact,
  }) {
    final sections = <PieChartSectionData>[];
    final cleanRadius = compact ? 42.0 : 54.0;
    final cleanFontSize = compact ? 12.0 : 14.0;
    final activeCounts = _activeMonthlyCounts;
    final activeColors = _activeMonthlyColors;

    for (int i = 0; i < activeCounts.length; i++) {
      final cleanCount = activeCounts[i];

      if (cleanCount > 0) {
        sections.add(
          PieChartSectionData(
            color: activeColors[i],
            value: cleanCount.toDouble(),
            title: '$cleanCount',
            radius: cleanRadius,
            titleStyle: TextStyle(
              fontSize: cleanFontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildLegendItem(int index, {required bool compact}) {
    final totalCount = _activeMonthlyCounts[index];
    final label = _activeMonthlyTitles[index];
    final color = _activeMonthlyColors[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $totalCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalCount workouts',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutMetaChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor.withOpacity(0.5),
                width: 1,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildWorkoutDetails(
    Workout workout, {
    required bool isCompleted,
    required bool isCheated,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          workout.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (workout.journeyName != null)
              _buildWorkoutMetaChip(
                label: workout.journeyName!,
                backgroundColor: const Color(0xFFFF6B35).withOpacity(0.15),
                textColor: const Color(0xFFFF8A5C),
              ),
            _buildWorkoutMetaChip(
              label: "${workout.exerciseList.length} exercises",
              backgroundColor: Colors.white.withOpacity(0.06),
              textColor: Colors.white70,
            ),
            _buildWorkoutMetaChip(
              label: workout.level,
              backgroundColor: _getLevelColor(workout.level).withOpacity(0.15),
              textColor: _getLevelColor(workout.level),
            ),
          ],
        ),
      ],
    );
  }

  // Load monthly category data from Firestore
  Future<void> _loadMonthlyCategoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get the start of the current month
        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        DateTime endOfMonth = DateTime(
          now.year,
          now.month + 1,
          0,
        ); // Last day of current month

        // Query completed workouts for the current month
        final completedWorkoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .where('completedAt', isGreaterThanOrEqualTo: startOfMonth)
            .where(
              'completedAt',
              isLessThan: endOfMonth.add(const Duration(days: 1)),
            )
            .get();

        // Initialize category counts with zeros
        List<int> categoryCounts = [0, 0, 0, 0, 0, 0];
        List<int> cheatedCategoryCounts = [0, 0, 0, 0, 0, 0];
        List<int> journeyCounts = [0, 0, 0, 0, 0];
        List<int> cheatedJourneyCounts = [0, 0, 0, 0, 0];

        // Process completed workouts to calculate category counts
        for (var doc in completedWorkoutsSnapshot.docs) {
          final data = doc.data();
          final workoutTitle = data['title'] as String?;
          final storedBodyFocus = data['bodyFocus'] as String?;
          final journeyId = data['journeyId'] as String?;
          final journeyName = data['journeyName'] as String?;
          String bodyFocus = storedBodyFocus ?? '';

          if (bodyFocus.isEmpty && workoutTitle != null) {
            final workout = exerciseWorkouts.firstWhere(
              (w) => w.title == workoutTitle,
              orElse: () => exerciseWorkouts[0],
            );
            bodyFocus = workout.bodyFocus;
          }

          // Check if the workout was cheated
          final bool isCheated = data['isCheated'] == true;
          final int? categoryIndex = _getCategoryIndex(bodyFocus);

          if (categoryIndex != null) {
            categoryCounts[categoryIndex]++;
            if (isCheated) {
              cheatedCategoryCounts[categoryIndex]++;
            }
          }

          final journeyIndex = _getJourneyIndex(
            journeyId: journeyId,
            journeyName: journeyName,
            workoutTitle: workoutTitle,
          );
          if (journeyIndex != null) {
            journeyCounts[journeyIndex]++;
            if (isCheated) {
              cheatedJourneyCounts[journeyIndex]++;
            }
          }
        }

        setState(() {
          _monthlyCategoryCounts = categoryCounts;
          _monthlyCheatedCategoryCounts = cheatedCategoryCounts;
          _monthlyJourneyCounts = journeyCounts;
          _monthlyJourneyCheatedCounts = cheatedJourneyCounts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _monthlyCategoryCounts = [0, 0, 0, 0, 0, 0];
          _monthlyCheatedCategoryCounts = [0, 0, 0, 0, 0, 0];
          _monthlyJourneyCounts = [0, 0, 0, 0, 0];
          _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading monthly category data: $e');
      setState(() {
        _monthlyCategoryCounts = [0, 0, 0, 0, 0, 0];
        _monthlyCheatedCategoryCounts = [0, 0, 0, 0, 0, 0];
        _monthlyJourneyCounts = [0, 0, 0, 0, 0];
        _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomWorkouts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore.collection('custom_workouts').get();
      List<Workout> customWorkouts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final assignToAll = data['assignToAll'] == true;
        final assignedUserIds = (data['assignedUserIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        if (assignToAll || assignedUserIds.contains(user.uid)) {
          List<Exercise> exerciseList = [];
          if (data['exercises'] != null) {
            final exercisesData = data['exercises'] as List<dynamic>;
            for (var exData in exercisesData) {
              exerciseList.add(Exercise(
                name: exData['name'] ?? 'Custom Exercise',
                baseCaloriesPerMinute: 10,
                duration: 300,
                description: exData['description'] ?? '',
                customVideoAsset: exData['videoAsset'],
                requiresWeightInputOverride: exData['requiresWeightInput'] as bool?,
              ));
            }
          } else {
            // Fallback for older custom workouts that only had one video at the top level
            exerciseList.add(Exercise(
              name: data['title'] ?? 'Custom Workout',
              baseCaloriesPerMinute: 10,
              duration: 300,
              description: data['description'] ?? '',
              customVideoAsset: data['videoAsset'],
            ));
          }

          int totalDurationMin = (exerciseList.length * 300) ~/ 60;
          String durationLabel = '\$totalDurationMin min';

          final workout = Workout(
            id: doc.id,
            title: data['title'] ?? 'Custom Workout',
            duration: durationLabel,
            exercises: '\${exerciseList.length}',
            level: data['level'] ?? 'Medium',
            bodyFocus: data['bodyFocus'] ?? 'Chest',
            videoAsset: data['videoAsset'] ?? '', // Fallback
            thumbnailAsset: data['thumbnailUrl'] ?? 'assets/thumbnails/custom_workout.jpg',
            description: data['description'],
            exerciseList: exerciseList,
          );
          customWorkouts.add(workout);
        }
      }

      if (mounted) {
        setState(() {
          _customWorkouts = customWorkouts;
        });
      }
    } catch (e) {
      print('Error loading custom workouts: \$e');
    }
  }

  Future<void> _loadSelectedJourney() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final journeyProgressSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journey_progress')
          .get();
      final doneInfosSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('doneInfos')
          .get();
      final data = userDoc.data();
      final selectedJourneyId = data?['selectedJourneyId'] as String?;
      final completedJourneyIds = journeyProgressSnapshot.docs
          .where((doc) {
            final progress = doc.data();
            return progress['isCompleted'] == true ||
                (progress['status']?.toString() == 'completed');
          })
          .map((doc) => doc.id)
          .toSet();
      final recommendation = _resolveAutomaticRecommendation(
        userData: data,
        journeyProgressSnapshot: journeyProgressSnapshot,
        doneInfosSnapshot: doneInfosSnapshot,
      );

      int selectedIndex = _journeys.indexWhere(
        (journey) => journey.journeyId == selectedJourneyId,
      );

      if (selectedIndex < 0) {
        selectedIndex = recommendation.index;
      }

      if (selectedIndex >= 0 && mounted) {
        setState(() {
          _selectedJourneyIndex = selectedIndex;
          _recommendedJourneyIndex = recommendation.index;
          _recommendedGoalType = recommendation.goalType;
          _recommendationReason = recommendation.reason;
          _completedJourneyIds = completedJourneyIds;
        });
      } else if (mounted) {
        setState(() {
          _recommendedJourneyIndex = recommendation.index;
          _recommendedGoalType = recommendation.goalType;
          _recommendationReason = recommendation.reason;
          _completedJourneyIds = completedJourneyIds;
        });
      }
    } catch (e) {
      print('Error loading selected journey: $e');
    }
  }

  Future<void> _saveSelectedJourney(
    FitnessJourneyPreview journey, {
    String? overrideGoalType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final resolvedGoalType = normalizeGoalType(
        overrideGoalType ?? goalForJourneyId(journey.journeyId),
      );

      await JourneyProgressService.syncJourneyProgressForUser(
        firestore: _firestore,
        uid: user.uid,
        journeyId: journey.journeyId,
        journeyName: journey.title,
        isSelected: true,
        markStarted: false,
      );

      await _firestore.collection('users').doc(user.uid).set({
        'selectedJourney': journey.title,
        'selectedJourneyId': journey.journeyId,
        'selectedJourneyName': journey.title,
        'selectedGoalType': resolvedGoalType,
        'selectedGoalLabel': goalLabel(resolvedGoalType),
        'journeyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving selected journey: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = screenWidth < 360;
    final horizontalPadding = isCompactScreen ? 12.0 : 16.0;

    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            "Workout",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false, // Prevents the automatic back button
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadMonthlyCategoryData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideLayout = kIsWeb && constraints.maxWidth >= 1180;
                  final contentMaxWidth = kIsWeb
                      ? (constraints.maxWidth >= 1440
                            ? 1320.0
                            : constraints.maxWidth.toDouble())
                      : constraints.maxWidth.toDouble();

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        horizontalPadding,
                        horizontalPadding,
                        120, // Extra bottom padding to clear the floating navbar
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isWideLayout)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _buildMonthlyTrackingCard(),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 8,
                                      child: _buildJourneySection(),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildMonthlyTrackingCard(),
                                const SizedBox(height: 20),
                                _buildJourneySection(),
                              ],
                              const SizedBox(height: 24),
                              const Text(
                                "Body Focus",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildBodyFocusTabs(),
                              const SizedBox(height: 20),
                              _buildWorkoutList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showChatbot)
            const ChatbotLauncher(title: 'Workout Chat'),
        ],
      ),
    );
  }

  // Body Focus Tabs Choices
  Widget _buildTab(String title, int index) {
    return _AnimatedCategoryTab(
      title: title,
      isSelected: _selectedTabIndex == index,
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
    );
  }

  Widget _buildMonthlyTrackingCard() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isCompactScreen ? 320 : 350,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1F24),
            Color(0xFF141416),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompactScreen ? 16 : 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactCard = constraints.maxWidth < 360;
            final desktopCard = kIsWeb && constraints.maxWidth >= 760;
            final chartHeight = desktopCard
                ? 220.0
                : compactCard
                    ? 160.0
                    : 190.0;
            // Ensure 2 columns fit comfortably even with floating point errors
            final legendWidth = (constraints.maxWidth - 16) / 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Category Tracking",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compactCard ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentMonthLabel(),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: compactCard ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMonthlyTrackingView = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _selectedMonthlyTrackingView == 0
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF8C42), Color(0xFFFF5200)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedMonthlyTrackingView == 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF5200).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Body Focus",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedMonthlyTrackingView == 0
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: compactCard ? 13 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMonthlyTrackingView = 1;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _selectedMonthlyTrackingView == 1
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF8C42), Color(0xFFFF5200)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedMonthlyTrackingView == 1
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF5200).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Journeys",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedMonthlyTrackingView == 1
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: compactCard ? 13 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: chartHeight,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF5200),
                            ),
                          ),
                        )
                      : _hasData()
                          ? PieChart(
                              PieChartData(
                                sections: _buildMonthlyChartSections(
                                  compact: compactCard,
                                ),
                                centerSpaceRadius: compactCard ? 28 : 36,
                                sectionsSpace: 4,
                                pieTouchData: PieTouchData(enabled: true),
                              ),
                            )
                          : const Center(
                              child: Text(
                                "Complete a workout to see your progress",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_activeMonthlyTitles.length, (i) {
                    return SizedBox(
                      width: legendWidth,
                      child: _buildLegendItem(i, compact: compactCard),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C42), Color(0xFFFF5200)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5200).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressTrackingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.insights, color: Colors.white),
                    label: Text(
                      "Open Progress Tracking",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compactCard ? 14 : 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBodyFocusTabs() {
    return SizedBox(
      height: 42,
      child: ScrollConfiguration(
        behavior: const _WorkoutDesktopScrollBehavior(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabTitles.length, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == _tabTitles.length - 1 ? 0 : 8),
                child: _buildTab(_tabTitles[index], index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneySection() {
    final recommendedJourney = _recommendedJourney;
    final recommendedJourneyCompleted =
        _isJourneyCompleted(recommendedJourney.journeyId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = kIsWeb && constraints.maxWidth >= 900;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fitness Journey",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F1F24),
                    Color(0xFF141416),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Recommended Journey",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _allJourneysCompleted
                        ? "All journeys are complete. You can still replay any journey anytime."
                        : "The app automatically highlights the journey that fits your current progress best.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          recommendedJourney.accentColor.withOpacity(0.1),
                          recommendedJourney.accentColor.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: recommendedJourney.accentColor.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalLabel(_recommendedGoalType),
                          style: TextStyle(
                            color: recommendedJourney.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommendedJourney.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _allJourneysCompleted
                              ? '${recommendedJourney.description} Replay any journey whenever you want.'
                              : recommendedJourneyCompleted
                                  ? '${recommendedJourney.description} This journey is already complete, but you can start it again anytime.'
                                  : recommendedJourney.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recommendationReason,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (kIsWeb)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isDesktop
                          ? "Use the arrow buttons or drag with your mouse to browse journeys."
                          : "Swipe or drag to browse journeys.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _scrollJourneyCards(forward: false),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white70,
                    tooltip: 'Previous journeys',
                  ),
                  IconButton(
                    onPressed: () => _scrollJourneyCards(forward: true),
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    color: Colors.white70,
                    tooltip: 'Next journeys',
                  ),
                ],
              )
            else
              Text(
                "Swipe to browse journeys.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.56),
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 310,
              child: ScrollConfiguration(
                behavior: const _WorkoutDesktopScrollBehavior(),
                child: kIsWeb
                    ? Scrollbar(
                        controller: _journeyScrollController,
                        thumbVisibility: isDesktop,
                        interactive: true,
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        child: ListView.separated(
                          controller: _journeyScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(bottom: isDesktop ? 14 : 0),
                          itemCount: _journeys.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final journey = _journeys[index];
                            final isSelected = index == _selectedJourneyIndex;
                            final isRecommended = index == _recommendedJourneyIndex;
                            final isCompletedJourney = _isJourneyCompleted(
                              journey.journeyId,
                            );

                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  _selectedJourneyIndex = index;
                                });
                                await _saveSelectedJourney(journey);

                                if (!mounted) {
                                  return;
                                }

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FitnessJourneyDetailScreen(
                                      journeyId: journey.journeyId,
                                      title: journey.title,
                                      durationLabel: journey.durationLabel,
                                      headline: journey.headline,
                                      description: journey.description,
                                      thumbnailAsset: journey.thumbnailAsset,
                                      icon: journey.icon,
                                      accentColor: journey.accentColor,
                                      buttonTextColor: journey.buttonTextColor,
                                      gradientStart: journey.gradientStart,
                                      gradientEnd: journey.gradientEnd,
                                    ),
                                  ),
                                );

                                await _loadSelectedJourney();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: isDesktop ? 320 : 292,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? journey.accentColor
                                        : Colors.white.withOpacity(0.08),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: journey.accentColor.withOpacity(
                                        isSelected ? 0.18 : 0.08,
                                      ),
                                      blurRadius: isSelected ? 18 : 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        journey.thumbnailAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildJourneyFallback(journey);
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.08),
                                              Colors.black.withOpacity(0.18),
                                              Colors.black.withOpacity(0.76),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            stops: const [0.0, 0.48, 1.0],
                                            colors: [
                                              Colors.black.withOpacity(0.62),
                                              Colors.black.withOpacity(0.34),
                                              Colors.black.withOpacity(0.08),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(22),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.black.withOpacity(0.6),
                                                    Colors.black.withOpacity(0.2),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.24),
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isRecommended
                                                    ? 'RECOMMENDED'
                                                    : isCompletedJourney
                                                        ? 'COMPLETED'
                                                        : journey.durationLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              journey.headline.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5,
                                                height: 1.0,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black87,
                                                    blurRadius: 24,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              journey.description,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                height: 1.3,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 16,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white,
                                                    Colors.white.withOpacity(0.9),
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    journey.buttonLabel,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: journey.buttonTextColor,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 15,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: journey.buttonTextColor,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : ListView.separated(
                        controller: _journeyScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _journeys.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final journey = _journeys[index];
                          final isSelected = index == _selectedJourneyIndex;
                          final isRecommended = index == _recommendedJourneyIndex;
                      final isCompletedJourney = _isJourneyCompleted(
                        journey.journeyId,
                      );

                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _selectedJourneyIndex = index;
                          });
                          await _saveSelectedJourney(journey);

                          if (!mounted) {
                            return;
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FitnessJourneyDetailScreen(
                                journeyId: journey.journeyId,
                                title: journey.title,
                                durationLabel: journey.durationLabel,
                                headline: journey.headline,
                                description: journey.description,
                                thumbnailAsset: journey.thumbnailAsset,
                                icon: journey.icon,
                                accentColor: journey.accentColor,
                                buttonTextColor: journey.buttonTextColor,
                                gradientStart: journey.gradientStart,
                                gradientEnd: journey.gradientEnd,
                              ),
                            ),
                          );

                          await _loadSelectedJourney();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isDesktop ? 320 : 292,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? journey.accentColor
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: journey.accentColor.withOpacity(
                                  isSelected ? 0.18 : 0.08,
                                ),
                                blurRadius: isSelected ? 18 : 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  journey.thumbnailAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildJourneyFallback(journey);
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.08),
                                        Colors.black.withOpacity(0.18),
                                        Colors.black.withOpacity(0.76),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: const [0.0, 0.48, 1.0],
                                      colors: [
                                        Colors.black.withOpacity(0.62),
                                        Colors.black.withOpacity(0.34),
                                        Colors.black.withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          isRecommended
                                              ? 'RECOMMENDED'
                                              : isCompletedJourney
                                                  ? 'COMPLETED'
                                                  : journey.durationLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 12,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        journey.headline.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          height: 0.98,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 18,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        journey.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.92),
                                          fontSize: 13,
                                          height: 1.25,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 12,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(26),
                                        ),
                                        child: Text(
                                          journey.buttonLabel,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: journey.buttonTextColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scrollJourneyCards({required bool forward}) async {
    if (!_journeyScrollController.hasClients) {
      return;
    }

    const offsetStep = 332.0;
    final currentOffset = _journeyScrollController.offset;
    final targetOffset = (currentOffset + (forward ? offsetStep : -offsetStep))
        .clamp(0.0, _journeyScrollController.position.maxScrollExtent);

    await _journeyScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildJourneyFallback(FitnessJourneyPreview journey) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            journey.gradientStart,
            journey.gradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: 28,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 26,
            top: 58,
            child: Icon(
              journey.icon,
              color: journey.accentColor.withOpacity(0.88),
              size: 86,
            ),
          ),
        ],
      ),
    );
  }

  // Workout List Section - Filtered based on selected tab
  Widget _buildWorkoutList() {
    List<Workout> combinedWorkouts = [
      ...exerciseWorkouts,
      ..._customWorkouts,
    ];

    // Filter workouts based on selected tab
    List<Workout> filteredWorkouts = combinedWorkouts.where((workout) {
      String bodyFocus = workout.bodyFocus.toLowerCase();
      String selectedCategory = _tabTitles[_selectedTabIndex].toLowerCase();

      // Map exercises to the new categories
      switch (selectedCategory) {
        case "chest":
          return bodyFocus == "chest";
        case "arms":
          return bodyFocus == "arm" ||
              bodyFocus == "arms" ||
              bodyFocus == "triceps" ||
              bodyFocus == "biceps" ||
              bodyFocus == "forearms";
        case "core":
          return bodyFocus == "abs" || bodyFocus == "core";
        case "lower body":
          return bodyFocus == "legs" ||
              bodyFocus == "lower body" ||
              bodyFocus == "calves" ||
              bodyFocus == "glutes & hamstrings";
        case "shoulders":
          return bodyFocus == "shoulders" || bodyFocus == "traps";
        case "back":
          return bodyFocus == "back" ||
              bodyFocus == "lats" ||
              bodyFocus == "mid-back";
        default:
          return bodyFocus == selectedCategory;
      }
    }).toList();

    return _buildWorkoutCollection(
      title: "${filteredWorkouts.length} ${_tabTitles[_selectedTabIndex]} Workouts",
      workouts: filteredWorkouts,
      emptyMessage: "No workouts available for this category",
    );
  }

  Widget _buildWorkoutCollection({
    required String title,
    required List<Workout> workouts,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (workouts.isEmpty)
          Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 1080;
              if (!useTwoColumns) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return _buildWorkoutCard(workouts[index]);
                  },
                );
              }

              final cardWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 0,
                children: workouts
                    .map(
                      (workout) => SizedBox(
                        width: cardWidth,
                        child: _buildWorkoutCard(workout),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
      ],
    );
  }

  // Build individual workout card
  Widget _buildWorkoutCard(Workout workout) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('completed_workouts')
          .doc(workout.title)
          .get(),
      builder: (context, snapshot) {
        bool isCompleted = false;
        bool isCheated = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isCompleted = data['completedAt'] != null;
          isCheated = data['isCheated'] == true;
        }

        return GestureDetector(
          onTap: () {
            // Navigate to workout detail screen when card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(
                  workout: workout,
                  onWorkoutCompleted: () {
                    _loadMonthlyCategoryData();
                    widget.onDataChanged?.call();
                  }, // Pass callback to refresh data when workout is completed
                  onWorkoutReset: () {
                    _loadMonthlyCategoryData();
                    widget.onDataChanged?.call();
                  }, // Pass callback to refresh data when workout is reset
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactCard = constraints.maxWidth < 340;
                final thumbnailWidth =
                    isCompactCard ? constraints.maxWidth : 130.0;
                final thumbnailHeight = isCompactCard ? 170.0 : double.infinity;

                final thumbnail = Stack(
                  fit: isCompactCard ? StackFit.loose : StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: isCompactCard
                          ? const BorderRadius.vertical(top: Radius.circular(21))
                          : const BorderRadius.horizontal(left: Radius.circular(21)),
                      child: workout.thumbnailAsset.startsWith('http')
                          ? Image.network(
                              workout.thumbnailAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Icon(Icons.fitness_center, color: Colors.white24, size: 40),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              workout.thumbnailAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Icon(Icons.fitness_center, color: Colors.white24, size: 40),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (isCompleted)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "DONE",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );

                final details = Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildWorkoutDetails(
                    workout,
                    isCompleted: isCompleted,
                    isCheated: false,
                  ),
                );

                if (isCompactCard) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: thumbnailHeight, width: thumbnailWidth, child: thumbnail),
                      details,
                    ],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: thumbnailWidth, child: thumbnail),
                      Expanded(child: details),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Helper method to get color based on workout level
  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to check if there's data to display in the pie chart
  bool _hasData() {
    return _activeMonthlyCounts.any((count) => count > 0);
  }

  // Calculate total duration from all exercises in the workout
  String _getTotalExerciseDuration(Workout workout) {
    int totalSeconds = 0;

    // Sum up the duration of all exercises
    for (Exercise exercise in workout.exerciseList) {
      totalSeconds += exercise.duration;
    }

    // Convert total seconds to minutes and format as "X min" or "X mins"
    int totalMinutes = totalSeconds ~/ 60;

    // Handle edge cases: if total minutes is 0, return "0 min", otherwise format appropriately
    if (totalMinutes == 0) {
      // If there are exercises but total is 0 minutes, at least show 1 min to avoid confusion
      if (workout.exerciseList.isNotEmpty) {
        // Check if there are any exercises with duration less than 60 seconds
        bool hasShortExercises = workout.exerciseList.any(
          (exercise) => exercise.duration > 0,
        );
        return hasShortExercises ? "1 min" : "0 min";
      }
      return "0 min";
    }

    return totalMinutes > 1 ? "${totalMinutes} mins" : "${totalMinutes} min";
  }
}

class _WorkoutDesktopScrollBehavior extends MaterialScrollBehavior {
  const _WorkoutDesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class FitnessJourneyPreview {
  final String journeyId;
  final String title;
  final String durationLabel;
  final String headline;
  final String description;
  final String buttonLabel;
  final String thumbnailAsset;
  final IconData icon;
  final Color accentColor;
  final Color buttonTextColor;
  final Color gradientStart;
  final Color gradientEnd;

  const FitnessJourneyPreview({
    required this.journeyId,
    required this.title,
    required this.durationLabel,
    required this.headline,
    required this.description,
    required this.buttonLabel,
    required this.thumbnailAsset,
    required this.icon,
    required this.accentColor,
    required this.buttonTextColor,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class _AnimatedCategoryTab extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedCategoryTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoryTab> createState() => _AnimatedCategoryTabState();
}

class _AnimatedCategoryTabState extends State<_AnimatedCategoryTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF8C42), Color(0xFFFF5200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.04),
                      Colors.white.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? const Color(0xFFFF5200).withOpacity(0.35) : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.65),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
                child: Text(widget.title),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
