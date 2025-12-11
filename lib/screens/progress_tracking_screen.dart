import 'package:flutter/material.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Suggested Goals Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              "Suggested Goal",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Complete 3 workouts this week",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Add goal functionality
                              },
                              child: Row(
                                children: [
                                  const Text(
                                    "Add",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Icon(
                                    Icons.add,
                                    color: Colors.orange,
                                    size: 16,
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

                // Daily Suggested Goals
                const Text(
                  "Daily Suggested Goals",
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
                      children: [
                        _buildDailyGoalItem("Workout", "30 min", true),
                        const Divider(height: 20, color: Colors.grey),
                        _buildDailyGoalItem("Cardio", "20 min", false),
                        const Divider(height: 20, color: Colors.grey),
                        _buildDailyGoalItem("Stretching", "10 min", false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                              const Text(
                                "7 days",
                                style: TextStyle(
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
                              const Text(
                                "15 reps",
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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

                // Day Labels (S, M, T, W, TH, F, S)
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDayLabel("S"),
                            _buildDayLabel("M"),
                            _buildDayLabel("T"),
                            _buildDayLabel("W"),
                            _buildDayLabel("TH"),
                            _buildDayLabel("F"),
                            _buildDayLabel("S"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Calendar days for current month (example)
                        _buildCalendarRow([1, 2, 3, 4, 5, 6, 7]),
                        _buildCalendarRow([8, 9, 10, 11, 12, 13, 14]),
                        _buildCalendarRow([15, 16, 17, 18, 19, 20, 21]),
                        _buildCalendarRow([22, 23, 24, 25, 26, 27, 28]),
                        _buildCalendarRow([29, 30, 31, "", "", ""]),
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
                        _buildPersonalRecordItem(
                          "Bench Press",
                          "120 lbs",
                          "Oct 1, 2024",
                        ),
                        const Divider(height: 20, color: Colors.grey),
                        _buildPersonalRecordItem(
                          "Squat",
                          "180 lbs",
                          "Sep 28, 2024",
                        ),
                        const Divider(height: 20, color: Colors.grey),
                        _buildPersonalRecordItem(
                          "Deadlift",
                          "220 lbs",
                          "Sep 25, 2024",
                        ),
                        const Divider(height: 20, color: Colors.grey),
                        _buildPersonalRecordItem(
                          "Pull-ups",
                          "15 reps",
                          "Sep 20, 2024",
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

  Widget _buildDailyGoalItem(String goal, String target, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: completed ? Colors.green : Colors.grey),
              color: completed ? Colors.green : Colors.transparent,
            ),
            child: completed
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            goal,
            style: TextStyle(
              color: completed ? Colors.green : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            target,
            style: TextStyle(
              color: completed ? Colors.green : Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String day) {
    return SizedBox(
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

  Widget _buildCalendarRow(List<dynamic> days) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          if (day == "") {
            return const SizedBox(width: 30, height: 30);
          }
          bool isToday = day == 15; // Example: day 15 is today
          bool hasWorkout = [
            5,
            10,
            12,
            15,
            20,
            25,
          ].contains(day); // Example workout days

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
                      color: hasWorkout
                          ? Colors.green
                          : Colors.grey.withOpacity(0.5),
                    ),
            ),
            child: Center(
              child: Text(
                day.toString(),
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
        }).toList(),
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
