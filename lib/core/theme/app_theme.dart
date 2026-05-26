import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

@immutable
class PetFolioColors extends ThemeExtension<PetFolioColors> {
  const PetFolioColors({
    required this.tangerine,
    required this.tangerine700,
    required this.tangerineSoft,
    required this.poppy,
    required this.poppy700,
    required this.poppySoft,
    required this.mint,
    required this.mint700,
    required this.mintSoft,
    required this.sunny,
    required this.sunny700,
    required this.sunnySoft,
    required this.lilac,
    required this.lilac700,
    required this.lilacSoft,
    required this.sky,
    required this.sky700,
    required this.skySoft,
  });

  final Color tangerine;
  final Color tangerine700;
  final Color tangerineSoft;
  final Color poppy;
  final Color poppy700;
  final Color poppySoft;
  final Color mint;
  final Color mint700;
  final Color mintSoft;
  final Color sunny;
  final Color sunny700;
  final Color sunnySoft;
  final Color lilac;
  final Color lilac700;
  final Color lilacSoft;
  final Color sky;
  final Color sky700;
  final Color skySoft;

  static const PetFolioColors light = PetFolioColors(
    tangerine: AppColors.tangerine,
    tangerine700: AppColors.tangerine700,
    tangerineSoft: AppColors.tangerineSoft,
    poppy: AppColors.poppy,
    poppy700: AppColors.poppy700,
    poppySoft: AppColors.poppySoft,
    mint: AppColors.mint,
    mint700: AppColors.mint700,
    mintSoft: AppColors.mintSoft,
    sunny: AppColors.sunny,
    sunny700: AppColors.sunny700,
    sunnySoft: AppColors.sunnySoft,
    lilac: AppColors.lilac,
    lilac700: AppColors.lilac700,
    lilacSoft: AppColors.lilacSoft,
    sky: AppColors.sky,
    sky700: AppColors.sky700,
    skySoft: AppColors.skySoft,
  );

  static const PetFolioColors dark = PetFolioColors(
    tangerine: AppColors.tangerineD,
    tangerine700: AppColors.tangerine700D,
    tangerineSoft: AppColors.tangerineSoftD,
    poppy: AppColors.poppyD,
    poppy700: AppColors.poppy700D,
    poppySoft: AppColors.poppySoftD,
    mint: AppColors.mintD,
    mint700: AppColors.mint700D,
    mintSoft: AppColors.mintSoftD,
    sunny: AppColors.sunnyD,
    sunny700: AppColors.sunny700D,
    sunnySoft: AppColors.sunnySoftD,
    lilac: AppColors.lilacD,
    lilac700: AppColors.lilac700D,
    lilacSoft: AppColors.lilacSoftD,
    sky: AppColors.skyD,
    sky700: AppColors.sky700,
    skySoft: AppColors.skySoftD,
  );

  @override
  PetFolioColors copyWith({
    Color? tangerine, Color? tangerine700, Color? tangerineSoft,
    Color? poppy, Color? poppy700, Color? poppySoft,
    Color? mint, Color? mint700, Color? mintSoft,
    Color? sunny, Color? sunny700, Color? sunnySoft,
    Color? lilac, Color? lilac700, Color? lilacSoft,
    Color? sky, Color? sky700, Color? skySoft,
  }) {
    return PetFolioColors(
      tangerine: tangerine ?? this.tangerine,
      tangerine700: tangerine700 ?? this.tangerine700,
      tangerineSoft: tangerineSoft ?? this.tangerineSoft,
      poppy: poppy ?? this.poppy,
      poppy700: poppy700 ?? this.poppy700,
      poppySoft: poppySoft ?? this.poppySoft,
      mint: mint ?? this.mint,
      mint700: mint700 ?? this.mint700,
      mintSoft: mintSoft ?? this.mintSoft,
      sunny: sunny ?? this.sunny,
      sunny700: sunny700 ?? this.sunny700,
      sunnySoft: sunnySoft ?? this.sunnySoft,
      lilac: lilac ?? this.lilac,
      lilac700: lilac700 ?? this.lilac700,
      lilacSoft: lilacSoft ?? this.lilacSoft,
      sky: sky ?? this.sky,
      sky700: sky700 ?? this.sky700,
      skySoft: skySoft ?? this.skySoft,
    );
  }

