import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../models/curriculum_models.dart';

class ComparisonCardWidget extends StatelessWidget {
  const ComparisonCardWidget({super.key, required this.card});

  final ComparisonCard card;

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
            Row(
              children: [
                Icon(Icons.compare_arrows_rounded, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(card.title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                if (isWide) {
                  return _WideTable(card: card);
                }
                return _StackedRows(card: card);
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final leftBox = _GuidanceBox(
                  heading: 'Choose ${card.leftTitle} when',
                  body: card.whenToChooseLeft,
                  accent: colors.primary,
                );
                final rightBox = _GuidanceBox(
                  heading: 'Choose ${card.rightTitle} when',
                  body: card.whenToChooseRight,
                  accent: colors.secondary,
                );
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftBox),
                      const SizedBox(width: 12),
                      Expanded(child: rightBox),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [leftBox, const SizedBox(height: 10), rightBox],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WideTable extends StatelessWidget {
  const _WideTable({required this.card});
  final ComparisonCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Aspect', style: theme.textTheme.titleSmall),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    card.leftTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    card.rightTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < card.rows.length; i++) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      card.rows[i].aspect,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      card.rows[i].left,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      card.rows[i].right,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StackedRows extends StatelessWidget {
  const _StackedRows({required this.card});
  final ComparisonCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (final row in card.rows)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.aspect, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '${card.leftTitle}: ${row.left}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${card.rightTitle}: ${row.right}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuidanceBox extends StatelessWidget {
  const _GuidanceBox({
    required this.heading,
    required this.body,
    required this.accent,
  });

  final String heading;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: theme.textTheme.titleSmall?.copyWith(color: accent),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
