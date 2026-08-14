import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../features/leads/data/leads_providers.dart';
import '../config/theme.dart';
import '../network/api_exception.dart';
import 'shimmer.dart';

enum _MicState { idle, recording, transcribing }

/// Mic button for voice-to-text notes. Tap once to start recording, tap again
/// to stop and send the clip to `POST /ai/transcribe`; the transcript is
/// appended to [controller] for the dealer to review and edit — it never
/// auto-submits, since transcription can be imperfect. Used next to the lead
/// notes field and the follow-up next-action / outcome-note fields.
class MicRecordButton extends ConsumerStatefulWidget {
  const MicRecordButton({super.key, required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<MicRecordButton> createState() => _MicRecordButtonState();
}

class _MicRecordButtonState extends ConsumerState<MicRecordButton> {
  final _recorder = AudioRecorder();
  _MicState _state = _MicState.idle;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    switch (_state) {
      case _MicState.idle:
        await _startRecording();
      case _MicState.recording:
        await _stopAndTranscribe();
      case _MicState.transcribing:
        break; // Ignore taps while the batch job is running.
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is needed to record a voice note.'),
        ),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'voice_note_${DateTime.now().microsecondsSinceEpoch}.m4a');
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() => _state = _MicState.recording);
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _recorder.stop();
    if (!mounted) return;
    if (path == null) {
      setState(() => _state = _MicState.idle);
      return;
    }

    // Transcription is a batch job, not a real-time call — several seconds is
    // normal, so this shows an explicit "Transcribing…" state rather than a
    // brief spinner.
    setState(() => _state = _MicState.transcribing);
    try {
      final text = await ref.read(leadsRepositoryProvider).transcribeAudio(path);
      _appendTranscript(text);
    } on ApiException catch (e) {
      if (!mounted) return;
      final message =
          e.statusCode == 503 ? "Couldn't transcribe — try again or type it" : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't transcribe — try again or type it")),
      );
    } finally {
      unawaited(File(path).delete().catchError((_) => File(path)));
      if (mounted) setState(() => _state = _MicState.idle);
    }
  }

  void _appendTranscript(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final controller = widget.controller;
    final existing = controller.text;
    final updated = existing.trim().isEmpty ? trimmed : '$existing $trimmed';
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (_state) {
      _MicState.idle => const Icon(Icons.mic_none),
      _MicState.recording => const Icon(Icons.stop_circle, color: AppColors.hot),
      _MicState.transcribing => const SoftLoader(size: 18, color: AppColors.yamahaBlue),
    };
    final tooltip = switch (_state) {
      _MicState.idle => 'Record a voice note',
      _MicState.recording => 'Stop recording',
      _MicState.transcribing => 'Transcribing…',
    };
    return IconButton(
      tooltip: tooltip,
      onPressed: _state == _MicState.transcribing ? null : _onTap,
      icon: icon,
    );
  }
}
