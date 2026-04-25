import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'admin_community_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_route_utils.dart';
import 'admin_users_screen.dart';
import 'community_member_profile_screen.dart';
import 'login_screen.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _feedback = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredFeedback = [];

  int get _unreviewedCount =>
      _feedback.where((item) => item['isReviewed'] != true).length;
  int get _reviewedCount =>
      _feedback.where((item) => item['isReviewed'] == true).length;
  double get _averageRating {
    if (_feedback.isEmpty) return 0;

    final total = _feedback.fold<int>(
      0,
      (sum, item) => sum + ((item['rating'] as int?) ?? 0),
    );
    return total / _feedback.length;
  }

  List<int> get _ratingDistribution => List<int>.generate(
        5,
        (index) => _feedback
            .where((item) => ((item['rating'] as int?) ?? 0) == index + 1)
            .length,
      );
  List<Map<String, dynamic>> get _newFeedback => _filteredFeedback
      .where((item) => item['isReviewed'] != true)
      .toList(growable: false);
  List<Map<String, dynamic>> get _reviewedFeedback => _filteredFeedback
      .where((item) => item['isReviewed'] == true)
      .toList(growable: false);

  void _onNavTapped(int index) {
    if (index == 3) return;

    final Widget page;
    if (index == 0) {
      page = const AdminDashboardScreen();
    } else if (index == 1) {
      page = const AdminUsersScreen();
    } else {
      page = const AdminCommunityScreen();
    }

    Navigator.pushReplacement(
      context,
      buildAdminRoute(page),
    );
  }

  Future<void> _logoutAdmin() async {
    final shouldLogout = await _showConfirmationDialog(
      'Logout Admin',
      'Are you sure you want to log out of the admin panel?',
    );
    if (!shouldLogout) return;

    final fbAuth.FirebaseAuth _firebaseAuth = fbAuth.FirebaseAuth.instance;
    await _firebaseAuth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF191919),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content:
                Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final snapshot = await _firestore
          .collection('user_feedback')
          .orderBy('createdAt', descending: true)
          .get();

      final feedback = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'userId': (data['userId'] ?? '').toString(),
          'displayName': (data['displayName'] ?? 'User').toString(),
          'email': (data['email'] ?? '').toString(),
          'photoURL': (data['photoURL'] ?? '').toString(),
          'rating': (data['rating'] as num?)?.toInt() ?? 0,
          'comment': (data['comment'] ?? '').toString(),
          'isReviewed': data['isReviewed'] == true,
          'createdAt': data['createdAt'],
        };
      }).toList();

      setState(() {
        _feedback = feedback;
        _applySearchFilter(_searchQuery);
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applySearchFilter(String query) {
    final normalized = query.trim().toLowerCase();
    final filtered = _feedback.where((item) {
      return normalized.isEmpty ||
          item['displayName'].toString().toLowerCase().contains(normalized) ||
          item['email'].toString().toLowerCase().contains(normalized) ||
          item['comment'].toString().toLowerCase().contains(normalized);
    }).toList();
    
    setState(() {
      _searchQuery = query;
      _filteredFeedback = filtered;
    });
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('MMM d, yyyy - hh:mm a').format(value.toDate());
    }
    return 'Unknown date';
  }

  Future<void> _toggleFeedbackReviewed(Map<String, dynamic> item) async {
    final feedbackId = item['id']?.toString() ?? '';
    if (feedbackId.isEmpty) return;

    final bool nextValue = item['isReviewed'] != true;

    try {
      await _firestore.collection('user_feedback').doc(feedbackId).update({
        'isReviewed': nextValue,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      await _loadFeedback(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feedback marked as reviewed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openUserProfile(Map<String, dynamic> item) {
    final userId = item['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMemberProfileScreen(
          userId: userId,
          initialDisplayName: item['displayName']?.toString(),
          initialProfileImageUrl: item['photoURL']?.toString().isNotEmpty == true
              ? item['photoURL']?.toString()
              : null,
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 4),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 18,
          ),
        );
      }),
    );
  }

  Widget _buildAverageRatingRow(double rating, {double iconSize = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        IconData icon;
        if (rating >= starNumber) {
          icon = Icons.star_rounded;
        } else if (rating >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 4),
          child: Icon(
            icon,
            color: Colors.amber,
            size: iconSize,
          ),
        );
      }),
    );
  }

  Widget _buildRatingInsightsCard() {
    final distribution = _ratingDistribution;
    final maxCount = distribution.isEmpty
        ? 1.0
        : distribution.reduce((a, b) => a > b ? a : b).toDouble();
    final chartMaxY = maxCount == 0 ? 1.0 : maxCount + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Average stars and how ratings are distributed from 1 to 5.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: isSmallScreen ? double.infinity : 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAverageRatingRow(_averageRating, iconSize: 18),
                        const SizedBox(height: 8),
                        Text(
                          '${_feedback.length} ratings',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSmallScreen)
                    SizedBox(
                      width: 190,
                      height: 180,
                      child: _buildBarChart(distribution, chartMaxY),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: _buildBarChart(distribution, chartMaxY),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> distribution, double chartMaxY) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: chartMaxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E1E1E),
            tooltipRoundedRadius: 12,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final count = distribution[group.x.toInt()];
              return BarTooltipItem(
                '${group.x + 1} star: $count',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0 || value < 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final label = value.toInt() + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$label',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(5, (index) {
          final count = distribution[index].toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFFFF8A00),
                    Color(0xFFFFD54F),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final photoUrl = item['photoURL']?.toString() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;
    final email = item['email']?.toString().trim().isNotEmpty == true
        ? item['email'].toString()
        : 'No email provided';
    final isReviewed = item['isReviewed'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.amber.withOpacity(0.14),
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['displayName']?.toString() ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusPill(
                          isReviewed ? 'Reviewed' : 'Needs Review',
                          isReviewed ? Colors.green : Colors.orange,
                        ),
                        _buildStatusPill(
                          _formatTimestamp(item['createdAt']),
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRatingRow(item['rating'] as int),
          const SizedBox(height: 12),
          Text(
            item['comment']?.toString().isNotEmpty == true
                ? item['comment'].toString()
                : 'No comment provided.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isReviewed)
                _buildActionChip(
                  label: 'Mark Reviewed',
                  icon: Icons.task_alt,
                  color: Colors.green,
                  onTap: () => _toggleFeedbackReviewed(item),
                ),
              if ((item['userId']?.toString().isNotEmpty ?? false))
                _buildActionChip(
                  label: 'View Profile',
                  icon: Icons.person_outline,
                  color: Colors.blue,
                  onTap: () => _openUserProfile(item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== WEB UI METHODS WITH SIDEBAR NAVIGATION ==============

  Widget _buildSidebarNavItem(String label, int index, IconData icon) {
    final isSelected = index == 3;
    
    return InkWell(
      onTap: () => _onNavTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: Colors.orange.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.white54,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSidebarNavigation() {
    return Container(
      width: 280,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Feedback Management',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          _buildSidebarNavItem('Overview', 0, Icons.dashboard_outlined),
          _buildSidebarNavItem('Users', 1, Icons.people_outline),
          _buildSidebarNavItem('Community', 2, Icons.forum_outlined),
          _buildSidebarNavItem('Feedback', 3, Icons.rate_review_outlined),
          const Spacer(),
          InkWell(
            onTap: _logoutAdmin,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.red, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFF0F0F0F),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          onChanged: (value) => _applySearchFilter(value),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search feedback by user, email, or comment...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.orange),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildWebStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildWebSummaryCard(
              icon: Icons.rate_review_outlined,
              iconColor: Colors.amber,
              label: 'Total Feedback',
              value: _feedback.length.toString(),
              subtitle: 'All user submissions',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebSummaryCard(
              icon: Icons.pending_actions,
              iconColor: Colors.orange,
              label: 'Pending Review',
              value: _unreviewedCount.toString(),
              subtitle: 'Need attention',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebSummaryCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              label: 'Reviewed',
              value: _reviewedCount.toString(),
              subtitle: 'Already processed',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWebSummaryCard(
              icon: Icons.star_rate_rounded,
              iconColor: Colors.amber,
              label: 'Average Rating',
              value: _averageRating.toStringAsFixed(1),
              subtitle: 'Out of 5.0 stars',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFeedbackSection() {
    if (_filteredFeedback.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No feedback found',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Pending Review', icon: Icon(Icons.pending_actions)),
                Tab(text: 'Reviewed', icon: Icon(Icons.check_circle_outline)),
              ],
            ),
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                _newFeedback.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No pending feedback to review',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _newFeedback.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFeedbackCard(_newFeedback[index]),
                        ),
                      ),
                _reviewedFeedback.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No reviewed feedback yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviewedFeedback.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFeedbackCard(_reviewedFeedback[index]),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingInsightsCard(),
          const SizedBox(height: 20),
          _buildWebFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFeedback(showLoader: false),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWebSidebarNavigation(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildWebSearchBar(),
                        _buildWebStatsRow(),
                        Expanded(
                          child: _buildWebContent(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============== MOBILE UI (UNCHANGED) ==============

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 800;
    
    if (isWeb && isLargeScreen) {
      return _buildWebLayout();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Feedback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _loadFeedback(showLoader: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Feedback Inbox',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Review ratings and comments submitted by users from their profile screen.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildStatChip(
                                  'Total',
                                  _feedback.length.toString(),
                                  Colors.amber,
                                ),
                                _buildStatChip(
                                  'Pending',
                                  _unreviewedCount.toString(),
                                  Colors.orange,
                                ),
                                _buildStatChip(
                                  'Reviewed',
                                  _reviewedCount.toString(),
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRatingInsightsCard(),
                      const SizedBox(height: 20),
                      if (_feedback.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Text(
                            'No feedback has been submitted yet.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        )
                      else ...[
                        _buildSectionHeader(
                          'New Feedback',
                          'Newest feedback always stays at the top until it is reviewed.',
                        ),
                        const SizedBox(height: 14),
                        if (_newFeedback.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF191919),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Text(
                              'No new feedback waiting for review.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ..._newFeedback.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFeedbackCard(item),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          'Reviewed Feedback',
                          'Previously checked feedback stays here as your history.',
                        ),
                        const SizedBox(height: 14),
                        if (_reviewedFeedback.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF191919),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Text(
                              'No reviewed feedback yet.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ..._reviewedFeedback.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFeedbackCard(item),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}