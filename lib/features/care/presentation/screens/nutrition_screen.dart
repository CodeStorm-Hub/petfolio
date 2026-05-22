import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import 'package:petfolio/features/pet_profile/data/models/activity_level.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/health_log.dart';
import '../controllers/nutrition_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NutritionScreen
// ─────────────────────────────────────────────────────────────────────────────

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _NutritionBody(pet: pet);
  }
}

class _NutritionBody extends ConsumerStatefulWidget {
  const _NutritionBody({required this.pet});

  final Pet pet;

  @override
  ConsumerState<_NutritionBody> createState() => _NutritionBodyState();
}

class _NutritionBodyState extends ConsumerState<_NutritionBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(nutritionProvider(widget.pet.id).notifier).refresh(),
    );
  }

  void _openLogSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogWeightSheet(petId: widget.pet.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final nutrition = ref.watch(nutritionProvider(widget.pet.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _NutritionAppBar(pet: widget.pet, pt: pt),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WeightTrendCard(
                  pt: pt,
                  history: nutrition.history,
                  petName: widget.pet.name,
                ),
                const SizedBox(height: 16),
                _CalorieCard(
                  pt: pt,
                  pet: widget.pet,
                  history: nutrition.history,
                ),
                const SizedBox(height: 16),
                _HistoryList(pt: pt, history: nutrition.history),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLogSheet,
        backgroundColor: pt.pillarHealth,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: Text(
          'Log Weight',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionAppBar extends StatelessWidget {
  const _NutritionAppBar({required this.pet, required this.pt});

  final Pet pet;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: pt.shadowE1.first.color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUTRITION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: pt.pillarHealth,
            ),
          ),
          Text(
            pet.name,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight Trend Card
// ─────────────────────────────────────────────────────────────────────────────

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.pt,
    required this.history,
    required this.petName,
  });

  final PetfolioThemeExtension pt;
  final AsyncValue<List<HealthLog>> history;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
        border: Border.all(color: pt.line200),
        boxShadow: pt.shadowE1,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: pt.pillarHealth, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weight Trend',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          history.when(
            data: (logs) {
              final weights = logs.where((l) => l.weightKg != null).toList();
              if (weights.length < 2) {
                return PetfolioEmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'Not enough data for a trend',
                  subtitle: weights.isEmpty
                      ? 'Log weight at least twice to see how $petName\'s weight changes over time.'
                      : 'Add one more weight entry to plot a trend line.',
                );
              }
              return _WeightLineChart(logs: weights, pt: pt);
            },
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Could not load weight history.',
                  style: TextStyle(color: cs.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({required this.logs, required this.pt});

  final List<HealthLog> logs;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spots = logs
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg!))
        .toList();

    final minY = spots.map((s) => s.y).reduce(math.min);
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final padding = (maxY - minY) < 0.5 ? 0.5 : (maxY - minY) * 0.15;

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, right: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (spots.length - 1).clamp(0, 1000000).toDouble(),
            minY: minY - padding,
            maxY: maxY + padding,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: pt.pillarHealth,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: pt.pillarHealth,
                    strokeWidth: 2,
                    strokeColor: cs.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      pt.pillarHealth.withAlpha(60),
                      pt.pillarHealth.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: pt.ink300,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.round();
                    if ((value - idx).abs() > 0.001) {
                      return const SizedBox.shrink();
                    }
                    if (idx < 0 || idx >= logs.length) {
                      return const SizedBox.shrink();
                    }
                    final date = logs[idx].occurredAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: pt.ink300,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: (maxY - minY) < 1 ? 0.5 : null,
              getDrawingHorizontalLine: (value) => FlLine(
                color: pt.line100,
                strokeWidth: 1,
              ),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => pt.ink500.withAlpha(220),
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(2)} kg',
                        GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Calorie Card
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({
    required this.pt,
    required this.pet,
    required this.history,
  });

  final PetfolioThemeExtension pt;
  final Pet pet;
  final AsyncValue<List<HealthLog>> history;

  static double? _latestLoggedWeightKg(AsyncValue<List<HealthLog>> history) {
    return history.maybeWhen(
      data: (list) {
        final dated = list.where((l) => l.weightKg != null).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        if (dated.isEmpty) return null;
        return dated.first.weightKg;
      },
      orElse: () => null,
    );
  }

  int? _computeCalories(Pet pet, double? kgForMer) {
    final kg = kgForMer;
    if (kg == null || kg <= 0) return null;

    final level = ActivityLevel.fromId(pet.activityLevel) ?? ActivityLevel.moderate;
    final factor = level.factor;
    final speciesModifier =
        pet.species.toLowerCase() == 'cat' ? 0.9 : 1.0;

    final rer = 70 * math.pow(kg, 0.75);
    final mer = rer * factor * speciesModifier;
    return mer.round();
  }

  static String _formatDisplayKg(double kg) =>
      kg < 20 ? kg.toStringAsFixed(2) : kg.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final weightKgForMer =
        _latestLoggedWeightKg(history) ?? pet.weightKg;
    final calories = _computeCalories(pet, weightKgForMer);
    final level = ActivityLevel.fromId(pet.activityLevel) ?? ActivityLevel.moderate;
    final activityLabel = level.shortLabel;
    final weightStr = weightKgForMer != null
        ? '${_formatDisplayKg(weightKgForMer)} kg'
        : 'Not set';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.pillarHealth,
            pt.pillarHealth.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 6),
            blurRadius: 20,
            spreadRadius: -4,
            color: pt.pillarHealth.withAlpha(100),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Nutrition',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (calories != null) ...[
            Text(
              '$calories',
              style: GoogleFonts.sora(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            Text(
              'kcal / day recommended',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius:
                    BorderRadius.circular(PetfolioThemeExtension.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _CalorieStat(
                    label: 'Weight',
                    value: weightStr,
                  ),
                  _CalorieDivider(),
                  _CalorieStat(
                    label: 'Activity',
                    value: activityLabel,
                  ),
                  _CalorieDivider(),
                  _CalorieStat(
                    label: 'Species',
                    value: pet.species.substring(0, 1).toUpperCase() +
                        pet.species.substring(1),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Set your pet\'s weight & activity\nlevel in their profile to see\ncaloric recommendations.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withAlpha(220),
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Based on NRC metabolic energy requirements (MER = 70 × kg^0.75 × activity factor)',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withAlpha(160),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  const _CalorieStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(180),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CalorieDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withAlpha(60),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight History List
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.pt, required this.history});

  final PetfolioThemeExtension pt;
  final AsyncValue<List<HealthLog>> history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return history.when(
      data: (logs) {
        final weights = logs.where((l) => l.weightKg != null).toList();
        if (weights.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                BorderRadius.circular(PetfolioThemeExtension.radiusLg),
            border: Border.all(color: pt.line200),
            boxShadow: pt.shadowE1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        color: pt.pillarHealth, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Log History',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = weights.length - 1; i >= 0; i--)
                _HistoryTile(log: weights[i], pt: pt, isLast: i == 0),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.log,
    required this.pt,
    required this.isLast,
  });

  final HealthLog log;
  final PetfolioThemeExtension pt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = log.occurredAt;
    final dateStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pt.pillarHealth.withAlpha(30),
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusSm),
                ),
                child: Icon(Icons.monitor_weight_outlined,
                    color: pt.pillarHealth, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.weightKg!.toStringAsFixed(2)} kg',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (log.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        log.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: pt.ink300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: pt.ink300,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: pt.line100),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Weight Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LogWeightSheet extends ConsumerStatefulWidget {
  const _LogWeightSheet({required this.petId});

  final String petId;

  @override
  ConsumerState<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<_LogWeightSheet> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _useLbs = false;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _weightKg {
    final raw = double.tryParse(_weightController.text.trim());
    if (raw == null) return null;
    return _useLbs ? raw * 0.453592 : raw;
  }

  Future<void> _save() async {
    final kg = _weightKg;
    if (kg == null || kg <= 0) {
      setState(() => _error = 'Please enter a valid weight.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(nutritionProvider(widget.petId).notifier).logWeight(
            kg,
            notes: _notesController.text,
            date: _date,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save. Please try again.';
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PetfolioThemeExtension.radius2xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, mq.viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pt.line200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined,
                  color: pt.pillarHealth, size: 22),
              const SizedBox(width: 10),
              Text(
                'Log Weight',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}')),
                  ],
                  decoration: InputDecoration(
                    labelText: _useLbs ? 'Weight (lbs)' : 'Weight (kg)',
                    hintText: _useLbs ? 'e.g. 22.5' : 'e.g. 10.2',
                  ),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 12),
              _UnitToggle(
                useLbs: _useLbs,
                pt: pt,
                onToggle: () => setState(() => _useLbs = !_useLbs),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. After vet visit',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius:
                    BorderRadius.circular(PetfolioThemeExtension.radiusMd),
                border: Border.all(color: pt.line200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: pt.ink300),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: pt.pillarHealth,
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.useLbs,
    required this.pt,
    required this.onToggle,
  });

  final bool useLbs;
  final PetfolioThemeExtension pt;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius:
              BorderRadius.circular(PetfolioThemeExtension.radiusMd),
          border: Border.all(color: pt.line200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UnitLabel(label: 'kg', active: !useLbs, pt: pt),
            const SizedBox(width: 4),
            Text('/', style: TextStyle(color: pt.ink300)),
            const SizedBox(width: 4),
            _UnitLabel(label: 'lbs', active: useLbs, pt: pt),
          ],
        ),
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel({
    required this.label,
    required this.active,
    required this.pt,
  });

  final String label;
  final bool active;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        color: active ? pt.pillarHealth : pt.ink300,
      ),
    );
  }
}
