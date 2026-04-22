import 'package:flutter/material.dart';
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

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  int _selectedJourneyIndex = 0;
  int _selectedMonthlyTrackingView = 0;
  int _recommendedJourneyIndex = 4;
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
  ]; // Total count for each category
  List<int> _monthlyCheatedCategoryCounts = [
    0,
    0,
    0,
    0,
    0,
  ]; // Cheated count for each category
  List<int> _monthlyJourneyCounts = [0, 0, 0, 0, 0];
  List<int> _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
  bool _isLoading = true;

  // List of tab titles and corresponding colors
  final List<String> _tabTitles = [
    "Chest",
    "Arms",
    "Core",
    "Lower Body",
    "Shoulders",
  ];
  final List<Color> _categoryColors = [
    Colors.red, // Chest
    Colors.blue, // Arms
    Colors.green, // Core
    Colors.orange, // Lower Body
    Colors.purple,   // Shoulders
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when the app resumes (e.g., when returning from workout detail screen)
      _loadMonthlyCategoryData();
      _loadSelectedJourney();
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
        normalizedFocus == "calves" ||
        normalizedFocus == "glutes & hamstrings") {
      return 3;
    }
    if (normalizedFocus == "shoulders" || normalizedFocus == "traps") {
      return 4;
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
    final cleanRadius = compact ? 42.0 : 50.0;
    final cheatedRadius = compact ? 34.0 : 42.0;
    final cleanFontSize = compact ? 10.0 : 12.0;
    final cheatedFontSize = compact ? 9.0 : 11.0;
    final activeCounts = _activeMonthlyCounts;
    final activeCheatedCounts = _activeMonthlyCheatedCounts;
    final activeColors = _activeMonthlyColors;

    for (int i = 0; i < activeCounts.length; i++) {
      final cheatedCount = activeCheatedCounts[i];
      final cleanCount = activeCounts[i] - cheatedCount;

      if (cleanCount > 0) {
        sections.add(
          PieChartSectionData(
            color: activeColors[i],
            value: cleanCount.toDouble(),
            title: '$cleanCount',
            radius: cleanRadius,
            titleStyle: TextStyle(
              fontSize: cleanFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }

      if (cheatedCount > 0) {
        sections.add(
          PieChartSectionData(
            color: activeColors[i].withOpacity(0.35),
            value: cheatedCount.toDouble(),
            title: '!$cheatedCount',
            radius: cheatedRadius,
            titleStyle: TextStyle(
              fontSize: cheatedFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildLegendItem(int index, {required bool compact}) {
    final totalCount = _activeMonthlyCounts[index];
    final cheatedCount = _activeMonthlyCheatedCounts[index];
    final cleanCount = totalCount - cheatedCount;
    final label = _activeMonthlyTitles[index];
    final color = _activeMonthlyColors[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $totalCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (cheatedCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$cheatedCount cheated',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '$cleanCount clean',
                    style: TextStyle(
                      color: Colors.white38,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor,
                width: 1,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
      children: [
        Text(
          workout.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (workout.journeyName != null)
              _buildWorkoutMetaChip(
                label: workout.journeyName!,
                backgroundColor: const Color(0xFFFF6B35).withOpacity(0.18),
                textColor: const Color(0xFFFF9B73),
              ),
            _buildWorkoutMetaChip(
              label: "${workout.exerciseList.length} exercises",
              backgroundColor: Colors.grey[800]!,
              textColor: Colors.white70,
            ),
            _buildWorkoutMetaChip(
              label: workout.level,
              backgroundColor: _getLevelColor(workout.level).withOpacity(0.2),
              textColor: _getLevelColor(workout.level),
            ),
            if (isCompleted)
              _buildWorkoutMetaChip(
                label: isCheated ? 'Cheated' : 'Done',
                backgroundColor: isCheated
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                textColor: isCheated ? Colors.red : Colors.green,
                borderColor: isCheated ? Colors.red : Colors.green,
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
        List<int> categoryCounts = [0, 0, 0, 0, 0];
        List<int> cheatedCategoryCounts = [0, 0, 0, 0, 0];
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
          _monthlyCategoryCounts = [0, 0, 0, 0, 0];
          _monthlyCheatedCategoryCounts = [0, 0, 0, 0, 0];
          _monthlyJourneyCounts = [0, 0, 0, 0, 0];
          _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading monthly category data: $e');
      setState(() {
        _monthlyCategoryCounts = [0, 0, 0, 0, 0];
        _monthlyCheatedCategoryCounts = [0, 0, 0, 0, 0];
        _monthlyJourneyCounts = [0, 0, 0, 0, 0];
        _monthlyJourneyCheatedCounts = [0, 0, 0, 0, 0];
        _isLoading = false;
      });
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Workout",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false, // Prevents the automatic back button
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMonthlyCategoryData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Category Chart
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: isCompactScreen ? 320 : 350,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isCompactScreen ? 14 : 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactCard = constraints.maxWidth < 360;
                          final chartHeight = compactCard ? 160.0 : 190.0;
                          final legendWidth = compactCard
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 10) / 2;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Monthly Category Tracking",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compactCard ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentMonthLabel(),
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: compactCard ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.24),
                                  borderRadius: BorderRadius.circular(14),
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
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedMonthlyTrackingView == 0
                                                ? const Color(0xFFFF6B35)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "Body Focus",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _selectedMonthlyTrackingView == 0
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.bold,
                                              fontSize: compactCard ? 12 : 13,
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
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedMonthlyTrackingView == 1
                                                ? const Color(0xFFFF6B35)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "Journeys",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _selectedMonthlyTrackingView == 1
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.bold,
                                              fontSize: compactCard ? 12 : 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: chartHeight,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.orange,
                                          ),
                                        ),
                                      )
                                    : _hasData()
                                        ? PieChart(
                                            PieChartData(
                                              sections: _buildMonthlyChartSections(
                                                compact: compactCard,
                                              ),
                                              centerSpaceRadius:
                                                  compactCard ? 24 : 30,
                                              sectionsSpace: 2,
                                              pieTouchData: PieTouchData(
                                                enabled: true,
                                                touchCallback: (
                                                  FlTouchEvent event,
                                                  pieTouchResponse,
                                                ) {
                                                  // Handle touch events if needed
                                                },
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Text(
                                              "Complete a workout to see your progress",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: List.generate(_activeMonthlyTitles.length, (i) {
                                  return SizedBox(
                                    width: legendWidth,
                                    child: _buildLegendItem(
                                      i,
                                      compact: compactCard,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Solid slices = clean completions. Faded slices with ! = cheated completions.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: compactCard ? 10 : 11,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProgressTrackingScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B35),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.insights),
                                  label: Text(
                                    "Open Progress Tracking",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: compactCard ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildJourneySection(),

                  const SizedBox(height: 24),

                  // Body Focus
                  const Text(
                    "Body Focus",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Tabs
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tabTitles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return _buildTab(_tabTitles[index], index);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Workout List Section - Filtered based on selected tab
                  _buildWorkoutList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Body Focus Tabs Choices
  Widget _buildTab(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedTabIndex == index
              ? const Color(0xFFFF6B35)
              : const Color(0xFF191919),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: _selectedTabIndex == index
                  ? Colors.white
                  : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneySection() {
    final recommendedJourney = _recommendedJourney;
    final recommendedJourneyCompleted =
        _isJourneyCompleted(recommendedJourney.journeyId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Fitness Journey",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF191919),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recommended Journey",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _allJourneysCompleted
                    ? "All journeys are complete. You can still replay any journey anytime."
                    : "The app automatically highlights the journey that fits your current progress best.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: recommendedJourney.accentColor.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalLabel(_recommendedGoalType),
                      style: TextStyle(
                        color: recommendedJourney.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendedJourney.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _allJourneysCompleted
                          ? '${recommendedJourney.description} Replay any journey whenever you want.'
                          : recommendedJourneyCompleted
                              ? '${recommendedJourney.description} This journey is already complete, but you can start it again anytime.'
                              : recommendedJourney.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _recommendationReason,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 11,
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
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _journeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final journey = _journeys[index];
              final isSelected = index == _selectedJourneyIndex;
              final isRecommended = index == _recommendedJourneyIndex;
              final isCompletedJourney = _isJourneyCompleted(journey.journeyId);

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
                  width: 292,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
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
                                  borderRadius: BorderRadius.circular(26),
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
      ],
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
    // Filter workouts based on selected tab
    List<Workout> filteredWorkouts = exerciseWorkouts.where((workout) {
      String bodyFocus = workout.bodyFocus.toLowerCase();
      String selectedCategory = _tabTitles[_selectedTabIndex].toLowerCase();

      // Map exercises to the new categories
      switch (selectedCategory) {
        case "chest":
          return bodyFocus == "chest";
        case "arms":
          return bodyFocus == "arm" ||
              bodyFocus == "triceps" ||
              bodyFocus == "biceps" ||
              bodyFocus == "forearms";
        case "core":
          return bodyFocus == "abs" || bodyFocus == "core";
        case "lower body":
          return bodyFocus == "legs" ||
              bodyFocus == "calves" ||
              bodyFocus == "glutes & hamstrings";
        case "shoulders":
          return bodyFocus == "shoulders" || bodyFocus == "traps";
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
          ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Disable scrolling for the list view since the parent is already scrollable
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(workouts[index]);
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
                  onWorkoutCompleted:
                      _loadMonthlyCategoryData, // Pass callback to refresh data when workout is completed
                  onWorkoutReset:
                      _loadMonthlyCategoryData, // Pass callback to refresh data when workout is reset
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF191919),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactCard = constraints.maxWidth < 340;
                  final thumbnailWidth =
                      isCompactCard ? constraints.maxWidth : 120.0;
                  final thumbnailHeight = isCompactCard ? 170.0 : 80.0;

                  final thumbnail = Stack(
                    children: [
                      Container(
                        width: thumbnailWidth,
                        height: thumbnailHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            workout.thumbnailAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCheated ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCheated ? Icons.warning : Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  );

                  final details = _buildWorkoutDetails(
                    workout,
                    isCompleted: isCompleted,
                    isCheated: isCheated,
                  );

                  if (isCompactCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbnail,
                        const SizedBox(height: 12),
                        details,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumbnail,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
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
