import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../data/dtc_codes.dart';

class AlertCard extends StatelessWidget {
  final String dtcCode;
  final String? aiExplanation;
  final bool aiLoading;

  const AlertCard({
    super.key,
    required this.dtcCode,
    required this.aiExplanation,
    required this.aiLoading,
  });

  @override
  Widget build(BuildContext context) {
    final info = lookupDtc(dtcCode);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.warm.withValues(alpha: 0.14),
            AppColors.warm.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.warm,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tag('Rule-based', AppColors.warm),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            info.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                    ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        _tag('AI-generated', AppColors.violet),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'For the rider',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (aiLoading)
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Generating explanation…',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      )
                    else
                      SelectableText(
                        aiExplanation ?? '—',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
