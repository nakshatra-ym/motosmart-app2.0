import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/design.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/document.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/lead.dart';
import '../../test_rides/presentation/test_rides_tab.dart';
import '../data/leads_providers.dart';
import '../widgets/lead_card.dart';

/// The lead register: every enquiry this branch holds, filterable by state.
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
    final pad = Ds.pagePad(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('REGISTER', style: Ds.label()),
            Text(
              isLeadsSegment ? 'Enquiries' : 'Test rides',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: isLeadsSegment
          ? FloatingActionButton(
              onPressed: () => context.push('/dealer/leads/new'),
              tooltip: 'Capture an enquiry',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Two registers in one book: enquiries and the test rides that create
          // them. A tab bar rather than a segmented button, since these are
          // sibling views of the same job.
          Padding(
            padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, Ds.s3),
            child: DocPage(
              child: _RegisterSwitch(
                segment: segment,
                onChanged: (value) =>
                    ref.read(leadsSegmentProvider.notifier).state = value,
              ),
            ),
          ),
          if (isLeadsSegment) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad.left),
              child: DocPage(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search a name or number',
                    labelText: null,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(leadSearchQueryProvider.notifier).state = '';
                            },
                          ),
                  ),
                  onChanged: (value) =>
                      ref.read(leadSearchQueryProvider.notifier).state = value,
                ),
              ),
            ),
            const SizedBox(height: Ds.s3),
            // Filing tabs: horizontally scrollable so four labels never
            // overflow, whatever the width.
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad.left),
                children: [
                  for (final entry in const [
                    (LeadTab.all, 'All'),
                    (LeadTab.newLead, 'New'),
                    (LeadTab.followUp, 'Follow-up'),
                    (LeadTab.closed, 'Closed'),
                  ])
                    _FileTab(
                      label: entry.$2,
                      selected: selectedTab == entry.$1,
                      onSelected: () =>
                          ref.read(leadTabProvider.notifier).state = entry.$1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: Ds.s3),
            Expanded(
              child: AsyncValueWidget<List<Lead>>(
                value: leads,
                onRetry: () => ref.invalidate(leadsListProvider),
                data: (data) {
                  if (data.isEmpty) {
                    return const EmptyState(
                      icon: Icons.folder_open_outlined,
                      title: 'Nothing filed here',
                      subtitle:
                          'Enquiries you capture, and leads created by test-ride bookings, appear in this register.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(leadsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        pad.left,
                        0,
                        pad.right,
                        Ds.s12 + Ds.s8,
                      ),
                      itemCount: data.length,
                      separatorBuilder: (_, _) => const SizedBox(height: Ds.s3),
                      itemBuilder: (context, index) => DocPage(
                        child: LeadCard(
                          lead: data[index],
                          onTap: () =>
                              context.push('/dealer/leads/${data[index].id}'),
                        ),
                      ),
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

/// The two registers, as index tabs on a file.
class _RegisterSwitch extends StatelessWidget {
  const _RegisterSwitch({required this.segment, required this.onChanged});

  final LeadsSegment segment;
  final ValueChanged<LeadsSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(color: Ds.lineStrong),
      ),
      child: Row(
        children: [
          for (final entry in const [
            (LeadsSegment.leads, 'Enquiries', Icons.groups_outlined),
            (LeadsSegment.testRides, 'Test rides', Icons.two_wheeler_outlined),
          ])
            Expanded(
              child: _SwitchHalf(
                label: entry.$2,
                icon: entry.$3,
                selected: segment == entry.$1,
                onTap: () => onChanged(entry.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchHalf extends StatelessWidget {
  const _SwitchHalf({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ds.rMd - 1),
        child: Container(
          height: Ds.tap - 4,
          decoration: BoxDecoration(
            // The selected register is inked; the other stays bare paper.
            color: selected ? Ds.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(Ds.rMd - 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? const Color(0xFFF7F5EF) : Ds.inkMuted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? const Color(0xFFF7F5EF) : Ds.inkSoft,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A filing tab: the selected one is inked, the rest are pencilled outlines.
class _FileTab extends StatelessWidget {
  const _FileTab({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Ds.s2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(Ds.rSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Ds.s3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Ds.caution : Colors.white,
              borderRadius: BorderRadius.circular(Ds.rSm),
              border: Border.all(
                color: selected ? Ds.caution : Ds.lineStrong,
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: Ds.label(color: selected ? Ds.ink : Ds.inkSoft)
                  .copyWith(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
