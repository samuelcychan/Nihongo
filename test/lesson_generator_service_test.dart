import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/data/lesson_generator_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

LessonGeneratorService _serviceThatThrows(FunctionException exception) {
  return SupabaseLessonGeneratorService(
    _FakeSupabaseClient(_ThrowingFunctionsClient(exception)),
  );
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this.functions);

  @override
  final FunctionsClient functions;
}

class _ThrowingFunctionsClient extends Fake implements FunctionsClient {
  _ThrowingFunctionsClient(this.exception);

  final FunctionException exception;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw exception;
}

void main() {
  test('generate maps FunctionException details into LessonGenerationException',
      () async {
    final service = _serviceThatThrows(
      const FunctionException(
        status: 422,
        details: {
          'error':
              'generated lesson failed translation-correctness verification',
          'details': ['item 2: 「さかな」 is ambiguous without more context'],
        },
        reasonPhrase: 'Unprocessable Entity',
      ),
    );

    expect(
      () => service.generate('fish'),
      throwsA(
        isA<LessonGenerationException>()
            .having(
              (e) => e.message,
              'message',
              'generated lesson failed translation-correctness verification',
            )
            .having(
              (e) => e.details,
              'details',
              ['item 2: 「さかな」 is ambiguous without more context'],
            ),
      ),
    );
  });

  test('approve maps FunctionException details into LessonGenerationException',
      () async {
    final service = _serviceThatThrows(
      const FunctionException(
        status: 409,
        details: {
          'error': 'approve failed because the draft was already reviewed',
          'details': ['unit_id draft-unit-1 is no longer pending review'],
        },
        reasonPhrase: 'Conflict',
      ),
    );

    expect(
      () => service.approve('draft-unit-1'),
      throwsA(
        isA<LessonGenerationException>()
            .having(
              (e) => e.message,
              'message',
              'approve failed because the draft was already reviewed',
            )
            .having(
              (e) => e.details,
              'details',
              ['unit_id draft-unit-1 is no longer pending review'],
            ),
      ),
    );
  });
}
