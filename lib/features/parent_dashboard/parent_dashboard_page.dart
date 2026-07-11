import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/item_visual.dart';
import '../../domain/models/content.dart';

/// Sprout parent dashboard (phone). Every number here is a real aggregate
/// computed from learner_item_states (see parent_metrics.dart) -- no
/// placeholder data (M1 NFR-parent).
class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(parentMetricsProvider);
    final dailyLimit = ref.watch(dailyLimitMinutesProvider).value ?? 30;

    final week = metrics.weekFractions;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1; // Mon=0..Sun=6

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
                _StatCard(
                    label: 'Time learning',
                    value: '${metrics.minutesToday}',
                    unit: ' min',
                    color: AppTheme.accent),
                _StatCard(
                    label: 'Words mastered',
                    value: '${metrics.mastered}',
                    unit: ' / ${metrics.totalItems}',
                    color: AppTheme.grassDeep),
                _StatCard(
                    label: 'Accuracy',
                    value: '${metrics.accuracyPercent}',
                    unit: '%',
                    color: AppTheme.ink),
                _StatCard(
                    label: 'Day streak',
                    value: metrics.dayStreak > 0 ? '🔥 ${metrics.dayStreak}' : '0',
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
            // review list — real items with the worst recent accuracy.
            if (metrics.reviewItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                decoration: AppTheme.cardDecoration(border: const Color(0xFFECE5D9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Could use review',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.ink)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        for (final item in metrics.reviewItems) ...[
                          Expanded(child: _ReviewChip(item: item)),
                          if (item != metrics.reviewItems.last) const SizedBox(width: 9),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            // basic screen-time setting (M1 NFR-parent)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              decoration: AppTheme.cardDecoration(border: const Color(0xFFECE5D9)),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Daily screen-time limit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.ink)),
                  ),
                  IconButton(
                    key: const Key('limit_decrease'),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: dailyLimit <= 5
                        ? null
                        : () => ref
                            .read(appDatabaseProvider)
                            .setDailyLimitMinutes(
                                ref.read(learnerIdProvider), dailyLimit - 5),
                  ),
                  Text('$dailyLimit min',
                      key: const Key('limit_value'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.grassDeep)),
                  IconButton(
                    key: const Key('limit_increase'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => ref
                        .read(appDatabaseProvider)
                        .setDailyLimitMinutes(
                            ref.read(learnerIdProvider), dailyLimit + 5),
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
  const _ReviewChip({required this.item});
  final Item item;

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
          ItemVisual(item: item, size: 22),
          const SizedBox(width: 8),
          Text(item.promptText ?? item.answer,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFB4502E))),
        ],
      ),
    );
  }
}
