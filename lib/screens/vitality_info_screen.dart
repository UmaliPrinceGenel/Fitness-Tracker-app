import 'package:flutter/material.dart';

class VitalityInfoScreen extends StatelessWidget {
  const VitalityInfoScreen({super.key});

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
          'About Vitality Score',
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
                  "Vitality Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "What is Vitality score?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Vitality score can be used to assess the positive impact of personal exercise on health. Regularly reaching a 7-day vitality score of 100 can have significant positive health impacts.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Vitality score is based on the WHO Guidelines on Physical Activity and Sedentary Behaviour, which recommend that: All healthy adults engage in at least 150-300 minutes of moderate-intensity exercise or 75-150 minutes of high-intensity exercise per week; or an equivalent combination of moderate and higher intensity exercise. At the same time, a little physical exercise is better than none. Replacing sedentary time with low-intensity exercise also has health benefits.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "How is it calculated?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The Vitality Score is customized based on your age, resting heart rate, maximum heart rate, and workout data from the past 7 days. You can earn Vitality points by exercising while wearing your device. Higher-intensity exercise will earn you more Vitality points in a shorter amount of time. As your Vitality score increases, it becomes more difficult to earn more points",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Why is it calculated on a 7-day basis?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Vitality score is a health indicator for the past 7 days. You don't have to exercise a lot on any given day, nor exercise every day; you can earn Vitality points by exercising at any time within the 7-day period. We recommend exercising at least 2-3 times a week to maintain your physical and mental health.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "How many Vitality points can I earn?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You can earn up to 80 Vitality points per day, so theoretically you could reach a score of 560 points over 7 days. However, as your score increases, it becomes increasingly difficult to earn more points.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Why set the three goals of 30, 60, and 100 points?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The WHO Guidelines on Physical Activity and Sedentary Behaviour recommend that all healthy adults engage in at least 75 minutes of higher-intensity exercise or 150 minutes of moderate-intensity exercise per week. For additional health benefits, a minimum of 300 minutes of moderate intensity activity or 150 minutes of higher intensity activity per week is required; alternatively, a person can engage in a combination of moderate and higher intensity aerobic activity at the same caloric consumption level.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "When your 7-day Vitality score reaches 60, you've reached WHO's weekly minimum exercise recommendation. For the greatest health benefits, aim for a 7-day Vitality score of 100. Make sure to manage your workout intensity according to your physical health, and try to make it a habit to exercise regularly.",
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
