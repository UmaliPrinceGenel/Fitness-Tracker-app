import 'package:flutter/material.dart';

class WaistMeasurementInfoScreen extends StatelessWidget {
  const WaistMeasurementInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'About Waist Measurement',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Waist Measurement Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "What is Waist Measurement?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Waist measurement is a key indicator of abdominal fat and overall health risk. It provides important information about your body composition that goes beyond just weight or BMI. Regularly monitoring your waist circumference can help assess your risk for various health conditions.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Excess abdominal fat is associated with increased risk of heart disease, type 2 diabetes, high blood pressure, and certain cancers. Maintaining a healthy waist measurement is crucial for long-term health and well-being.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "How to Measure Correctly?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "1. Stand straight and breathe normally\n2. Locate your hip bone and the bottom of your ribs\n3. Place the measuring tape midway between these points\n4. Ensure the tape is parallel to the floor\n5. Keep the tape snug but not compressing the skin\n6. Take the measurement at the end of a normal breath",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Why is Waist Measurement Important?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Waist measurement is a better predictor of health risks than BMI alone because it specifically measures abdominal fat. Visceral fat around your organs is metabolically active and can release inflammatory substances that increase disease risk.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Healthy Waist Measurement Guidelines",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "For Men:\n• Low risk: Less than 94 cm (37 inches)\n• Increased risk: 94-102 cm (37-40 inches)\n• High risk: More than 102 cm (40 inches)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "For Women:\n• Low risk: Less than 80 cm (31.5 inches)\n• Increased risk: 80-88 cm (31.5-34.6 inches)\n• High risk: More than 88 cm (34.6 inches)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "How Often Should I Measure?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We recommend measuring your waist:\n• Once a week for general monitoring\n• At the same time of day (preferably morning)\n• Under similar conditions (before eating)\n• Using the same measuring tape for consistency",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tips for Reducing Waist Measurement",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "• Engage in regular aerobic exercise\n• Include strength training 2-3 times per week\n• Reduce refined carbohydrates and added sugars\n• Increase fiber intake from vegetables and whole grains\n• Manage stress levels and get adequate sleep\n• Stay hydrated and limit alcohol consumption",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "When to Consult a Healthcare Professional",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "If your waist measurement falls into the 'high risk' category or if you notice rapid changes in your waist size, it's recommended to consult with a healthcare provider. They can provide personalized advice and help develop a plan to improve your health metrics.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}