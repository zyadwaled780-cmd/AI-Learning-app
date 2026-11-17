import 'package:ai_automation_hero/app/app.dart';
import 'package:ai_automation_hero/core/models/curriculum_models.dart';
import 'package:ai_automation_hero/core/models/learner_state.dart';
import 'package:ai_automation_hero/core/providers/app_providers.dart';
import 'package:ai_automation_hero/core/repositories/curriculum_repository.dart';
import 'package:ai_automation_hero/core/repositories/key_value_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

class _CachedCurriculumRepository implements CurriculumRepository {
  _CachedCurriculumRepository(this.bundle);
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

  Widget buildApp({InMemoryKeyValueStore? store}) {
    return ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
          store ?? InMemoryKeyValueStore(),
        ),
        curriculumRepositoryProvider.overrideWithValue(
          _CachedCurriculumRepository(bundle),
        ),
      ],
      child: const AiAutomationHeroApp(),
    );
  }

  testWidgets(
    'onboarding start-from-zero flow reaches dashboard on desktop layout cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Learning Path Setup'), findsOneWidget);
      expect(find.text('Start from zero'), findsOneWidget);
      expect(find.text('I already use n8n'), findsOneWidget);

      await tester.tap(find.text('Start from zero'));
      await tester.pumpAndSettle();

      final beginBtn = find.text('Begin From Module 1');
      await tester.ensureVisible(beginBtn);
      await tester.tap(beginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Engineering Dashboard'), findsOneWidget);
      expect(find.text('Roadmap'), findsOneWidget);
      expect(find.text('Start Checkpoint'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'n8n diagnostic quiz suggests starting module without auto-completing earlier modules',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('I already use n8n'));
      await tester.pumpAndSettle();

      final startDiag = find.text('Start 10-Question n8n Diagnostic');
      await tester.ensureVisible(startDiag);
      await tester.tap(startDiag);
      await tester.pumpAndSettle();

      expect(
        find.text('Diagnostic Placement Quiz for n8n Builders'),
        findsOneWidget,
      );

      for (final dq in bundle.diagnosticQuestions) {
        final optFinder = find.text(dq.options.first.text);
        await tester.ensureVisible(optFinder);
        await tester.tap(optFinder);
        await tester.pump();
      }

      final submitBtn = find.text('Score Diagnostic & Suggest Start');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Diagnostic Complete:'), findsOneWidget);
      expect(
        find.textContaining('NOT marked completed or mastered'),
        findsOneWidget,
      );

      final goDash = find.text('Go to Dashboard');
      await tester.ensureVisible(goDash);
      await tester.tap(goDash);
      await tester.pumpAndSettle();

      expect(find.text('Engineering Dashboard'), findsOneWidget);

      await tester.tap(find.text('Roadmap'));
      await tester.pumpAndSettle();
      expect(find.text('Engineering Foundations'), findsOneWidget);
      expect(find.text('0/8 confirmed'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'roadmap -> lesson detail -> knowledge check -> notes -> projects -> glossary -> planner -> settings',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Dashboard'));
      await tester.pumpAndSettle();

      // 1. Open Roadmap, expand Module 3, open localhost lesson.
      await tester.tap(find.text('Roadmap'));
      await tester.pumpAndSettle();

      final mod3 = find.text('Networking, HTTP, and Hosting');
      await tester.ensureVisible(mod3);
      await tester.tap(mod3);
      await tester.pumpAndSettle();

      final cp = bundle.checkpointById['m03_c05']!;
      final cpFinder = find.text(cp.title);
      await tester.ensureVisible(cpFinder);
      await tester.tap(cpFinder);
      await tester.pumpAndSettle();

      expect(find.text('Plain-English Mental Model'), findsOneWidget);
      expect(find.text('When to Use'), findsOneWidget);
      expect(find.text('When NOT to Use'), findsOneWidget);

      // Bookmark & save personal note.
      await tester.tap(find.byTooltip('Bookmark lesson'));
      await tester.pump();

      final readCheckbox = find.text('I studied this lesson thoroughly');
      await tester.ensureVisible(readCheckbox);
      await tester.tap(readCheckbox);
      await tester.pump();

      final noteField = find.widgetWithText(
        TextField,
        'Write what clicked, errors you debugged, or questions to revisit…',
      );
      await tester.ensureVisible(noteField);
      await tester.enterText(
        noteField,
        'Docker containers isolate loopback 127.0.0.1',
      );
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      // Open Knowledge Check from inside Lesson Detail.
      final quizBtn = find.text('Take Knowledge Check');
      await tester.ensureVisible(quizBtn);
      await tester.tap(quizBtn);
      await tester.pumpAndSettle();

      for (final q in cp.quizQuestions) {
        final correctOpt = q.options.firstWhere((o) => o.isCorrect);
        final optFinder = find.text(correctOpt.text);
        await tester.ensureVisible(optFinder);
        await tester.tap(optFinder);
        await tester.pump();
      }

      final submitQuiz = find.text('Submit Knowledge Check');
      await tester.ensureVisible(submitQuiz);
      await tester.tap(submitQuiz);
      await tester.pumpAndSettle();

      expect(find.textContaining('Check Passed'), findsOneWidget);
      final returnBtn = find.text('Return to Lesson');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      // Explicitly mark Completed via SegmentedButton.
      final completedSeg = find.descendant(
        of: find.byType(SegmentedButton<CheckpointStatus>),
        matching: find.text('Completed'),
      );
      await tester.ensureVisible(completedSeg);
      await tester.tap(completedSeg);
      await tester.pumpAndSettle();

      // Return to shell from Lesson Detail.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // 2. Check Notes screen displays saved note & bookmark.
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(
        find.text('Docker containers isolate loopback 127.0.0.1'),
        findsOneWidget,
      );

      // 3. Open Projects -> Capstone 1 detail & save repo link.
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      final projCard = find.text(bundle.projects.first.title);
      await tester.ensureVisible(projCard);
      await tester.tap(projCard);
      await tester.pumpAndSettle();

      final repoField = find.widgetWithText(TextField, 'GitHub Repository URL');
      await tester.ensureVisible(repoField);
      await tester.enterText(repoField, 'https://github.com/example/triage');
      final saveProj = find.text('Save Repo, Metrics & Reflection');
      await tester.ensureVisible(saveProj);
      await tester.tap(saveProj);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Project repository, measured metrics, and reflection saved.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Back to Projects'));
      await tester.pumpAndSettle();

      // 4. Open Glossary and filter for Cloudflare Tunnel.
      await tester.tap(find.text('Glossary'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Cloudflare Tunnel');
      await tester.pumpAndSettle();
      expect(find.text('Cloudflare Tunnel'), findsAtLeastNWidgets(1));

      // 5. Open Study Planner and confirm estimate disclosure.
      await tester.tap(find.text('Planner'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Estimates Only'), findsOneWidget);

      // 6. Open Settings, switch theme & cancel reset confirmation.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      final darkSeg = find.text('Dark');
      await tester.ensureVisible(darkSeg);
      await tester.tap(darkSeg);
      await tester.pumpAndSettle();

      final resetBtn = find.text('Reset Progress');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset All Learning Progress?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open Export Progress JSON dialog cleanly & dismiss.
      final exportBtn = find.text('Export Progress JSON');
      await tester.ensureVisible(exportBtn);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();
      expect(find.text('Copy JSON'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Open Import Progress JSON dialog & confirm invalid JSON reports error cleanly.
      final importBtn = find.text('Import Progress JSON');
      await tester.ensureVisible(importBtn);
      await tester.tap(importBtn);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        '{"schemaVersion": 99}',
      );
      await tester.tap(find.text('Validate & Import'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unsupported progress schemaVersion'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open Global Search dialog from desktop sidebar & jump to Glossary/Lesson hit.
      await tester.tap(find.text('Search curriculum…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Pydantic');
      await tester.pumpAndSettle();
      expect(find.textContaining('Pydantic'), findsAtLeastNWidgets(1));
      await tester.tap(find.byTooltip('Close search'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mobile viewport renders bottom navigation bar and More sheet cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsOneWidget);
      expect(find.text('Engineering Glossary'), findsOneWidget);
      expect(find.text('Settings & Export'), findsOneWidget);

      await tester.tap(find.text('Study Planner'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Estimates Only'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
