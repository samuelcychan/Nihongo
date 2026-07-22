import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'pronunciation_scorer.dart';
import 'speech_service.dart';

/// On-device speech capture via the platform recognizer (PRD F2's
/// on-device-first strategy — no audio ever leaves the device from our code;
/// see docs/compliance-checklist.md). Scoring is [pronunciationScore] over the
/// final transcript.
class OnDeviceSpeechService implements SpeechService {
  OnDeviceSpeechService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _initialized = false;

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      try {
        _initialized = await _speech.initialize();
      } catch (_) {
        _initialized = false;
      }
    }
    return _initialized;
  }

  @override
  Future<PronunciationResult> evaluate({
    required String target,
    String language = 'es-ES',
  }) async {
    if (!await isAvailable()) {
      throw StateError('Speech recognition is not available on this device.');
    }
    final completer = Completer<String>();
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: language.replaceAll('-', '_'),
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
      ),
      onResult: (result) {
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(result.recognizedWords);
        }
      },
    );
    // The plugin stops on its own after listenFor/pauseFor; the timeout is a
    // belt-and-braces guard so a missed callback can never hang the activity.
    final transcript = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _speech.stop();
        return '';
      },
    );
    return PronunciationResult(
      transcript: transcript,
      score: pronunciationScore(target, transcript),
    );
  }

  @override
  Future<void> cancel() => _speech.cancel();
}
