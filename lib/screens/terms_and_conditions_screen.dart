import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/web_auth_shell.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  Widget _buildWebTermsScreen(BuildContext context) {
    return WebAuthShell(
      leftTitle: 'Welcome',
      leftSubtitle: 'Rockies Fitness Gym Tracker',
      rightChild: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool narrow = constraints.maxWidth < 420;
            final double contentHeight = narrow ? 420 : 470;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                height: contentHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        color: const Color(0xFF141414),
                        fontSize: narrow ? 24 : 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(narrow ? 14 : 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE0DBD7)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _WebTermsSection(
                                title: '1. Acceptance of Terms',
                                body:
                                    'By downloading or using this app, you agree to be bound by these Terms and Conditions. If you do not agree, do not use the app.',
                              ),
                              _WebTermsSection(
                                title: '2. Health Disclaimer',
                                body:
                                    'This app provides fitness-related content for informational purposes only. It does not substitute for professional medical advice. Consult a healthcare provider before beginning any exercise program. Use of the app is at your own risk.',
                              ),
                              _WebTermsSection(
                                title: '3. User Responsibilities',
                                body:
                                    'You are responsible for maintaining the security of your account and device. Do not share your login credentials. Any content you upload must be lawful and owned by you.',
                              ),
                              _WebTermsSection(
                                title: '4. Intellectual Property',
                                body:
                                    'All content, trademarks, and software within the app are the property of the app provider. You may not copy, modify, or reverse-engineer any part of the app.',
                              ),
                              _WebTermsSection(
                                title: '5. Privacy and Data Usage',
                                body:
                                    'The app may collect and process personal data to improve services. You are responsible for any data charges incurred while using the app.',
                              ),
                              _WebTermsSection(
                                title: '6. Limitation of Liability',
                                body:
                                    'The app provider is not liable for injuries, health issues, or damages resulting from use of the app. You assume full responsibility for your participation in workouts.',
                              ),
                              _WebTermsSection(
                                title: '7. Deletion of Account',
                                body:
                                    'The provider may suspend or terminate your access if you violate these Terms.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF141414),
                          side: const BorderSide(color: Color(0xFFD8D2CE)),
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebTermsScreen(context);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button with circular background
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF191919),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Header - Fixed at the top
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Content container with fixed header and scrollable text
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF191919),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed header inside the container
                        const Text(
                          "Rockies Fitness Terms and Conditions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Scrollable text content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Content with consistent border radius on all corners
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Section 1
                                      const Text(
                                        "1. Acceptance of Terms",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "By downloading or using this app, you agree to be bound by these Terms and Conditions. If you do not agree, do not use the app.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 2
                                      const Text(
                                        "2. Health Disclaimer",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "This app provides fitness-related content for informational purposes only. It does not substitute for professional medical advice. Consult a healthcare provider before beginning any exercise program. Use of the app is at your own risk.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 3
                                      const Text(
                                        "3. User Responsibilities",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "You are responsible for maintaining the security of your account and device. Do not share your login credentials. Any content you upload must be lawful and owned by you.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 4
                                      const Text(
                                        "4. Intellectual Property",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "All content, trademarks, and software within the app are the property of the app provider. You may not copy, modify, or reverse-engineer any part of the app.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 5
                                      const Text(
                                        "5. Privacy and Data Usage",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "The app may collect and process personal data to improve services. You are responsible for any data charges incurred while using the app.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 6
                                      const Text(
                                        "6. Limitation of Liability",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "The app provider is not liable for injuries, health issues, or damages resulting from use of the app. You assume full responsibility for your participation in workouts.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Section 7
                                      const Text(
                                        "7. Deletion of Account",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "The provider may suspend or terminate your access if you violate these Terms.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Add some spacing at the bottom
                                const SizedBox(height: 20),
                              ],
                            ),
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
    );
  }
}

class _WebTermsSection extends StatelessWidget {
  const _WebTermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF141414),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF575757),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
