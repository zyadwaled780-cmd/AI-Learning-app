import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/status_badge.dart';

enum _RoadmapFilter {
  all('All Modules'),
  incomplete('With Remaining'),
  completed('Fully Confirmed'),
  focus('Diagnostic / Suggested');

  const _RoadmapFilter(this.label);
  final String label;
}

class RoadmapScreen extends ConsumerStatefulWidget {
  const RoadmapScreen({super.key, this.initialModuleId});

  final String? initialModuleId;

  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends ConsumerState<RoadmapScreen> {
  final Set<String> _expandedModuleIds = {};
  final TextEditingController _searchController = TextEditingController();
  _RoadmapFilter _filter = _RoadmapFilter.all;
  DifficultyLevel? _difficultyFilter;

  @override
  void initState() {
    super.initState();
    if (widget.initialModuleId != null && widget.initialModuleId!.isNotEmpty) {
      _expandedModuleIds.add(widget.initialModuleId!);
    }
  }

  @override
  void didUpdateWidget(covariant RoadmapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialModuleId != null &&
        widget.initialModuleId!.isNotEmpty &&
        widget.initialModuleId != oldWidget.initialModuleId) {
      setState(() {
        _expandedModuleIds.add(widget.initialModuleId!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        title: 'Unable to load roadmap',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final state = learnerAsync.value ?? const LearnerState();
        final summary = ProgressSummary.compute(bundle: bundle, state: state);
        final suggestedStart = state.profile.suggestedStartModuleId;
        final weakIds =
            state.profile.diagnosticResult?.weakModuleIds.toSet() ??
            const <String>{};

        // Ensure suggested start module starts expanded on initial visit if nothing else expanded.
        if (_expandedModuleIds.isEmpty &&
            widget.initialModuleId == null &&
            bundle.moduleById.containsKey(suggestedStart)) {
          _expandedModuleIds.add(suggestedStart);
        }

        final query = _searchController.text.trim().toLowerCase();

        final filteredModules = bundle.modules
            .where((mod) {
              if (_difficultyFilter != null &&
                  mod.difficulty != _difficultyFilter) {
                return false;
              }
              final metrics = summary.moduleMetrics[mod.id];
              final cps = bundle.checkpointsByModuleId[mod.id] ?? const [];

              if (_filter == _RoadmapFilter.incomplete &&
                  metrics != null &&
                  metrics.completedCount >= metrics.totalCheckpoints) {
                return false;
              }
              if (_filter == _RoadmapFilter.completed &&
                  (metrics == null ||
                      metrics.completedCount < metrics.totalCheckpoints)) {
                return false;
              }
              if (_filter == _RoadmapFilter.focus &&
                  mod.id != suggestedStart &&
                  !weakIds.contains(mod.id)) {
                return false;
              }

              if (query.isEmpty) return true;
              final modMatches =
                  mod.title.toLowerCase().contains(query) ||
                  mod.subtitle.toLowerCase().contains(query) ||
                  mod.outcome.toLowerCase().contains(query);
              final cpMatches = cps.any(
                (cp) =>
                    cp.title.toLowerCase().contains(query) ||
                    cp.summary.toLowerCase().contains(query) ||
                    cp.tags.any((t) => t.toLowerCase().contains(query)),
              );
              return modMatches || cpMatches;
            })
            .toList(growable: false);

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Curriculum Roadmap',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${bundle.modules.length} ordered modules · ${bundle.checkpoints.length} hands-on checkpoints. Prerequisites are explained so you understand why order helps—every module remains freely inspectable without hard locks.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Filters
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Filter modules or checkpoints by keyword (e.g. FastAPI, localhost, RAG)…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear filter',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () => setState(
                                      () => _searchController.clear(),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in _RoadmapFilter.values)
                              ChoiceChip(
                                label: Text(f.label),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            const SizedBox(width: 8),
                            for (final diff in DifficultyLevel.values)
                              FilterChip(
                                label: Text(diff.label),
                                selected: _difficultyFilter == diff,
                                onSelected: (sel) => setState(
                                  () => _difficultyFilter = sel ? diff : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (filteredModules.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No modules match the active filters.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  for (final mod in filteredModules) ...[
                    _ModuleAccordionCard(
                      bundle: bundle,
                      module: mod,
                      checkpoints:
                          bundle.checkpointsByModuleId[mod.id] ?? const [],
                      metrics: summary.moduleMetrics[mod.id],
                      state: state,
                      isSuggestedStart: mod.id == suggestedStart,
                      isWeakDiagnostic: weakIds.contains(mod.id),
                      expanded:
                          _expandedModuleIds.contains(mod.id) ||
                          query.isNotEmpty,
                      filterQuery: query,
                      onToggleExpand: () {
                        setState(() {
                          if (_expandedModuleIds.contains(mod.id)) {
                            _expandedModuleIds.remove(mod.id);
                          } else {
                            _expandedModuleIds.add(mod.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
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

class _ModuleAccordionCard extends ConsumerWidget {
  const _ModuleAccordionCard({
    required this.bundle,
    required this.module,
    required this.checkpoints,
    required this.metrics,
    required this.state,
    required this.isSuggestedStart,
    required this.isWeakDiagnostic,
    required this.expanded,
    required this.filterQuery,
    required this.onToggleExpand,
  });

  final CurriculumBundle bundle;
  final LearningModule module;
  final List<Checkpoint> checkpoints;
  final ModuleProgressMetrics? metrics;
  final LearnerState state;
  final bool isSuggestedStart;
  final bool isWeakDiagnostic;
  final bool expanded;
  final String filterQuery;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final estMinutes = bundle.moduleEstimatedMinutes(module.id);
    final estHours = (estMinutes / 60).toStringAsFixed(1);
    final checklistDone =
        state.moduleChecklistDone[module.id]?.toSet() ?? const <String>{};

    final visibleCheckpoints = filterQuery.isEmpty
        ? checkpoints
        : checkpoints
              .where((cp) {
                final moduleHits = module.title.toLowerCase().contains(
                  filterQuery,
                );
                return moduleHits ||
                    cp.title.toLowerCase().contains(filterQuery) ||
                    cp.summary.toLowerCase().contains(filterQuery) ||
                    cp.tags.any((t) => t.toLowerCase().contains(filterQuery));
              })
              .toList(growable: false);

    final prereqLabels = module.prerequisiteModuleIds
        .map((id) => bundle.moduleById[id])
        .whereType<LearningModule>()
        .map((m) => 'M${m.number}')
        .toList(growable: false);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppTokens.radiusMd),
              bottom: expanded
                  ? Radius.zero
                  : const Radius.circular(AppTokens.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Module ${module.number}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DifficultyBadge(difficulty: module.difficulty),
                            Text(
                              '${checkpoints.length} lessons · ~$estHours hrs est.',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (isSuggestedStart)
                              Chip(
                                label: const Text('Suggested Start'),
                                backgroundColor: colors.primaryContainer
                                    .withValues(alpha: 0.55),
                              ),
                            if (isWeakDiagnostic)
                              const Chip(label: Text('Diagnostic Focus')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(module.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Outcome: ${module.outcome}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  if (prereqLabels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Helpful prerequisites (${prereqLabels.join(', ')}, open anytime): ${module.prerequisiteRationale}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (metrics != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: metrics!.completionRatio,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${metrics!.completedCount}/${metrics!.totalCheckpoints} confirmed',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: AppMotion.duration(context),
            curve: AppMotion.curve(context),
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1),
                      for (var i = 0; i < visibleCheckpoints.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _CheckpointRowTile(
                          checkpoint: visibleCheckpoints[i],
                          progress: state
                              .checkpointProgress[visibleCheckpoints[i].id],
                        ),
                      ],
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mini-Project Panel
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radiusSm,
                                ),
                                border: Border.all(color: colors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Module ${module.number} Mini-Project: ${module.miniProject.title}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    module.miniProject.brief,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final step in module.miniProject.steps)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        '• $step',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Module Mastery Self-Checklist',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            for (final item in module.masteryChecklist)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  item,
                                  style: theme.textTheme.bodySmall,
                                ),
                                value: checklistDone.contains(item),
                                onChanged: (_) => ref
                                    .read(learnerStateProvider.notifier)
                                    .toggleModuleChecklistItem(module.id, item),
                              ),
                            if (module.resourceLinks.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final res in module.resourceLinks)
                                    ActionChip(
                                      avatar: const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 15,
                                      ),
                                      label: Text(res.title),
                                      onPressed: () =>
                                          openExternalUrl(context, res.url),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointRowTile extends StatelessWidget {
  const _CheckpointRowTile({required this.checkpoint, required this.progress});

  final Checkpoint checkpoint;
  final CheckpointProgress? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = progress?.status ?? CheckpointStatus.notStarted;
    final isBookmarked = progress?.isBookmarked ?? false;
    final needsRevisit = progress?.needsRevisit ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: colors.surfaceContainerHighest,
        child: Text('${checkpoint.order}', style: theme.textTheme.labelMedium),
      ),
      title: Text(checkpoint.title, style: theme.textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              checkpoint.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: status),
                Text(
                  '~${checkpoint.estimatedMinutes} min est.',
                  style: theme.textTheme.bodySmall,
                ),
                if (isBookmarked)
                  Icon(Icons.bookmark_rounded, size: 16, color: colors.primary),
                if (needsRevisit) const Icon(Icons.flag_rounded, size: 16),
              ],
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () => context.push('/lesson/${checkpoint.id}'),
    );
  }
}
