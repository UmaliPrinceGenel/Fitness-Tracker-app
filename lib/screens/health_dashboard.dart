import 'package:flutter/material.dart';
import '../widgets/semi_circle_progress.dart';
import 'detail_screen.dart';
import 'dart:math' as math;

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SizedBox(
        height: 87, // Increased from default ~60px to 62px
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Health",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run),
              label: "Workout",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Community",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sticky header with "Health" text and "+" button
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight:
                  60, // <-- HEIGHT OF HEADER CONTAINER (Change this value to adjust height)
              floating: false,
              pinned: true,
              automaticallyImplyLeading:
                  false, // Prevents automatic back button
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 30, // <-- ADJUST TOP PADDING TO LOWER "Health" TEXT
                    ), // Move "Health" slightly to the right and lower it
                    child: Text(
                      "Health",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 30, // <-- ADJUST TOP PADDING TO LOWER "+" BUTTON
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      color: Colors.grey[800], // Gray background for dropdown
                      onSelected: (String result) {
                        // Handle menu item selection
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'add',
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                ), // White text
                              ),
                            ),
                          ],
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            // Scrollable content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),

                  // Progress arc
                  Center(
                    child: Transform.translate(
                      offset: const Offset(
                        0,
                        -20, // Adjust this value to move the semi-circle higher or lower
                      ), // Move semi-circle higher
                      child: SemiCircleProgress(
                        caloriesPercent: 80.8, // 485/600
                        stepsPercent: 62.3, // 4360/7000
                        movingPercent: 15.0, // 9/60
                      ),
                    ),
                  ),

                  const SizedBox(height: 5), // Reduced space below semi-circle
                  // Activity summary card
                  SizedBox(
                    width: double.infinity,
                    height: 195, // Fixed height for the card
                    child: Card(
                      color: const Color(0xFF191919),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12), // Reduced padding
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 8,
                            ), // Symmetrical top padding
                            // Horizontal row of activity metrics with adjusted spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _MetricItem(
                                  icon: Icons.local_fire_department,
                                  iconColor: Colors.orange,
                                  label: "Calories",
                                  value: "485",
                                  goal: "/600 kcal",
                                ),
                                const SizedBox(width: 12), // Reduced spacing
                                _MetricItem(
                                  icon: Icons.directions_walk,
                                  iconColor: Colors.yellow,
                                  label: "Steps",
                                  value: "4360",
                                  goal: "/7000 steps",
                                ),
                                const SizedBox(width: 12), // Reduced spacing
                                _MetricItem(
                                  icon: Icons.directions_run,
                                  iconColor: Colors.blue,
                                  label: "Moving",
                                  value: "9",
                                  goal: "/60 mins",
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ), // Adjusted divider spacing
                            const Divider(
                              color: Colors.grey,
                              height: 16,
                              thickness: 0.2,
                            ),
                            const SizedBox(height: 8), // Symmetrical spacing
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.accessibility,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Standing: 7 hrs",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ), // Symmetrical bottom padding
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ), // Reduced space below Activity Summary Card
                  // Grid for cards (Sleep, Weight, BMI) with enlarged cards
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 2, // Increased spacing between columns
                    mainAxisSpacing: 2, // Increased spacing between rows
                    childAspectRatio: 0.89, // Increase card height
                    children: [
                      const _InfoCard(
                        title: "Body Fat %",
                        subtitle: "22.5%\n12 September | Normal",
                        progressText: "Healthy",
                        icon: Icons.opacity,
                        iconColor: Colors.blue,
                      ),
                      const _InfoCard(
                        title: "Weight",
                        subtitle: "60.00 kg\n9/12 21:11",
                        progressText: "13/09",
                        icon: Icons.monitor_weight,
                        iconColor: Colors.green,
                      ),
                      const _InfoCard(
                        title: "BMI",
                        subtitle: "80.0",
                        progressText: "",
                        icon: Icons.calculate,
                        iconColor: Colors.blue,
                      ),
                      const _InfoCard(
                        title: "Vitality Score",
                        subtitle: "80.0",
                        progressText: "",
                        icon: Icons.favorite, // Heart icon for vitality
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Reusable Widgets ---------------- //

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String goal;

  const _MetricItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align children to the start (left)
      children: [
        // Horizontal row with icon, label, and arrow
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8), // Fixed width instead of Spacer
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Value and goal below the horizontal row, aligned with icon
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24, // Larger font size for value
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          goal,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12, // Smaller font size for goal
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String progressText;
  final IconData icon;
  final Color? iconColor;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.progressText,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail screen based on card type
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(title: title)),
        );
      },
      child: Card(
        color: const Color(0xFF191919),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor ?? Colors.white, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              Text(
                progressText,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
