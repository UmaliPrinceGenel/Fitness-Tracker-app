import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_login_screen.dart';

class AboutThisAppScreen extends StatefulWidget {
  const AboutThisAppScreen({super.key});

  @override
  State<AboutThisAppScreen> createState() => _AboutThisAppScreenState();
}

class _AboutThisAppScreenState extends State<AboutThisAppScreen> {
  static const Color _surfaceColor = Color(0xFF171717);
  static const Color _surfaceBorder = Color(0xFF2A2A2A);
  static const Color _accentColor = Color(0xFFFF8A3D);
  static const Color _accentColorDeep = Color(0xFFFF5A36);

  int _tapCount = 0;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _handleLogoTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 10) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminLoginScreen(),
          ),
        );
        _tapCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'About This App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _handleLogoTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _surfaceBorder),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B1B1B), Color(0xFF111111)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_accentColor, _accentColorDeep],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF7A2F),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rockies Fitness',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Train with structure, track with clarity, and stay consistent every day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _HeroChip(
                          icon: Icons.local_fire_department,
                          label: 'Workout Tracking',
                        ),
                        _HeroChip(
                          icon: Icons.favorite,
                          label: 'Health Insights',
                        ),
                        _HeroChip(
                          icon: Icons.groups_rounded,
                          label: 'Community Support',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              title: 'About Rockies Fitness',
              subtitle:
                  'A fitness companion focused on structure, progress, and daily consistency.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Rockies Fitness helps users stay on top of workouts, body progress, and daily health data in one place. From guided workout plans to sleep, BMI, and progress albums, the app is built to make your routine easier to follow and easier to improve.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 16),
                  _InfoBadgeRow(
                    leading: 'Built for',
                    value: 'Daily fitness tracking',
                  ),
                  SizedBox(height: 10),
                  _InfoBadgeRow(
                    leading: 'Designed to help',
                    value: 'Stay consistent and motivated',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              title: 'Key Features',
              subtitle:
                  'The core tools that make Rockies Fitness useful day to day.',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.home,
              title: 'Home Dashboard',
              description:
                  'See calories, workout minutes, BMI, and body metrics in one focused dashboard.',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Community',
              description:
                  'Share wins, post progress, and stay motivated with other users on the same path.',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.directions_run,
              title: 'Workout Plans',
              description:
                  'Follow structured plans, log reps and weights, and keep a clean workout history.',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.photo_library,
              title: 'Progress Album',
              description:
                  'Keep visual check-ins organized by day so recent and older progress stay easy to review.',
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              title: 'Technical Information',
              subtitle: 'Quick details about the current build.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Version', 'DEV 0.0.5'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Build Date', 'December 2025'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Flutter Version', '3.16.0'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Platform', 'iOS & Android'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              title: 'Developer Information',
              subtitle: 'Project and repository details.',
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _launchURL(
                'https://github.com/UmaliPrinceGenel/Fitness-Tracker-app',
              ),
              child: _buildSectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                      ),
                      child: const Icon(Icons.code, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SE Group 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Code Repository',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.link, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Visit GitHub',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              title: 'Acknowledgements',
              subtitle: 'Tools and support behind the app.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              child: Column(
                children: const [
                  _AcknowledgementRow(
                    label: 'Firebase',
                    detail: 'Authentication and data storage',
                  ),
                  SizedBox(height: 12),
                  _AcknowledgementRow(
                    label: 'Supabase',
                    detail: 'Image and file storage',
                  ),
                  SizedBox(height: 12),
                  _AcknowledgementRow(
                    label: 'Flutter Community',
                    detail: 'Packages and tooling support',
                  ),
                  SizedBox(height: 12),
                  _AcknowledgementRow(
                    label: 'Beta Testers',
                    detail: 'Feedback and real usage insights',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentColor, _accentColorDeep],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF7A2F),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 30),
                  SizedBox(height: 12),
                  Text(
                    'Rock solid routines. Real progress. One place to keep going.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorder),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadgeRow extends StatelessWidget {
  const _InfoBadgeRow({
    required this.leading,
    required this.value,
  });

  final String leading;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leading,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcknowledgementRow extends StatelessWidget {
  const _AcknowledgementRow({
    required this.label,
    required this.detail,
  });

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _AboutThisAppScreenState._accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
