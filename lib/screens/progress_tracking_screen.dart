import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/exercise_data2.dart';
import '../data/fitness_journey_workouts.dart';
import '../models/workout_model.dart';
import '../services/progress_tracking_service.dart';
import '../services/workout_goal_service.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Workout> _knownWorkouts = [
    ...exerciseWorkouts,
    ...fitnessJourneyWorkoutsById.values.expand((workouts) => workouts),
  ];
  List<DateTime> _completedWorkoutDates = [];
  List<_JourneyProgressSummary> _startedJourneySummaries = [];
  List<_WorkoutCompletionSummary> _currentMonthWorkoutCompletions = [];
  ExerciseRecord? _highestWeightRecord;
  List<ExerciseRecord> _allExerciseRecords = [];
  List<_WorkoutCompletionSummary> _filteredWorkoutCompletions = [];
  String _selectedGoal = 'All';
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  String? _recommendedGoalType;
  bool _showAllRecords = false;

  // Categories and difficulties for filtering
  final List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Abs',
    'Core',
  ];
  final List<String> _goalOptions = ['All', ...supportedGoalTypes];
  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    // Get all completed workout dates
    _completedWorkoutDates = await _progressService.getCompletedWorkoutDates();
    _startedJourneySummaries = await _loadStartedJourneySummaries();
    _recommendedGoalType = await _progressService.getRecommendedGoalType();

    // Get highest weight record
    _highestWeightRecord = await _progressService.getHighestWeightRecord();

    // Get all exercise records
    _allExerciseRecords = await _progressService.getExerciseRecords();
    _currentMonthWorkoutCompletions = await _loadCurrentMonthWorkoutCompletions();

    // Personal Records should match completed workouts, so filter doneInfos entries.
    _filteredWorkoutCompletions = _applyWorkoutCompletionFilters(
      _currentMonthWorkoutCompletions,
    );
    _showAllRecords = false;

    setState(() {});
  }

  Future<List<_JourneyProgressSummary>> _loadStartedJourneySummaries() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journey_progress')
          .get();

      const journeyOrder = [
        weightLossJourneyId,
        cardioJourneyId,
        strengthPowerJourneyId,
        muscularEnduranceJourneyId,
        healthWellnessJourneyId,
      ];

      final summaries = snapshot.docs
          .map((doc) => _JourneyProgressSummary.fromMap(doc.id, doc.data()))
          .where((summary) => summary.hasStarted)
          .toList()
        ..sort((a, b) {
          final aIndex = journeyOrder.indexOf(a.journeyId);
          final bIndex = journeyOrder.indexOf(b.journeyId);
          final resolvedAIndex = aIndex == -1 ? 999 : aIndex;
          final resolvedBIndex = bIndex == -1 ? 999 : bIndex;
          return resolvedAIndex.compareTo(resolvedBIndex);
        });

      return summaries;
    } catch (e) {
      print('Error loading journey progress summaries: $e');
      return [];
    }
  }

  int _completedWorkoutsThisWeek() {
    final now = DateTime.now();
    final startOfWindow = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    return _completedWorkoutDates.where((date) => !date.isBefore(startOfWindow)).length;
  }

  bool _matchesCategory(ExerciseRecord record, String category) {
    final normalizedCategory = category.toLowerCase().trim();
    final normalizedFocus = record.bodyFocus.toLowerCase().trim();

    if (normalizedFocus.contains(normalizedCategory) ||
        normalizedCategory.contains(normalizedFocus)) {
      return true;
    }

    if (normalizedCategory == 'arms') {
      return normalizedFocus == 'arm' ||
          normalizedFocus == 'arms' ||
          normalizedFocus == 'triceps' ||
          normalizedFocus == 'biceps' ||
          normalizedFocus == 'forearms';
    }

    if (normalizedCategory == 'abs') {
      return normalizedFocus == 'abs' || normalizedFocus == 'core';
    }

    return false;
  }

  bool _matchesGoalFilter({
    required String primaryGoal,
    required List<String> goalTags,
  }) {
    if (_selectedGoal == 'All') {
      return true;
    }

    final normalizedSelectedGoal = normalizeGoalType(_selectedGoal);
    return primaryGoal == normalizedSelectedGoal ||
        goalTags.contains(normalizedSelectedGoal);
  }

  Future<List<_WorkoutCompletionSummary>> _loadCurrentMonthWorkoutCompletions() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('doneInfos')
          .where('completedAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('completedAt', isLessThan: startOfNextMonth)
          .get();

      final completions = snapshot.docs
          .map(
            (doc) => _WorkoutCompletionSummary.fromMap(
              doc.data(),
              fallbackWorkout: _findWorkoutForCompletion(doc.data()),
            ),
          )
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      return completions;
    } catch (e) {
      print('Error loading current month workout completions: $e');
      return [];
    }
  }

  Workout? _findWorkoutForCompletion(Map<String, dynamic> data) {
    final workoutId = (data['workoutId'] ?? '').toString();
    final workoutTitle = (data['title'] ?? '').toString();

    for (final workout in _knownWorkouts) {
      if (workoutId.isNotEmpty && workout.id == workoutId) {
        return workout;
      }
    }

    for (final workout in _knownWorkouts) {
      if (workoutTitle.isNotEmpty && workout.title == workoutTitle) {
        return workout;
      }
    }

    return null;
  }

  List<_WorkoutCompletionSummary> _applyWorkoutCompletionFilters(
    List<_WorkoutCompletionSummary> completions,
  ) {
    return completions.where((completion) {
      final goalMatch = _matchesGoalFilter(
        primaryGoal: completion.primaryGoal,
        goalTags: completion.goalTags,
      );
      final categoryMatch = _selectedCategory == 'All'
          ? true
          : _matchesCompletionCategory(completion, _selectedCategory);
      final difficultyMatch = _selectedDifficulty == 'All'
          ? true
          : completion.level.toLowerCase().contains(
                _selectedDifficulty.toLowerCase(),
              );

      return goalMatch && categoryMatch && difficultyMatch;
    }).toList(growable: false);
  }

  bool _matchesCompletionCategory(
    _WorkoutCompletionSummary completion,
    String category,
  ) {
    final normalizedCategory = category.toLowerCase().trim();
    final normalizedFocus = completion.bodyFocus.toLowerCase().trim();

    if (normalizedFocus.contains(normalizedCategory) ||
        normalizedCategory.contains(normalizedFocus)) {
      return true;
    }

    if (normalizedCategory == 'arms') {
      return normalizedFocus == 'arm' ||
          normalizedFocus == 'arms' ||
          normalizedFocus == 'triceps' ||
          normalizedFocus == 'biceps' ||
          normalizedFocus == 'forearms';
    }

    if (normalizedCategory == 'abs') {
      return normalizedFocus == 'abs' || normalizedFocus == 'core';
    }

    return false;
  }

  void _filterWorkoutRecords() {
    setState(() {
      _filteredWorkoutCompletions = _applyWorkoutCompletionFilters(
        _currentMonthWorkoutCompletions,
      );
      _showAllRecords = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _showAllRecords
        ? _filteredWorkoutCompletions
        : _filteredWorkoutCompletions.take(5).toList();
    final hasMoreThanFiveRecords = _filteredWorkoutCompletions.length > 5;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Progress Tracking",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideLayout = kIsWeb && constraints.maxWidth >= 1120;
            final isMediumLayout = kIsWeb && constraints.maxWidth >= 760;
            final horizontalPadding = isWideLayout ? 24.0 : 16.0;
            final contentMaxWidth = kIsWeb
                ? (constraints.maxWidth >= 1440
                      ? 1320.0
                      : constraints.maxWidth.toDouble())
                : constraints.maxWidth.toDouble();

            if (_allExerciseRecords.isEmpty &&
                _completedWorkoutDates.isEmpty &&
                _startedJourneySummaries.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Colors.grey,
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No workout data yet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Complete a workout to see your progress",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMediumLayout)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildOverviewSection(
                                  title: "History",
                                  child: _buildPersonalBestCard(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildOverviewSection(
                                  title: "Today",
                                  child: _buildTodayCard(),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildOverviewSection(
                            title: "History",
                            child: _buildPersonalBestCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildOverviewSection(
                            title: "Today",
                            child: _buildTodayCard(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (_startedJourneySummaries.isNotEmpty) ...[
                          _buildSectionTitle("Fitness Journeys"),
                          const SizedBox(height: 12),
                          _buildJourneyProgressPanel(isWideLayout: isWideLayout),
                          const SizedBox(height: 18),
                        ],
                        if (isWideLayout)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPersonalRecordsSection(
                                      visibleRecords: visibleRecords,
                                      hasMoreThanFiveRecords: hasMoreThanFiveRecords,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: _buildInsightsSection(),
                              ),
                            ],
                          )
                        else ...[
                          _buildPersonalRecordsSection(
                            visibleRecords: visibleRecords,
                            hasMoreThanFiveRecords: hasMoreThanFiveRecords,
                          ),
                          const SizedBox(height: 18),
                          _buildInsightsSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverviewSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildPersonalBestCard() {
    return _buildPanel(
      child: Column(
        children: [
          const Icon(
            Icons.star,
            color: Colors.yellow,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            "Personal Best",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _highestWeightRecord != null
                ? "${_highestWeightRecord!.weightUsed} kg"
                : "0 kg",
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_highestWeightRecord != null)
            Text(
              _highestWeightRecord!.exerciseName,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayCard() {
    final now = DateTime.now();
    final hasCleanWorkoutToday = _completedWorkoutDates.any(
      (workoutDate) =>
          workoutDate.day == now.day &&
          workoutDate.month == now.month &&
          workoutDate.year == now.year,
    );

    return _buildPanel(
      child: Row(
        children: [
          const Icon(
            Icons.today,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCleanWorkoutToday
                      ? "You completed a clean workout today."
                      : "No clean workout recorded today yet.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyProgressPanel({required bool isWideLayout}) {
    if (!isWideLayout) {
      return _buildPanel(
        child: Column(
          children: _startedJourneySummaries
              .map(_buildJourneyProgressItem)
              .toList(),
        ),
      );
    }

    return _buildPanel(
      child: Wrap(
        spacing: 16,
        runSpacing: 0,
        children: _startedJourneySummaries
            .map(
              (summary) => SizedBox(
                width: 620,
                child: _buildJourneyProgressItem(summary),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPersonalRecordsSection({
    required List<_WorkoutCompletionSummary> visibleRecords,
    required bool hasMoreThanFiveRecords,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Personal Records",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (hasMoreThanFiveRecords)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllRecords = !_showAllRecords;
                  });
                },
                child: Text(
                  _showAllRecords ? 'Show less' : 'Show all',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedGoal != 'All' ||
            (_recommendedGoalType != null &&
                _recommendedGoalType!.trim().isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _selectedGoal == 'All'
                  ? 'Recommended goal: ${goalLabel(_recommendedGoalType!)}.'
                  : 'Filtering workouts by ${goalLabel(_selectedGoal)}.',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        if (!hasMoreThanFiveRecords && _filteredWorkoutCompletions.isNotEmpty)
          Text(
            'Showing ${_filteredWorkoutCompletions.length} workout record${_filteredWorkoutCompletions.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 12),
        _buildFiltersCard(),
        const SizedBox(height: 12),
        _buildPanel(
          child: _filteredWorkoutCompletions.isEmpty
              ? const Text(
                  "No workout records yet",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              : Column(
                  children: visibleRecords
                      .map(_buildPersonalRecordItem)
                      .toList(),
                ),
        ),
        if (hasMoreThanFiveRecords)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                _showAllRecords
                    ? 'Showing all ${_filteredWorkoutCompletions.length} records'
                    : 'Showing 5 of ${_filteredWorkoutCompletions.length} records',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersCard() {
    return _buildPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final categoryField = _buildCategoryDropdown();
          final difficultyField = _buildDifficultyDropdown();

          return Column(
            children: [
              _buildGoalDropdown(),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  children: [
                    Expanded(child: categoryField),
                    const SizedBox(width: 16),
                    Expanded(child: difficultyField),
                  ],
                )
              else ...[
                categoryField,
                const SizedBox(height: 16),
                difficultyField,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGoal,
      decoration: const InputDecoration(
        labelText: 'Goal',
        labelStyle: TextStyle(color: Colors.orange),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
      ),
      items: _goalOptions.map((String goalType) {
        return DropdownMenuItem(
          value: goalType,
          child: Text(
            goalType == 'All' ? 'All Goals' : goalLabel(goalType),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue == null) {
          return;
        }
        _selectedGoal = newValue;
        _filterWorkoutRecords();
      },
      dropdownColor: const Color(0xFF191919),
      iconEnabledColor: Colors.white,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: Colors.orange),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue == null) {
          return;
        }
        _selectedCategory = newValue;
        _filterWorkoutRecords();
      },
      dropdownColor: const Color(0xFF191919),
      iconEnabledColor: Colors.white,
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        labelStyle: TextStyle(color: Colors.orange),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
      ),
      items: _difficulties.map((String difficulty) {
        return DropdownMenuItem(
          value: difficulty,
          child: Text(
            difficulty,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue == null) {
          return;
        }
        _selectedDifficulty = newValue;
        _filterWorkoutRecords();
      },
      dropdownColor: const Color(0xFF191919),
      iconEnabledColor: Colors.white,
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Progress Insights"),
        const SizedBox(height: 12),
        _buildPanel(
          child: Column(
            children: [
              _buildInsightItem(
                icon: Icons.calendar_today,
                title: "Workout Frequency",
                value: "${_completedWorkoutsThisWeek()} this week",
                description: "Clean workouts in the last 7 days",
              ),
              const Divider(height: 20, color: Colors.grey),
              _buildInsightItem(
                icon: Icons.repeat,
                title: "Most Practiced",
                value: _allExerciseRecords.isEmpty
                    ? "No data"
                    : _getMostPracticedExercise(),
                description: "Your most practiced exercise",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get the most practiced exercise
 String _getMostPracticedExercise() {
    if (_allExerciseRecords.isEmpty) return "No data";
    
    // Count occurrences of each exercise
    final Map<String, int> exerciseCount = {};
    for (final record in _allExerciseRecords) {
      exerciseCount[record.exerciseName] = (exerciseCount[record.exerciseName] ?? 0) + 1;
    }
    
    // Find the exercise with the highest count
    String mostPracticed = "";
    int maxCount = 0;
    exerciseCount.forEach((exercise, count) {
      if (count > maxCount) {
        maxCount = count;
        mostPracticed = exercise;
      }
    });
    
    return mostPracticed.isEmpty ? "No data" : mostPracticed;
  }

  // Helper method to build insight items
  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String value,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyProgressItem(_JourneyProgressSummary summary) {
    final statusColor = summary.isCompleted ? Colors.greenAccent : Colors.orange;
    final statusLabel = summary.isCompleted ? 'Completed' : 'In Progress';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.journeyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: summary.progressRatio,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${summary.completedWorkoutsCount} of ${summary.totalWorkoutsCount} workouts completed',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.progressPercent.toStringAsFixed(0)}% progress',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (summary.completionCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                summary.repeatCompletionCount > 0
                    ? 'Finished again ${summary.repeatCompletionCount} ${summary.repeatCompletionCount == 1 ? 'time' : 'times'}'
                    : 'First completion unlocked',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordItem(_WorkoutCompletionSummary record) {
    final goalText = record.primaryGoal.trim().isNotEmpty
        ? goalLabel(record.primaryGoal)
        : null;
    final journeyText = record.journeyName.trim().isNotEmpty
        ? record.journeyName
        : null;
    final subtitleParts = _uniqueTextParts([
      record.bodyFocus,
      if (goalText != null) goalText,
      if (journeyText != null) journeyText,
    ]);
    final metricParts = <String>[
      if (record.recordedMinutes > 0) '${record.recordedMinutes} min',
      if (record.recordedCalories > 0) '${record.recordedCalories} cal',
      if (record.isCheated) 'Cheated',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' | '),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                if (metricParts.isNotEmpty)
                  Text(
                    metricParts.join(' | '),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd, yyyy').format(record.completedAt),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<String> _uniqueTextParts(List<String> values) {
    final uniqueParts = <String>[];
    final seenNormalizedValues = <String>{};

    for (final value in values) {
      final trimmedValue = value.trim();
      if (trimmedValue.isEmpty) {
        continue;
      }

      final normalizedValue = trimmedValue.toLowerCase();
      if (seenNormalizedValues.add(normalizedValue)) {
        uniqueParts.add(trimmedValue);
      }
    }

    return uniqueParts;
  }
}

class _JourneyProgressSummary {
  final String journeyId;
  final String journeyName;
  final int completedWorkoutsCount;
  final int totalWorkoutsCount;
  final int completionCount;
  final int repeatCompletionCount;
  final double progressPercent;
  final String status;

  const _JourneyProgressSummary({
    required this.journeyId,
    required this.journeyName,
    required this.completedWorkoutsCount,
    required this.totalWorkoutsCount,
    required this.completionCount,
    required this.repeatCompletionCount,
    required this.progressPercent,
    required this.status,
  });

  bool get hasStarted => status == 'in_progress' || status == 'completed';

  bool get isCompleted => status == 'completed';

  double get progressRatio {
    if (totalWorkoutsCount <= 0) {
      return 0.0;
    }
    return (completedWorkoutsCount / totalWorkoutsCount).clamp(0.0, 1.0);
  }

  factory _JourneyProgressSummary.fromMap(
    String journeyId,
    Map<String, dynamic> data,
  ) {
    return _JourneyProgressSummary(
      journeyId: journeyId,
      journeyName: (data['journeyName'] ?? 'Fitness Journey').toString(),
      completedWorkoutsCount:
          (data['completedWorkoutsCount'] as num?)?.toInt() ?? 0,
      totalWorkoutsCount: (data['totalWorkoutsCount'] as num?)?.toInt() ?? 0,
      completionCount: (data['completionCount'] as num?)?.toInt() ??
          (((data['status'] ?? 'not_started').toString() == 'completed')
              ? 1
              : 0),
      repeatCompletionCount: (data['repeatCompletionCount'] as num?)?.toInt() ??
          0,
      progressPercent: (data['progressPercent'] as num?)?.toDouble() ?? 0.0,
      status: (data['status'] ?? 'not_started').toString(),
    );
  }
}

class _WorkoutCompletionSummary {
  final DateTime completedAt;
  final String title;
  final String bodyFocus;
  final String level;
  final String journeyName;
  final String primaryGoal;
  final List<String> goalTags;
  final int recordedMinutes;
  final int recordedCalories;
  final bool isCheated;

  const _WorkoutCompletionSummary({
    required this.completedAt,
    required this.title,
    required this.bodyFocus,
    required this.level,
    required this.journeyName,
    required this.primaryGoal,
    required this.goalTags,
    required this.recordedMinutes,
    required this.recordedCalories,
    required this.isCheated,
  });

  factory _WorkoutCompletionSummary.fromMap(
    Map<String, dynamic> data, {
    Workout? fallbackWorkout,
  }) {
    final timestamp = data['completedAt'] as Timestamp?;
    final fallbackPrimaryGoal = fallbackWorkout == null
        ? generalFitnessGoal
        : inferPrimaryGoalForWorkout(fallbackWorkout);
    final fallbackGoalTags = fallbackWorkout == null
        ? <String>[fallbackPrimaryGoal]
        : inferGoalTagsForWorkout(fallbackWorkout);

    return _WorkoutCompletionSummary(
      completedAt: timestamp?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: (data['title'] ?? fallbackWorkout?.title ?? 'Workout').toString(),
      bodyFocus: (data['bodyFocus'] ?? fallbackWorkout?.bodyFocus ?? '').toString(),
      level: (data['level'] ?? fallbackWorkout?.level ?? '').toString(),
      journeyName: (data['journeyName'] ?? fallbackWorkout?.journeyName ?? '')
          .toString(),
      primaryGoal: normalizeGoalType(
        (data['primaryGoal'] ?? fallbackPrimaryGoal).toString(),
      ),
      goalTags: ((data['goalTags'] as List<dynamic>? ?? fallbackGoalTags)
              .map((goal) => normalizeGoalType(goal.toString()))
              .toSet()
              .toList())
          .cast<String>(),
      recordedMinutes: (data['recordedMinutes'] as num?)?.toInt() ?? 0,
      recordedCalories: (data['recordedCalories'] as num?)?.toInt() ?? 0,
      isCheated: data['isCheated'] == true,
    );
  }
}
