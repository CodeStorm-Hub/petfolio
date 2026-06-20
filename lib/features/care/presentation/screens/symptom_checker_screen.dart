import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/health_log.dart';
import '../../data/repositories/health_repository.dart';

const _emergencySymptoms = {
  'Difficulty breathing',
  'Seizure',
  'Heavy bleeding',
  'Collapse / unconscious',
};

const _symptoms = [
  'Vomiting',
  'Diarrhea',
  'Not eating',
  'Lethargy',
  'Limping',
  'Coughing',
  'Difficulty breathing',
  'Seizure',
  'Heavy bleeding',
  'Collapse / unconscious',
  'Other',
];

const _durations = ['Less than 24 hours', '1–3 days', 'More than 3 days'];

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() =>
      _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  int _step = 0;
  String? _symptom;
  String? _duration;
  HealthSeverity? _severity;
  bool _saving = false;

  bool get _isEmergency =>
      _symptom != null && _emergencySymptoms.contains(_symptom);

  _Triage get _triage {
    if (_isEmergency || _severity == HealthSeverity.severe) {
      return const _Triage(
        level: 'Seek a vet now',
        color: _TriageColor.urgent,
        guidance:
            'These signs can be serious. Contact an emergency veterinary clinic right away.',
      );
    }
    if (_severity == HealthSeverity.moderate ||
        _duration == 'More than 3 days') {
      return const _Triage(
        level: 'See a vet soon',
        color: _TriageColor.caution,
        guidance:
            'Book a veterinary appointment in the next day or two and monitor closely.',
      );
    }
    return const _Triage(
      level: 'Monitor at home',
      color: _TriageColor.ok,
      guidance:
          'Keep an eye on your pet. If symptoms worsen or persist, contact a vet.',
    );
  }

  Future<void> _save() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      await ref.read(healthRepositoryProvider).createLog(
            HealthLog(
              id: '',
              petId: pet.id,
              recordedBy: '',
              logType: HealthLogType.symptom,
              title: _symptom ?? 'Symptom',
              description: 'Duration: ${_duration ?? '—'}. ${_triage.level}.',
              severity: _severity,
              occurredAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (mounted) {
        AppSnackBar.showSuccess('Saved to health log');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(title: const Text('Symptom checker')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DisclaimerBanner(),
              const SizedBox(height: 16),
              Expanded(child: _buildStep(pt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(PetfolioThemeExtension pt) {
    final tt = Theme.of(context).textTheme;
    switch (_step) {
      case 0:
        return _ChoiceStep(
          title: 'What are you noticing?',
          options: _symptoms,
          selected: _symptom,
          onSelect: (v) => setState(() {
            _symptom = v;
            if (_emergencySymptoms.contains(v)) {
              _step = 3;
            } else {
              _step = 1;
            }
          }),
        );
      case 1:
        return _ChoiceStep(
          title: 'How long has this been going on?',
          options: _durations,
          selected: _duration,
          onSelect: (v) => setState(() {
            _duration = v;
            _step = 2;
          }),
        );
      case 2:
        return _ChoiceStep(
          title: 'How severe does it seem?',
          options: const ['Mild', 'Moderate', 'Severe'],
          selected: _severity == null
              ? null
              : _severity!.name[0].toUpperCase() + _severity!.name.substring(1),
          onSelect: (v) => setState(() {
            _severity = switch (v) {
              'Severe' => HealthSeverity.severe,
              'Moderate' => HealthSeverity.moderate,
              _ => HealthSeverity.mild,
            };
            _step = 3;
          }),
        );
      default:
        final triage = _triage;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: triage.resolve(context, pt).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(triage.level,
                        style: tt.titleLarge?.copyWith(
                            color: triage.resolve(context, pt),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(triage.guidance, style: tt.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Summary', style: tt.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${_symptom ?? '—'} · ${_duration ?? 'urgent'}',
                style: tt.bodyMedium?.copyWith(color: pt.ink500),
              ),
              const SizedBox(height: 24),
              PrimaryPillButton(
                label: 'Save to health log',
                isFullWidth: true,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _step = 0;
                  _symptom = null;
                  _duration = null;
                  _severity = null;
                }),
                child: const Text('Start over'),
              ),
            ],
          ),
        );
    }
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    title: Text(o),
                    trailing: selected == o
                        ? const Icon(Icons.check_circle, size: 20)
                        : const Icon(Icons.chevron_right),
                    onTap: () => onSelect(o),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pt.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: pt.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is not a diagnosis. For emergencies, contact a vet immediately.',
              style: tt.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TriageColor { ok, caution, urgent }

class _Triage {
  const _Triage({
    required this.level,
    required this.color,
    required this.guidance,
  });

  final String level;
  final _TriageColor color;
  final String guidance;

  Color resolve(BuildContext context, PetfolioThemeExtension pt) =>
      switch (color) {
        _TriageColor.ok => pt.success,
        _TriageColor.caution => pt.warning,
        _TriageColor.urgent => Theme.of(context).colorScheme.error,
      };
}
