import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/fitness_journey_workouts.dart';
import '../models/workout_model.dart';
import '../services/journey_progress_service.dart';
import 'workout_detail_screen.dart';

class FitnessJourneyDetailScreen extends StatefulWidget {
  final String journeyId;
  final String title;
  final String durationLabel;
  final String headline;
  final String description;
  final String thumbnailAsset;
  final IconData icon;
  final Color accentColor;
  final Color buttonTextColor;
  final Color gradientStart;
  final Color gradientEnd;

  const FitnessJourneyDetailScreen({
    super.key,
    required this.journeyId,
    required this.title,
    required this.durationLabel,
    required this.headline,
    required this.description,
    required this.thumbnailAsset,
    required this.icon,
    required this.accentColor,
    required this.buttonTextColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  State<FitnessJourneyDetailScreen> createState() =>
      _FitnessJourneyDetailScreenState();
}

class _FitnessJourneyDetailScreenState extends State<FitnessJourneyDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _trackingPageController = PageController();

  bool _isLoadingProgress = true;
  bool _isJourneyStarting = false;
  int _completedWorkoutsCount = 0;
  int _cheatedWorkoutsCount = 0;
  int _cleanWorkoutsCount = 0;
  int _totalWorkoutsCount = 0;
  double _progressRatio = 0.0;
  double _progressPercent = 0.0;
  bool _hasStartedJourney = false;
  bool _isJourneyCompleted = false;
  DateTime? _activeJourneyCycleStartedAt;
  int _trackingPageIndex = 0;
  double _trackingPagePosition = 0.0;

  List<Workout> get _journeyWorkouts => getJourneyWorkouts(widget.journeyId);

  @override
  void initState() {
    super.initState();
    _totalWorkoutsCount = _journeyWorkouts.length;
    _trackingPageController.addListener(_handleTrackingPageScroll);
    _loadJourneyProgress();
  }

  void _handleTrackingPageScroll() {
    final page = _trackingPageController.hasClients
        ? (_trackingPageController.page ?? _trackingPageIndex.toDouble())
        : _trackingPageIndex.toDouble();

    if (!mounted) {
      return;
    }

    setState(() {
      _trackingPagePosition = page;
    });
  }

  Future<void> _loadJourneyProgress({bool markStarted = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingProgress = false;
          _completedWorkoutsCount = 0;
          _progressRatio = 0.0;
        _progressPercent = 0.0;
        _hasStartedJourney = false;
        _activeJourneyCycleStartedAt = null;
        _totalWorkoutsCount = _journeyWorkouts.length;
      });
      return;
      }

