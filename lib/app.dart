import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/config/theme.dart';
import 'package:bhandari_pariwar/config/routes.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class BhandariPariwarApp extends ConsumerWidget {
  const BhandariPariwarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'Bhandari Pariwar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ne'),
      ],
      routerConfig: router,
    );
  }
}
