import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/models/content.dart';

/// M1 NFR-safety: a minimal parental-consent gate shown once before first
/// play. Anonymous auth continues underneath -- this doesn't collect any
/// identity data, it's a lightweight age/attention gate (a simple math
/// question a young child is unlikely to answer, common in kids-app consent
/// flows) plus an explicit guardian confirmation checkbox.
class ConsentGatePage extends ConsumerStatefulWidget {
  const ConsentGatePage({super.key, this.pendingLesson});

  /// The lesson the learner was trying to play when the gate interrupted
  /// them -- forwarded to `/play` once consent is confirmed.
  final Lesson? pendingLesson;

  @override
  ConsumerState<ConsentGatePage> createState() => _ConsentGatePageState();
}

class _ConsentGatePageState extends ConsumerState<ConsentGatePage> {
  late final int _a;
  late final int _b;
  final _answerController = TextEditingController();
  bool _agreed = false;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _a = 3 + rand.nextInt(6); // 3..8
    _b = 3 + rand.nextInt(6);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final answer = int.tryParse(_answerController.text.trim());
    if (answer != _a + _b) {
      setState(() => _error = "That answer doesn't look right. Please try again.");
      return;
    }
    if (!_agreed) {
      setState(() => _error = 'Please confirm you are the parent or guardian.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await ref
          .read(consentStoreProvider)
          .setConsentGiven(ref.read(learnerIdProvider), true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong saving that. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    if (widget.pendingLesson != null) {
      context.pushReplacement('/play', extra: widget.pendingLesson);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: const Text('For Parents & Guardians'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.family_restroom, size: 56, color: AppTheme.grass),
              const SizedBox(height: 12),
              const Text(
                'Before your child starts playing, we need a parent or '
                "guardian to confirm they're setting this up.",
                style: TextStyle(fontSize: 15, color: AppTheme.inkSoft, height: 1.4),
              ),
              const SizedBox(height: 20),
              Text('Quick check: what is $_a + $_b?',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                key: const Key('consent_answer_field'),
                controller: _answerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Your answer',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                key: const Key('consent_checkbox'),
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "I am this child's parent or guardian and I agree to "
                  'let them use this app.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppTheme.incorrect, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('consent_continue_button'),
                onPressed: _submitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppTheme.minTapTarget * 0.6),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
