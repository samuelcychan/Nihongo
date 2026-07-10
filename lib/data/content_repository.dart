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

  /// Fixed published course id (see supabase/migrations/0002_seed.sql). Every
  /// unit approved via the M0.5 AI generator (supabase/functions/generate-lesson)
  /// also lands here -- see PUBLISHED_COURSE_ID in that function.
  static const publishedCourseId = '11111111-1111-1111-1111-111111111111';

  /// All lessons in [courseId]'s units, in course order (unit `position`, then
  /// `created_at` as a stable tiebreak -- AI-generated units are all inserted
  /// at position 0, so creation time is what actually orders them). Assumes
  /// one lesson per unit, matching both the seed data and the generator.
  Future<List<Lesson>> fetchCourseLessons(String courseId) async {
    final unitRows = await _client
        .from('units')
        .select('id')
        .eq('course_id', courseId)
        .order('position', ascending: true)
        .order('created_at', ascending: true);
    final unitIds = [for (final u in unitRows) u['id'] as String];
    if (unitIds.isEmpty) return const [];

    final lessonRows = await _client
        .from('lessons')
        .select('id, unit_id, title')
        .inFilter('unit_id', unitIds);
    final lessonRowByUnit = <String, Map<String, dynamic>>{};
    for (final row in lessonRows) {
      lessonRowByUnit.putIfAbsent(row['unit_id'] as String, () => row);
    }
    final lessonIds = [
      for (final id in unitIds)
        if (lessonRowByUnit[id] != null) lessonRowByUnit[id]!['id'] as String,
    ];
    if (lessonIds.isEmpty) return const [];

    final activityRows = await _client
        .from('activities')
        .select()
        .inFilter('lesson_id', lessonIds)
        .order('position', ascending: true);
    final activityRowsByLesson = <String, List<Map<String, dynamic>>>{};
    for (final row in activityRows) {
      activityRowsByLesson
          .putIfAbsent(row['lesson_id'] as String, () => [])
          .add(row);
    }
    final activityIds = [for (final a in activityRows) a['id'] as String];

    final itemRows = activityIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
            .from('items')
            .select()
            .inFilter('activity_id', activityIds)
            .order('position', ascending: true);
    final itemsByActivity = <String, List<Item>>{};
    for (final row in itemRows) {
      final item = Item.fromMap(row);
      itemsByActivity.putIfAbsent(item.activityId, () => []).add(item);
    }

    final courseRow = await _client
        .from('courses')
        .select('target_language')
        .eq('id', courseId)
        .single();
    final targetLanguage = _bcp47(courseRow['target_language'] as String? ?? 'en');

    final lessons = <Lesson>[];
    for (final unitId in unitIds) {
      final lessonRow = lessonRowByUnit[unitId];
      if (lessonRow == null) continue; // a unit with no lesson yet
      final lessonId = lessonRow['id'] as String;
      final activities = [
        for (final a in activityRowsByLesson[lessonId] ?? const <Map<String, dynamic>>[])
          Activity.fromMap(a, items: itemsByActivity[a['id']] ?? const []),
      ];
      final lesson = Lesson(
        id: lessonId,
        title: lessonRow['title'] as String? ?? 'Lesson',
        activities: activities,
        targetLanguage: targetLanguage,
      );
      _cache[lessonId] = lesson;
      lessons.add(lesson);
    }
    return lessons;
  }

  Future<Lesson> fetchLesson(String lessonId) async {
    try {
      final activityRows = await _client
          .from('activities')
          .select()
          .eq('lesson_id', lessonId)
          .order('position', ascending: true);

      final activityIds =
          [for (final a in activityRows) a['id'] as String];

      final itemRows = activityIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
              .from('items')
              .select()
              .inFilter('activity_id', activityIds)
              .order('position', ascending: true);

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
