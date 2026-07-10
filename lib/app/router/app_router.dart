import 'package:go_router/go_router.dart';

import '../../domain/models/content.dart';
import '../../features/activity_match/activity_match_page.dart';
import '../../features/learner_home/learner_home_page.dart';
import '../../features/lesson_generator/lesson_generator_page.dart';
import '../../features/lesson_map/lesson_map_page.dart';
import '../../features/parent_dashboard/parent_dashboard_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/round_complete/round_complete_page.dart';
import '../../features/teacher_auth/teacher_login_page.dart';

/// App routes. The learner flow plus the new Sprout screens (lesson map,
/// round-complete celebration, parent dashboard). Role-gating for the parent
/// route can slot in here later.
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LearnerHomePage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const LessonMapPage(),
    ),
    GoRoute(
      path: '/play',
      builder: (context, state) =>
          ActivityMatchPage(lesson: state.extra as Lesson),
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
  ],
);
