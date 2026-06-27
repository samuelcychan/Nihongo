import 'package:flutter_tts/flutter_tts.dart';

/// Audio OUTPUT for activities (PRD F2): speaks prompt words and feedback.
///
/// The slice uses on-device TTS so no audio assets need shipping; when an item
/// carries a `prompt_audio_url` (native-speaker clip) a future implementation can
/// prefer that. Every activity depends on this abstraction, never on the plugin.
abstract class AudioService {
  /// Speaks [text] in [language] (BCP-47, e.g. 'es-ES'), awaiting completion.
  Future<void> speakWord(String text, {String language = 'es-ES'});

  /// Short spoken feedback cue.
  Future<void> speakFeedback(String text, {String language = 'en-US'});

  Future<void> stop();
  Future<void> dispose();
}

class TtsAudioService implements AudioService {
  TtsAudioService([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;
  String? _lastLanguage;

  Future<void> _ensureLanguage(String language) async {
    if (_lastLanguage == language) return;
    await _tts.setLanguage(language);
    _lastLanguage = language;
  }

  @override
  Future<void> speakWord(String text, {String language = 'es-ES'}) async {
    await _tts.stop();
    await _ensureLanguage(language);
    await _tts.setSpeechRate(0.4); // slow + clear for learners
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  @override
  Future<void> speakFeedback(String text, {String language = 'en-US'}) async {
    await _tts.stop();
    await _ensureLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.2); // brighter for encouragement
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> dispose() => _tts.stop();
}
