import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';

class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void didUpdateWidget(covariant GlossaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != null &&
        widget.initialQuery != oldWidget.initialQuery) {
      _searchController.text = widget.initialQuery!;
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

    return curriculumAsync.when(
      loading: () => const LoadingScaffoldBody(),
      error: (err, _) => ErrorStateCard(
        title: 'Unable to load glossary',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final categories =
            bundle.glossary
                .map((g) => g.category)
                .toSet()
                .toList(growable: false)
              ..sort();

        final q = _searchController.text.trim().toLowerCase();
        final filtered = bundle.glossary
            .where((term) {
              if (_selectedCategory != null &&
                  term.category != _selectedCategory) {
                return false;
              }
              if (q.isEmpty) return true;
              return term.term.toLowerCase().contains(q) ||
                  term.category.toLowerCase().contains(q) ||
                  term.plainEnglish.toLowerCase().contains(q) ||
                  term.technicalDefinition.toLowerCase().contains(q) ||
                  term.example.toLowerCase().contains(q);
            })
            .toList(growable: false);

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Engineering Glossary',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${bundle.glossary.length} terms explained in plain English and crisp technical language, linked back to lessons.',
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
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Search terms (e.g. localhost, CORS, Pydantic, RAG, Cloudflare)…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: q.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () => setState(
                                      () => _searchController.clear(),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('All (${bundle.glossary.length})'),
                                selected: _selectedCategory == null,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = null),
                              ),
                              for (final cat in categories) ...[
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(cat),
                                  selected: _selectedCategory == cat,
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No glossary terms match "${_searchController.text.trim()}".',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  for (final item in filtered) ...[
                    _GlossaryTermCard(term: item, bundle: bundle),
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

class _GlossaryTermCard extends StatelessWidget {
  const _GlossaryTermCard({required this.term, required this.bundle});

  final GlossaryTerm term;
  final CurriculumBundle bundle;

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
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(term.term, style: theme.textTheme.titleLarge),
                Chip(label: Text(term.category)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Plain English',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(term.plainEnglish, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            Text(
              'Technical Definition',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(term.technicalDefinition, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Text(
                'Example: ${term.example}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
            if (term.relatedCheckpointIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Related lessons:', style: theme.textTheme.labelMedium),
                  for (final cpId in term.relatedCheckpointIds)
                    if (bundle.checkpointById[cpId] != null)
                      ActionChip(
                        avatar: const Icon(Icons.article_outlined, size: 15),
                        label: Text(bundle.checkpointById[cpId]!.title),
                        onPressed: () => context.push('/lesson/$cpId'),
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
