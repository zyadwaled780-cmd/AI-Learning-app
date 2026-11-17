import '../models/curriculum_models.dart';
import '../models/learner_state.dart';

class PlannedSession {
  const PlannedSession({
    required this.weekNumber,
    required this.weekdayNumber,
    required this.allocatedMinutes,
    required this.checkpoints,
  });

  final int weekNumber;
  final int weekdayNumber;
  final int allocatedMinutes;
  final List<Checkpoint> checkpoints;
}

class StudyPlanResult {
  const StudyPlanResult({
    required this.remainingCheckpoints,
    required this.totalRemainingMinutes,
    required this.weeklyMinutesBudget,
    required this.estimatedWeeks,
    required this.sessions,
  });

  final int remainingCheckpoints;
  final int totalRemainingMinutes;
  final int weeklyMinutesBudget;
  final int estimatedWeeks;
  final List<PlannedSession> sessions;
}

abstract final class StudyPlannerEngine {
  static const List<String> weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String weekdayLabel(int weekday) {
    if (weekday < 1 || weekday > 7) return 'Day';
    return weekdayLabels[weekday - 1];
  }

  static StudyPlanResult generatePlan({
    required CurriculumBundle bundle,
    required LearnerState learnerState,
    required int weeklyHours,
    required List<int> studyDays,
    bool prioritizeSuggestedStart = true,
    int maxWeeksToPreview = 8,
  }) {
    final safeHours = weeklyHours.clamp(1, 60);
    final activeDays = (studyDays.isEmpty ? [1, 3, 5] : studyDays.toList())
      ..sort();
    final uniqueDays =
        activeDays.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();
    if (uniqueDays.isEmpty) {
      uniqueDays.addAll([1, 3, 5]);
    }

    final remaining = <Checkpoint>[];
    final orderedModules = [...bundle.modules]
      ..sort((a, b) => a.number.compareTo(b.number));

    // If learner took diagnostic or has suggested start module, place suggested
    // and weak modules first in recommendation order while keeping all incomplete work.
    final suggestedStartId = learnerState.profile.suggestedStartModuleId;
    final weakIds =
        learnerState.profile.diagnosticResult?.weakModuleIds.toSet() ??
        const <String>{};

    final prioritizedModules = <LearningModule>[];
    if (prioritizeSuggestedStart) {
      for (final m in orderedModules) {
        if (weakIds.contains(m.id) || m.id == suggestedStartId) {
          prioritizedModules.add(m);
        }
      }
      for (final m in orderedModules) {
        if (!prioritizedModules.any((pm) => pm.id == m.id)) {
          prioritizedModules.add(m);
        }
      }
    } else {
      prioritizedModules.addAll(orderedModules);
    }

    for (final m in prioritizedModules) {
      final cps = bundle.checkpointsByModuleId[m.id] ?? const [];
      for (final cp in cps) {
        final progress = learnerState.checkpointProgress[cp.id];
        if (progress?.status != CheckpointStatus.completed) {
          remaining.add(cp);
        }
      }
    }

    final totalRemainingMinutes = remaining.fold<int>(
      0,
      (sum, cp) => sum + cp.estimatedMinutes,
    );
    final weeklyMinutes = safeHours * 60;
    final estimatedWeeks = remaining.isEmpty
        ? 0
        : (totalRemainingMinutes / weeklyMinutes).ceil();

    final perSessionBudget = (weeklyMinutes / uniqueDays.length).round().clamp(
      20,
      360,
    );

    final sessions = <PlannedSession>[];
    var cursor = 0;

    for (
      var week = 1;
      week <= maxWeeksToPreview && cursor < remaining.length;
      week++
    ) {
      for (final weekday in uniqueDays) {
        if (cursor >= remaining.length) break;
        final sessionCps = <Checkpoint>[];
        var used = 0;

        while (cursor < remaining.length) {
          final next = remaining[cursor];
          if (sessionCps.isNotEmpty &&
              used + next.estimatedMinutes > perSessionBudget + 10) {
            break;
          }
          sessionCps.add(next);
          used += next.estimatedMinutes;
          cursor++;
          if (used >= perSessionBudget) break;
        }

        if (sessionCps.isNotEmpty) {
          sessions.add(
            PlannedSession(
              weekNumber: week,
              weekdayNumber: weekday,
              allocatedMinutes: used,
              checkpoints: List.unmodifiable(sessionCps),
            ),
          );
        }
      }
    }

    return StudyPlanResult(
      remainingCheckpoints: remaining.length,
      totalRemainingMinutes: totalRemainingMinutes,
      weeklyMinutesBudget: weeklyMinutes,
      estimatedWeeks: estimatedWeeks,
      sessions: List.unmodifiable(sessions),
    );
  }
}
