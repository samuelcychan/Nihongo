import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

/// Audio OUTPUT for activities (PRD F2): speaks prompt words and feedback.
///
/// Prefers a native-speaker clip (`Item.promptAudioUrl`) when the item has
/// one, falling back to on-device TTS otherwise -- TTS remains the mandatory
/// fallback (M1 extends, not replaces, the emoji+TTS baseline). Every
/// activity depends on this abstraction, never on the plugins directly.
abstract class AudioService {
  /// Speaks [text] in [language] (BCP-47, e.g. 'es-ES'), awaiting completion.
  /// If [audioUrl] is given, plays that native clip instead and only falls
  /// back to TTS if playback fails.
  Future<void> speakWord(String text, {String language = 'es-ES', String? audioUrl});

  /// Short spoken feedback cue.
  Future<void> speakFeedback(String text, {String language = 'en-US'});

  Future<void> stop();
  Future<void> dispose();
}

class TtsAudioService implements AudioService {
  TtsAudioService([FlutterTts? tts, AudioPlayer? player])
      : _tts = tts ?? FlutterTts(),
        _player = player ?? AudioPlayer() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;
  final AudioPlayer _player;
  String? _lastLanguage;

  Future<void> _ensureLanguage(String language) async {
    if (_lastLanguage == language) return;
    await _tts.setLanguage(language);
    _lastLanguage = language;
  }

  @override
  Future<void> speakWord(String text, {String language = 'es-ES', String? audioUrl}) async {
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _tts.stop();
        await _player.setUrl(audioUrl);
        await _player.play();
        return;
      } catch (_) {
        // Native clip failed to load/play -- fall through to TTS below.
      }
    }
    await _player.stop();
    await _tts.stop();
    await _ensureLanguage(language);
    await _tts.setSpeechRate(0.4); // slow + clear for learners
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  @override
  Future<void> speakFeedback(String text, {String language = 'en-US'}) async {
    await _player.stop();
    await _tts.stop();
    await _ensureLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.2); // brighter for encouragement
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => Future.wait([_tts.stop(), _player.stop()]);

  @override
  Future<void> dispose() => Future.wait([_tts.stop(), _player.dispose()]);
}
