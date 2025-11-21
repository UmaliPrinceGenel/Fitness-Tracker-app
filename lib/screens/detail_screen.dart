import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_data_screen.dart';
import 'vitality_info_screen.dart';
import 'calories_info_screen.dart';
import 'moving_info_screen.dart';
import 'steps_info_screen.dart';
import 'body_composition_info_screen.dart';
import 'dart:ui' as ui;

class DetailScreen extends StatefulWidget {
  final String title;
  final double? currentValue;
  final double? goalValue;

  const DetailScreen({
    super.key,
    required this.title,
    this.currentValue,
    this.goalValue,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String selectedDate;
  int _currentIndex = 0;
  int _timeTab = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _currentData = 0.0;
  double _goalData = 0.0;
  List<double> _historicalData = [];
  List<DateTime> _historicalDates = [];
  List<DailyActivity> _dailyActivityHistory = [];
  bool _isLoading = true;

  // User profile data for calculations
  double _weight = 0.0;
  double _height = 0.0;

  @override
  void initState() {
    super.initState();
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDataFromFirebase();
  }

  Future<void> _loadDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load user profile data first
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _weight = (userData['profile']?['weight'] ?? 0.0).toDouble();
            _height = (userData['profile']?['height'] ?? 0.0).toDouble();
          });
        }

        // Load health metrics
        final healthDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('health_metrics')
            .doc('current')
            .get();

        // Load daily activity history
        final dailyActivitySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_activity')
            .orderBy('date', descending: true)
            .limit(30)
            .get();

        setState(() {
          if (healthDoc.exists) {
            final healthData = healthDoc.data()!;

            switch (widget.title) {
              case "Calories":
                _currentData = (healthData['calories'] ?? 0.0).toDouble();
                _goalData = 600.0;
                _loadTimeBasedData('calories');
                break;
              case "Steps":
                _currentData = (healthData['steps'] ?? 0).toDouble();
                _goalData = 7000.0;
                _loadTimeBasedData('steps');
                break;
              case "Moving":
                _currentData = (healthData['movingMinutes'] ?? 0.0).toDouble();
                _goalData = 60.0;
                _loadTimeBasedData('movingMinutes');
                break;
              case "Body Fat %":
                _currentData = (healthData['bodyFat'] ?? 0.0).toDouble();
                _goalData = 20.0;
                _historicalData = List<double>.from(
                  healthData['bodyFatHistory'] ?? [],
                );
                _historicalDates = _generateDatesForHistory(
                  _historicalData.length,
                );
                break;
              case "Weight":
                _currentData = _weight;
                _goalData = 62.0;
                _historicalData = List<double>.from(
                  healthData['weightHistory'] ?? [],
                );
                _historicalDates = _generateDatesForHistory(
                  _historicalData.length,
                );
                break;
              case "BMI":
                _calculateBMI();
                _goalData = 22.0;
                // No need to load historical data since we removed the trend graph
                _historicalData = [];
                _historicalDates = [];
                break;
              case "Vitality Score":
                _currentData = (healthData['vitalityScore'] ?? 0.0).toDouble();
                _goalData = 100.0;
                _historicalData = List<double>.from(
                  healthData['vitalityHistory'] ?? [],
                );
                _historicalDates = _generateDatesForHistory(
                  _historicalData.length,
                );
                break;
            }

            // Load daily activity history
            _dailyActivityHistory = dailyActivitySnapshot.docs
                .map((doc) => DailyActivity.fromMap(doc.data()))
                .toList();
          } else {
            _currentData = 0.0;
            _goalData = _getDefaultGoal();
            _historicalData = [];
            _historicalDates = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data from Firebase: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DateTime> _generateDatesForHistory(int length) {
    List<DateTime> dates = [];
    for (int i = 0; i < length; i++) {
      dates.add(DateTime.now().subtract(Duration(days: length - 1 - i)));
    }
    return dates;
  }

  void _loadTimeBasedData(String metric) {
    if (_dailyActivityHistory.isEmpty) {
      _historicalData = [];
      _historicalDates = [];
      return;
    }

    int days = _timeTab == 0 ? 1 : (_timeTab == 1 ? 7 : 30);
    int endIndex = days < _dailyActivityHistory.length
        ? days
        : _dailyActivityHistory.length;

    _historicalData = [];
    _historicalDates = [];

    for (int i = 0; i < endIndex; i++) {
      DateTime date = _dailyActivityHistory[i].date;
      double value = 0.0;

      switch (metric) {
        case 'calories':
          value = _dailyActivityHistory[i].calories;
          break;
        case 'steps':
          value = _dailyActivityHistory[i].steps.toDouble();
          break;
        case 'movingMinutes':
          value = _dailyActivityHistory[i].movingMinutes;
          break;
      }

      _historicalData.add(value);
      _historicalDates.add(date);
    }

    // Reverse to show chronological order (oldest to newest)
    _historicalData = _historicalData.reversed.toList();
    _historicalDates = _historicalDates.reversed.toList();
  }

  void _calculateBMI() {
    if (_height > 0 && _weight > 0) {
      double bmi = _weight / ((_height / 100) * (_height / 100));
      setState(() {
        _currentData = double.parse(bmi.toStringAsFixed(1));
      });
    }
  }

  double _getDefaultGoal() {
    switch (widget.title) {
      case "Calories":
        return 600.0;
      case "Steps":
        return 7000.0;
      case "Moving":
        return 60.0;
      case "Body Fat %":
        return 20.0;
      case "Weight":
        return 62.0;
      case "BMI":
        return 22.0;
      case "Vitality Score":
        return 100.0;
      default:
        return 0.0;
    }
  }

  String _getCurrentValue() {
    if (_isLoading) return "Loading...";

    switch (widget.title) {
      case "Body Fat %":
        return "${_currentData.toStringAsFixed(1)}%";
      case "Weight":
        return "${_currentData.toStringAsFixed(1)} kg";
      case "BMI":
        return _currentData.toStringAsFixed(1);
      case "Vitality Score":
        return _currentData.toStringAsFixed(1);
      case "Calories":
      case "Steps":
      case "Moving":
        return _currentData.toStringAsFixed(0);
      default:
        return "N/A";
    }
  }

  String _getAverageValue() {
    if (_historicalData.isEmpty) return "N/A";
    double average =
        _historicalData.reduce((a, b) => a + b) / _historicalData.length;
    switch (widget.title) {
      case "Body Fat %":
        return "${average.toStringAsFixed(1)}%";
      case "Weight":
        return "${average.toStringAsFixed(1)} kg";
      case "BMI":
        return average.toStringAsFixed(1);
      case "Vitality Score":
        return average.toStringAsFixed(1);
      case "Calories":
      case "Steps":
      case "Moving":
        return average.toStringAsFixed(0);
      default:
        return "N/A";
    }
  }

  String _getTrend() {
    if (_historicalData.length < 2) return "→ Stable";
    double first = _historicalData.first;
    double last = _historicalData.last;

    if (last > first) return "↑ Increasing";
    if (last < first) return "↓ Decreasing";
    return "→ Stable";
  }

  String _getGoal() {
    switch (widget.title) {
      case "Body Fat %":
        return "${_goalData.toStringAsFixed(1)}%";
      case "Weight":
        return "${_goalData.toStringAsFixed(1)} kg";
      case "BMI":
        return _goalData.toStringAsFixed(1);
      case "Vitality Score":
        return _goalData.toStringAsFixed(1);
      case "Calories":
        return "${_goalData.toInt()} kcal";
      case "Steps":
        return "${_goalData.toInt()} steps";
      case "Moving":
        return "${_goalData.toInt()} mins";
      default:
        return "N/A";
    }
  }

  String _getUnitWithGoal() {
    if (_isLoading) return _getUnit();

    switch (widget.title) {
      case "Calories":
        return "/${_goalData.toInt()} kcal";
      case "Steps":
        return "/${_goalData.toInt()} steps";
      case "Moving":
        return "/${_goalData.toInt()} mins";
      default:
        return _getUnit();
    }
  }

  String _getUnit() {
    switch (widget.title) {
      case "Calories":
        return "kcal";
      case "Steps":
        return "steps";
      case "Moving":
        return "min";
      case "Body Fat %":
        return "%";
      case "Weight":
        return "kg";
      default:
        return "";
    }
  }

  Color _getThemeColor() {
    switch (widget.title) {
      case "Calories":
        return const Color(0xFFFF6B35);
      case "Steps":
        return const Color(0xFFFF9800);
      case "Moving":
        return const Color(0xFF2196F3);
      case "Body Fat %":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.deepOrange;
  }

  double _getBMIIndicatorPosition(double width) {
    double clampedValue = _currentData.clamp(15.0, 40.0);
    double percentage = (clampedValue - 15.0) / (40.0 - 15.0);
    return percentage * width;
  }

  String _getBMIRecommendation() {
    if (_currentData < 18.5) {
      return "BMI is low. Consider consulting a healthcare professional to develop a healthy eating plan.";
    } else if (_currentData >= 18.5 && _currentData <= 24.9) {
      return "BMI is normal. Keep eating healthy and exercise regularly to avoid the accumulation of abdominal fat.";
    } else if (_currentData >= 25.0 && _currentData <= 29.9) {
      return "BMI is high. Consider incorporating more physical activity and a balanced diet to maintain a healthy weight.";
    } else {
      return "BMI is very high. It's recommended to consult with a healthcare professional for guidance on weight management.";
    }
  }

  String _getSummaryTitle() {
    if (_timeTab == 0) return "Daily Summary";
    if (_timeTab == 1) return "Weekly Summary";
    return "Monthly Summary";
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: _buildAppBarActions(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildContent()),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (widget.title == "Weight") {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDataScreen(title: widget.title),
            ),
          ),
        ),
      ];
    }
    return [];
  }

  Widget _buildContent() {
    switch (widget.title) {
      case "Weight":
        return _buildWeightContent();
      case "BMI":
        return _buildBMIContent();
      case "Vitality Score":
        return _buildVitalityContent();
      case "Calories":
      case "Steps":
      case "Moving":
        return _buildMetricContent();
      case "Body Fat %":
        return _buildBodyFatContent();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildWeightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF191919),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildTabButton('Latest', 0),
              _buildTabButton('Trend', 1),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_currentIndex == 0) ..._buildLatestWeightContent(),
        if (_currentIndex == 1) ..._buildTrendWeightContent(),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _currentIndex == index ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLatestWeightContent() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _currentData.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "kg",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        DateFormat('dd MMMM yyyy').format(DateTime.now()),
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      const SizedBox(height: 20),
      _buildWeightGraph(),
      const SizedBox(height: 20),
      _buildBodyCompositionCard(),
    ];
  }

  List<Widget> _buildTrendWeightContent() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTrendCard("High", "65.0kg", Colors.red),
          _buildTrendCard("Low", "58.5kg", Colors.green),
        ],
      ),
      const SizedBox(height: 20),
      _buildTrendGraph(),
      const SizedBox(height: 20),
      _buildChangesCard(),
    ];
  }

  Widget _buildTrendCard(String label, String value, Color color) {
    return Container(
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  label == "High" ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getBMIColor(_currentData),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getBMICategory(_currentData),
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
                  Center(
                    child: Text(
                      _currentData.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      "Body Mass Index",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FIXED BMI Scale with Proper Arrow Positioning
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      children: [
                        // BMI Scale Bar
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.orange,
                                Colors.deepOrange,
                              ],
                              stops: [0.24, 0.49, 0.74, 1.0],
                            ),
                          ),
                        ),

                        // BMI Indicator Arrow
                        Positioned(
                          left: _calculateBMIPosition(),
                          bottom: 12, // Position above the scale
                          child: Column(
                            children: [
                              Icon(
                                Icons.arrow_drop_up,
                                color: _getBMIColor(_currentData),
                                size: 32,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBMIColor(_currentData),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _currentData.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BMI Scale Labels
                  const SizedBox(height: 40), // More space for the arrow
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "15",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "18.5",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "25",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "30",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "40+",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BMI Categories
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "BMI Categories:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBMICategoryRow(
                          "Underweight",
                          "Below 18.5",
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildBMICategoryRow(
                          "Normal",
                          "18.5 - 24.9",
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildBMICategoryRow(
                          "Overweight",
                          "25.0 - 29.9",
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildBMICategoryRow(
                          "Obese",
                          "30.0 and above",
                          Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Health Recommendation
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
                                color: _getBMIColor(_currentData),
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
        ],
      ),
    );
  }

  // FIXED BMI position calculation
  double _calculateBMIPosition() {
    // Get the available width for the scale (container width minus margins)
    double availableWidth =
        MediaQuery.of(context).size.width -
        56; // 16*2 (padding) + 8*2 (margin) + 8*2 (extra)

    // BMI ranges from 15 to 40 for the scale
    double clampedValue = _currentData.clamp(15.0, 40.0);
    double percentage = (clampedValue - 15.0) / (40.0 - 15.0);

    // Calculate position, but ensure it stays within bounds
    double position = percentage * availableWidth;

    // Ensure the arrow doesn't go off the edges
    return position.clamp(
      0.0,
      availableWidth - 30,
    ); // 30 is approx half the arrow width
  }

  // Helper method for BMI category rows
  Widget _buildBMICategoryRow(String category, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          range,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVitalityContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
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
                      Text(
                        _currentData.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "7-day Vitality Score",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildVitalityPointsSystem(),
          const SizedBox(height: 20),
          _buildAboutVitalityCard(),
        ],
      ),
    );
  }

  Widget _buildMetricContent() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF191919),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildTimeTabButton('Day', 0),
              _buildTimeTabButton('Week', 1),
              _buildTimeTabButton('Month', 2),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
                _currentData.toStringAsFixed(0),
                style: TextStyle(
                  color: _getThemeColor(),
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getUnitWithGoal(),
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
              painter: RealDataChartPainter(
                data: _historicalData,
                dates: _historicalDates,
                color: _getThemeColor(),
                goal: _goalData,
                timeTab: _timeTab,
              ),
              size: const Size(double.infinity, 180),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
                      _getSummaryTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white38, height: 1, thickness: 0.5),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_currentData.toStringAsFixed(0)} ${_getUnit()}",
                            style: TextStyle(
                              color: _getThemeColor(),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Total",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_timeTab > 0 && _historicalData.isNotEmpty) ...[
                      Container(
                        width: 0.5,
                        height: 40,
                        color: Colors.white38,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${_getAverageValue()} ${_getUnit()}",
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
        GestureDetector(
          onTap: () => _showAboutInfo(context),
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
                  Icon(Icons.info_outline, color: _getThemeColor(), size: 24),
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
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyFatContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF191919),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentData.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Body Fat %",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                painter: RealDataChartPainter(
                  data: _historicalData,
                  dates: _historicalDates,
                  color: Colors.blue,
                  goal: _goalData,
                  timeTab: 2, // Always show full history for body fat
                ),
                size: const Size(double.infinity, 180),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildBodyFatHistorySection(),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      children: [
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
                const Icon(Icons.show_chart, color: Colors.orange, size: 50),
                const SizedBox(height: 10),
                Text(
                  "Graph Visualization for ${widget.title}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Real data from Firebase",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  "Current: ${_currentData.toStringAsFixed(1)}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSummarySection(),
      ],
    );
  }

  Widget _buildTimeTabButton(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timeTab = index;
          });
          _loadTimeBasedData(_getMetricKey());
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _timeTab == index ? _getThemeColor() : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMetricKey() {
    switch (widget.title) {
      case "Calories":
        return 'calories';
      case "Steps":
        return 'steps';
      case "Moving":
        return 'movingMinutes';
      default:
        return '';
    }
  }

  // Graph implementations with real data
  Widget _buildWeightGraph() => _buildRealGraph(_historicalData, Colors.green);
  Widget _buildTrendGraph() => _buildRealGraph(_historicalData, Colors.green);
  Widget _buildVitalityGraph() => _buildRealGraph(_historicalData, Colors.cyan);

  Widget _buildRealGraph(List<double> data, Color color) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomPaint(
          painter: RealDataChartPainter(
            data: data,
            dates: _historicalDates,
            color: color,
            goal: _goalData,
            timeTab: 2,
          ),
          size: const Size(double.infinity, 168),
        ),
      ),
    );
  }

  Widget _buildBodyCompositionCard() {
    return Container(
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
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BodyCompositionInfoScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Weight",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_currentData.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Suggested",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white38,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DetailScreen(title: "BMI"),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2525),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _calculateCurrentBMI().toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getBMICategory(_calculateCurrentBMI()),
                                    style: TextStyle(
                                      color: _getBMIColor(
                                        _calculateCurrentBMI(),
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weight Progress",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: (_currentData / _goalData * 100).clamp(
                          0.0,
                          100.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Goal: ${_goalData.toStringAsFixed(1)} kg",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Remaining: ${(_goalData - _currentData).toStringAsFixed(1)} kg",
                      style: const TextStyle(
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
    );
  }

  double _calculateCurrentBMI() {
    if (_height > 0 && _weight > 0) {
      return _weight / ((_height / 100) * (_height / 100));
    }
    return 0.0;
  }

  Widget _buildChangesCard() {
    double change = _historicalData.length >= 2
        ? _historicalData.last - _historicalData.first
        : 0.0;

    return Container(
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
                "${change.toStringAsFixed(2)}kg",
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
                "Weight Change",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  Container(
                    width: ((change + 5) / 10 * 100).clamp(
                      0.0,
                      100.0,
                    ), // Normalize for display
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: change >= 0
                            ? [Colors.red, Colors.redAccent]
                            : [Colors.green, Colors.greenAccent],
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
    );
  }

  Widget _buildVitalityPointsSystem() {
    double vitalityPercentage = (_currentData / _goalData * 100).clamp(
      0.0,
      100.0,
    );

    return Container(
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
                color: Color(0xFF705ADD),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Progress
                  Container(
                    width:
                        vitalityPercentage *
                        0.01 *
                        (MediaQuery.of(context).size.width - 32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF705ADD), Color(0xFF9D8AEE)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Markers
                  Positioned(
                    left: 0.1 * (MediaQuery.of(context).size.width - 32),
                    child: Container(width: 2, height: 20, color: Colors.white),
                  ),
                  Positioned(
                    left: 0.6 * (MediaQuery.of(context).size.width - 32),
                    child: Container(width: 2, height: 20, color: Colors.white),
                  ),
                  Positioned(
                    left: 0,
                    top: -15,
                    child: Text(
                      "10",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  Positioned(
                    left: 0.6 * (MediaQuery.of(context).size.width - 32) - 10,
                    top: -15,
                    child: Text(
                      "60",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 32) - 20,
                    top: -15,
                    child: Text(
                      "100",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
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
            const SizedBox(height: 10),
            Text(
              "Current Score: ${_currentData.toStringAsFixed(1)}/100",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutVitalityCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VitalityInfoScreen()),
      ),
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
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyFatHistorySection() {
    return Container(
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
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "History",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            if (_historicalData.isNotEmpty)
              ..._historicalData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                DateTime date = _historicalDates[index];
                return _buildModernHistoryItem(date, value);
              }).toList(),
            if (_historicalData.isEmpty)
              const Text(
                "No history data available",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
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
            _buildSummaryItem("Current Value", _getCurrentValue()),
            const SizedBox(height: 8),
            _buildSummaryItem("7-Day Average", _getAverageValue()),
            const SizedBox(height: 8),
            _buildSummaryItem("Trend", _getTrend()),
            const SizedBox(height: 8),
            _buildSummaryItem("Goal", _getGoal()),
          ],
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

  Widget _buildModernHistoryItem(DateTime date, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(date),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
            ),
            child: Text(
              "${percentage.toStringAsFixed(1)}%",
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

  void _showAboutInfo(BuildContext context) {
    if (widget.title == "Calories") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CaloriesInfoScreen()),
      );
    } else if (widget.title == "Moving") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MovingInfoScreen()),
      );
    } else if (widget.title == "Steps") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StepsInfoScreen()),
      );
    } else {
      showGeneralDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF191919),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          "Information about this metric will be displayed here.",
                          style: TextStyle(
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
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
    }
  }
}

