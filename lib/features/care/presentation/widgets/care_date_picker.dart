import 'package:flutter/material.dart';

import 'package:petfolio/core/theme/theme.dart';

class CareDatePicker extends StatefulWidget {
  const CareDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<CareDatePicker> createState() => _CareDatePickerState();
}

class _CareDatePickerState extends State<CareDatePicker> {
  late final ScrollController _scroll;

  static const _chipW = 52.0;
  static const _chipGap = 8.0;
  static const _daysBack = 30;
  static const _daysAhead = 6;
  static const _totalDays = _daysBack + 1 + _daysAhead;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_scroll.hasClients) return;
    final screenW = context.size?.width ?? 360;
    final todayOffset =
        _daysBack * (_chipW + _chipGap) - (screenW / 2 - _chipW / 2) + 16;
    _scroll.jumpTo(todayOffset.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());

    return ClipRect(
      child: SizedBox(
        height: 76,
        child: Stack(
          children: [
            ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _totalDays,
              itemBuilder: (context, i) {
                final date = today.subtract(Duration(days: _daysBack - i));
                final isSelected =
                    DateUtils.dateOnly(widget.selectedDate) == date;
                final isToday = date == today;
                final isFuture = date.isAfter(today);

                final ymd =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                return Padding(
                  padding: EdgeInsets.only(
                      right: i < _totalDays - 1 ? _chipGap : 0),
                  child: Semantics(
                    label: isToday ? 'Today, ${date.day}' : '${_dayLetters[date.weekday - 1]}, ${date.day}',
                    selected: isSelected,
                    enabled: !isFuture,
                    button: true,
                    child: GestureDetector(
                    key: ValueKey<String>('care_date_$ymd'),
                    onTap: isFuture ? null : () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: PetfolioThemeExtension.durationSm,
                      width: _chipW,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : (isToday
                                ? cs.primary.withAlpha(15)
                                : pt.surface2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isToday
                                  ? cs.primary.withAlpha(80)
                                  : pt.line),
                          width: isToday && !isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayLetters[date.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isSelected
                                  ? Colors.white.withAlpha(200)
                                  : (isFuture ? pt.ink300 : pt.ink500),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              height: 1,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday
                                      ? cs.primary
                                      : (isFuture
                                          ? pt.ink300
                                          : cs.onSurface)),
                            ),
                          ),
                          if (isToday && !isSelected) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
