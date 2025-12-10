import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/progress_tracking_service.dart';
import '../services/workout_history_service.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  List<DateTime> _completedWorkoutDates = [];
  List<DateTime> _allDates = [];
  int _longestStreak = 0;
  ExerciseRecord? _highestWeightRecord;
  List<ExerciseRecord> _allExerciseRecords = [];
 List<ExerciseRecord> _filteredExerciseRecords = [];
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  DateTime _currentMonth = DateTime.now();
  
  // Categories and difficulties for filtering
  final List<String> _categories = ['All', 'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Abs', 'Core'];
  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    // Get all completed workout dates
    _completedWorkoutDates = await _progressService.getCompletedWorkoutDates();
    
    // Calculate longest streak
    _longestStreak = await _progressService.getLongestStreak();
    
    // Get highest weight record
    _highestWeightRecord = await _progressService.getHighestWeightRecord();
    
    // Get all exercise records
    _allExerciseRecords = await _progressService.getExerciseRecords();
    
    // Set filtered records to all records initially
    _filteredExerciseRecords = _allExerciseRecords;
    
    // Update calendar dates
    _updateCalendarDates();
    
    setState(() {});
  }

 void _updateCalendarDates() {
    // Get days in current month
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    
    // Create list of all dates in the current month
    _allDates = List.generate(
      daysInMonth,
      (index) => DateTime(_currentMonth.year, _currentMonth.month, index + 1),
    );
  }

 // Navigate to previous month
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _updateCalendarDates();
    });
  }

  // Navigate to next month
 void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _updateCalendarDates();
    });
  }

  // Format month and year for display
  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Check if a date is today
  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.day == today.day && 
           date.month == today.month && 
           date.year == today.year;
  }

  // Check if a date has a completed workout
 bool _hasWorkout(DateTime date) {
    return _completedWorkoutDates.any((workoutDate) => 
      workoutDate.day == date.day && 
      workoutDate.month == date.month && 
      workoutDate.year == date.year
    );
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
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: _allExerciseRecords.isEmpty && _completedWorkoutDates.isEmpty
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

                      // Day Streak and Personal Best Cards (Side by Side)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF191919),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Day Streak",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${_longestStreak} days",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF191919),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.star, color: Colors.yellow, size: 32),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Calendar Section
                      const Text(
                        "Calendar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Month Navigation and Title
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: _previousMonth,
                                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                                  ),
                                  Text(
                                    _formatMonthYear(_currentMonth),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _nextMonth,
                                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Day Labels (S, M, T, W, TH, F, S)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDayLabel("S"),
                                  _buildDayLabel("M"),
                                  _buildDayLabel("T"),
                                  _buildDayLabel("W"),
                                  _buildDayLabel("T"),
                                  _buildDayLabel("F"),
                                  _buildDayLabel("S"),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Calendar grid
                              _buildCalendarGrid(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal Records Section
                      const Text(
                        "Personal Records",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                                  children: _filteredExerciseRecords
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
                                value: _completedWorkoutDates.isEmpty 
                                    ? "0 workouts" 
                                    : "${(_completedWorkoutDates.length / 4).toStringAsFixed(1)} per week",
                                description: "Average workouts per week",
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
                              const Divider(height: 20, color: Colors.grey),
                              // Consistency
                              _buildInsightItem(
                                icon: Icons.trending_up,
                                title: "Consistency",
                                value: _longestStreak == 0 
                                    ? "0 days" 
                                    : "${(_longestStreak / 7).toStringAsFixed(1)} weeks",
                                description: "Longest streak in weeks",
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

  Widget _buildDayLabel(String day) {
    return Container(
      width: 30,
      height: 30,
      child: Center(
        child: Text(
          day,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

 Widget _buildCalendarGrid() {
    // Get the first day of the month and the number of days in the month
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = firstDay.weekday % 7; // 0 = Sunday, 1 = Monday, etc.

    // Create a list of all days to display (including empty spaces for days before the first)
    final days = <Widget>[];

    // Add empty spaces for days before the first day of the month
    for (int i = 0; i < firstDayWeekday; i++) {
      days.add(const SizedBox(width: 30, height: 30));
    }

    // Add all the days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      days.add(_buildCalendarDay(date));
    }

    // Add empty spaces for days after the last day of the month to complete the grid
    final totalCells = ((days.length + 6) ~/ 7) * 7; // Round up to nearest multiple of 7
    for (int i = days.length; i < totalCells; i++) {
      days.add(const SizedBox(width: 30, height: 30));
    }

    // Create the grid rows
    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.sublist(
              i,
              i + 7 > days.length ? days.length : i + 7,
            ),
          ),
        ),
      );
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    bool isToday = _isToday(date);
    bool hasWorkout = _hasWorkout(date);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday
            ? Colors.orange
            : hasWorkout
                ? Colors.green.withOpacity(0.3)
                : Colors.transparent,
        border: isToday
            ? null
            : Border.all(
                color: hasWorkout ? Colors.green : Colors.grey.withOpacity(0.5),
              ),
      ),
      child: Center(
        child: Text(
          date.day.toString(),
          style: TextStyle(
            color: isToday
                ? Colors.black
                : hasWorkout
                    ? Colors.green
                    : Colors.white70,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
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
