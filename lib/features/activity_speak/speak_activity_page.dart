import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/item_visual.dart';
import '../../domain/models/content.dart';
import '../round_complete/round_complete_page.dart';

enum _Status { idle, listening, good, tryAgain }

/// "Say the word" activity (PRD F2, M2): the child hears a word, sees its
/// picture, and says it back. The on-device recognizer's transcript is scored
/// against the target ([SpeechService.evaluate]) and the score is persisted to
/// `pronunciation_score`, feeding the SRS quality signal (PRD F3).
///
/// If speech capture is unavailable (no recognizer on device, permission
/// denied), the page says so and offers a way back instead of dead-ending —
/// no fake results are recorded.
class SpeakActivityPage extends ConsumerStatefulWidget {
  const SpeakActivityPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<SpeakActivityPage> createState() => _SpeakActivityPageState();
}

class _SpeakActivityPageState extends ConsumerState<SpeakActivityPage> {
  static const _passScore = 0.5;
  static const _maxTriesPerItem = 2;

  late final List<Item> _items;
  int _index = 0;
  int _tries = 0;
  int _missed = 0;
  _Status _status = _Status.idle;
  double? _lastScore;
  bool? _speechAvailable; // null while probing
  bool _finished = false;
  final DateTime _start = DateTime.now();

  Item get _item => _items[_index];

  @override
  void initState() {
    super.initState();
    // No item cap: unlike drag-drop/sequence there's no "must fit one
    // screen" constraint (items are shown one at a time), and dropping
    // items here silently made lessons with >8 items permanently unpassable
    // (courseProgressProvider.isPassed() requires a repetition on every item).
    _items = widget.lesson.allItems;
    WidgetsBinding.instance.addPostFrameCallback((_) => _probeSpeech());
  }

  Future<void> _probeSpeech() async {
    final available = await ref.read(speechServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _speechAvailable = available);
    if (available) _speakTarget();
  }

  void _speakTarget() {
    if (_finished) return;
    final word = _item.promptText ?? _item.answer;
    ref.read(audioServiceProvider).speakWord(
          word,
          language: widget.lesson.targetLanguage,
          audioUrl: _item.promptAudioUrl,
        );
  }

  Future<void> _listen() async {
    if (_status == _Status.listening || _finished) return;
    setState(() {
      _status = _Status.listening;
      _lastScore = null;
    });
    double score;
    try {
      final result = await ref.read(speechServiceProvider).evaluate(
            target: _item.promptText ?? _item.answer,
            language: widget.lesson.targetLanguage,
          );
      score = result.score;
    } catch (_) {
      score = 0;
    }
    if (!mounted) return;
    _tries++;
    final passed = score >= _passScore;

    setState(() {
      _lastScore = score;
      _status = passed ? _Status.good : _Status.tryAgain;
    });
    final audio = ref.read(audioServiceProvider);

    if (passed || _tries >= _maxTriesPerItem) {
      if (passed) {
        audio.speakFeedback('Great job!');
      } else {
        _missed++;
        audio.speakFeedback('Nice try!');
      }
      try {
        await ref.read(resultsRepositoryProvider).recordResult(
              learnerId: ref.read(learnerIdProvider),
              item: _item,
              correct: passed,
              attempts: _tries,
              responseTime: DateTime.now().difference(_start),
              pronunciationScore: score,
            );
      } catch (_) {/* persisted locally even if sync failed */}
      await Future.delayed(const Duration(milliseconds: 1200));
      _next();
    } else {
      audio.speakFeedback('Try again');
    }
  }

  void _next() {
    if (!mounted) return;
    if (_index + 1 >= _items.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _tries = 0;
      _status = _Status.idle;
      _lastScore = null;
    });
    _speakTarget();
  }

  void _finish() {
    setState(() => _finished = true);
    final stars = _missed == 0 ? 3 : (_missed <= 2 ? 2 : 1);
    final earned = _items.length * 2 + stars * 3;
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
        title: const Text('Say the Word'),
      ),
      body: SafeArea(
        top: false,
        child: switch (_speechAvailable) {
          null => const Center(child: CircularProgressIndicator()),
          false => _SpeechUnavailable(onBack: () => context.pop()),
          true => _buildRound(context),
        },
      ),
    );
  }

  Widget _buildRound(BuildContext context) {
    final noReading = ref.watch(noReadingModeProvider).value ?? false;
    return Column(
      children: [
        const SizedBox(height: 10),
        Text('${_index + 1}/${_items.length}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.inkFaint)),
        const Spacer(),
        ItemVisual(item: _item, size: 110),
        const SizedBox(height: 10),
        if (!noReading)
          Text(_item.promptText ?? _item.answer,
              key: const Key('speak_prompt_text'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 6),
        TextButton.icon(
          key: const Key('speak_replay_button'),
          onPressed: _speakTarget,
          icon: const Icon(Icons.volume_up_rounded, size: 20),
          label: const Text('Hear it again'),
        ),
        SizedBox(height: 48, child: _FeedbackBanner(status: _status, score: _lastScore)),
        const Spacer(),
        _MicButton(
          key: const Key('speak_mic_button'),
          listening: _status == _Status.listening,
          onTap: _listen,
        ),
        const SizedBox(height: 8),
        Text(
          _status == _Status.listening ? 'Listening…' : 'Tap and say the word',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.inkFaint),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({super.key, required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget button = Semantics(
      button: true,
      label: 'Say the word',
      child: Material(
        color: listening ? AppTheme.coral : AppTheme.grass,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppTheme.chunky(
                  listening ? AppTheme.coralDeep : AppTheme.grassDeep),
            ),
            alignment: Alignment.center,
            child: Icon(listening ? Icons.hearing : Icons.mic_rounded,
                color: Colors.white, size: 48),
          ),
        ),
      ),
    );
    if (listening) {
      button = button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.06, duration: 500.ms);
    }
    return button;
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.status, required this.score});

  final _Status status;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final (String text, IconData icon, Color fg, Color bg) = switch (status) {
      _Status.good => ('せいかい！', Icons.check_rounded, AppTheme.correct,
          const Color(0xFFE4F6EC)),
      _Status.tryAgain => ('Try again', Icons.refresh_rounded,
          AppTheme.coralDeep, const Color(0xFFFDE9E4)),
      _ => ('', Icons.circle, Colors.transparent, Colors.transparent),
    };
    if (status != _Status.good && status != _Status.tryAgain) {
      return const SizedBox.shrink();
    }
    return Center(
      child: Container(
        key: Key(status == _Status.good ? 'speak_feedback_good' : 'speak_feedback_try'),
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

class _SpeechUnavailable extends StatelessWidget {
  const _SpeechUnavailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('speech_unavailable'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off_rounded, size: 56, color: AppTheme.inkFaint),
            const SizedBox(height: 12),
            const Text(
              "This device can't listen right now, so the speaking game "
              'is taking a nap. Ask a grown-up to check the microphone '
              'permission, or play a different lesson!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}
