import '../models/workout_model.dart';

const String weightLossGoal = 'weight_loss';
const String cardioEnduranceGoal = 'cardio_endurance';
const String strengthPowerGoal = 'strength_power';
const String muscularEnduranceGoal = 'muscular_endurance';
const String generalFitnessGoal = 'general_fitness';

const List<String> supportedGoalTypes = [
  weightLossGoal,
  cardioEnduranceGoal,
  strengthPowerGoal,
  muscularEnduranceGoal,
  generalFitnessGoal,
];

const Map<String, String> goalLabels = {
  weightLossGoal: 'Weight Loss',
  cardioEnduranceGoal: 'Cardio Endurance',
  strengthPowerGoal: 'Strength & Power',
  muscularEnduranceGoal: 'Muscular Endurance',
  generalFitnessGoal: 'General Fitness',
};

const Map<String, String> _journeyGoalById = {
  'weight_loss': weightLossGoal,
  'cardio': cardioEnduranceGoal,
  'strength_power': strengthPowerGoal,
  'muscular_endurance': muscularEnduranceGoal,
  'health_wellness': generalFitnessGoal,
};

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String? _firstAvailableText(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString();
    if (_hasText(text)) {
      return text!.trim();
    }
  }
  return null;
}

String goalLabel(String goalType) =>
    goalLabels[goalType] ?? 'General Fitness';

String normalizeGoalType(String? value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return generalFitnessGoal;
  }

  if (supportedGoalTypes.contains(normalized)) {
    return normalized;
  }

  switch (normalized) {
    case 'weight loss':
    case 'fat loss':
      return weightLossGoal;
    case 'cardio':
    case 'cardio endurance':
    case 'endurance':
    case 'stamina':
      return cardioEnduranceGoal;
    case 'strength':
    case 'strength and power':
    case 'strength & power':
    case 'muscle gain':
      return strengthPowerGoal;
    case 'muscular endurance':
      return muscularEnduranceGoal;
    case 'health & wellness':
    case 'health and wellness':
    case 'general fitness':
    case 'wellness':
      return generalFitnessGoal;
    default:
      return generalFitnessGoal;
  }
}

String goalForJourneyId(String? journeyId) {
  if (!_hasText(journeyId)) {
    return generalFitnessGoal;
  }

  return _journeyGoalById[journeyId!.trim()] ?? generalFitnessGoal;
}

List<String> inferGoalTagsForWorkout(Workout workout) {
  final tags = <String>{};
  final bodyFocus = workout.bodyFocus.toLowerCase().trim();

  if (workout.goalTags.isNotEmpty) {
    tags.addAll(workout.goalTags.map(normalizeGoalType));
  }

  if (_hasText(workout.journeyId)) {
    tags.add(goalForJourneyId(workout.journeyId));
  }

  if (bodyFocus.contains('weight loss')) {
    tags.add(weightLossGoal);
    tags.add(cardioEnduranceGoal);
  }
  if (bodyFocus.contains('cardio')) {
    tags.add(cardioEnduranceGoal);
    tags.add(weightLossGoal);
  }
  if (bodyFocus.contains('strength')) {
    tags.add(strengthPowerGoal);
  }
  if (bodyFocus.contains('endurance')) {
    tags.add(muscularEnduranceGoal);
    tags.add(cardioEnduranceGoal);
  }
  if (bodyFocus.contains('wellness') || bodyFocus.contains('recovery')) {
    tags.add(generalFitnessGoal);
  }

  if (tags.isEmpty) {
    tags.add(generalFitnessGoal);
  }

  return tags.toList(growable: false);
}

String inferPrimaryGoalForWorkout(Workout workout) {
  if (_hasText(workout.primaryGoal)) {
    return normalizeGoalType(workout.primaryGoal);
  }

  final tags = inferGoalTagsForWorkout(workout);
  return tags.isEmpty ? generalFitnessGoal : tags.first;
}

String? resolvePreferredGoalFromUserData(Map<String, dynamic>? userData) {
  if (userData == null) {
    return null;
  }

  final profile = userData['profile'];
  final nestedGoal = profile is Map<String, dynamic>
      ? profile['fitnessGoal']
      : null;
  final resolvedGoal = _firstAvailableText([
    nestedGoal,
    userData['profile.fitnessGoal'],
    userData['fitnessGoal'],
    userData['selectedGoalType'],
  ]);

  if (_hasText(resolvedGoal)) {
    return normalizeGoalType(resolvedGoal);
  }

  final selectedJourneyId = userData['selectedJourneyId']?.toString();
  if (_hasText(selectedJourneyId)) {
    return goalForJourneyId(selectedJourneyId);
  }

  return null;
}
