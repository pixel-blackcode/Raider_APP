import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/push/push_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/notifications/presentation/notification_bell.dart';
import '../features/sos/presentation/sos_banner.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// Widget racine de Rider Group.
class RiderGroupApp extends ConsumerStatefulWidget {
  const RiderGroupApp({super.key});

  @override
  ConsumerState<RiderGroupApp> createState() => _RiderGroupAppState();
}

class _RiderGroupAppState extends ConsumerState<RiderGroupApp> {
  @override
  void initState() {
    super.initState();
    // Notifications push : sans effet si Firebase n'est pas configuré.
    ref.read(pushRegistrarProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Alertes SOS reçues : bandeau visible sur tous les écrans.
      builder: (context, child) => SosAlertsOverlay(
        child: NotificationSoundListener(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
