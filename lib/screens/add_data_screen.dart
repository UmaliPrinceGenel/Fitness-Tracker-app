import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddDataScreen extends StatefulWidget {
  final String title;
  final VoidCallback? onDataSaved;
  const AddDataScreen({
    super.key,
    required this.title,
    this.onDataSaved,
  });

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _valueController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveData() async {
    if (_valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a value'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final value = double.tryParse(_valueController.text);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        switch (widget.title) {
          case "Waist Measurement":
            // Update waist measurement in main health metrics and subcollection
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('health_metrics')
                .doc('current')
                .set({
                  'waistMeasurement': value,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            // Add to waist history subcollection for Android compatibility
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('waist_history')
                .doc(DateTime.now().toIso8601String())
                .set({
                  'waist': value,
                  'date': DateTime.now(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
            break;
          case "Weight":
            // Update weight in main health metrics and subcollection
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('health_metrics')
                .doc('current')
                .set({
                  'weight': value,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            // Update in user profile
            await _firestore.collection('users').doc(user.uid).set({
              'profile.weight': value,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Add to weight history subcollection for Android compatibility
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('weight_history')
                .doc(DateTime.now().toIso8601String())
                .set({
                  'weight': value,
                  'date': DateTime.now(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
            break;
          case "Sleep Hours":
            // Update sleep hours in main health metrics and subcollection
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('health_metrics')
                .doc('current')
                .set({
                  'sleepHours': value,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            // Add to sleep history subcollection for Android compatibility
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('sleep_history')
                .doc(DateTime.now().toIso8601String())
                .set({
                  'sleepHours': value,
                  'date': DateTime.now(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
            break;
        }

        // Notify parent screen of the update
        widget.onDataSaved?.call();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the screen
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String unit = '';
    String hintText = '';
    double maxValue = 999.0;

    switch (widget.title) {
      case "Waist Measurement":
        unit = "cm";
        hintText = "Enter waist measurement in cm";
        maxValue = 300.0;
        break;
      case "Weight":
        unit = "kg";
        hintText = "Enter weight in kg";
        maxValue = 500.0;
        break;
      case "Sleep Hours":
        unit = "hours";
        hintText = "Enter sleep hours";
        maxValue = 24.0;
        break;
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
          "Add ${widget.title}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF191919),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New ${widget.title}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Unit: $unit",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
