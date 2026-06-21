import 'package:flutter/painting.dart';

abstract final class AppColors {
  // ── Warm primary palette ─────────────────────────────────────────────────────
  static const cream        = Color(0xFFFFF4E6);
  static const cream2       = Color(0xFFFFEAD2);
  static const creamD       = Color(0xFF1A1014);
  static const cream2D      = Color(0xFF221319);

  // ── Tangerine — Pets / primary action ───────────────────────────────────────
  static const tangerine     = Color(0xFFFF8A4C);
  static const tangerine700  = Color(0xFFE0651E);
  static const tangerineSoft = Color(0xFFFFE0CB);
  static const tangerineD    = Color(0xFFFFA374);
  static const tangerine700D = Color(0xFFFFB886);
  static const tangerineSoftD= Color(0xFF4A2516);

  // ── Poppy — Social / danger ─────────────────────────────────────────────────
  static const poppy     = Color(0xFFFF3D3D);
  static const poppy700  = Color(0xFFC41818);
  static const poppySoft = Color(0xFFFFE0E0);
  static const poppyD    = Color(0xFFFF7070);
  static const poppy700D = Color(0xFFFF9898);
  static const poppySoftD= Color(0xFF3D1010);

  // ── Mint — Health / marketplace ─────────────────────────────────────────────
  static const mint     = Color(0xFF2FCBA0);
  static const mint700  = Color(0xFF198C6E);
  static const mintSoft = Color(0xFFBFF1E0);
  static const mintD    = Color(0xFF59E0BB);
  static const mint700D = Color(0xFF62E8BE);
  static const mintSoftD= Color(0xFF163A2E);

  // ── Sunny — Care / streak ───────────────────────────────────────────────────
  static const sunny     = Color(0xFFFFC53D);
  static const sunny700  = Color(0xFFC68B0F);
  static const sunnySoft = Color(0xFFFFEDB3);
  static const sunnyD    = Color(0xFFFFD668);
  static const sunny700D = Color(0xFFFFD96E);
  static const sunnySoftD= Color(0xFF3D2B0A);

  // ── Lilac — Match ──────────────────────────────────────────────────────────
  static const lilac     = Color(0xFFA98BFF);
  static const lilac700  = Color(0xFF6E4DDB);
  static const lilacSoft = Color(0xFFE2D6FF);
  static const lilacD    = Color(0xFFC1A7FF);
  static const lilac700D = Color(0xFFC8AEFF);
  static const lilacSoftD= Color(0xFF2E2249);

  // ── Sky — Bird species accent ───────────────────────────────────────────────
  static const sky     = Color(0xFF6EC8FF);
  static const sky700  = Color(0xFF2895DA);
  static const skySoft = Color(0xFFCDEAFF);
  static const skyD    = Color(0xFF6EC8FF);
  static const sky700D = Color(0xFF8FD4FF);
  static const skySoftD= Color(0xFF0B2840);

  // ── Ink — Text & icons ──────────────────────────────────────────────────────
  static const ink950  = Color(0xFF261308);
  static const ink700  = Color(0xFF5E3A28);
  static const ink500  = Color(0xFF957762);
  static const ink300  = Color(0xFFD6C2B0);
  static const ink950D = Color(0xFFFFF1E1);
  static const ink700D = Color(0xFFE9CFB8);
  static const ink500D = Color(0xFFB89685);
  static const ink300D = Color(0xFFB09080);

  // ── Dividers / lines ────────────────────────────────────────────────────────
  static const line    = Color(0xFFF4E2CB);
  static const line2   = Color(0xFFEFD8BB);
  static const lineD   = Color(0xFF47313F);
  static const line2D  = Color(0xFF5A404C);

