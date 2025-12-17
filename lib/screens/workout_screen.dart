import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'progress_tracking_screen.dart'; // Import the new progress tracking screen
import '../data/exercise_data2.dart'; // Import workout data
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
  List<int> _monthlyCategoryCounts = [0, 0, 0, 0, 0]; // Count for each category: Chest, Arms, Core, Lower Body, Shoulders
  bool _isLoading = true;

  // List of tab titles and corresponding colors
  final List<String> _tabTitles = ["Chest", "Arms", "Core", "Lower Body", "Shoulders"];
  final List<Color> _categoryColors = [
    Colors.red,      // Chest
    Colors.blue,     // Arms
    Colors.green,    // Core
    Colors.orange,   // Lower Body
    Colors.purple,   // Shoulders
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthlyCategoryData();
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
    }
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
        DateTime endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of current month

        // Query completed workouts for the current month
        final completedWorkoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('doneInfos')
            .where('completedAt', isGreaterThanOrEqualTo: startOfMonth)
            .where('completedAt', isLessThan: endOfMonth.add(const Duration(days: 1)))
            .get();

        // Initialize category counts with zeros
        List<int> categoryCounts = [0, 0, 0, 0, 0]; // For Chest, Arms, Core, Lower Body, Shoulders respectively

        // Process completed workouts to calculate category counts
        for (var doc in completedWorkoutsSnapshot.docs) {
          final data = doc.data();
          final completedAt = (data['completedAt'] as Timestamp).toDate();

          // Extract workout title to get the actual exercise list from our workout data
          final workoutTitle = data['title'] as String;
          final workout = exerciseWorkouts.firstWhere((w) => w.title == workoutTitle, orElse: () => exerciseWorkouts[0]);

          // Check if the workout was cheated
          bool isCheated = data['isCheated'] == true;

          // Determine the category of the workout and increment the count if not cheated
          if (!isCheated) {
            String bodyFocus = workout.bodyFocus.toLowerCase();
            
            // Map exercises to the new categories and increment the count
            if (bodyFocus == "chest") {
              categoryCounts[0]++; // Chest
            } else if (bodyFocus == "arm" || bodyFocus == "triceps" || bodyFocus == "biceps" || bodyFocus == "forearms") {
              categoryCounts[1]++; // Arms
            } else if (bodyFocus == "abs" || bodyFocus == "core") {
              categoryCounts[2]++; // Core
            } else if (bodyFocus == "legs" || bodyFocus == "calves" || bodyFocus == "glutes & hamstrings") {
              categoryCounts[3]++; // Lower Body
            } else if (bodyFocus == "shoulders" || bodyFocus == "traps") {
              categoryCounts[4]++; // Shoulders
            }
          }
        }

        setState(() {
          _monthlyCategoryCounts = categoryCounts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading monthly category data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
          onRefresh: _loadMonthlyCategoryData,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Category Chart
                  Container(
                    width: double.infinity,
                    height: 300, // Increased height to accommodate the chart
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
                          const Text(
                            "Monthly Category Tracking",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                    ),
                                  )
                                : PieChart(
                                    PieChartData(
                                      sections: List.generate(_tabTitles.length, (i) {
                                        return PieChartSectionData(
                                          color: _categoryColors[i],
                                          value: _monthlyCategoryCounts[i].toDouble(),
                                          title: '${_monthlyCategoryCounts[i]}',
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }),
                                      centerSpaceRadius: 30, // Creates the donut hole effect
                                      sectionsSpace: 2, // Space between sections
                                      pieTouchData: PieTouchData(
                                        enabled: true,
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          // Handle touch events if needed
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          // Legend for categories
                          Wrap(
                            spacing: 10,
                            children: List.generate(_tabTitles.length, (i) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _categoryColors[i],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_tabTitles[i]}: ${_monthlyCategoryCounts[i]}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
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
                        _buildTab(_tabTitles[4], 4),
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
    List<Workout> filteredWorkouts = exerciseWorkouts.where((workout) {
      String bodyFocus = workout.bodyFocus.toLowerCase();
      String selectedCategory = _tabTitles[_selectedTabIndex].toLowerCase();
      
      // Map exercises to the new categories
      switch(selectedCategory) {
        case "chest":
          return bodyFocus == "chest";
        case "arms":
          return bodyFocus == "arm" || bodyFocus == "triceps" || bodyFocus == "biceps" || bodyFocus == "forearms";
        case "core":
          return bodyFocus == "abs" || bodyFocus == "core";
        case "lower body":
          return bodyFocus == "legs" || bodyFocus == "calves" || bodyFocus == "glutes & hamstrings";
        case "shoulders":
          return bodyFocus == "shoulders" || bodyFocus == "traps";
        default:
          return bodyFocus == selectedCategory;
      }
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
          .collection('doneInfos')
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
                  onWorkoutCompleted: _loadMonthlyCategoryData, // Pass callback to refresh data when workout is completed
                  onWorkoutReset: _loadMonthlyCategoryData, // Pass callback to refresh data when workout is reset
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
                                "${workout.exerciseList.length} exercises", // Use actual count from exercise list
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
        bool hasShortExercises = workout.exerciseList.any((exercise) => exercise.duration > 0);
        return hasShortExercises ? "1 min" : "0 min";
      }
      return "0 min";
    }
    
    return totalMinutes > 1 ? "${totalMinutes} mins" : "${totalMinutes} min";
  }
}
