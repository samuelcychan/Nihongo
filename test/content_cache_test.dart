import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/domain/models/content.dart';

/// M2 NFR-offline: the drift course cache stores lessons as JSON via
/// Lesson.toCacheMap / Lesson.fromCacheMap. A silent asymmetry between the
/// two would corrupt every offline session, so the round-trip is pinned here.
void main() {
  const lesson = Lesson(
    id: 'L1',
    title: 'Farm Animals',
    targetLanguage: 'ja-JP',
    activities: [
      Activity(
        id: 'A1',
        lessonId: 'L1',
        type: 'speak',
        title: 'Say the Word',
        config: {'optionCount': 4},
        items: [
          Item(
            id: 'I1',
            activityId: 'A1',
            answer: 'ねこ',
            promptText: 'ねこ',
            promptAudioUrl: 'https://example.com/neko.mp3',
            imageUrl: null,
            glyph: '🐱',
            difficulty: 2,
            position: 0,
          ),
          Item(
            id: 'I2',
            activityId: 'A1',
            answer: 'いぬ',
            glyph: '🐶',
            difficulty: 1,
            position: 1,
          ),
        ],
      ),
    ],
  );

  test('toCacheMap -> JSON -> fromCacheMap round-trips every field', () {
    final decoded = Lesson.fromCacheMap(
      (jsonDecode(jsonEncode(lesson.toCacheMap())) as Map)
          .cast<String, dynamic>(),
    );

    expect(decoded.id, lesson.id);
    expect(decoded.title, lesson.title);
    expect(decoded.targetLanguage, lesson.targetLanguage);
    expect(decoded.activities, hasLength(1));

    final a = decoded.activities.first;
    expect(a.id, 'A1');
    expect(a.type, 'speak');
    expect(a.optionCount, 4);
    expect(a.items, hasLength(2));

    final i1 = a.items.first;
    expect(i1.id, 'I1');
    expect(i1.answer, 'ねこ');
    expect(i1.promptText, 'ねこ');
    expect(i1.promptAudioUrl, 'https://example.com/neko.mp3');
    expect(i1.imageUrl, isNull);
    expect(i1.glyph, '🐱');
    expect(i1.difficulty, 2);

    final i2 = a.items.last;
    expect(i2.promptText, isNull);
    expect(i2.position, 1);
  });

  test('a whole course (lesson list) round-trips as stored by the cache', () {
    final payload = jsonEncode([lesson.toCacheMap(), lesson.toCacheMap()]);
    final decoded = [
      for (final m in jsonDecode(payload) as List)
        Lesson.fromCacheMap((m as Map).cast<String, dynamic>()),
    ];
    expect(decoded, hasLength(2));
    expect(decoded.first.allItems, hasLength(2));
  });
}
