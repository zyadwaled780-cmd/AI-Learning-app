import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../core/models/learner_state.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../features/bookmarks_notes/presentation/bookmarks_notes_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/glossary/presentation/glossary_screen.dart';
import '../../features/lesson/presentation/lesson_detail_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/planner/presentation/study_planner_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/roadmap/presentation/roadmap_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'responsive_shell.dart';

class _RouterRefreshListenable extends ChangeNotifier {
  void triggerRefresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refreshNotifier = _RouterRefreshListenable();

  ref.listen<AsyncValue<LearnerState>>(
    learnerStateProvider,
    (_, _) => refreshNotifier.triggerRefresh(),
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final learnerAsync = ref.read(learnerStateProvider);
      if (!learnerAsync.hasValue) {
        return null;
      }
      final onboardingCompleted =
          learnerAsync.requireValue.profile.onboardingCompleted;
      if (!onboardingCompleted && state.matchedLocation == '/') {
        return '/onboarding';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorStateCard(
          title: 'Route not found',
          details: 'No view matched "${state.uri}".',
          onRetry: () => context.go('/'),
        ),
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ResponsiveShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/roadmap',
                builder: (context, state) => RoadmapScreen(
                  initialModuleId: state.uri.queryParameters['module'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':projectId',
                    builder: (context, state) => ProjectDetailScreen(
                      projectId: state.pathParameters['projectId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                builder: (context, state) => const StudyPlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/glossary',
                builder: (context, state) => GlossaryScreen(
                  initialQuery: state.uri.queryParameters['q'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const BookmarksNotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/diagnostic',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const QuizScreen(mode: QuizScreenMode.diagnostic),
      ),
      GoRoute(
        path: '/lesson/:checkpointId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LessonDetailScreen(
          checkpointId: state.pathParameters['checkpointId']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:checkpointId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => QuizScreen(
          mode: QuizScreenMode.checkpoint,
          checkpointId: state.pathParameters['checkpointId']!,
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});
