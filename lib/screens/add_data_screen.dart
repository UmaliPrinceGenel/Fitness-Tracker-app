import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDataScreen extends StatefulWidget {
  final String title;

  const AddDataScreen({super.key, required this.title});

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

  void _onSave() {
    // In a real app, you would save the data here
    // For now, we'll just pop back to the previous screen
    Navigator.pop(context);
  }

  void _calculateBMI() {
    // Calculate BMI when the button is pressed
    // For now, just show a snackbar with the calculated BMI
    if (_ageController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        _selectedGender != null) {
      double weight = double.tryParse(_weightController.text) ?? 0;
      double height = double.tryParse(_heightController.text) ?? 0;
      if (height > 0) {
        // Calculate BMI: weight (kg) / (height (m))^2
        double heightInMeters = height / 100; // Convert cm to meters
        double bmi = weight / (heightInMeters * heightInMeters);
        String bmiText = bmi.toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your BMI is: $bmiText'),
            backgroundColor: Colors.orange,
          ),
        );
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

  List<Color> _getDateGradientColors() {
    switch (widget.title) {
      case "Calories":
        return [
          const Color(0xFFFF6B35),
          const Color(0xFFFF9800),
        ]; // Red-orange gradient
      case "Steps":
        return [
          const Color(0xFFFF9800),
          const Color(0xFFFFC107),
        ]; // Orange gradient
      case "Moving":
        return [
          const Color(0xFF2196F3),
          const Color(0xFF03A9F4),
        ]; // Blue gradient
      case "Weight":
        return [
          const Color(0xFF4CAF50),
          const Color(0xFF8BC34A),
        ]; // Green gradient
      case "Body Fat %":
        return [
          const Color(0xFF2196F3),
          const Color(0xFF3F51B5),
        ]; // Blue gradient
      case "BMI":
        return [
          const Color(0xFFFF9800),
          const Color(0xFFFFC107),
        ]; // Orange gradient
      default:
        return [
          const Color(0xFF1A1A1A),
          const Color(0xFF121212),
        ]; // Default dark gradient
    }
  }

  Color _getHintTextColor() {
    switch (widget.title) {
      case "Calories":
        return const Color(0xFFFF6B35); // Red-orange color
      case "Steps":
        return const Color(0xFFFF9800); // Orange color
      case "Moving":
        return const Color(0xFF2196F3); // Blue color
      case "Weight":
        return const Color(0xFF4CAF50); // Green color
      case "Body Fat %":
        return const Color(0xFF2196F3); // Blue color
      case "BMI":
        return const Color(0xFFFF9800); // Orange color
      default:
        return Colors.white60; // Default color
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
            ? SingleChildScrollView(
                // Make BMI screen scrollable
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BMI-specific content
                      // Gender selection (moved to the top)
                      const Text(
                        'Gender',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = 'Male';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == 'Male'
                                          ? Colors.blue.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            fontWeight:
                                                _selectedGender == 'Male'
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
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = 'Female';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == 'Female'
                                          ? Colors.pink.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            fontWeight:
                                                _selectedGender == 'Female'
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
                      ),
                      const SizedBox(height: 20),

                      // Age input
                      const Text(
                        'Age',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(18),
                            border: InputBorder.none,
                            hintText: 'Enter your age',
                            hintStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Height input
                      const Text(
                        'Height (cm)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(18),
                            border: InputBorder.none,
                            hintText: 'Enter your height in cm',
                            hintStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                              ),
                              child: const Icon(
                                Icons.straighten,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Weight input
                      const Text(
                        'Weight (kg)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(18),
                            border: InputBorder.none,
                            hintText: 'Enter your weight in kg',
                            hintStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                              ),
                              child: const Icon(
                                Icons.monitor_weight,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Calculate button
                      Container(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About BMI section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About BMI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Body mass index (BMI) is a person\'s weight in kilograms divided by the square of height in metres. BMI is an easy screening method for weight category.',
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
                ),
              )
            : Padding(
                // For non-BMI screens, keep the original layout
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display selected date at the top
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Date selection
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
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
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Time selection
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.access_time,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Input field that changes based on title (for non-BMI screens)
                    Text(
                      widget.title == "Body Fat %"
                          ? 'Body Fat %'
                          : widget.title == "Calories"
                          ? 'Calories (kcal)'
                          : widget.title == "Steps"
                          ? 'Steps'
                          : widget.title == "Moving"
                          ? 'Moving (Intensity)'
                          : '${widget.title} (kg)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
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
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(18),
                          border: InputBorder.none,
                          hintText: widget.title == "Body Fat %"
                              ? 'Enter body fat percentage'
                              : widget.title == "Calories"
                              ? 'Enter calories in kcal'
                              : widget.title == "Steps"
                              ? 'Enter number of steps'
                              : widget.title == "Moving"
                              ? 'Enter moving intensity'
                              : 'Enter ${widget.title.toLowerCase()} in kg',
                          hintStyle: TextStyle(color: _getHintTextColor()),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 8.0,
                            ),
                            child: widget.title == "Body Fat %"
                                ? const Icon(
                                    Icons.monitor_heart,
                                    color: Colors.blue,
                                    size: 24,
                                  )
                                : widget.title == "Calories"
                                ? const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                    size: 24,
                                  )
                                : widget.title == "Steps"
                                ? const Icon(
                                    Icons.directions_walk,
                                    color: Colors.green,
                                    size: 24,
                                  )
                                : widget.title == "Moving"
                                ? const Icon(
                                    Icons.directions_run,
                                    color: Colors.purple,
                                    size: 24,
                                  )
                                : const Icon(
                                    Icons.monitor_weight,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
