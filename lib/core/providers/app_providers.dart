import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/curriculum_models.dart';
import '../models/learner_state.dart';
import '../repositories/curriculum_repository.dart';
import '../repositories/key_value_store.dart';
import '../repositories/progress_repository.dart';

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SharedPreferencesAsyncStore(),
);

final curriculumRepositoryProvider = Provider<CurriculumRepository>(
  (ref) => AssetCurriculumRepository(),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => LocalProgressRepository(store: ref.watch(keyValueStoreProvider)),
);

final curriculumProvider = FutureProvider<CurriculumBundle>(
  (ref) async => ref.watch(curriculumRepositoryProvider).loadCurriculum(),
  retry: (_, _) => null,
);

final learnerStateProvider =
    AsyncNotifierProvider<LearnerStateNotifier, LearnerState>(
      LearnerStateNotifier.new,
      retry: (_, _) => null,
    );

class ModuleProgressMetrics {
  const ModuleProgressMetrics({
    required this.moduleId,
    required this.totalCheckpoints,
    required this.completedCount,
    required this.inProgressCount,
    required this.readCount,
    required this.quizPassedCount,
    required this.practiceDoneCount,
  });

  final String moduleId;
  final int totalCheckpoints;
  final int completedCount;
  final int inProgressCount;
  final int readCount;
  final int quizPassedCount;
  final int practiceDoneCount;

  double get completionRatio =>
      totalCheckpoints == 0 ? 0 : completedCount / totalCheckpoints;
  int get completionPercent => (completionRatio * 100).round();
}

class ProgressSummary {
  const ProgressSummary({
    required this.totalCheckpoints,
    required this.completedCount,
    required this.inProgressCount,
    required this.lessonsReadCount,
    required this.quizzesPassedCount,
    required this.practicesCompletedCount,
    required this.bookmarkedCount,
    required this.notesCount,
    required this.revisitCount,
    required this.completedMinutes,
    required this.totalMinutes,
    required this.moduleMetrics,
    required this.currentModule,
    required this.recommendedNextCheckpoint,
    required this.completedProjectMilestones,
    required this.totalProjectMilestones,
  });

  final int totalCheckpoints;
  final int completedCount;
  final int inProgressCount;
  final int lessonsReadCount;
  final int quizzesPassedCount;
  final int practicesCompletedCount;
  final int bookmarkedCount;
  final int notesCount;
  final int revisitCount;
  final int completedMinutes;
  final int totalMinutes;
  final Map<String, ModuleProgressMetrics> moduleMetrics;
  final LearningModule? currentModule;
  final Checkpoint? recommendedNextCheckpoint;
  final int completedProjectMilestones;
  final int totalProjectMilestones;

  double get completionRatio =>
      totalCheckpoints == 0 ? 0 : completedCount / totalCheckpoints;
  int get completionPercent => (completionRatio * 100).round();

  double get projectCompletionRatio => totalProjectMilestones == 0
      ? 0
      : completedProjectMilestones / totalProjectMilestones;

