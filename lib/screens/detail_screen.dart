import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'add_data_screen.dart'; // Add data screen
import 'vitality_info_screen.dart'; // Vitality info screen
import 'calories_info_screen.dart'; // Calories info screen
import 'moving_info_screen.dart'; // Moving info screen
import 'dart:ui' as ui;

class DetailScreen extends StatefulWidget {
  final String title;

  const DetailScreen({super.key, required this.title});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String selectedDate;
  late String firstInputDate;
  late String lastInputDate;
  int _currentIndex = 0; // For tab navigation
  int _timeTab = 0; // For Day/Week/Month tabs (0: Day, 1: Week, 2: Month)

  @override
  void initState() {
    super.initState();
    // Initialize with today's date
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Initialize sample dates for the date range
    firstInputDate = "2025-02-13"; // Sample first input date
    lastInputDate = "2025-02-25"; // Sample last input date
  }

  String _getFormattedDateRange() {
    // Format the date range as "13 February - 25 February"
    final firstDate = DateFormat('yyyy-MM-dd').parse(firstInputDate);
    final lastDate = DateFormat('yyyy-MM-dd').parse(lastInputDate);

    final firstFormatted = DateFormat('dd MMMM').format(firstDate);
    final lastFormatted = DateFormat('dd MMMM').format(lastDate);

    return '$firstFormatted - $lastFormatted';
  }

