import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central "Sprout" design tokens and [ThemeData].
///
/// Soft sticker-book direction: warm cream canvas, leafy-green primary, rounded
/// Fredoka display + Nunito body, and a chunky "0 Ypx 0" bottom shadow that
/// gives buttons and tiles a tactile, pressable feel.
///
/// Accessibility table-stakes are preserved from the original theme: large
/// glanceable tap targets, big readable type, and colorblind-safe feedback that
/// never relies on red-vs-green alone (success/failure also carry an icon).
abstract final class AppTheme {
  // ---- sizing -------------------------------------------------------------
  /// Minimum tap-target edge for interactive tiles.
  static const double minTapTarget = 96;

  /// Standard spacing unit.
  static const double gap = 16;

  static const double cardRadius = 28;
  static const double tileRadius = 26;
  static const double buttonRadius = 22;

  // ---- Sprout palette -----------------------------------------------------
  static const Color cream = Color(0xFFFFF9F0); // app background
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color ink = Color(0xFF38302A); // primary text (warm near-black)
  static const Color inkSoft = Color(0xFF8A7E72); // secondary text
  static const Color inkFaint = Color(0xFFA8967E); // tertiary / captions
  static const Color hairline = Color(0xFFF0E8DA); // borders/dividers

  static const Color grass = Color(0xFF46B97E); // primary
  static const Color grassDeep = Color(0xFF2F9E68); // pressed shadow / mastered
  static const Color sky = Color(0xFF5BAEE6);
  static const Color sun = Color(0xFFFFC24B);
  static const Color tangerine = Color(0xFFC97A1E); // streak / stars text
  static const Color coral = Color(0xFFFF6B57);
  static const Color coralDeep = Color(0xFFE2543F);
  static const Color grape = Color(0xFFA988E0);

  // ---- Colorblind-safe feedback (kept, mapped onto Sprout) ----------------
  static const Color correct = grassDeep; // bluish green
  static const Color incorrect = coral; // warm vermillion
  static const Color accent = Color(0xFF0072B2); // blue (parent charts)
  static const Color highlight = sun;

  // ---- helpers ------------------------------------------------------------
  /// The signature chunky bottom shadow (hard, no blur). Pass the darker
  /// shade of whatever surface it sits under.
  static List<BoxShadow> chunky(Color shade, {double y = 7}) =>
      [BoxShadow(color: shade, offset: Offset(0, y), blurRadius: 0)];

  /// Soft elevated card shadow.
  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x232F9E68),
          offset: Offset(0, 10),
          blurRadius: 26,
          spreadRadius: -12,
        ),
      ];

  /// Standard white rounded card decoration.
  static BoxDecoration cardDecoration({Color? border}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border ?? hairline),
        boxShadow: softShadow,
      );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: grass,
      primary: grass,
      surface: surface,
      brightness: Brightness.light,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: cream,
      textTheme: base.textTheme.copyWith(
        headlineMedium: GoogleFonts.fredoka(
            fontSize: 26, fontWeight: FontWeight.w600, color: ink),
        headlineSmall: GoogleFonts.fredoka(
            fontSize: 23, fontWeight: FontWeight.w600, color: ink),
        titleLarge: GoogleFonts.fredoka(
            fontSize: 20, fontWeight: FontWeight.w600, color: ink),
        titleMedium: GoogleFonts.fredoka(
            fontSize: 17, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: GoogleFonts.nunito(
            fontSize: 18, fontWeight: FontWeight.w700, color: ink),
        bodyMedium: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w600, color: inkSoft),
        labelLarge: GoogleFonts.fredoka(
            fontSize: 18, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
            fontSize: 18, fontWeight: FontWeight.w600, color: ink),
        iconTheme: const IconThemeData(color: ink),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFFF1DA),
        side: const BorderSide(color: Color(0xFFFFD79B), width: 1.5),
        labelStyle: GoogleFonts.nunito(
            fontSize: 13, fontWeight: FontWeight.w800, color: tangerine),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: grass,
          foregroundColor: Colors.white,
          textStyle:
              GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600),
          minimumSize: const Size(64, 64),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
        ),
      ),
      // Generous default touch targets everywhere.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
