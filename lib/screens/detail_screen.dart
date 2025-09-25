import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'add_data_screen.dart'; // Add data screen

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

                  // Body Composition card
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
                              const Icon(
                                Icons.accessibility,
                                color: Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Body Composition",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            color: Colors.white38,
                            height: 1,
                            thickness: 0.2,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left section - Weight information
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "65.0 kg",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                              // Vertical line separator
                              Container(
                                width: 1,
                                color: Colors.white38,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              // Right section - BMI information with clickable area
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: () {
                                    // Show BMI graph popup
                                    _showBMIPopup(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // BMI text and value
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            "22.0",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "BMI",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Arrow icon
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Trend tab content
                  // High and Low values
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: const [
                            Text(
                              "High",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "65.0kg",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191919),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: const [
                            Text(
                              "Low",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "58.5kg",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Graph placeholder for Trend
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
                            "Weight Trend Analysis",
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

                  // Changes card
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
                            children: const [
                              Icon(
                                Icons.visibility,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            color: Colors.white38,
                            height: 1,
                            thickness: 0.5,
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              "0.00kg",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              "Weight",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (widget.title == "BMI") ...[
                // BMI Card - Redesigned UI
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
                        // BMI Value and Level with separator
                        Row(
                          children: [
                            // BMI Number - Top Left
                            Text(
                              _getCurrentValue(), // This will show the BMI value like "22.0"
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Vertical Line Separator
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 12),
                            // Level - Top Right
                            Text(
                              _getBMILevelFromValue(), // This will show the level like "Normal"
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4-color horizontal representation of BMI levels
                        Container(
                          height: 30,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
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
                              ], // Stops for the color transitions
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // BMI Scale Labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Low",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Normal",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "High",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Very High",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Recommendation text
                        Text(
                          _getBMIRecommendation(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                  // History card
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
                          // History title in blue color
                          Text(
                            "History",
                            style: TextStyle(
                              color: Colors.blue, // Blue color for label
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            color: Colors.white38,
                            height: 1,
                            thickness: 0.5,
                          ),
                          const SizedBox(height: 15),

                          // History items - sample data
                          _buildHistoryItem("2025-09-20", "10:30 AM", "22.5%"),
                          const SizedBox(height: 15),
                          _buildHistoryItem("2025-09-15", "09:15 AM", "23.1%"),
                          const SizedBox(height: 15),
                          _buildHistoryItem("2025-09-10", "11:45 AM", "23.8%"),
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
}
