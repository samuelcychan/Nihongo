import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/item_visual.dart';
import '../../domain/models/content.dart';
import '../round_complete/round_complete_page.dart';

/// Sequence activity (PRD F1, M1's third interaction type): the child taps
/// shuffled items back into their correct order (`Item.position` ascending,
/// e.g. days of the week or a story's word order). Each correct tap fills
/// the next slot in the "built so far" row; a wrong tap shakes in place
/// without advancing.
class SequenceActivityPage extends ConsumerStatefulWidget {
  const SequenceActivityPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<SequenceActivityPage> createState() => _SequenceActivityPageState();
}

class _SequenceActivityPageState extends ConsumerState<SequenceActivityPage> {
  static const _maxItems = 6;

  late final List<Item> _correctOrder;
  late final List<Item> _pool;
  final List<Item> _placed = [];
  String? _wrongTapId;
  int _wrongTaps = 0;
  final DateTime _start = DateTime.now();
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final items = List<Item>.from(widget.lesson.allItems)
      ..sort((a, b) => a.position.compareTo(b.position));
    _correctOrder = items.take(_maxItems).toList();
    _pool = List<Item>.from(_correctOrder)..shuffle();
  }

  Item get _expected => _correctOrder[_placed.length];

  Future<void> _onTap(Item tapped) async {
    if (_finished || _placed.any((p) => p.id == tapped.id)) return;
    final audio = ref.read(audioServiceProvider);
    if (tapped.id != _expected.id) {
      _wrongTaps++;
      audio.speakFeedback('Try again');
      setState(() => _wrongTapId = tapped.id);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _wrongTapId = null);
      return;
    }

    audio.speakFeedback('Great job!');
    setState(() => _placed.add(tapped));
    try {
      await ref.read(resultsRepositoryProvider).recordResult(
            learnerId: ref.read(learnerIdProvider),
            item: tapped,
            correct: true,
            attempts: 1,
            responseTime: DateTime.now().difference(_start),
          );
    } catch (_) {/* persisted locally even if sync failed */}

    if (_placed.length == _correctOrder.length) {
      _finish();
    }
  }

  void _finish() {
    setState(() => _finished = true);
    final stars = _wrongTaps == 0 ? 3 : (_wrongTaps <= 2 ? 2 : 1);
    final earned = _correctOrder.length * 2 + stars * 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement(
        '/complete',
        extra: RoundSummary(
          title: widget.lesson.title,
          stars: stars,
          starsEarned: earned,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: const Text('Put Them in Order'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gap),
          child: Column(
            children: [
              // "Built so far" row: one numbered slot per item, filled in order.
              SizedBox(
                height: 84,
                child: Row(
                  children: [
                    for (var i = 0; i < _correctOrder.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _SlotTile(
                            key: Key('slot_$i'),
                            item: i < _placed.length ? _placed[i] : null,
                            index: i,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.gap * 1.5),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final item in _pool)
                      if (!_placed.any((p) => p.id == item.id))
                        _PoolTile(
                          key: ValueKey('pool_${item.id}'),
                          item: item,
                          wrong: _wrongTapId == item.id,
                          onTap: () => _onTap(item),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({super.key, required this.item, required this.index});

  final Item? item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final filled = item != null;
    return Container(
      decoration: BoxDecoration(
        color: filled ? Colors.white : const Color(0xFFF0E8DA),
        borderRadius: BorderRadius.circular(AppTheme.tileRadius),
        border: Border.all(
          color: filled ? AppTheme.grassDeep : AppTheme.hairline,
          width: filled ? 3 : 2,
          style: filled ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: filled
          ? ItemVisual(item: item!, size: 32)
          : Text('${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.inkFaint)),
    );
  }
}

class _PoolTile extends StatelessWidget {
  const _PoolTile({
    super.key,
    required this.item,
    required this.wrong,
    required this.onTap,
  });

  final Item item;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile = Semantics(
      button: true,
      label: item.answer,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.tileRadius),
          onTap: onTap,
          child: Container(
            key: Key('pool_tile_${item.id}'),
            width: AppTheme.minTapTarget * 0.85,
            height: AppTheme.minTapTarget * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.tileRadius),
              border: Border.all(
                color: wrong ? AppTheme.coral : const Color(0xFFECE4D6),
                width: 4,
              ),
              boxShadow: AppTheme.chunky(wrong ? AppTheme.coralDeep : const Color(0xFFEFE7DA)),
            ),
            alignment: Alignment.center,
            child: ItemVisual(item: item, size: 40),
          ),
        ),
      ),
    );

    if (wrong) {
      tile = tile.animate().shake(duration: 400.ms);
    }
    return tile;
  }
}
