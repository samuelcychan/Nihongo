import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

/// Sprout "Lesson map": a winding path of lesson nodes (done / current / locked)
/// for the current unit. The active node deep-links into the seed match game.
///
/// Node data is a local list for now — wire it to the content hierarchy
/// (units -> lessons) and per-lesson mastery when that data is available.
class LessonMapPage extends ConsumerWidget {
  const LessonMapPage({super.key});

  static const _nodes = <_MapNode>[
    _MapNode('Colors', 0.62, 0.04, _NodeState.done),
    _MapNode('Food', 0.12, 0.24, _NodeState.done),
    _MapNode('Animals', 0.46, 0.46, _NodeState.current, emoji: '🐮'),
    _MapNode('Family', 0.12, 0.70, _NodeState.locked),
    _MapNode('Numbers', 0.46, 0.90, _NodeState.locked),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(seedLessonProvider);

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UNIT 1',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppTheme.inkFaint)),
                          Text('Around the Farm',
                              style:
                                  Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFFFFD79B), width: 1.5),
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
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = Size(c.maxWidth, c.maxHeight);
                    return Stack(
                      children: [
                        // dashed connecting path
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DashedPathPainter(
                              points: [
                                for (final n in _nodes)
                                  Offset(n.fx * size.width,
                                      n.fy * size.height + 40),
                              ],
                            ),
                          ),
                        ),
                        // scenery
                        const Positioned(
                            left: 24, top: 14, child: _Scenery('🌳')),
                        const Positioned(
                            right: 30, top: 120, child: _Scenery('🌾')),
                        const Positioned(
                            left: 28, bottom: 40, child: _Scenery('🌻')),
                        // nodes
                        for (final n in _nodes)
                          Positioned(
                            left: n.fx * size.width - 42,
                            top: n.fy * size.height,
                            child: _MapNodeView(
                              node: n,
                              onTap: n.state == _NodeState.current
                                  ? () {
                                      final lesson = lessonAsync.value;
                                      if (lesson != null) {
                                        context.push('/play', extra: lesson);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NodeState { done, current, locked }

class _MapNode {
  const _MapNode(this.label, this.fx, this.fy, this.state, {this.emoji});
  final String label;
  final double fx; // 0..1 horizontal
  final double fy; // 0..1 vertical
  final _NodeState state;
  final String? emoji;
}

class _MapNodeView extends StatelessWidget {
  const _MapNodeView({required this.node, this.onTap});
  final _MapNode node;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = node.state == _NodeState.current;
    final done = node.state == _NodeState.done;
    final double d = current ? 84 : 62;

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
                  color: node.state == _NodeState.locked
                      ? AppTheme.hairline
                      : Colors.white,
                  width: current ? 6 : 5),
              boxShadow: AppTheme.chunky(shade, y: current ? 8 : 6),
            ),
            alignment: Alignment.center,
            child: Text(
              current
                  ? (node.emoji ?? '▶')
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
              child: Text('▶ ${node.label}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppTheme.tangerine)),
            )
          else
            Text(node.label,
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
