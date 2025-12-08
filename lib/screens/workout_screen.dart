import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'progress_tracking_screen.dart'; // Import the new progress tracking screen
import '../data/workout_data.dart'; // Import workout data
import '../models/workout_model.dart'; // Import workout model
import 'workout_detail_screen.dart'; // Import workout detail screen

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<int> _weeklyWorkoutData = [0, 0, 0, 0, 0, 0, 0]; // Initialize with zeros for each day of the week
  int _weeklyWorkoutsCount = 0; // Track weekly completed workouts
  int _weeklyCalories = 0; // Track weekly calories burned
  int _weeklyMinutes = 0; // Track weekly minutes exercised
  bool _isLoading = true;

 // List of tab titles
  final List<String> _tabTitles = ["Abs", "Arm", "Chest", "Leg"];

  @override
  void initState() {
    super.initState();
    _loadWeeklyProgressData();
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
      _loadWeeklyProgressData();
    }
  }

  // Load weekly progress data from Firestore
  Future<void> _loadWeeklyProgressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get the start of the current week (Monday)
        DateTime now = DateTime.now();
        DateTime startOfWeek = _getStartOfWeek(now);
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

        // Query completed workouts for the current week
        final completedWorkoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('completed_workouts')
            .where('completedAt', isGreaterThanOrEqualTo: startOfWeek)
            .where('completedAt', isLessThan: endOfWeek)
            .get();

        // Initialize weekly data with zeros
        List<int> weeklyData = [0, 0, 0, 0, 0, 0, 0];
        int totalWeeklyWorkouts = 0;
        int totalWeeklyCalories = 0;
        int totalWeeklyMinutes = 0;

        // Process completed workouts to calculate weekly data
        for (var doc in completedWorkoutsSnapshot.docs) {
          final data = doc.data();
          final completedAt = (data['completedAt'] as Timestamp).toDate();
          final dayOfWeek = completedAt.weekday - 1; // Monday = 0, Sunday = 6

          // Extract workout title to get the actual exercise list from our workout data
          final workoutTitle = data['title'] as String;
          final workout = workouts.firstWhere((w) => w.title == workoutTitle, orElse: () => workouts[0]);

          // Calculate total calories burned for this workout based on exercises
          double totalCalories = 0;
          int totalMinutes = 0;
          for (Exercise exercise in workout.exerciseList) {
            totalCalories += exercise.getCaloriesBurned();
            totalMinutes += (exercise.duration / 60).round(); // Convert seconds to minutes
          }

          // Check if the workout was cheated
          bool isCheated = data['isCheated'] == true;

          // Add to the appropriate day, incrementing by 1 for each workout completed (instead of calories)
          // Only increment if the workout was not cheated
          if (dayOfWeek >= 0 && dayOfWeek < 7 && !isCheated) {
            weeklyData[dayOfWeek] += 1; // Increment by 1 for each workout completed on that day - this is used for the daily chart
          }

          // Add to weekly totals (include cheated workouts in count but potentially handle them differently)
          // Only increment the total weekly workouts if the workout was not cheated
          if (!isCheated) {
            totalWeeklyWorkouts++;
          }
          totalWeeklyCalories += totalCalories.floor();
          totalWeeklyMinutes += totalMinutes;
        }

        setState(() {
          _weeklyWorkoutData = weeklyData;
          _weeklyWorkoutsCount = totalWeeklyWorkouts;
          _weeklyCalories = totalWeeklyCalories;
          _weeklyMinutes = totalWeeklyMinutes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weekly progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to get the start of the week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    int daysFromMonday = date.weekday - 1; // Monday is 1, so subtract 1
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  @override
  Widget build(BuildContext context) {
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
          onRefresh: _loadWeeklyProgressData,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Card
                  Container(
                    width: double.infinity,
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
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.fitness_center,
                            label: "Workouts",
                            value: _weeklyWorkoutsCount.toString(),
                            color: Colors.orange, // Orange for workouts
                          ),
                          _buildStatItem(
                            icon: Icons.local_fire_department,
                            label: "kcal",
                            value: _weeklyCalories.toString(),
                            color: const Color(0xFFFF6B35), // Red orange for kcal
                          ),
                          _buildStatItem(
                            icon: Icons.timer,
                            label: "Minutes",
                            value: _weeklyMinutes.toString(),
                            color: Colors.blue, // Blue for minutes
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Weekly Goal
                  const Text(
                    "Weekly Goal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Progress Tracking Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressTrackingScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Progress Tracking",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProgressTrackingScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "More",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Bar chart visualization - now shows number of workouts per day instead of calories
                            Container(
                              height: 150,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: _weeklyWorkoutData.isNotEmpty
                                            ? (_weeklyWorkoutData.reduce((a, b) => a > b ? a : b) + 2).toDouble()
                                            : 5, // Dynamic maxY based on data, with appropriate increment for workout counts
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: 1,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: Colors.grey.withOpacity(0.3),
                                              strokeWidth: 0.5,
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                switch (value.toInt()) {
                                                  case 0:
                                                    return Text(
                                                      'Mon',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 1:
                                                    return Text(
                                                      'Tue',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 2:
                                                    return Text(
                                                      'Wed',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 3:
                                                    return Text(
                                                      'Thu',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 4:
                                                    return Text(
                                                      'Fri',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 5:
                                                    return Text(
                                                      'Sat',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  case 6:
                                                    return Text(
                                                      'Sun',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  default:
                                                    return Text('');
                                                }
                                              },
                                              reservedSize: 30,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                  ),
                                                );
                                              },
                                              reservedSize: 35,
                                              interval: 1,
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        barGroups: List.generate(7, (i) {
                                          return BarChartGroupData(
                                            x: i,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _weeklyWorkoutData[i].toDouble(),
                                                color: i == DateTime.now().weekday - 1
                                                    ? const Color(0xFFFF6B35) // Today's color
                                                    : const Color(0xFFFF6B35).withOpacity(0.5), // Other days color
                                                width: 10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 15),
                            // Streaks visualization
                            const Text(
                              "Streaks",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 20,
                              child: Row(
                                children: List.generate(7, (index) {
                                  bool hasWorkout = _weeklyWorkoutData[index] > 0;
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasWorkout
                                            ? Colors.green
                                            : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildTab(_tabTitles[0], 0),
                        _buildTab(_tabTitles[1], 1),
                        _buildTab(_tabTitles[2], 2),
                        _buildTab(_tabTitles[3], 3),
                      ],
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // Body Focus Tabs Choices
  Widget _buildTab(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? const Color(0xFFFF6B35)
                : Colors.transparent,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Workout List Section - Filtered based on selected tab
  Widget _buildWorkoutList() {
    // Filter workouts based on selected tab
    List<Workout> filteredWorkouts = workouts.where((workout) {
      return workout.bodyFocus.toLowerCase() == _tabTitles[_selectedTabIndex].toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display number of workouts for the selected category
        Text(
          "${filteredWorkouts.length} ${_tabTitles[_selectedTabIndex]} Workouts",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        // Check if there are workouts for the selected category
        if (filteredWorkouts.isEmpty)
          const Center(
            child: Text(
              "No workouts available for this category",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          )
        else
          // Build the list of workout cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the list view since the parent is already scrollable
            itemCount: filteredWorkouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(filteredWorkouts[index]);
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
                  onWorkoutCompleted: _loadWeeklyProgressData, // Pass callback to refresh data when workout is completed
                  onWorkoutReset: _loadWeeklyProgressData, // Pass callback to refresh data when workout is reset
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video preview box with thumbnail
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            workout.thumbnailAsset, // Use the thumbnail asset from the workout data
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if the image fails to load
                              return const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),
                      // Status indicator overlay
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
                  ),
                  const SizedBox(width: 12),
                  // Video details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.title, // Use title from workout data
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              workout.duration, // Use duration from workout data
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                workout.exercises, // Use exercises from workout data
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getLevelColor(workout.level).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                workout.level, // Use level from workout data
                                style: TextStyle(
                                  color: _getLevelColor(workout.level),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCheated ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCheated ? Colors.red : Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isCheated ? 'Cheated' : 'Done',
                                  style: TextStyle(
                                    color: isCheated ? Colors.red : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
    );
  }

  // Helper method to get color based on workout level
  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
