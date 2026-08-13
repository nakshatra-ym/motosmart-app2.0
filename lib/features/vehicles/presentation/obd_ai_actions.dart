import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/theme.dart';
import '../../../obd_feature/models/obd_reading.dart';
import '../../../obd_feature/state/dashboard_provider.dart';
import '../../service/presentation/new_service_request_screen.dart';
import '../data/telemetry_buffer.dart';
import '../data/telemetry_summary.dart';

/// The AI actions bar overlaid on the OBD health dashboard.
class ObdAiActions extends ConsumerStatefulWidget {
  const ObdAiActions({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<ObdAiActions> createState() => _ObdAiActionsState();
}

class _ObdAiActionsState extends ConsumerState<ObdAiActions> {
  bool _loading = false;
  TelemetrySummary? _summary;
  String? _error;

  final _buffer = TelemetryBuffer();
  DashboardProvider? _dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboard = legacy_provider.Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      _dashboard = dashboard..addListener(_collect);
      _collect();
    });
  }

  @override
  void dispose() {
    _dashboard?.removeListener(_collect);
    super.dispose();
  }

  void _collect() {
    final dashboard = _dashboard;
    if (dashboard == null || !dashboard.isLive) return;
    _buffer.add(dashboard.latestReading);
  }

  TelemetryReadings _snapshot(DashboardProvider dashboard) {
    final ObdReading reading = dashboard.latestReading;
    final health = dashboard.health;
    final span = _buffer.span.inSeconds;
    return TelemetryReadings(
      rpm: reading.rpm,
      coolantTempC: reading.coolantTempC,
      speedKph: reading.speedKph,
      batteryVoltage: reading.batteryVoltage,
      throttlePositionPct: reading.throttlePositionPct,
      fuelLevelPct: reading.fuelLevelPct,
      dtcCodes: reading.activeDtcCodes,
      healthLevel: health.level.name,
      healthReasons: health.reasons,
      samples: _buffer.toJson(),
      windowSeconds: span > 0 ? span : null,
    );
  }

  Future<void> _summarise() async {
    final dashboard = legacy_provider.Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final readings = _snapshot(dashboard);

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(telemetrySummaryRepositoryProvider).summarise(
            vehicleId: widget.vehicleId,
            readings: readings,
          );
      if (!mounted) return;
      setState(() => _summary = result);
      _showSheet(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSheet(TelemetrySummary summary) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceElevated,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.yamahaBlue.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.yamahaBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bike health summary',
                              style: Theme.of(sheetContext).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.isAiGenerated
                                  ? 'AI generated insight'
                                  : 'Rule-based insight',
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yamahaBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.yamahaBlue.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              summary.isAiGenerated ? 'AI' : 'Rules',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.yamahaBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (summary.samplesUsed > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Based on ${summary.samplesUsed} readings'
                      '${summary.windowSeconds != null ? ' over the last ${summary.windowSeconds}s' : ''}.',
                      style: Theme.of(sheetContext).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 14),
                  SelectableText(
                    summary.summary,
                    style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  if (summary.isActionable) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.hot.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hot.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.hot, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These readings are worth a dealer check.',
                              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _raiseTicket(summary);
                        },
                        icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                        label: const Text('Raise a service ticket'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _raiseTicket(TelemetrySummary summary) {
    context.push(
      '/customer/service/new',
      extra: NewServiceRequestArgs(
        vehicleId: widget.vehicleId,
        prefillType: summary.suggestedType,
        prefillDescription: summary.suggestedDescription,
        obdContext: summary.obdContext,
      ),
    );
  }

  Widget _actionButtons({required bool actionable}) {
    final summaryBtn = SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _summarise,
        icon: _loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_loading ? 'Analysing…' : 'AI summary'),
        ),
      ),
    );

    if (!actionable) return SizedBox(width: double.infinity, child: summaryBtn);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final ticketBtn = SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _raiseTicket(
              _summary ??
                  const TelemetrySummary(
                    summary: '',
                    source: 'fallback',
                    isActionable: true,
                  ),
            ),
            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Raise ticket'),
            ),
          ),
        );

        if (narrow) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: summaryBtn),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ticketBtn),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: summaryBtn),
            const SizedBox(width: 8),
            Expanded(child: ticketBtn),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = legacy_provider.Provider.of<DashboardProvider>(context);
    _collect();
    final flagged = dashboard.health.level != HealthLevel.green ||
        dashboard.latestReading.activeDtcCodes.isNotEmpty;
    final actionable = _summary?.isActionable ?? flagged;

    if (!dashboard.isLive) {
      return Material(
        color: AppColors.surfaceElevated,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.inkFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connect your OBD device to get an AI health summary.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surfaceElevated,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.hot, fontSize: 12, height: 1.35),
                  ),
                ),
              _actionButtons(actionable: actionable),
              if (_summary != null && !_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () => _showSheet(_summary!),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: AppColors.yamahaBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _summary!.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Read',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.yamahaBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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
