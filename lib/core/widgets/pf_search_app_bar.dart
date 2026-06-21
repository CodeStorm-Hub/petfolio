import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// M3 Expressive search app bar — a self-contained, debounced search field
/// in the app's squircle shape language, with a leading icon/back button and
/// a trailing clear action that appears once text is entered.
class PfSearchAppBar extends StatefulWidget {
  const PfSearchAppBar({
    super.key,
    required this.onQueryChanged,
    this.hintText = 'Search',
    this.leading,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 300),
  });

  final ValueChanged<String> onQueryChanged;
  final String hintText;
  final Widget? leading;
  final bool autofocus;
  final Duration debounce;

  @override
  State<PfSearchAppBar> createState() => _PfSearchAppBarState();
}

class _PfSearchAppBarState extends State<PfSearchAppBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onQueryChanged(value));
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    _debounceTimer?.cancel();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: isDark ? pt.surface2 : Theme.of(context).colorScheme.surface,
        shadows: pt.shadowE1,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          side: BorderSide(color: pt.line),
        ),
      ),
      child: Row(
        children: [
          widget.leading ?? Icon(Icons.search_rounded, size: 20, color: pt.ink500),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: _onChanged,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pt.ink950),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pt.ink500),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_hasText)
            Semantics(
              label: 'Clear search',
              button: true,
              child: GestureDetector(
                onTap: _clear,
                child: Icon(Icons.close_rounded, size: 18, color: pt.ink500),
              ),
            ),
        ],
      ),
    );
  }
}
