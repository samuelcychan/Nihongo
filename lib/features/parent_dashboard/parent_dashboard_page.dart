import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

/// Sprout parent dashboard (phone). Mastered/total are read from the live
/// progress stream; time/accuracy/streak and the weekly chart are placeholders
/// until those metrics are tracked — wire them to real aggregates when ready.
class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(seedLessonProvider);
    final states = ref.watch(progressProvider).value ?? const [];
    final mastered = states.where((s) => s.repetitions >= 2).length;
    final total = lessonAsync.value?.allItems.length ?? 0;

    // demo weekly minutes (Mon..Sun); replace with real session aggregates
    const week = [0.30, 0.55, 0.88, 0.48, 0.66, 0.20, 0.10];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const todayIndex = 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4EF),
        title: const Text('Parent dashboard'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PARENT VIEW',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppTheme.inkFaint)),
                      Text("Mia's week",
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E0D5)),
                  ),
                  child: const Text('This week ▾',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF6E665C))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // stat grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 2.4,
              children: [
                const _StatCard(
                    label: 'Time learning',
                    value: '38',
                    unit: ' min',
                    color: AppTheme.accent),
                _StatCard(
                    label: 'Words mastered',
                    value: '$mastered',
                    unit: ' / $total',
                    color: AppTheme.grassDeep),
                const _StatCard(
                    label: 'Accuracy', value: '86', unit: '%', color: AppTheme.ink),
                const _StatCard(
                    label: 'Day streak',
                    value: '🔥 3',
                    unit: '',
                    color: AppTheme.tangerine),
              ],
            ),
            const SizedBox(height: 14),
            // weekly chart
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration(border: const Color(0xFFECE5D9)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Minutes per day',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.ink)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 86,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < week.length; i++)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 64 * week[i],
                                    decoration: BoxDecoration(
                                      color: i == todayIndex
                                          ? AppTheme.accent
                                          : const Color(0xFF9FD0EE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(days[i],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          color: i == todayIndex
                                              ? AppTheme.accent
                                              : const Color(0xFFB7AB9B))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // review list
            Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              decoration: AppTheme.cardDecoration(border: const Color(0xFFECE5D9)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Could use review',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.ink)),
                  SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(child: _ReviewChip(emoji: '🐟', word: 'さかな')),
                      SizedBox(width: 9),
                      Expanded(child: _ReviewChip(emoji: '🐮', word: 'うし')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.push('/generate'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create a lesson (AI, M0.5)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppTheme.minTapTarget * 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE5D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.inkFaint)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: color),
              children: [
                TextSpan(
                    text: unit,
                    style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.emoji, required this.word});
  final String emoji;
  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(word,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFB4502E))),
        ],
      ),
    );
  }
}