  static ProgressSummary compute({
    required CurriculumBundle bundle,
    required LearnerState state,
  }) {
    var completed = 0;
    var inProgress = 0;
    var read = 0;
    var quizPassed = 0;
    var practiceDone = 0;
    var bookmarked = 0;
    var notes = 0;
    var revisit = 0;
    var completedMinutes = 0;

    final moduleMetrics = <String, ModuleProgressMetrics>{};

    for (final m in bundle.modules) {
      final cps = bundle.checkpointsByModuleId[m.id] ?? const <Checkpoint>[];
      var mCompleted = 0;
      var mInProgress = 0;
      var mRead = 0;
      var mQuiz = 0;
      var mPractice = 0;

      for (final cp in cps) {
        final p = state.checkpointProgress[cp.id];
        if (p != null) {
          if (p.status == CheckpointStatus.completed) {
            completed++;
            mCompleted++;
            completedMinutes += cp.estimatedMinutes;
          } else if (p.status == CheckpointStatus.inProgress) {
            inProgress++;
            mInProgress++;
          }
          if (p.lessonRead) {
            read++;
            mRead++;
          }
          if (p.quizPassed) {
            quizPassed++;
            mQuiz++;
          }
          if (p.practiceCompleted) {
            practiceDone++;
            mPractice++;
          }
          if (p.isBookmarked) bookmarked++;
          if (p.note.trim().isNotEmpty) notes++;
          if (p.needsRevisit) revisit++;
        }
      }

      moduleMetrics[m.id] = ModuleProgressMetrics(
        moduleId: m.id,
        totalCheckpoints: cps.length,
        completedCount: mCompleted,
        inProgressCount: mInProgress,
        readCount: mRead,
        quizPassedCount: mQuiz,
        practiceDoneCount: mPractice,
      );
    }

    var completedMilestones = 0;
    var totalMilestones = 0;
    for (final proj in bundle.projects) {
      totalMilestones += proj.milestones.length;
      final pp = state.projectProgress[proj.id];
      if (pp != null) {
        final validIds = proj.milestones.map((m) => m.id).toSet();
        completedMilestones += pp.completedMilestoneIds
            .where(validIds.contains)
            .length;
      }
    }

    final recommendedNext = _findRecommendedNext(bundle, state);
    final currentModule = recommendedNext != null
        ? bundle.moduleById[recommendedNext.moduleId]
        : (bundle.modules.isNotEmpty ? bundle.modules.last : null);

    return ProgressSummary(
      totalCheckpoints: bundle.checkpoints.length,
      completedCount: completed,
      inProgressCount: inProgress,
      lessonsReadCount: read,
      quizzesPassedCount: quizPassed,
      practicesCompletedCount: practiceDone,
      bookmarkedCount: bookmarked,
      notesCount: notes,
      revisitCount: revisit,
      completedMinutes: completedMinutes,
      totalMinutes: bundle.totalEstimatedMinutes,
      moduleMetrics: Map.unmodifiable(moduleMetrics),
      currentModule: currentModule,
      recommendedNextCheckpoint: recommendedNext,
      completedProjectMilestones: completedMilestones,
      totalProjectMilestones: totalMilestones,
    );
  }

  static Checkpoint? _findRecommendedNext(
    CurriculumBundle bundle,
    LearnerState state,
  ) {
    // 1. If the learner was actively working on a checkpoint not yet completed, resume it.
    final lastId = state.lastVisitedCheckpointId;
    if (lastId != null) {
      final lastCp = bundle.checkpointById[lastId];
      final lastStatus = state.checkpointProgress[lastId]?.status;
      if (lastCp != null && lastStatus != CheckpointStatus.completed) {
        return lastCp;
      }
    }

    // 2. Prioritize weak modules from diagnostic or suggested start module.
    final startModuleId = state.profile.suggestedStartModuleId;
    final startCps = bundle.checkpointsByModuleId[startModuleId] ?? const [];
    for (final cp in startCps) {
      if (state.checkpointProgress[cp.id]?.status !=
          CheckpointStatus.completed) {
        return cp;
      }
    }

    // 3. Otherwise first incomplete checkpoint in curriculum order.
    for (final m in bundle.modules) {
      final cps = bundle.checkpointsByModuleId[m.id] ?? const [];
      for (final cp in cps) {
        if (state.checkpointProgress[cp.id]?.status !=
            CheckpointStatus.completed) {
          return cp;
        }
      }
    }
    return null;
  }
}

class LearnerStateNotifier extends AsyncNotifier<LearnerState> {
  ProgressRepository get _repo => ref.read(progressRepositoryProvider);

  @override
  Future<LearnerState> build() async {
    return _repo.load();
  }

