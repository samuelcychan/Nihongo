/// Speech INPUT abstraction for pronunciation capture (PRD F2).
///
/// Defined now so future "speak the word" activities can drop in without
/// touching activity code. The chosen strategy is on-device-first with an
/// opt-in cloud fallback for richer scoring — both implementations will live
/// behind this interface. The first slice activity is tap-based, so only the
/// interface and an unavailable stub ship here.
library;

/// Result of evaluating a spoken attempt against a target word.
class PronunciationResult {
  const PronunciationResult({
    required this.transcript,
    required this.score,
  });

  /// What the recognizer heard.
  final String transcript;

  /// Pronunciation accuracy in [0, 1]; feeds learner_item_states.pronunciation_score.
  final double score;
}

abstract class SpeechService {
  /// Whether speech capture is available on this device/build.
  Future<bool> isAvailable();

  /// Captures a spoken attempt and scores it against [target] (in [language]).
  Future<PronunciationResult> evaluate({
    required String target,
    String language = 'es-ES',
  });

  Future<void> cancel();
}

/// Placeholder used until the on-device implementation lands. Reports
/// unavailable so callers gracefully hide speech affordances.
class UnavailableSpeechService implements SpeechService {
  const UnavailableSpeechService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<PronunciationResult> evaluate({
    required String target,
    String language = 'es-ES',
  }) async =>
      throw UnsupportedError('Speech input is not implemented in this build.');

  @override
  Future<void> cancel() async {}
}