  @override
  Widget build(BuildContext context) {
    // Format selected date as "day, full month name, year"
    final formattedDate = DateFormat(
      'dd MMMM yyyy',
    ).format(DateFormat('yyyy-MM-dd').parse(selectedDate));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            // Only show date picker for Weight screen and non-BMI screens
            if (widget.title != "BMI") ...[
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateFormat('yyyy-MM-dd').parse(selectedDate),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = DateFormat(
                        'yyyy-MM-dd',
                      ).format(pickedDate);
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display either single date or date range based on current tab
                    if (widget.title == "Weight" && _currentIndex == 1) ...[
                      // Trend tab - show date range
                      Text(
                        _getFormattedDateRange(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ] else if (widget.title == "Calories" ||
                        widget.title == "Steps" ||
                        widget.title == "Moving") ...[
                      // For Calories, Steps, Moving - show the formatted date and make it clickable
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      // Latest tab or other screens - show single date
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (widget.title == "Body Fat %") ...[
            // Plus button for Body Fat % page
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                // Navigate to Add Data screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDataScreen(title: widget.title),
                  ),
                );
              },
            ),
          ] else if (widget.title == "Vitality Score") ...[
            // No add button for Vitality Score - it's calculated automatically
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[800], // Grey background for popup menu
              onSelected: (String result) {
                // Handle menu item selection
                if (result == 'all_data') {
                  // Handle "All data" selection
                } // Note: No 'add_data' option for Vitality Score
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'all_data',
                  child: Text(
                    'All data',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ] else ...[
            // Original popup menu for other pages
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[800], // Grey background for popup menu
              onSelected: (String result) {
                // Handle menu item selection
                if (result == 'all_data') {
                  // Handle "All data" selection
                } else if (result == 'add_data') {
                  // Navigate to Add Data screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDataScreen(title: widget.title),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'all_data',
                  child: Text(
                    'All data',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'add_data',
                  child: Text(
                    'Add data',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show tabs and weight-specific content only for Weight screen
              if (widget.title == "Weight") ...[
                // Tab navigation with animation
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _currentIndex == 0
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'Latest',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _currentIndex == 1
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'Trend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content that changes based on the selected tab
                if (_currentIndex == 0) ...[
                  // Latest tab content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Vertically center align
                        children: const [
                          Text(
                            '60.0', // Sample weight value
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40, // Large font size for the number
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 4,
                          ), // Small space between number and unit
                          Text(
                            'kg', // Weight unit
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14, // Smaller font size for the unit
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 2,
                      ), // Reduced space between weight and date
                      Text(
                        '15 September 2025', // Sample date
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Graph placeholder for Weight
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.show_chart,
                            color: Colors.green,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Latest Weight Data",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "X-axis: Time | Y-axis: Kilograms",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Modern Body Composition card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Modern Header with Icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.accessibility,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Body Composition",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Modern Info Icon
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Show information about body composition
                                  _showBodyCompositionInfo(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Modern Data Display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left section - Weight information with modern styling
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Weight",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "65.0 kg",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Suggested",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Vertical line separator with modern styling
                              Container(
                                width: 1,
                                height: 60,
                                color: Colors.white38,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              // Right section - BMI information with modern styling and clickable area
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: () {
                                    // Show BMI graph popup
                                    _showBMIPopup(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252525),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "BMI",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // BMI text and value
                                            const Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "22.0",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  "Normal",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Modern Arrow icon
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Modern Progress Indicators
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Weight Progress
                              const Text(
                                "Weight Progress",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Modern Linear Progress Bar
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    // Progress Fill
                                    Container(
                                      width:
                                          120, // Example width based on progress
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Goal: 62.0 kg",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "Remaining: 3.0 kg",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Trend tab content
                  // High and Low values with modern design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // High value card
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: MediaQuery.of(context).size.width / 2.3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "High",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "65.0kg",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Low value card
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: MediaQuery.of(context).size.width / 2.3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Low",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "58.5kg",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Modern graph visualization for Trend
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
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
                      child: Column(
                        children: [
                          // Graph header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Weight Trend",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                  "7 days",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Graph area with gradient background
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF191919).withOpacity(0.5),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: CustomPaint(
                                painter: WeightTrendChartPainter(),
                                size: Size(double.infinity, 150),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Changes card with modern design
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "7-day",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              "0.00kg",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              "Weight",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Progress indicator
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              children: [
                                // Progress fill
                                Container(
                                  width: 100, // Example width based on progress
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.green,
                                        Colors.greenAccent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (widget.title == "BMI") ...[
                // Modern BMI Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern BMI Header with Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.monitor_heart,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "BMI Index",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Modern Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getBMIColorFromValue(),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getBMILevelFromValue(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Large BMI Value with Modern Styling
                        Center(
                          child: Text(
                            _getCurrentValue(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Center(
                          child: Text(
                            "Body Mass Index",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Modern Gradient Bar with Indicator
                        Stack(
                          children: [
                            // Background Gradient Bar
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.blue, // Low BMI (< 18.5)
                                    Colors.green, // Normal BMI (18.5-24.9)
                                    Colors.orange, // High BMI (25.0-29.9)
                                    Colors.deepOrange, // Very High BMI (≥ 30.0)
                                  ],
                                  stops: [
                                    0.24, // End of Low range
                                    0.49, // End of Normal range
                                    0.74, // End of High range
                                    1.0, // End of Very High range
                                  ],
                                ),
                              ),
                            ),
                            // Position Indicator
                            Positioned(
                              left: _getBMIIndicatorPosition(),
                              child: Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Modern Scale Labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "15",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "18.5",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "25",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "30",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "40+",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Modern Recommendation Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: _getBMIColorFromValue(),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Health Recommendation",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getBMIRecommendation(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (widget.title == "Vitality Score") ...[
                // Vitality Score Section
                // Main score display
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
                        // Score and label
                        Row(
                          children: [
                            Text(
                              _getCurrentValue(), // This will show the vitality score like "80.0"
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "7-day Vitality Score",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 7-day graph placeholder
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Color.fromARGB(255, 112, 90, 221),
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Vitality Score Chart",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Track your vitality over time",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Vitality Points System card
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
                        const Text(
                          "Vitality Points System",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 112, 90, 221),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Non-colorful bar with divisions at 10, 60, 100
                        Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              // Division markers at 10%, 60%, and 100%
                              Positioned(
                                left:
                                    0.1 *
                                    MediaQuery.of(context).size.width *
                                    0.8,
                                child: Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                left:
                                    0.6 *
                                    MediaQuery.of(context).size.width *
                                    0.8,
                                child: Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                left:
                                    1.0 *
                                    MediaQuery.of(context).size.width *
                                    0.8,
                                child: Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                              // Text labels for divisions
                              Positioned(
                                left: 0,
                                top: -15,
                                child: Text(
                                  "10",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Positioned(
                                left:
                                    0.6 *
                                        MediaQuery.of(context).size.width *
                                        0.8 -
                                    10,
                                top: -15,
                                child: Text(
                                  "60",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Positioned(
                                left:
                                    1.0 *
                                        MediaQuery.of(context).size.width *
                                        0.8 -
                                    10,
                                top: -15,
                                child: Text(
                                  "100",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Vitality Score measures the positive impact of your exercise on health over the past 7 days. Higher scores indicate better health outcomes from your physical activities.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // About Vitality Score card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VitalityInfoScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "About Vitality Score",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (widget.title == "Calories" ||
                  widget.title == "Steps" ||
                  widget.title == "Moving") ...[
                // Modern tabs for Day/Week/Month for Calories, Steps, Moving
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _timeTab = 0; // Day
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _timeTab == 0
                                  ? _getThemeColor()
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'Day',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _timeTab = 1; // Week
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _timeTab == 1
                                  ? _getThemeColor()
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'Week',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _timeTab = 2; // Month
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _timeTab == 2
                                  ? _getThemeColor()
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Modern large number display for the selected metric
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getLargeValue(), // This will show the value like "227"
                        style: TextStyle(
                          color: _getThemeColor(),
                          fontSize: 56, // Very large font size for the number
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getUnit(), // This will show the unit like "kcal", "steps", or "min"
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18, // Smaller font size for the unit
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Modern statistics chart with improved styling
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
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
                    child: CustomPaint(
                      painter: StatChartPainter(
                        title: widget.title,
                        timeTab: _timeTab,
                      ),
                      size: Size(double.infinity, 180),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Modern summary card with enhanced design
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _getThemeColor().withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForMetric(),
                                color: _getThemeColor(),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getSummaryTitle(), // This will show "Daily Summary", "Weekly Summary", or "Monthly Summary"
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                          color: Colors.white38,
                          height: 1,
                          thickness: 0.5,
                        ),
                        const SizedBox(height: 16),
                        // Two-column layout with separator for summary card
                        Row(
                          children: [
                            // Left side: Value and Total
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_getLargeValue()} ${_getUnit()}", // This will show "27 kcal", "8432 steps", or "45 min"
                                    style: TextStyle(
                                      color:
                                          _getThemeColor(), // Dynamic color based on metric
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Vertical separator line
                            Container(
                              width: 0.5,
                              height: 40,
                              color: Colors.white38,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // Right side: Average (only for Week and Month tabs)
                            if (_timeTab > 0) ...[
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${_getAverageValue()} ${_getUnit()}", // This will show average value
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Average",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Modern About card with enhanced styling
                GestureDetector(
                  onTap: () {
                    // Navigate to about page for the specific metric
                    _showAboutInfo(context);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _getThemeColor(),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "About ${widget.title}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Graph placeholder (in a real app, you would use a charting library like fl_chart)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.show_chart,
                          color: Colors.orange,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Graph Visualization for ${widget.title}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Sample data visualization",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // History section for Body Fat % page
                if (widget.title == "Body Fat %") ...[
                  // Modern History card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // History title with icon
                          Row(
                            children: [
                              Icon(Icons.history, color: Colors.blue, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "History",
                                style: TextStyle(
                                  color: Colors.blue, // Blue color for label
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Optional: Add a sort button or other controls here
                            ],
                          ),
                          const SizedBox(height: 16),

                          // History items - sample data with modern design
                          _buildModernHistoryItem(
                            "2025-09-20",
                            "10:30 AM",
                            "22.5%",
                          ),
                          const SizedBox(height: 12),
                          _buildModernHistoryItem(
                            "2025-09-15",
                            "09:15 AM",
                            "23.1%",
                          ),
                          const SizedBox(height: 12),
                          _buildModernHistoryItem(
                            "2025-09-10",
                            "11:45 AM",
                            "23.8%",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Summary section for non-Body Fat % and non-BMI pages
                if (widget.title != "Body Fat %") ...[
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
                          const Text(
                            "Summary",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryItem(
                            "Current Value",
                            _getCurrentValue(),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryItem(
                            "7-Day Average",
                            _getAverageValue(),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryItem("Trend", _getTrend()),
                          const SizedBox(height: 8),
                          _buildSummaryItem("Goal", _getGoal()),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Build history item for Body Fat % page
  Widget _buildHistoryItem(String date, String time, String percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white38, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Date and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date in big font
              Text(
                DateFormat(
                  'MMMM d, yyyy',
                ).format(DateFormat('yyyy-MM-dd').parse(date)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Time below date
              Text(
                time,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          // Right side: Percentage in big font
          Text(
            percentage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Build modern history item for Body Fat % page
  Widget _buildModernHistoryItem(String date, String time, String percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(
          0xFF151515,
        ), // Slightly different background for distinction
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Date and time with better typography
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat(
                  'MMMM d, yyyy',
                ).format(DateFormat('yyyy-MM-dd').parse(date)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          // Right side: Percentage with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
            ),
            child: Text(
              percentage,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sample data methods (in a real app, this would come from your data source)
  String _getCurrentValue() {
    switch (widget.title) {
      case "Body Fat %":
        return "22.5%";
      case "Weight":
        return "60.0 kg";
      case "BMI":
        return "22.0";
      case "Vitality Score":
        return "80.0";
      default:
        return "N/A";
    }
  }

  String _getAverageValue() {
    switch (widget.title) {
      case "Body Fat %":
        return "23.2%";
      case "Weight":
        return "59.8 kg";
      case "BMI":
        return "21.8";
      case "Vitality Score":
        return "78.5";
      default:
        return "N/A";
    }
  }

  String _getTrend() {
    switch (widget.title) {
      case "Body Fat %":
        return "↓ Decreasing";
      case "Weight":
        return "→ Stable";
      case "BMI":
        return "→ Stable";
      case "Vitality Score":
        return "↑ Improving";
      default:
        return "N/A";
    }
  }

  String _getGoal() {
    switch (widget.title) {
      case "Body Fat %":
        return "20.0%";
      case "Weight":
        return "62.0 kg";
      case "BMI":
        return "22.0";
      case "Vitality Score":
        return "85.0";
      default:
        return "N/A";
    }
  }

  void _showBMIPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54, // Semi-transparent background
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 400,
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20, // Space at the bottom
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF191919),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "BMI Categories",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // BMI Graph
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Low - Blue
                            _buildBMICategory("Low", "< 18.5", Colors.blue),
                            // Normal - Green
                            _buildBMICategory(
                              "Normal",
                              "18.5 - 24.9",
                              Colors.green,
                            ),
                            // High - Yellow
                            _buildBMICategory(
                              "High",
                              "25.0 - 29.9",
                              Colors.yellow,
                            ),
                            // Very High - Orange
                            _buildBMICategory(
                              "Very High",
                              "≥ 30.0",
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Your BMI section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                "Your BMI",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "22.0",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Normal",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // Slide up animation from bottom
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Start from below the screen
                end: Offset.zero, // End at its final position
              ).animate(animation),
              child: child,
            );
          },
    );
  }

  Widget _buildBMICategory(String category, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Text(
          range,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  // Helper method to get BMI level from the value
  String _getBMILevelFromValue() {
    String bmiValueStr = _getCurrentValue();
    double bmiValue =
        double.tryParse(bmiValueStr) ?? 22.0; // Default to 2.0 if parsing fails

    if (bmiValue < 18.5) {
      return "Low";
    } else if (bmiValue >= 18.5 && bmiValue <= 24.9) {
      return "Normal";
    } else if (bmiValue >= 25.0 && bmiValue <= 29.9) {
      return "High";
    } else {
      return "Very High";
    }
  }

  // Helper method to get BMI color based on the value
  Color _getBMIColorFromValue() {
    String bmiValueStr = _getCurrentValue();
    double bmiValue =
        double.tryParse(bmiValueStr) ?? 22.0; // Default to 2.0 if parsing fails

    if (bmiValue < 18.5) {
      return Colors.blue; // Low BMI
    } else if (bmiValue >= 18.5 && bmiValue <= 24.9) {
      return Colors.green; // Normal BMI
    } else if (bmiValue >= 25.0 && bmiValue <= 29.9) {
      return Colors.orange; // High BMI
    } else {
      return Colors.deepOrange; // Very High BMI
    }
  }

  // Helper method to get BMI indicator position for the modern gradient bar
  double _getBMIIndicatorPosition() {
    String bmiValueStr = _getCurrentValue();
    double bmiValue =
        double.tryParse(bmiValueStr) ??
        22.0; // Default to 22.0 if parsing fails

    // Clamp the value between 15 and 40 for positioning
    double clampedValue = bmiValue.clamp(15.0, 40.0);

    // Calculate percentage position (0% at 15, 100% at 40)
    double percentage = (clampedValue - 15.0) / (40.0 - 15.0);

    // Return position in pixels (accounting for container padding)
    return percentage * 300; // Assuming container width of ~300px
  }

  // Helper method to get BMI recommendation based on the value
  String _getBMIRecommendation() {
    String bmiValueStr = _getCurrentValue();
    double bmiValue =
        double.tryParse(bmiValueStr) ??
        22.0; // Default to 22.0 if parsing fails

    if (bmiValue < 18.5) {
      return "BMI is low. Consider consulting a healthcare professional to develop a healthy eating plan.";
    } else if (bmiValue >= 18.5 && bmiValue <= 24.9) {
      return "BMI is normal. Keep eating healthy and exercise regularly to avoid the accumulation of abdominal fat.";
    } else if (bmiValue >= 25.0 && bmiValue <= 29.9) {
      return "BMI is high. Consider incorporating more physical activity and a balanced diet to maintain a healthy weight.";
    } else {
      return "BMI is very high. It's recommended to consult with a healthcare professional for guidance on weight management.";
    }
  }

  // Helper method to get large value for Calories, Steps, Moving
  String _getLargeValue() {
    switch (widget.title) {
      case "Calories":
        return "227"; // Sample value
      case "Steps":
        return "8432"; // Sample value
      case "Moving":
        return "45"; // Sample value
      default:
        return "0";
    }
  }

  // Helper method to get unit for Calories, Steps, Moving
  String _getUnit() {
    switch (widget.title) {
      case "Calories":
        return "kcal";
      case "Steps":
        return "steps";
      case "Moving":
        return "min";
      default:
        return "";
    }
  }

  // Helper method to get summary title based on selected time tab
  String _getSummaryTitle() {
    if (_timeTab == 0) {
      return "Daily Summary";
    } else if (_timeTab == 1) {
      return "Weekly Summary";
    } else {
      return "Monthly Summary";
    }
  }

  // Helper method to show about info
  void _showAboutInfo(BuildContext context) {
    if (widget.title == "Calories") {
      // Navigate to the new dedicated Calories info screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CaloriesInfoScreen()),
      );
    } else if (widget.title == "Moving") {
      // Navigate to the new dedicated Moving info screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MovingInfoScreen()),
      );
    } else {
      // For Steps and other metrics, keep the original popup behavior
      String aboutText = "";
      if (widget.title == "Steps") {
        aboutText =
            "Steps track your daily walking activity. Walking is a simple, low-impact exercise that can improve cardiovascular health, strengthen bones, and boost mood. The average person takes about 3,000-4,000 steps per day.";
      }

      showGeneralDialog(
        context: context,
        barrierColor: Colors.black54, // Semi-transparent background
        barrierDismissible: true,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 400,
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20, // Space at the bottom
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF191919),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "About ${widget.title}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // About content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              aboutText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
        transitionBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              // Slide up animation from bottom
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0), // Start from below the screen
                  end: Offset.zero, // End at its final position
                ).animate(animation),
                child: child,
              );
            },
      );
    }
  }

  // Helper method to get color based on metric type
  Color _getMetricColor() {
    switch (widget.title) {
      case "Calories":
        return const Color(0xFFFF4500); // Red orange color
      case "Steps":
        return Colors.orange; // Orange color
      case "Moving":
        return Colors.blue; // Blue color
      default:
        return Colors.white; // Default color
    }
  }

  // Helper method to get theme color based on metric type
  Color _getThemeColor() {
    switch (widget.title) {
      case "Calories":
        return const Color(0xFFFF6B35); // Modern red-orange color
      case "Steps":
        return const Color(0xFFFF9800); // Modern orange color
      case "Moving":
        return const Color(0xFF2196F3); // Modern blue color
      default:
        return Colors.orange; // Default to orange
    }
  }

  // Helper method to get icon for the metric type
  IconData _getIconForMetric() {
    switch (widget.title) {
      case "Calories":
        return Icons.local_fire_department;
      case "Steps":
        return Icons.directions_walk;
      case "Moving":
        return Icons.directions_run;
      default:
        return Icons.visibility;
    }
  }

  // Method to show information about body composition
  void _showBodyCompositionInfo(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54, // Semi-transparent background
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 400,
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20, // Space at the bottom
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF191919),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Body Composition",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Information content
                      const Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Body composition refers to the proportion of fat, muscle, bone, and water in your body. It's a more comprehensive measure of health than weight alone.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Understanding Your Metrics:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "• Weight: Your total body weight including fat, muscle, bone, and water.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "• BMI (Body Mass Index): A calculation based on your height and weight that provides a general indication of whether your weight is healthy.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "• Body Fat Percentage: The percentage of your total weight that is fat tissue.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Why It Matters:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Monitoring your body composition can help you understand changes in your health and fitness over time. It can reveal whether weight changes are due to fat loss, muscle gain, or other factors.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // Slide up animation from bottom
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Start from below the screen
                end: Offset.zero, // End at its final position
              ).animate(animation),
              child: child,
            );
          },
    );
  }

  // Removed the vitality info popup method since we're navigating to a new screen
} // End of _DetailScreenState class

// Weight Trend Chart Painter class
class WeightTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      double y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw vertical grid lines
    for (int i = 0; i <= 6; i++) {
      double x = size.width / 6 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Sample weight data for 7 days (in kg)
    List<double> weights = [60.5, 61.2, 60.8, 62.1, 61.7, 62.3, 62.0];

    // Find min and max weights for scaling
    double minWeight = weights.reduce((a, b) => a < b ? a : b);
    double maxWeight = weights.reduce((a, b) => a > b ? a : b);

    // Add some padding to the scale
    double padding = (maxWeight - minWeight) * 0.1;
    minWeight -= padding;
    maxWeight += padding;

    // Create a path for the chart line
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    List<Offset> points = [];

    // Calculate points for the chart
    for (int i = 0; i < weights.length; i++) {
      double x = size.width / (weights.length - 1) * i;
      double y =
          size.height -
          ((weights[i] - minWeight) / (maxWeight - minWeight)) * size.height;
      points.add(Offset(x, y));
    }

    // Draw the filled area under the line
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw the line chart
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], linePaint);
      }

      // Draw data points
      final pointPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      for (int i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], 5, pointPaint);
        canvas.drawCircle(points[i], 3, Paint()..color = Colors.black);
      }
    }

    // Draw Y-axis labels
    final labelPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;

    final labelTextPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      double value = minWeight + (maxWeight - minWeight) * (1 - i / 4);
      double y = size.height / 4 * i;

      labelTextPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(color: Colors.white70, fontSize: 10),
      );

      labelTextPainter.layout();
      labelTextPainter.paint(canvas, Offset(size.width - 25, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Statistics Chart Painter class for Calories, Steps, Moving
class StatChartPainter extends CustomPainter {
  final String title;
  final int timeTab; // 0: Day, 1: Week, 2: Month

  StatChartPainter({required this.title, required this.timeTab});

  // Helper method to get theme color based on metric type
  Color _getThemeColor() {
    switch (title) {
      case "Calories":
        return const Color(0xFFFF6B35); // Modern red-orange color
      case "Steps":
        return const Color(0xFFFF9800); // Modern orange color
      case "Moving":
        return const Color(0xFF2196F3); // Modern blue color
      default:
        return const Color(0xFFFF9800); // Default to modern orange
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getThemeColor()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Define sample data based on the title and time tab
    List<double> values = [];
    List<String> labels = [];
    double maxValue = 0;

    if (timeTab == 0) {
      // Day tab
      // Hourly data for the current day (24 hours)
      values = [
        0,
        2,
        1,
        0,
        5,
        8,
        12,
        6,
        10,
        15,
        18,
        2,
        20,
        25,
        24,
        22,
        18,
        15,
        12,
        8,
        5,
        3,
      ];
      labels = ["", "6AM", "", "", "", "12PM", "", "", "6PM", "", ""];
      maxValue = 30;
    } else if (timeTab == 1) {
      // Week tab
      // Daily data for the week (7 days)
      values = [120, 150, 130, 180, 220, 190, 160];
      labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      maxValue = 250;
    } else {
      // Month tab
      // Weekly data for the month (4 weeks)
      values = [800, 950, 875, 1020];
      labels = ["Week 1", "Week 2", "Week 3", "Week 4"];
      maxValue = 1200;
    }

    // Draw y-axis labels (0, 6, 12, 24, 30) for calories, or appropriate values for other metrics
    double yStep = size.height / 4; // Divide height into 4 segments
    List<double> yValues = [
      0,
      maxValue * 0.25,
      maxValue * 0.5,
      maxValue * 0.75,
      maxValue,
    ];

    for (int i = 0; i < yValues.length; i++) {
      double y = size.height - (i * yStep);
      TextPainter(
          text: TextSpan(
            text: yValues[i].toInt().toString(),
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          textDirection: ui.TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(5, y - 6)); // Move labels to the left side
    }

    // Draw grid lines for y-axis
    for (int i = 0; i < 5; i++) {
      double y = size.height - (i * yStep);
      canvas.drawLine(
        Offset(30, y), // Start from left edge
        Offset(size.width, y), // End at the right edge
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 0.5,
      );
    }

    // Draw x-axis labels
    double xStep = size.width / (labels.length - 1);
    for (int i = 0; i < labels.length; i++) {
      double x = i * xStep;
      TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          textDirection: ui.TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(x - 10, size.height - 15));
    }

    // Draw the line chart
    List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      double x = (size.width - 40) / (values.length - 1) * i + 40;
      double y =
          size.height - 20 - ((values[i] / maxValue) * (size.height - 40));
      points.add(Offset(x, y));
    }

    // Draw line connecting the points
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw points
    for (Offset point in points) {
      canvas.drawCircle(point, 4, paint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.black);
    }

    // Draw gradient under the line
    if (points.length > 1) {
      final themeColor = _getThemeColor();
      final gradient = LinearGradient(
        colors: [themeColor.withOpacity(0.4), themeColor.withOpacity(0.1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      Path path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, size.height - 20);
      path.lineTo(points.first.dx, size.height - 20);
      path.close();

      canvas.drawPath(path, Paint()..shader = gradient);
    }
  }

  @override
  bool shouldRepaint(StatChartPainter oldDelegate) => false;
}
