import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/app_visuals.dart';
import 'core/widgets/shimmer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.canvasDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MotoSmartApp()));
}

class MotoSmartApp extends ConsumerStatefulWidget {
  const MotoSmartApp({super.key});

  @override
  ConsumerState<MotoSmartApp> createState() => _MotoSmartAppState();
}

class _MotoSmartAppState extends ConsumerState<MotoSmartApp>
    with TickerProviderStateMixin {
  /// Native splash → branded intro → app. Child is hidden until intro ends
  /// so shimmer/main never flash underneath a fading overlay.
  bool _introVisible = true;
  bool _appVisible = false;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _runIntro();
  }

  Future<void> _runIntro() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    await _enter.forward();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    // Mount the real app under the splash, then fade the splash away.
    setState(() => _appVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 24));
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    setState(() => _introVisible = false);
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Motospot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      color: AppColors.canvasDeep,
      routerConfig: router,
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.canvasDeep,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_appVisible && child != null) child,
              if (_introVisible)
                FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                    CurvedAnimation(parent: _exit, curve: Curves.easeInOut),
                  ),
                  child: _OpeningSplash(enter: _enter),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OpeningSplash extends StatelessWidget {
  const _OpeningSplash({required this.enter});

  final AnimationController enter;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: enter, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: enter, curve: Curves.easeOutCubic));

    return Material(
      color: AppColors.canvasDeep,
      child: AppPageBackground(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MotospotMark(compact: true),
                  const SizedBox(height: 28),
                  const SoftLoader(size: 24, color: AppColors.yamahaBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Starting Motospot',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
