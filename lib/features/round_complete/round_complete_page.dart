import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';

/// Outcome handed to [RoundCompletePage] via the router's `extra`.
class RoundSummary {
  const RoundSummary({
    required this.title,
    required this.stars,
    required this.starsEarned,
  });
  final String title;
  final int stars;
  final int starsEarned;
}

/// Sprout "Round complete" celebration. Shown after a match round finishes.
///
/// Pass the round's outcome in; defaults make it previewable on its own. Wire it
/// up from [ActivityMatchPage] by computing stars from attempts/accuracy and
/// either pushing this route or showing it inline in place of the done view.
class RoundCompletePage extends StatelessWidget {
  const RoundCompletePage({
    super.key,
    this.title = 'Animals',
    this.stars = 2,
    this.starsEarned = 15,
    this.rewardName = 'Bessie the Cow',
    this.heroEmoji = '🐮',
  });

  final String title;
  final int stars; // 0..3
  final int starsEarned;
  final String rewardName;
  final String heroEmoji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4DF), AppTheme.cream],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // hero
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(0, -0.3),
                        colors: [Color(0xFFFFE7A8), AppTheme.sun],
                      ),
                      boxShadow: AppTheme.chunky(const Color(0xFFE09A1E), y: 10),
                    ),
                    alignment: Alignment.center,
                    child: Text(heroEmoji, style: const TextStyle(fontSize: 62)),
                  ),
                )
                    .animate()
                    .scaleXY(begin: 0.6, end: 1, duration: 420.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 18),
                Text('すごい！',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text('You finished the $title round',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.inkFaint)),
                const SizedBox(height: 16),
                _Stars(filled: stars),
                const SizedBox(height: 16),
                Center(child: _StarsEarnedChip(amount: starsEarned)),
                const SizedBox(height: 18),
                _RewardCard(name: rewardName),
                const Spacer(),
                _PrimaryButton(
                  label: 'Keep going →',
                  onTap: () => context.go('/map'),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back home',
                        style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.inkSoft)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 1 ? 10 : 0),
            child: Opacity(
              opacity: i < filled ? 1 : 0.32,
              child: Text('⭐',
                  style: TextStyle(fontSize: i == 1 ? 56 : 42)),
            ).animate(delay: (180 * i).ms).scaleXY(
                begin: 0.2,
                end: 1,
                duration: 360.ms,
                curve: Curves.easeOutBack),
          ),
      ],
    );
  }
}

class _StarsEarnedChip extends StatelessWidget {
  const _StarsEarnedChip({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD79B), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12)],
      ),
      child: Text('+$amount ⭐ stars earned',
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.tangerine)),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFFD9CDBA),
            width: 2,
            style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          // placeholder sticker swatch — swap for real art
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6F0E6), Color(0xFFF0E8DA)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text('🐮', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NEW STICKER UNLOCKED',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppTheme.grass)),
              Text(name,
                  style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.grass,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.chunky(AppTheme.grassDeep),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white)),
        ),
      ),
    );
  }
}
