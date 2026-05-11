import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../data/models/pet_species.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — 6-step progressive profiling
// step 0: Welcome  1: Species  2: Name  3: Breed  4: Photo  5: Done
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 4; // visible progress segments (steps 1-4)

  int _step = 0;
  PetSpecies? _species;
  String _name = '';
  String? _breed;
  Uint8List? _photoBytes;
  bool _isSubmitting = false;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step = (_step - 1).clamp(0, 5));

  Future<void> _complete() async {
    setState(() => _isSubmitting = true);
    try {
      // Create the pet record first.
      final pet = await ref.read(petListProvider.notifier).addPet(
            name: _name,
            species: _species!.name,
            breed: _breed,
          );

      // Upload photo and patch avatar_url if the user provided one.
      if (_photoBytes != null) {
        final repo = ref.read(petRepositoryProvider);
        final url = await repo.uploadAvatar(_photoBytes!, pet.id);
        await repo.updateAvatarUrl(pet.id, url);
        final updated = pet.copyWith(avatarUrl: url);
        ref.read(petListProvider.notifier).updateLocal(updated);
        await ref.read(activePetControllerProvider.notifier).setActivePet(updated);
      } else {
        await ref.read(activePetControllerProvider.notifier).setActivePet(pet);
      }

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: AnimatedSwitcher(
        duration: PetfolioThemeExtension.durationMd,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _buildStep(context, pt),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, PetfolioThemeExtension pt) {
    switch (_step) {
      case 0:
        return _WelcomeStep(onStart: _next, onSkip: () => context.go('/home'));
      case 1:
        return _SpeciesStep(
          selected: _species,
          onBack: _back,
          onPick: (sp) {
            setState(() {
              _species = sp;
              _breed = null; // reset breed when species changes
            });
            _next();
          },
          step: 1,
          total: _totalSteps,
        );
      case 2:
        return _NameStep(
          name: _name,
          species: _species!,
          onBack: _back,
          onChange: (v) => setState(() => _name = v),
          onNext: _next,
          step: 2,
          total: _totalSteps,
        );
      case 3:
        return _BreedStep(
          selected: _breed,
          species: _species!,
          onBack: _back,
          onPick: (b) {
            setState(() => _breed = b);
            _next();
          },
          step: 3,
          total: _totalSteps,
        );
      case 4:
        return _PhotoStep(
          name: _name,
          species: _species!,
          photoBytes: _photoBytes,
          onBack: _back,
          onSetPhoto: (bytes) => setState(() => _photoBytes = bytes),
          onNext: _next,
          step: 4,
          total: _totalSteps,
        );
      case 5:
        return _DoneStep(
          name: _name,
          species: _species!,
          breed: _breed,
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
  const _OnboardingHeader({
    required this.step,
    required this.total,
    required this.onBack,
  });

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
            // Back button — 44 dp hit target
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowE1L,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                        color: pt.line200,
                        blurRadius: 0,
                        spreadRadius: 0.5),
                  ],
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 24),
              ),
            ),
            const SizedBox(width: 14),

            // Progress bar
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

            // Step counter
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08 * 12,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: tt.displaySmall),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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

            // ── Hero blobs ──────────────────────────────────────────────
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

            // ── Copy ────────────────────────────────────────────────────
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

            // ── CTAs ─────────────────────────────────────────────────────
            PrimaryPillButton(
              label: 'Add your first pet',
              onPressed: onStart,
              isFullWidth: true,
              size: PillButtonSize.xl,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                child: Text(
                  "I'll do this later",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can add more pets anytime',
              style: TextStyle(fontSize: 12, color: pt.ink500),
            ),
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
            BoxShadow(
              color: color.withAlpha(90),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Sora',
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
// Step 1 — Choose species
// ─────────────────────────────────────────────────────────────────────────────

class _SpeciesStep extends StatelessWidget {
  const _SpeciesStep({
    required this.selected,
    required this.onBack,
    required this.onPick,
    required this.step,
    required this.total,
  });

  final PetSpecies? selected;
  final VoidCallback onBack;
  final ValueChanged<PetSpecies> onPick;
  final int step, total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OnboardingHeader(step: step, total: total, onBack: onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step $step of $total',
            title: 'What kind of pet?',
            subtitle: 'Pick one. You can add more pets later.',
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: PetSpecies.values
                  .map((sp) => _SpeciesCard(
                        species: sp,
                        selected: selected == sp,
                        onTap: () => onPick(sp),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: selected ? species.tint : cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: species.accent.withAlpha(85),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowE1L,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
          border: Border.all(
            color: selected ? species.accent : pt.line200,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon chip
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: species.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: species.accent.withAlpha(170),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                species.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const Spacer(),
            Text(
              species.label,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Choose name
// ─────────────────────────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  const _NameStep({
    required this.name,
    required this.species,
    required this.onBack,
    required this.onChange,
    required this.onNext,
    required this.step,
    required this.total,
  });

  final String name;
  final PetSpecies species;
  final VoidCallback onBack;
  final ValueChanged<String> onChange;
  final VoidCallback onNext;
  final int step, total;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focus);
    });
  }

  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final ready = _ctrl.text.trim().isNotEmpty;

    return Column(
      children: [
        _OnboardingHeader(
            step: widget.step, total: widget.total, onBack: widget.onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step ${widget.step} of ${widget.total}',
            title:
                "What's your ${widget.species.label.toLowerCase()}'s name?",
            subtitle: 'Just a name for now — fill in the rest later.',
            cta: PrimaryPillButton(
              label: 'Continue',
              onPressed: ready ? widget.onNext : null,
              isFullWidth: true,
              size: PillButtonSize.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large name input (64 dp, Sora)
                AnimatedContainer(
                  duration: PetfolioThemeExtension.durationSm,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ready ? cs.primary.withAlpha(40) : AppColors.shadowE1L,
                        blurRadius: 2,
                        spreadRadius: ready ? 1.5 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: ready ? cs.primary : pt.line200,
                      width: ready ? 1.5 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: (v) {
                      widget.onChange(v);
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (ready) widget.onNext();
                    },
                    maxLength: 24,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Luna',
                      hintStyle: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: pt.ink300,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${_ctrl.text.length} / 24',
                    style: TextStyle(fontSize: 13, color: pt.ink500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Choose breed
// ─────────────────────────────────────────────────────────────────────────────

class _BreedStep extends StatefulWidget {
  const _BreedStep({
    required this.selected,
    required this.species,
    required this.onBack,
    required this.onPick,
    required this.step,
    required this.total,
  });

  final String? selected;
  final PetSpecies species;
  final VoidCallback onBack;
  final ValueChanged<String> onPick;
  final int step, total;

  @override
  State<_BreedStep> createState() => _BreedStepState();
}

class _BreedStepState extends State<_BreedStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final filtered = _query.isEmpty
        ? widget.species.breeds
        : widget.species.breeds
            .where((b) => b.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        _OnboardingHeader(
            step: widget.step, total: widget.total, onBack: widget.onBack),
        Expanded(
          child: _StepFrame(
            eyebrow: 'Step ${widget.step} of ${widget.total}',
            title: 'Breed?',
            subtitle: "Pick one or tap \"Don't know yet\" — you can change this anytime.",
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pt.line200, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, size: 18, color: pt.ink500),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search breeds',
                            hintStyle: TextStyle(
                                fontSize: 16, color: pt.ink300),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(fontSize: 16, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Breed list
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No breeds match "$_query".\nTap "Don\'t know yet" — you can always edit later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: pt.ink500),
                    ),
                  )
                else
                  ...filtered.map((b) {
                    final isSelected = widget.selected == b;
                    final isUnknown = b.startsWith("Don't");
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onPick(b),
                        child: AnimatedContainer(
                          duration: PetfolioThemeExtension.durationSm,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.species.tint
                                : (isUnknown ? pt.surface2 : cs.surface),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected ? widget.species.accent : pt.line200,
                              width: isSelected ? 2 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: isUnknown
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: isUnknown ? cs.onSurfaceVariant : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: widget.species.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 14, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Add photo (optional)
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
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: photoBytes != null ? null : species.tint,
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: photoBytes == null
                            ? Border.all(
                                color: species.accent,
                                width: 2,
                                style: BorderStyle.solid,
                              )
                            : Border.all(
                                color: species.tint,
                                width: 4,
                              ),
                        boxShadow: photoBytes != null
                            ? [
                                BoxShadow(
                                  color: species.accent.withAlpha(85),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: species.accent.withAlpha(100),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    fontFamily: 'Sora',
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
                  const SizedBox(height: 18),
                  Text(
                    'We\'ll never share photos without your permission.\nEXIF location data is stripped on upload.',
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
// Step 5 — Done
// ─────────────────────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({
    required this.name,
    required this.species,
    this.breed,
    this.photoBytes,
    required this.onEnter,
    required this.isLoading,
  });

  final String name;
  final PetSpecies species;
  final String? breed;
  final Uint8List? photoBytes;
  final VoidCallback onEnter;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hasBreed = breed != null && !breed!.startsWith("Don't");

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6],
          colors: [species.tint, pt.surface1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),

              // ── Pet avatar ────────────────────────────────────────────
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
                          name.isNotEmpty
                              ? name.substring(0, 1).toUpperCase()
                              : species.emoji,
                          style: TextStyle(
                            fontSize: name.isNotEmpty ? 52 : 40,
                            color: Colors.white,
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 28),

              // ── Name + profile created ────────────────────────────────
              Text(
                'Hi, ${name.isNotEmpty ? name : 'friend'}.',
                style: tt.displaySmall?.copyWith(letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                [
                  if (hasBreed) '$breed · ',
                  'Profile created. You can fill in age, weight, vet info anytime from Health.',
                ].join(),
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ── Deferred items checklist ──────────────────────────────
              Column(
                children: [
                  _ChecklistItem(label: 'Basic profile', done: true, color: pt.success),
                  const SizedBox(height: 8),
                  _ChecklistItem(
                      label: 'Health & vaccinations · later',
                      done: false,
                      color: pt.ink300),
                  const SizedBox(height: 8),
                  _ChecklistItem(
                      label: 'Daily care routine · later',
                      done: false,
                      color: pt.ink300),
                ],
              ),

              const Spacer(),

              // ── Enter CTA ─────────────────────────────────────────────
              PrimaryPillButton(
                label: 'Enter PetFolio',
                onPressed: isLoading ? null : onEnter,
                isLoading: isLoading,
                isFullWidth: true,
                size: PillButtonSize.xl,
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
          Text(
            label,
            style: TextStyle(fontSize: 13, color: pt.ink500),
          ),
        ],
      ),
    );
  }
}
