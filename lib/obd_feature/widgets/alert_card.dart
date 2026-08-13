import 'package:flutter/material.dart';

import '../../core/config/design.dart';
import '../data/dtc_codes.dart';

/// A fault, written up as a defect note on the inspection sheet.
///
/// Two halves, honestly labelled: the code and its standard meaning came from
/// the on-device rule engine, and the plain-language paragraph came from the
/// model. Keeping them visibly separate is the point — a rider should be able to
/// tell which part is a standard and which part is a machine explaining it.
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
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: Ds.s3),
      decoration: BoxDecoration(
        color: Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(color: Ds.caution.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The code itself, set as a plate: it is an identifier, and this is the
          // register identifiers live in throughout the app.
          Container(
            padding: const EdgeInsets.all(Ds.s3),
            decoration: BoxDecoration(
              color: Ds.caution.withValues(alpha: 0.16),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Ds.rMd - 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Ds.ink,
                    borderRadius: BorderRadius.circular(Ds.rSm),
                  ),
                  child: Text(
                    info.code,
                    style: Ds.figure(12, color: const Color(0xFFF7F5EF)),
                  ),
                ),
                const SizedBox(width: Ds.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAGNOSED BY RULE ENGINE · SAE',
                        style: Ds.label(color: Ds.caution)
                            .copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.description,
                        style: text.bodyMedium?.copyWith(color: Ds.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Ds.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: Ds.info),
                    const SizedBox(width: 5),
                    Text(
                      'EXPLAINED FOR THE RIDER',
                      style: Ds.label(color: Ds.info)
                          .copyWith(fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: Ds.s2),
                if (aiLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Ds.info,
                        ),
                      ),
                      const SizedBox(width: Ds.s2),
                      Text('Reading the codes…', style: text.bodySmall),
                    ],
                  )
                else
                  Text(
                    aiExplanation ?? 'No explanation available yet.',
                    style: text.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
