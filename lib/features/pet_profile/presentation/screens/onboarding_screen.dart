import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../data/models/pet.dart';
import '../../data/models/pet_species.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';

// Steps: 0=Welcome  1=Species+Breed  2=PetDetails(merged)  3=Photo  4=Done

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.addAnotherPet = false});

  /// `true` when navigated from the pet switcher's "Add another pet" entry —
  /// skips the first-run Welcome step and routes back to /care on completion.
  final bool addAnotherPet;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 3;

  late int _step = widget.addAnotherPet ? 1 : 0;
  PetSpecies? _species;
  String? _breed;
  String _name = '';
  DateTime? _dateOfBirth;
  double? _weightKg;
  double? _targetWeightKg;
  bool _useKg = true;
  String? _activityLevel;
  Uint8List? _photoBytes;
  bool _isSubmitting = false;

  void _next() => setState(() => _step++);
  void _back() {
    // In add-another-pet mode the welcome screen is hidden; backing out from
    // the first real step closes onboarding rather than revealing step 0.
    final floor = widget.addAnotherPet ? 1 : 0;
    if (_step <= floor) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() => _step = (_step - 1).clamp(0, 4));
  }

  Future<void> _complete() async {
    setState(() => _isSubmitting = true);
    try {
      final pet = await ref.read(petListProvider.notifier).addPet(
            name: _name,
            species: _species!.name,
            breed: _breed,
            dateOfBirth: _dateOfBirth,
            weightKg: _weightKg,
            activityLevel: _activityLevel,
          );

      Pet activePet = pet;
      if (_photoBytes != null) {
        final repo = ref.read(petRepositoryProvider);
        final url = await repo.uploadAvatar(_photoBytes!, pet.id);
        await repo.updateAvatarUrl(pet.id, url);
        activePet = pet.copyWith(avatarUrl: url);
        ref.read(petListProvider.notifier).updateLocal(activePet);
      }
      await ref.read(activePetControllerProvider.notifier).setActivePet(activePet);

      if (_targetWeightKg != null) {
        try {
          await ref.read(petRepositoryProvider).writeTargetWeight(pet.id, _targetWeightKg!);
        } catch (_) {}
      }

      if (mounted) {
        context.go('/care?onboardingComplete=1');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.warmCream,
      body: AnimatedSwitcher(
        duration: PetfolioThemeExtension.durationMd,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_step), child: _buildStep(context, pt)),
      ),
    );
  }

  Widget _buildStep(BuildContext context, PetfolioThemeExtension pt) {
    switch (_step) {
      case 0:
        return _WelcomeStep(onStart: _next, onSkip: () => context.go('/home'));
      case 1:
        return _SpeciesBreedStep(
          species: _species,
          breed: _breed,
          onPickSpecies: (sp) => setState(() { _species = sp; _breed = null; }),
          onPickBreed: (b) => setState(() => _breed = b),
          onNext: _next,
          onBack: _back,
          step: 1,
          total: _totalSteps,
        );
      case 2:
        return _PetDetailsStep(
          name: _name,
          dateOfBirth: _dateOfBirth,
          weightKg: _weightKg,
          targetWeightKg: _targetWeightKg,
          useKg: _useKg,
          activityLevel: _activityLevel,
          species: _species!,
          onNameChanged: (v) => setState(() => _name = v),
          onDobPick: (d) => setState(() => _dateOfBirth = d),
          onWeightChanged: (v) => setState(() => _weightKg = v),
          onTargetChanged: (v) => setState(() => _targetWeightKg = v),
          onUnitToggle: (v) => setState(() => _useKg = v),
          onActivityPick: (level) => setState(() => _activityLevel = level),
          onNext: _next,
          onBack: _back,
          step: 2,
          total: _totalSteps,
        );
      case 3:
        return _PhotoStep(
          name: _name,
          species: _species!,
          photoBytes: _photoBytes,
          onBack: _back,
          onSetPhoto: (bytes) => setState(() => _photoBytes = bytes),
          onNext: _next,
          step: 3,
          total: _totalSteps,
        );
      case 4:
        return _DoneStep(
          name: _name,
          species: _species!,
          breed: _breed,
          dateOfBirth: _dateOfBirth,
          weightKg: _weightKg,
          activityLevel: _activityLevel,
          photoBytes: _photoBytes,
          onEnter: _complete,
          isLoading: _isSubmitting,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.total, required this.onBack});

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: const Offset(0, 1)),
                    BoxShadow(color: pt.line200, blurRadius: 0, spreadRadius: 0.5),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(10, 18),
                    painter: _ChevronPainter(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < total; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: PetfolioThemeExtension.durationMd,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < step ? cs.primary : pt.line200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (i < total - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 32,
              child: Text(
                '$step/$total',
                style: TextStyle(
                  fontSize: 13,
                  color: pt.ink500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.child,
    this.cta,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08 * 12,
                  color: AppColors.blue600,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: tt.displayMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 15, height: 1.45, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: child,
          ),
        ),
        if (cta != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: cta!,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Welcome
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart, required this.onSkip});

  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 220,
              height: 160,
              child: Stack(
                children: [
                  _Blob(color: AppColors.coral500, x: 8, y: 12, size: 100, label: 'L'),
                  _Blob(color: AppColors.sunset500, x: 100, y: 36, size: 84, label: 'M'),
                  _Blob(color: AppColors.meadow500, x: 58, y: 90, size: 72, label: 'H'),
                  _Blob(color: AppColors.blue500, x: 140, y: 96, size: 60, label: '+'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Welcome to\nPetFolio',
              textAlign: TextAlign.center,
              style: tt.displayLarge?.copyWith(height: 1.05),
            ),
            const SizedBox(height: 14),
            Text(
              'One home for every pet in your life —\nsocial, health, care, and the marketplace.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Semantics(
              label: 'Add your first pet',
              button: true,
              child: PrimaryPillButton(
                key: const ValueKey('onboarding_start_cta'),
                label: 'Add your first pet',
                onPressed: onStart,
                isFullWidth: true,
                size: PillButtonSize.xl,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                child: const Text(
                  "I'll do this later",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.blue600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('You can add more pets anytime', style: TextStyle(fontSize: 12, color: pt.ink500)),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.label,
  });

  final Color color;
  final double x, y, size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [
              Color.lerp(color, Colors.white, 0.4)!,
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(color: color.withAlpha(90), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Species + Breed (combined)
// ─────────────────────────────────────────────────────────────────────────────

class _SpeciesBreedStep extends StatefulWidget {
  const _SpeciesBreedStep({
    required this.species,
    required this.breed,
    required this.onPickSpecies,
    required this.onPickBreed,
    required this.onNext,
    required this.onBack,
    required this.step,
    required this.total,
  });

  final PetSpecies? species;
  final String? breed;
  final ValueChanged<PetSpecies> onPickSpecies;
  final ValueChanged<String> onPickBreed;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int step, total;

  @override
  State<_SpeciesBreedStep> createState() => _SpeciesBreedStepState();
}

class _SpeciesBreedStepState extends State<_SpeciesBreedStep> {
  String _query = '';
  late final TextEditingController _searchCtrl;
  final _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchFocus.addListener(() => setState(() => _searchFocused = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SpeciesBreedStep old) {
    super.didUpdateWidget(old);
    if (old.species != widget.species) {
      _query = '';
      _searchCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = widget.species;
    final breed = widget.breed;

    final filtered = species == null
        ? <String>[]
        : (_query.isEmpty
            ? species.breeds
            : species.breeds
                .where((b) => b.toLowerCase().contains(_query.toLowerCase()))
                .toList());

    final subtitle = species == null
        ? 'Pick one. You can add more pets later.'
        : "Now choose a breed — or tap \"Don't know yet\".";

    return Column(
      children: [
        _OnboardingHeader(step: widget.step, total: widget.total, onBack: widget.onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step ${widget.step} of ${widget.total}',
            title: 'About your pet',
            subtitle: subtitle,
            cta: PrimaryPillButton(
              label: 'Continue',
              onPressed: (species != null && breed != null) ? widget.onNext : null,
              isFullWidth: true,
              size: PillButtonSize.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPECIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: pt.ink500,
                  ),
                ),
                const SizedBox(height: 10),

                // 3-column compact grid — all 6 species visible without scrolling
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 56,
                  ),
                  itemCount: PetSpecies.values.length,
                  itemBuilder: (_, i) => _CompactSpeciesCard(
                    species: PetSpecies.values[i],
                    selected: species == PetSpecies.values[i],
                    onTap: () => widget.onPickSpecies(PetSpecies.values[i]),
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),

                // Breed section (animated in after species pick)
                AnimatedSize(
                  duration: PetfolioThemeExtension.durationMd,
                  curve: Curves.easeOut,
                  child: species != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  'BREED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: pt.ink500,
                                  ),
                                ),
                                const Spacer(),
                                if (breed != null && !breed.startsWith("Don't"))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: species.tint,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: species.accent.withAlpha(80)),
                                    ),
                                    child: Text(
                                      breed,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: species.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // AuthField-style breed search
                            AnimatedContainer(
                              duration: PetfolioThemeExtension.durationSm,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _searchFocused
                                    ? [
                                        BoxShadow(
                                          color: cs.primary.withAlpha(30),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: (v) => setState(() => _query = v),
                                style: TextStyle(fontSize: 15, color: cs.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Search breeds',
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: _searchFocused ? cs.primary : pt.ink500,
                                  ),
                                  filled: true,
                                  fillColor: _searchFocused ? cs.surface : pt.surface2,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: pt.line200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: cs.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Breed list
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'No breeds match "$_query".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: pt.ink500),
                                ),
                              )
                            else
                              ...filtered.map((b) {
                                final isSelected = breed == b;
                                final isUnknown = b.startsWith("Don't");
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () => widget.onPickBreed(b),
                                    child: AnimatedContainer(
                                      duration: PetfolioThemeExtension.durationSm,
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? species.tint
                                            : (isUnknown ? pt.surface2 : cs.surface),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? species.accent : pt.line200,
                                          width: isSelected ? 2 : 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              b,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                fontStyle: isUnknown
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                                color: isUnknown
                                                    ? cs.onSurfaceVariant
                                                    : cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: species.accent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check,
                                                  size: 12, color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactSpeciesCard extends StatelessWidget {
  const _CompactSpeciesCard({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final PetSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? species.tint : cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: species.accent.withAlpha(70),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: const Offset(0, 1)),
                ],
          border: Border.all(
            color: selected ? species.accent : pt.line200,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? species.accent : species.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _SpeciesGlyph(
                species: species,
                color: selected ? Colors.white : species.accent,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                species.label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? species.accent : cs.onSurface,
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Pet Details (merged: name + DOB + weight + activity)
// ─────────────────────────────────────────────────────────────────────────────

class _PetDetailsStep extends StatefulWidget {
  const _PetDetailsStep({
    required this.name,
    required this.dateOfBirth,
    required this.weightKg,
    required this.targetWeightKg,
    required this.useKg,
    required this.activityLevel,
    required this.species,
    required this.onNameChanged,
    required this.onDobPick,
    required this.onWeightChanged,
    required this.onTargetChanged,
    required this.onUnitToggle,
    required this.onActivityPick,
    required this.onNext,
    required this.onBack,
    required this.step,
    required this.total,
  });

  final String name;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final double? targetWeightKg;
  final bool useKg;
  final String? activityLevel;
  final PetSpecies species;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<DateTime> onDobPick;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<double?> onTargetChanged;
  final ValueChanged<bool> onUnitToggle;
  final ValueChanged<String> onActivityPick;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int step, total;

  @override
  State<_PetDetailsStep> createState() => _PetDetailsStepState();
}

class _PetDetailsStepState extends State<_PetDetailsStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _currentWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  final _nameFocus = FocusNode();
  final _currentWeightFocus = FocusNode();
  final _targetWeightFocus = FocusNode();
  bool _nameFocused = false;
  bool _currentWeightFocused = false;
  bool _targetWeightFocused = false;

  static const _kgToLbs = 2.20462;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _currentWeightCtrl = TextEditingController(
      text: _formatWeight(widget.weightKg, widget.useKg),
    );
    _targetWeightCtrl = TextEditingController(
      text: _formatWeight(widget.targetWeightKg, widget.useKg),
    );
    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _currentWeightFocus.addListener(
      () => setState(() => _currentWeightFocused = _currentWeightFocus.hasFocus),
    );
    _targetWeightFocus.addListener(
      () => setState(() => _targetWeightFocused = _targetWeightFocus.hasFocus),
    );
  }

  @override
  void didUpdateWidget(_PetDetailsStep old) {
    super.didUpdateWidget(old);
    if (old.useKg != widget.useKg) {
      _currentWeightCtrl.text = _formatWeight(widget.weightKg, widget.useKg);
      _targetWeightCtrl.text = _formatWeight(widget.targetWeightKg, widget.useKg);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _nameFocus.dispose();
    _currentWeightFocus.dispose();
    _targetWeightFocus.dispose();
    super.dispose();
  }

  String _formatWeight(double? kg, bool useKg) {
    if (kg == null) return '';
    final v = useKg ? kg : kg * _kgToLbs;
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  double? _parseToKg(String text, bool useKg) {
    final v = double.tryParse(text);
    if (v == null || v <= 0) return null;
    return useKg ? v : v / _kgToLbs;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.dateOfBirth ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Date of birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.blue500),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) widget.onDobPick(picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _ageLabel(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0 && months > 0) return '$years yr $months mo old';
    if (years > 0) return '$years year${years > 1 ? 's' : ''} old';
    if (months > 0) return '$months month${months > 1 ? 's' : ''} old';
    return 'Just born';
  }

  Widget _sectionLabel(String text, PetfolioThemeExtension pt, {String? suffix}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: pt.ink500,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(suffix, style: TextStyle(fontSize: 11, color: pt.ink300)),
        ],
      ],
    );
  }

  Widget _buildNameField(ColorScheme cs, PetfolioThemeExtension pt) {
    return AnimatedContainer(
      duration: PetfolioThemeExtension.durationSm,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _nameFocused || _nameCtrl.text.isNotEmpty
            ? [BoxShadow(color: cs.primary.withAlpha(30), blurRadius: 8)]
            : [],
      ),
      child: TextField(
        controller: _nameCtrl,
        focusNode: _nameFocus,
        maxLength: 24,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onChanged: (v) {
          widget.onNameChanged(v);
          setState(() {});
        },
        style: TextStyle(fontSize: 16, color: cs.onSurface),
        decoration: InputDecoration(
          labelText: "Pet's name",
          filled: true,
          fillColor: _nameFocused ? cs.surface : pt.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pt.line200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required bool focused,
    required String label,
    required String unit,
    required ColorScheme cs,
    required PetfolioThemeExtension pt,
    required ValueChanged<String> onChanged,
  }) {
    return AnimatedContainer(
      duration: PetfolioThemeExtension.durationSm,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: focused || ctrl.text.isNotEmpty
            ? [BoxShadow(color: cs.primary.withAlpha(30), blurRadius: 8)]
            : [],
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
        onChanged: onChanged,
        style: TextStyle(fontSize: 16, color: cs.onSurface),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          suffixStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: pt.ink500,
          ),
          filled: true,
          fillColor: focused ? cs.surface : pt.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pt.line200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDobPicker(ColorScheme cs, PetfolioThemeExtension pt) {
    final dob = widget.dateOfBirth;
    return GestureDetector(
      onTap: _pickDate,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dob != null ? widget.species.tint : pt.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dob != null ? widget.species.accent : pt.line200,
            width: dob != null ? 2 : 1,
          ),
          boxShadow: dob != null
              ? [BoxShadow(color: widget.species.accent.withAlpha(30), blurRadius: 8)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dob != null ? widget.species.accent : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: dob != null ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dob != null ? _formatDate(dob) : 'Tap to set date of birth',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dob != null ? widget.species.accent : cs.onSurfaceVariant,
                    ),
                  ),
                  if (dob != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _ageLabel(dob),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.species.accent.withAlpha(180),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: dob != null ? widget.species.accent.withAlpha(160) : pt.ink300,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final nameReady = _nameCtrl.text.trim().isNotEmpty;

    return Column(
      children: [
        _OnboardingHeader(step: widget.step, total: widget.total, onBack: widget.onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step ${widget.step} of ${widget.total}',
            title: 'Your ${widget.species.label.toLowerCase()}\'s profile',
            cta: PrimaryPillButton(
              label: nameReady ? 'Continue' : 'Skip for now',
              onPressed: widget.onNext,
              isFullWidth: true,
              size: PillButtonSize.xl,
              variant: nameReady ? PillButtonVariant.primary : PillButtonVariant.secondary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ────────────────────────────────────────────────
                _sectionLabel('NAME', pt),
                const SizedBox(height: 8),
                _buildNameField(cs, pt),
                const SizedBox(height: 24),

                // ── Date of Birth ────────────────────────────────────────
                _sectionLabel('DATE OF BIRTH', pt, suffix: 'optional'),
                const SizedBox(height: 8),
                _buildDobPicker(cs, pt),
                const SizedBox(height: 24),

                // ── Weight ───────────────────────────────────────────────
                Row(
                  children: [
                    _sectionLabel('WEIGHT', pt, suffix: 'optional'),
                    const Spacer(),
                    _UnitToggle(useKg: widget.useKg, onToggle: widget.onUnitToggle),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWeightField(
                  ctrl: _currentWeightCtrl,
                  focus: _currentWeightFocus,
                  focused: _currentWeightFocused,
                  label: 'Current weight',
                  unit: widget.useKg ? 'kg' : 'lbs',
                  cs: cs,
                  pt: pt,
                  onChanged: (v) => widget.onWeightChanged(_parseToKg(v, widget.useKg)),
                ),
                const SizedBox(height: 10),
                _buildWeightField(
                  ctrl: _targetWeightCtrl,
                  focus: _targetWeightFocus,
                  focused: _targetWeightFocused,
                  label: 'Target weight',
                  unit: widget.useKg ? 'kg' : 'lbs',
                  cs: cs,
                  pt: pt,
                  onChanged: (v) => widget.onTargetChanged(_parseToKg(v, widget.useKg)),
                ),
                const SizedBox(height: 24),

                // ── Activity Level ───────────────────────────────────────
                _sectionLabel('ACTIVITY LEVEL', pt, suffix: 'optional'),
                const SizedBox(height: 8),
                ..._kActivityOptions.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActivityTile(
                      option: opt,
                      selected: widget.activityLevel == opt.id,
                      onTap: () => widget.onActivityPick(opt.id),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity tile — compact horizontal row (no overflow)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityOption {
  const _ActivityOption(this.id, this.label, this.description, this.icon, this.accent, this.tint);
  final String id, label, description;
  final IconData icon;
  final Color accent, tint;
}

const _kActivityOptions = [
  _ActivityOption(
    'sedentary',
    'Couch Potato',
    'Mostly resting, minimal movement',
    Icons.weekend_rounded,
    Color(0xFF60A5FA),
    Color(0xFFEFF6FF),
  ),
  _ActivityOption(
    'low',
    'Easy Going',
    'Short walks & light play',
    Icons.directions_walk_rounded,
    Color(0xFF34D399),
    Color(0xFFF0FDF4),
  ),
  _ActivityOption(
    'moderate',
    'Active',
    'Daily walks & regular play',
    Icons.directions_run_rounded,
    AppColors.meadow500,
    Color(0xFFDCFCE7),
  ),
  _ActivityOption(
    'high',
    'Energetic',
    'Long runs & vigorous exercise',
    Icons.bolt_rounded,
    AppColors.sunset500,
    Color(0xFFFFF7ED),
  ),
  _ActivityOption(
    'very_high',
    'Athlete',
    'Intense exercise every day',
    Icons.fitness_center_rounded,
    AppColors.coral500,
    Color(0xFFFFF1F2),
  ),
];

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ActivityOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? option.tint : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? option.accent : pt.line200,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: option.accent.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: const Offset(0, 1)),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? option.accent : option.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                size: 16,
                color: selected ? Colors.white : option.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? option.accent : cs.onSurface,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? option.accent.withAlpha(180)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: option.accent, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit toggle
// ─────────────────────────────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.useKg, required this.onToggle});

  final bool useKg;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: pt.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pt.line200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(label: 'kg', selected: useKg, cs: cs, pt: pt, onTap: () => onToggle(true)),
          _UnitChip(label: 'lbs', selected: !useKg, cs: cs, pt: pt, onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.cs,
    required this.pt,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme cs;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : pt.ink500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Photo
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.name,
    required this.species,
    this.photoBytes,
    required this.onBack,
    required this.onSetPhoto,
    required this.onNext,
    required this.step,
    required this.total,
  });

  final String name;
  final PetSpecies species;
  final Uint8List? photoBytes;
  final VoidCallback onBack;
  final ValueChanged<Uint8List> onSetPhoto;
  final VoidCallback onNext;
  final int step, total;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    onSetPhoto(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _OnboardingHeader(step: step, total: total, onBack: onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step $step of $total',
            title: 'A photo of ${name.isNotEmpty ? name : 'your pet'}?',
            subtitle: 'Optional — gives your feed a face. You can add one later.',
            cta: Column(
              children: [
                PrimaryPillButton(
                  label: photoBytes != null ? 'Continue' : 'Skip for now',
                  onPressed: onNext,
                  isFullWidth: true,
                  size: PillButtonSize.xl,
                ),
                if (photoBytes == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        'Choose from library',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: species.tint,
                              borderRadius: BorderRadius.circular(36),
                              image: photoBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(photoBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: photoBytes != null
                                  ? [
                                      BoxShadow(
                                        color: species.accent.withAlpha(85),
                                        blurRadius: 40,
                                        offset: const Offset(0, 18),
                                      ),
                                      BoxShadow(color: species.tint, blurRadius: 0, spreadRadius: 4),
                                    ]
                                  : null,
                            ),
                            child: photoBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: species.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, color: Colors.white, size: 26),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to add photo',
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: species.accent,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (photoBytes == null)
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _DashedBorderPainter(
                              color: species.accent,
                              radius: 36,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "We'll never share photos without your permission.\nEXIF location data is stripped on upload.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: pt.ink500, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Done
// ─────────────────────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({
    required this.name,
    required this.species,
    this.breed,
    this.dateOfBirth,
    this.weightKg,
    this.activityLevel,
    this.photoBytes,
    required this.onEnter,
    required this.isLoading,
  });

  final String name;
  final PetSpecies species;
  final String? breed;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? activityLevel;
  final Uint8List? photoBytes;
  final VoidCallback onEnter;
  final bool isLoading;

  String _ageLabel(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
    if (months > 0) return '$months mo';
    return 'Newborn';
  }

  String? _activityLabel(String? id) {
    try {
      return _kActivityOptions.firstWhere((o) => o.id == id).label;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final hasBreed = breed != null && !breed!.startsWith("Don't");
    final hasDob = dateOfBirth != null;
    final hasWeight = weightKg != null;
    final hasActivity = activityLevel != null;

    final chips = <String>[
      if (hasBreed) breed!,
      if (hasDob) _ageLabel(dateOfBirth!),
      if (hasWeight) '${weightKg!.toStringAsFixed(1)} kg',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6],
          colors: [species.tint, pt.warmCream],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(species.accent, Colors.white, 0.3)!,
                      species.accent,
                    ],
                  ),
                  image: photoBytes != null
                      ? DecorationImage(
                          image: MemoryImage(photoBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: species.accent.withAlpha(100),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: photoBytes == null
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : species.emoji,
                          style: TextStyle(
                            fontSize: name.isNotEmpty ? 52 : 40,
                            color: Colors.white,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 28),
              Text(
                'Hi, ${name.isNotEmpty ? name : 'friend'}.',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.64,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (chips.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: chips
                      .map((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: species.tint,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: species.accent.withAlpha(60)),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: species.accent,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 14),
              Text(
                chips.isEmpty
                    ? 'Profile created. Fill in health details anytime from the Health tab.'
                    : 'Profile complete! You can add vet records and more from Health.',
                style: TextStyle(fontSize: 15, height: 1.45, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Column(
                children: [
                  _ChecklistItem(label: 'Basic profile', done: true, color: pt.success),
                  const SizedBox(height: 8),
                  _ChecklistItem(
                    label: hasDob && hasWeight ? 'Age & weight' : 'Age & weight · later',
                    done: hasDob && hasWeight,
                    color: hasDob && hasWeight ? pt.success : pt.ink300,
                  ),
                  const SizedBox(height: 8),
                  _ChecklistItem(
                    label: hasActivity
                        ? 'Activity level · ${_activityLabel(activityLevel)}'
                        : 'Activity level · later',
                    done: hasActivity,
                    color: hasActivity ? pt.success : pt.ink300,
                  ),
                  const SizedBox(height: 8),
                  _ChecklistItem(
                    label: 'Health & vaccinations · later',
                    done: false,
                    color: pt.ink300,
                  ),
                ],
              ),
              const Spacer(),
              Semantics(
                label: 'Enter PetFolio',
                button: true,
                child: PrimaryPillButton(
                  key: const ValueKey('onboarding_finish_cta'),
                  label: 'Enter PetFolio',
                  onPressed: isLoading ? null : onEnter,
                  isLoading: isLoading,
                  isFullWidth: true,
                  size: PillButtonSize.xl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.done,
    required this.color,
  });

  final String label;
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Opacity(
      opacity: done ? 1.0 : 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: pt.ink500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

class _SpeciesGlyph extends StatelessWidget {
  const _SpeciesGlyph({required this.species, required this.color, this.size = 22});
  final PetSpecies species;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SpeciesGlyphPainter(species: species, color: color),
    );
  }
}

class _SpeciesGlyphPainter extends CustomPainter {
  const _SpeciesGlyphPainter({required this.species, required this.color});
  final PetSpecies species;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (species) {
      case PetSpecies.dog:
        canvas.drawCircle(Offset(8 * s, 9 * s), 4 * s, fill);
        canvas.drawCircle(Offset(4 * s, 5 * s), 1.6 * s, fill);
        canvas.drawCircle(Offset(12 * s, 5 * s), 1.6 * s, fill);
      case PetSpecies.cat:
        canvas.drawCircle(Offset(8 * s, 10 * s), 4 * s, fill);
        canvas.drawPath(
          Path()
            ..moveTo(3.5 * s, 4 * s)
            ..lineTo(5.5 * s, 8 * s)
            ..lineTo(7.3 * s, 7 * s)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12.5 * s, 4 * s)
            ..lineTo(10.5 * s, 8 * s)
            ..lineTo(8.7 * s, 7 * s)
            ..close(),
          fill,
        );
      case PetSpecies.rabbit:
        canvas.drawCircle(Offset(8 * s, 11 * s), 3.5 * s, fill);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(6 * s, 5 * s), width: 2.4 * s, height: 6 * s),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(10 * s, 5 * s), width: 2.4 * s, height: 6 * s),
          fill,
        );
      case PetSpecies.bird:
        canvas.drawCircle(Offset(8 * s, 9 * s), 3.5 * s, fill);
        canvas.drawPath(
          Path()
            ..moveTo(5 * s, 6 * s)
            ..lineTo(3 * s, 4 * s)
            ..lineTo(5.5 * s, 4.5 * s)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(11 * s, 11 * s)
            ..lineTo(14 * s, 12 * s)
            ..lineTo(13 * s, 10 * s)
            ..close(),
          fill,
        );
      case PetSpecies.fish:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(7 * s, 8 * s), width: 8 * s, height: 5 * s),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(11 * s, 8 * s)
            ..lineTo(14 * s, 6 * s)
            ..lineTo(14 * s, 10 * s)
            ..close(),
          fill,
        );
      case PetSpecies.reptile:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(8 * s, 9 * s), width: 9 * s, height: 4.4 * s),
          fill,
        );
        canvas.drawCircle(
          Offset(11.5 * s, 8 * s),
          0.6 * s,
          Paint()..color = Colors.white,
        );
    }
  }

  @override
  bool shouldRepaint(_SpeciesGlyphPainter old) => old.species != species || old.color != color;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 2,
  });
  final Color color;
  final double radius;
  final double strokeWidth;

  static const double _dashLength = 8;
  static const double _gapLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final half = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(half, half, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
