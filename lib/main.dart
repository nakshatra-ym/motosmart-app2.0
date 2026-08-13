import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/app_visuals.dart';
import 'core/widgets/shimmer.dart';

void main() {
  runApp(const ProviderScope(child: MotoSmartApp()));
}

class MotoSmartApp extends ConsumerStatefulWidget {
  const MotoSmartApp({super.key});

  @override
  ConsumerState<MotoSmartApp> createState() => _MotoSmartAppState();
}

class _MotoSmartAppState extends ConsumerState<MotoSmartApp>
    with SingleTickerProviderStateMixin {
  bool _showIntro = true;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    // Brief branded opening — one controller, no assets.
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      await _intro.forward();
      if (mounted) setState(() => _showIntro = false);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Motospot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (_showIntro)
              FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(
                  CurvedAnimation(parent: _intro, curve: Curves.easeInOutCubic),
                ),
                child: const _OpeningSplash(),
              ),
          ],
        );
      },
    );
  }
}

class _OpeningSplash extends StatelessWidget {
  const _OpeningSplash();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvasDeep,
      child: AppPageBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MotospotMark(compact: true),
                const SizedBox(height: 28),
                const SoftLoader(size: 26, color: AppColors.yamahaBlue),
                const SizedBox(height: 14),
                Text(
                  'Booting the dealer OS…',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
