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
///
/// Deliberately lives **outside** `lib/obd_feature/` and only ever *reads*
/// [DashboardProvider]'s published state (`latestReading`, `health`). Nothing
/// here touches the Bluetooth/ELM327 connection code — it works identically
/// whether the readings come from a live device or the in-app simulator.
///
/// Two actions, both driven by whatever is on screen at the moment the rider
/// taps:
///  * **AI summary** — posts the current readings to the backend, which asks
///    Bedrock to explain them in plain language.
///  * **Raise a service ticket** — appears only once the summary says the
///    readings are worth a dealer's attention, and pre-fills the request form
///    with the captured diagnostics.
class ObdAiActions extends ConsumerStatefulWidget {
  const ObdAiActions({super.key, required this.vehicleId});

  /// The vehicle whose dashboard is showing. Needed both for the ownership check
  /// on the summary endpoint and to file any resulting service request.
  final String vehicleId;

  @override
  ConsumerState<ObdAiActions> createState() => _ObdAiActionsState();
}

class _ObdAiActionsState extends ConsumerState<ObdAiActions> {
  bool _loading = false;
  TelemetrySummary? _summary;
  String? _error;

  /// The last minute of readings, collected while this screen is open. The
  /// summary is computed from this window rather than one instant, which is what
  /// lets it talk about trends ("coolant climbed 12°C").
  final _buffer = TelemetryBuffer();
  DashboardProvider? _dashboard;

  @override
  void initState() {
    super.initState();
    // Deferred: the provider is above us in the tree and is not readable from
    // initState directly.
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

  /// Buffers each new reading as it arrives. Only real readings are kept - with
  /// no device connected nothing is emitted, so nothing accumulates.
  void _collect() {
    final dashboard = _dashboard;
    if (dashboard == null || !dashboard.isLive) return;
    _buffer.add(dashboard.latestReading);
  }

  /// Snapshot the readings at the instant of the tap: the stream keeps ticking,
  /// and the summary must describe what the rider actually saw.
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
      // The buffered window, sent alongside the latest reading.
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.yamahaBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bike health summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                // Honest about provenance: says so when the model was unreachable
                // and the deterministic rules answered instead.
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    summary.isAiGenerated ? 'AI generated' : 'Rule-based',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            if (summary.samplesUsed > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Based on ${summary.samplesUsed} readings'
                '${summary.windowSeconds != null ? ' over the last ${summary.windowSeconds}s' : ''}.',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
            const SizedBox(height: 12),
            Text(summary.summary, style: const TextStyle(fontSize: 15, height: 1.45)),
            const SizedBox(height: 20),
            if (summary.isActionable) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.hot.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.hot, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These readings are worth a dealer check.',
                        style: TextStyle(fontSize: 13),
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
                  icon: const Icon(Icons.confirmation_number_outlined),
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
    );
  }

  /// Hands the captured diagnostics to the normal service-request form, so a
  /// ticket raised from the dashboard is the same kind of ticket as any other —
  /// same thread, same dealer chat, same AI triage.
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

  @override
  Widget build(BuildContext context) {
    // Rebuilds with the stream so the fault hint appears as soon as the rule
    // engine flags something, without the rider having to ask for a summary.
    final dashboard = legacy_provider.Provider.of<DashboardProvider>(context);
    _collect();
    final flagged = dashboard.health.level != HealthLevel.green ||
        dashboard.latestReading.activeDtcCodes.isNotEmpty;
    final actionable = _summary?.isActionable ?? flagged;

    // Nothing to summarise until the bike is actually feeding readings. Saying so
    // is better than offering a button that would describe an empty dashboard.
    if (!dashboard.isLive) {
      return Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.black.withValues(alpha: 0.45)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connect your OBD device to get an AI health summary.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      color: Colors.white,
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
                    style: const TextStyle(color: AppColors.hot, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _summarise,
                      icon: _loading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_loading ? 'Analysing…' : 'AI summary'),
                    ),
                  ),
                  if (actionable) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _raiseTicket(
                          _summary ??
                              const TelemetrySummary(
                                summary: '',
                                source: 'fallback',
                                isActionable: true,
                              ),
                        ),
                        icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                        label: const Text('Raise ticket'),
                      ),
                    ),
                  ],
                ],
              ),
              if (_summary != null && !_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () => _showSheet(_summary!),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.black45),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _summary!.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                        const Text('Read', style: TextStyle(fontSize: 12, color: AppColors.yamahaBlue)),
                      ],
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
