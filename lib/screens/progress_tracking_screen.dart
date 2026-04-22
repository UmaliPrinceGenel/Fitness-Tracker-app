import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/fitness_journey_workouts.dart';
import '../services/progress_tracking_service.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DateTime> _completedWorkoutDates = [];
  List<_JourneyProgressSummary> _startedJourneySummaries = [];
  ExerciseRecord? _highestWeightRecord;
  List<ExerciseRecord> _allExerciseRecords = [];
  List<ExerciseRecord> _filteredExerciseRecords = [];
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
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

    // Get highest weight record
    _highestWeightRecord = await _progressService.getHighestWeightRecord();
    
    // Get all exercise records
    _allExerciseRecords = await _progressService.getExerciseRecords();
    
    // Set filtered records to all records initially
    _filteredExerciseRecords = _allExerciseRecords;
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

  // Filter exercises based on selected category and difficulty
  Future<void> _filterExercises() async {
    List<ExerciseRecord> filtered = _allExerciseRecords;

    // Apply category filter if not 'All'
    if (_selectedCategory != 'All') {
      filtered = await _progressService.getExerciseRecordsByCategory(_selectedCategory);
    }

    // Apply difficulty filter if not 'All'
    if (_selectedDifficulty != 'All') {
      final difficultyFiltered = await _progressService.getExerciseRecordsByDifficulty(_selectedDifficulty);
      
      // If both filters are applied, find the intersection
      if (_selectedCategory != 'All') {
        filtered = filtered.where((record) => 
          difficultyFiltered.any((r) => r.exerciseName == record.exerciseName)
        ).toList();
      } else {
        filtered = difficultyFiltered;
      }
    }

    setState(() {
      _filteredExerciseRecords = filtered;
      _showAllRecords = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _showAllRecords
        ? _filteredExerciseRecords
        : _filteredExerciseRecords.take(5).toList();
    final hasMoreThanFiveRecords = _filteredExerciseRecords.length > 5;

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
        child: _allExerciseRecords.isEmpty &&
                _completedWorkoutDates.isEmpty &&
                _startedJourneySummaries.isEmpty
            ? const Center(
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
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // History Section
                      const Text(
                        "History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Personal Best Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
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
                              if (_highestWeightRecord != null)
                                Text(
                                  "${_highestWeightRecord!.weightUsed} kg",
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const Text(
                                  "0 kg",
                                  style: TextStyle(
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Today Section
                      const Text(
                        "Today",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
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
                                          DateFormat(
                                            'EEEE, MMMM dd, yyyy',
                                          ).format(DateTime.now()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _completedWorkoutDates.any(
                                            (workoutDate) =>
                                                workoutDate.day ==
                                                    DateTime.now().day &&
                                                workoutDate.month ==
                                                    DateTime.now().month &&
                                                workoutDate.year ==
                                                    DateTime.now().year,
                                          )
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_startedJourneySummaries.isNotEmpty) ...[
                        const Text(
                          "Fitness Journeys",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: _startedJourneySummaries
                                  .map(_buildJourneyProgressItem)
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Personal Records Section
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

                      if (!hasMoreThanFiveRecords &&
                          _filteredExerciseRecords.isNotEmpty)
                        Text(
                          'Showing ${_filteredExerciseRecords.length} record${_filteredExerciseRecords.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Filter Controls
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
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
                                        setState(() {
                                          _selectedCategory = newValue!;
                                          _filterExercises();
                                        });
                                      },
                                      dropdownColor: const Color(0xFF191919),
                                      iconEnabledColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
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
                                        setState(() {
                                          _selectedDifficulty = newValue!;
                                          _filterExercises();
                                        });
                                      },
                                      dropdownColor: const Color(0xFF191919),
                                      iconEnabledColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Personal Records List
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _filteredExerciseRecords.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "No exercise records yet",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: visibleRecords
                                      .map((record) => _buildPersonalRecordItem(
                                            record.exerciseName,
                                            "${record.weightUsed} kg",
                                            record.timestamp != null
                                                ? DateFormat('MMM dd, yyyy').format(record.timestamp!)
                                                : 'Date unknown',
                                          ))
                                      .toList(),
                                ),
                              ),
                      ),

                      if (hasMoreThanFiveRecords)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(
                              _showAllRecords
                                  ? 'Showing all ${_filteredExerciseRecords.length} records'
                                  : 'Showing 5 of ${_filteredExerciseRecords.length} records',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      
                      // Additional progress metrics
                      const SizedBox(height: 16),
                      const Text(
                        "Progress Insights",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress insights cards
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Workout frequency insight
                              _buildInsightItem(
                                icon: Icons.calendar_today,
                                title: "Workout Frequency",
                                value: "${_completedWorkoutsThisWeek()} this week",
                                description: "Clean workouts in the last 7 days",
                              ),
                              const Divider(height: 20, color: Colors.grey),
                              // Most frequent exercise
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
                      ),
                    ],
                  ),
                ),
              ),
      ),
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

  Widget _buildPersonalRecordItem(String exercise, String record, String date) {
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
                  exercise,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  record,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
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
