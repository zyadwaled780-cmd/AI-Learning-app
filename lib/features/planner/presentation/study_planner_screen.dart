import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/study_planner_engine.dart';
import '../../../core/widgets/common_widgets.dart';

class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  bool _prioritizeDiagnostic = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    return curriculumAsync.when(
      loading: () => const LoadingScaffoldBody(),
      error: (err, _) => ErrorStateCard(
        title: 'Unable to load planner',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final state = learnerAsync.value ?? const LearnerState();
        final weeklyHours = state.profile.weeklyStudyHours;
        final studyDays = state.profile.studyDays;
        final notifier = ref.read(learnerStateProvider.notifier);

        final plan = StudyPlannerEngine.generatePlan(
          bundle: bundle,
          learnerState: state,
          weeklyHours: weeklyHours,
          studyDays: studyDays,
          prioritizeSuggestedStart: _prioritizeDiagnostic,
          maxWeeksToPreview: 12,
        );

        final groupedWeeks = <int, List<PlannedSession>>{};
        for (final session in plan.sessions) {
          groupedWeeks.putIfAbsent(session.weekNumber, () => []).add(session);
        }

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Study Planner', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Dynamically splits your remaining checkpoints across your selected weekly schedule.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),

                // Explicit Estimate Notice (Requirement H)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: colors.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Estimates Only — Not Guarantees: Lesson minute counts are rough reading & initial exercise estimates. Hands-on debugging, building the 4 capstone projects, and testing APIs vary significantly per person.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Configuration Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Weekly Study Budget',
                              style: theme.textTheme.titleMedium,
                            ),
                            Chip(label: Text('$weeklyHours hrs / week (est.)')),
                          ],
                        ),
                        Slider(
                          value: weeklyHours.toDouble().clamp(1, 30),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '$weeklyHours hrs/week',
                          onChanged: (val) => notifier.updateStudySchedule(
                            weeklyHours: val.round(),
                            studyDays: studyDays,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preferred Learning Days',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var day = 1; day <= 7; day++)
                              FilterChip(
                                label: Text(
                                  StudyPlannerEngine.weekdayLabel(day),
                                ),
                                selected: studyDays.contains(day),
                                onSelected: (selected) {
                                  final next = {...studyDays};
                                  if (selected) {
                                    next.add(day);
                                  } else if (next.length > 1) {
                                    next.remove(day);
                                  }
                                  final sorted = next.toList()..sort();
                                  notifier.updateStudySchedule(
                                    weeklyHours: weeklyHours,
                                    studyDays: sorted,
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Prioritize suggested starting & diagnostic focus modules first',
                          ),
                          value: _prioritizeDiagnostic,
                          onChanged: (v) =>
                              setState(() => _prioritizeDiagnostic = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estimate Summary Metrics
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PlannerStatChip(
                      label: 'Remaining Checkpoints',
                      value: '${plan.remainingCheckpoints}',
                    ),
                    _PlannerStatChip(
                      label: 'Remaining Content (Estimate)',
                      value:
                          '~${(plan.totalRemainingMinutes / 60).toStringAsFixed(1)} hrs',
                    ),
                    _PlannerStatChip(
                      label: 'Estimated Duration (Not a Guarantee)',
                      value: plan.remainingCheckpoints == 0
                          ? 'Done'
                          : '~${plan.estimatedWeeks} weeks',
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (plan.sessions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'All curriculum checkpoints are currently marked Completed. Review Capstones or uncheck checkpoints to replan.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Previewing Up to Next ${groupedWeeks.length} Estimated Weeks',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final weekEntry in groupedWeeks.entries) ...[
                    Card(
                      child: ExpansionTile(
                        initiallyExpanded: weekEntry.key == 1,
                        title: Text(
                          'Estimated Week ${weekEntry.key}',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${weekEntry.value.length} sessions · ~${weekEntry.value.fold<int>(0, (s, e) => s + e.allocatedMinutes)} min est. reading & checks',
                        ),
                        children: [
                          const Divider(height: 1),
                          for (final session in weekEntry.value)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${StudyPlannerEngine.weekdayLabel(session.weekdayNumber)} (~${session.allocatedMinutes} min est.)',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  for (final cp in session.checkpoints)
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      title: Text(cp.title),
                                      subtitle: Text(
                                        'Module ${bundle.moduleById[cp.moduleId]?.number ?? ''} · ~${cp.estimatedMinutes} min est.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onTap: () =>
                                          context.push('/lesson/${cp.id}'),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlannerStatChip extends StatelessWidget {
  const _PlannerStatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
