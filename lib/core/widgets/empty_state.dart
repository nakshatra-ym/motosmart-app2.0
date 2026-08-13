import 'package:flutter/material.dart';

import '../config/design.dart';

/// Nothing filed under this heading yet — a blank form rather than a sad icon.
///
/// The empty state is a real state in this world: an unused document with its
/// ruled lines showing, so an empty list reads as "no records", not as a screen
/// that failed to load.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Ds.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The blank form: a bordered sheet with its ruled lines empty.
              Container(
                width: 96,
                height: 76,
                decoration: BoxDecoration(
                  color: Ds.surfaceRaised,
                  borderRadius: BorderRadius.circular(Ds.rMd),
                  border: Border.all(color: Ds.lineStrong),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: Ds.lineStrong),
                    const SizedBox(height: Ds.s2),
                    for (final w in const [40.0, 28.0])
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(width: w, height: 2, color: Ds.line),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Ds.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(color: Ds.inkSoft),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Ds.s1 + 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Ds.s5),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
