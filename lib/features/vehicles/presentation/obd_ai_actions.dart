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
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.yamahaBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.yamahaBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bike health summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.isAiGenerated ? 'AI generated insight' : 'Rule-based insight',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: summary.isAiGenerated ? 'AI generated' : 'Rule-based',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.yamahaBlue.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        summary.isAiGenerated ? 'AI' : 'Rules',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.yamahaBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (summary.samplesUsed > 0) ...[
                const SizedBox(height: 14),
                Text(
                  'Based on ${summary.samplesUsed} readings'
                  '${summary.windowSeconds != null ? ' over the last ${summary.windowSeconds}s' : ''}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.4),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SelectableText(
                summary.summary,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 22),
              if (summary.isActionable) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.hot.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.hot.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.hot, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These readings are worth a dealer check.',
                            style: TextStyle(fontSize: 13.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                  height: 48,
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
        color: Colors.white,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.black.withValues(alpha: 0.4)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connect your OBD device to get an AI health summary.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.hot, fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
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
                    ),
                    if (actionable) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
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
                      ),
                    ],
                  ],
                ),
                if (_summary != null && !_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Semantics(
                      button: true,
                      label: 'Open AI health summary',
                      child: InkWell(
                        onTap: () => _showSheet(_summary!),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.yamahaBlue.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _summary!.summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                              Text(
                                'Read',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.yamahaBlue.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
