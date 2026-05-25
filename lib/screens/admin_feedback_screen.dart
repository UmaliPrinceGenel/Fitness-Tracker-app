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
import 'admin_custom_workout_screen.dart';
import 'community_member_profile_screen.dart';
import 'login_screen.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import 'dart:ui' as ui;

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
    } else if (index == 2) {
      page = const AdminCommunityScreen();
    } else {
      page = const AdminCustomWorkoutScreen();
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

  Widget _buildStatChip(String label, String value, Color color, {IconData? icon}) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon ?? Icons.analytics_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 420 ? 3 : width >= 280 ? 2 : 1;
        const spacing = 8.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
        );
      },
    );
  }

  Widget _buildStatusPill(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color.withOpacity(0.8)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.12),
                color.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
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
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.015),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution of ${_feedback.length} ratings from 1 to 5 stars',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: isSmallScreen ? double.infinity : 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.08),
                          Colors.amber.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAverageRatingRow(_averageRating, iconSize: 18),
                        const SizedBox(height: 8),
                        Text(
                          '${_feedback.length} ratings',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
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

  Widget _buildSectionHeader(String title, String subtitle, {int count = 0}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final photoUrl = item['photoURL']?.toString() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;
    final email = item['email']?.toString().trim().isNotEmpty == true
        ? item['email'].toString()
        : 'No email provided';
    final isReviewed = item['isReviewed'] == true;
    final rating = (item['rating'] as int?) ?? 0;
    final displayName = item['displayName']?.toString() ?? 'User';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.015),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !isReviewed
              ? const Color(0xFFFF7317).withOpacity(0.12)
              : Colors.white.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isReviewed
                          ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                          : [const Color(0xFFFF7317), const Color(0xFFFF9E59)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1A1A1A),
                    backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: isReviewed ? const Color(0xFF4ADE80) : const Color(0xFFFF7317),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusPill(
                            isReviewed ? 'REVIEWED' : 'PENDING',
                            isReviewed ? const Color(0xFF4ADE80) : const Color(0xFFFF7317),
                            icon: isReviewed ? Icons.check_circle_outline : Icons.schedule,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.mail_outline, size: 11, color: Colors.white.withOpacity(0.35)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 11, color: Colors.white.withOpacity(0.35)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(item['createdAt']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
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
          // Rating + Comment
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _buildRatingRow(rating),
                const SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: TextStyle(
                    color: Colors.amber.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Text(
                item['comment']?.toString().isNotEmpty == true
                    ? item['comment'].toString()
                    : 'No comment provided.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: item['comment']?.toString().isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
          ),
          // Action bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                if (!isReviewed)
                  Expanded(
                    child: _buildActionChip(
                      label: 'Mark Reviewed',
                      icon: Icons.task_alt,
                      color: const Color(0xFF4ADE80),
                      onTap: () => _toggleFeedbackReviewed(item),
                    ),
                  ),
                if (!isReviewed && (item['userId']?.toString().isNotEmpty ?? false))
                  const SizedBox(width: 8),
                if ((item['userId']?.toString().isNotEmpty ?? false))
                  Expanded(
                    child: _buildActionChip(
                      label: 'View Profile',
                      icon: Icons.person_outline,
                      color: const Color(0xFF4DA6FF),
                      onTap: () => _openUserProfile(item),
                    ),
                  ),
              ],
            ),
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
          _buildSidebarNavItem('Custom Workout', 4, Icons.fitness_center),
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
      extendBody: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Atmospheric glowing backdrops
            Positioned(
              top: -140,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7317).withOpacity(0.07),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: 350,
              left: -150,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.04),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.04),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7317)),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading feedback...',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF7317),
                    backgroundColor: const Color(0xFF1A1A1A),
                    onRefresh: () => _loadFeedback(showLoader: false),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Header
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7317).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFF7317).withOpacity(0.2)),
                                  ),
                                  child: const Text(
                                    'RATINGS & REVIEWS',
                                    style: TextStyle(
                                      color: Color(0xFFFF7317),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Feedback',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Review user ratings, comments & app feedback',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.06),
                                  Colors.white.withOpacity(0.025),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.07)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: _applySearchFilter,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search feedback by name or comment...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                prefixIcon: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFFFF7317), Color(0xFFFF9E59)],
                                  ).createShader(bounds),
                                  child: const Icon(Icons.search, color: Colors.white, size: 22),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4), size: 18),
                                        onPressed: () => _applySearchFilter(''),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stats Row
                          _buildStatsGrid([
                            _buildStatChip(
                              'Total',
                              _feedback.length.toString(),
                              const Color(0xFF4DA6FF),
                              icon: Icons.inbox_outlined,
                            ),
                            _buildStatChip(
                              'Pending',
                              _unreviewedCount.toString(),
                              const Color(0xFFFF7317),
                              icon: Icons.pending_outlined,
                            ),
                            _buildStatChip(
                              'Reviewed',
                              _reviewedCount.toString(),
                              const Color(0xFF4ADE80),
                              icon: Icons.check_circle_outline,
                            ),
                          ]),
                          const SizedBox(height: 16),

                          _buildRatingInsightsCard(),
                          const SizedBox(height: 22),

                          if (_feedback.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 48),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.rate_review_outlined,
                                        size: 40,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No feedback yet',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'User submissions will appear here',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            _buildSectionHeader(
                              'New Feedback',
                              'Unreviewed feedback.',
                              count: _newFeedback.length,
                            ),
                            const SizedBox(height: 12),
                            if (_newFeedback.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'All caught up! No new feedback.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 13,
                                    ),
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
                            const SizedBox(height: 18),
                            _buildSectionHeader(
                              'Reviewed',
                              'Previously reviewed.',
                              count: _reviewedFeedback.length,
                            ),
                            const SizedBox(height: 12),
                            if (_reviewedFeedback.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No reviewed feedback yet.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 13,
                                    ),
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 3,
        onTap: _onNavTapped,
      ),
    );
  }
}