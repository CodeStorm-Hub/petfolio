import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/models/weight_log.dart';
import '../controllers/vitals_controller.dart';

class VitalsChartCard extends ConsumerWidget {
  const VitalsChartCard({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vitalsNotifierProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        border: Border.all(color: pt.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Weight Tracker',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddLogSheet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          logsAsync.when(
            loading: () => const SkeletonLoader(width: double.infinity, height: 140),
            error: (_, _) => SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Could not load weight data',
                  style: TextStyle(color: pt.ink300, fontSize: 13),
                ),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monitor_weight_outlined, size: 40, color: pt.ink300),
                        const SizedBox(height: 8),
                        Text(
                          'No weight logs yet',
                          style: TextStyle(color: pt.ink300, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap Log to record the first entry',
                          style: TextStyle(color: pt.ink300, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final sorted = List<WeightLog>.from(logs)
                ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
              return _WeightChart(logs: sorted, pt: pt);
            },
          ),
        ],
      ),
    );
  }

  void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddWeightLogSheet(petId: petId, ref: ref),
    );
  }
}

class _WeightChart extends StatefulWidget {
  const _WeightChart({required this.logs, required this.pt});

  final List<WeightLog> logs;
  final PetfolioThemeExtension pt;

  @override
  State<_WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<_WeightChart> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    final pt = widget.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            button: true,
            label: _showTable ? 'Show chart' : 'Show data table',
            child: InkWell(
              onTap: () => setState(() => _showTable = !_showTable),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTable ? Icons.show_chart_rounded : Icons.table_rows_rounded,
                      size: 14,
                      color: pt.ink500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTable ? 'Chart' : 'Table',
                      style: TextStyle(fontSize: 12, color: pt.ink500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (_showTable) _DataTable(logs: logs, pt: pt) else _ChartView(logs: logs, pt: pt),
      ],
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({required this.logs, required this.pt});

  final List<WeightLog> logs;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: 'Weight log table with ${logs.length} entries',
      child: SizedBox(
        height: 160,
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pt.line))),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Date', style: tt.labelSmall?.copyWith(color: pt.ink500, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Weight (kg)', style: tt.labelSmall?.copyWith(color: pt.ink500, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              for (final log in logs.reversed)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${log.recordedAt.year}/${log.recordedAt.month.toString().padLeft(2, '0')}/${log.recordedAt.day.toString().padLeft(2, '0')}',
                        style: tt.bodySmall?.copyWith(color: pt.ink500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        log.weightKg.toStringAsFixed(2),
                        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartView extends StatelessWidget {
  const _ChartView({required this.logs, required this.pt});

  final List<WeightLog> logs;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mint = isDark ? AppColors.mintD : AppColors.mint;
    final weights = logs.map((l) => l.weightKg).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 0.5).clamp(0.0, double.infinity);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 0.5;

    final spots = List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].weightKg),
    );

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(0.1, double.infinity),
            getDrawingHorizontalLine: (_) => FlLine(
              color: pt.line,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: pt.ink300),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: logs.length <= 7,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= logs.length) return const SizedBox.shrink();
                  final d = logs[i].recordedAt;
                  return Text(
                    '${d.month}/${d.day}',

                    style: TextStyle(fontSize: 10, color: pt.ink300),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: mint,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: mint,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    mint.withAlpha(60),
                    mint.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => pt.surface1,
              tooltipBorder: BorderSide(color: pt.line),
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final log = logs[s.x.toInt()];
                return LineTooltipItem(
                  '${log.weightKg} kg\n',
                  TextStyle(color: mint, fontWeight: FontWeight.w700, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '${log.recordedAt.year}/${log.recordedAt.month}/${log.recordedAt.day}',
                      style: TextStyle(fontSize: 11, color: pt.ink500, fontWeight: FontWeight.w400),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWeightLogSheet extends StatefulWidget {
  const _AddWeightLogSheet({required this.petId, required this.ref});

  final String petId;
  final WidgetRef ref;

  @override
  State<_AddWeightLogSheet> createState() => _AddWeightLogSheetState();
}

class _AddWeightLogSheetState extends State<_AddWeightLogSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kg = double.tryParse(_ctrl.text.trim());
    if (kg == null || kg <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(vitalsNotifierProvider.notifier).addLog(
        petId: widget.petId,
        weightKg: kg,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: pt.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Log Weight', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Weight (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
