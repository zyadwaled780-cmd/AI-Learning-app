import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../app/router/responsive_shell.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/models/learner_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/json_transfer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final jsonString = await ref
        .read(learnerStateProvider.notifier)
        .exportProgressJson();
    final downloaded = await downloadJsonFile(
      filename: 'ai_automation_hero_progress_v1.json',
      jsonContent: jsonString,
    );

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          downloaded ? 'Progress Exported & Ready' : 'Export Progress JSON',
        ),
        content: SizedBox(
          width: 520,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    downloaded
                        ? 'Downloaded `ai_automation_hero_progress_v1.json` (schemaVersion: ${LearnerState.currentSchemaVersion}). You can also copy the payload below:'
                        : 'Copy your versioned progress JSON (schemaVersion: ${LearnerState.currentSchemaVersion}) below:',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTokens.codeSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppTokens.codeText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonString));
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Progress JSON copied to clipboard.'),
                ),
              );
            },
            child: const Text('Copy JSON'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportDialog(BuildContext context) async {
    final imported = await showDialog<LearnerState>(
      context: context,
      builder: (_) => const _ImportJsonDialog(),
    );
    if (imported != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported schema v${imported.schemaVersion} (${imported.checkpointProgress.length} checkpoint records).',
          ),
        ),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Learning Progress?'),
        content: const Text(
          'This clears all checkpoint completions, quiz attempts, personal notes, bookmarks, project milestones, and saved settings from local browser/device storage. Export a JSON backup first if you want to keep a copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(learnerStateProvider.notifier).resetProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local progress has been reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);
    final state = learnerAsync.value ?? const LearnerState();
    final notifier = ref.read(learnerStateProvider.notifier);

    return SingleChildScrollView(
      child: AppPageContainer(
        maxWidth: AppTokens.maxReadingWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Settings & Backup', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Customize appearance, update your weekly goal, back up or restore your progress JSON, or review curriculum details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // Appearance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Appearance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Calm navy/slate Material 3 surfaces supporting reduced motion.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AppThemeSetting>(
                      segments: [
                        for (final m in AppThemeSetting.values)
                          ButtonSegment(value: m, label: Text(m.label)),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (sel) =>
                          notifier.setThemeMode(sel.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Weekly Goal & Learning Path
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
                          'Weekly Study Goal',
                          style: theme.textTheme.titleMedium,
                        ),
                        Chip(
                          label: Text(
                            '${state.profile.weeklyStudyHours} hrs/week',
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: state.profile.weeklyStudyHours.toDouble().clamp(
                        1,
                        30,
                      ),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      onChanged: (v) => notifier.updateStudySchedule(
                        weeklyHours: v.round(),
                        studyDays: state.profile.studyDays,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/onboarding'),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text('Update Entry Path & Goals'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/diagnostic'),
                          icon: const Icon(Icons.quiz_outlined, size: 18),
                          label: const Text('Retake n8n Diagnostic'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Progress Export / Import / Reset
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Portability & Reset',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All progress persists locally on this browser/device using schema v${LearnerState.currentSchemaVersion}. Export regular JSON backups or transfer across machines cleanly.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _handleExport(context, ref),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Export Progress JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _handleImportDialog(context),
                          icon: const Icon(Icons.upload_rounded),
                          label: const Text('Import Progress JSON'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          onPressed: () => _confirmReset(context, ref),
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Reset Progress'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // About & Content Source Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About & Content Sources',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Automation Engineer: Zero to Hero (v1.0.0)',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Built completely offline-ready: zero backend required, zero paid accounts, zero model API keys required to study and track progress.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (curriculumAsync.value != null)
                      Text(
                        'Loaded Curriculum: ${curriculumAsync.value!.modules.length} modules · ${curriculumAsync.value!.checkpoints.length} checkpoints · ${curriculumAsync.value!.projects.length} capstones · ${curriculumAsync.value!.glossary.length} glossary terms · Content reviewed ${curriculumAsync.value!.lastReviewedAt}.',
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Official references cited across modules include MDN Web Docs, Python 3 Docs, FastAPI, Pydantic v2, Pytest, Docker Networking, n8n Docs, LangChain / LangGraph Docs, OWASP LLM Top 10, and Cloudflare Zero Trust / Tunnel / Workers Docs.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _ImportJsonDialog extends ConsumerStatefulWidget {
  const _ImportJsonDialog();

  @override
  ConsumerState<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends ConsumerState<_ImportJsonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMsg;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runImport() async {
    if (_isImporting) return;
    setState(() {
      _isImporting = true;
      _errorMsg = null;
    });
    try {
      final bundle = ref.read(curriculumProvider).value;
      final parsed = await ref
          .read(learnerStateProvider.notifier)
          .importProgressJson(_controller.text, curriculum: bundle);
      if (!mounted) return;
      Navigator.of(context).pop(parsed);
    } on ProgressImportException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.message;
        _isImporting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Import failed: $e';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Import Progress JSON'),
      content: SizedBox(
        width: 520,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paste exported JSON or upload a `.json` backup file. Payloads are strictly schema-validated before overwriting local progress.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                if (supportsBrowserFileTransfer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: _isImporting
                          ? null
                          : () async {
                              final picked = await pickJsonFileContent();
                              if (!mounted || picked == null) return;
                              setState(() {
                                _controller.text = picked;
                                _errorMsg = null;
                              });
                            },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Choose .json File From Computer'),
                    ),
                  ),
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '{"schemaVersion": 1, ...}',
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMsg!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isImporting ? null : _runImport,
          child: const Text('Validate & Import'),
        ),
      ],
    );
  }
}
