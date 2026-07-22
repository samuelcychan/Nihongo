import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/content.dart';
import '../../features/activity_dragdrop/dragdrop_activity_page.dart';
import '../../features/activity_match/activity_match_page.dart';
import '../../features/activity_sequence/sequence_activity_page.dart';
import '../../features/activity_speak/speak_activity_page.dart';
import '../../features/consent_gate/consent_gate_page.dart';
import '../../features/landing/auth_page.dart';
import '../../features/landing/landing_page.dart';
import '../../features/learner_home/learner_home_page.dart';
import '../../features/lesson_generator/lesson_generator_page.dart';
import '../../features/lesson_map/lesson_map_page.dart';
import '../../features/parent_dashboard/parent_dashboard_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/round_complete/round_complete_page.dart';
import '../../features/teacher_auth/teacher_login_page.dart';
import '../providers.dart';

/// Navigates to a lesson, routing through the M1 consent gate first if a
/// parent/guardian hasn't confirmed it yet -- the single entry point both
/// the home Play button and the lesson map's nodes go through.
void playLesson(BuildContext context, WidgetRef ref, Lesson lesson) {
  final consented = ref.read(consentGivenProvider).value ?? false;
  if (consented) {
    context.push('/play', extra: lesson);
  } else {
    context.push('/consent', extra: lesson);
  }
}

/// Gates any destination that needs parental confirmation first but isn't
/// playing a lesson -- currently just '/register', since a learner account
/// collects a real email and shouldn't bypass the same gate lesson-play does.
void requireConsent(
  BuildContext context,
  WidgetRef ref, {
  required String forwardRoute,
}) {
  final consented = ref.read(consentGivenProvider).value ?? false;
  if (consented) {
    context.push(forwardRoute);
  } else {
    context.push('/consent?forward=$forwardRoute');
  }
}

/// App routes. The learner flow plus the new Sprout screens (lesson map,
/// round-complete celebration, parent dashboard). Role-gating for the parent
/// route can slot in here later.
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      // Shows the landing page (sign up / log in / continue as guest) once
      // per device; picking any path marks hasSeenLandingProvider and lands
      // back here, which then renders the real home.
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final hasSeenLanding = ref.watch(hasSeenLandingProvider).value ?? false;
          return hasSeenLanding ? const LearnerHomePage() : const LandingPage();
        },
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const AuthPage(mode: AuthMode.register),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthPage(mode: AuthMode.login),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const LessonMapPage(),
    ),
    GoRoute(
      path: '/play',
      // M1: a lesson's first activity picks the interaction type; `match`
      // (and any unrecognized/legacy type) stays the default.
      builder: (context, state) {
        final lesson = state.extra as Lesson;
        final type = lesson.activities.isNotEmpty
            ? lesson.activities.first.type
            : 'match';
        return switch (type) {
          'drag_drop' => DragDropActivityPage(lesson: lesson),
          'sequence' => SequenceActivityPage(lesson: lesson),
          'speak' => SpeakActivityPage(lesson: lesson),
          _ => ActivityMatchPage(lesson: lesson),
        };
      },
    ),
    GoRoute(
      path: '/complete',
      builder: (context, state) {
        final r = state.extra as RoundSummary?;
        return RoundCompletePage(
          title: r?.title ?? 'Animals',
          stars: r?.stars ?? 2,
          starsEarned: r?.starsEarned ?? 15,
        );
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressPage(),
    ),
    GoRoute(
      path: '/parents',
      builder: (context, state) => const ParentDashboardPage(),
    ),
    GoRoute(
      path: '/generate',
      builder: (context, state) => const LessonGeneratorPage(),
    ),
    GoRoute(
      path: '/teacher-login',
      builder: (context, state) => const TeacherLoginPage(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => ConsentGatePage(
        pendingLesson: state.extra as Lesson?,
        pendingRoute: state.uri.queryParameters['forward'],
      ),
    ),
  ],
);
