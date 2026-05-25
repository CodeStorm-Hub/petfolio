import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PetfolioThemeExtension
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class PetfolioThemeExtension extends ThemeExtension<PetfolioThemeExtension> {
  const PetfolioThemeExtension({
    required this.ink500,
    required this.ink300,
    required this.line200,
    required this.line100,
    required this.surface1,
    required this.surface2,
    required this.warmCream,
    required this.success,
    required this.warning,
    required this.info,
    required this.pillarSocial,
    required this.pillarMatch,
    required this.pillarHealth,
    required this.pillarMarket,
    required this.glassFill,
    required this.glassTopBorder,
    required this.glassRimBorder,
    required this.glassShine,
    required this.glassBlurSigma,
    required this.shadowE1,
    required this.shadowE2,
    required this.shadowE3,
    required this.shadowE4,
    required this.shadowGlass,
  });

  final Color ink500;
  final Color ink300;
  final Color line200;
  final Color line100;

  final Color surface1;
  final Color surface2;
  final Color warmCream;

  final Color success;
  final Color warning;
  final Color info;

  final Color pillarSocial;
  final Color pillarMatch;
  final Color pillarHealth;
  final Color pillarMarket;

  final Color glassFill;
  final Color glassTopBorder;
  final Color glassRimBorder;
  final Color glassShine;
  final double glassBlurSigma;

  final List<BoxShadow> shadowE1;
  final List<BoxShadow> shadowE2;
  final List<BoxShadow> shadowE3;
  final List<BoxShadow> shadowE4;
  final List<BoxShadow> shadowGlass;

  // ── §4.4 Radius scale ────────────────────────────────────────────────────
  static const double radiusXs   = 6.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radius2xl  = 28.0;
  static const double radius3xl  = 32.0;
  static const double radiusPill = 999.0;

  // ── §8 Motion durations ──────────────────────────────────────────────────
  static const durationXs = Duration(milliseconds: 80);
  static const durationSm = Duration(milliseconds: 140);
  static const durationMd = Duration(milliseconds: 220);
  static const durationLg = Duration(milliseconds: 320);
  static const durationXl = Duration(milliseconds: 500);

  // ── §5.1 Button heights ──────────────────────────────────────────────────
  static const double btnHeightSm   = 36.0;
  static const double btnHeightMd   = 44.0;
  static const double btnHeightLg   = 52.0;
  static const double btnHeightXl   = 60.0;
  static const double btnHeightWalk = 64.0;

  // ── Pre-built instances ──────────────────────────────────────────────────
  static const PetfolioThemeExtension light = PetfolioThemeExtension(
    ink500: AppColors.ink500,
    ink300: AppColors.ink300,
    line200: AppColors.line200,
    line100: AppColors.line100,
    surface1: AppColors.surface1,
    surface2: AppColors.surface2,
    warmCream: AppColors.cream50,
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    pillarSocial: AppColors.sunset500,
    pillarMatch: AppColors.coral500,
    pillarHealth: AppColors.meadow500,
    pillarMarket: AppColors.apricot500,
    glassFill: AppColors.glassFillL,
    glassTopBorder: AppColors.glassTopL,
    glassRimBorder: AppColors.glassRimL,
    glassShine: AppColors.glassShineL,
    glassBlurSigma: 24.0,
    shadowE1: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: AppColors.shadowE1L),
    ],
    shadowE2: [
      BoxShadow(offset: Offset(0, 4), blurRadius: 12, spreadRadius: -2, color: AppColors.shadowE2L),
    ],
    shadowE3: [
      BoxShadow(offset: Offset(0, 12), blurRadius: 28, spreadRadius: -6, color: AppColors.shadowE3L),
    ],
    shadowE4: [
      BoxShadow(offset: Offset(0, 20), blurRadius: 40, spreadRadius: -8, color: AppColors.shadowE4L),
    ],
    shadowGlass: [
      BoxShadow(offset: Offset(0, 16), blurRadius: 40, spreadRadius: -8, color: AppColors.shadowGlassL),
    ],
  );

  static const PetfolioThemeExtension dark = PetfolioThemeExtension(
    ink500: AppColors.ink500D,
    ink300: AppColors.ink300D,
    line200: AppColors.line200D,
    line100: AppColors.line100D,
    surface1: AppColors.surface1D,
    surface2: AppColors.surface2D,
    warmCream: AppColors.surface2D,
    success: AppColors.successD,
    warning: AppColors.warningD,
    info: AppColors.infoD,
    pillarSocial: AppColors.sunset500D,
    pillarMatch: AppColors.coral500D,
    pillarHealth: AppColors.meadow500D,
    pillarMarket: AppColors.apricot500D,
    glassFill: AppColors.glassFillD,
    glassTopBorder: AppColors.glassTopD,
    glassRimBorder: AppColors.glassRimD,
    glassShine: AppColors.glassShineD,
    glassBlurSigma: 28.0,
    shadowE1: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: AppColors.shadowE1D),
    ],
    shadowE2: [
      BoxShadow(offset: Offset(0, 6), blurRadius: 14, spreadRadius: -2, color: AppColors.shadowE2D),
    ],
    shadowE3: [
      BoxShadow(offset: Offset(0, 14), blurRadius: 32, spreadRadius: -6, color: AppColors.shadowE3D),
    ],
    shadowE4: [
      BoxShadow(offset: Offset(0, 24), blurRadius: 48, spreadRadius: -10, color: AppColors.shadowE4D),
    ],
    shadowGlass: [
      BoxShadow(offset: Offset(0, 18), blurRadius: 48, spreadRadius: -10, color: AppColors.shadowGlassD),
    ],
  );

  // ── ThemeExtension API ────────────────────────────────────────────────────
  @override
  PetfolioThemeExtension copyWith({
    Color? ink500,
    Color? ink300,
    Color? line200,
    Color? line100,
    Color? surface1,
    Color? surface2,
    Color? warmCream,
    Color? success,
    Color? warning,
    Color? info,
    Color? pillarSocial,
    Color? pillarMatch,
    Color? pillarHealth,
    Color? pillarMarket,
    Color? glassFill,
    Color? glassTopBorder,
    Color? glassRimBorder,
    Color? glassShine,
    double? glassBlurSigma,
    List<BoxShadow>? shadowE1,
    List<BoxShadow>? shadowE2,
    List<BoxShadow>? shadowE3,
    List<BoxShadow>? shadowE4,
    List<BoxShadow>? shadowGlass,
  }) =>
      PetfolioThemeExtension(
        ink500: ink500 ?? this.ink500,
        ink300: ink300 ?? this.ink300,
        line200: line200 ?? this.line200,
        line100: line100 ?? this.line100,
        surface1: surface1 ?? this.surface1,
        surface2: surface2 ?? this.surface2,
        warmCream: warmCream ?? this.warmCream,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        pillarSocial: pillarSocial ?? this.pillarSocial,
        pillarMatch: pillarMatch ?? this.pillarMatch,
        pillarHealth: pillarHealth ?? this.pillarHealth,
        pillarMarket: pillarMarket ?? this.pillarMarket,
        glassFill: glassFill ?? this.glassFill,
        glassTopBorder: glassTopBorder ?? this.glassTopBorder,
        glassRimBorder: glassRimBorder ?? this.glassRimBorder,
        glassShine: glassShine ?? this.glassShine,
        glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
        shadowE1: shadowE1 ?? this.shadowE1,
        shadowE2: shadowE2 ?? this.shadowE2,
        shadowE3: shadowE3 ?? this.shadowE3,
        shadowE4: shadowE4 ?? this.shadowE4,
        shadowGlass: shadowGlass ?? this.shadowGlass,
      );

  @override
  PetfolioThemeExtension lerp(PetfolioThemeExtension? other, double t) {
    if (other is! PetfolioThemeExtension) return this;
    return PetfolioThemeExtension(
      ink500: Color.lerp(ink500, other.ink500, t)!,
      ink300: Color.lerp(ink300, other.ink300, t)!,
      line200: Color.lerp(line200, other.line200, t)!,
      line100: Color.lerp(line100, other.line100, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      warmCream: Color.lerp(warmCream, other.warmCream, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      pillarSocial: Color.lerp(pillarSocial, other.pillarSocial, t)!,
      pillarMatch: Color.lerp(pillarMatch, other.pillarMatch, t)!,
      pillarHealth: Color.lerp(pillarHealth, other.pillarHealth, t)!,
      pillarMarket: Color.lerp(pillarMarket, other.pillarMarket, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassTopBorder: Color.lerp(glassTopBorder, other.glassTopBorder, t)!,
      glassRimBorder: Color.lerp(glassRimBorder, other.glassRimBorder, t)!,
      glassShine: Color.lerp(glassShine, other.glassShine, t)!,
      glassBlurSigma: lerpDouble(glassBlurSigma, other.glassBlurSigma, t),
      shadowE1: BoxShadow.lerpList(shadowE1, other.shadowE1, t) ?? shadowE1,
      shadowE2: BoxShadow.lerpList(shadowE2, other.shadowE2, t) ?? shadowE2,
      shadowE3: BoxShadow.lerpList(shadowE3, other.shadowE3, t) ?? shadowE3,
      shadowE4: BoxShadow.lerpList(shadowE4, other.shadowE4, t) ?? shadowE4,
      shadowGlass: BoxShadow.lerpList(shadowGlass, other.shadowGlass, t) ?? shadowGlass,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────
final class AppThemeSpacing {
  const AppThemeSpacing();
  double get xs => 4;
  double get sm => 8;
  double get md => 12;
  double get lg => 16;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
  static const AppThemeSpacing spacing = AppThemeSpacing();

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final cs = _colorScheme(isDark);
    final tt = _textTheme(isDark);
    final ext = isDark ? PetfolioThemeExtension.dark : PetfolioThemeExtension.light;
    final pt = ext;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: tt,
      extensions: [pt],

      // ── Scaffold ──────────────────────────────────────────
      scaffoldBackgroundColor: isDark ? AppColors.surface1D : AppColors.cream50,

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.cream50,
        foregroundColor: isDark ? AppColors.ink950D : AppColors.ink950,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? AppColors.shadowE1D : AppColors.shadowE1L,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.ink950D : AppColors.ink950,
          height: 1.2,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.ink700D : AppColors.ink700,
        ),
      ),

      // ── NavigationBar (mobile bottom nav) ─────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.cream50,
        indicatorColor: isDark
            ? AppColors.amber700.withAlpha(80)
            : AppColors.cream200,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.amber500 : AppColors.amber700,
            );
          }
          return IconThemeData(
            color: isDark ? AppColors.ink500D : AppColors.ink500,
          );
        }),
      ),

      // ── NavigationRail (tablet/web) ───────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.surface0,
        indicatorColor: isDark
            ? AppColors.amber700.withAlpha(80)
            : AppColors.cream200,
        selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.amber500 : AppColors.amber700,
        ),
        unselectedIconTheme: IconThemeData(
          color: isDark ? AppColors.ink500D : AppColors.ink500,
        ),
        labelType: NavigationRailLabelType.all,
        elevation: 0,
      ),

      // ── Card ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surface0D : AppColors.surface0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius3xl),
          side: BorderSide(
            color: isDark ? AppColors.line200D : AppColors.line200,
            width: 0.5,
          ),
        ),
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.line200D : AppColors.line200,
        thickness: 1,
        space: 0,
      ),

      // ── Input ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface2D : AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.line200D : AppColors.line200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.line200D : AppColors.line200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.amber500 : AppColors.amber500,
            width: 2,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: isDark ? AppColors.ink300D : AppColors.ink300,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chip ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surface2D : AppColors.cream100,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.ink950D : AppColors.warmBlack,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── FilledButton (primary) ────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.amber500.withAlpha(102);
            }
            return AppColors.amber500;
          }),
          foregroundColor: WidgetStateProperty.all(AppColors.warmBlack),
          minimumSize: const WidgetStatePropertyAll(
            Size(120, PetfolioThemeExtension.btnHeightLg),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      // ── OutlinedButton (secondary/ghost) ──────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(
            isDark ? AppColors.amber500 : AppColors.amber700,
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: isDark ? AppColors.amber500 : AppColors.amber500),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(96, PetfolioThemeExtension.btnHeightMd),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // ── NavigationDrawer (expanded/desktop sidebar) ───────
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.surface0,
        indicatorColor: isDark ? AppColors.amber700.withAlpha(80) : AppColors.cream100,
        indicatorShape: const StadiumBorder(),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.inter(
            fontSize: 14,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          );
          return base.copyWith(
            color: states.contains(WidgetState.selected)
                ? (isDark ? AppColors.amber500 : AppColors.amber700)
                : (isDark ? AppColors.ink700D : AppColors.ink700),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.amber500 : AppColors.amber700,
            );
          }
          return IconThemeData(
            color: isDark ? AppColors.ink500D : AppColors.ink500,
          );
        }),
      ),

      // ── SnackBar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surface2D : AppColors.ink950,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppColors.ink950D : AppColors.surface0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Color Scheme ───────────────────────────────────────────────────────────
  static ColorScheme _colorScheme(bool isDark) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.amber500,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return base.copyWith(
      primary: isDark ? AppColors.amber500 : AppColors.amber500,
      onPrimary: AppColors.warmBlack,
      primaryContainer: isDark ? AppColors.amber700.withAlpha(60) : AppColors.cream100,
      onPrimaryContainer: isDark ? AppColors.amber500 : AppColors.amber700,
      secondary: isDark ? AppColors.sunset500D : AppColors.sunset500,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF3D2510)
          : const Color(0xFFFEEBD7),
      onSecondaryContainer: isDark
          ? AppColors.sunset500D
          : const Color(0xFF7A4B20),
      tertiary: isDark ? AppColors.meadow500D : AppColors.meadow500,
      onTertiary: Colors.white,
      tertiaryContainer: isDark
          ? const Color(0xFF173D2E)
          : const Color(0xFFD7F0E5),
      onTertiaryContainer: isDark
          ? AppColors.meadow500D
          : const Color(0xFF1F5C40),
      error: isDark ? AppColors.dangerD : AppColors.danger,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF4D1515)
          : const Color(0xFFFFDADA),
      onErrorContainer: isDark ? AppColors.dangerD : AppColors.danger,
      surface: isDark ? AppColors.surface0D : AppColors.surface0,
      onSurface: isDark ? AppColors.ink950D : AppColors.ink950,
      surfaceContainerLowest: isDark ? AppColors.surface0D : AppColors.surface0,
      surfaceContainerLow: isDark ? AppColors.surface1D : AppColors.cream50,
      surfaceContainer: isDark ? AppColors.surface1D : AppColors.cream50,
      surfaceContainerHigh: isDark ? AppColors.surface2D : AppColors.cream100,
      surfaceContainerHighest: isDark ? AppColors.surface2D : AppColors.cream200,
      onSurfaceVariant: isDark ? AppColors.ink700D : AppColors.ink700,
      outline: isDark ? AppColors.line200D : AppColors.line200,
      outlineVariant: isDark ? AppColors.line100D : AppColors.line100,
      shadow: isDark ? Colors.black : AppColors.shadowInk,
      scrim: const Color(0x59000000),
      inverseSurface: isDark ? AppColors.surface0 : AppColors.ink950,
      onInverseSurface: isDark ? AppColors.ink950 : AppColors.surface0,
      inversePrimary: isDark ? AppColors.amber500 : AppColors.cream200,
    );
  }

  // ── Text Theme — §3.2 Adaptive Type Scale ─────────────────────────────────
  // Fredoka → display, headline, titleLarge roles  (warm display & UI)
  // Inter   → body, label, title roles             (Body & Numerics)
  static TextTheme _textTheme(bool isDark) {
    final headColor = isDark ? AppColors.ink950D : AppColors.ink950;
    final bodyColor = isDark ? AppColors.ink700D : AppColors.ink700;

    return TextTheme(
      // Display XL — 36sp / 600
      displayLarge: GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -0.54,
        color: headColor,
      ),
      // Display — 30sp / 600
      displayMedium: GoogleFonts.fredoka(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.08,
        letterSpacing: -0.30,
        color: headColor,
      ),
      // Headline — 24sp / 500
      displaySmall: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.12,
        color: headColor,
      ),
      headlineLarge: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.12,
        color: headColor,
      ),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0,
        color: headColor,
      ),
      headlineSmall: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0,
        color: headColor,
      ),
      titleLarge: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0,
        color: headColor,
      ),
      // Body L — 17sp / 500 (Inter)
      titleMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0,
        color: bodyColor,
      ),
      // Body — 16sp / 500 (Inter)
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
        color: bodyColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: bodyColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
        color: bodyColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.07,
        color: bodyColor,
      ),
      // Caption — 12sp / 500
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.18,
        color: isDark ? AppColors.ink500D : AppColors.ink500,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.18,
        color: isDark ? AppColors.ink500D : AppColors.ink500,
      ),
      // Overline — 11sp / 600
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.88,
        color: isDark ? AppColors.ink500D : AppColors.ink500,
      ),
    );
  }
}
