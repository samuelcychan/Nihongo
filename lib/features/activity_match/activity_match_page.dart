import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/item_visual.dart';
import '../../domain/models/content.dart';
import '../round_complete/round_complete_page.dart';
import 'match_round.dart';

enum _Status { playing, correct, wrong }

/// Tap-to-match activity (PRD F1/F2/F3), Sprout skin. The child hears a word and
/// taps the matching picture; every tap gives immediate audio-visual feedback
/// and each result is persisted (offline-first + SRS).
///
/// NOTE: the game logic, providers, and persistence are unchanged from the
/// original — only the widget presentation was reskinned to the mock.
class ActivityMatchPage extends ConsumerStatefulWidget {
  const ActivityMatchPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<ActivityMatchPage> createState() => _ActivityMatchPageState();
}

class _ActivityMatchPageState extends ConsumerState<ActivityMatchPage> {
  late final List<MatchRound> _rounds;
  int _index = 0;
  int _attempts = 0;
  int _wrongTaps = 0;
  DateTime _roundStart = DateTime.now();
  _Status _status = _Status.playing;
  String? _selectedId;
  bool _captions = true;
  bool _finished = false;

  List<Item> get _items => widget.lesson.allItems;
  MatchRound get _round => _rounds[_index];

  @override
  void initState() {
    super.initState();
    _rounds = const MatchRoundBuilder().build(_items);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTarget());
  }

  void _speakTarget() {
    if (_finished) return;
    final word = _round.target.promptText ?? _round.target.answer;
    ref.read(audioServiceProvider).speakWord(
          word,
          language: widget.lesson.targetLanguage,
          audioUrl: _round.target.promptAudioUrl,
        );
  }

  Future<void> _onSelect(Item option) async {
    if (_status != _Status.playing || _finished) return;
    _attempts++;
    final correct = option.id == _round.target.id;
    setState(() {
      _selectedId = option.id;
      _status = correct ? _Status.correct : _Status.wrong;
    });

    final audio = ref.read(audioServiceProvider);
    if (correct) {
      audio.speakFeedback('Great job!');
      try {
        await ref.read(resultsRepositoryProvider).recordResult(
              learnerId: ref.read(learnerIdProvider),
              item: _round.target,
              correct: true,
              attempts: _attempts,
              responseTime: DateTime.now().difference(_roundStart),
            );
      } catch (_) {/* persisted locally even if sync failed */}
      await Future.delayed(const Duration(milliseconds: 1200));
      _next();
    } else {
      _wrongTaps++;
      audio.speakFeedback('Try again');
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _status = _Status.playing;
        _selectedId = null;
      });
    }
  }

  void _next() {
    if (!mounted) return;
    if (_index + 1 >= _rounds.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _attempts = 0;
      _roundStart = DateTime.now();
      _status = _Status.playing;
      _selectedId = null;
    });
    _speakTarget();
  }

  /// Round finished: show the full-screen Sprout celebration, carrying a star
  /// rating derived from how cleanly the child played.
  void _finish() {
    setState(() => _finished = true);
    final stars = _wrongTaps == 0 ? 3 : (_wrongTaps <= 2 ? 2 : 1);
    final earned = _rounds.length * 2 + stars * 3;
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
      appBar: AppBar(
        title: const Text('Tap the Animal'),
        actions: [
          IconButton(
            tooltip: 'Captions',
            icon: Icon(_captions ? Icons.subtitles : Icons.subtitles_off),
            onPressed: () => setState(() => _captions = !_captions),
          ),
        ],
      ),
      body: _finished ? _buildDone(context) : _buildRound(context),
    );
  }

  Widget _buildRound(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _ProgressDots(total: _rounds.length, index: _index),
          const SizedBox(height: 6),
          _PromptBar(
            captionsOn: _captions,
            word: _round.target.promptText ?? _round.target.answer,
            onReplay: _speakTarget,
          ),
          SizedBox(height: 42, child: _FeedbackBanner(status: _status)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.gap, 4, AppTheme.gap, AppTheme.gap),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final option in _round.options)
                    _OptionTile(
                      key: ValueKey('option_${option.id}'),
                      item: option,
                      state: _selectedId == option.id
                          ? _status
                          : _Status.playing,
                      onTap: () => _onSelect(option),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Center(
      key: const Key('activity_done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐮', style: TextStyle(fontSize: 96)),
          const SizedBox(height: AppTheme.gap),
          Text('すごい！', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('You finished the Animals round',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.inkFaint)),
          const SizedBox(height: AppTheme.gap * 1.5),
          SizedBox(
            width: 200,
            height: 60,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Keep going'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented progress indicator: filled (done), active (current), empty.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.index});
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: i < index
                      ? AppTheme.grassDeep
                      : i == index
                          ? const Color(0xFF5BD89A)
                          : const Color(0xFFEFE7DA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (i != total - 1) const SizedBox(width: 6),
          ],
          const SizedBox(width: 8),
          Text('${index + 1}/$total',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppTheme.inkFaint)),
        ],
      ),
    );
  }
}

class _PromptBar extends StatelessWidget {
  const _PromptBar({
    required this.captionsOn,
    required this.word,
    required this.onReplay,
  });

  final bool captionsOn;
  final String word;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: 'Play the word again',
          child: Material(
            color: AppTheme.grass,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onReplay,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.chunky(AppTheme.grassDeep),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.volume_up_rounded,
                    color: Colors.white, size: 38),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tap to hear it again',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.inkFaint)),
        if (captionsOn) ...[
          const SizedBox(height: 6),
          Text(word,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(letterSpacing: 1.2)),
        ],
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _Status.correct:
        return const _Banner(
          key: Key('feedback_correct'),
          text: 'せいかい！',
          icon: Icons.check_rounded,
          fg: AppTheme.correct,
          bg: Color(0xFFE4F6EC),
        );
      case _Status.wrong:
        return const _Banner(
          key: Key('feedback_wrong'),
          text: 'Try again',
          icon: Icons.refresh_rounded,
          fg: AppTheme.coralDeep,
          bg: Color(0xFFFDE9E4),
        );
      case _Status.playing:
        return const SizedBox.shrink();
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.text,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String text;
  final IconData icon;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.item,
    required this.state,
    required this.onTap,
  });

  final Item item;
  final _Status state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color shade) = switch (state) {
      _Status.correct => (AppTheme.grassDeep, AppTheme.grassDeep),
      _Status.wrong => (AppTheme.coral, AppTheme.coralDeep),
      _Status.playing => (const Color(0xFFECE4D6), const Color(0xFFEFE7DA)),
    };

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
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTapTarget,
              minHeight: AppTheme.minTapTarget,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.tileRadius),
              border: Border.all(color: border, width: 4),
              boxShadow: AppTheme.chunky(shade, y: state == _Status.wrong ? 7 : 6),
            ),
            alignment: Alignment.center,
            child: ItemVisual(item: item),
          ),
        ),
      ),
    );

    // Cosmetic feedback animation (does not affect logic/tests).
    if (state == _Status.wrong) {
      tile = tile.animate().shake(duration: 400.ms);
    } else if (state == _Status.correct) {
      tile = tile.animate().scaleXY(end: 1.08, duration: 250.ms);
    }
    return tile;
  }
}
