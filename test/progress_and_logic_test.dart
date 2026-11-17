import 'dart:convert';

import 'package:ai_automation_hero/core/models/curriculum_models.dart';
import 'package:ai_automation_hero/core/models/learner_state.dart';
import 'package:ai_automation_hero/core/providers/app_providers.dart';
import 'package:ai_automation_hero/core/repositories/curriculum_repository.dart';
import 'package:ai_automation_hero/core/repositories/key_value_store.dart';
import 'package:ai_automation_hero/core/repositories/progress_repository.dart';
import 'package:ai_automation_hero/core/utils/search_engine.dart';
import 'package:ai_automation_hero/core/utils/study_planner_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCurriculumRepo implements CurriculumRepository {
  _MemoryCurriculumRepo(this.bundle);
  final CurriculumBundle bundle;

  @override
  Future<CurriculumBundle> loadCurriculum() async => bundle;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurriculumBundle bundle;

  setUpAll(() async {
    bundle = await AssetCurriculumRepository().loadCurriculum();
  });

  group('LocalProgressRepository & schema validation', () {
    test('saves, reloads, exports, validates, and resets progress', () async {
      final store = InMemoryKeyValueStore();
      final repo = LocalProgressRepository(store: store);

      final initialLoaded = await repo.load();
      expect(initialLoaded.profile.onboardingCompleted, isFalse);

      final custom = LearnerState(
        themeMode: AppThemeSetting.dark,
        profile: const LearnerProfile(
          onboardingCompleted: true,
          entryPath: EntryPath.n8nUser,
          experienceSummary: 'Knows basic n8n webhooks',
          weeklyStudyHours: 8,
          studyDays: [2, 4, 6],
          learningGoals: ['Ship FastAPI + Pydantic services'],
          suggestedStartModuleId: 'm03',
        ),
        checkpointProgress: {
          'm03_c05': CheckpointProgress(
            checkpointId: 'm03_c05',
            status: CheckpointStatus.inProgress,
            lessonRead: true,
            isBookmarked: true,
            needsRevisit: true,
            note: 'Docker container localhost != host loopback',
          ),
        },
      );

      await repo.save(custom);
      final reloaded = await repo.load();
      expect(reloaded.themeMode, AppThemeSetting.dark);
      expect(reloaded.profile.weeklyStudyHours, 8);
      expect(reloaded.profile.suggestedStartModuleId, 'm03');
      expect(reloaded.checkpointProgress['m03_c05']?.isBookmarked, isTrue);
      expect(
        reloaded.checkpointProgress['m03_c05']?.note,
        'Docker container localhost != host loopback',
      );

      final exported = repo.exportJson(reloaded);
      final reimported = repo.parseAndValidateImport(
        exported,
        curriculum: bundle,
      );
      expect(reimported.schemaVersion, LearnerState.currentSchemaVersion);
      expect(reimported.checkpointProgress['m03_c05']?.lessonRead, isTrue);

      await repo.reset();
      final afterReset = await repo.load();
      expect(afterReset.profile.onboardingCompleted, isFalse);
      expect(afterReset.checkpointProgress, isEmpty);
    });

    test('rejects invalid import JSON payloads safely', () {
      final repo = LocalProgressRepository(store: InMemoryKeyValueStore());

      expect(
        () => repo.parseAndValidateImport('', curriculum: bundle),
        throwsA(isA<ProgressImportException>()),
      );
      expect(
        () => repo.parseAndValidateImport('{not json', curriculum: bundle),
        throwsA(isA<ProgressImportException>()),
      );
      expect(
        () => repo.parseAndValidateImport('[]', curriculum: bundle),
        throwsA(isA<ProgressImportException>()),
      );
      expect(
        () => repo.parseAndValidateImport(
          jsonEncode({'schemaVersion': 999}),
          curriculum: bundle,
        ),
        throwsA(isA<ProgressImportException>()),
      );

      final unknownCpPayload = jsonEncode(
        const LearnerState(
          checkpointProgress: {
            'non_existent_cp': CheckpointProgress(
              checkpointId: 'non_existent_cp',
            ),
          },
        ).toJson(),
      );
      expect(
        () => repo.parseAndValidateImport(unknownCpPayload, curriculum: bundle),
        throwsA(isA<ProgressImportException>()),
      );
    });
  });

  group('LearnerStateNotifier domain rules', () {
    test(
      'diagnostic onboarding suggests start module WITHOUT marking skipped modules mastered',
      () async {
        final store = InMemoryKeyValueStore();
        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            curriculumRepositoryProvider.overrideWithValue(
              _MemoryCurriculumRepo(bundle),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(learnerStateProvider.future);
        final notifier = container.read(learnerStateProvider.notifier);

        await notifier.completeOnboarding(
          entryPath: EntryPath.n8nUser,
          experienceSummary: 'Uses n8n',
          weeklyStudyHours: 6,
          studyDays: const [1, 3, 5],
          learningGoals: const ['Learn Python & RAG'],
          suggestedStartModuleId: 'm05',
          diagnosticResult: DiagnosticResult(
            completedAt: DateTime.utc(2026, 11, 17),
            correctCount: 5,
            totalCount: 10,
            weakModuleIds: const ['m05', 'm07'],
            confidentModuleIds: const ['m03', 'm04'],
            suggestedStartModuleId: 'm05',
          ),
        );

        final state = container.read(learnerStateProvider).requireValue;
        expect(state.profile.onboardingCompleted, isTrue);
        expect(state.profile.suggestedStartModuleId, 'm05');

        final summary = ProgressSummary.compute(bundle: bundle, state: state);
        expect(summary.completedCount, 0);
        for (final modId in ['m01', 'm02', 'm03', 'm04']) {
          expect(summary.moduleMetrics[modId]?.completedCount, 0);
        }
      },
    );

    test(
      'passing quiz does NOT auto-complete checkpoint until learner confirms completion',
      () async {
        final store = InMemoryKeyValueStore();
        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            curriculumRepositoryProvider.overrideWithValue(
              _MemoryCurriculumRepo(bundle),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(learnerStateProvider.future);
        final notifier = container.read(learnerStateProvider.notifier);

        await notifier.recordQuizAttempt(
          QuizAttemptRecord(
            id: 'att_1',
            targetId: 'm03_c05',
            attemptedAt: DateTime.utc(2026, 11, 17),
            correctCount: 2,
            totalCount: 2,
            selectedOptionByQuestion: const {'q1': 'a', 'q2': 'b'},
          ),
          checkpointTitle: 'Why localhost differs across machines',
        );

        var progress = container
            .read(learnerStateProvider)
            .requireValue
            .checkpointProgress['m03_c05'];
        expect(progress, isNotNull);
        expect(progress!.quizPassed, isTrue);
        expect(progress.status, CheckpointStatus.inProgress);
        expect(progress.status, isNot(CheckpointStatus.completed));

        await notifier.setCheckpointStatus(
          'm03_c05',
          CheckpointStatus.completed,
          checkpointTitle: 'Why localhost differs across machines',
        );

        progress = container
            .read(learnerStateProvider)
            .requireValue
            .checkpointProgress['m03_c05'];
        expect(progress!.status, CheckpointStatus.completed);
        expect(progress.completedAt, isNotNull);
      },
    );
  });

  group('SearchEngine & StudyPlannerEngine', () {
    test('searches checkpoints, glossary, capstones, and saved notes', () {
      const state = LearnerState(
        checkpointProgress: {
          'm03_c05': CheckpointProgress(
            checkpointId: 'm03_c05',
            note: 'Remember host.docker.internal note token xylophone99',
          ),
        },
      );

      final tunnelHits = SearchEngine.search(
        bundle: bundle,
        learnerState: state,
        query: 'Cloudflare Tunnel',
      );
      expect(tunnelHits, isNotEmpty);
      expect(
        tunnelHits.any((h) => h.type == SearchResultType.glossary),
        isTrue,
      );

      final noteHits = SearchEngine.search(
        bundle: bundle,
        learnerState: state,
        query: 'xylophone99',
      );
      expect(noteHits.length, 1);
      expect(noteHits.first.type, SearchResultType.note);
      expect(noteHits.first.route, '/lesson/m03_c05');
    });

    test('adapts estimated weeks when hours or completed lessons change', () {
      const baseState = LearnerState();
      final plan6h = StudyPlannerEngine.generatePlan(
        bundle: bundle,
        learnerState: baseState,
        weeklyHours: 6,
        studyDays: const [1, 3, 5],
      );
      final plan12h = StudyPlannerEngine.generatePlan(
        bundle: bundle,
        learnerState: baseState,
        weeklyHours: 12,
        studyDays: const [1, 2, 3, 4, 5, 6],
      );

      expect(plan6h.remainingCheckpoints, bundle.checkpoints.length);
      expect(plan12h.estimatedWeeks, lessThan(plan6h.estimatedWeeks));
      expect(plan6h.sessions, isNotEmpty);

      final partiallyDone = LearnerState(
        checkpointProgress: {
          for (final cp in bundle.checkpoints.take(12))
            cp.id: CheckpointProgress(
              checkpointId: cp.id,
              status: CheckpointStatus.completed,
            ),
        },
      );
      final reducedPlan = StudyPlannerEngine.generatePlan(
        bundle: bundle,
        learnerState: partiallyDone,
        weeklyHours: 6,
        studyDays: const [1, 3, 5],
      );
      expect(reducedPlan.remainingCheckpoints, bundle.checkpoints.length - 12);
      expect(
        reducedPlan.totalRemainingMinutes,
        lessThan(plan6h.totalRemainingMinutes),
      );
    });
  });
}
