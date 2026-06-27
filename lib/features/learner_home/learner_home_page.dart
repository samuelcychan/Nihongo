import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

/// Landing screen (Sprout direction): greeting, streak chip, a course card with
/// progress, and a big tactile Play button. Logic/providers are unchanged from
/// the original — only the presentation was reskinned to match the mock.
class LearnerHomePage extends ConsumerWidget {
  const LearnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the offline-outbox reconnect listener alive for the app's lifetime.
    ref.watch(connectivitySyncProvider);

    final lessonAsync = ref.watch(seedLessonProvider);
    final progress = ref.watch(progressProvider).value ?? const [];
    final learned = progress.where((s) => s.correctCount > 0).length;

    return Scaffold(
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Could not load lessons.\n$e',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (lesson) {
            final total = lesson.allItems.length;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // greeting + avatar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tuesday morning',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.inkFaint)),
                            const SizedBox(height: 2),
                            Text('おはよう、Mia！',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE7C2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.chunky(const Color(0xFFF2D49E),
                              y: 4),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🦊',
                            style: TextStyle(fontSize: 30)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.gap),
                  // streak chip
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _StreakChip(days: 3),
                  ),
                  const SizedBox(height: AppTheme.gap),
                  // course card
                  _CourseCard(
                    title: lesson.title,
                    learned: learned,
                    total: total,
                  ),
                  const Spacer(),
                  // primary play button (chunky)
                  _ChunkyButton(
                    label: 'Play',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => context.push('/play', extra: lesson),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Map',
                          emoji: '🗺️',
                          onTap: () => context.push('/map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Stars',
                          emoji: '⭐',
                          onTap: () => context.push('/progress'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Parents',
                          emoji: '👪',
                          onTap: () => context.push('/parents'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD79B), width: 1.5),
      ),
      child: Text('🔥 $days-day streak',
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.tangerine)),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.title,
    required this.learned,
    required this.total,
  });

  final String title;
  final int learned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : learned / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFCFF0DD), Color(0xFFA6E4C4)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Text('🐮', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COURSE · EN → JP',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.4,
                            color: AppTheme.grass)),
                    const SizedBox(height: 2),
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Words learned',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppTheme.inkSoft)),
              Text('$learned / $total',
                  key: const Key('progress_badge'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppTheme.grassDeep)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: const Color(0xFFEFE7DA),
              valueColor: const AlwaysStoppedAnimation(AppTheme.grass),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big tactile primary button with the signature chunky bottom shadow.
class _ChunkyButton extends StatelessWidget {
  const _ChunkyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppTheme.grass,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              boxShadow: AppTheme.chunky(AppTheme.grassDeep),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 8),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white, fontSize: 22)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.hairline, width: 2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