  Future<void> _commit(
    LearnerState Function(LearnerState current) transform, {
    ActivityLogEntry? activity,
  }) async {
    final current = state.value ?? await future;
    var next = transform(current);
    if (activity != null) {
      final updatedLog = [activity, ...next.recentActivity];
      next = next.copyWith(
        recentActivity: updatedLog.take(30).toList(growable: false),
      );
    }
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> completeOnboarding({
    required EntryPath entryPath,
    required String experienceSummary,
    required int weeklyStudyHours,
    required List<int> studyDays,
    required List<String> learningGoals,
    required String suggestedStartModuleId,
    DiagnosticResult? diagnosticResult,
  }) async {
    // IMPORTANT: Never auto-mark skipped modules/checkpoints as mastered.
    await _commit(
      (current) => current.copyWith(
        profile: current.profile.copyWith(
          onboardingCompleted: true,
          entryPath: entryPath,
          experienceSummary: experienceSummary,
          weeklyStudyHours: weeklyStudyHours.clamp(1, 60),
          studyDays: studyDays.isEmpty ? const [1, 3, 5] : studyDays,
          learningGoals: learningGoals,
          suggestedStartModuleId: suggestedStartModuleId,
          diagnosticResult: diagnosticResult,
          clearDiagnosticResult: diagnosticResult == null,
        ),
      ),
      activity: diagnosticResult == null
          ? null
          : ActivityLogEntry(
              id: 'diag_${DateTime.now().microsecondsSinceEpoch}',
              timestamp: DateTime.now(),
              kind: 'diagnostic_completed',
              title:
                  'Completed n8n diagnostic (${diagnosticResult.correctCount}/${diagnosticResult.totalCount}) — suggested Module ${suggestedStartModuleId.replaceFirst('m', '')}',
              route: '/roadmap?module=$suggestedStartModuleId',
            ),
    );
  }

  Future<void> markLessonVisited(String checkpointId) async {
    final current = state.value ?? await future;
    if (current.lastVisitedCheckpointId == checkpointId) return;
    await _commit((s) => s.copyWith(lastVisitedCheckpointId: checkpointId));
  }

  Future<void> toggleLessonRead(
    String checkpointId, {
    String? checkpointTitle,
  }) async {
    var becameRead = false;
    await _commit((s) {
      final existing =
          s.checkpointProgress[checkpointId] ??
          CheckpointProgress(checkpointId: checkpointId);
      final nextRead = !existing.lessonRead;
      becameRead = nextRead;
      final nextStatus =
          existing.status == CheckpointStatus.notStarted && nextRead
          ? CheckpointStatus.inProgress
          : existing.status;
      final updated = existing.copyWith(
        lessonRead: nextRead,
        status: nextStatus,
        lastUpdatedAt: DateTime.now(),
      );
      return s.copyWith(
        lastVisitedCheckpointId: checkpointId,
        checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
      );
    });
    if (becameRead && checkpointTitle != null) {
      await _appendActivity(
        kind: 'lesson_read',
        title: 'Read lesson: $checkpointTitle',
        route: '/lesson/$checkpointId',
      );
    }
  }

  Future<void> togglePracticeCompleted(
    String checkpointId, {
    String? checkpointTitle,
  }) async {
    var becameDone = false;
    await _commit((s) {
      final existing =
          s.checkpointProgress[checkpointId] ??
          CheckpointProgress(checkpointId: checkpointId);
      final nextDone = !existing.practiceCompleted;
      becameDone = nextDone;
      final nextStatus =
          existing.status == CheckpointStatus.notStarted && nextDone
          ? CheckpointStatus.inProgress
          : existing.status;
      final updated = existing.copyWith(
        practiceCompleted: nextDone,
        status: nextStatus,
        lastUpdatedAt: DateTime.now(),
      );
      return s.copyWith(
        lastVisitedCheckpointId: checkpointId,
        checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
      );
    });
    if (becameDone && checkpointTitle != null) {
      await _appendActivity(
        kind: 'practice_done',
        title: 'Completed practice task: $checkpointTitle',
        route: '/lesson/$checkpointId',
      );
    }
  }

  Future<void> setCheckpointStatus(
    String checkpointId,
    CheckpointStatus status, {
    String? checkpointTitle,
  }) async {
    await _commit(
      (s) {
        final existing =
            s.checkpointProgress[checkpointId] ??
            CheckpointProgress(checkpointId: checkpointId);
        final now = DateTime.now();
        final updated = existing.copyWith(
          status: status,
          completedAt: status == CheckpointStatus.completed ? now : null,
          clearCompletedAt: status != CheckpointStatus.completed,
          lastUpdatedAt: now,
        );
        return s.copyWith(
          lastVisitedCheckpointId: checkpointId,
          checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
        );
      },
      activity: status == CheckpointStatus.completed
          ? ActivityLogEntry(
              id: 'cp_${DateTime.now().microsecondsSinceEpoch}',
              timestamp: DateTime.now(),
              kind: 'checkpoint_completed',
              title: 'Confirmed completion: ${checkpointTitle ?? checkpointId}',
              route: '/lesson/$checkpointId',
            )
          : null,
    );
  }

  Future<void> recordQuizAttempt(
    QuizAttemptRecord attempt, {
    String? checkpointTitle,
  }) async {
    await _commit(
      (s) {
        final existing =
            s.checkpointProgress[attempt.targetId] ??
            CheckpointProgress(checkpointId: attempt.targetId);
        final nextQuizPassed = existing.quizPassed || attempt.passed;
        // Quiz completion never auto-marks the checkpoint as completed.
        final nextStatus = existing.status == CheckpointStatus.notStarted
            ? CheckpointStatus.inProgress
            : existing.status;
        final updated = existing.copyWith(
          quizPassed: nextQuizPassed,
          status: nextStatus,
          lastUpdatedAt: DateTime.now(),
          quizAttempts: [...existing.quizAttempts, attempt],
        );
        return s.copyWith(
          lastVisitedCheckpointId: attempt.targetId,
          checkpointProgress: {
            ...s.checkpointProgress,
            attempt.targetId: updated,
          },
        );
      },
      activity: ActivityLogEntry(
        id: 'quiz_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        kind: 'quiz_attempt',
        title:
            'Knowledge check (${attempt.correctCount}/${attempt.totalCount}): ${checkpointTitle ?? attempt.targetId}',
        route: '/lesson/${attempt.targetId}',
      ),
    );
  }

  Future<void> toggleBookmark(String checkpointId) async {
    await _commit((s) {
      final existing =
          s.checkpointProgress[checkpointId] ??
          CheckpointProgress(checkpointId: checkpointId);
      final updated = existing.copyWith(
        isBookmarked: !existing.isBookmarked,
        lastUpdatedAt: DateTime.now(),
      );
      return s.copyWith(
        checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
      );
    });
  }

  Future<void> toggleNeedsRevisit(String checkpointId) async {
    await _commit((s) {
      final existing =
          s.checkpointProgress[checkpointId] ??
          CheckpointProgress(checkpointId: checkpointId);
      final updated = existing.copyWith(
        needsRevisit: !existing.needsRevisit,
        lastUpdatedAt: DateTime.now(),
      );
      return s.copyWith(
        checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
      );
    });
  }

  Future<void> updateNote(
    String checkpointId,
    String note, {
    String? checkpointTitle,
  }) async {
    await _commit((s) {
      final existing =
          s.checkpointProgress[checkpointId] ??
          CheckpointProgress(checkpointId: checkpointId);
      final updated = existing.copyWith(
        note: note,
        lastUpdatedAt: DateTime.now(),
      );
      return s.copyWith(
        checkpointProgress: {...s.checkpointProgress, checkpointId: updated},
      );
    });
    if (note.trim().isNotEmpty && checkpointTitle != null) {
      await _appendActivity(
        kind: 'note_updated',
        title: 'Updated note: $checkpointTitle',
        route: '/lesson/$checkpointId',
      );
    }
  }

  Future<void> toggleModuleChecklistItem(String moduleId, String item) async {
    await _commit((s) {
      final list = [...(s.moduleChecklistDone[moduleId] ?? const <String>[])];
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
      return s.copyWith(
        moduleChecklistDone: {
          ...s.moduleChecklistDone,
          moduleId: List.unmodifiable(list),
        },
      );
    });
  }

  Future<void> toggleProjectMilestone(
    String projectId,
    String milestoneId, {
    String? projectTitle,
  }) async {
    var added = false;
    await _commit((s) {
      final existing =
          s.projectProgress[projectId] ?? ProjectProgress(projectId: projectId);
      final list = [...existing.completedMilestoneIds];
      if (list.contains(milestoneId)) {
        list.remove(milestoneId);
      } else {
        list.add(milestoneId);
        added = true;
      }
      return s.copyWith(
        projectProgress: {
          ...s.projectProgress,
          projectId: existing.copyWith(
            completedMilestoneIds: List.unmodifiable(list),
            lastUpdatedAt: DateTime.now(),
          ),
        },
      );
    });
    if (added && projectTitle != null) {
      await _appendActivity(
        kind: 'project_milestone',
        title: 'Milestone completed in $projectTitle',
        route: '/projects/$projectId',
      );
    }
  }

  Future<void> toggleProjectSecurityCheck(
    String projectId,
    String checkItem,
  ) async {
    await _commit((s) {
      final existing =
          s.projectProgress[projectId] ?? ProjectProgress(projectId: projectId);
      final list = [...existing.completedSecurityChecks];
      if (list.contains(checkItem)) {
        list.remove(checkItem);
      } else {
        list.add(checkItem);
      }
      return s.copyWith(
        projectProgress: {
          ...s.projectProgress,
          projectId: existing.copyWith(
            completedSecurityChecks: List.unmodifiable(list),
            lastUpdatedAt: DateTime.now(),
          ),
        },
      );
    });
  }

  Future<void> updateProjectDetails(
    String projectId, {
    String? githubRepoUrl,
    Map<String, String>? recordedMetrics,
    String? reflectionNotes,
  }) async {
    await _commit((s) {
      final existing =
          s.projectProgress[projectId] ?? ProjectProgress(projectId: projectId);
      return s.copyWith(
        projectProgress: {
          ...s.projectProgress,
          projectId: existing.copyWith(
            githubRepoUrl: githubRepoUrl ?? existing.githubRepoUrl,
            recordedMetrics: recordedMetrics ?? existing.recordedMetrics,
            reflectionNotes: reflectionNotes ?? existing.reflectionNotes,
            lastUpdatedAt: DateTime.now(),
          ),
        },
      );
    });
  }

  Future<void> updateStudySchedule({
    required int weeklyHours,
    required List<int> studyDays,
  }) async {
    await _commit(
      (s) => s.copyWith(
        profile: s.profile.copyWith(
          weeklyStudyHours: weeklyHours.clamp(1, 60),
          studyDays: studyDays.isEmpty ? const [1, 3, 5] : studyDays,
        ),
      ),
    );
  }

  Future<void> setThemeMode(AppThemeSetting mode) async {
    await _commit((s) => s.copyWith(themeMode: mode));
  }

  Future<String> exportProgressJson() async {
    final current = state.value ?? await future;
    return _repo.exportJson(current);
  }

  Future<LearnerState> importProgressJson(
    String rawJson, {
    CurriculumBundle? curriculum,
  }) async {
    final imported = _repo.parseAndValidateImport(
      rawJson,
      curriculum: curriculum,
    );
    state = AsyncData(imported);
    await _repo.save(imported);
    return imported;
  }

  Future<void> resetProgress() async {
    const fresh = LearnerState();
    state = const AsyncData(fresh);
    await _repo.reset();
  }

  Future<void> _appendActivity({
    required String kind,
    required String title,
    String? route,
  }) async {
    await _commit(
      (s) => s,
      activity: ActivityLogEntry(
        id: 'act_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        kind: kind,
        title: title,
        route: route,
      ),
    );
  }
}
