/// Plain immutable content models (PRD F4 hierarchy).
///
/// Deliberately hand-written rather than freezed-generated: the slice keeps the
/// build_runner surface limited to drift, and these shapes are small. Each model
/// parses directly from the Supabase row maps returned by postgrest.
library;

/// A single teachable item — a word/phrase with a picture and audio.
class Item {
  const Item({
    required this.id,
    required this.activityId,
    required this.answer,
    this.promptText,
    this.promptAudioUrl,
    this.imageUrl,
    this.glyph,
    this.difficulty = 1,
    this.position = 0,
  });

  final String id;
  final String activityId;

  /// Canonical answer key (also the word being taught).
  final String answer;

  /// The word/phrase shown or spoken as the prompt.
  final String? promptText;

  /// Native-speaker audio clip; when null the client falls back to TTS.
  final String? promptAudioUrl;

  /// Optional remote picture URL.
  final String? imageUrl;

  /// Emoji "picture" used when [imageUrl] is absent — no bundled asset needed.
  final String? glyph;

  /// Difficulty tag 1..5 (feeds adaptive selection, PRD F3).
  final int difficulty;
  final int position;

  factory Item.fromMap(Map<String, dynamic> m) => Item(
        id: m['id'] as String,
        activityId: m['activity_id'] as String,
        answer: m['answer'] as String,
        promptText: m['prompt_text'] as String?,
        promptAudioUrl: m['prompt_audio_url'] as String?,
        imageUrl: m['image_url'] as String?,
        glyph: m['glyph'] as String?,
        difficulty: (m['difficulty'] as num?)?.toInt() ?? 1,
        position: (m['position'] as num?)?.toInt() ?? 0,
      );
}

/// An activity — for the slice always a tap-to-match mini-game.
class Activity {
  const Activity({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.title,
    required this.items,
    this.config = const {},
  });

  final String id;
  final String lessonId;
  final String type;
  final String title;
  final List<Item> items;
  final Map<String, dynamic> config;

  /// How many picture options to show in a match round (default 4).
  int get optionCount => (config['optionCount'] as num?)?.toInt() ?? 4;

  factory Activity.fromMap(
    Map<String, dynamic> m, {
    required List<Item> items,
  }) =>
      Activity(
        id: m['id'] as String,
        lessonId: m['lesson_id'] as String,
        type: m['type'] as String? ?? 'match',
        title: m['title'] as String? ?? '',
        items: items,
        config: (m['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// A lesson with its activities (the unit the learner opens and plays).
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.activities,
    this.targetLanguage = 'en-US',
  });

  final String id;
  final String title;
  final List<Activity> activities;

  /// BCP-47 tag of the language being taught (e.g. 'ja-JP'), used for TTS.
  final String targetLanguage;

  /// All items across the lesson's activities, in order.
  List<Item> get allItems =>
      [for (final a in activities) ...a.items];
}
