import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class WarmSearchBar extends StatelessWidget {
  const WarmSearchBar({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
    this.onTap,
    this.controller,
    this.readOnly = false,
    this.trailing,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius:
              BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          border: Border.all(color: pt.line200, width: 1),
          boxShadow: pt.shadowE1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: pt.ink500),
            const SizedBox(width: 10),
            Expanded(
              child: readOnly
                  ? Text(
                      hint,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: pt.ink300,
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      autofocus: autofocus,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: pt.ink300,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
