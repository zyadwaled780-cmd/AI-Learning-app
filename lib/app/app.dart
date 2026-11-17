import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/models/learner_state.dart';
import '../core/providers/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AiAutomationHeroApp extends ConsumerWidget {
  const AiAutomationHeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final learnerAsync = ref.watch(learnerStateProvider);
    final setting = learnerAsync.value?.themeMode ?? AppThemeSetting.system;

    final themeMode = switch (setting) {
      AppThemeSetting.system => ThemeMode.system,
      AppThemeSetting.light => ThemeMode.light,
      AppThemeSetting.dark => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: 'AI Automation Engineer: Zero to Hero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
