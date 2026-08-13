import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'app_visuals.dart';

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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassPanel(
          style: GlassStyle.soft,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          glow: AppColors.yamahaBlue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconWell(icon: icon, size: 72, iconSize: 32, filled: true),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted, height: 1.5),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 22),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
