import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    return curriculumAsync.when(
      loading: () => const LoadingScaffoldBody(),
      error: (err, _) => ErrorStateCard(
        title: 'Failed to load capstone projects',
        details: '$err',
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (bundle) {
        final state = learnerAsync.value ?? const LearnerState();

        return SingleChildScrollView(
          child: AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Capstone Projects',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Four progressive, production-minded builds connecting n8n, FastAPI, Pydantic, RAG, LangGraph, evaluations, and deployment. Record only genuine metrics observed from your own tests.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 760;
                    if (!twoCol) {
                      return Column(
                        children: [
                          for (final project in bundle.projects) ...[
                            _CapstoneCard(
                              project: project,
                              progress: state.projectProgress[project.id],
                              bundle: bundle,
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < bundle.projects.length; i += 2) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _CapstoneCard(
                                  project: bundle.projects[i],
                                  progress: state
                                      .projectProgress[bundle.projects[i].id],
                                  bundle: bundle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: i + 1 < bundle.projects.length
                                    ? _CapstoneCard(
                                        project: bundle.projects[i + 1],
                                        progress:
                                            state.projectProgress[bundle
                                                .projects[i + 1]
                                                .id],
                                        bundle: bundle,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
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

class _CapstoneCard extends StatelessWidget {
  const _CapstoneCard({
    required this.project,
    required this.progress,
    required this.bundle,
  });

  final CapstoneProject project;
  final ProjectProgress? progress;
  final CurriculumBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final totalMilestones = project.milestones.length;
    final doneMilestones = progress == null
        ? 0
        : project.milestones
              .where((m) => progress!.completedMilestoneIds.contains(m.id))
              .length;
    final ratio = totalMilestones == 0 ? 0.0 : doneMilestones / totalMilestones;
    final hasRepo = (progress?.githubRepoUrl ?? '').trim().isNotEmpty;

    return Card(
      child: InkWell(
        onTap: () => context.go('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
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
                  Chip(label: Text('Capstone ${project.number}')),
                  if (hasRepo)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Repo linked',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(project.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                project.tagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.brief,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final mId in project.relatedModuleIds)
                    if (bundle.moduleById[mId] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'M${bundle.moduleById[mId]!.number}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Milestones: $doneMilestones / $totalMilestones',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    'Open Guide ->',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: ratio, minHeight: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
