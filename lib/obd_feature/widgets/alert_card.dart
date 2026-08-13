import 'package:flutter/material.dart';
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

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag('Rule-based', Colors.orange),
              const SizedBox(width: 6),
              Text(info.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(info.description, style: const TextStyle(fontSize: 13)),
          const Divider(height: 20),
          Row(
            children: [
              _tag('AI-generated', Colors.deepPurple),
              const SizedBox(width: 6),
              const Text('For the rider',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 6),
          if (aiLoading)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Generating explanation…', style: TextStyle(fontSize: 13)),
              ],
            )
          else
            Text(
              aiExplanation ?? '—',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