// Daily Activity Model (same as in healthdashboard.dart)
class DailyActivity {
  final DateTime date;
  final int steps;
  final double calories;
  final double movingMinutes;

  DailyActivity({
    required this.date,
    required this.steps,
    required this.calories,
    required this.movingMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'calories': calories,
      'movingMinutes': movingMinutes,
    };
  }

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      date: DateTime.parse(map['date']),
      steps: map['steps'],
      calories: (map['calories'] ?? 0).toDouble(),
      movingMinutes: (map['movingMinutes'] ?? 0).toDouble(),
    );
  }
}

class RealDataChartPainter extends CustomPainter {
  final List<double> data;
  final List<DateTime> dates;
  final Color color;
  final double goal;
  final int timeTab;

  RealDataChartPainter({
    required this.data,
    required this.dates,
    required this.color,
    required this.goal,
    required this.timeTab,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawNoDataMessage(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Calculate max value for scaling
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    maxValue = maxValue > goal ? maxValue * 1.1 : goal * 1.1;
    if (maxValue == 0) maxValue = 1;

    // Draw goal line
    final goalPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double goalY = size.height - (goal / maxValue * size.height);
    canvas.drawLine(Offset(0, goalY), Offset(size.width, goalY), goalPaint);

    // Draw data points and lines
    List<Offset> points = [];
    double xStep = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double y = size.height - (data[i] / maxValue * size.height);
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw points and date labels
    final textStyle = ui.TextStyle(color: Colors.white70, fontSize: 10);

    for (int i = 0; i < points.length; i++) {
      Offset point = points[i];

      // Draw point
      canvas.drawCircle(point, 4, paint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.black);

      // Draw date label for every point or every other point depending on density
      if (data.length <= 7 || i % 2 == 0 || i == data.length - 1) {
        String dateLabel = _getDateLabel(dates[i]);
        final textPainter = TextPainter(
          text: TextSpan(
            text: dateLabel,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(point.dx - textPainter.width / 2, size.height - 15),
        );
      }
    }

    // Draw area under curve
    if (points.length > 1) {
      final gradient = LinearGradient(
        colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      Path path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.lineTo(points.first.dx, size.height);
      path.close();
      canvas.drawPath(path, Paint()..shader = gradient);
    }
  }

  String _getDateLabel(DateTime date) {
    if (timeTab == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (timeTab == 1) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  void _drawNoDataMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "No data available",
        style: TextStyle(color: Colors.white54, fontSize: 14),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(RealDataChartPainter oldDelegate) => true;
}
