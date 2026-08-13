import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MotoSmartApp()));
}

class MotoSmartApp extends ConsumerWidget {
  const MotoSmartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Dealer Enquiry App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
