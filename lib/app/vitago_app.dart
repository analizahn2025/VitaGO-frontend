import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/routing/app_router.dart';
import 'package:vitago_app/app/theme/app_theme.dart';

class VitaGoApp extends ConsumerWidget {
  const VitaGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forMode(config.mode),
      routerConfig: router,
    );
  }
}
