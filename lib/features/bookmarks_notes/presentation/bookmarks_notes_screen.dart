import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/status_badge.dart';

enum _SavedFilter {
  all('All Saved'),
  bookmarked('Bookmarked'),
  notes('With Notes'),
  revisit('Flagged to Revisit');

  const _SavedFilter(this.label);
  final String label;
}

class BookmarksNotesScreen extends ConsumerStatefulWidget {
  const BookmarksNotesScreen({super.key});

  @override
  ConsumerState<BookmarksNotesScreen> createState() =>
      _BookmarksNotesScreenState();
}

class _BookmarksNotesScreenState extends ConsumerState<BookmarksNotesScreen> {
  _SavedFilter _filter = _SavedFilter.all;
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    return curriculumAsync.when(
      loading: () => const LoadingScaffoldBody(),
      error: (err, _) => ErrorStateCard(
        title: 'Unable to load notes',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final state = learnerAsync.value ?? const LearnerState();
        final notifier = ref.read(learnerStateProvider.notifier);
        final q = _queryController.text.trim().toLowerCase();

        final entries = <({Checkpoint cp, CheckpointProgress progress})>[];
        for (final mod in bundle.modules) {
          for (final cp in bundle.checkpointsByModuleId[mod.id] ?? const []) {
            final p = state.checkpointProgress[cp.id];
            if (p == null) continue;
            final hasNote = p.note.trim().isNotEmpty;
            if (!p.isBookmarked && !hasNote && !p.needsRevisit) continue;

            final matchesTab = switch (_filter) {
              _SavedFilter.all => true,
              _SavedFilter.bookmarked => p.isBookmarked,
              _SavedFilter.notes => hasNote,
              _SavedFilter.revisit => p.needsRevisit,
            };
            if (!matchesTab) continue;

            if (q.isNotEmpty) {
              final hit =
                  cp.title.toLowerCase().contains(q) ||
                  cp.summary.toLowerCase().contains(q) ||
                  p.note.toLowerCase().contains(q);
              if (!hit) continue;
            }
            entries.add((cp: cp, progress: p));
          }
        }

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bookmarks & Personal Notes',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Revisit bookmarked lessons, inspect saved study notes, and track difficult concepts flagged for review.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _queryController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Search notes or bookmarked lesson titles…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: q.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () => setState(
                                      () => _queryController.clear(),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in _SavedFilter.values)
                              ChoiceChip(
                                label: Text(f.label),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmarks_outlined,
                            size: 36,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            q.isEmpty
                                ? 'Nothing saved here yet. Bookmark a checkpoint, flag a tough concept to revisit, or add personal notes inside any lesson.'
                                : 'No saved items match "${_queryController.text.trim()}".',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final entry in entries) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Module ${bundle.moduleById[entry.cp.moduleId]?.number ?? ''}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(color: colors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.cp.title,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: entry.progress.isBookmarked
                                      ? 'Remove bookmark'
                                      : 'Bookmark lesson',
                                  icon: Icon(
                                    entry.progress.isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: entry.progress.isBookmarked
                                        ? colors.primary
                                        : null,
                                  ),
                                  onPressed: () =>
                                      notifier.toggleBookmark(entry.cp.id),
                                ),
                                IconButton(
                                  tooltip: entry.progress.needsRevisit
                                      ? 'Clear revisit flag'
                                      : 'Flag to revisit',
                                  icon: Icon(
                                    entry.progress.needsRevisit
                                        ? Icons.flag_rounded
                                        : Icons.flag_outlined,
                                    color: entry.progress.needsRevisit
                                        ? AppTokens.lightWarning
                                        : null,
                                  ),
                                  onPressed: () =>
                                      notifier.toggleNeedsRevisit(entry.cp.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            StatusBadge(status: entry.progress.status),
                            if (entry.progress.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  entry.progress.note.trim(),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    context.push('/lesson/${entry.cp.id}'),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text('Open Checkpoint'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
