// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../models/curriculum_models.dart';
import '../models/learner_state.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final CheckpointStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, icon) = switch (status) {
      CheckpointStatus.completed => (
        (isDark ? AppTokens.darkSuccess : AppTokens.lightSuccess).withValues(
          alpha: 0.14,
        ),
        isDark ? AppTokens.darkSuccess : AppTokens.lightSuccess,
        Icons.check_circle_rounded,
      ),
      CheckpointStatus.inProgress => (
        Theme.of(context).colorScheme.primaryContainer,
        Theme.of(context).colorScheme.primary,
        Icons.timelapse_rounded,
      ),
      CheckpointStatus.notStarted => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.radio_button_unchecked_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final DifficultyLevel difficulty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final fg = switch (difficulty) {
      DifficultyLevel.beginner =>
        isDark ? AppTokens.darkSuccess : AppTokens.lightSuccess,
      DifficultyLevel.intermediate => colors.primary,
      DifficultyLevel.advanced =>
        isDark ? AppTokens.darkWarning : AppTokens.lightWarning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
        color: fg.withValues(alpha: 0.08),
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class MasteryPillarsRow extends StatelessWidget {
  const MasteryPillarsRow({super.key, required this.progress});

  final CheckpointProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _PillarChip(
          label: 'Lesson read',
          done: p?.lessonRead ?? false,
          icon: Icons.menu_book_rounded,
        ),
        _PillarChip(
          label: 'Check passed',
          done: p?.quizPassed ?? false,
          icon: Icons.quiz_rounded,
        ),
        _PillarChip(
          label: 'Practice done',
          done: p?.practiceCompleted ?? false,
          icon: Icons.build_rounded,
        ),
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({
    required this.label,
    required this.done,
    required this.icon,
  });

  final String label;
  final bool done;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final activeColor = isDark ? AppTokens.darkSuccess : AppTokens.lightSuccess;
    final fg = done ? activeColor : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? activeColor.withValues(alpha: 0.12)
            : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? activeColor.withValues(alpha: 0.4) : colors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_rounded : icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
