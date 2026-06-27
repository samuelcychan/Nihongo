import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/db/app_database.dart';
import '../../domain/models/content.dart';

/// Sprout "My Stars" — per-item mastery (PRD F3). Reads reactive local state, so
/// it reflects results immediately and offline. Mastery maps to a 0–3 star
/// rating; un-started / lapsed items show a status pill instead.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  // Display-only English gloss for the seed animals (data has no UI-language
  // translation column yet). Safe to leave incomplete — missing keys are hidden.
  static const _gloss = <String, String>{
    'ねこ': 'cat',
    'いぬ': 'dog',
    'とり': 'bird',
    'さかな': 'fish',
    'うし': 'cow',
    'あひる': 'duck',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(seedLessonProvider);
    final states = ref.watch(progressProvider).value ?? const [];
    final byItem = {for (final s in states) s.itemId: s};

    return Scaffold(
      appBar: AppBar(title: const Text('My Stars')),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (lesson) {
          final ratings = [
            for (final item in lesson.allItems)
              _rate(item, byItem[item.id]),
          ];
          final mastered = ratings.where((r) => r.status == 'Mastered').length;
          final totalStars = ratings.fold<int>(0, (a, r) => a + r.stars);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                      child: _SummaryCard(
                          value: '$totalStars ⭐',
                          label: 'total stars',
                          color: AppTheme.tangerine)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _SummaryCard(
                          value: '$mastered',
                          label: 'mastered',
                          color: AppTheme.grassDeep)),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: _SummaryCard(
                          value: '🔥3', label: 'day streak', color: AppTheme.ink)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('FARM ANIMALS',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: AppTheme.inkFaint)),
              const SizedBox(height: 9),
              for (var i = 0; i < lesson.allItems.length; i++) ...[
                _ProgressRow(item: lesson.allItems[i], rating: ratings[i]),
                if (i != lesson.allItems.length - 1) const SizedBox(height: 9),
              ],
            ],
          );
        },
      ),
    );
  }

  _Rating _rate(Item item, LocalItemState? s) {
    if (s == null) return const _Rating(0, 'New', faded: true);
    if (s.repetitions >= 2) return const _Rating(3, 'Mastered');
    if (s.correctCount > 0) {
      return _Rating(s.repetitions >= 1 ? 2 : 1, 'Learning');
    }
    return const _Rating(0, 'Review', faded: true);
  }
}

class _Rating {
  const _Rating(this.stars, this.status, {this.faded = false});
  final int stars;
  final String status;
  final bool faded;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppTheme.inkFaint)),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.item, required this.rating});

  final Item item;
  final _Rating rating;

  @override
  Widget build(BuildContext context) {
    final gloss = ProgressPage._gloss[item.answer];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: rating.faded ? const Color(0xFFFBF4E8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rating.faded ? const Color(0xFFE3D6BF) : AppTheme.hairline,
          width: rating.faded ? 1 : 1,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: rating.faded ? 0.7 : 1,
            child: Text(item.glyph ?? '•',
                style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(item.answer,
                    style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: rating.faded ? AppTheme.inkSoft : AppTheme.ink)),
                if (gloss != null) ...[
                  const SizedBox(width: 6),
                  Text('· $gloss',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFFB7AB9B))),
                ],
              ],
            ),
          ),
          if (rating.stars > 0)
            _StarRow(filled: rating.stars)
          else
            _StatusPill(text: rating.status),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Opacity(
            opacity: i < filled ? 1 : 0.28,
            child: const Text('⭐', style: TextStyle(fontSize: 15)),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFFB7AB9B))),
    );
  }
}
