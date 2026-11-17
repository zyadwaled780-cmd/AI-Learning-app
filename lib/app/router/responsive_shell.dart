// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/curriculum_models.dart';
import '../../core/models/learner_state.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/search_engine.dart';
import '../theme/app_tokens.dart';

class _NavDestination {
  const _NavDestination({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const List<_NavDestination> _allDestinations = [
  _NavDestination(
    branchIndex: 0,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    route: '/',
  ),
  _NavDestination(
    branchIndex: 1,
    label: 'Roadmap',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
    route: '/roadmap',
  ),
  _NavDestination(
    branchIndex: 2,
    label: 'Projects',
    icon: Icons.workspaces_outlined,
    selectedIcon: Icons.workspaces_rounded,
    route: '/projects',
  ),
  _NavDestination(
    branchIndex: 3,
    label: 'Planner',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
    route: '/planner',
  ),
  _NavDestination(
    branchIndex: 4,
    label: 'Glossary',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
    route: '/glossary',
  ),
  _NavDestination(
    branchIndex: 5,
    label: 'Notes',
    icon: Icons.bookmarks_outlined,
    selectedIcon: Icons.bookmarks_rounded,
    route: '/notes',
  ),
  _NavDestination(
    branchIndex: 6,
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: '/settings',
  ),
];

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _selectBranch(BuildContext context, int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppTokens.desktopBreakpoint;
    final curriculumAsync = ref.watch(curriculumProvider);
    final learnerAsync = ref.watch(learnerStateProvider);

    final currentDest = _allDestinations.firstWhere(
      (d) => d.branchIndex == navigationShell.currentIndex,
      orElse: () => _allDestinations.first,
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              selectedBranch: navigationShell.currentIndex,
              onSelectBranch: (i) => _selectBranch(context, i),
              curriculum: curriculumAsync.value,
              learnerState: learnerAsync.value,
              onSearch: () => _openGlobalSearch(context),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Mobile layout with concise 5-item bottom NavigationBar (`More` reveals Planner/Glossary/Settings/Onboarding).
    final mobileSelected = switch (navigationShell.currentIndex) {
      0 => 0,
      1 => 1,
      2 => 2,
      5 => 3,
      _ => 4,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(currentDest.label),
        actions: [
          IconButton(
            tooltip: 'Search lessons, glossary & notes',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _openGlobalSearch(context),
          ),
          IconButton(
            tooltip: 'Learning Path & n8n Diagnostic',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.push('/onboarding'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileSelected,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _selectBranch(context, 0);
            case 1:
              _selectBranch(context, 1);
            case 2:
              _selectBranch(context, 2);
            case 3:
              _selectBranch(context, 5);
            case 4:
              _showMobileMoreSheet(context);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'Roadmap',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspaces_outlined),
            selectedIcon: Icon(Icons.workspaces_rounded),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_open_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Future<void> _showMobileMoreSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tools & Settings',
                  style: Theme.of(sheetCtx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Study Planner'),
                  subtitle: const Text('Estimated weekly pace & schedule'),
                  selected: navigationShell.currentIndex == 3,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _selectBranch(context, 3);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Engineering Glossary'),
                  subtitle: const Text('Plain-English & technical definitions'),
                  selected: navigationShell.currentIndex == 4,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _selectBranch(context, 4);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Settings & Export'),
                  subtitle: const Text('Theme, backup JSON, reset'),
                  selected: navigationShell.currentIndex == 6,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _selectBranch(context, 6);
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  leading: const Icon(Icons.quiz_outlined),
                  title: const Text('Onboarding & n8n Diagnostic'),
                  subtitle: const Text(
                    'Review entry path or retake diagnostic',
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/onboarding');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGlobalSearch(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const GlobalSearchDialog(),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedBranch,
    required this.onSelectBranch,
    required this.curriculum,
    required this.learnerState,
    required this.onSearch,
  });

  final int selectedBranch;
  final ValueChanged<int> onSelectBranch;
  final CurriculumBundle? curriculum;
  final LearnerState? learnerState;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = (curriculum != null && learnerState != null)
        ? ProgressSummary.compute(bundle: curriculum!, state: learnerState!)
        : null;

    return SizedBox(
      width: 248,
      child: Material(
        color: colors.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.hub_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Automation',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'Zero to Hero',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: 'Open curriculum search',
                  child: InkWell(
                    onTap: onSearch,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search curriculum…',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: _allDestinations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, idx) {
                      final d = _allDestinations[idx];
                      final selected = d.branchIndex == selectedBranch;
                      return _SidebarItem(
                        icon: selected ? d.selectedIcon : d.icon,
                        label: d.label,
                        selected: selected,
                        onTap: () => onSelectBranch(d.branchIndex),
                      );
                    },
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Confirmed Mastery',
                                style: theme.textTheme.labelMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${summary.completedCount}/${summary.totalCheckpoints}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: summary.completionRatio,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push('/onboarding'),
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('Path & Diagnostic'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: AnimatedContainer(
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 160),
          ),
          curve: AppMotion.curve(context),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.65)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.primary : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  SearchResultType? _filterType;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(curriculumProvider).value;
    final learnerState =
        ref.watch(learnerStateProvider).value ?? const LearnerState();

    final query = _controller.text;
    final hits = bundle == null
        ? const <SearchHit>[]
        : SearchEngine.search(
            bundle: bundle,
            learnerState: learnerState,
            query: query,
            types: _filterType == null ? null : {_filterType!},
          );

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText:
                            'Search checkpoints, glossary, capstones, or notes…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close search',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filterType == null,
                      onSelected: (_) => setState(() => _filterType = null),
                    ),
                    for (final type in SearchResultType.values) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _filterType == type,
                        onSelected: (_) => setState(() => _filterType = type),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: query.trim().isEmpty
                    ? Center(
                        child: Text(
                          'Try searching "localhost", "Pydantic", "interrupt", "Cloudflare Tunnel", or your personal notes.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : hits.isEmpty
                    ? Center(
                        child: Text(
                          'No matches found for "${query.trim()}".',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        itemCount: hits.length > 40 ? 40 : hits.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final hit = hits[i];
                          return ListTile(
                            leading: _hitIcon(hit.type),
                            title: Text(
                              hit.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              hit.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Chip(label: Text(hit.type.label)),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go(hit.route);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _hitIcon(SearchResultType type) {
    return switch (type) {
      SearchResultType.module => const Icon(Icons.folder_outlined),
      SearchResultType.checkpoint => const Icon(Icons.article_outlined),
      SearchResultType.glossary => const Icon(Icons.menu_book_outlined),
      SearchResultType.project => const Icon(Icons.workspaces_outline),
      SearchResultType.note => const Icon(Icons.edit_note_rounded),
    };
  }
}

class AppPageContainer extends StatelessWidget {
  const AppPageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppTokens.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: width >= 680 ? 28 : 16,
      vertical: width >= 680 ? 24 : 16,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding ?? defaultPadding, child: child),
      ),
    );
  }
}
