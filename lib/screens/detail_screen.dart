import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'sleep_info_screen.dart';
import 'calories_info_screen.dart';
import 'moving_info_screen.dart';
import 'steps_info_screen.dart';
import 'waist_measurement_info_screen.dart';
import 'dart:ui' as ui;

class DetailScreen extends StatefulWidget {
  final String title;
  final double? currentValue;
  final double? goalValue;
  final VoidCallback? onDataSaved; // Add this
  const DetailScreen({
    super.key,
    required this.title,
    this.currentValue,
    this.goalValue,
    this.onDataSaved, // Add this
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _MetricHistoryPoint {
  final DateTime date;
  final double value;

  const _MetricHistoryPoint(this.date, this.value);
}

class _DetailScreenState extends State<DetailScreen> {
  static const double _minValidHeightCm = 80.0;
  static const double _maxValidHeightCm = 250.0;
  static const double _minValidWeightKg = 20.0;
  static const double _maxValidWeightKg = 400.0;
  static const double _minDisplayBmi = 10.0;
  static const double _maxDisplayBmi = 80.0;

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

  double _parseDoubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _computeSafeBmi(double weightKg, double heightCm) {
    if (weightKg < _minValidWeightKg ||
        weightKg > _maxValidWeightKg ||
        heightCm < _minValidHeightCm ||
        heightCm > _maxValidHeightCm) {
      return 0.0;
    }

    final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    if (bmi < _minDisplayBmi || bmi > _maxDisplayBmi) {
      return 0.0;
    }

    return double.parse(bmi.toStringAsFixed(1));
  }

  bool _isDisplayableBmiPair(double weightKg, double heightCm) {
    if (weightKg < _minValidWeightKg ||
        weightKg > _maxValidWeightKg ||
        heightCm < _minValidHeightCm ||
        heightCm > _maxValidHeightCm) {
      return false;
    }

    final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    return bmi >= _minDisplayBmi && bmi <= _maxDisplayBmi;
  }

  List<_MetricHistoryPoint> _extractHistoryPoints(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String valueKey,
  ) {
    final points = <_MetricHistoryPoint>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = _parseDoubleValue(data[valueKey]);
      final dateValue = data['date'];
      DateTime? date;

      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.tryParse(dateValue);
      }

      if (value > 0 && date != null) {
        points.add(_MetricHistoryPoint(date, value));
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  double _resolveHeightForDate(
    List<_MetricHistoryPoint> heightPoints,
    DateTime target,
  ) {
    if (heightPoints.isEmpty) return _height;

    _MetricHistoryPoint selected = heightPoints.first;
    for (final point in heightPoints) {
      if (point.date.isAfter(target)) break;
      selected = point;
    }
    return selected.value;
  }

  String _getRecordedEntriesText(String label) {
    final count = _historicalData.length;
    final suffix = count == 1 ? "entry" : "entries";
    return "Recorded $count $label $suffix";
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasSleepEntryForToday() {
    final today = DateTime.now();
    return _historicalDates.any((date) => _isSameDay(date, today));
  }

  String _getSleepCoachingMessage() {
    if (!_hasSleepEntryForToday()) {
      return "Enter your new sleep hours for last night to update today's sleep record.";
    }
    if (_currentData < 7) {
      return "You need more sleep today. Try to add rest tonight or over the next few days.";
    }
    if (_currentData <= 9) {
      return "Great job. You slept the recommended number of hours today.";
    }
    return "You slept longer than the usual healthy range today. Try to balance your next days and avoid oversleep.";
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfTomorrow() {
    return _startOfToday().add(const Duration(days: 1));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadTodaySleepEntries() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_history')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfToday()))
        .where('date', isLessThan: Timestamp.fromDate(_startOfTomorrow()))
        .get();
  }

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
          final profileData = userData['profile'] as Map<String, dynamic>? ?? <String, dynamic>{};
          setState(() {
            _weight = _parseDoubleValue(profileData['weight']) > 0
                ? _parseDoubleValue(profileData['weight'])
                : _parseDoubleValue(userData['profile.weight']);
            _height = _parseDoubleValue(profileData['height']) > 0
                ? _parseDoubleValue(profileData['height'])
                : _parseDoubleValue(userData['profile.height']);
          });
        }

        // Load health metrics
        final healthDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('health_metrics')
            .doc('current')
            .get();

        // Load weight history with real dates
        final weightHistorySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('weight_history')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .get();

        // Load waist history from subcollection (for Android compatibility)
        final waistHistorySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('waist_history')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .get();

        // Load sleep history with real dates
        final sleepHistorySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sleep_history')
            .orderBy('timestamp', descending: true)
            .limit(30)
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
          _dailyActivityHistory = dailyActivitySnapshot.docs
              .map((doc) => DailyActivity.fromMap(doc.data()))
              .toList();

          if (healthDoc.exists) {
            final healthData = healthDoc.data()!;

            switch (widget.title) {
              case "kcal":
              case "Calories":
                _currentData = (healthData['weeklyCalories'] ?? 0).toDouble();
                _goalData = 2500.0;
                _loadTimeBasedData('weeklyCalories');
                break;
              case "Minutes":
              case "Steps":
                _currentData = (healthData['weeklyMinutes'] ?? 0).toDouble();
                _goalData = 300.0;
                _loadTimeBasedData('weeklyMinutes');
                break;
              case "Workouts":
              case "Moving":
                _currentData =
                    (healthData['weeklyWorkoutsCount'] ?? 0).toDouble();
                _goalData = 5.0;
                _loadTimeBasedData('weeklyWorkoutsCount');
                break;
              case "Waist Measurement":
                _currentData = waistHistorySnapshot.docs.isNotEmpty
                    ? ((waistHistorySnapshot.docs.first.data()['waist'] ?? 0.0)
                        as num)
                        .toDouble()
                    : (healthData['waistMeasurement'] ?? 0.0).toDouble();
                _goalData = 80.0;
                // Use subcollection data if main history is empty (Android compatibility)
                List<double> waistHistoryFromSubcollection = [];
                for (var doc in waistHistorySnapshot.docs) {
                  final data = doc.data();
                  waistHistoryFromSubcollection.add((data['waist'] ?? 0.0).toDouble());
                }
                waistHistoryFromSubcollection = waistHistoryFromSubcollection.reversed.toList(); // Chronological order

                _historicalData = waistHistoryFromSubcollection.isEmpty
                    ? List<double>.from(healthData['waistHistory'] ?? [])
                    : waistHistoryFromSubcollection;

                // Generate dates for the historical data
                _historicalDates = _generateDatesForHistory(_historicalData.length);
                break;
              case "Weight":
                _currentData = weightHistorySnapshot.docs.isNotEmpty
                    ? ((weightHistorySnapshot.docs.first.data()['weight'] ?? _weight)
                        as num)
                        .toDouble()
                    : (healthData['weight'] ?? _weight).toDouble();
                _goalData =
                    (healthData['weightGoalKg'] ?? widget.goalValue ?? 62.0)
                        .toDouble();
                _historicalData = [];
                _historicalDates = [];

                for (var doc in weightHistorySnapshot.docs) {
                  final data = doc.data();
                  _historicalData.add((data['weight'] ?? 0.0).toDouble());
                  _historicalDates.add((data['date'] as Timestamp).toDate());
                }
                _historicalData = _historicalData.reversed.toList();
                _historicalDates = _historicalDates.reversed.toList();
                break;
              case "Height":
                _currentData = _parseDoubleValue(healthData['height']) > 0
                    ? _parseDoubleValue(healthData['height'])
                    : _height;
                _goalData = 170.0;
                _historicalData = [];
                _historicalDates = [];
                break;
              case "BMI":
                _calculateBMI();
                _goalData = 22.0;
                _historicalData = [];
                _historicalDates = [];

                final weightPoints = _extractHistoryPoints(
                  weightHistorySnapshot,
                  'weight',
                );
                final heightPoints = <_MetricHistoryPoint>[
                  if (_height >= _minValidHeightCm)
                    _MetricHistoryPoint(DateTime.now(), _height),
                ];

                for (final weightPoint in weightPoints) {
                  final heightAtDate = _resolveHeightForDate(
                    heightPoints,
                    weightPoint.date,
                  );
                  final bmiAtDate = _computeSafeBmi(
                    weightPoint.value,
                    heightAtDate,
                  );

                  if (bmiAtDate > 0) {
                    _historicalData.add(bmiAtDate);
                    _historicalDates.add(weightPoint.date);
                  }
                }

                if (_historicalData.isEmpty && _currentData > 0) {
                  _historicalData = [_currentData];
                  _historicalDates = [DateTime.now()];
                }
                break;
              case "Sleep Hours":
                // First try to get the latest sleep entry from sleep_history
                double latestSleepHours = 0.0;
                if (sleepHistorySnapshot.docs.isNotEmpty) {
                  // The first document is the latest one due to descending order
                  final latestSleepDoc = sleepHistorySnapshot.docs.first;
                  final latestData = latestSleepDoc.data();
                  latestSleepHours = (latestData['sleepHours'] ?? 0.0)
                      .toDouble();
                }

                _currentData = latestSleepHours > 0
                    ? latestSleepHours
                    : (healthData['sleepHours'] ?? 0.0).toDouble();
                _goalData = 8.0;

                // Load sleep history with actual dates
                _historicalData = [];
                _historicalDates = [];

                for (var doc in sleepHistorySnapshot.docs) {
                  final data = doc.data();
                  _historicalData.add((data['sleepHours'] ?? 0.0).toDouble());
                  _historicalDates.add((data['date'] as Timestamp).toDate());
                }

                // Reverse to show chronological order (oldest to newest)
                _historicalData = _historicalData.reversed.toList();
                _historicalDates = _historicalDates.reversed.toList();
                break;
            }
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
        case 'weeklyCalories':
        case 'calories':
          value = _dailyActivityHistory[i].weeklyCalories.toDouble();
          break;
        case 'weeklyMinutes':
        case 'steps':
          value = _dailyActivityHistory[i].weeklyMinutes.toDouble();
          break;
        case 'weeklyWorkoutsCount':
        case 'movingMinutes':
          value = _dailyActivityHistory[i].weeklyWorkoutsCount.toDouble();
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
    setState(() {
      _currentData = _computeSafeBmi(_weight, _height);
    });
  }

  double _calculateCurrentBMI() {
    return _computeSafeBmi(_weight, _height);
  }

  double _getDefaultGoal() {
    switch (widget.title) {
      case "kcal":
      case "Calories":
        return 2500.0;
      case "Minutes":
      case "Steps":
        return 300.0;
      case "Workouts":
      case "Moving":
        return 5.0;
      case "Waist Measurement": // UPDATED
        return 80.0;
      case "Weight":
        return 62.0;
      case "Height":
        return 170.0;
      case "BMI":
        return 22.0;
      case "Sleep Hours": // UPDATED
        return 8.0;
      default:
        return 0.0;
    }
  }

  String _getCurrentValue() {
    if (_isLoading) return "Loading...";

    switch (widget.title) {
      case "Waist Measurement": // UPDATED
        return "${_currentData.toStringAsFixed(1)} cm";
      case "Height":
        return "${_currentData.toStringAsFixed(1)} cm";
      case "Weight":
        return "${_currentData.toStringAsFixed(1)} kg";
      case "BMI":
        return _currentData.toStringAsFixed(1);
      case "Sleep Hours": // UPDATED
        return "${_currentData.toStringAsFixed(1)} hrs";
      case "kcal":
      case "Minutes":
      case "Workouts":
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
      case "Waist Measurement": // UPDATED
        return "${average.toStringAsFixed(1)} cm";
      case "Height":
        return "${average.toStringAsFixed(1)} cm";
      case "Weight":
        return "${average.toStringAsFixed(1)} kg";
      case "BMI":
        return average.toStringAsFixed(1);
      case "Sleep Hours": // UPDATED
        return "${average.toStringAsFixed(1)} hrs";
      case "kcal":
      case "Minutes":
      case "Workouts":
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
      case "Waist Measurement": // UPDATED
        return "${_goalData.toStringAsFixed(1)} cm";
      case "Height":
        return "${_goalData.toStringAsFixed(1)} cm";
      case "Weight":
        return "${_goalData.toStringAsFixed(1)} kg";
      case "BMI":
        return _goalData.toStringAsFixed(1);
      case "Sleep Hours": // UPDATED
        return "${_goalData.toStringAsFixed(1)} hrs";
      case "kcal":
      case "Calories":
        return "${_goalData.toInt()} kcal";
      case "Minutes":
      case "Steps":
        return "${_goalData.toInt()} mins";
      case "Workouts":
      case "Moving":
        return "${_goalData.toInt()} workouts";
      default:
        return "N/A";
    }
  }

  String _getUnitWithGoal() {
    if (_isLoading) return _getUnit();

    switch (widget.title) {
      case "kcal":
      case "Calories":
        return "/${_goalData.toInt()} kcal";
      case "Minutes":
      case "Steps":
        return "/${_goalData.toInt()} mins";
      case "Workouts":
      case "Moving":
        return "/${_goalData.toInt()} workouts";
      default:
        return _getUnit();
    }
  }

  String _getUnit() {
    switch (widget.title) {
      case "kcal":
      case "Calories":
        return "kcal";
      case "Minutes":
      case "Steps":
        return "mins";
      case "Workouts":
      case "Moving":
        return "workouts";
      case "Waist Measurement": // UPDATED
      case "Height":
        return "cm";
      case "Weight":
        return "kg";
      case "Sleep Hours": // UPDATED
        return "hrs";
      default:
        return "";
    }
  }

  Color _getThemeColor() {
    switch (widget.title) {
      case "kcal":
      case "Calories":
        return const Color(0xFFFF6B35);
      case "Minutes":
      case "Steps":
        return const Color(0xFFFF9800);
      case "Workouts":
      case "Moving":
        return const Color(0xFF2196F3);
      case "Waist Measurement": // UPDATED: Changed to blue
        return Colors.blue;
      case "Height":
        return const Color(0xFF4FC3F7);
      case "Sleep Hours": // UPDATED: Changed to purple
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return "Check data";
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color _getBMIColor(double bmi) {
    if (bmi <= 0) return Colors.white54;
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
      case "kcal":
      case "Calories":
        return Icons.local_fire_department;
      case "Minutes":
      case "Steps":
        return Icons.directions_walk;
      case "Workouts":
      case "Moving":
        return Icons.directions_run;
      case "Waist Measurement": // UPDATED
        return Icons.straighten;
      case "Height":
        return Icons.height;
      case "Sleep Hours": // UPDATED
        return Icons.bedtime;
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
          onPressed: () {
            Navigator.pop(context);
          },
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

  // In the _buildAppBarActions method in details_screen.dart
  // In the _buildAppBarActions method
  List<Widget> _buildAppBarActions() {
    if (widget.title == "Weight" ||
        widget.title == "Height" ||
        widget.title == "Waist Measurement" ||
        widget.title == "Sleep Hours") {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _showMetricInputDialog,
        ),
      ];
    }
    return [];
  }

  Future<void> _showMetricInputDialog() async {
    final isSleepMetric = widget.title == "Sleep Hours";
    final todaySleepEntries = isSleepMetric ? await _loadTodaySleepEntries() : null;
    final hasTodaySleepEntry = todaySleepEntries?.docs.isNotEmpty ?? false;
    final dialogTitle = isSleepMetric
        ? (hasTodaySleepEntry
            ? "Update Sleep Hours"
            : "Add Your Sleep Hours Last Night")
        : "Update ${widget.title}";
    final hintText = isSleepMetric
        ? (hasTodaySleepEntry
            ? "Update today's sleep hours"
            : "Enter your sleep hours last night")
        : "Enter ${widget.title.toLowerCase()}";
    final initialText = isSleepMetric
        ? (hasTodaySleepEntry && _currentData > 0
            ? _currentData.toStringAsFixed(1)
            : '')
        : (_currentData > 0 ? _currentData.toStringAsFixed(1) : '');

    final controller = TextEditingController(text: initialText);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: Text(
            dialogTitle,
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white38),
              suffixText: _getUnit().isEmpty ? null : _getUnit(),
              suffixStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _getThemeColor()),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final value = double.tryParse(controller.text);
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (widget.title == "Weight" &&
                    (value < _minValidWeightKg || value > _maxValidWeightKg)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a realistic weight between 20 and 400 kg'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (widget.title == "Height" &&
                    (value < _minValidHeightCm || value > _maxValidHeightCm)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a realistic height between 80 and 250 cm'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (widget.title == "Weight" &&
                    _height >= _minValidHeightCm &&
                    !_isDisplayableBmiPair(value, _height)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('That weight does not match your current height. Please enter a more realistic value'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (widget.title == "Height" &&
                    _weight >= _minValidWeightKg &&
                    !_isDisplayableBmiPair(_weight, value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('That height does not match your current weight. Please enter a more realistic value'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                switch (widget.title) {
                  case "Weight":
                    await _updateWeightData(value);
                    break;
                  case "Height":
                    await _updateHeightData(value);
                    break;
                  case "Waist Measurement":
                    await _updateWaistMeasurementData(value);
                    break;
                  case "Sleep Hours": {
                    await _updateSleepHoursData(
                      value,
                      existingTodayEntries: todaySleepEntries,
                    );
                    break;
                  }
                }

                _refreshData();
              },
              child: Text(
                "Save",
                style: TextStyle(color: _getThemeColor()),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add refresh method
  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    widget.onDataSaved?.call();
    _loadDataFromFirebase();
  }

  bool _isWeightGoalReached() {
    return (_currentData - _goalData).abs() < 0.1;
  }

  Future<void> _showWeightGoalDialog() async {
    final controller = TextEditingController(
      text: _goalData > 0 ? _goalData.toStringAsFixed(1) : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: const Text(
            'Set Weight Goal',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter goal in kg',
              hintStyle: const TextStyle(color: Colors.white38),
              suffixText: 'kg',
              suffixStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final goal = double.tryParse(controller.text);
                if (goal == null || goal <= 0 || goal > 500) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid goal in kg'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _saveWeightGoal(goal);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWeightGoal(double goal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current')
        .set({
      'weightGoalKg': goal,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _goalData = goal;
    });

    widget.onDataSaved?.call();
  }

  // Add method to update waist measurement data in subcollection
  Future<void> _updateWaistMeasurementData(double newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update in health metrics collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .doc('current')
          .set({
            'waistMeasurement': newValue,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Add to waist history subcollection for Android compatibility
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('waist_history')
          .doc(DateTime.now().toIso8601String())
          .set({
            'waist': newValue,
            'date': DateTime.now(),
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<void> _updateHeightData(double newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      final updatedBmi = _computeSafeBmi(_weight, newValue);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .doc('current')
          .set({
            'height': newValue,
            'bmi': updatedBmi,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _firestore.collection('users').doc(user.uid).set({
        'profile': {
          'weight': _weight,
          'height': newValue,
          'bmi': updatedBmi,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Add method to update weight data in subcollection
  Future<void> _updateWeightData(double newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (_height >= _minValidHeightCm && !_isDisplayableBmiPair(newValue, _height)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That weight does not match your current height. Please enter a more realistic value',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedBmi = _computeSafeBmi(newValue, _height);

      // Update in health metrics collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .doc('current')
          .set({
            'weight': newValue,
            'bmi': updatedBmi,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update in user profile
      await _firestore.collection('users').doc(user.uid).set({
        'profile': {
          'weight': newValue,
          'height': _height,
          'bmi': updatedBmi,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add to weight history subcollection for Android compatibility
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weight_history')
          .doc(DateTime.now().toIso8601String())
          .set({
            'weight': newValue,
            'date': DateTime.now(),
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  // Add method to update sleep hours data in subcollection
  Future<void> _updateSleepHoursData(
    double newValue, {
    QuerySnapshot<Map<String, dynamic>>? existingTodayEntries,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update in health metrics collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .doc('current')
          .set({
            'sleepHours': newValue,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      final sleepHistoryRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sleep_history');

      if (existingTodayEntries != null && existingTodayEntries.docs.isNotEmpty) {
        final docs = existingTodayEntries.docs;
        final primaryDoc = docs.first;

        await primaryDoc.reference.set({
          'sleepHours': newValue,
          'date': Timestamp.fromDate(DateTime.now()),
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        for (final extraDoc in docs.skip(1)) {
          await extraDoc.reference.delete();
        }
      } else {
        await sleepHistoryRef.doc(DateTime.now().toIso8601String()).set({
          'sleepHours': newValue,
          'date': DateTime.now(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Widget _buildContent() {
    switch (widget.title) {
      case "Weight":
        return _buildWeightContent();
      case "Height":
        return _buildHeightContent();
      case "BMI":
        return _buildBMIContent();
      case "Sleep Hours": // UPDATED
        return _buildSleepContent();
      case "kcal":
      case "Minutes":
      case "Workouts":
      case "Calories":
      case "Steps":
      case "Moving":
        return _buildMetricContent();
      case "Waist Measurement": // UPDATED
        return _buildWaistContent();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildHeightContent() {
    final currentBmi = _computeSafeBmi(_weight, _currentData);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              children: [
                Text(
                  _currentData.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Height (cm)",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7).withOpacity(0.28),
                    ),
                  ),
                  child: Text(
                    "Current saved height for your profile",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildHeightProfileCard(currentBmi),
          const SizedBox(height: 20),
          _buildHeightInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeightProfileCard(double currentBmi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            children: const [
              Icon(Icons.height, color: Color(0xFF4FC3F7), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Height Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Height usually changes rarely, so this screen keeps only your latest measured value.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeightSummaryChip(
                      label: "Current Height",
                      value: "${_currentData.toStringAsFixed(1)} cm",
                    ),
                    _buildHeightSummaryChip(
                      label: "Current Weight",
                      value: _weight > 0
                          ? "${_weight.toStringAsFixed(1)} kg"
                          : "Add weight",
                    ),
                    _buildHeightSummaryChip(
                      label: "BMI from this height",
                      value: currentBmi > 0
                          ? currentBmi.toStringAsFixed(1)
                          : "Check data",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightSummaryChip({
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              children: [
                Text(
                  _currentData.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Weight (kg)",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.green.withOpacity(0.35)),
                      ),
                      child: Text(
                        "Goal: ${_goalData.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _showWeightGoalDialog,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.withOpacity(0.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        "Set Goal",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isWeightGoalReached()
                        ? Colors.green.withOpacity(0.16)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isWeightGoalReached()
                          ? Colors.green.withOpacity(0.35)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isWeightGoalReached()
                            ? Icons.check_circle
                            : Icons.track_changes,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isWeightGoalReached()
                              ? "Goal reached"
                              : "Difference: ${(_currentData - _goalData).abs().toStringAsFixed(1)} kg",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
              child: _historicalData.isNotEmpty
                  ? CustomPaint(
                      painter: RealDataChartPainter(
                        data: _historicalData,
                        dates: _historicalDates,
                        color: Colors.green,
                        goal: _goalData,
                        timeTab: 2,
                      ),
                      size: const Size(double.infinity, 180),
                    )
                  : const Center(
                      child: Text(
                        "No historical data available",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _buildWeightHistorySection(),
          const SizedBox(height: 20),
          _buildBodyCompositionCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeightHistorySection() {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          "Weight History",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${_historicalData.length} entries",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_historicalData.isNotEmpty)
              ..._historicalData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                DateTime date = _historicalDates[index];
                return _buildWeightHistoryItem(date, value);
              }).toList(),
            if (_historicalData.isEmpty)
              const Center(
                child: Text(
                  "No weight history available",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryItem(DateTime date, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Text(
              "${value.toStringAsFixed(1)} kg",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                            stops: [0.14, 0.40, 0.60, 1.0],
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

  // UPDATED: Changed from _buildVitalityContent to _buildSleepContent
  // UPDATED: Changed from _buildVitalityContent to _buildSleepContent
  Widget _buildSleepContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  _currentData.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sleep Hours",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getSleepCoachingMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                  color: Colors.purple,
                  goal: _goalData,
                  timeTab: 2, // Always show full history for sleep
                ),
                size: const Size(double.infinity, 180),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSleepHistorySection(), // New method for sleep history
          const SizedBox(height: 20),
          _buildAboutSleepCard(),
        ],
      ),
    );
  }

  Widget _buildSleepHistorySection() {
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
                const Icon(Icons.history, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Sleep History",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_historicalData.isNotEmpty)
              ..._historicalData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                DateTime date = _historicalDates[index];
                return _buildSleepHistoryItem(date, value);
              }).toList(),
            if (_historicalData.isEmpty)
              const Center(
                child: Text(
                  "No sleep history available",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepHistoryItem(DateTime date, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.4)),
            ),
            child: Text(
              "${value.toStringAsFixed(1)} hrs",
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      "Today",
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
                  ],
                ),
              ],
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
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white38, height: 1, thickness: 0.5),
                const SizedBox(height: 14),
                Text(
                  _getInlineMetricInfo(),
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
        const SizedBox(height: 20),
        _buildMetricTipsCard(),
      ],
    );
  }

  String _getInlineMetricInfo() {
    switch (widget.title) {
      case "kcal":
      case "Calories":
        return "Calories here show the energy you burned from recorded workouts today. Completing more workout volume usually increases this number.";
      case "Minutes":
      case "Steps":
        return "Minutes show how much workout time you logged today based on your completed workout exercises and their estimated duration.";
      case "Workouts":
      case "Moving":
        return "Workouts show how many workout sessions you completed today. Each finished workout adds to this total.";
      default:
        return "Information about this metric is shown here.";
    }
  }

  List<String> _getMetricTips() {
    switch (widget.title) {
      case "kcal":
      case "Calories":
        return [
          "Longer workouts and more total sets usually increase calories burned.",
          "Compound exercises often burn more energy than isolation exercises.",
          "If this stays low, try finishing a full workout instead of stopping early.",
        ];
      case "Minutes":
      case "Steps":
        return [
          "Workout minutes increase when you complete more exercises in one session.",
          "Resting too long between exercises can make the session feel slower without adding useful minutes.",
          "A short routine still counts, but longer consistent sessions usually improve this total.",
        ];
      case "Workouts":
      case "Moving":
        return [
          "Each fully completed session adds to your workout count for today.",
          "Several short finished workouts count better than opening a workout and leaving it unfinished.",
          "Use this number to stay consistent, even on lighter training days.",
        ];
      default:
        return [
          "Keep logging this metric regularly to build a more useful daily record.",
        ];
    }
  }

  Widget _buildMetricTipsCard() {
    final tips = _getMetricTips();

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
                Icon(Icons.tips_and_updates_outlined, color: _getThemeColor(), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Tips",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white38, height: 1, thickness: 0.5),
            const SizedBox(height: 14),
            ...tips.asMap().entries.map((entry) {
              final isLast = entry.key == tips.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: _getThemeColor().withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: _getThemeColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // UPDATED: Changed from _buildBodyFatContent to _buildWaistContent
  Widget _buildWaistContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  _currentData.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.blue, // UPDATED: Changed color
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Waist Measurement", // UPDATED: Changed text
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getRecordedEntriesText("waist"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                  color: Colors.blue, // UPDATED: Changed color
                  goal: _goalData,
                  timeTab: 2, // Always show full history for waist measurement
                ),
                size: const Size(double.infinity, 180),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildWaistHistorySection(), // UPDATED: Changed method name
          const SizedBox(height: 20),
          _buildAboutWaistCard(),
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
      case "kcal":
      case "Calories":
        return 'weeklyCalories';
      case "Minutes":
      case "Steps":
        return 'weeklyMinutes';
      case "Workouts":
      case "Moving":
        return 'weeklyWorkoutsCount';
      default:
        return '';
    }
  }

  // Graph implementations with real data
  Widget _buildWeightGraph() => _buildRealGraph(_historicalData, Colors.green);
  Widget _buildTrendGraph() => _buildRealGraph(_historicalData, Colors.green);
  Widget _buildSleepGraph() =>
      _buildRealGraph(_historicalData, Colors.purple); // UPDATED: Changed color

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
          crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the header
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
              ],
            ),
            const SizedBox(height: 24),

            // CENTERED: Weight and BMI section
            Container(
              width: double.infinity,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Evenly space items
                children: [
                  // Weight Column - Centered content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center align
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
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Current",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Vertical divider
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white38,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // BMI Column - Centered content
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DetailScreen(title: "BMI"),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // Center align
                          children: [
                            const Text(
                              "BMI",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _calculateCurrentBMI().toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  _getBMICategory(_calculateCurrentBMI()),
                                  style: TextStyle(
                                    color: _getBMIColor(_calculateCurrentBMI()),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
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
            ),
            const SizedBox(height: 16),

            // Progress section - Centered
          ],
        ),
      ),
    );
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

  // UPDATED: Changed from _buildVitalityPointsSystem to _buildSleepQualitySystem
  Widget _buildSleepQualitySystem() {
    double sleepPercentage = (_currentData / _goalData * 100).clamp(0.0, 100.0);

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
              "Sleep Quality System",
              style: TextStyle(
                color: Colors.purple, // UPDATED: Changed color
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
                        sleepPercentage *
                        0.01 *
                        (MediaQuery.of(context).size.width - 32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.purpleAccent,
                        ], // UPDATED: Changed colors
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
                      "0",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  Positioned(
                    left: 0.6 * (MediaQuery.of(context).size.width - 32) - 10,
                    top: -15,
                    child: Text(
                      "6",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 32) - 20,
                    top: -15,
                    child: Text(
                      "12",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sleep Hours measures the duration of your sleep. Adults typically need 7-9 hours of quality sleep per night for optimal health and well-being.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Current Sleep: ${_currentData.toStringAsFixed(1)}/8 hrs", // UPDATED: Changed text
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

  // UPDATED: Changed from _buildAboutVitalityCard to _buildAboutSleepCard
  Widget _buildAboutSleepCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SleepInfoScreen(),
        ), // UPDATED: Changed screen
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
                  "About Sleep Hours", // UPDATED: Changed text
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

  // UPDATED: Changed from _buildBodyFatHistorySection to _buildWaistHistorySection
  Widget _buildWaistHistorySection() {
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
              ],
            ),
            const SizedBox(height: 16),

            if (_historicalData.isNotEmpty)
              ..._historicalData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                DateTime date = _historicalDates[index];
                return _buildCenteredHistoryItem(date, value);
              }).toList(),
            if (_historicalData.isEmpty)
              const Center(
                child: Text(
                  "No history data available",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutWaistCard() {
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
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "About Waist Measurement",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Divider(color: Colors.white38, height: 1, thickness: 0.5),
            SizedBox(height: 14),
            Text(
              "Waist measurement helps you track body changes over time. Updating it regularly gives a clearer picture of your progress together with weight, height, and BMI.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightInfoCard() {
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
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4FC3F7), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "About Height",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Divider(color: Colors.white38, height: 1, thickness: 0.5),
            SizedBox(height: 14),
            Text(
              "Height is a body profile measurement, not a workout progress stat. Update it only when you take a new measurement so your BMI, dashboard, and profile stay accurate.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredHistoryItem(DateTime date, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
            ),
            child: Text(
              "${value.toStringAsFixed(1)} cm",
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

  Widget _buildModernHistoryItem(DateTime date, double value) {
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
              color: Colors.blue.withOpacity(0.2), // UPDATED: Changed color
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withOpacity(0.4),
              ), // UPDATED: Changed color
            ),
            child: Text(
              "${value.toStringAsFixed(1)} cm", // UPDATED: Changed unit
              style: const TextStyle(
                color: Colors.blue, // UPDATED: Changed color
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
    if (widget.title == "Calories" || widget.title == "kcal") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CaloriesInfoScreen()),
      );
    } else if (widget.title == "Moving" || widget.title == "Workouts") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MovingInfoScreen()),
      );
    } else if (widget.title == "Steps" || widget.title == "Minutes") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StepsInfoScreen()),
      );
    } else if (widget.title == "Sleep Hours") {
      // UPDATED: Added sleep info
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SleepInfoScreen()),
      );
    } else if (widget.title == "Waist Measurement") {
      // UPDATED: Added waist info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WaistMeasurementInfoScreen(),
        ),
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
  final int weeklyMinutes;
  final int weeklyCalories;
  final int weeklyWorkoutsCount;

  DailyActivity({
    required this.date,
    required this.weeklyMinutes,
    required this.weeklyCalories,
    required this.weeklyWorkoutsCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'weeklyMinutes': weeklyMinutes,
      'weeklyCalories': weeklyCalories,
      'weeklyWorkoutsCount': weeklyWorkoutsCount,
    };
  }

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      date: DateTime.parse(map['date']),
      weeklyMinutes:
          (map['weeklyMinutes'] ?? map['movingMinutes'] ?? 0).toInt(),
      weeklyCalories: (map['weeklyCalories'] ?? map['calories'] ?? 0).toInt(),
      weeklyWorkoutsCount: (map['weeklyWorkoutsCount'] ?? 0).toInt(),
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
    final bool hasMultiplePoints = data.length > 1;
    double xStep = hasMultiplePoints ? size.width / (data.length - 1) : 0;

    for (int i = 0; i < data.length; i++) {
      double x = hasMultiplePoints ? i * xStep : 0;
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
    final bool sameDayOnly =
        dates.isNotEmpty &&
        dates.every(
          (entry) =>
              entry.year == dates.first.year &&
              entry.month == dates.first.month &&
              entry.day == dates.first.day,
        );

    if (timeTab == 0 || sameDayOnly) {
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
