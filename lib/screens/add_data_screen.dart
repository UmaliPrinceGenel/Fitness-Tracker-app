import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDataScreen extends StatefulWidget {
  final String title;
  final VoidCallback? onDataSaved;
  const AddDataScreen({super.key, required this.title, this.onDataSaved});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  late DateTime _selectedDate;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _selectedGender;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        double value = double.tryParse(_valueController.text) ?? 0.0;

        if (value <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a valid ${_getInputLabel()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        switch (widget.title) {
          case "Weight":
            await _saveWeightData(value);
            break;
          case "Waist Measurement":
            await _saveWaistData(value);
            break;
          case "Sleep Hours":
            await _saveSleepData(value);
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onDataSaved != null) {
          widget.onDataSaved!();
        }

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveWeightData(double weight) async {
    final user = _auth.currentUser!;
    final timestamp = _selectedDate.millisecondsSinceEpoch;

    // Get current user data to calculate BMI
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    double height = 0.0;
    if (userData != null && userData['profile'] != null) {
      height = (userData['profile']['height'] ?? 0.0).toDouble();
    }

    double bmi = 0.0;
    if (height > 0) {
      double heightInMeters = height / 100;
      bmi = weight / (heightInMeters * heightInMeters);
    }

    // Update user profile with weight AND BMI
    await _firestore.collection('users').doc(user.uid).set({
      'profile': {
        'weight': weight,
        'bmi': double.parse(bmi.toStringAsFixed(1)),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    // Update current weight in health metrics
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current')
        .set({
          'weight': weight,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Add to weight history
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weight_history')
        .add({'weight': weight, 'date': _selectedDate, 'timestamp': timestamp});

    // Update weight history array for graphs
    await _updateWeightHistory(weight);
  }

  Future<void> _saveWaistData(double waist) async {
    final user = _auth.currentUser!;
    final timestamp = _selectedDate.millisecondsSinceEpoch;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current')
        .set({
          'waistMeasurement': waist,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('waist_history')
        .add({'waist': waist, 'date': _selectedDate, 'timestamp': timestamp});

    await _updateWaistHistory(waist);
  }

  Future<void> _saveSleepData(double sleepHours) async {
    final user = _auth.currentUser!;
    final timestamp = _selectedDate.millisecondsSinceEpoch;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current')
        .set({
          'sleepHours': sleepHours,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_history')
        .add({
          'sleepHours': sleepHours,
          'date': _selectedDate,
          'timestamp': timestamp,
        });

    await _updateSleepHistory(sleepHours);
  }

  Future<void> _updateWeightHistory(double newWeight) async {
    final user = _auth.currentUser!;
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current');

    final doc = await docRef.get();
    List<dynamic> currentHistory = doc.data()?['weightHistory'] ?? [];

    currentHistory.add(newWeight);
    if (currentHistory.length > 30) {
      currentHistory = currentHistory.sublist(currentHistory.length - 30);
    }

    await docRef.set({
      'weightHistory': currentHistory,
    }, SetOptions(merge: true));
  }

  Future<void> _updateWaistHistory(double newWaist) async {
    final user = _auth.currentUser!;
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current');

    final doc = await docRef.get();
    List<dynamic> currentHistory = doc.data()?['waistHistory'] ?? [];

    currentHistory.add(newWaist);
    if (currentHistory.length > 30) {
      currentHistory = currentHistory.sublist(currentHistory.length - 30);
    }

    await docRef.set({'waistHistory': currentHistory}, SetOptions(merge: true));
  }

  Future<void> _updateSleepHistory(double newSleep) async {
    final user = _auth.currentUser!;
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_metrics')
        .doc('current');

    final doc = await docRef.get();
    List<dynamic> currentHistory = doc.data()?['sleepHistory'] ?? [];

    currentHistory.add(newSleep);
    if (currentHistory.length > 30) {
      currentHistory = currentHistory.sublist(currentHistory.length - 30);
    }

    await docRef.set({'sleepHistory': currentHistory}, SetOptions(merge: true));
  }

  void _calculateBMI() {
    if (_ageController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        _selectedGender != null) {
      double weight = double.tryParse(_weightController.text) ?? 0;
      double height = double.tryParse(_heightController.text) ?? 0;
      if (height > 0) {
        double heightInMeters = height / 100;
        double bmi = weight / (heightInMeters * heightInMeters);
        String bmiText = bmi.toStringAsFixed(1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your BMI is: $bmiText'),
            backgroundColor: Colors.orange,
          ),
        );

        _valueController.text = bmiText;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid height'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInputLabel() {
    switch (widget.title) {
      case "Weight":
        return "weight in kg";
      case "Waist Measurement":
        return "waist measurement in cm";
      case "Sleep Hours":
        return "sleep hours";
      default:
        return "value";
    }
  }

  String _getInputHint() {
    switch (widget.title) {
      case "Weight":
        return "Enter weight in kg";
      case "Waist Measurement":
        return "Enter waist measurement in cm";
      case "Sleep Hours":
        return "Enter sleep hours";
      default:
        return "Enter value";
    }
  }

  IconData _getInputIcon() {
    switch (widget.title) {
      case "Weight":
        return Icons.monitor_weight;
      case "Waist Measurement":
        return Icons.straighten;
      case "Sleep Hours":
        return Icons.bedtime;
      default:
        return Icons.edit;
    }
  }

  Color _getInputColor() {
    switch (widget.title) {
      case "Weight":
        return Colors.green;
      case "Waist Measurement":
        return Colors.blue;
      case "Sleep Hours":
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  List<Color> _getDateGradientColors() {
    switch (widget.title) {
      case "Weight":
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
      case "Waist Measurement":
        return [const Color(0xFF2196F3), const Color(0xFF03A9F4)];
      case "Sleep Hours":
        return [const Color(0xFF9C27B0), const Color(0xFFE040FB)];
      default:
        return [const Color(0xFF1A1A1A), const Color(0xFF121212)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Call the callback even when closing with back button
            if (widget.onDataSaved != null) {
              widget.onDataSaved!();
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add ${widget.title} Data',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _onSave,
          ),
        ],
      ),
      body: SafeArea(
        child: widget.title == "BMI"
            ? _buildBMIContent()
            : _buildStandardContent(),
      ),
    );
  }

  Widget _buildStandardContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getDateGradientColors(),
                ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Selected Date & Time',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(_selectedDate),
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          _buildDateSelection(),
          const SizedBox(height: 20),

          _buildTimeSelection(),
          const SizedBox(height: 30),

          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildValueInput(),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  _selectedDate.hour,
                  _selectedDate.minute,
                );
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_selectedDate),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );
            if (pickedTime != null) {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(Icons.access_time, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _valueController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(18),
          border: InputBorder.none,
          hintText: _getInputHint(),
          hintStyle: TextStyle(color: _getInputColor().withOpacity(0.7)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(_getInputIcon(), color: _getInputColor(), size: 24),
          ),
          suffixText: _getSuffixText(),
          suffixStyle: TextStyle(
            color: _getInputColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getSuffixText() {
    switch (widget.title) {
      case "Weight":
        return "kg";
      case "Waist Measurement":
        return "cm";
      case "Sleep Hours":
        return "hrs";
      default:
        return "";
    }
  }

  Widget _buildBMIContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildGenderSelection(),
            const SizedBox(height: 20),

            const Text(
              'Age',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAgeInput(),
            const SizedBox(height: 20),

            const Text(
              'Height (cm)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildHeightInput(),
            const SizedBox(height: 20),

            const Text(
              'Weight (kg)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildWeightInput(),
            const SizedBox(height: 20),

            _buildCalculateButton(),
            const SizedBox(height: 20),

            _buildAboutBMISection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Male'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Male'
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        color: _selectedGender == 'Male'
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Male',
                        style: TextStyle(
                          color: _selectedGender == 'Male'
                              ? Colors.blue
                              : Colors.white60,
                          fontWeight: _selectedGender == 'Male'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Female'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Female'
                        ? Colors.pink.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        color: _selectedGender == 'Female'
                            ? Colors.pink
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Female',
                        style: TextStyle(
                          color: _selectedGender == 'Female'
                              ? Colors.pink
                              : Colors.white60,
                          fontWeight: _selectedGender == 'Female'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(18),
          border: InputBorder.none,
          hintText: 'Enter your age',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(Icons.person, color: Colors.blue, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _heightController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(18),
          border: InputBorder.none,
          hintText: 'Enter your height in cm',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(Icons.straighten, color: Colors.green, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _weightController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(18),
          border: InputBorder.none,
          hintText: 'Enter your weight in kg',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(Icons.monitor_weight, color: Colors.orange, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      child: ElevatedButton(
        onPressed: _calculateBMI,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Calculate BMI',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAboutBMISection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About BMI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Body mass index (BMI) is a person\'s weight in kilograms divided by the square of height in metres. BMI is an easy screening method for weight category.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
