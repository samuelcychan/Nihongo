import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/item_visual.dart';
import '../../domain/models/content.dart';
import '../round_complete/round_complete_page.dart';

/// Drag-and-drop matching activity (PRD F1, M1's second interaction type
/// alongside `match`). All pairs are visible at once as a matching board --
/// the child drags each picture onto its word label -- rather than
/// activity_match's one-target-many-distractors rounds, so MatchRoundBuilder
/// isn't reused here (every item needs to be on-screen simultaneously).
class DragDropActivityPage extends ConsumerStatefulWidget {
  const DragDropActivityPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<DragDropActivityPage> createState() => _DragDropActivityPageState();
}

class _DragDropActivityPageState extends ConsumerState<DragDropActivityPage> {
  /// Keeps the board on one screen without scrolling for young learners.
  static const _maxPairs = 5;

  late final List<Item> _targets;
  late final List<Item> _draggables;
  final Set<String> _matchedIds = {};
  String? _wrongFlashTargetId;
  int _wrongDrops = 0;
  final DateTime _start = DateTime.now();
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final pool = List<Item>.from(widget.lesson.allItems)..shuffle();
    _targets = pool.take(_maxPairs).toList();
    _draggables = List<Item>.from(_targets)..shuffle();
  }

  Future<void> _onDrop(Item dragged, Item target) async {
    if (_finished || _matchedIds.contains(target.id)) return;
    final audio = ref.read(audioServiceProvider);
    if (dragged.id != target.id) {
      _wrongDrops++;
      audio.speakFeedback('Try again');
      setState(() => _wrongFlashTargetId = target.id);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _wrongFlashTargetId = null);
      return;
    }

    audio.speakFeedback('Great job!');
    setState(() => _matchedIds.add(target.id));
    try {
      await ref.read(resultsRepositoryProvider).recordResult(
            learnerId: ref.read(learnerIdProvider),
            item: target,
            correct: true,
            attempts: 1,
            responseTime: DateTime.now().difference(_start),
          );
    } catch (_) {/* persisted locally even if sync failed */}

    if (_matchedIds.length == _targets.length) {
      _finish();
    }
  }

  void _finish() {
    setState(() => _finished = true);
    final stars = _wrongDrops == 0 ? 3 : (_wrongDrops <= 2 ? 2 : 1);
    final earned = _targets.length * 2 + stars * 3;
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
        title: const Text('Drag to Match'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final item in _targets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DropTargetTile(
                          key: ValueKey('target_${item.id}'),
                          item: item,
                          matched: _matchedIds.contains(item.id),
                          wrong: _wrongFlashTargetId == item.id,
                          onAccept: (dragged) => _onDrop(dragged, item),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.gap),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in _draggables)
                      if (!_matchedIds.contains(item.id))
                        _DraggableTile(key: ValueKey('drag_${item.id}'), item: item),
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

class _DropTargetTile extends StatelessWidget {
  const _DropTargetTile({
    super.key,
    required this.item,
    required this.matched,
    required this.wrong,
    required this.onAccept,
  });

  final Item item;
  final bool matched;
  final bool wrong;
  final ValueChanged<Item> onAccept;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color bg, IconData? icon, Color? iconColor) = switch ((matched, wrong)) {
      (true, _) => (AppTheme.grassDeep, const Color(0xFFE4F6EC), Icons.check_circle, AppTheme.correct),
      (_, true) => (AppTheme.coral, const Color(0xFFFDE9E4), Icons.close_rounded, AppTheme.incorrect),
      _ => (AppTheme.hairline, Colors.white, null, null),
    };

    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) => !matched,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Semantics(
          label: 'Drop target: ${item.promptText ?? item.answer}'
              '${matched ? ', matched' : ''}',
          child: Container(
            key: Key('drop_target_${item.id}'),
            constraints:
                const BoxConstraints(minHeight: AppTheme.minTapTarget * 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTheme.tileRadius),
              border: Border.all(
                color: candidateData.isNotEmpty ? AppTheme.sky : border,
                width: candidateData.isNotEmpty ? 4 : 2,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.promptText ?? item.answer,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                if (icon != null) Icon(icon, color: iconColor, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final visual = Container(
      key: Key('draggable_${item.id}'),
      width: AppTheme.minTapTarget * 0.7,
      height: AppTheme.minTapTarget * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.tileRadius),
        border: Border.all(color: AppTheme.hairline, width: 2),
        boxShadow: AppTheme.chunky(const Color(0xFFEFE7DA)),
      ),
      alignment: Alignment.center,
      child: ItemVisual(item: item, size: 40),
    );

    return Semantics(
      button: true,
      label: item.answer,
      child: Draggable<Item>(
        data: item,
        feedback: Material(color: Colors.transparent, child: visual),
        childWhenDragging: Opacity(opacity: 0.3, child: visual),
        child: visual,
      ),
    );
  }
}
