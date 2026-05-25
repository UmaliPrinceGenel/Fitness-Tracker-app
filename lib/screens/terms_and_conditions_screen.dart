import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/web_auth_shell.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_back_button.dart';

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
    if (kIsWeb && MediaQuery.of(context).size.width >= 800) {
      return _buildWebTermsScreen(context);
    }

    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: colors.scaffold,
                  toolbarHeight: 80,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  title: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Row(
                      children: [
                        PremiumBackButton(
                          iconColor: colors.textPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Terms & Conditions",
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: colors.cardGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Rockies Fitness Agreements",
                            style: TextStyle(
                              color: Color(0xFFFF7317), // Theme accent color
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 24),
                          _TermsSection(
                            title: '1. Acceptance of Terms',
                            body:
                                'By downloading or using this app, you agree to be bound by these Terms and Conditions. If you do not agree, do not use the app.',
                          ),
                          _TermsSection(
                            title: '2. Health Disclaimer',
                            body:
                                'This app provides fitness-related content for informational purposes only. It does not substitute for professional medical advice. Consult a healthcare provider before beginning any exercise program. Use of the app is at your own risk.',
                          ),
                          _TermsSection(
                            title: '3. User Responsibilities',
                            body:
                                'You are responsible for maintaining the security of your account and device. Do not share your login credentials. Any content you upload must be lawful and owned by you.',
                          ),
                          _TermsSection(
                            title: '4. Intellectual Property',
                            body:
                                'All content, trademarks, and software within the app are the property of the app provider. You may not copy, modify, or reverse-engineer any part of the app.',
                          ),
                          _TermsSection(
                            title: '5. Privacy and Data Usage',
                            body:
                                'The app may collect and process personal data to improve services. You are responsible for any data charges incurred while using the app.',
                          ),
                          _TermsSection(
                            title: '6. Limitation of Liability',
                            body:
                                'The app provider is not liable for injuries, health issues, or damages resulting from use of the app. You assume full responsibility for your participation in workouts.',
                          ),
                          _TermsSection(
                            title: '7. Deletion of Account',
                            body:
                                'The provider may suspend or terminate your access if you violate these Terms.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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
