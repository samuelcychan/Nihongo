import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/content.dart';

/// Reads published content (PRD F4 hierarchy) from Supabase.
///
/// Keeps a last-good in-memory copy so a lesson already opened this session
/// survives a brief connectivity blip. (Durable offline content caching in
/// drift is a tracked follow-up; the slice's offline guarantee centres on
/// never losing learner results — see [ResultsRepository].)
class ContentRepository {
  ContentRepository(this._client);

  final SupabaseClient _client;
  final Map<String, Lesson> _cache = {};

  /// Fixed seed lesson id (see supabase/migrations/0002_seed.sql).
  static const seedLessonId = '33333333-3333-3333-3333-333333333333';

  Future<Lesson> fetchLesson(String lessonId) async {
    try {
      final activityRows = await _client
          .from('activities')
          .select()
          .eq('lesson_id', lessonId)
          .order('position');

      final activityIds =
          [for (final a in activityRows) a['id'] as String];

      final itemRows = activityIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
              .from('items')
              .select()
              .inFilter('activity_id', activityIds)
              .order('position');

      final itemsByActivity = <String, List<Item>>{};
      for (final row in itemRows) {
        final item = Item.fromMap(row);
        itemsByActivity.putIfAbsent(item.activityId, () => []).add(item);
      }

      final activities = [
        for (final a in activityRows)
          Activity.fromMap(a, items: itemsByActivity[a['id']] ?? const []),
      ];

      // Title + the course's target language (embedded via FK relationships).
      final lessonRow = await _client
          .from('lessons')
          .select('title, units(courses(target_language))')
          .eq('id', lessonId)
          .single();

      final lesson = Lesson(
        id: lessonId,
        title: lessonRow['title'] as String? ?? 'Lesson',
        activities: activities,
        targetLanguage: _bcp47(_embeddedTargetLanguage(lessonRow)),
      );
      _cache[lessonId] = lesson;
      return lesson;
    } catch (_) {
      final cached = _cache[lessonId];
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Pulls `target_language` out of the embedded `units(courses(...))` shape,
  /// which PostgREST returns as either a nested object or a single-element list.
  static String _embeddedTargetLanguage(Map<String, dynamic> lessonRow) {
    Object? pick(Object? v) => v is List ? (v.isEmpty ? null : v.first) : v;
    final unit = pick(lessonRow['units']) as Map<String, dynamic>?;
    final course = pick(unit?['courses']) as Map<String, dynamic>?;
    return (course?['target_language'] as String?) ?? 'en';
  }

  /// Maps a short language code to a BCP-47 tag suitable for TTS engines.
  static String _bcp47(String code) => switch (code) {
        'ja' => 'ja-JP',
        'es' => 'es-ES',
        'en' => 'en-US',
        'fr' => 'fr-FR',
        'de' => 'de-DE',
        'zh' => 'zh-CN',
        'ko' => 'ko-KR',
        _ => code,
      };
}
