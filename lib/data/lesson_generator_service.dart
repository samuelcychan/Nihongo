import 'package:supabase_flutter/supabase_flutter.dart';

/// A single generated item, shown in the preview before approve/reject.
class GeneratedItemPreview {
  const GeneratedItemPreview({
    required this.promptText,
    required this.glyph,
    required this.difficulty,
  });

  final String promptText;
  final String glyph;
  final int difficulty;
}

/// Result of a successful generation — a draft unit sitting in the
/// AI-Generated Lessons (Draft) course, not yet visible to learners.
class GeneratedLesson {
  const GeneratedLesson({
    required this.unitId,
    required this.lessonTitle,
    required this.items,
  });

  final String unitId;
  final String lessonTitle;
  final List<GeneratedItemPreview> items;
}

/// Thrown for any generation/review failure — always carries a message meant
/// to be shown to the user, never a silent failure (see the failure-modes
/// table in docs/implementation-plan.md).
class LessonGenerationException implements Exception {
  const LessonGenerationException(this.message, [this.details]);
  final String message;
  final List<String>? details;

  @override
  String toString() =>
      details == null ? message : '$message: ${details!.join(', ')}';
}

/// M0.5 AI Lesson Generator client — talks to the `generate-lesson` Edge
/// Function (see supabase/functions/generate-lesson). Kept as an interface so
/// the Flutter screen can be built and tested against [MockLessonGeneratorService]
/// independently of the deployed function (T5's parallel lane).
abstract class LessonGeneratorService {
  Future<GeneratedLesson> generate(String topic);
  Future<void> approve(String unitId);
  Future<void> reject(String unitId);
}

class SupabaseLessonGeneratorService implements LessonGeneratorService {
  SupabaseLessonGeneratorService(this._client);

  final SupabaseClient _client;

  @override
  Future<GeneratedLesson> generate(String topic) async {
    final FunctionResponse res;
    try {
      res = await _client.functions.invoke(
        'generate-lesson',
        body: {'topic': topic},
      );
    } on FunctionException catch (e) {
      throw _fromFunctionException(e, 'Generation failed');
    } catch (e) {
      throw LessonGenerationException('Could not reach the generator: $e');
    }
    final data = _asMap(res.data);
    if (res.status >= 400) {
      throw _fromErrorMap(data, 'Generation failed');
    }
    if (data == null) {
      throw const LessonGenerationException('Generation failed: invalid response');
    }
    final unitId = data['unit_id'] as String?;
    if (unitId == null || unitId.isEmpty) {
      throw const LessonGenerationException('Generation failed: missing unit id');
    }
    final lessonTitle = data['lesson_title'] as String? ?? topic;
    final itemsRaw = data['items'] as List?;
    if (itemsRaw == null) {
      throw const LessonGenerationException(
        'Generation failed: missing lesson preview items',
      );
    }
    return GeneratedLesson(
      unitId: unitId,
      lessonTitle: lessonTitle,
      items: [
        for (final row in itemsRaw.whereType<Map>())
          GeneratedItemPreview(
            promptText: row['prompt_text'] as String? ?? '',
            glyph: row['glyph'] as String? ?? '•',
            difficulty: ((row['difficulty'] as num?) ?? 1).toInt(),
          ),
      ],
    );
  }

  @override
  Future<void> approve(String unitId) => _review('approve', unitId);

  @override
  Future<void> reject(String unitId) => _review('reject', unitId);

  Future<void> _review(String action, String unitId) async {
    final FunctionResponse res;
    try {
      res = await _client.functions.invoke(
        'generate-lesson',
        body: {'action': action, 'unit_id': unitId},
      );
    } on FunctionException catch (e) {
      throw _fromFunctionException(e, '$action failed');
    } catch (e) {
      throw LessonGenerationException('Could not reach the generator: $e');
    }
    if (res.status >= 400) {
      throw _fromErrorMap(_asMap(res.data), '$action failed');
    }
  }

  LessonGenerationException _fromFunctionException(
    FunctionException e,
    String fallbackMessage,
  ) => _fromErrorMap(_asMap(e.details), fallbackMessage);

  LessonGenerationException _fromErrorMap(
    Map<String, dynamic>? data,
    String fallbackMessage,
  ) => LessonGenerationException(
    data?['error'] as String? ?? fallbackMessage,
    _asStringList(data?['details']),
  );

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  List<String>? _asStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }
}

/// Mock used for the Flutter screen's independent build/test lane (T5) —
/// doesn't require the Edge Function to be deployed.
class MockLessonGeneratorService implements LessonGeneratorService {
  MockLessonGeneratorService({this.failGeneration = false});

  /// When true, [generate] throws — exercises the error-state UI.
  final bool failGeneration;

  @override
  Future<GeneratedLesson> generate(String topic) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (failGeneration) {
      throw const LessonGenerationException(
        'generated lesson failed translation-correctness verification',
        ['item 2: 「さかな」 is ambiguous without more context'],
      );
    }
    return GeneratedLesson(
      unitId: 'mock-unit-id',
      lessonTitle: topic,
      items: const [
        GeneratedItemPreview(promptText: 'いす', glyph: '🪑', difficulty: 1),
        GeneratedItemPreview(promptText: 'つくえ', glyph: '🪵', difficulty: 2),
        GeneratedItemPreview(promptText: 'ほん', glyph: '📚', difficulty: 1),
        GeneratedItemPreview(promptText: 'えんぴつ', glyph: '✏️', difficulty: 2),
        GeneratedItemPreview(promptText: 'かばん', glyph: '🎒', difficulty: 3),
        GeneratedItemPreview(promptText: 'とけい', glyph: '⏰', difficulty: 3),
      ],
    );
  }

  @override
  Future<void> approve(String unitId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> reject(String unitId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
