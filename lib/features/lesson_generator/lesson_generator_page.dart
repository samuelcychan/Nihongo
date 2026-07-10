import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/lesson_generator_service.dart';

enum _Status { idle, generating, preview, reviewing, error }

/// M0.5 "Create a lesson" screen (T5): type a topic, generate a draft lesson
/// via the Edge Function, preview it, then approve (moves it into the
/// published course) or reject (deletes it). Every failure path shows a
/// clear, non-silent error with a retry — see docs/implementation-plan.md's
/// failure-modes table (T6).
class LessonGeneratorPage extends ConsumerStatefulWidget {
  const LessonGeneratorPage({super.key});

  @override
  ConsumerState<LessonGeneratorPage> createState() =>
      _LessonGeneratorPageState();
}

class _LessonGeneratorPageState extends ConsumerState<LessonGeneratorPage> {
  final _topicController = TextEditingController();
  _Status _status = _Status.idle;
  GeneratedLesson? _lesson;
  String? _errorMessage;
  List<String>? _errorDetails;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() => _status = _Status.generating);
    try {
      final lesson =
          await ref.read(lessonGeneratorServiceProvider).generate(topic);
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _status = _Status.preview;
      });
    } on LessonGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _errorDetails = e.details;
        _status = _Status.error;
      });
    }
  }

  Future<void> _review(bool approve) async {
    final lesson = _lesson;
    if (lesson == null) return;
    setState(() => _status = _Status.reviewing);
    try {
      final service = ref.read(lessonGeneratorServiceProvider);
      if (approve) {
        await service.approve(lesson.unitId);
      } else {
        await service.reject(lesson.unitId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? '"${lesson.lessonTitle}" approved and published.'
              : '"${lesson.lessonTitle}" rejected and removed.'),
        ),
      );
      setState(() {
        _lesson = null;
        _status = _Status.idle;
        _topicController.clear();
      });
    } on LessonGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _errorDetails = e.details;
        _status = _Status.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = ref.watch(isTeacherProvider).value ?? false;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: const Text('Create a lesson'),
        actions: [
          TextButton.icon(
            key: const Key('teacher_status_button'),
            onPressed: () async {
              if (isTeacher) {
                await ref.read(supabaseClientProvider).auth.signOut();
                await ref
                    .read(supabaseClientProvider)
                    .auth
                    .signInAnonymously();
              } else {
                await context.push('/teacher-login');
              }
            },
            icon: Icon(
              isTeacher ? Icons.school : Icons.school_outlined,
              size: 18,
            ),
            label: Text(isTeacher ? 'Teacher · sign out' : 'Teacher sign-in'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: switch (_status) {
            _Status.idle || _Status.generating => _TopicForm(
                controller: _topicController,
                generating: _status == _Status.generating,
                onGenerate: _generate,
              ),
            _Status.preview || _Status.reviewing => _PreviewCard(
                lesson: _lesson!,
                reviewing: _status == _Status.reviewing,
                isTeacher: isTeacher,
                onApprove: () => _review(true),
                onReject: () => _review(false),
                onSignIn: () => context.push('/teacher-login'),
              ),
            _Status.error => _ErrorCard(
                message: _errorMessage!,
                details: _errorDetails,
                onRetry: () => setState(() => _status = _Status.idle),
              ),
          },
        ),
      ),
    );
  }
}

class _TopicForm extends StatelessWidget {
  const _TopicForm({
    required this.controller,
    required this.generating,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool generating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Type a topic and an AI-generated Japanese vocabulary lesson will '
          'be created as a draft — it stays hidden from learners until you '
          'review and approve it.',
          style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('topic_field'),
          controller: controller,
          enabled: !generating,
          decoration: InputDecoration(
            hintText: 'e.g. "things in a classroom"',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.hairline),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('generate_button'),
          onPressed: generating ? null : onGenerate,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTheme.minTapTarget * 0.6),
          ),
          child: generating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.lesson,
    required this.reviewing,
    required this.isTeacher,
    required this.onApprove,
    required this.onReject,
    required this.onSignIn,
  });

  final GeneratedLesson lesson;
  final bool reviewing;
  final bool isTeacher;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lesson.lessonTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${lesson.items.length} words · draft, not yet visible to learners',
            style: const TextStyle(color: AppTheme.inkFaint, fontSize: 12)),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: lesson.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = lesson.items[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    Text(item.glyph, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.promptText,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    _StarRow(filled: item.difficulty),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (!isTeacher) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.inkSoft, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sign in as a teacher to approve or reject this lesson.',
                    style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                  ),
                ),
                TextButton(
                  key: const Key('preview_signin_button'),
                  onPressed: onSignIn,
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('reject_button'),
                  onPressed: reviewing ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.incorrect,
                    side: const BorderSide(color: AppTheme.incorrect),
                    minimumSize:
                        const Size.fromHeight(AppTheme.minTapTarget * 0.6),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('approve_button'),
                  onPressed: reviewing ? null : onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.correct,
                    minimumSize:
                        const Size.fromHeight(AppTheme.minTapTarget * 0.6),
                  ),
                  child: reviewing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Approve'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.filled});
  final int filled; // difficulty 1-5

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 14,
            color: AppTheme.tangerine,
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final List<String>? details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('error_card'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.error_outline, color: AppTheme.incorrect, size: 40),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        if (details != null && details!.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final d in details!)
            Text('• $d',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('retry_button'),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