  @override
  PetFolioColors lerp(ThemeExtension<PetFolioColors>? other, double t) {
    if (other is! PetFolioColors) return this;
    return PetFolioColors(
      tangerine: Color.lerp(tangerine, other.tangerine, t)!,
      tangerine700: Color.lerp(tangerine700, other.tangerine700, t)!,
      tangerineSoft: Color.lerp(tangerineSoft, other.tangerineSoft, t)!,
      poppy: Color.lerp(poppy, other.poppy, t)!,
      poppy700: Color.lerp(poppy700, other.poppy700, t)!,
      poppySoft: Color.lerp(poppySoft, other.poppySoft, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mint700: Color.lerp(mint700, other.mint700, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      sunny: Color.lerp(sunny, other.sunny, t)!,
      sunny700: Color.lerp(sunny700, other.sunny700, t)!,
      sunnySoft: Color.lerp(sunnySoft, other.sunnySoft, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      lilac700: Color.lerp(lilac700, other.lilac700, t)!,
      lilacSoft: Color.lerp(lilacSoft, other.lilacSoft, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      sky700: Color.lerp(sky700, other.sky700, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
    );
  }
}

@immutable
class PetfolioThemeExtension extends ThemeExtension<PetfolioThemeExtension> {
  const PetfolioThemeExtension({
    required this.ink950,
    required this.ink700,
    required this.ink500,
    required this.ink300,
    required this.line,
    required this.line2,
    required this.surface1,
    required this.surface2,
    required this.cream,
    required this.cream2,
    required this.success,
    required this.warning,
    required this.info,
    // Pillar accents
    required this.pillarPets,
    required this.pillarCare,
    required this.pillarSocial,
    required this.pillarMatch,
    required this.pillarHealth,
    required this.pillarMarket,
    // Soft fills
    required this.tangerineSoft,
    required this.poppySoft,
    required this.mintSoft,
    required this.sunnySoft,
    required this.lilacSoft,
    required this.skySoft,
    // Glass
    required this.glassFill,
    required this.glassTopBorder,
    required this.glassRimBorder,
    required this.glassShine,
    required this.glassBlurSigma,
    // Shadows
    required this.shadowE1,
    required this.shadowE2,
    required this.shadowE3,
    required this.shadowE4,
    required this.shadowGlass,
  });

  final Color ink950;
  final Color ink700;
  final Color ink500;
  final Color ink300;
  final Color line;
  final Color line2;
  final Color surface1;
  final Color surface2;
  final Color cream;
  final Color cream2;

  final Color success;
  final Color warning;
  final Color info;

  final Color pillarPets;
  final Color pillarCare;
  final Color pillarSocial;
  final Color pillarMatch;
  final Color pillarHealth;
  final Color pillarMarket;

  final Color tangerineSoft;
  final Color poppySoft;
  final Color mintSoft;
  final Color sunnySoft;
  final Color lilacSoft;
  final Color skySoft;

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

  // ── Static radius / motion tokens ────────────────────────────────────────────
  static const double radiusXs   = 6.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radius2xl  = 28.0;
  static const double radius3xl  = 32.0;
  static const double radiusPill = 999.0;

  static const durationXs = Duration(milliseconds: 80);
  static const durationSm = Duration(milliseconds: 140);
  static const durationMd = Duration(milliseconds: 220);
  static const durationLg = Duration(milliseconds: 320);
  static const durationXl = Duration(milliseconds: 500);

  static const double btnHeightSm   = 36.0;
  static const double btnHeightMd   = 44.0;
  static const double btnHeightLg   = 52.0;
  static const double btnHeightXl   = 60.0;
  static const double btnHeightWalk = 64.0;

  // ── Pre-built instances ───────────────────────────────────────────────────────
  static const PetfolioThemeExtension light = PetfolioThemeExtension(
    ink950: AppColors.ink950,
    ink700: AppColors.ink700,
    ink500: AppColors.ink500,
    ink300: AppColors.ink300,
    line: AppColors.line,
    line2: AppColors.line2,
    surface1: AppColors.surface1,
    surface2: AppColors.surface2,
    cream: AppColors.cream,
    cream2: AppColors.cream2,
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    pillarPets: AppColors.tangerine,
    pillarCare: AppColors.sunny,
    pillarSocial: AppColors.poppy,
    pillarMatch: AppColors.lilac,
    pillarHealth: AppColors.mint,
    pillarMarket: AppColors.mint,
    tangerineSoft: AppColors.tangerineSoft,
    poppySoft: AppColors.poppySoft,
    mintSoft: AppColors.mintSoft,
    sunnySoft: AppColors.sunnySoft,
    lilacSoft: AppColors.lilacSoft,
    skySoft: AppColors.skySoft,
    glassFill: AppColors.glassFillL,
    glassTopBorder: AppColors.glassTopL,
    glassRimBorder: AppColors.glassRimL,
    glassShine: AppColors.glassShineL,
    glassBlurSigma: 24.0,
    shadowE1: [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: AppColors.shadowE1L)],
    shadowE2: [BoxShadow(offset: Offset(0, 4), blurRadius: 12, spreadRadius: -2, color: AppColors.shadowE2L)],
    shadowE3: [BoxShadow(offset: Offset(0, 12), blurRadius: 28, spreadRadius: -6, color: AppColors.shadowE3L)],
    shadowE4: [BoxShadow(offset: Offset(0, 20), blurRadius: 40, spreadRadius: -8, color: AppColors.shadowE4L)],
    shadowGlass: [BoxShadow(offset: Offset(0, 16), blurRadius: 40, spreadRadius: -8, color: AppColors.shadowGlassL)],
  );

  static const PetfolioThemeExtension dark = PetfolioThemeExtension(
    ink950: AppColors.ink950D,
    ink700: AppColors.ink700D,
    ink500: AppColors.ink500D,
    ink300: AppColors.ink300D,
    line: AppColors.lineD,
    line2: AppColors.line2D,
    surface1: AppColors.surface1D,
    surface2: AppColors.surface2D,
    cream: AppColors.creamD,
    cream2: AppColors.cream2D,
    success: AppColors.successD,
    warning: AppColors.warningD,
    info: AppColors.infoD,
    pillarPets: AppColors.tangerineD,
    pillarCare: AppColors.sunnyD,
    pillarSocial: AppColors.poppyD,
    pillarMatch: AppColors.lilacD,
    pillarHealth: AppColors.mintD,
    pillarMarket: AppColors.mintD,
    tangerineSoft: AppColors.tangerineSoftD,
    poppySoft: AppColors.poppySoftD,
    mintSoft: AppColors.mintSoftD,
    sunnySoft: AppColors.sunnySoftD,
    lilacSoft: AppColors.lilacSoftD,
    skySoft: AppColors.skySoftD,
    glassFill: AppColors.glassFillD,
    glassTopBorder: AppColors.glassTopD,
    glassRimBorder: AppColors.glassRimD,
    glassShine: AppColors.glassShineD,
    glassBlurSigma: 28.0,
    shadowE1: [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: AppColors.shadowE1D)],
    shadowE2: [BoxShadow(offset: Offset(0, 6), blurRadius: 14, spreadRadius: -2, color: AppColors.shadowE2D)],
    shadowE3: [BoxShadow(offset: Offset(0, 14), blurRadius: 32, spreadRadius: -6, color: AppColors.shadowE3D)],
    shadowE4: [BoxShadow(offset: Offset(0, 24), blurRadius: 48, spreadRadius: -10, color: AppColors.shadowE4D)],
    shadowGlass: [BoxShadow(offset: Offset(0, 18), blurRadius: 48, spreadRadius: -10, color: AppColors.shadowGlassD)],
  );

  @override
  PetfolioThemeExtension copyWith({
    Color? ink950, Color? ink700, Color? ink500, Color? ink300, Color? line, Color? line2,
    Color? surface1, Color? surface2, Color? cream, Color? cream2,
    Color? success, Color? warning, Color? info,
    Color? pillarPets, Color? pillarCare, Color? pillarSocial,
    Color? pillarMatch, Color? pillarHealth, Color? pillarMarket,
    Color? tangerineSoft, Color? poppySoft, Color? mintSoft,
    Color? sunnySoft, Color? lilacSoft, Color? skySoft,
    Color? glassFill, Color? glassTopBorder, Color? glassRimBorder,
    Color? glassShine, double? glassBlurSigma,
    List<BoxShadow>? shadowE1, List<BoxShadow>? shadowE2,
    List<BoxShadow>? shadowE3, List<BoxShadow>? shadowE4,
    List<BoxShadow>? shadowGlass,
  }) => PetfolioThemeExtension(
    ink950: ink950 ?? this.ink950,
    ink700: ink700 ?? this.ink700,
    ink500: ink500 ?? this.ink500,
    ink300: ink300 ?? this.ink300,
    line: line ?? this.line,
    line2: line2 ?? this.line2,
    surface1: surface1 ?? this.surface1,
    surface2: surface2 ?? this.surface2,
    cream: cream ?? this.cream,
    cream2: cream2 ?? this.cream2,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    pillarPets: pillarPets ?? this.pillarPets,
    pillarCare: pillarCare ?? this.pillarCare,
    pillarSocial: pillarSocial ?? this.pillarSocial,
    pillarMatch: pillarMatch ?? this.pillarMatch,
    pillarHealth: pillarHealth ?? this.pillarHealth,
    pillarMarket: pillarMarket ?? this.pillarMarket,
    tangerineSoft: tangerineSoft ?? this.tangerineSoft,
    poppySoft: poppySoft ?? this.poppySoft,
    mintSoft: mintSoft ?? this.mintSoft,
    sunnySoft: sunnySoft ?? this.sunnySoft,
    lilacSoft: lilacSoft ?? this.lilacSoft,
    skySoft: skySoft ?? this.skySoft,
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
      ink950: Color.lerp(ink950, other.ink950, t)!,
      ink700: Color.lerp(ink700, other.ink700, t)!,
      ink500: Color.lerp(ink500, other.ink500, t)!,
      ink300: Color.lerp(ink300, other.ink300, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      cream2: Color.lerp(cream2, other.cream2, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      pillarPets: Color.lerp(pillarPets, other.pillarPets, t)!,
      pillarCare: Color.lerp(pillarCare, other.pillarCare, t)!,
      pillarSocial: Color.lerp(pillarSocial, other.pillarSocial, t)!,
      pillarMatch: Color.lerp(pillarMatch, other.pillarMatch, t)!,
      pillarHealth: Color.lerp(pillarHealth, other.pillarHealth, t)!,
      pillarMarket: Color.lerp(pillarMarket, other.pillarMarket, t)!,
      tangerineSoft: Color.lerp(tangerineSoft, other.tangerineSoft, t)!,
      poppySoft: Color.lerp(poppySoft, other.poppySoft, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      sunnySoft: Color.lerp(sunnySoft, other.sunnySoft, t)!,
      lilacSoft: Color.lerp(lilacSoft, other.lilacSoft, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassTopBorder: Color.lerp(glassTopBorder, other.glassTopBorder, t)!,
      glassRimBorder: Color.lerp(glassRimBorder, other.glassRimBorder, t)!,
      glassShine: Color.lerp(glassShine, other.glassShine, t)!,
      glassBlurSigma: _lerpD(glassBlurSigma, other.glassBlurSigma, t),
      shadowE1: BoxShadow.lerpList(shadowE1, other.shadowE1, t) ?? shadowE1,
      shadowE2: BoxShadow.lerpList(shadowE2, other.shadowE2, t) ?? shadowE2,
      shadowE3: BoxShadow.lerpList(shadowE3, other.shadowE3, t) ?? shadowE3,
      shadowE4: BoxShadow.lerpList(shadowE4, other.shadowE4, t) ?? shadowE4,
      shadowGlass: BoxShadow.lerpList(shadowGlass, other.shadowGlass, t) ?? shadowGlass,
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppThemeSpacing
// ─────────────────────────────────────────────────────────────────────────────
final class AppThemeSpacing {
  const AppThemeSpacing();
  double get xs => 4;
  double get sm => 8;
  double get md => 12;
  double get lg => 16;
  double get xl => 24;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
  static const AppThemeSpacing spacing = AppThemeSpacing();

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final cs = _colorScheme(isDark);
    final tt = _textTheme(isDark);
    final ext = isDark ? PetfolioThemeExtension.dark : PetfolioThemeExtension.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: tt,
      extensions: [ext, isDark ? PetFolioColors.dark : PetFolioColors.light],

      scaffoldBackgroundColor: isDark ? AppColors.creamD : AppColors.cream,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.surface0,
        foregroundColor: isDark ? AppColors.ink950D : AppColors.ink950,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? AppColors.shadowE1D : AppColors.shadowE1L,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.ink950D : AppColors.ink950,
          height: 1.2,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.ink700D : AppColors.ink700,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24);
          }
          return IconThemeData(
            color: isDark ? AppColors.ink500D : AppColors.ink500,
            size: 24,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.surface0,
        indicatorColor: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
        selectedIconTheme: IconThemeData(color: isDark ? AppColors.tangerineD : AppColors.tangerine),
        unselectedIconTheme: IconThemeData(color: isDark ? AppColors.ink500D : AppColors.ink500),
        labelType: NavigationRailLabelType.all,
        elevation: 0,
        selectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.tangerineD : AppColors.tangerine,
        ),
        unselectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.ink500D : AppColors.ink500,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? AppColors.surface0D : AppColors.surface0,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
          side: BorderSide(color: isDark ? AppColors.lineD : AppColors.line),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.lineD : AppColors.line,
        thickness: 1,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface0D : AppColors.surface0,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          borderSide: BorderSide(color: isDark ? AppColors.line2D : AppColors.line2, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          borderSide: BorderSide(color: isDark ? AppColors.line2D : AppColors.line2, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          borderSide: BorderSide(color: isDark ? AppColors.tangerineD : AppColors.tangerine, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: isDark ? AppColors.ink300D : AppColors.ink300,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
        labelStyle: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.tangerine700D : AppColors.tangerine700,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return (isDark ? AppColors.tangerineD : AppColors.tangerine).withAlpha(102);
            }
            return isDark ? AppColors.tangerineD : AppColors.tangerine;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size(120, PetfolioThemeExtension.btnHeightLg)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(
            isDark ? AppColors.tangerineD : AppColors.tangerine700,
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: isDark ? AppColors.tangerineD : AppColors.tangerine, width: 1.5),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(96, PetfolioThemeExtension.btnHeightMd)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surface0D : AppColors.ink950,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.ink950D : AppColors.surface0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ColorScheme _colorScheme(bool isDark) {
    final base = ColorScheme.fromSeed(
      seedColor: isDark ? AppColors.tangerineD : AppColors.tangerine,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return base.copyWith(
      primary: isDark ? AppColors.tangerineD : AppColors.tangerine,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
      onPrimaryContainer: isDark ? AppColors.tangerine700D : AppColors.tangerine700,
      secondary: isDark ? AppColors.poppyD : AppColors.poppy,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? AppColors.poppySoftD : AppColors.poppySoft,
      onSecondaryContainer: isDark ? AppColors.poppy700D : AppColors.poppy700,
      tertiary: isDark ? AppColors.mintD : AppColors.mint,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? AppColors.mintSoftD : AppColors.mintSoft,
      onTertiaryContainer: isDark ? AppColors.mint700D : AppColors.mint700,
      error: isDark ? AppColors.dangerD : AppColors.danger,
      onError: Colors.white,
      errorContainer: isDark ? AppColors.poppySoftD : AppColors.poppySoft,
      onErrorContainer: isDark ? AppColors.poppyD : AppColors.poppy700,
      surface: isDark ? AppColors.creamD : AppColors.cream,
      onSurface: isDark ? AppColors.ink950D : AppColors.ink950,
      surfaceContainerLowest: isDark ? AppColors.surface0D : AppColors.surface0,
      surfaceContainerLow: isDark ? AppColors.surface1D : AppColors.surface1,
      surfaceContainer: isDark ? AppColors.surface1D : AppColors.cream,
      surfaceContainerHigh: isDark ? AppColors.surface2D : AppColors.surface2,
      surfaceContainerHighest: isDark ? AppColors.surface2D : AppColors.surface2,
      onSurfaceVariant: isDark ? AppColors.ink700D : AppColors.ink700,
      outline: isDark ? AppColors.lineD : AppColors.line,
      outlineVariant: isDark ? AppColors.line2D : AppColors.line2,
      shadow: isDark ? Colors.black : AppColors.shadowInk,
      scrim: const Color(0x59000000),
      inverseSurface: isDark ? AppColors.surface0 : AppColors.ink950,
      onInverseSurface: isDark ? AppColors.ink950 : AppColors.surface0,
      inversePrimary: isDark ? AppColors.tangerine : AppColors.tangerineSoft,
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final headColor = isDark ? AppColors.ink950D : AppColors.ink950;
    final bodyColor = isDark ? AppColors.ink700D : AppColors.ink700;
    final mutedColor = isDark ? AppColors.ink500D : AppColors.ink500;

    // Bundled weights: Fraunces → w500 (Medium), w700 (Bold)
    //                  Nunito → w400 (Regular), w500 (Medium), w600 (SemiBold), w700 (Bold), w800, w900

    return TextTheme(
      // ── Display — Fraunces Bold for hero numbers & screen titles ─────────────────
      displayLarge: GoogleFonts.fraunces(
        fontSize: 36, fontWeight: FontWeight.w700,
        height: 1.05, letterSpacing: -0.5, color: headColor,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 30, fontWeight: FontWeight.w700,
        height: 1.08, letterSpacing: -0.3, color: headColor,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 24, fontWeight: FontWeight.w600,
        height: 1.15, letterSpacing: -0.1, color: headColor,
      ),
      // ── Headline — Fraunces for section headers & screen headings ────────────────
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 24, fontWeight: FontWeight.w700,
        height: 1.15, letterSpacing: -0.1, color: headColor,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 20, fontWeight: FontWeight.w700,
        height: 1.2, letterSpacing: 0, color: headColor,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 18, fontWeight: FontWeight.w700,
        height: 1.2, letterSpacing: 0, color: headColor,
      ),
      // ── Title — Fraunces SemiBold for card titles & list headers ─────────────────
      titleLarge: GoogleFonts.fraunces(
        fontSize: 20, fontWeight: FontWeight.w600,
        height: 1.2, letterSpacing: 0, color: headColor,
      ),
      titleMedium: GoogleFonts.fraunces(
        fontSize: 16, fontWeight: FontWeight.w600,
        height: 1.45, letterSpacing: 0, color: bodyColor,
      ),
      titleSmall: GoogleFonts.fraunces(
        fontSize: 15, fontWeight: FontWeight.w600,
        height: 1.5, letterSpacing: 0, color: bodyColor,
      ),
      // ── Body — Nunito for paragraph & descriptive text ────────────────────────
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w500,
        height: 1.5, letterSpacing: 0, color: bodyColor,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 15, fontWeight: FontWeight.w400,
        height: 1.5, letterSpacing: 0, color: bodyColor,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w400,
        height: 1.45, letterSpacing: 0, color: bodyColor,
      ),
      // ── Label — Nunito for UI chips, badges, metadata ─────────────────────────
      labelLarge: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w600,
        height: 1.35, letterSpacing: 0.1, color: mutedColor,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w600,
        height: 1.35, letterSpacing: 0.1, color: mutedColor,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 11, fontWeight: FontWeight.w700,
        height: 1.2, letterSpacing: 0.5, color: mutedColor,
      ),
    );
  }
}
