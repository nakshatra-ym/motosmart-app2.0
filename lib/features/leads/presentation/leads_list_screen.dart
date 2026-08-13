import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/lead.dart';
import '../../test_rides/presentation/test_rides_tab.dart';
import '../data/leads_providers.dart';
import '../widgets/lead_card.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(leadsListProvider);
    final selectedTab = ref.watch(leadTabProvider);
    final segment = ref.watch(leadsSegmentProvider);
    final isLeadsSegment = segment == LeadsSegment.leads;

    return Scaffold(
      appBar: AppBar(title: const Text('Leads')),
      floatingActionButton: isLeadsSegment
          ? FloatingActionButton(
              onPressed: () => context.push('/dealer/leads/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<LeadsSegment>(
              segments: const [
                ButtonSegment(
                  value: LeadsSegment.leads,
                  label: Text('Leads'),
                  icon: Icon(Icons.groups_outlined),
                ),
                ButtonSegment(
                  value: LeadsSegment.testRides,
                  label: Text('Test rides'),
                  icon: Icon(Icons.two_wheeler_outlined),
                ),
              ],
              selected: {segment},
              onSelectionChanged: (selection) =>
                  ref.read(leadsSegmentProvider.notifier).state = selection.first,
            ),
          ),
          if (isLeadsSegment) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or mobile number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(leadSearchQueryProvider.notifier).state = '';
                          },
                        ),
                ),
                onChanged: (value) => ref.read(leadSearchQueryProvider.notifier).state = value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TabChip(
                      label: 'All',
                      selected: selectedTab == LeadTab.all,
                      onSelected: () => ref.read(leadTabProvider.notifier).state = LeadTab.all,
                    ),
                    _TabChip(
                      label: 'New',
                      selected: selectedTab == LeadTab.newLead,
                      onSelected: () => ref.read(leadTabProvider.notifier).state = LeadTab.newLead,
                    ),
                    _TabChip(
                      label: 'Follow-up',
                      selected: selectedTab == LeadTab.followUp,
                      onSelected: () => ref.read(leadTabProvider.notifier).state = LeadTab.followUp,
                    ),
                    _TabChip(
                      label: 'Closed',
                      selected: selectedTab == LeadTab.closed,
                      onSelected: () => ref.read(leadTabProvider.notifier).state = LeadTab.closed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncValueWidget<List<Lead>>(
                value: leads,
                onRetry: () => ref.invalidate(leadsListProvider),
                data: (data) {
                  if (data.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No leads here yet',
                      subtitle: 'New enquiries you capture will show up in this list.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(leadsListProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final lead = data[index];
                        return LeadCard(
                          lead: lead,
                          onTap: () => context.push('/dealer/leads/${lead.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ] else
            const Expanded(child: TestRidesTab()),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
