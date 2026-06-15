import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TutorPortalApp extends ConsumerWidget {
  const TutorPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Tutor Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Dark mode isn't designed yet (all mockups are light; the Profile toggle
      // is a stub). Pin to light so the brand coral renders identically on the
      // simulator, a physical phone in dark mode, and the web. Switch to
      // ThemeMode.system once a real dark palette + theme controller land.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