      final snapshot = await JourneyProgressService.syncJourneyProgressForUser(
        firestore: _firestore,
        uid: user.uid,
        journeyId: widget.journeyId,
        journeyName: widget.title,
        isSelected: true,
        markStarted: markStarted,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _completedWorkoutsCount = snapshot.completedWorkoutsCount;
        _cheatedWorkoutsCount = snapshot.cheatedWorkoutsCount;
        _cleanWorkoutsCount = snapshot.cleanWorkoutsCount;
        _totalWorkoutsCount = snapshot.totalWorkoutsCount;
        _progressRatio = snapshot.progressRatio;
        _progressPercent = snapshot.progressPercent;
        _hasStartedJourney = snapshot.hasStarted;
        _isJourneyCompleted = snapshot.isCompleted;
        _activeJourneyCycleStartedAt = snapshot.startedAt;
        _isLoadingProgress = false;
        _isJourneyStarting = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProgress = false;
        _isJourneyStarting = false;
      });
    }
  }

  Future<void> _refreshJourneyScreen() async {
    await _loadJourneyProgress();
  }

  Future<void> _startJourney() async {
    if (_isJourneyStarting) {
      return;
    }

    setState(() {
      _isJourneyStarting = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No signed-in user');
      }

      final snapshot = await JourneyProgressService.syncJourneyProgressForUser(
        firestore: _firestore,
        uid: user.uid,
        journeyId: widget.journeyId,
        journeyName: widget.title,
        isSelected: true,
        markStarted: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _completedWorkoutsCount = snapshot.completedWorkoutsCount;
        _cheatedWorkoutsCount = snapshot.cheatedWorkoutsCount;
        _cleanWorkoutsCount = snapshot.cleanWorkoutsCount;
        _totalWorkoutsCount = snapshot.totalWorkoutsCount;
        _progressRatio = snapshot.progressRatio;
        _progressPercent = snapshot.progressPercent;
        _hasStartedJourney = snapshot.hasStarted;
        _isJourneyCompleted = snapshot.isCompleted;
        _activeJourneyCycleStartedAt = snapshot.startedAt;
        _isLoadingProgress = false;
        _isJourneyStarting = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isJourneyStarting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start journey. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.title} journey started.'),
        backgroundColor: widget.accentColor,
      ),
    );
  }

  @override
  void dispose() {
    _trackingPageController.removeListener(_handleTrackingPageScroll);
    _trackingPageController.dispose();
    super.dispose();
  }

  Widget _buildWorkoutMetaChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor,
                width: 1,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWorkoutDetails(
    Workout workout, {
    required bool isCompleted,
    required bool isCheated,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workout.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildWorkoutMetaChip(
              label: widget.title,
              backgroundColor: widget.accentColor.withOpacity(0.18),
              textColor: widget.accentColor,
            ),
            _buildWorkoutMetaChip(
              label: "${workout.exerciseList.length} exercises",
              backgroundColor: Colors.grey[800]!,
              textColor: Colors.white70,
            ),
            _buildWorkoutMetaChip(
              label: workout.level,
              backgroundColor: _getLevelColor(workout.level).withOpacity(0.2),
              textColor: _getLevelColor(workout.level),
            ),
            if (isCompleted)
              _buildWorkoutMetaChip(
                label: isCheated ? 'Cheated' : 'Done',
                backgroundColor: isCheated
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                textColor: isCheated ? Colors.red : Colors.green,
                borderColor: isCheated ? Colors.red : Colors.green,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('completed_workouts')
          .doc(workout.title)
          .get(),
      builder: (context, snapshot) {
        bool isCompleted = false;
        bool isCheated = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final completedAt = data['completedAt'];
          final completedDate = completedAt is Timestamp
              ? completedAt.toDate()
              : null;
          final cycleStartedAt = _activeJourneyCycleStartedAt;
          final isInActiveJourneyCycle = completedDate != null &&
              (cycleStartedAt == null ||
                  !completedDate.isBefore(cycleStartedAt));

          isCompleted = completedDate != null && isInActiveJourneyCycle;
          isCheated = isCompleted && data['isCheated'] == true;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(
                  workout: workout,
                  onWorkoutCompleted: () {
                    _loadJourneyProgress();
                  },
                  onWorkoutReset: () {
                    _loadJourneyProgress();
                  },
                ),
              ),
            ).then((_) => _loadJourneyProgress());
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF191919),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactCard = constraints.maxWidth < 340;
                  final thumbnailWidth =
                      isCompactCard ? constraints.maxWidth : 120.0;
                  final thumbnailHeight = isCompactCard ? 170.0 : 80.0;

                  final thumbnail = Stack(
                    children: [
                      Container(
                        width: thumbnailWidth,
                        height: thumbnailHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            workout.thumbnailAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCheated ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCheated ? Icons.warning : Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  );

                  final details = _buildWorkoutDetails(
                    workout,
                    isCompleted: isCompleted,
                    isCheated: isCheated,
                  );

                  if (isCompactCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbnail,
                        const SizedBox(height: 12),
                        details,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumbnail,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeroHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = kIsWeb && constraints.maxWidth >= 900;

        return Container(
          height: isDesktop ? 300 : 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.thumbnailAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.gradientStart,
                            widget.gradientEnd,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 90,
                          color: widget.accentColor.withOpacity(0.92),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.12),
                        Colors.black.withOpacity(0.34),
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.durationLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.headline.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 38 : 32,
                          fontWeight: FontWeight.w900,
                          height: 0.96,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 420 : constraints.maxWidth,
                        ),
                        child: Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard() {
    final showStartJourneyButton = !_hasStartedJourney || _isJourneyCompleted;
    final isJourneyActionBusy = _isLoadingProgress || _isJourneyStarting;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Journey Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_progressPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _isLoadingProgress ? null : _progressRatio.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_completedWorkoutsCount of $_totalWorkoutsCount workouts completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 13,
            ),
          ),
          if (showStartJourneyButton) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJourneyActionBusy ? null : _startJourney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: widget.accentColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isLoadingProgress
                      ? 'Loading...'
                      : _isJourneyStarting
                          ? 'Starting...'
                      : _isJourneyCompleted
                          ? 'Start Workout Again'
                          : 'Start Journey',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
          if (_hasStartedJourney) ...[
            const SizedBox(height: 10),
            Text(
              _isJourneyCompleted
                  ? 'This journey is complete. Start Workout Again to begin a fresh run.'
                  : 'This journey is active. Complete workouts to move the progress bar toward 100%.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.64),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingStat({
    required String label,
    required String value,
    required Color accentColor,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: compact ? 11 : 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTrackingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final useSingleColumn = availableWidth < 420;
          final compactLayout = availableWidth < 380;
          final statWidth = useSingleColumn
              ? availableWidth
              : (availableWidth - 12) / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: useSingleColumn ? availableWidth : availableWidth - 130,
                    child: Text(
                      'Journey Category Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compactLayout ? 16 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_cheatedWorkoutsCount.toString()} cheated',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: compactLayout ? 13 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'This tracks the workouts inside ${widget.title}. Clean and cheated history can both be shown for the same workout if it was replayed.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: compactLayout ? 11 : 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: statWidth,
                    child: _buildTrackingStat(
                      label: 'Completed workouts',
                      value: _completedWorkoutsCount.toString(),
                      accentColor: widget.accentColor,
                      compact: compactLayout,
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _buildTrackingStat(
                      label: 'Cheated workout history',
                      value: _cheatedWorkoutsCount.toString(),
                      accentColor: Colors.orange,
                      compact: compactLayout,
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _buildTrackingStat(
                      label: 'Clean workout history',
                      value: _cleanWorkoutsCount.toString(),
                      accentColor: Colors.green,
                      compact: compactLayout,
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _buildTrackingStat(
                      label: 'Workouts remaining',
                      value: (_totalWorkoutsCount - _completedWorkoutsCount)
                          .clamp(0, _totalWorkoutsCount)
                          .toString(),
                      accentColor: Colors.white,
                      compact: compactLayout,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                compactLayout
                    ? 'Use the panel buttons to switch views.'
                    : 'Use the panel buttons or drag to switch between journey progress and journey tracking.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.56),
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _trackingPageHeightForWidth(double width, int pageIndex) {
    if (pageIndex == 0) {
      if (width < 330) {
        return 240;
      }
      if (width < 380) {
        return 225;
      }
      if (width < 460) {
        return 210;
      }
      return 192;
    }

    if (width < 330) {
      return 610;
    }
    if (width < 380) {
      return 560;
    }
    if (width < 420) {
      return 500;
    }
    if (width < 460) {
      return 450;
    }
    return 380;
  }

  double _trackingCarouselHeightForWidth(double width) {
    final progressHeight = _trackingPageHeightForWidth(width, 0);
    final trackingHeight = _trackingPageHeightForWidth(width, 1);
    final position = _trackingPagePosition.clamp(0.0, 1.0);

    return ui.lerpDouble(progressHeight, trackingHeight, position) ??
        _trackingPageHeightForWidth(width, _trackingPageIndex);
  }

  Future<void> _animateToTrackingPage(int index) async {
    await _trackingPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _stepTrackingPage(bool forward) async {
    final nextIndex = (_trackingPageIndex + (forward ? 1 : -1)).clamp(0, 1);
    await _animateToTrackingPage(nextIndex);
  }

  Widget _buildTrackingCarousel({required double availableWidth}) {
    final isDesktop = kIsWeb && availableWidth >= 700;
    final showWebControls = kIsWeb;

    return Column(
      children: [
        if (showWebControls) ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTrackingPageButton(
                          label: 'Progress',
                          index: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTrackingPageButton(
                          label: 'Tracking',
                          index: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _trackingPageIndex == 0
                      ? null
                      : () => _stepTrackingPage(false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white70,
                  tooltip: 'Previous panel',
                ),
                IconButton(
                  onPressed: _trackingPageIndex == 1
                      ? null
                      : () => _stepTrackingPage(true),
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  color: Colors.white70,
                  tooltip: 'Next panel',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          height: _trackingCarouselHeightForWidth(availableWidth),
          child: ScrollConfiguration(
            behavior: const _JourneyDesktopScrollBehavior(),
            child: PageView(
              controller: _trackingPageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _trackingPageIndex = index;
                  _trackingPagePosition = index.toDouble();
                });
              },
              children: [
                ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _buildProgressCard(),
                  ),
                ),
                ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _buildJourneyTrackingCard(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(bottom: isDesktop ? 8 : 0),
          child: Text(
            showWebControls
                ? (isDesktop
                    ? 'Use the buttons above, drag with your mouse, or use trackpad swipe to switch panels.'
                    : 'Use the buttons above or swipe to switch panels.')
                : 'Swipe to switch panels.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _trackingPageIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? widget.accentColor
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTrackingPageButton({
    required String label,
    required int index,
  }) {
    final isActive = _trackingPageIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        _animateToTrackingPage(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? widget.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshJourneyScreen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = kIsWeb && constraints.maxWidth >= 1180;
              final contentMaxWidth = kIsWeb
                  ? (constraints.maxWidth >= 1440
                        ? 1320.0
                        : constraints.maxWidth.toDouble())
                  : constraints.maxWidth.toDouble();
              final workoutCardWidth = isDesktop
                  ? (contentMaxWidth - 20) / 2
                  : contentMaxWidth;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  8,
                  isDesktop ? 24 : 16,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDesktop)
                          _buildHeroHeader()
                        else ...[
                          _buildHeroHeader(),
                          const SizedBox(height: 20),
                          _buildTrackingCarousel(
                            availableWidth: constraints.maxWidth,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.title} Workouts',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_journeyWorkouts.length} workouts ready for this journey.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (_journeyWorkouts.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF191919),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Text(
                                          'No journey workouts available for this category yet.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 15,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 0,
                                        children: _journeyWorkouts
                                            .map(
                                              (workout) => SizedBox(
                                                width: workoutCardWidth,
                                                child: _buildWorkoutCard(workout),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 6,
                                child: _buildTrackingCarousel(
                                  availableWidth:
                                      (contentMaxWidth * 6 / 13).clamp(420.0, 620.0),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Text(
                            '${widget.title} Workouts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_journeyWorkouts.length} workouts ready for this journey.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_journeyWorkouts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF191919),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'No journey workouts available for this category yet.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._journeyWorkouts.map(_buildWorkoutCard),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JourneyDesktopScrollBehavior extends MaterialScrollBehavior {
  const _JourneyDesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
