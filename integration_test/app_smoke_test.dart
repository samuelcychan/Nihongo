// M1 NFR-parity: a real on-device/on-simulator smoke test, run via CI on an
// actual iOS Simulator (see .github/workflows/ci.yml's ios-build-and-smoke-test
// job) since this repo has no local Mac/Xcode available for interactive
// verification. Runs without Supabase dart-defines (CI doesn't inject
// secrets here), matching the app's documented offline-boot fallback --
// proves the compiled app actually launches and renders on iOS, not just
// that `flutter build ios` succeeds.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kids_lang/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots on-device without crashing and renders a screen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KidsLangApp()));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
