import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommunityMemberProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialDisplayName;
  final String? initialProfileImageUrl;

  const CommunityMemberProfileScreen({
    super.key,
    required this.userId,
    this.initialDisplayName,
    this.initialProfileImageUrl,
  });

  @override
  State<CommunityMemberProfileScreen> createState() =>
      _CommunityMemberProfileScreenState();
}

class _CommunityMemberProfileScreenState
    extends State<CommunityMemberProfileScreen> {
  static const Color _surface = Color(0xFF171717);
  static const Color _surfaceAlt = Color(0xFF1E1E1E);
  static const Color _border = Color(0xFF2A2A2A);
  static const double _minValidHeightCm = 80.0;
  static const double _maxValidHeightCm = 250.0;
  static const double _minValidWeightKg = 20.0;
  static const double _maxValidWeightKg = 400.0;
  static const double _minDisplayBmi = 10.0;
  static const double _maxDisplayBmi = 80.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<_CommunityMemberProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<_CommunityMemberProfileData> _loadProfileData() async {
    final userDoc =
        await _firestore.collection('users').doc(widget.userId).get();
    if (!userDoc.exists) {
      throw Exception('User profile not found.');
    }

    final healthDoc = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('health_metrics')
        .doc('current')
        .get();

    final doneInfosSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('doneInfos')
        .get();

    final exerciseRecordsSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('exercise_records')
        .get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final healthData = healthDoc.data() ?? <String, dynamic>{};

    final workoutRuns = doneInfosSnapshot.docs
        .map((doc) => _CommunityWorkoutRun.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final Map<String, _PersonalBestRecord> bestByExercise = {};
    for (final doc in exerciseRecordsSnapshot.docs) {
      final record = _PersonalBestRecord.fromMap(doc.data());
      final currentBest = bestByExercise[record.exerciseName];
      if (currentBest == null ||
          record.weightUsed > currentBest.weightUsed ||
          (record.weightUsed == currentBest.weightUsed &&
              record.timestamp != null &&
              currentBest.timestamp != null &&
              record.timestamp!.isAfter(currentBest.timestamp!))) {
        bestByExercise[record.exerciseName] = record;
      }
    }

    final bestRecords = bestByExercise.values.toList()
      ..sort((a, b) {
        final weightCompare = b.weightUsed.compareTo(a.weightUsed);
        if (weightCompare != 0) return weightCompare;
        final aTime = a.timestamp;
        final bTime = b.timestamp;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

    final weight = _readProfileNumber(userData, 'weight') > 0
        ? _readProfileNumber(userData, 'weight')
        : _parseDouble(healthData['weight']);
    final height = _readProfileNumber(userData, 'height') > 0
        ? _readProfileNumber(userData, 'height')
        : _parseDouble(healthData['height']);

    double bmi = _readProfileNumber(userData, 'bmi');
    if (bmi <= 0) {
      bmi = _parseDouble(healthData['bmi']);
    }
    if (bmi <= 0) {
      bmi = _computeSafeBmi(weightKg: weight, heightCm: height);
    }

    final totalCalories = workoutRuns.fold<int>(
      0,
      (sum, run) => sum + run.effectiveCalories,
    );
    final totalMinutes = workoutRuns.fold<int>(
      0,
      (sum, run) => sum + run.effectiveMinutes,
    );
    final cleanWorkouts = workoutRuns.where((run) => !run.isCheated).length;

    return _CommunityMemberProfileData(
      userId: widget.userId,
      displayName:
          (userData['displayName'] as String?)?.trim().isNotEmpty == true
              ? userData['displayName'] as String
              : (widget.initialDisplayName?.trim().isNotEmpty == true
                    ? widget.initialDisplayName!.trim()
                    : 'Community Member'),
      profileImageUrl: _resolveProfileImageUrl(userData),
      gender: userData['profile']?['gender']?.toString(),
      age: _calculateAge(userData),
      weight: weight,
      height: height,
      bmi: bmi,
      waistMeasurement: _parseDouble(healthData['waistMeasurement']),
      sleepHours: _parseDouble(healthData['sleepHours']),
      workoutRuns: workoutRuns,
      bestRecords: bestRecords,
      totalCalories: totalCalories,
      totalMinutes: totalMinutes,
      cleanWorkouts: cleanWorkouts,
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _readProfileNumber(Map<String, dynamic> userData, String key) {
    final profile = userData['profile'];
    if (profile is Map<String, dynamic>) {
      final value = profile[key];
      final parsed = _parseDouble(value);
      if (parsed > 0) return parsed;
    }

    final dottedValue = userData['profile.$key'];
    return _parseDouble(dottedValue);
  }

  String? _resolveProfileImageUrl(Map<String, dynamic> userData) {
    final url =
        userData['photoURL']?.toString() ??
        userData['profile']?['photoURL']?.toString() ??
        widget.initialProfileImageUrl;
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  int? _calculateAge(Map<String, dynamic> userData) {
    final birthdate =
        userData['profile']?['birthdate'] ??
        userData['profile']?['dateOfBirth'] ??
        userData['birthdate'];

    if (birthdate == null) return null;

    DateTime? birthDate;
    if (birthdate is Timestamp) {
      birthDate = birthdate.toDate();
    } else if (birthdate is String) {
      birthDate = DateTime.tryParse(birthdate);
    }

    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double _computeSafeBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg < _minValidWeightKg ||
        weightKg > _maxValidWeightKg ||
        heightCm < _minValidHeightCm ||
        heightCm > _maxValidHeightCm) {
      return 0.0;
    }

    final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    if (bmi < _minDisplayBmi || bmi > _maxDisplayBmi) return 0.0;
    return double.parse(bmi.toStringAsFixed(1));
  }

  String _formatMetric(
    double value,
    String unit, {
    bool allowEmpty = true,
  }) {
    if (value <= 0 && allowEmpty) return '--';
    final bool isWhole = value == value.roundToDouble();
    final formatted =
        isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$formatted $unit';
  }

  String _bmiLabel(double bmi) {
    if (bmi <= 0) return 'No BMI data';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0) return Colors.grey;
    if (bmi < 18.5) return const Color(0xFF3EA6FF);
    if (bmi < 25) return const Color(0xFF4CAF50);
    if (bmi < 30) return const Color(0xFFFFA726);
    return const Color(0xFFFF5A36);
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _loadProfileData();
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Community Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<_CommunityMemberProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            color: Colors.orange,
            backgroundColor: _surface,
            onRefresh: _refreshProfile,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final horizontalPadding = maxWidth > 900 ? 28.0 : 16.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(data),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            title: 'Health Stats',
                            subtitle:
                                'A quick view of this member\'s current body metrics.',
                          ),
                          const SizedBox(height: 14),
                          _buildHealthStatsGrid(data),
                          const SizedBox(height: 28),
                          _buildSectionTitle(
                            title: 'Workout Progress',
                            subtitle:
                                'Completion totals and recorded effort across finished workouts.',
                          ),
                          const SizedBox(height: 14),
                          _buildWorkoutSummaryGrid(data),
                          const SizedBox(height: 28),
                          _buildSectionTitle(
                            title: 'Best Personal Records',
                            subtitle:
                                'Top recorded lifts and exercise performances.',
                          ),
                          const SizedBox(height: 14),
                          _buildPersonalBestSection(data),
                          const SizedBox(height: 28),
                          _buildSectionTitle(
                            title: 'Completed Workouts',
                            subtitle:
                                'Full workout history from this community member.',
                          ),
                          const SizedBox(height: 14),
                          _buildWorkoutHistorySection(data),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(_CommunityMemberProfileData data) {
    final bmiColor = _bmiColor(data.bmi);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1D1D), Color(0xFF111111)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 620;
          const avatarSize = 84.0;

          final bmiBadge = Container(
            width: stacked ? double.infinity : 148,
            margin: EdgeInsets.only(top: stacked ? 18 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: bmiColor.withOpacity(0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Current BMI',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.bmi > 0 ? data.bmi.toStringAsFixed(1) : '--',
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bmiLabel(data.bmi),
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 2),
                    color: Colors.grey[850],
                  ),
                  child: ClipOval(
                    child: data.profileImageUrl != null
                        ? Image.network(
                            data.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 36,
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      icon: Icons.groups_rounded,
                      label: 'Community member',
                    ),
                    if ((data.gender ?? '').isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.badge_outlined,
                        label: data.gender!,
                      ),
                    if (data.age != null)
                      _buildMetaChip(
                        icon: Icons.cake_outlined,
                        label: '${data.age} yrs',
                      ),
                  ],
                ),
                bmiBadge,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 2),
                        color: Colors.grey[850],
                      ),
                      child: ClipOval(
                        child: data.profileImageUrl != null
                            ? Image.network(
                                data.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 36,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMetaChip(
                                icon: Icons.groups_rounded,
                                label: 'Community member',
                              ),
                              if ((data.gender ?? '').isNotEmpty)
                                _buildMetaChip(
                                  icon: Icons.badge_outlined,
                                  label: data.gender!,
                                ),
                              if (data.age != null)
                                _buildMetaChip(
                                  icon: Icons.cake_outlined,
                                  label: '${data.age} yrs',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              bmiBadge,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStatsGrid(_CommunityMemberProfileData data) {
    final items = [
      _StatCardData(
        label: 'Weight',
        value: _formatMetric(data.weight, 'kg'),
        icon: Icons.monitor_weight,
        accent: const Color(0xFF63D471),
      ),
      _StatCardData(
        label: 'Height',
        value: _formatMetric(data.height, 'cm'),
        icon: Icons.height,
        accent: const Color(0xFF4FC3F7),
      ),
      _StatCardData(
        label: 'BMI',
        value: data.bmi > 0 ? data.bmi.toStringAsFixed(1) : '--',
        sublabel: _bmiLabel(data.bmi),
        icon: Icons.monitor_heart_outlined,
        accent: _bmiColor(data.bmi),
      ),
      _StatCardData(
        label: 'Waist',
        value: _formatMetric(data.waistMeasurement, 'cm'),
        icon: Icons.straighten,
        accent: const Color(0xFF3EA6FF),
      ),
      _StatCardData(
        label: 'Sleep',
        value: _formatMetric(data.sleepHours, 'hrs'),
        icon: Icons.nights_stay_rounded,
        accent: const Color(0xFFC43BFF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 860 ? 5 : width > 680 ? 3 : width > 380 ? 2 : 1;
        const spacing = 12.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;
        final hasSingleLastItem = items.length % columns == 1;
        final compact = width < 420;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(items.length, (index) {
            final isLastSingleCard =
                hasSingleLastItem && index == items.length - 1;
            return SizedBox(
              width: isLastSingleCard ? width : cardWidth,
              child: _buildStatCard(
                items[index],
                compact: compact,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatCard(
    _StatCardData item, {
    required bool compact,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 132 : 144),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 9 : 10),
            decoration: BoxDecoration(
              color: item.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: item.accent,
              size: compact ? 18 : 20,
            ),
          ),
          SizedBox(height: compact ? 18 : 24),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: compact ? 14 : 16,
            child: (item.sublabel ?? '').isNotEmpty
                ? Text(
                    item.sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.accent,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummaryGrid(_CommunityMemberProfileData data) {
    final items = [
      _SummaryCardData(
        label: 'Completed',
        value: '${data.workoutRuns.length}',
        icon: Icons.task_alt,
        accent: const Color(0xFF63D471),
      ),
      _SummaryCardData(
        label: 'Clean Runs',
        value: '${data.cleanWorkouts}',
        icon: Icons.verified_rounded,
        accent: const Color(0xFF3EA6FF),
      ),
      _SummaryCardData(
        label: 'Total Minutes',
        value: '${data.totalMinutes}',
        icon: Icons.timer_outlined,
        accent: const Color(0xFFFFB020),
      ),
      _SummaryCardData(
        label: 'Total Calories',
        value: '${data.totalCalories}',
        icon: Icons.local_fire_department,
        accent: const Color(0xFFFF6B57),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 780 ? 4 : width > 520 ? 2 : 1;
        const spacing = 12.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPersonalBestSection(_CommunityMemberProfileData data) {
    if (data.bestRecords.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.fitness_center,
        title: 'No personal records yet',
        subtitle:
            'This member has not saved any exercise records that can be shown here yet.',
      );
    }

    final visibleRecords = data.bestRecords.take(8).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (int index = 0; index < visibleRecords.length; index++) ...[
            _buildPersonalBestRow(
              rank: index + 1,
              record: visibleRecords[index],
            ),
            if (index != visibleRecords.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white10, height: 1),
              ),
          ],
          if (data.bestRecords.length > visibleRecords.length) ...[
            const SizedBox(height: 14),
            Text(
              'Showing ${visibleRecords.length} of ${data.bestRecords.length} personal bests',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalBestRow({
    required int rank,
    required _PersonalBestRecord record,
  }) {
    final dateLabel = record.timestamp != null
        ? DateFormat('MMM d, yyyy').format(record.timestamp!)
        : 'No date';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final weightLabel =
            '${record.weightUsed.toStringAsFixed(record.weightUsed == record.weightUsed.roundToDouble() ? 0 : 1)} kg';
        final meta = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniChip(weightLabel),
            _buildMiniChip('${record.repsPerformed} reps'),
            _buildMiniChip('${record.setsPerformed} sets'),
            _buildMiniChip(dateLabel),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      record.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              meta,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRankBadge(rank),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  meta,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutHistorySection(_CommunityMemberProfileData data) {
    if (data.workoutRuns.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.history,
        title: 'No completed workouts yet',
        subtitle:
            'Completed workout history will appear here once this member finishes workouts.',
      );
    }

    return Column(
      children: data.workoutRuns
          .map((run) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWorkoutRunCard(run),
              ))
          .toList(),
    );
  }

  Widget _buildWorkoutRunCard(_CommunityWorkoutRun run) {
    final statusColor = run.isCheated
        ? const Color(0xFFFFB020)
        : const Color(0xFF63D471);
    final statusLabel = run.isCheated ? 'Flagged' : 'Clean';
    final dateLabel = DateFormat('MMM d, yyyy • h:mm a').format(run.completedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (run.bodyFocus.isNotEmpty) _buildMiniChip(run.bodyFocus),
              if (run.level.isNotEmpty) _buildMiniChip(run.level),
              if (run.effectiveMinutes > 0) _buildMiniChip('${run.effectiveMinutes} mins'),
              if (run.effectiveCalories > 0) _buildMiniChip('${run.effectiveCalories} kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.26)),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white38, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityMemberProfileData {
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final String? gender;
  final int? age;
  final double weight;
  final double height;
  final double bmi;
  final double waistMeasurement;
  final double sleepHours;
  final List<_CommunityWorkoutRun> workoutRuns;
  final List<_PersonalBestRecord> bestRecords;
  final int totalCalories;
  final int totalMinutes;
  final int cleanWorkouts;

  const _CommunityMemberProfileData({
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.waistMeasurement,
    required this.sleepHours,
    required this.workoutRuns,
    required this.bestRecords,
    required this.totalCalories,
    required this.totalMinutes,
    required this.cleanWorkouts,
  });
}

class _CommunityWorkoutRun {
  final String id;
  final String title;
  final String level;
  final String bodyFocus;
  final DateTime completedAt;
  final int recordedMinutes;
  final int recordedCalories;
  final int actualDurationSeconds;
  final int expectedDurationSeconds;
  final bool isCheated;

  const _CommunityWorkoutRun({
    required this.id,
    required this.title,
    required this.level,
    required this.bodyFocus,
    required this.completedAt,
    required this.recordedMinutes,
    required this.recordedCalories,
    required this.actualDurationSeconds,
    required this.expectedDurationSeconds,
    required this.isCheated,
  });

  int get effectiveMinutes {
    if (recordedMinutes > 0) return recordedMinutes;
    if (actualDurationSeconds > 0) return (actualDurationSeconds / 60).ceil();
    if (expectedDurationSeconds > 0) return (expectedDurationSeconds / 60).ceil();
    return 0;
  }

  int get effectiveCalories {
    if (recordedCalories > 0) return recordedCalories;
    final minutes = effectiveMinutes;
    if (minutes <= 0) return 0;
    return minutes * 5;
  }

  factory _CommunityWorkoutRun.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final completedAtValue = data['completedAt'];
    DateTime completedAt;
    if (completedAtValue is Timestamp) {
      completedAt = completedAtValue.toDate();
    } else if (completedAtValue is DateTime) {
      completedAt = completedAtValue;
    } else if (completedAtValue is String) {
      completedAt = DateTime.tryParse(completedAtValue) ?? DateTime.now();
    } else {
      completedAt = DateTime.now();
    }

    return _CommunityWorkoutRun(
      id: id,
      title: (data['title'] ?? 'Workout').toString(),
      level: (data['level'] ?? '').toString(),
      bodyFocus: (data['bodyFocus'] ?? '').toString(),
      completedAt: completedAt,
      recordedMinutes: (data['recordedMinutes'] as num?)?.toInt() ?? 0,
      recordedCalories: (data['recordedCalories'] as num?)?.toInt() ?? 0,
      actualDurationSeconds: (data['actualDuration'] as num?)?.toInt() ?? 0,
      expectedDurationSeconds: (data['expectedDuration'] as num?)?.toInt() ?? 0,
      isCheated: data['isCheated'] == true,
    );
  }
}

class _PersonalBestRecord {
  final String exerciseName;
  final double weightUsed;
  final int repsPerformed;
  final int setsPerformed;
  final DateTime? timestamp;

  const _PersonalBestRecord({
    required this.exerciseName,
    required this.weightUsed,
    required this.repsPerformed,
    required this.setsPerformed,
    required this.timestamp,
  });

  factory _PersonalBestRecord.fromMap(Map<String, dynamic> data) {
    final dynamic timestampValue = data['timestamp'];
    DateTime? timestamp;
    if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else if (timestampValue is DateTime) {
      timestamp = timestampValue;
    } else if (timestampValue is String) {
      timestamp = DateTime.tryParse(timestampValue);
    }

    return _PersonalBestRecord(
      exerciseName: (data['exerciseName'] ?? 'Exercise').toString(),
      weightUsed: (data['weightUsed'] as num?)?.toDouble() ?? 0.0,
      repsPerformed: (data['repsPerformed'] as num?)?.toInt() ?? 0,
      setsPerformed: (data['setsPerformed'] as num?)?.toInt() ?? 0,
      timestamp: timestamp,
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final String? sublabel;
  final IconData icon;
  final Color accent;

  const _StatCardData({
    required this.label,
    required this.value,
    this.sublabel,
    required this.icon,
    required this.accent,
  });
}

class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
}
