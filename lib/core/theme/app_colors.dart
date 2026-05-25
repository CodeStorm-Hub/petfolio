import 'package:flutter/painting.dart';

/// Raw design-token color constants for the PetFolio design system.
/// Every value maps 1-to-1 to §2 of the PetFolio Design System spec.
///
/// Suffix-less names are **light-mode** values.
/// Names ending in `D` are the **dark-mode** counterpart.
///
/// Prefer consuming [PetfolioThemeExtension] inside widgets — it
/// resolves the correct light/dark pair automatically.
abstract final class AppColors {
  // ── §2.1  Blue primary ramp (Friendly Pet Vibe) ─────────────────────────
  static const blue50   = Color(0xFFF0F5FC);
  static const blue100  = Color(0xFFD6E4F8);
  static const blue200  = Color(0xFFABC8ED);
  static const blue300  = Color(0xFF7EACDF);
  static const blue400  = Color(0xFF4A90E2); // ★ Primary brand (light)
  static const blue500  = Color(0xFF387AB9); 
  static const blue600  = Color(0xFF2B5C8C);
  static const blue700  = Color(0xFF1F4164);
  static const blue800  = Color(0xFF14293D);
  static const blue900  = Color(0xFF09121B);

  static const blue50D  = Color(0xFF09121B);
  static const blue100D = Color(0xFF14293D);
  static const blue200D = Color(0xFF1F4164);
  static const blue300D = Color(0xFF2B5C8C);
  static const blue400D = Color(0xFF387AB9);
  static const blue500D = Color(0xFF4A90E2); // ★ Primary brand (dark)
  static const blue600D = Color(0xFF7EACDF);
  static const blue700D = Color(0xFFABC8ED);
  static const blue800D = Color(0xFFD6E4F8);
  static const blue900D = Color(0xFFF0F5FC);

  // ── §2.2  Secondaries — warm empathetic family ────────────────────────────
  static const sunset500   = Color(0xFFF4A261); // Social pillar
  static const sunset500D  = Color(0xFFF6B27A);
  static const coral500    = Color(0xFFE76F51); // Match pillar
  static const coral500D   = Color(0xFFF08770);
  static const meadow500   = Color(0xFF6BAF92); // Health pillar
  static const meadow500D  = Color(0xFF7BC4A4);
  static const apricot500  = Color(0xFFF5C49B); // Marketplace pillar
  static const apricot500D = Color(0xFFE8B58A);
  static const mulberry500  = Color(0xFF9B5C8A); // Premium/breed-match
  static const mulberry500D = Color(0xFFB274A0);

  // ── §2.3  Neutrals — cool-warm hybrid ─────────────────────────────────────
  static const ink950  = Color(0xFF0B1220); // Primary text (light)
  static const ink950D = Color(0xFFF4F6FB); // Primary text (dark)
  static const ink700  = Color(0xFF2A3447); // Body text (light)
  static const ink700D = Color(0xFFC7CEDB); // Body text (dark)
  static const ink500  = Color(0xFF5C657A); // Secondary/caption (light)
  static const ink500D = Color(0xFF8A93A6); // Secondary/caption (dark)
  static const ink300  = Color(0xFFA3ABBC); // Placeholder (light)
  static const ink300D = Color(0xFF5C657A); // Placeholder (dark)

  static const line200  = Color(0xFFE4E7EF); // Hairline dividers (light)
  static const line200D = Color(0xFF1F2738); // Hairline dividers (dark)
  static const line100  = Color(0xFFEEF1F7); // Subtle dividers (light)
  static const line100D = Color(0xFF172033); // Subtle dividers (dark)

  static const surface0  = Color(0xFFFFFFFF); // Card / sheet (light)
  static const surface0D = Color(0xFF0A0F1C); // Card / sheet (dark)
  static const surface1  = Color(0xFFFAFBFD); // App background (light)
  static const surface1D = Color(0xFF0F1525); // App background (dark)
  static const surface2  = Color(0xFFF2F4F9); // Inset wells (light)
  static const surface2D = Color(0xFF141B2D); // Inset wells (dark)

  // ── §2.4  Semantic ────────────────────────────────────────────────────────
  static const success  = Color(0xFF1F8A5B);
  static const successD = Color(0xFF3FB57F);
  static const warning  = Color(0xFFC97A1A);
  static const warningD = Color(0xFFF0A23A);
  static const danger   = Color(0xFFD14343);
  static const dangerD  = Color(0xFFF26A6A);
  static const info     = Color(0xFF2A6FDB);
  static const infoD    = Color(0xFF5C95F2);

  // ── §4.1  Glass fills — ARGB; alpha = round(opacity × 255) ───────────────
  // rgba(255,255,255,0.62) → α = 158 = 0x9E
  static const glassFillL   = Color(0x9EFFFFFF);
  // rgba(20,27,45,0.55)    → α = 140 = 0x8C
  static const glassFillD   = Color(0x8C141B2D);
  // Inner/top border highlight
  // rgba(255,255,255,0.55) → α = 140 = 0x8C
  static const glassTopL    = Color(0x8CFFFFFF);
  // rgba(255,255,255,0.10) → α = 26  = 0x1A
  static const glassTopD    = Color(0x1AFFFFFF);
  // Outer rim border
  // rgba(11,18,32,0.06)    → α = 15  = 0x0F
  static const glassRimL    = Color(0x0F0B1220);
  // rgba(0,0,0,0.40)       → α = 102 = 0x66
  static const glassRimD    = Color(0x66000000);
  // Specular highlight: 8 % (light) / 4 % (dark) white
  // 0.08 × 255 ≈ 20 = 0x14
  static const glassShineL  = Color(0x14FFFFFF);
  // 0.04 × 255 ≈ 10 = 0x0A
  static const glassShineD  = Color(0x0AFFFFFF);

  // ── §4.3  Shadow base tints ───────────────────────────────────────────────
  static const shadowInk = Color(0xFF0B1220); // light-mode shadow tint
  // e1 light  rgba(11,18,32,0.04) → α=10=0x0A
  static const shadowE1L = Color(0x0A0B1220);
  // e2 light  rgba(11,18,32,0.10) → α=26=0x1A
  static const shadowE2L = Color(0x1A0B1220);
  // e3 light  rgba(11,18,32,0.14) → α=36=0x24
  static const shadowE3L = Color(0x240B1220);
  // e4 light  rgba(11,18,32,0.20) → α=51=0x33
  static const shadowE4L = Color(0x330B1220);
  // Glass shadow light  rgba(11,18,32,0.18) → α=46=0x2E
  static const shadowGlassL = Color(0x2E0B1220);
  // e1 dark  rgba(0,0,0,0.35) → α=89=0x59
  static const shadowE1D = Color(0x59000000);
  // e2 dark  rgba(0,0,0,0.45) → α=115=0x73
  static const shadowE2D = Color(0x73000000);
  // e3 dark  rgba(0,0,0,0.55) → α=140=0x8C
  static const shadowE3D = Color(0x8C000000);
  // e4 dark  rgba(0,0,0,0.65) → α=166=0xA6
  static const shadowE4D = Color(0xA6000000);
  // Glass shadow dark  rgba(0,0,0,0.55)
  static const shadowGlassD = Color(0x8C000000);
}
