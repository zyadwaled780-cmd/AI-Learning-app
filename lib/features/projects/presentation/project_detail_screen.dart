import 'package:flutter/services.dart';
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

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final Map<String, TextEditingController> _metricControllers = {};
  String? _hydratedProjectId;

  @override
  void dispose() {
    _repoController.dispose();
    _reflectionController.dispose();
    for (final c in _metricControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(CapstoneProject project, ProjectProgress? progress) {
    if (_hydratedProjectId == project.id) return;
    _hydratedProjectId = project.id;
    _repoController.text = progress?.githubRepoUrl ?? '';
    _reflectionController.text = progress?.reflectionNotes ?? '';
    for (final c in _metricControllers.values) {
      c.dispose();
    }
    _metricControllers.clear();
    for (final tmpl in project.metricTemplates) {
      _metricControllers[tmpl.id] = TextEditingController(
        text: progress?.recordedMetrics[tmpl.id] ?? '',
      );
    }
  }

  Future<void> _saveLearnerDetails(CapstoneProject project) async {
    final metrics = <String, String>{};
    for (final entry in _metricControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) {
        metrics[entry.key] = val;
      }
    }
    await ref
        .read(learnerStateProvider.notifier)
        .updateProjectDetails(
          project.id,
          githubRepoUrl: _repoController.text.trim(),
          recordedMetrics: metrics,
          reflectionNotes: _reflectionController.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Project repository, measured metrics, and reflection saved.',
        ),
      ),
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
          tooltip: 'Back to Projects',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/projects');
            }
          },
        ),
        title: Text(
          curriculumAsync.value?.projectById[widget.projectId]?.title ??
              'Capstone Project',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: curriculumAsync.when(
        loading: () => const LoadingScaffoldBody(),
        error: (err, _) => ErrorStateCard(
          title: 'Could not load project',
          details: '$err',
          onRetry: () => ref.invalidate(curriculumProvider),
        ),
        data: (bundle) {
          final project = bundle.projectById[widget.projectId];
          if (project == null) {
            return ErrorStateCard(
              title: 'Capstone not found',
              details: 'Unknown project "${widget.projectId}".',
              onRetry: () => context.go('/projects'),
            );
          }

          final state = learnerAsync.value ?? const LearnerState();
          final progress = state.projectProgress[project.id];
          _hydrate(project, progress);

          final completedMilestones =
              progress?.completedMilestoneIds.toSet() ?? const <String>{};
          final completedSecurity =
              progress?.completedSecurityChecks.toSet() ?? const <String>{};
          final notifier = ref.read(learnerStateProvider.notifier);

          return SingleChildScrollView(
            child: AppPageContainer(
              maxWidth: AppTokens.maxReadingWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(label: Text('Capstone ${project.number}')),
                      for (final mId in project.relatedModuleIds)
                        if (bundle.moduleById[mId] != null)
                          ActionChip(
                            label: Text(
                              'Module ${bundle.moduleById[mId]!.number}',
                            ),
                            onPressed: () => context.go('/roadmap?module=$mId'),
                          ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(project.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    project.tagline,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(project.brief, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 18),

                  // Architecture Diagram (horizontally scrolling code surface)
                  CodeSnippetCard(
                    example: CodeExample(
                      title: 'Reference System Architecture Diagram',
                      description:
                          'Scroll horizontally if needed; verify every trust and validation boundary.',
                      language: 'diagram',
                      code: project.architectureDiagram,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Requirements
                  _ProjectSection(
                    title: 'Engineering Requirements',
                    icon: Icons.rule_rounded,
                    child: _BulletList(items: project.requirements),
                  ),
                  const SizedBox(height: 14),

                  // Staged Milestones (Interactive)
                  _ProjectSection(
                    title:
                        'Milestones (${completedMilestones.length}/${project.milestones.length})',
                    icon: Icons.flag_circle_outlined,
                    child: Column(
                      children: [
                        for (final milestone in project.milestones) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: completedMilestones.contains(milestone.id)
                                  ? colors.primaryContainer.withValues(
                                      alpha: 0.25,
                                    )
                                  : colors.surfaceContainerHighest.withValues(
                                      alpha: 0.35,
                                    ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radiusSm,
                                ),
                                side: BorderSide(
                                  color:
                                      completedMilestones.contains(milestone.id)
                                      ? colors.primary
                                      : colors.outline,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      value: completedMilestones.contains(
                                        milestone.id,
                                      ),
                                      onChanged: (_) =>
                                          notifier.toggleProjectMilestone(
                                            project.id,
                                            milestone.id,
                                            projectTitle: project.title,
                                          ),
                                      title: Text(
                                        '${milestone.stage}: ${milestone.title}',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      subtitle: Text(
                                        milestone.description,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Verification Checks:',
                                            style: theme.textTheme.labelMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          for (final check
                                              in milestone.verificationChecks)
                                            Text(
                                              '• $check',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Deliverables & Test Cases
                  _ProjectSection(
                    title: 'Deliverables',
                    icon: Icons.inventory_2_outlined,
                    child: _BulletList(items: project.deliverables),
                  ),
                  const SizedBox(height: 14),
                  _ProjectSection(
                    title: 'Test Cases to Automate',
                    icon: Icons.science_outlined,
                    child: _BulletList(items: project.testCases),
                  ),
                  const SizedBox(height: 14),

                  // Assessment Rubric
                  _ProjectSection(
                    title: 'Assessment Rubric',
                    icon: Icons.grading_rounded,
                    child: Column(
                      children: [
                        for (final r in project.rubric) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outline),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSm,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.criterion,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Emerging: ${r.emerging}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Production-Ready: ${r.productionReady}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Eval Dataset Ideas + Interactive Security Checklist
                  _ProjectSection(
                    title: 'Evaluation Dataset Guide',
                    icon: Icons.dataset_outlined,
                    child: _BulletList(items: project.evalDatasetSuggestions),
                  ),
                  const SizedBox(height: 14),
                  _ProjectSection(
                    title:
                        'Security Verification Checklist (${completedSecurity.length}/${project.securityChecklist.length})',
                    icon: Icons.shield_outlined,
                    child: Column(
                      children: [
                        for (final item in project.securityChecklist)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: completedSecurity.contains(item),
                            onChanged: (_) => notifier
                                .toggleProjectSecurityCheck(project.id, item),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Learner GitHub Repo, Honest Measured Metrics & Reflection
                  _ProjectSection(
                    title: 'Your Repository, Measured Metrics & Reflection',
                    icon: Icons.edit_document,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _repoController,
                          decoration: InputDecoration(
                            labelText: 'GitHub Repository URL',
                            hintText: 'https://github.com/<user>/<repo>',
                            suffixIcon: IconButton(
                              tooltip: 'Open repository URL',
                              icon: const Icon(Icons.open_in_new_rounded),
                              onPressed: () {
                                final url = _repoController.text.trim();
                                if (url.isNotEmpty) {
                                  openExternalUrl(context, url);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Measured Results Observed on Your Test Set',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Leave blank until you run your own evaluation harness—never enter synthetic estimates as measured benchmarks.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        for (final tmpl in project.metricTemplates) ...[
                          TextField(
                            controller: _metricControllers[tmpl.id],
                            decoration: InputDecoration(
                              labelText: '${tmpl.label} (${tmpl.unit})',
                              hintText: tmpl.hint,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 6),
                        TextField(
                          controller: _reflectionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Reflection & Lessons Learned',
                            hintText:
                                'Document real bugs encountered (e.g., localhost/Docker issues, edge cases), architecture trade-offs, and v2 improvements…',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _saveLearnerDetails(project),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text(
                              'Save Repo, Metrics & Reflection',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Portfolio README Template
                  Card(
                    child: ExpansionTile(
                      title: const Text('Portfolio Case-Study README Template'),
                      subtitle: const Text(
                        'Honest template ready for your repository README',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        CodeSnippetCard(
                          example: CodeExample(
                            title: 'README.md Case Study Template',
                            description:
                                'Replace bracketed placeholders only with genuinely tested results.',
                            language: 'markdown',
                            code: project.portfolioReadmeTemplate,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: project.portfolioReadmeTemplate,
                                ),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Portfolio README template copied to clipboard.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Markdown Template'),
                          ),
                        ),
                      ],
                    ),
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
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({
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

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
