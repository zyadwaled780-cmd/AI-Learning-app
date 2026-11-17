import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/curriculum_models.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/study_planner_engine.dart';
import '../../../core/widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const List<String> _goalPresets = [
    'Master networking, HTTP, localhost & deployment',
    'Build reliable Python & FastAPI services',
    'Enforce strict Pydantic schemas on AI outputs',
    'Connect n8n workflows cleanly to Python backends',
    'Learn LangChain, LangGraph & RAG guardrails',
    'Ship honest evaluated portfolio capstones',
  ];

  static const List<String> _experiencePresets = [
    'Total beginner (no coding or automation background)',
    'Know basic n8n workflows, weak on APIs & HTTP/localhost',
    'Write scripts occasionally, new to production AI & FastAPI',
    'Software developer transitioning into AI & automation systems',
  ];

  bool _initialized = false;
  EntryPath _entryPath = EntryPath.n8nUser;
  String _selectedExperience =
      'Know basic n8n workflows, weak on APIs & HTTP/localhost';
  final TextEditingController _customExperienceController =
      TextEditingController();
  double _weeklyHours = 6;
  final Set<int> _studyDays = {1, 3, 5, 6};
  final Set<String> _goals = {
    'Master networking, HTTP, localhost & deployment',
    'Build reliable Python & FastAPI services',
    'Connect n8n workflows cleanly to Python backends',
  };

  @override
  void dispose() {
    _customExperienceController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile(LearnerProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _entryPath = profile.entryPath;
    _weeklyHours = profile.weeklyStudyHours.toDouble().clamp(1, 30);
    if (profile.studyDays.isNotEmpty) {
      _studyDays
        ..clear()
        ..addAll(profile.studyDays);
    }
    if (profile.learningGoals.isNotEmpty) {
      _goals
        ..clear()
        ..addAll(profile.learningGoals);
    }
    if (_experiencePresets.contains(profile.experienceSummary)) {
      _selectedExperience = profile.experienceSummary;
    } else if (profile.experienceSummary.trim().isNotEmpty &&
        profile.experienceSummary != 'Starting fresh') {
      _selectedExperience = '';
      _customExperienceController.text = profile.experienceSummary;
    }
  }

  String get _effectiveExperience {
    final custom = _customExperienceController.text.trim();
    if (custom.isNotEmpty) return custom;
    if (_selectedExperience.isNotEmpty) return _selectedExperience;
    return _entryPath == EntryPath.zero
        ? 'Starting from zero'
        : 'Uses n8n; exploring AI systems engineering';
  }

  Future<void> _saveAndFinish({required bool runDiagnostic}) async {
    final days = _studyDays.toList()..sort();
    final notifier = ref.read(learnerStateProvider.notifier);

    if (runDiagnostic) {
      await notifier.completeOnboarding(
        entryPath: EntryPath.n8nUser,
        experienceSummary: _effectiveExperience,
        weeklyStudyHours: _weeklyHours.round(),
        studyDays: days.isEmpty ? const [1, 3, 5] : days,
        learningGoals: _goals.toList(growable: false),
        suggestedStartModuleId: 'm03',
        diagnosticResult: ref
            .read(learnerStateProvider)
            .value
            ?.profile
            .diagnosticResult,
      );
      if (mounted) {
        context.go('/diagnostic');
      }
      return;
    }

    await notifier.completeOnboarding(
      entryPath: EntryPath.zero,
      experienceSummary: _effectiveExperience,
      weeklyStudyHours: _weeklyHours.round(),
      studyDays: days.isEmpty ? const [1, 3, 5] : days,
      learningGoals: _goals.toList(growable: false),
      suggestedStartModuleId: 'm01',
    );
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _skipToDashboard() async {
    final notifier = ref.read(learnerStateProvider.notifier);
    final current =
        ref.read(learnerStateProvider).value ?? const LearnerState();
    await notifier.completeOnboarding(
      entryPath: current.profile.entryPath,
      experienceSummary: current.profile.experienceSummary,
      weeklyStudyHours: current.profile.weeklyStudyHours,
      studyDays: current.profile.studyDays,
      learningGoals: current.profile.learningGoals,
      suggestedStartModuleId: current.profile.suggestedStartModuleId,
      diagnosticResult: current.profile.diagnosticResult,
    );
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    if (learnerAsync.hasValue) {
      _hydrateFromProfile(learnerAsync.requireValue.profile);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Dashboard',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _skipToDashboard,
        ),
        title: const Text('Learning Path Setup'),
        actions: [
          TextButton(
            onPressed: _skipToDashboard,
            child: const Text('Explore Dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const LoadingScaffoldBody(),
        error: (err, _) => ErrorStateCard(
          title: 'Could not load curriculum',
          details: '$err',
          onRetry: () => ref.invalidate(curriculumProvider),
        ),
        data: (bundle) {
          final existingDiagnostic =
              learnerAsync.value?.profile.diagnosticResult;
          final suggestedModule = existingDiagnostic != null
              ? bundle.moduleById[existingDiagnostic.suggestedStartModuleId]
              : null;

          return SingleChildScrollView(
            child: AppPageContainer(
              maxWidth: AppTokens.maxReadingWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AI Automation Engineer: Zero to Hero',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure your starting path and weekly study estimate. You stay completely in control—even if a diagnostic suggests jumping ahead, no skipped lesson is ever falsely marked mastered.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Entry Path Selection
                  Text(
                    '1. Choose your entry path',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 600;
                      final zeroCard = _EntryPathCard(
                        title: 'Start from zero',
                        subtitle:
                            'Begin at Module 1 (Engineering Foundations) through Terminal, Git, Networking, Python, and Production AI.',
                        badge: 'Recommended for beginners',
                        icon: Icons.rocket_launch_outlined,
                        selected: _entryPath == EntryPath.zero,
                        onTap: () =>
                            setState(() => _entryPath = EntryPath.zero),
                      );
                      final n8nCard = _EntryPathCard(
                        title: 'I already use n8n',
                        subtitle:
                            'Take a 10-question diagnostic on HTTP, localhost, Python, Pydantic, RAG & Cloudflare to target weak areas.',
                        badge: 'Suggested path without fake mastery',
                        icon: Icons.account_tree_outlined,
                        selected: _entryPath == EntryPath.n8nUser,
                        onTap: () =>
                            setState(() => _entryPath = EntryPath.n8nUser),
                      );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: zeroCard),
                            const SizedBox(width: 12),
                            Expanded(child: n8nCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          zeroCard,
                          const SizedBox(height: 12),
                          n8nCard,
                        ],
                      );
                    },
                  ),

                  if (existingDiagnostic != null &&
                      suggestedModule != null) ...[
                    const SizedBox(height: 16),
                    _DiagnosticSummaryBanner(
                      result: existingDiagnostic,
                      suggestedModule: suggestedModule,
                      bundle: bundle,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 2. Current Experience
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Current experience',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pick the description closest to where you are starting, or write your own.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final preset in _experiencePresets)
                                ChoiceChip(
                                  label: Text(preset),
                                  selected: _selectedExperience == preset,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedExperience = preset;
                                      _customExperienceController.clear();
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customExperienceController,
                            decoration: const InputDecoration(
                              labelText: 'Or describe your background briefly',
                              hintText:
                                  'e.g. Built n8n Slack bots, confused by Docker localhost & Python APIs',
                            ),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty &&
                                  _selectedExperience.isNotEmpty) {
                                setState(() => _selectedExperience = '');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Weekly Hours & Study Days
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
                                '3. Available study pace',
                                style: theme.textTheme.titleMedium,
                              ),
                              Chip(
                                label: Text(
                                  '${_weeklyHours.round()} hrs / week (estimate)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Used only to build an adjustable Study Planner schedule—time estimates are rough pacing guides, never guarantees.',
                            style: theme.textTheme.bodySmall,
                          ),
                          Slider(
                            value: _weeklyHours,
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '${_weeklyHours.round()} hrs/wk',
                            onChanged: (v) => setState(() => _weeklyHours = v),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preferred learning days',
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
                                  selected: _studyDays.contains(day),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _studyDays.add(day);
                                      } else if (_studyDays.length > 1) {
                                        _studyDays.remove(day);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Learning Goals
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '4. Learning goals',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select the engineering outcomes that matter most right now.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final goal in _goalPresets)
                                FilterChip(
                                  label: Text(goal),
                                  selected: _goals.contains(goal),
                                  onSelected: (sel) {
                                    setState(() {
                                      if (sel) {
                                        _goals.add(goal);
                                      } else {
                                        _goals.remove(goal);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CTA Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _saveAndFinish(runDiagnostic: false),
                        child: Text(
                          _entryPath == EntryPath.zero
                              ? 'Save & Start at Module 1'
                              : 'Skip Diagnostic & Open Dashboard',
                        ),
                      ),
                      if (_entryPath == EntryPath.n8nUser)
                        FilledButton.icon(
                          onPressed: () => _saveAndFinish(runDiagnostic: true),
                          icon: const Icon(Icons.quiz_rounded),
                          label: Text(
                            existingDiagnostic == null
                                ? 'Start 10-Question n8n Diagnostic'
                                : 'Retake n8n Diagnostic Quiz',
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _saveAndFinish(runDiagnostic: false),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Begin From Module 1'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EntryPathCard extends StatelessWidget {
  const _EntryPathCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.35)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: selected ? colors.primary : colors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: theme.textTheme.labelMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticSummaryBanner extends StatelessWidget {
  const _DiagnosticSummaryBanner({
    required this.result,
    required this.suggestedModule,
    required this.bundle,
  });

  final DiagnosticResult result;
  final LearningModule suggestedModule;
  final CurriculumBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weakTitles = result.weakModuleIds
        .map((id) => bundle.moduleById[id])
        .whereType<LearningModule>()
        .map((m) => 'M${m.number}: ${m.title}')
        .toList(growable: false);

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Diagnostic Result: ${result.correctCount}/${result.totalCount}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suggested starting module: Module ${suggestedModule.number} — ${suggestedModule.title}.',
              style: theme.textTheme.bodyMedium,
            ),
            if (weakTitles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Areas flagged for extra practice: ${weakTitles.join(' • ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Note: Modules before Module ${suggestedModule.number} remain unmarked and fully open—never falsely marked mastered.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
