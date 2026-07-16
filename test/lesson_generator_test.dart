import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/data/lesson_generator_service.dart';
import 'package:kids_lang/features/lesson_generator/lesson_generator_page.dart';

Future<void> _pump(WidgetTester tester, LessonGeneratorService service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lessonGeneratorServiceProvider.overrideWithValue(service),
        // Approve/reject are gated on a signed-in teacher (see
        // lesson_generator_page.dart); these tests exercise the review flow
        // itself, not the auth gate, so act as if a teacher is signed in.
        isTeacherProvider.overrideWith((ref) => Future.value(true)),
      ],
      child: const MaterialApp(home: LessonGeneratorPage()),
    ),
  );
}

void main() {
  testWidgets('topic -> preview -> approve flow (T5)', (tester) async {
    await _pump(tester, MockLessonGeneratorService());

    await tester.enterText(
        find.byKey(const Key('topic_field')), 'things in a classroom');
    await tester.tap(find.byKey(const Key('generate_button')));
    await tester.pump(); // enters generating state
    await tester.pump(const Duration(milliseconds: 700)); // mock delay

    expect(find.text('things in a classroom'), findsOneWidget);
    expect(find.text('いす'), findsOneWidget); // preview shows generated items
    expect(find.byKey(const Key('approve_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('approve_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Back to the topic form, ready for the next generation.
    expect(find.byKey(const Key('topic_field')), findsOneWidget);
    expect(find.byKey(const Key('approve_button')), findsNothing);
  });

  testWidgets('picking an activity type threads it through to generation',
      (tester) async {
    await _pump(tester, MockLessonGeneratorService());

    await tester.enterText(
        find.byKey(const Key('topic_field')), 'classroom objects');
    await tester.tap(find.text('Drag & Drop'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('generate_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Drag & Drop'), findsOneWidget);
  });

  testWidgets('teacher edits a drafted word before approving (M3 curation)',
      (tester) async {
    final service = MockLessonGeneratorService();
    await _pump(tester, service);

    await tester.enterText(find.byKey(const Key('topic_field')), 'classroom');
    await tester.tap(find.byKey(const Key('generate_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Tap the first preview row to open the edit dialog and fix the word.
    await tester.tap(find.byKey(const Key('edit_item_0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('edit_word_field')), 'こくばん');
    await tester.tap(find.byKey(const Key('edit_save_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The service got the edit and the preview reflects it in place.
    expect(service.editedWords['mock-i1'], 'こくばん');
    expect(find.text('こくばん'), findsOneWidget);
    expect(find.text('いす'), findsNothing);
  });

  testWidgets('reject flow discards the draft without approving',
      (tester) async {
    await _pump(tester, MockLessonGeneratorService());

    await tester.enterText(find.byKey(const Key('topic_field')), 'kitchen');
    await tester.tap(find.byKey(const Key('generate_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byKey(const Key('reject_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('topic_field')), findsOneWidget);
  });

  testWidgets('generation failure shows a non-silent error with retry (T6)',
      (tester) async {
    await _pump(tester, MockLessonGeneratorService(failGeneration: true));

    await tester.enterText(find.byKey(const Key('topic_field')), 'fish');
    await tester.tap(find.byKey(const Key('generate_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('error_card')), findsOneWidget);
    expect(
      find.text('generated lesson failed translation-correctness verification'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pump();

    expect(find.byKey(const Key('topic_field')), findsOneWidget);
    expect(find.byKey(const Key('error_card')), findsNothing);
  });
}
