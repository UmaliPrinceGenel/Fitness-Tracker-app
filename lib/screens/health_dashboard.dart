import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/semi_circle_progress.dart';
import 'detail_screen.dart';
import 'my_profile.dart';
import 'workout_screen.dart';
import 'community_screen.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Health data - will be loaded from Firestore
  double _calories = 0.0;
  double _caloriesGoal = 600.0;
  int _steps = 0;
  int _stepsGoal = 7000;
 double _movingMinutes = 0.0;
  double _movingGoal = 60.0;

  // Body metrics data - UPDATED: bodyFat to waistMeasurement, vitalityScore to sleepHours
  double _waistMeasurement = 0.0;
  double _weight = 0.0;
  double _height = 0.0;
  double _bmi = 0.0;
  double _sleepHours = 0.0;

  // Historical data for graphs - UPDATED: bodyFatHistory to waistHistory, vitalityHistory to sleepHistory
  List<double> _waistHistory = [];
  List<double> _weightHistory = [];
  List<double> _sleepHistory = [];

  // Daily activity history
  List<DailyActivity> _dailyActivityHistory = [];

  // Step tracking variables
  bool _isLoading = true;
  bool _isTrackingSteps = false;
  String _status = 'Waiting...';

 // Date tracking for daily reset
  DateTime _currentDate = DateTime.now();

  // Improved accelerometer variables
  List<double> _accelerometerValues = [0, 0];
  DateTime _lastStepTime = DateTime.now();
  DateTime _lastMovementTime = DateTime.now();
  int _stepBuffer = 0;
  List<double> _accelerationBuffer = [];
  static const int STEP_TIME_GAP = 300;
  static const double STEP_ACCEL_THRESHOLD = 12.0; // Increased threshold
  static const int MOVEMENT_TIME_THRESHOLD = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _initStepTracking();
    _checkDailyReset();
  }

  // Check if we need to reset daily data
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _currentDate.day ||
        now.month != _currentDate.month ||
        now.year != _currentDate.year) {
      _resetDailyData();
    }

    // Check every minute for date change
    Future.delayed(const Duration(minutes: 1), _checkDailyReset);
  }

  // Reset daily activity data and save to history
  Future<void> _resetDailyData() async {
    final user = _auth.currentUser;
    if (user != null && (_steps > 0 || _calories > 0 || _movingMinutes > 0)) {
      // Save current day's data to history
      final dailyActivity = DailyActivity(
        date: _currentDate,
        steps: _steps,
        calories: _calories,
        movingMinutes: _movingMinutes,
      );

      _dailyActivityHistory.add(dailyActivity);

      // Keep only last 30 days
      if (_dailyActivityHistory.length > 30) {
        _dailyActivityHistory.removeAt(0);
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_activity')
          .doc(_currentDate.toIso8601String().split('T')[0])
          .set(dailyActivity.toMap());

      // Update activity history in health metrics
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .doc('current')
          .set({
            'dailyActivityHistory': _dailyActivityHistory
                .map((e) => e.toMap())
                .toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    // Reset daily counters
    setState(() {
      _currentDate = DateTime.now();
      _steps = 0;
      _calories = 0;
      _movingMinutes = 0;
      _stepBuffer = 0;
    });

    // Update Firestore with reset data
    _updateHealthData(steps: 0, calories: 0, movingMinutes: 0);
  }

  // FIXED: Improved step tracking initialization
  Future<void> _initStepTracking() async {
    await _requestPermissions();
    await _initPedometer();
    _startAccelerometerTracking();
    _startMovingMinutesTimer(); // ADD THIS
  }

  // FIXED: Improved permission request
  Future<void> _requestPermissions() async {
    try {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        setState(() {
          _isTrackingSteps = true;
          _status = 'Step tracking active';
        });
      } else {
        setState(() {
          _status = 'Activity permission required for step tracking';
        });
        // Fall back to accelerometer only
        _startAccelerometerTracking();
      }
    } catch (e) {
      print('Permission error: $e');
      setState(() {
        _status = 'Using basic motion detection';
      });
      // Fall back to accelerometer only
      _startAccelerometerTracking();
    }
  }

 Future<void> _initPedometer() async {
    try {
      Pedometer.stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      Pedometer.pedestrianStatusStream
          .listen(_onPedestrianStatusChanged)
          .onError(_onPedestrianStatusError);

      setState(() {
        _status = 'Pedometer initialized';
      });
    } catch (e) {
      print('Pedometer init error: $e');
      setState(() {
        _status = 'Pedometer not available';
      });
    }
 }

  // FIXED: Prevent duplicate step counting
  void _onStepCount(StepCount event) {
    final newSteps = event.steps;

    // Only update if the pedometer reports significantly more steps
    // This prevents small fluctuations from causing issues
    if (newSteps > _steps + 5) {
      // Only update if at least 5 new steps
      setState(() {
        _steps = newSteps;
        _lastMovementTime = DateTime.now(); // Update movement time
        _updateCaloriesFromSteps();
      });
      _updateHealthData(steps: _steps);
    }
  }

  void _onStepCountError(error) {
    print('Step count error: $error');
    setState(() {
      _status = 'Step counter error';
    });
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
  }

  void _startAccelerometerTracking() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      _detectStepFromAccelerometer(event);
    });
  }

  // FIXED: Improved step detection algorithm
  void _detectStepFromAccelerometer(AccelerometerEvent event) {
    // Calculate magnitude of acceleration vector
    double acceleration =
        (event.x * event.x + event.y * event.y + event.z * event.z);

    // Add to buffer for smoothing
    _accelerationBuffer.add(acceleration);
    if (_accelerationBuffer.length > 10) {
      // Increased buffer size
      _accelerationBuffer.removeAt(0);
    }

    // Calculate smoothed acceleration
    double smoothedAcceleration =
        _accelerationBuffer.reduce((a, b) => a + b) /
        _accelerationBuffer.length;

    DateTime now = DateTime.now();
    int timeDiff = now.difference(_lastStepTime).inMilliseconds;

    // Only count step if enough time has passed and acceleration exceeds threshold
    if (timeDiff > STEP_TIME_GAP &&
        smoothedAcceleration > STEP_ACCEL_THRESHOLD) {
      // Additional validation: check if this is a valid step pattern
      if (_isValidStepPattern(smoothedAcceleration)) {
        _stepBuffer++;
        _lastStepTime = now;
        _lastMovementTime = now; // Update movement time for moving minutes

        // Process steps in batches to reduce UI updates
        if (_stepBuffer >= 3) {
          // Process every 3 steps
          final newSteps = _steps + _stepBuffer;
          setState(() {
            _steps = newSteps;
            _updateCaloriesFromSteps();
          });

          _updateHealthData(steps: _steps);
          _stepBuffer = 0;
        }
      }
    }
  }

 // FIXED: Add step pattern validation
  bool _isValidStepPattern(double acceleration) {
    // Check if we have enough data in buffer
    if (_accelerationBuffer.length < 5) return true;

    // Calculate variance to detect consistent movement vs random shakes
    double mean =
        _accelerationBuffer.reduce((a, b) => a + b) /
        _accelerationBuffer.length;
    double variance =
        _accelerationBuffer
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        _accelerationBuffer.length;

    // If variance is too high, it might be random shaking, not walking
    return variance < 50.0; // Adjust this threshold as needed
  }

  // FIXED: New moving minutes timer
  void _startMovingMinutesTimer() {
    // Check every 30 seconds if user has been active
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        final now = DateTime.now();
        final timeSinceLastMovement = now
            .difference(_lastMovementTime)
            .inSeconds;

        // If movement occurred within the last 2 minutes, count as active time
        if (timeSinceLastMovement <= MOVEMENT_TIME_THRESHOLD) {
          setState(() {
            _movingMinutes += 0.5; // Add 0.5 minutes (30 seconds)
          });

          // Update Firestore every 5 minutes of movement
          if (_movingMinutes % 5 < 0.1) {
            _updateHealthData(movingMinutes: _movingMinutes);
          }
        }

        // Continue the timer
        _startMovingMinutesTimer();
      }
    });
  }

  // FIXED: Improved calorie calculation
  void _updateCaloriesFromSteps() {
    if (_steps <= 0) return;

    // More accurate calorie calculation based on weight and steps
    double caloriesPerStep = _weight > 0 ? _weight * 0.0004 : 0.04;
    double newCalories = _steps * caloriesPerStep;

    // Only update if there's a meaningful change
    if ((newCalories - _calories).abs() > 0.1) {
      setState(() {
        _calories = newCalories;
      });
      _updateHealthData(calories: _calories);
    }
  }

 // REMOVED: Old _updateMovingMinutes method as it's now handled by timer

 // Automatic BMI Calculation
  void _calculateBMI() {
    if (_height > 0 && _weight > 0) {
      double heightInMeters = _height / 100;
      double newBmi = _weight / (heightInMeters * heightInMeters);
      if (newBmi != _bmi) {
        setState(() {
          _bmi = double.parse(newBmi.toStringAsFixed(1));
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;

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
            _weight = (userData['profile']?['weight'] ?? 0.0).toDouble();
            _height = (userData['profile']?['height'] ?? 0.0).toDouble();

            if (healthDoc.exists) {
              final healthData = healthDoc.data()!;
              _calories = (healthData['calories'] ?? 0.0).toDouble();
              _steps = (healthData['steps'] ?? 0).toInt();
              _movingMinutes = (healthData['movingMinutes'] ?? 0.0).toDouble();
              // UPDATED: bodyFat to waistMeasurement, vitalityScore to sleepHours
              _waistMeasurement = (healthData['waistMeasurement'] ?? 0.0)
                  .toDouble();
              _sleepHours = (healthData['sleepHours'] ?? 0.0).toDouble();

              // UPDATED: bodyFatHistory to waistHistory, vitalityHistory to sleepHistory
              _waistHistory = List<double>.from(
                healthData['waistHistory'] ?? [],
              );
              _weightHistory = List<double>.from(
                healthData['weightHistory'] ?? [],
              );
              _sleepHistory = List<double>.from(
                healthData['sleepHistory'] ?? [],
              );

              // Load daily activity history
              if (healthData['dailyActivityHistory'] != null) {
                _dailyActivityHistory = List<Map<String, dynamic>>.from(
                  healthData['dailyActivityHistory'],
                ).map((e) => DailyActivity.fromMap(e)).toList();
              }
            } else {
              _initializeNewUserHealthData(user.uid);
            }

            // Load additional daily activity from subcollection
            _dailyActivityHistory.addAll(
              dailyActivitySnapshot.docs
                  .map((doc) => DailyActivity.fromMap(doc.data()))
                  .toList(),
            );

            // Remove duplicates and sort by date
            _dailyActivityHistory.sort((a, b) => a.date.compareTo(b.date));

            _isLoading = false;
          });

          _calculateBMI();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
 }

  Future<void> _initializeNewUserHealthData(String userId) async {
    try {
      _calculateBMI();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .doc('current')
          .set({
            'calories': 0,
            'steps': 0,
            'movingMinutes': 0,
            'waistMeasurement': _waistMeasurement, // UPDATED
            'sleepHours': _sleepHours, // UPDATED
            'waistHistory': [_waistMeasurement], // UPDATED
            'weightHistory': [_weight],
            'sleepHistory': [_sleepHours], // UPDATED
            'dailyActivityHistory': [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error initializing health data: $e');
    }
 }

  Future<void> _updateHealthData({
    double? calories,
    int? steps,
    double? movingMinutes,
    double? waistMeasurement, // UPDATED
    double? weight,
    double? sleepHours, // UPDATED
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (calories != null) updates['calories'] = calories;
        if (steps != null) updates['steps'] = steps;
        if (movingMinutes != null) updates['movingMinutes'] = movingMinutes;
        if (waistMeasurement != null)
          updates['waistMeasurement'] = waistMeasurement; // UPDATED
        if (sleepHours != null) updates['sleepHours'] = sleepHours; // UPDATED

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('health_metrics')
            .doc('current')
            .set(updates, SetOptions(merge: true));

        if (weight != null && weight != _weight) {
          await _firestore.collection('users').doc(user.uid).set({
            'profile.weight': weight,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _weightHistory.add(weight);
          if (_weightHistory.length > 10) _weightHistory.removeAt(0);

          setState(() {
            _weight = weight;
          });
          _calculateBMI();

          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('health_metrics')
              .doc('current')
              .set({
                'weightHistory': _weightHistory,
                'waistHistory': _waistHistory, // UPDATED
                'sleepHistory': _sleepHistory, // UPDATED
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }

        if (waistMeasurement != null) {
          // UPDATED
          _waistHistory.add(waistMeasurement);
          if (_waistHistory.length > 10) _waistHistory.removeAt(0);
        }
        if (sleepHours != null) {
          // UPDATED
          _sleepHistory.add(sleepHours);
          if (_sleepHistory.length > 10) _sleepHistory.removeAt(0);
        }
      }
    } catch (e) {
      print('Error updating health data: $e');
    }
 }

  // Get activity data for different time periods
  List<DailyActivity> _getWeeklyActivity() {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _dailyActivityHistory
        .where((activity) => activity.date.isAfter(oneWeekAgo))
        .toList();
 }

  List<DailyActivity> _getMonthlyActivity() {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _dailyActivityHistory
        .where((activity) => activity.date.isAfter(oneMonthAgo))
        .toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Color _getSelectedIconColor(int index) {
    return index == _selectedIndex ? Colors.deepOrange : Colors.grey;
  }

  // FIXED: Improved app lifecycle handling
 @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes to foreground
      _loadUserData();
    } else if (state == AppLifecycleState.paused) {
      // Save current state when app goes to background
      _updateHealthData(
        steps: _steps,
        calories: _calories,
        movingMinutes: _movingMinutes,
      );
    }
  }

 void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading your health data...',
                style: TextStyle(color: Colors.white),
              ),
              if (!_isTrackingSteps)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Step tracking requires activity permission',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SizedBox(
        height: 87,
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite, color: _getSelectedIconColor(0)),
              label: "Health",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run, color: _getSelectedIconColor(1)),
              label: "Workout",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, color: _getSelectedIconColor(2)),
              label: "Community",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: _getSelectedIconColor(3)),
              label: "Profile",
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.black,
                    expandedHeight: 60,
                    floating: false,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10, top: 30),
                          child: Text(
                            "Health",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                            ),
                            color: Colors.grey[800],
                            onSelected: (String result) {
                              _showAddDataDialog();
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'add',
                                    child: Text(
                                      'Add Data',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10),

                        // PROPERLY CENTERED: Semi-circle progress
                        Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Centered semi-circle chart
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.85,
                                  maxHeight: 180,
                                ),
                                child: SemiCircleProgress(
                                  caloriesPercent:
                                      (_calories / _caloriesGoal * 100).clamp(
                                        0.0,
                                        100.0,
                                      ),
                                  stepsPercent: (_steps / _stepsGoal * 100)
                                      .clamp(0.0, 100.0),
                                  movingPercent:
                                      (_movingMinutes / _movingGoal * 100)
                                          .clamp(0.0, 100.0),
                                  caloriesValue: _calories.toStringAsFixed(0),
                                  caloriesGoal:
                                      "/${_caloriesGoal.toInt()} kcal",
                                  stepsValue: _steps.toString(),
                                  stepsGoal: "/$_stepsGoal steps",
                                  movingValue: _movingMinutes.toStringAsFixed(
                                    0,
                                  ),
                                  movingGoal: "/${_movingGoal.toInt()} mins",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        if (_isTrackingSteps)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Step Tracking: $_status',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Responsive metrics container
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: 180,
                            maxHeight: 220,
                          ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Metrics row
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: _ModernMetricItem(
                                          icon: Icons.local_fire_department,
                                          iconColor: const Color(0xFFFF6B35),
                                          label: "Calories",
                                          value: _calories.toStringAsFixed(0),
                                          goal:
                                              "/${_caloriesGoal.toInt()} kcal",
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      title: "Calories",
                                                      currentValue: _calories,
                                                      goalValue: _caloriesGoal,
                                                      onDataSaved:
                                                          _loadUserData,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _ModernMetricItem(
                                          icon: Icons.directions_walk,
                                          iconColor: const Color(0xFFFF9800),
                                          label: "Steps",
                                          value: _steps.toString(),
                                          goal: "/$_stepsGoal steps",
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      title: "Steps",
                                                      currentValue: _steps
                                                          .toDouble(),
                                                      goalValue: _stepsGoal
                                                          .toDouble(),
                                                      onDataSaved:
                                                          _loadUserData,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _ModernMetricItem(
                                          icon: Icons.directions_run,
                                          iconColor: const Color(0xFF2196F3),
                                          label: "Moving",
                                          value: _movingMinutes.toStringAsFixed(
                                            0,
                                          ),
                                          goal: "/${_movingGoal.toInt()} mins",
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      title: "Moving",
                                                      currentValue:
                                                          _movingMinutes,
                                                      goalValue: _movingGoal,
                                                      onDataSaved:
                                                          _loadUserData,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Bottom text
                                Text(
                                  'Data resets daily at midnight • ${_dailyActivityHistory.length} days of history',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // UPDATED: Changed parameters to waistMeasurement and sleepHours
                        _DraggableCardGrid(
                          waistMeasurement: _waistMeasurement,
                          weight: _weight,
                          bmi: _bmi,
                          sleepHours: _sleepHours,
                          waistHistory: _waistHistory,
                          weightHistory: _weightHistory,
                          sleepHistory: _sleepHistory,
                          onDataSaved: _loadUserData,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const WorkoutScreen(),
            const CommunityScreen(),
            MyProfile(
              key: ValueKey('profile_${DateTime.now().millisecondsSinceEpoch}'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Update Health Data',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.straighten, color: Colors.blue),
                title: const Text(
                  'Update Height',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Manual height input',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateDialog('Height', _height, 250.0);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateDialog(String type, double currentValue, double maxValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toStringAsFixed(1) : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Update $type',
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
              labelText: 'New $type Value (cm)',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? 0.0;
                if (newValue >= 0 && newValue <= maxValue) {
                  Navigator.pop(context);
                  _handleDataUpdate(type, newValue);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a value between 0 and $maxValue',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleDataUpdate(String type, double newValue) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      switch (type) {
        case 'Height':
          // Get current user data to calculate BMI
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
          final userData = userDoc.data();

          double weight = 0.0;
          if (userData != null && userData['profile'] != null) {
            weight = (userData['profile']['weight'] ?? 0.0).toDouble();
          }

          double bmi = 0.0;
          if (newValue > 0 && weight > 0) {
            double heightInMeters = newValue / 100;
            bmi = weight / (heightInMeters * heightInMeters);
          }

          // Update user profile with height AND recalculated BMI
          await _firestore.collection('users').doc(user.uid).set({
            'profile': {
              'height': newValue,
              'bmi': double.parse(bmi.toStringAsFixed(1)),
              'lastUpdated': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));

          // Update health metrics with new BMI
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('health_metrics')
              .doc('current')
              .set({
                'bmi': bmi,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

          // Refresh local data
          _loadUserData();

          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating $type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update $type'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Daily Activity Model
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

class _ModernMetricItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String goal;
  final VoidCallback? onTap;

  const _ModernMetricItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: iconColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              goal,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
    );
 }
}

// UPDATED: Changed parameters to waistMeasurement and sleepHours
class _DraggableCardGrid extends StatefulWidget {
  final double waistMeasurement;
  final double weight;
  final double bmi;
  final double sleepHours;
  final List<double> waistHistory;
  final List<double> weightHistory;
  final List<double> sleepHistory;
  final VoidCallback onDataSaved; // ADD THIS
  const _DraggableCardGrid({
    required this.waistMeasurement,
    required this.weight,
    required this.bmi,
    required this.sleepHours,
    required this.waistHistory,
    required this.weightHistory,
    required this.sleepHistory,
    required this.onDataSaved, // ADD THIS
  });

  @override
  State<_DraggableCardGrid> createState() => _DraggableCardGridState();
}

class _DraggableCardGridState extends State<_DraggableCardGrid> {
  List<Widget> cards = [];

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    // UPDATED: Changed to WaistCard and SleepCard
    cards = [
      _WaistCard(
        waistMeasurement: widget.waistMeasurement,
        waistHistory: widget.waistHistory,
        onDataSaved: widget.onDataSaved, // ADD THIS
      ),
      _WeightCard(
        weight: widget.weight,
        weightHistory: widget.weightHistory,
        onDataSaved: widget.onDataSaved,
      ), // ADD THIS
      _BMICard(bmi: widget.bmi, onDataSaved: widget.onDataSaved), // ADD THIS
      _SleepCard(
        sleepHours: widget.sleepHours,
        sleepHistory: widget.sleepHistory,
        onDataSaved: widget.onDataSaved, // ADD THIS
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant _DraggableCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initializeCards();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 350;
        final double cardWidth =
            constraints.maxWidth / 2 - (isSmallScreen ? 6 : 8);
        final double cardHeight = cardWidth * (isSmallScreen ? 1.2 : 1.1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: isSmallScreen ? 6 : 8,
            mainAxisSpacing: isSmallScreen ? 6 : 8,
            childAspectRatio: isSmallScreen ? 0.75 : 0.85,
          ),
          itemCount: cards.length,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(
              height: cardHeight,
              child: LongPressDraggable<int>(
                data: index,
                feedback: Material(
                  elevation: 8,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Opacity(opacity: 0.8, child: cards[index]),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Card(
                    color: const Color(0xFF191919),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      child: const Center(child: SizedBox.shrink()),
                    ),
                  ),
                ),
                onDragStarted: () {},
                onDragEnd: (details) {},
                child: DragTarget<int>(
                  onAccept: (int oldIndex) {
                    if (oldIndex != index) {
                      setState(() {
                        Widget card = cards.removeAt(oldIndex);
                        int adjustedNewIndex = oldIndex < index
                            ? index - 1
                            : index;
                        cards.insert(adjustedNewIndex, card);
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return cards[index];
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// UPDATED: Changed from BodyFatCard to WaistCard with new icon
class _WaistCard extends StatelessWidget {
  final double waistMeasurement;
  final List<double> waistHistory;
  final VoidCallback onDataSaved; // ADD THIS
  const _WaistCard({
    required this.waistMeasurement,
    required this.waistHistory,
    required this.onDataSaved, // ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              title: "Waist Measurement",
              onDataSaved: onDataSaved, // PASS THE CALLBACK
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF191919),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ), // Reduced padding for small screens
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 160;
              final bool isVerySmallScreen = constraints.maxWidth < 140;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // UPDATED: Changed icon from Icons.opacity to Icons.straighten
                      Icon(
                        Icons.straighten,
                        color: Colors.blue,
                        size: isVerySmallScreen ? 20 : 24,
                      ),
                      if (!isSmallScreen) ...[const Spacer()],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Waist", // UPDATED: Changed label
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${waistMeasurement.toStringAsFixed(1)} cm", // UPDATED: Changed unit
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 16 : 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isVerySmallScreen ? 8 : 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    height: 30, // Reduced height for small screens
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: waistHistory.length >= 2
                        ? CustomPaint(
                            painter: LineChartPainter(data: waistHistory),
                            size: const Size(double.infinity, 30),
                          )
                        : Center(
                            child: Text(
                              "No data",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: isVerySmallScreen ? 8 : 10,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Start",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isVerySmallScreen ? 8 : 9,
                        ),
                      ),
                      Text(
                        "Now",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isVerySmallScreen ? 8 : 9,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final double weight;
  final List<double> weightHistory;
  final VoidCallback onDataSaved; // ADD THIS
  const _WeightCard({
    required this.weight,
    required this.weightHistory,
    required this.onDataSaved,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              title: "Weight",
              onDataSaved: onDataSaved, // PASS THE CALLBACK
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF191919),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ), // Reduced padding for small screens
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 160;
              final bool isVerySmallScreen = constraints.maxWidth < 140;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.monitor_weight,
                        color: Colors.green,
                        size: isVerySmallScreen ? 20 : 24,
                      ),
                      if (!isSmallScreen) ...[const Spacer()],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Weight",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${weight.toStringAsFixed(1)} kg",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 16 : 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isVerySmallScreen ? 8 : 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    height: 30, // Reduced height for small screens
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: weightHistory.length >= 2
                        ? CustomPaint(
                            painter: WeightLineChartPainter(
                              data: weightHistory,
                            ),
                            size: const Size(double.infinity, 30),
                          )
                        : Center(
                            child: Text(
                              "No data",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: isVerySmallScreen ? 8 : 10,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Start",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isVerySmallScreen ? 8 : 9,
                        ),
                      ),
                      Text(
                        "Now",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isVerySmallScreen ? 8 : 9,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ResponsiveBMIIndicator extends StatelessWidget {
  final double bmi;
  final double height;

  const ResponsiveBMIIndicator({Key? key, required this.bmi, this.height = 32})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Column(
        children: [
          // BMI Scale Bar
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                return Stack(
                  children: [
                    // Background scale
                    _buildBMIScale(width),
                    // BMI Indicator
                    _buildBMIIndicator(width),
                  ],
                );
              },
            ),
          ),
          // BMI Labels
          SizedBox(height: 4),
          _buildBMILabels(),
        ],
      ),
    );
  }

 Widget _buildBMIScale(double totalWidth) {
    // Define BMI ranges and their widths
    final bmiRanges = [
      _BMIRange(15.0, 18.5, Colors.blue), // Underweight
      _BMIRange(18.5, 25.0, Colors.green), // Normal
      _BMIRange(25.0, 30.0, Colors.orange), // Overweight
      _BMIRange(30.0, 40.0, Colors.red), // Obese
    ];

    return Row(
      children: bmiRanges.map((range) {
        final rangeWidth = _calculateRangeWidth(range, totalWidth);
        return Container(
          width: rangeWidth,
          height: 12,
          decoration: BoxDecoration(
            color: range.color,
            borderRadius: _getBorderRadius(range, bmiRanges),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBMIIndicator(double totalWidth) {
    final double indicatorPosition = _calculateIndicatorPosition(totalWidth);

    return Positioned(
      left: indicatorPosition - 8, // Center the arrow above the position
      child: Column(
        children: [
          Icon(Icons.arrow_drop_up, color: Colors.white, size: 20),
          SizedBox(height: 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getBMIColor(bmi),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildBMILabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("15", style: TextStyle(color: Colors.white70, fontSize: 10)),
        Text("18.5", style: TextStyle(color: Colors.white70, fontSize: 10)),
        Text("25", style: TextStyle(color: Colors.white70, fontSize: 10)),
        Text("30", style: TextStyle(color: Colors.white70, fontSize: 10)),
        Text("40+", style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  double _calculateRangeWidth(_BMIRange range, double totalWidth) {
    final totalRange = 40.0 - 15.0; // 15 to 40+
    final rangeSize = range.end - range.start;
    return (rangeSize / totalRange) * totalWidth;
  }

  double _calculateIndicatorPosition(double totalWidth) {
    final double clampedBMI = bmi.clamp(15.0, 40.0);
    final double totalRange = 40.0 - 15.0;
    final double percentage = (clampedBMI - 15.0) / totalRange;
    return percentage * totalWidth;
  }

  BorderRadius _getBorderRadius(_BMIRange range, List<_BMIRange> allRanges) {
    final isFirst = range == allRanges.first;
    final isLast = range == allRanges.last;

    return BorderRadius.horizontal(
      left: isFirst ? Radius.circular(6) : Radius.circular(0),
      right: isLast ? Radius.circular(6) : Radius.circular(0),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _BMIRange {
  final double start;
  final double end;
  final Color color;

  _BMIRange(this.start, this.end, this.color);
}

class _BMICard extends StatelessWidget {
  final double bmi;
 final VoidCallback onDataSaved; // ADD THIS
  const _BMICard({required this.bmi, required this.onDataSaved});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              title: "BMI",
              onDataSaved: onDataSaved, // PASS THE CALLBACK
            ),
          ),
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
              Icon(Icons.monitor_heart, color: Colors.orange, size: 28),
              const SizedBox(height: 10),
              Text(
                "BMI",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bmi.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getBMICategory(bmi),
                style: TextStyle(
                  color: _getBMIColor(bmi),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Use the new responsive BMI indicator
              ResponsiveBMIIndicator(bmi: bmi),
            ],
          ),
        ),
      ),
    );
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
    return Colors.red;
  }
}

// UPDATED: Changed from VitalityCard to SleepCard with new icon
class _SleepCard extends StatelessWidget {
  final double sleepHours;
  final List<double> sleepHistory;
  final VoidCallback onDataSaved; // ADD THIS
  const _SleepCard({
    required this.sleepHours,
    required this.sleepHistory,
    required this.onDataSaved,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              title: "Sleep Hours",
              onDataSaved: onDataSaved, // PASS THE CALLBACK
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF191919),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                // UPDATED: Changed icon from Icons.person to Icons.bedtime
                child: Icon(
                  Icons.bedtime,
                  color: Colors.purple,
                  size: 28,
                ), // Changed color to purple for sleep
              ),
              const SizedBox(height: 6),
              Text(
                "Sleep Hours", // UPDATED: Changed label
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "${sleepHours.toStringAsFixed(1)} hrs", // UPDATED: Changed display
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                "${DateTime.now().day} ${_getMonthName(DateTime.now().month)}",
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const Spacer(),
              Container(
                height: 25,
                decoration: BoxDecoration(color: Colors.grey[800]),
                child: CustomPaint(
                  painter: SleepGraphPainter(
                    data: sleepHistory,
                  ), // UPDATED: Changed painter
                  size: const Size(double.infinity, 40),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "0",
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                  Text(
                    "12", // UPDATED: Changed max value from 100 to 12 for sleep hours
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// Chart painters
class LineChartPainter extends CustomPainter {
  final List<double> data;

  const LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double minValue = data.reduce((a, b) => a < b ? a : b);
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    double range = maxValue - minValue;
    if (range == 0) range = 1;

    double xStep = size.width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double y = size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    final gradient = LinearGradient(
      colors: [Colors.blue.shade300, Colors.blue.shade800],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class WeightLineChartPainter extends CustomPainter {
  final List<double> data;

  const WeightLineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double minValue = data.reduce((a, b) => a < b ? a : b);
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    double range = maxValue - minValue;
    if (range == 0) range = 1;

    double xStep = size.width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double y = size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    final gradient = LinearGradient(
      colors: [Colors.green.shade300, Colors.green.shade800],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..shader = gradient);
  }

 @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// UPDATED: Changed from VitalityGraphPainter to SleepGraphPainter
class SleepGraphPainter extends CustomPainter {
  final List<double> data;

  const SleepGraphPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final currentHours = data.last;
    // Normalize to 12 hours max for sleep
    final normalizedHeight = (currentHours / 12) * size.height;

    final gradient =
        LinearGradient(
          colors: [
            Colors.purple.shade300,
            Colors.purple.shade800,
          ], // UPDATED: Changed colors
        ).createShader(
          Rect.fromLTWH(
            0,
            size.height - normalizedHeight,
            size.width,
            normalizedHeight,
          ),
        );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - normalizedHeight,
        size.width,
        normalizedHeight,
      ),
      Paint()..shader = gradient,
    );

    final linePaint = Paint()
      ..color = Colors
          .purple // UPDATED: Changed color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height - normalizedHeight),
      Offset(size.width, size.height - normalizedHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
