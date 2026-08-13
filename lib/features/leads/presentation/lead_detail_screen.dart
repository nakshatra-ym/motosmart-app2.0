import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/design.dart';
import '../../../core/widgets/document.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/intent_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/lead.dart';
import '../../../models/lead_followup.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/leads_providers.dart';

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ENQUIRY RECORD', style: Ds.label()),
            Text('Detail', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
      body: AsyncValueWidget<Lead>(
        value: leadAsync,
        onRetry: () => ref.invalidate(leadDetailProvider(leadId)),
        data: (lead) => _LeadDetailBody(lead: lead),
      ),
    );
  }
}

class _LeadDetailBody extends ConsumerWidget {
  const _LeadDetailBody({required this.lead});

  final Lead lead;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<LeadStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LeadStatus.values
              .map((s) => ListTile(
                    title: Text(s.label),
                    trailing: s == lead.status ? const Icon(Icons.check) : null,
                    onTap: () => context.pop(s),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected == null || selected == lead.status) return;
    try {
      await ref.read(leadsRepositoryProvider).updateLead(lead.id, status: selected);
      invalidateLeadsData(ref, leadId: lead.id);
      ref.invalidate(dashboardSummaryProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _classify(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(leadsRepositoryProvider).classifyLead(lead.id);
      invalidateLeadsData(ref, leadId: lead.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _addFollowup(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_FollowupFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FollowupFormSheet(),
    );
    if (result == null) return;
    try {
      await ref.read(leadsRepositoryProvider).createFollowup(
            lead.id,
            nextAction: result.nextAction,
            scheduledDate: result.scheduledDate,
          );
      invalidateLeadsData(ref, leadId: lead.id);
      ref.invalidate(dashboardSummaryProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _markFollowupDone(
    BuildContext context,
    WidgetRef ref,
    LeadFollowup followup,
  ) async {
    final outcomeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark follow-up as done'),
        content: TextField(
          controller: outcomeController,
          decoration: const InputDecoration(labelText: 'Outcome note (optional)'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => context.pop(true), child: const Text('Mark done')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(leadsRepositoryProvider).updateFollowup(
            followup.id,
            completed: true,
            outcomeNote: outcomeController.text.trim().isEmpty
                ? null
                : outcomeController.text.trim(),
          );
      invalidateLeadsData(ref, leadId: lead.id);
      ref.invalidate(dashboardSummaryProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeModels = ref.watch(bikeModelsProvider).valueOrNull;
    final bikeName = bikeModels == null
        ? null
        : bikeModels.where((b) => b.id == lead.interestedModelId).map((b) => b.displayName);
    final followupsAsync = ref.watch(leadFollowupsProvider(lead.id));
    final canConvert = lead.convertedCustomerId == null && lead.status != LeadStatus.closedWon;

    return ListView(
      padding: Ds.pagePad(context),
      children: [
        DocPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The record's head: who, their number, the AI's stamp, and the
              // status field that can be re-filed.
              DocSheet(
                emphasis: true,
                padding: const EdgeInsets.all(Ds.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            lead.customerName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: Ds.s2),
                        if (lead.aiIntent != null)
                          IntentBadge(intent: lead.aiIntent!)
                        else
                          UnclassifiedBadge(onTap: () => _classify(context, ref)),
                      ],
                    ),
                    const SizedBox(height: Ds.s2),
                    Row(
                      children: [
                        const Icon(Icons.call_outlined, size: 14, color: Ds.inkMuted),
                        const SizedBox(width: 5),
                        Text(
                          lead.mobile,
                          style: Ds.figure(14, weight: 580, color: Ds.inkSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: Ds.s4),
                    // Re-filing the record: the status field is the control.
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => _changeStatus(context, ref),
                        borderRadius: BorderRadius.circular(Ds.rSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              StatusChip(status: lead.status),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined,
                                  size: 14, color: Ds.inkMuted),
                              const SizedBox(width: 4),
                              Text('Change', style: Ds.label()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Ds.s3),
              // The pre-printed field block.
              DocSheet(
                padding: const EdgeInsets.all(Ds.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldGrid(fields: [
                      ('Source', lead.source.label),
                      (
                        'Interested model',
                        bikeName?.isNotEmpty == true ? bikeName!.first : '—'
                      ),
                      ('Current bike', lead.currentBike ?? '—'),
                      (
                        'Tentative purchase',
                        lead.tentativePurchaseDate == null
                            ? '—'
                            : DateFormat('d MMM yyyy')
                                .format(lead.tentativePurchaseDate!)
                      ),
                    ]),
                    if (lead.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: Ds.s4),
                      const Divider(height: 1, color: Ds.line),
                      const SizedBox(height: Ds.s3),
                      DocField(label: 'Notes', value: lead.notes),
                    ],
                  ],
                ),
              ),
              if (lead.convertedCustomerId != null) ...[
                const SizedBox(height: Ds.s3),
                // The endorsement: this enquiry became a customer.
                DocSheet(
                  spine: Ds.positive,
                  tint: Ds.positive.withValues(alpha: 0.06),
                  padding: const EdgeInsets.all(Ds.s4),
                  child: Row(
                    children: [
                      const DocStamp(
                        label: 'Converted',
                        color: Ds.positive,
                        icon: Icons.verified_outlined,
                        filled: true,
                      ),
                      const SizedBox(width: Ds.s3),
                      Expanded(
                        child: Text(
                          'Now an onboarded customer.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Ds.s6),
              DocSectionHeader(
                title: 'Follow-ups',
                trailing: TextButton.icon(
                  onPressed: () => _addFollowup(context, ref),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Schedule'),
                ),
              ),
        AsyncValueWidget<List<LeadFollowup>>(
          value: followupsAsync,
          onRetry: () => ref.invalidate(leadFollowupsProvider(lead.id)),
          data: (followups) {
            if (followups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'No follow-ups yet',
                  subtitle: 'Add one to schedule the next action for this lead.',
                ),
              );
            }
            return Column(
              children: followups
                  .map((f) => _FollowupTile(
                        followup: f,
                        onMarkDone: () => _markFollowupDone(context, ref, f),
                      ))
                  .toList(),
            );
          },
        ),
              const SizedBox(height: Ds.s6),
              if (canConvert)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/dealer/leads/${lead.id}/convert'),
                  icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                  label: const Text('Convert to customer'),
                ),
              const SizedBox(height: Ds.s8),
            ],
          ),
        ),
      ],
    );
  }
}

/// The field block: two columns on a wide window, one on a phone. A form's
/// fields, not a run of label/value rows.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.fields});

  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    final twoUp = MediaQuery.sizeOf(context).width >= 420;
    if (!twoUp) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: Ds.s3),
            DocField(label: fields[i].$1, value: fields[i].$2),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Ds.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DocField(label: fields[i].$1, value: fields[i].$2),
              ),
              const SizedBox(width: Ds.s4),
              Expanded(
                child: i + 1 < fields.length
                    ? DocField(
                        label: fields[i + 1].$1,
                        value: fields[i + 1].$2,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FollowupTile extends StatelessWidget {
  const _FollowupTile({required this.followup, required this.onMarkDone});

  final LeadFollowup followup;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final tagColor = followup.completed
        ? Ds.positive
        : followup.isOverdue
            ? Ds.alert
            : followup.isDueToday
                ? Ds.caution
                : Ds.info;
    final tagText = followup.completed
        ? 'Done'
        : followup.isOverdue
            ? 'Overdue'
            : followup.isDueToday
                ? 'Today'
                : DateFormat('d MMM').format(followup.scheduledDate);

    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Ds.s2),
      child: DocSheet(
        spine: followup.completed ? Ds.line : tagColor,
        padding: const EdgeInsets.fromLTRB(Ds.s2, Ds.s2, Ds.s3, Ds.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The tick box on a job card: ticking it signs the action off.
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: followup.completed,
                onChanged: followup.completed ? null : (_) => onMarkDone(),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Ds.lineStrong, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Ds.rSm),
                ),
                activeColor: Ds.positive,
              ),
            ),
            const SizedBox(width: Ds.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  Text(
                    followup.nextAction,
                    style: text.bodyMedium?.copyWith(
                      color: followup.completed ? Ds.inkMuted : Ds.ink,
                      decoration:
                          followup.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (followup.outcomeNote != null) ...[
                    const SizedBox(height: 3),
                    Text(followup.outcomeNote!, style: text.bodySmall),
                  ],
                  const SizedBox(height: 6),
                ],
              ),
            ),
            const SizedBox(width: Ds.s2),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tagText.toUpperCase(),
                style: Ds.label(color: tagColor).copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowupFormResult {
  const _FollowupFormResult(this.nextAction, this.scheduledDate);
  final String nextAction;
  final DateTime scheduledDate;
}

class _FollowupFormSheet extends StatefulWidget {
  const _FollowupFormSheet();

  @override
  State<_FollowupFormSheet> createState() => _FollowupFormSheetState();
}

class _FollowupFormSheetState extends State<_FollowupFormSheet> {
  final _controller = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add follow-up', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Next action'),
            autofocus: true,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Scheduled date'),
              child: Text(DateFormat('d MMM yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => ElevatedButton(
              onPressed: value.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context)
                      .pop(_FollowupFormResult(value.text.trim(), _date)),
              child: const Text('Save follow-up'),
            ),
          ),
        ],
      ),
    );
  }
}
