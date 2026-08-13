import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
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
      appBar: AppBar(title: const Text('Lead detail')),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lead.customerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (lead.aiIntent != null)
                      IntentBadge(intent: lead.aiIntent!)
                    else
                      UnclassifiedBadge(onTap: () => _classify(context, ref)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 15, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(lead.mobile, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _changeStatus(context, ref),
                  child: Row(
                    children: [
                      StatusChip(status: lead.status),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 14, color: Colors.black38),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Source', value: lead.source.label),
                _InfoRow(label: 'Interested model', value: bikeName?.isNotEmpty == true ? bikeName!.first : '—'),
                _InfoRow(label: 'Current bike', value: lead.currentBike ?? '—'),
                _InfoRow(
                  label: 'Tentative purchase',
                  value: lead.tentativePurchaseDate == null
                      ? '—'
                      : DateFormat('d MMM yyyy').format(lead.tentativePurchaseDate!),
                ),
                _InfoRow(label: 'Notes', value: lead.notes?.isNotEmpty == true ? lead.notes! : '—'),
              ],
            ),
          ),
        ),
        if (lead.convertedCustomerId != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.statusClosedWon.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.verified, color: AppColors.statusClosedWon),
              title: const Text('Converted to customer'),
              subtitle: Text('Customer ID: ${lead.convertedCustomerId}'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Follow-ups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addFollowup(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
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
        const SizedBox(height: 24),
        if (canConvert)
          OutlinedButton.icon(
            onPressed: () => context.push('/dealer/leads/${lead.id}/convert'),
            icon: const Icon(Icons.person_add),
            label: const Text('Convert to customer'),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
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
        ? AppColors.statusClosedWon
        : followup.isOverdue
            ? AppColors.hot
            : followup.isDueToday
                ? AppColors.warm
                : AppColors.cold;
    final tagText = followup.completed
        ? 'Done'
        : followup.isOverdue
            ? 'Overdue'
            : followup.isDueToday
                ? 'Today'
                : DateFormat('d MMM').format(followup.scheduledDate);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Checkbox(
          value: followup.completed,
          onChanged: followup.completed ? null : (_) => onMarkDone(),
        ),
        title: Text(
          followup.nextAction,
          style: TextStyle(
            decoration: followup.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: followup.outcomeNote == null ? null : Text(followup.outcomeNote!),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(tagText, style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.w600)),
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