  // ── Surfaces ────────────────────────────────────────────────────────────────
  static const surface0  = Color(0xFFFFFFFF);
  static const surface1  = Color(0xFFFFF4E6); // cream
  static const surface2  = Color(0xFFFFFAF3);
  static const surface3  = Color(0xFFF2F3F7); // neutral cool light
  static const surface0D = Color(0xFF2A1820);
  static const surface1D = Color(0xFF1A1014);
  static const surface2D = Color(0xFF321C25);
  static const surface3D = Color(0xFF252020); // neutral dark

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const success  = Color(0xFF2FCBA0); // mint
  static const successD = Color(0xFF59E0BB);
  static const warning  = Color(0xFFFFC53D); // sunny
  static const warningD = Color(0xFFFFD668);
  static const warningSoft  = Color(0xFFFFF3CD); // light warning fill
  static const warningSoftD = Color(0xFF3D2E00); // dark warning fill
  static const danger   = Color(0xFFFF3D3D); // poppy
  static const dangerD  = Color(0xFFFF7070);
  static const info     = Color(0xFF6EC8FF); // sky
  static const infoD    = Color(0xFF6EC8FF);

  // ── Achievement badge palette ────────────────────────────────────────────────
  static const badgeGreen  = Color(0xFF4CAF50);
  static const badgeAmber  = Color(0xFFFF9800);
  static const badgeGold   = Color(0xFFFFCC00);
  static const badgeBlue   = Color(0xFF2196F3);
  static const badgePurple = Color(0xFF9C27B0);
  static const badgePink   = Color(0xFFE91E63);
  static const badgeViolet = Color(0xFF7B61FF);

  // ── Premium gold ────────────────────────────────────────────────────────────
  static const premiumGold     = Color(0xFFD4AF37);
  static const premiumGoldSoft = Color(0xFFF5D56E);

  // ── Glass fills ──────────────────────────────────────────────────────────────
  static const glassFillL   = Color(0x9EFFFFFF);
  static const glassFillD   = Color(0x8C2A1820);
  static const glassTopL    = Color(0x8CFFFFFF);
  static const glassTopD    = Color(0x1AFFFFFF);
  static const glassRimL    = Color(0x0F261308);
  static const glassRimD    = Color(0x66000000);
  static const glassShineL  = Color(0x14FFFFFF);
  static const glassShineD  = Color(0x0AFFFFFF);

  // ── Shadow tints ─────────────────────────────────────────────────────────────
  static const shadowInk = Color(0xFF261308);
  static const shadowE1L = Color(0x0A261308);
  static const shadowE2L = Color(0x1A261308);
  static const shadowE3L = Color(0x24261308);
  static const shadowE4L = Color(0x33261308);
  static const shadowGlassL = Color(0x2E261308);
  static const shadowE1D = Color(0x59000000);
  static const shadowE2D = Color(0x73000000);
  static const shadowE3D = Color(0x8C000000);
  static const shadowE4D = Color(0xA6000000);
  static const shadowGlassD = Color(0x8C000000);

  // ── Backward-compat aliases (used by existing screens) ──────────────────────
  static const blue50   = Color(0xFFFFE0CB); // → tangerineSoft
  static const blue100  = tangerineSoft;
  static const blue200  = tangerineSoft;
  static const blue300  = tangerine;
  static const blue400  = tangerine;
  static const blue500  = tangerine;
  static const blue600  = tangerine700;
  static const blue700  = tangerine700;
  static const blue100D = tangerineSoftD;
  static const blue200D = tangerineSoftD;
  static const blue300D = tangerineD;
  static const blue400D = tangerineD;
  static const blue500D = tangerineD;
  static const blue600D = tangerine700D;
  static const blue700D = tangerine700D;
  static const blue800D = tangerine700D;
  static const blue900D = tangerine700D;

  static const sunset500  = tangerine;
  static const sunset500D = tangerineD;
  static const coral500   = poppy;
  static const coral500D  = poppyD;
  static const meadow500  = mint;
  static const meadow500D = mintD;
  static const apricot500  = sunny;
  static const apricot500D = sunnyD;
  static const mulberry500  = lilac;
  static const mulberry500D = lilacD;

  static const line200  = line;
  static const line200D = lineD;
  static const line100  = line2;
  static const line100D = line2D;

  /// Parses a CSS hex string (`#RRGGBB` or `#AARRGGBB`) into a [Color].
  /// Returns [fallback] if the string is null, empty, or unparseable.
  static Color fromHexString(String? hex, {Color fallback = tangerine}) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '');
    try {
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return fallback;
  }
}
