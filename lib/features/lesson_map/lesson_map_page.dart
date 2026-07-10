import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

/// Sprout "Lesson map": a winding path of lesson nodes (done / current /
/// locked) for the published course. Node positions are laid out
/// procedurally from the real lesson list (courses -> units -> lessons) and
/// each node deep-links into its own lesson -- not a single shared one.
class LessonMapPage extends ConsumerWidget {
  const LessonMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7EE), AppTheme.cream],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Could not load the lesson map.\n$e',
                    textAlign: TextAlign.center),
              ),
            ),
            data: (progress) => _MapBody(progress: progress),
          ),
        ),
      ),
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({required this.progress});
  final List<LessonProgress> progress;

  @override
  Widget build(BuildContext context) {
    final done = progress.where((p) => p.status == LessonStatus.done).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COURSE PROGRESS',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.inkFaint)),
                    Text('$done / ${progress.length} lessons complete',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFD79B), width: 1.5),
                ),
                child: const Text('⭐ 26',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.tangerine)),
              ),
            ],
          ),
        ),
        Expanded(
          child: progress.isEmpty
              ? const Center(child: Text('No lessons yet.'))
              : LayoutBuilder(
                  builder: (context, c) {
                    // Fixed per-node spacing + a scrollable canvas, rather
                    // than cramming a variable node count into the fixed
                    // viewport -- the course grows over time (every AI
                    // lesson a teacher approves adds a unit), so the map
                    // must scroll instead of overflowing or squeezing.
                    const nodeSpacing = 220.0;
                    const topPad = 40.0;
                    final n = progress.length;
                    final width = c.maxWidth;
                    final contentHeight =
                        math.max(c.maxHeight, topPad + nodeSpacing * n + 80);

                    Offset pointFor(int i) => Offset(
                        (i.isEven ? 0.62 : 0.16) * width, topPad + i * nodeSpacing);

                    return SingleChildScrollView(
                      child: SizedBox(
                        width: width,
                        height: contentHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DashedPathPainter(
                                  points: [
                                    for (var i = 0; i < n; i++)
                                      pointFor(i) + const Offset(0, 40),
                                  ],
                                ),
                              ),
                            ),
                            const Positioned(left: 24, top: 14, child: _Scenery('🌳')),
                            const Positioned(right: 30, top: 120, child: _Scenery('🌾')),
                            Positioned(
                                left: 28,
                                top: contentHeight - 60,
                                child: const _Scenery('🌻')),
                            for (var i = 0; i < n; i++)
                              Positioned(
                                left: pointFor(i).dx - 42,
                                top: pointFor(i).dy,
                                child: _MapNodeView(
                                  progress: progress[i],
                                  // Locked nodes stay inert; both the active
                                  // node and already-passed ones are tappable
                                  // so a learner can freely retake a
                                  // completed lesson.
                                  onTap: progress[i].status == LessonStatus.locked
                                      ? null
                                      : () => context.push('/play',
                                          extra: progress[i].lesson),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MapNodeView extends StatelessWidget {
  const _MapNodeView({required this.progress, this.onTap});
  final LessonProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = progress.status == LessonStatus.current;
    final done = progress.status == LessonStatus.done;
    final double d = current ? 84 : 62;
    final label = progress.lesson.title;
    final emoji =
        progress.lesson.allItems.isNotEmpty ? progress.lesson.allItems.first.glyph : null;

    final Color bg = current
        ? AppTheme.sun
        : done
            ? AppTheme.grass
            : Colors.white;
    final Color shade = current
        ? const Color(0xFFE09A1E)
        : done
            ? AppTheme.grassDeep
            : const Color(0xFFEFE7DA);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                  color: progress.status == LessonStatus.locked
                      ? AppTheme.hairline
                      : Colors.white,
                  width: current ? 6 : 5),
              boxShadow: AppTheme.chunky(shade, y: current ? 8 : 6),
            ),
            alignment: Alignment.center,
            child: Text(
              current
                  ? (emoji ?? '▶')
                  : done
                      ? '✓'
                      : '🔒',
              style: TextStyle(
                  fontSize: current ? 40 : 24,
                  color: done ? Colors.white : null,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 5),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8)
                ],
              ),
              child: Text('▶ $label',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppTheme.tangerine)),
            )
          else
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: done ? AppTheme.grassDeep : AppTheme.inkFaint)),
        ],
      ),
    );
  }
}

class _Scenery extends StatelessWidget {
  const _Scenery(this.emoji);
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}

/// Draws a soft dashed poly-curve connecting the node centres.
class _DashedPathPainter extends CustomPainter {
  _DashedPathPainter({required this.points});
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = const Color(0xFFD9CDBA)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, mid.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(cur.dx, mid.dy, cur.dx, cur.dy);
    }
    _drawDashed(canvas, path, paint);
  }

  void _drawDashed(Canvas canvas, Path source, Paint paint) {
    const dash = 2.0;
    const gap = 15.0;
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dash, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPathPainter old) => old.points != points;
}
