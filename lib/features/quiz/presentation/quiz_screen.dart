import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';

enum QuizScreenMode { checkpoint, diagnostic }

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.mode, this.checkpointId});

  final QuizScreenMode mode;
  final String? checkpointId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final Map<String, String> _selected = {};
  bool _submitted = false;
  DiagnosticResult? _diagnosticSummary;

  void _resetForRetry() {
    setState(() {
      _selected.clear();
      _submitted = false;
      _diagnosticSummary = null;
    });
  }

  Future<void> _submitCheckpointQuiz(Checkpoint cp) async {
    var correct = 0;
    for (final qq in cp.quizQuestions) {
      final chosenId = _selected[qq.id];
      final right = qq.options.any((o) => o.id == chosenId && o.isCorrect);
      if (right) correct++;
    }

    final attempt = QuizAttemptRecord(
      id: 'att_${DateTime.now().microsecondsSinceEpoch}',
      targetId: cp.id,
      attemptedAt: DateTime.now(),
      correctCount: correct,
      totalCount: cp.quizQuestions.length,
      selectedOptionByQuestion: Map.unmodifiable(_selected),
    );

    await ref
        .read(learnerStateProvider.notifier)
        .recordQuizAttempt(attempt, checkpointTitle: cp.title);

    if (mounted) {
      setState(() {
        _submitted = true;
      });
    }
  }

  Future<void> _submitDiagnostic(CurriculumBundle bundle) async {
    var correctCount = 0;
    final missedByModule = <String, int>{};
    final hitByModule = <String, int>{};

    for (final dq in bundle.diagnosticQuestions) {
      final chosen = _selected[dq.id];
      final ok = dq.options.any((o) => o.id == chosen && o.isCorrect);
      if (ok) {
        correctCount++;
        hitByModule[dq.moduleId] = (hitByModule[dq.moduleId] ?? 0) + 1;
      } else {
        missedByModule[dq.moduleId] = (missedByModule[dq.moduleId] ?? 0) + 1;
      }
    }

    final weakModules = bundle.modules
        .where((m) => (missedByModule[m.id] ?? 0) > 0)
        .map((m) => m.id)
        .toList(growable: false);

    final confidentModules = bundle.modules
        .where(
          (m) =>
              (hitByModule[m.id] ?? 0) > 0 && (missedByModule[m.id] ?? 0) == 0,
        )
        .map((m) => m.id)
        .toList(growable: false);

    // Suggest the earliest missed diagnostic module (or m03/m04 if user nailed everything except networking/HTTP,
    // or m05 if they aced m03/m04 already, never locking or auto-completing any earlier modules).
    String suggestedStart;
    if (weakModules.isNotEmpty) {
      suggestedStart = weakModules.first;
    } else {
      suggestedStart = 'm06';
    }

    final result = DiagnosticResult(
      completedAt: DateTime.now(),
      correctCount: correctCount,
      totalCount: bundle.diagnosticQuestions.length,
      weakModuleIds: weakModules,
      confidentModuleIds: confidentModules,
      suggestedStartModuleId: suggestedStart,
    );

    final currentProfile =
        ref.read(learnerStateProvider).value?.profile ?? const LearnerProfile();

    await ref
        .read(learnerStateProvider.notifier)
        .completeOnboarding(
          entryPath: EntryPath.n8nUser,
          experienceSummary: currentProfile.experienceSummary,
          weeklyStudyHours: currentProfile.weeklyStudyHours,
          studyDays: currentProfile.studyDays,
          learningGoals: currentProfile.learningGoals,
          suggestedStartModuleId: suggestedStart,
          diagnosticResult: result,
        );

    if (mounted) {
      setState(() {
        _submitted = true;
        _diagnosticSummary = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (widget.checkpointId != null) {
              context.go('/lesson/${widget.checkpointId}');
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          widget.mode == QuizScreenMode.diagnostic
              ? 'n8n Engineering Diagnostic'
              : 'Knowledge Check',
        ),
      ),
      body: curriculumAsync.when(
        loading: () => const LoadingScaffoldBody(),
        error: (err, _) => ErrorStateCard(
          title: 'Failed to load questions',
          details: '$err',
          onRetry: () => ref.invalidate(curriculumProvider),
        ),
        data: (bundle) {
          if (widget.mode == QuizScreenMode.diagnostic) {
            return _buildDiagnosticBody(context, theme, colors, bundle);
          }

          final cp = widget.checkpointId != null
              ? bundle.checkpointById[widget.checkpointId!]
              : null;
          if (cp == null) {
            return ErrorStateCard(
              title: 'Checkpoint not found',
              details: 'Unknown checkpoint "${widget.checkpointId}".',
              onRetry: () => context.go('/roadmap'),
            );
          }

          final progress = learnerAsync.value?.checkpointProgress[cp.id];
          return _buildCheckpointQuizBody(
            context,
            theme,
            colors,
            bundle,
            cp,
            progress,
          );
        },
      ),
    );
  }

  Widget _buildCheckpointQuizBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    CurriculumBundle bundle,
    Checkpoint cp,
    CheckpointProgress? progress,
  ) {
    final allAnswered = cp.quizQuestions.every(
      (q) => _selected.containsKey(q.id),
    );
    final correctCount = cp.quizQuestions.where((q) {
      final sel = _selected[q.id];
      return q.options.any((o) => o.id == sel && o.isCorrect);
    }).length;
    final passedNow =
        cp.quizQuestions.isNotEmpty &&
        (correctCount / cp.quizQuestions.length) >= 0.7;

    return SingleChildScrollView(
      child: AppPageContainer(
        maxWidth: AppTokens.maxReadingWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cp.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Multiple-choice checks verify conceptual grasp, not hands-on implementation. Passing updates "Check passed" but leaves final Checkpoint Status for you to confirm after doing the practical exercise.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (progress != null &&
                        progress.quizAttempts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              'Attempts: ${progress.quizAttempts.length}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Best score: ${progress.bestScorePercent}%',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (_submitted) ...[
              _QuizScoreCard(
                correctCount: correctCount,
                totalCount: cp.quizQuestions.length,
                passed: passedNow,
                disclaimer: 'Remember: passing this knowledge check does not automatically mark the checkpoint Completed—finish the practice task first.',
              ),
              const SizedBox(height: 18),
            ],

            for (var i = 0; i < cp.quizQuestions.length; i++) ...[
              _QuestionCard(
                index: i + 1,
                prompt: cp.quizQuestions[i].prompt,
                scenarioContext: cp.quizQuestions[i].scenarioContext,
                kind: cp.quizQuestions[i].kind,
                options: cp.quizQuestions[i].options,
                takeaway: cp.quizQuestions[i].takeaway,
                selectedOptionId: _selected[cp.quizQuestions[i].id],
                submitted: _submitted,
                onSelect: (optId) {
                  if (_submitted) return;
                  setState(() => _selected[cp.quizQuestions[i].id] = optId);
                },
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                if (_submitted) ...[
                  OutlinedButton.icon(
                    onPressed: _resetForRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Check'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/lesson/${cp.id}');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Return to Lesson'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: allAnswered
                        ? () => _submitCheckpointQuiz(cp)
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      allAnswered
                          ? 'Submit Knowledge Check'
                          : 'Answer all ${cp.quizQuestions.length} questions',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    CurriculumBundle bundle,
  ) {
    final questions = bundle.diagnosticQuestions;
    final allAnswered = questions.every((q) => _selected.containsKey(q.id));
    final summary = _diagnosticSummary;

    return SingleChildScrollView(
      child: AppPageContainer(
        maxWidth: AppTokens.maxReadingWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostic Placement Quiz for n8n Builders',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tests real mental models across Docker localhost, HTTP auth vs CORS, Python virtualenvs, idempotency, prompt injection, Pydantic, RAG tenant ACLs, LangGraph, and Cloudflare Tunnel. Skipped early modules are NEVER automatically marked as completed or mastered.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (_submitted && summary != null) ...[
              _DiagnosticOutcomeCard(result: summary, bundle: bundle),
              const SizedBox(height: 18),
            ],

            for (var i = 0; i < questions.length; i++) ...[
              _QuestionCard(
                index: i + 1,
                domainTag: questions[i].domain,
                prompt: questions[i].prompt,
                scenarioContext: '',
                kind: 'scenario',
                options: questions[i].options,
                takeaway: '',
                selectedOptionId: _selected[questions[i].id],
                submitted: _submitted,
                onSelect: (optId) {
                  if (_submitted) return;
                  setState(() => _selected[questions[i].id] = optId);
                },
              ),
              const SizedBox(height: 14),
            ],

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                if (_submitted && summary != null) ...[
                  OutlinedButton.icon(
                    onPressed: _resetForRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake Diagnostic'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Go to Dashboard'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: allAnswered
                        ? () => _submitDiagnostic(bundle)
                        : null,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(
                      allAnswered
                          ? 'Score Diagnostic & Suggest Start'
                          : 'Answer all ${questions.length} diagnostic questions',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuizScoreCard extends StatelessWidget {
  const _QuizScoreCard({
    required this.correctCount,
    required this.totalCount,
    required this.passed,
    required this.disclaimer,
  });

  final int correctCount;
  final int totalCount;
  final bool passed;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = passed
        ? (isDark ? AppTokens.darkSuccess : AppTokens.lightSuccess)
        : (isDark ? AppTokens.darkWarning : AppTokens.lightWarning);
    final pct = totalCount == 0
        ? 0
        : ((correctCount / totalCount) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                passed
                    ? 'Score: $correctCount / $totalCount ($pct%) — Check Passed'
                    : 'Score: $correctCount / $totalCount ($pct%) — Review explanations below',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(disclaimer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DiagnosticOutcomeCard extends StatelessWidget {
  const _DiagnosticOutcomeCard({required this.result, required this.bundle});

  final DiagnosticResult result;
  final CurriculumBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final startMod = bundle.moduleById[result.suggestedStartModuleId];
    final weakMods = result.weakModuleIds
        .map((id) => bundle.moduleById[id])
        .whereType<LearningModule>()
        .toList(growable: false);

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Complete: ${result.correctCount}/${result.totalCount} Correct',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (startMod != null)
              Text(
                'Suggested Starting Point: Module ${startMod.number} — ${startMod.title}',
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 6),
            Text(
              'Important rule: Modules before Module ${startMod?.number ?? 1} are NOT marked completed or mastered. You can revisit or confirm them anytime.',
              style: theme.textTheme.bodySmall,
            ),
            if (weakMods.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recommended Focus Modules:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in weakMods)
                    ActionChip(
                      label: Text('Module ${m.number}: ${m.title}'),
                      onPressed: () => context.go('/roadmap?module=${m.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.prompt,
    required this.scenarioContext,
    required this.kind,
    required this.options,
    required this.takeaway,
    required this.selectedOptionId,
    required this.submitted,
    required this.onSelect,
    this.domainTag,
  });

  final int index;
  final String prompt;
  final String scenarioContext;
  final String kind;
  final List<QuizOption> options;
  final String takeaway;
  final String? selectedOptionId;
  final bool submitted;
  final ValueChanged<String> onSelect;
  final String? domainTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark
        ? AppTokens.darkSuccess
        : AppTokens.lightSuccess;
    final errorColor = isDark ? AppTokens.darkDanger : AppTokens.lightDanger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    domainTag ??
                        (kind == 'scenario'
                            ? 'Question $index · Scenario'
                            : 'Question $index · Check'),
                  ),
                ),
                if (domainTag != null)
                  Text('Question $index', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 10),
            if (scenarioContext.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: colors.outline),
                ),
                child: Text(scenarioContext, style: theme.textTheme.bodyMedium),
              ),
            ],
            Text(prompt, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            for (final opt in options) ...[
              Builder(
                builder: (context) {
                  final isSelected = selectedOptionId == opt.id;
                  Color borderColor = isSelected
                      ? colors.primary
                      : colors.outline;
                  Color? fillColor = isSelected
                      ? colors.primaryContainer.withValues(alpha: 0.28)
                      : null;

                  if (submitted) {
                    if (opt.isCorrect) {
                      borderColor = successColor;
                      fillColor = successColor.withValues(alpha: 0.1);
                    } else if (isSelected && !opt.isCorrect) {
                      borderColor = errorColor;
                      fillColor = errorColor.withValues(alpha: 0.1);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: submitted ? null : () => onSelect(opt.id),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: borderColor,
                            width: (isSelected || (submitted && opt.isCorrect))
                                ? 1.6
                                : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  submitted
                                      ? (opt.isCorrect
                                            ? Icons.check_circle_rounded
                                            : isSelected
                                            ? Icons.cancel_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded)
                                      : (isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded),
                                  size: 20,
                                  color: submitted
                                      ? (opt.isCorrect
                                            ? successColor
                                            : isSelected
                                            ? errorColor
                                            : colors.onSurfaceVariant)
                                      : (isSelected
                                            ? colors.primary
                                            : colors.onSurfaceVariant),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (submitted) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 30),
                                child: Text(
                                  opt.explanation,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: opt.isCorrect
                                        ? successColor
                                        : isSelected
                                        ? errorColor
                                        : colors.onSurfaceVariant,
                                    fontWeight: opt.isCorrect || isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            if (submitted && takeaway.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Text(
                  'Key takeaway: $takeaway',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
