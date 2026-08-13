import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design.dart';

/// The one place loading/error/data is rendered for an [AsyncValue], per
/// PLAN_frontend.md's "every screen handles the three states explicitly."
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (error, stackTrace) => _ErrorView(error: error, onRetry: onRetry),
      loading: () => loading ?? const DocLoading(),
    );
  }
}

/// Records being pulled from the file: ruled placeholder sheets that pulse.
///
/// Skeletons in the shape of the content they replace, rather than a spinner in
/// the middle of an empty screen — the page's structure is visible while it
/// loads, so nothing jumps when the data lands.
class DocLoading extends StatefulWidget {
  const DocLoading({super.key, this.rows = 3});

  final int rows;

  @override
  State<DocLoading> createState() => _DocLoadingState();
}

class _DocLoadingState extends State<DocLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: Ds.pagePad(context),
      itemCount: widget.rows,
      separatorBuilder: (_, _) => const SizedBox(height: Ds.s3),
      itemBuilder: (context, i) => FadeTransition(
        // Staggered so the sheets breathe as a set instead of blinking in step.
        opacity: Tween(begin: 0.45, end: 0.9).animate(
          CurvedAnimation(
            parent: _c,
            curve: Interval((i * 0.12).clamp(0.0, 0.5), 1, curve: Curves.easeInOut),
          ),
        ),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: Ds.surfaceRaised,
            borderRadius: BorderRadius.circular(Ds.rMd),
            border: Border.all(color: Ds.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Ds.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Bar(width: 120, height: 12),
                _Bar(width: 200, height: 8),
                _Bar(width: 90, height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Ds.line,
        borderRadius: BorderRadius.circular(Ds.rSm),
      ),
    );
  }
}

/// A rejected form: the problem named, and the way to recover.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Ds.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Ds.s3,
                  vertical: Ds.s1 + 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Ds.alert, width: 1.6),
                  borderRadius: BorderRadius.circular(Ds.rSm),
                ),
                child: Transform.rotate(
                  angle: -0.03,
                  child: Text(
                    'NOT ACCEPTED',
                    style: Ds.label(color: Ds.alert)
                        .copyWith(fontSize: 12, letterSpacing: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: Ds.s4),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: Ds.inkSoft),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: Ds.s5),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
