import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/study_planner_engine.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    return curriculumAsync.when(
      loading: () => const LoadingScaffoldBody(),
      error: (err, _) => ErrorStateCard(
        title: 'Unable to load curriculum',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final state = learnerAsync.value ?? const LearnerState();
        final summary = ProgressSummary.compute(bundle: bundle, state: state);
        final nextCp = summary.recommendedNextCheckpoint;
        final currentMod = summary.currentModule;
        final plan = StudyPlannerEngine.generatePlan(
          bundle: bundle,
          learnerState: state,
          weeklyHours: state.profile.weeklyStudyHours,
          studyDays: state.profile.studyDays,
        );

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Engineering Dashboard',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.profile.entryPath == EntryPath.n8nUser
                              ? 'Path: n8n Builder -> Production AI Systems Engineer'
                              : 'Path: Zero to Production AI Automation Engineer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/onboarding'),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Entry Path & Goals'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/diagnostic'),
                          icon: const Icon(Icons.quiz_outlined, size: 18),
                          label: const Text('n8n Diagnostic'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Continue / Recommended Next Checkpoint Card
                _ContinueLearningHero(
                  bundle: bundle,
                  state: state,
                  nextCheckpoint: nextCp,
                  currentModule: currentMod,
                ),
                const SizedBox(height: 20),

                // 3-Metric Summary Row (Overall Progress, Weekly Goal Estimate, Project Progress)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 880;
                    final mid = constraints.maxWidth >= 560;
                    final cards = [
                      _OverallProgressCard(summary: summary),
                      _WeeklyGoalCard(profile: state.profile, plan: plan),
                      _ProjectSummaryCard(
                        bundle: bundle,
                        summary: summary,
                        state: state,
                      ),
                    ];
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[2]),
                        ],
                      );
                    }
                    if (mid) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 14),
                              Expanded(child: cards[1]),
                            ],
                          ),
                          const SizedBox(height: 14),
                          cards[2],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                        const SizedBox(height: 12),
                        cards[2],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Two-column bottom section: Current Module Focus + Recent Activity
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final modFocus = _CurrentModuleFocusCard(
                      bundle: bundle,
                      summary: summary,
                      state: state,
                    );
                    final recent = _RecentActivityCard(
                      activities: state.recentActivity,
                      summary: summary,
                    );
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: modFocus),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: recent),
                        ],
                      );
                    }
                    return Column(
                      children: [modFocus, const SizedBox(height: 14), recent],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContinueLearningHero extends StatelessWidget {
  const _ContinueLearningHero({
    required this.bundle,
    required this.state,
    required this.nextCheckpoint,
    required this.currentModule,
  });

  final CurriculumBundle bundle;
  final LearnerState state;
  final Checkpoint? nextCheckpoint;
  final LearningModule? currentModule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cp = nextCheckpoint;

    if (cp == null) {
      return Card(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, size: 36, color: colors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All ${bundle.checkpoints.length} Checkpoints Confirmed Completed',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep sharpening your Capstone Repositories, evaluations, and architecture trade-offs.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => context.go('/projects'),
                child: const Text('Review Capstones'),
              ),
            ],
          ),
        ),
      );
    }

    final cpProgress = state.checkpointProgress[cp.id];
    final mod = bundle.moduleById[cp.moduleId] ?? currentModule;
    final isResuming = state.lastVisitedCheckpointId == cp.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    isResuming
                        ? 'Continue Learning'
                        : 'Recommended Next Checkpoint',
                  ),
                ),
                if (mod != null)
                  Text(
                    'Module ${mod.number}: ${mod.title}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                DifficultyBadge(difficulty: cp.difficulty),
                Text(
                  '~${cp.estimatedMinutes} min est.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(cp.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              cp.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            MasteryPillarsRow(progress: cpProgress),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/lesson/${cp.id}'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isResuming ? 'Resume Checkpoint' : 'Start Checkpoint',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/roadmap?module=${cp.moduleId}'),
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('View Module in Roadmap'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.summary});
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${summary.completedCount}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text(
                  '/ ${summary.totalCheckpoints} confirmed (${summary.completionPercent}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: summary.completionRatio,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _MiniCount(
                  label: 'In progress',
                  count: summary.inProgressCount,
                ),
                _MiniCount(label: 'Read', count: summary.lessonsReadCount),
                _MiniCount(
                  label: 'Checks passed',
                  count: summary.quizzesPassedCount,
                ),
                _MiniCount(
                  label: 'Practice done',
                  count: summary.practicesCompletedCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.profile, required this.plan});

  final LearnerProfile profile;
  final StudyPlanResult plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dayNames = profile.studyDays
        .map(StudyPlannerEngine.weekdayLabel)
        .join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Weekly Study Goal',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/planner'),
                  child: const Text('Planner'),
                ),
              ],
            ),
            Text(
              '${profile.weeklyStudyHours} hrs / week',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text('Days: $dayNames', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              plan.remainingCheckpoints == 0
                  ? 'All checkpoints completed.'
                  : '${plan.remainingCheckpoints} checkpoints left (~${(plan.totalRemainingMinutes / 60).toStringAsFixed(1)} hrs · est. ${plan.estimatedWeeks} wks, estimate only).',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({
    required this.bundle,
    required this.summary,
    required this.state,
  });

  final CurriculumBundle bundle;
  final ProgressSummary summary;
  final LearnerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final linkedRepos = bundle.projects
        .where(
          (p) => (state.projectProgress[p.id]?.githubRepoUrl ?? '')
              .trim()
              .isNotEmpty,
        )
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Capstone Projects',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/projects'),
                  child: const Text('Open All'),
                ),
              ],
            ),
            Text(
              '${summary.completedProjectMilestones} / ${summary.totalProjectMilestones} milestones',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: summary.projectCompletionRatio,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$linkedRepos of ${bundle.projects.length} capstones linked to a GitHub repo.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentModuleFocusCard extends StatelessWidget {
  const _CurrentModuleFocusCard({
    required this.bundle,
    required this.summary,
    required this.state,
  });

  final CurriculumBundle bundle;
  final ProgressSummary summary;
  final LearnerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mod = summary.currentModule;
    if (mod == null) return const SizedBox.shrink();

    final metrics = summary.moduleMetrics[mod.id];
    final cps = bundle.checkpointsByModuleId[mod.id] ?? const <Checkpoint>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Focus: Module ${mod.number}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/roadmap?module=${mod.id}'),
                  child: const Text('Expand Module'),
                ),
              ],
            ),
            Text(mod.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(mod.outcome, style: theme.textTheme.bodyMedium),
            if (metrics != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${metrics.completedCount} / ${metrics.totalCheckpoints} checkpoints confirmed',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${metrics.completionPercent}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: metrics.completionRatio,
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final cp in cps.take(4))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: StatusBadge(
                  status:
                      state.checkpointProgress[cp.id]?.status ??
                      CheckpointStatus.notStarted,
                ),
                title: Text(
                  cp.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/lesson/${cp.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities, required this.summary});

  final List<ActivityLogEntry> activities;
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (summary.revisitCount > 0 || summary.bookmarkedCount > 0)
                  TextButton(
                    onPressed: () => context.go('/notes'),
                    child: Text(
                      '${summary.bookmarkedCount} saved · ${summary.revisitCount} revisit',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No learning activity recorded yet. Open your first checkpoint or run the n8n diagnostic to start tracking.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final act in activities.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _iconForKind(act.kind),
                    size: 18,
                    color: colors.primary,
                  ),
                  title: Text(
                    act.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatDate(act.timestamp),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: act.route == null
                      ? null
                      : () => context.go(act.route!),
                ),
          ],
        ),
      ),
    );
  }

  IconData _iconForKind(String kind) {
    return switch (kind) {
      'checkpoint_completed' => Icons.check_circle_outline_rounded,
      'quiz_attempt' => Icons.quiz_outlined,
      'lesson_read' => Icons.menu_book_outlined,
      'practice_done' => Icons.build_outlined,
      'project_milestone' => Icons.workspaces_outlined,
      'diagnostic_completed' => Icons.analytics_outlined,
      _ => Icons.history_rounded,
    };
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
