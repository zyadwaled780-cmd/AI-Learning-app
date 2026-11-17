import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/code_snippet_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/comparison_card_widget.dart';
import '../../../core/widgets/status_badge.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({super.key, required this.checkpointId});

  final String checkpointId;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  String? _hydratedCheckpointId;
  bool _noteSavedFlash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(learnerStateProvider.notifier)
            .markLessonVisited(widget.checkpointId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LessonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkpointId != widget.checkpointId) {
      _hydratedCheckpointId = null;
      _noteSavedFlash = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(learnerStateProvider.notifier)
              .markLessonVisited(widget.checkpointId);
        }
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncNoteController(CheckpointProgress? progress) {
    if (_hydratedCheckpointId == widget.checkpointId) return;
    _hydratedCheckpointId = widget.checkpointId;
    _noteController.text = progress?.note ?? '';
  }

  Future<void> _saveNote(Checkpoint cp) async {
    await ref
        .read(learnerStateProvider.notifier)
        .updateNote(cp.id, _noteController.text, checkpointTitle: cp.title);
    if (!mounted) return;
    setState(() => _noteSavedFlash = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal note saved locally.')),
    );
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
            } else {
              context.go('/roadmap');
            }
          },
        ),
        title: Text(
          curriculumAsync.value?.checkpointById[widget.checkpointId]?.title ??
              'Checkpoint',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (curriculumAsync.value?.checkpointById[widget.checkpointId] !=
              null) ...[
            Builder(
              builder: (context) {
                final progress =
                    learnerAsync.value?.checkpointProgress[widget.checkpointId];
                final isBookmarked = progress?.isBookmarked ?? false;
                final needsRevisit = progress?.needsRevisit ?? false;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: isBookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark lesson',
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isBookmarked ? colors.primary : null,
                      ),
                      onPressed: () => ref
                          .read(learnerStateProvider.notifier)
                          .toggleBookmark(widget.checkpointId),
                    ),
                    IconButton(
                      tooltip: needsRevisit
                          ? 'Clear revisit flag'
                          : 'Flag concept to revisit',
                      icon: Icon(
                        needsRevisit ? Icons.flag_rounded : Icons.flag_outlined,
                        color: needsRevisit ? AppTokens.lightWarning : null,
                      ),
                      onPressed: () => ref
                          .read(learnerStateProvider.notifier)
                          .toggleNeedsRevisit(widget.checkpointId),
                    ),
                  ],
                );
              },
            ),
          ],
          IconButton(
            tooltip: 'Open Roadmap',
            icon: const Icon(Icons.route_outlined),
            onPressed: () {
              final cp =
                  curriculumAsync.value?.checkpointById[widget.checkpointId];
              context.go(
                cp == null ? '/roadmap' : '/roadmap?module=${cp.moduleId}',
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const LoadingScaffoldBody(),
        error: (err, _) => ErrorStateCard(
          title: 'Failed to load checkpoint',
          details: '$err',
          onRetry: () => ref.invalidate(curriculumProvider),
        ),
        data: (bundle) {
          final cp = bundle.checkpointById[widget.checkpointId];
          if (cp == null) {
            return ErrorStateCard(
              title: 'Checkpoint not found',
              details: 'Unknown checkpoint "${widget.checkpointId}".',
              onRetry: () => context.go('/roadmap'),
            );
          }

          final mod = bundle.moduleById[cp.moduleId];
          final progress = learnerAsync.value?.checkpointProgress[cp.id];
          _syncNoteController(progress);

          final ordered = _orderedAllCheckpoints(bundle);
          final idx = ordered.indexWhere((c) => c.id == cp.id);
          final prevCp = idx > 0 ? ordered[idx - 1] : null;
          final nextCp = idx >= 0 && idx < ordered.length - 1
              ? ordered[idx + 1]
              : null;

          final linkedComparisons = cp.comparisonCardIds
              .map((id) => bundle.comparisonById[id])
              .whereType<ComparisonCard>()
              .toList(growable: false);

          return SingleChildScrollView(
            child: AppPageContainer(
              maxWidth: AppTokens.maxReadingWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Breadcrumbs & Metadata
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (mod != null)
                        ActionChip(
                          label: Text('Module ${mod.number}: ${mod.title}'),
                          onPressed: () =>
                              context.go('/roadmap?module=${mod.id}'),
                        ),
                      DifficultyBadge(difficulty: cp.difficulty),
                      StatusBadge(
                        status: progress?.status ?? CheckpointStatus.notStarted,
                      ),
                      Text(
                        '~${cp.estimatedMinutes} min est.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(cp.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    cp.summary,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Learning Objectives & Prerequisites
                  _SectionCard(
                    title: 'Learning Objectives',
                    icon: Icons.track_changes_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final obj in cp.learningObjectives)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    obj,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (cp.prerequisiteIds.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 16),
                          Text(
                            'Helpful Prerequisites (browse anytime, never locked):',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final pId in cp.prerequisiteIds)
                                if (bundle.checkpointById[pId] != null)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.link_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      bundle.checkpointById[pId]!.title,
                                    ),
                                    onPressed: () =>
                                        context.push('/lesson/$pId'),
                                  ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Plain-English & Technical Explanations
                  _SectionCard(
                    title: 'Plain-English Mental Model',
                    icon: Icons.lightbulb_outline_rounded,
                    child: Text(
                      cp.plainEnglishExplanation,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Technical Explanation',
                    icon: Icons.engineering_outlined,
                    child: Text(
                      cp.technicalExplanation,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Why It Matters',
                    icon: Icons.bolt_rounded,
                    child: Text(
                      cp.whyItMatters,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // When to Use vs When NOT to Use
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 600;
                      final useCard = _CalloutBox(
                        title: 'When to Use',
                        body: cp.whenToUse,
                        accent: theme.brightness == Brightness.dark
                            ? AppTokens.darkSuccess
                            : AppTokens.lightSuccess,
                        icon: Icons.check_circle_outline_rounded,
                      );
                      final avoidCard = _CalloutBox(
                        title: 'When NOT to Use',
                        body: cp.whenNotToUse,
                        accent: theme.brightness == Brightness.dark
                            ? AppTokens.darkWarning
                            : AppTokens.lightWarning,
                        icon: Icons.do_not_disturb_on_outlined,
                      );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: useCard),
                            const SizedBox(width: 12),
                            Expanded(child: avoidCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          useCard,
                          const SizedBox(height: 12),
                          avoidCard,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Worked Examples (Horizontally scrolling code blocks)
                  SectionHeader(
                    title: 'Worked Examples',
                    subtitle:
                        'Code blocks scroll horizontally cleanly on small screens.',
                  ),
                  const SizedBox(height: 10),
                  for (final ex in cp.examples) ...[
                    CodeSnippetCard(example: ex),
                    const SizedBox(height: 12),
                  ],

                  // Comparison Cards if present
                  for (final comp in linkedComparisons) ...[
                    ComparisonCardWidget(card: comp),
                    const SizedBox(height: 14),
                  ],

                  // Practical Exercise & Acceptance Criteria
                  _SectionCard(
                    title: 'Practical Exercise',
                    icon: Icons.build_circle_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cp.practiceTask, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 14),
                        Text(
                          'Acceptance Criteria',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        for (final criterion in cp.acceptanceCriteria)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 17,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    criterion,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Common Mistakes
                  _SectionCard(
                    title: 'Common Mistakes to Avoid',
                    icon: Icons.warning_amber_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final mistake in cp.commonMistakes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: colors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mistake,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Knowledge Check Launcher
                  Card(
                    color: colors.secondaryContainer.withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                color: colors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Knowledge Check (${cp.quizQuestions.length} questions)',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (progress?.bestScorePercent != null)
                                Chip(
                                  label: Text(
                                    'Best: ${progress!.bestScorePercent}%',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Test your reasoning on scenario and multiple-choice traps. Passing a quiz proves concept recall—finish the practical exercise above before confirming mastery.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/quiz/${cp.id}'),
                            icon: const Icon(Icons.play_lesson_rounded),
                            label: Text(
                              (progress?.quizAttempts.isNotEmpty ?? false)
                                  ? 'Retry Knowledge Check (${progress!.quizAttempts.length} attempts)'
                                  : 'Take Knowledge Check',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Official Resources
                  _SectionCard(
                    title: 'Verified Official Resources',
                    icon: Icons.menu_book_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final res in cp.resourceLinks)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            title: Text(res.title),
                            subtitle: Text(
                              '${res.source} · Reviewed ${res.reviewedAt}',
                              style: theme.textTheme.bodySmall,
                            ),
                            onTap: () => openExternalUrl(context, res.url),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Personal Notes
                  _SectionCard(
                    title: 'Personal Notes & Takeaways',
                    icon: Icons.edit_note_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          onChanged: (_) {
                            if (_noteSavedFlash) {
                              setState(() => _noteSavedFlash = false);
                            }
                          },
                          decoration: const InputDecoration(
                            hintText:
                                'Write what clicked, errors you debugged, or questions to revisit…',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_noteSavedFlash)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  'Saved',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            FilledButton.tonalIcon(
                              onPressed: () => _saveNote(cp),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save Note'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status & Mastery Controls
                  _MasteryControlCard(checkpoint: cp, progress: progress),
                  const SizedBox(height: 20),

                  // Prev / Next Footer Navigation
                  Row(
                    children: [
                      if (prevCp != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.pushReplacement('/lesson/${prevCp.id}'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              'Prev: ${prevCp.title}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      if (nextCp != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.pushReplacement('/lesson/${nextCp.id}'),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              'Next: ${nextCp.title}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Checkpoint> _orderedAllCheckpoints(CurriculumBundle bundle) {
    final result = <Checkpoint>[];
    for (final m in bundle.modules) {
      result.addAll(bundle.checkpointsByModuleId[m.id] ?? const []);
    }
    return result;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CalloutBox extends StatelessWidget {
  const _CalloutBox({
    required this.title,
    required this.body,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String body;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MasteryControlCard extends ConsumerWidget {
  const _MasteryControlCard({required this.checkpoint, required this.progress});

  final Checkpoint checkpoint;
  final CheckpointProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentStatus = progress?.status ?? CheckpointStatus.notStarted;
    final read = progress?.lessonRead ?? false;
    final practice = progress?.practiceCompleted ?? false;
    final quizPassed = progress?.quizPassed ?? false;
    final notifier = ref.read(learnerStateProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mastery Pillars & Checkpoint Status',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Track reading, knowledge check, and practical implementation independently. Only confirm Completed when you are confident you can apply the concept.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            MasteryPillarsRow(progress: progress),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I studied this lesson thoroughly'),
              value: read,
              onChanged: (_) => notifier.toggleLessonRead(
                checkpoint.id,
                checkpointTitle: checkpoint.title,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I completed the practical exercise & verified acceptance criteria',
              ),
              value: practice,
              onChanged: (_) => notifier.togglePracticeCompleted(
                checkpoint.id,
                checkpointTitle: checkpoint.title,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quizPassed
                  ? 'Knowledge check status: Passed'
                  : 'Knowledge check status: Not yet passed (take quiz above)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: quizPassed ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text('Checkpoint Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<CheckpointStatus>(
              segments: [
                for (final st in CheckpointStatus.values)
                  ButtonSegment(value: st, label: Text(st.label)),
              ],
              selected: {currentStatus},
              onSelectionChanged: (sel) {
                notifier.setCheckpointStatus(
                  checkpoint.id,
                  sel.first,
                  checkpointTitle: checkpoint.title,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
