
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import 'package:petfolio/core/domain/controllers/active_pet_controller.dart';
import 'package:petfolio/core/domain/controllers/pet_list_controller.dart';
// import '../../../../core/theme/app_theme.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.addAnotherPet = false});
  final bool addAnotherPet;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 5;

  late int _step = widget.addAnotherPet ? 1 : 0;
  PetSpecies _species = PetSpecies.dog;
  String _name = '';
  int _ageMonths = 24;
  final List<String> _personality = [];
  bool _isSubmitting = false;

  void _next() => setState(() => _step++);
  void _back() {
    final floor = widget.addAnotherPet ? 1 : 0;
    if (_step <= floor) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() => _step = (_step - 1).clamp(0, _totalSteps));
  }

  Future<void> _complete() async {
    setState(() => _isSubmitting = true);
    try {
      final pet = await ref.read(petListProvider.notifier).addPet(
            name: _name,
            species: _species.name,
            dateOfBirth: DateTime.now().subtract(Duration(days: _ageMonths * 30)),
            bio: _personality.join(', '),
          );

      await ref.read(activePetControllerProvider.notifier).setActivePet(pet);

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
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface1D : const Color(0xFFFFFFFF);
    final softColor = _species.resolvedTint(isDark);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              softColor,
              bgColor,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating paws
            Positioned.fill(
              child: _FloatingPaws(species: _species),
            ),
            
            // Content
            Column(
              children: [
                _OnboardingHeader(step: _step, total: _totalSteps, onBack: _back),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _StepHello(
          onNext: _next,
          onSkip: () => context.go('/home'),
          species: _species,
        );
      case 1:
        return _StepSpecies(
          selectedSpecies: _species,
          onSelect: (s) => setState(() => _species = s),
          onNext: _next,
        );
      case 2:
        return _StepName(
          name: _name,
          species: _species,
          onNameChanged: (n) => setState(() => _name = n),
          onNext: _next,
        );
      case 3:
        return _StepAge(
          ageMonths: _ageMonths,
          name: _name,
          species: _species,
          onAgeChanged: (a) => setState(() => _ageMonths = a),
          onNext: _next,
        );
      case 4:
        return _StepPersonality(
          personality: _personality,
          name: _name,
          species: _species,
          onToggle: (p) {
            setState(() {
              if (_personality.contains(p)) {
                _personality.remove(p);
              } else {
                _personality.add(p);
              }
            });
          },
          onNext: () {
            _next();
            Future.delayed(const Duration(milliseconds: 1400), _complete);
          },
        );
      case 5:
        return _StepDone(
          name: _name,
          species: _species,
          isLoading: _isSubmitting,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.total, required this.onBack});
  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    if (step == 0 || step >= total) return const SizedBox.shrink();
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final activeColor = pt.ink950;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < total - 1; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < step ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (i < total - 2) const SizedBox(width: 6),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _FloatingPaws extends StatefulWidget {
  const _FloatingPaws({required this.species});
  final PetSpecies species;

  @override
  State<_FloatingPaws> createState() => _FloatingPawsState();
}

class _FloatingPawsState extends State<_FloatingPaws> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.species.resolvedAccent(isDark);
    
    return Opacity(
      opacity: 0.16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Stack(
            children: [
              _buildPaw(14, 18, 40, 12, math.sin(t * math.pi * 2) * 10, color),
              _buildPaw(80, 22, 28, -8, math.cos(t * math.pi * 2) * 8, color),
              _buildPaw(12, 68, 32, 18, math.sin(t * math.pi * 2 + 1) * 12, color),
              _buildPaw(78, 72, 46, -12, math.cos(t * math.pi * 2 + 1.5) * 9, color),
              _buildPaw(42, 38, 22, 4, math.sin(t * math.pi * 2 + 2) * 7, color),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaw(double x, double y, double size, double rot, double offset, Color color) {
    return Positioned(
      left: MediaQuery.of(context).size.width * (x / 100),
      top: MediaQuery.of(context).size.height * (y / 100) + offset,
      child: Transform.rotate(
        angle: rot * math.pi / 180,
        child: Icon(Icons.pets_rounded, size: size, color: color),
      ),
    );
  }
}

// -- Steps --

class _StepHello extends StatelessWidget {
  const _StepHello({required this.onNext, required this.onSkip, required this.species});
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final PetSpecies species;

  @override
  Widget build(BuildContext context) {
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 160,
            height: 160,
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [pc.tangerine, pc.poppy, pc.sunny, pc.mint, pc.tangerine],
              ),
              boxShadow: [
                BoxShadow(color: pc.tangerine.withAlpha(100), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🐾', style: TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Hi! I'm PetFolio.",
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: pt.ink950,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your pet's whole life — feeds, friends, health, treats — in one cozy place.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: const Color(0xFF334155), height: 1.45),
          ),
          const Spacer(flex: 2),
          PrimaryPillButton(
            label: 'Start the tail-wag',
            onPressed: onNext,
            isFullWidth: true,
            size: PillButtonSize.xl,
            trailingIcon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onSkip,
            child: Text(
              "I already have an account",
              style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xFF334155), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepSpecies extends StatelessWidget {
  const _StepSpecies({required this.selectedSpecies, required this.onSelect, required this.onNext});
  final PetSpecies selectedSpecies;
  final ValueChanged<PetSpecies> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Who are we\nwelcoming home?",
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700, height: 1.1,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick your pet — the app will dress up to match.",
            style: TextStyle(fontSize: 15, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 22),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: PetSpecies.values.length,
              itemBuilder: (context, i) {
                final s = PetSpecies.values[i];
                final on = selectedSpecies == s;
                final color = s.resolvedAccent(isDark);
                
                return GestureDetector(
                  onTap: () => onSelect(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 14),
                    decoration: BoxDecoration(
                      color: on ? color : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: on ? color : Colors.transparent, width: 2),
                      boxShadow: on 
                          ? [BoxShadow(color: color.withAlpha(100), blurRadius: 24, offset: const Offset(0, 10))]
                          : [const BoxShadow(color: AppColors.shadowE1L, blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: on ? Colors.white.withAlpha(70) : s.resolvedTint(isDark),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(s.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: on ? Colors.white : pt.ink950,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          PrimaryPillButton(
            label: 'Continue',
            onPressed: onNext,
            isFullWidth: true,
            size: PillButtonSize.xl,
            trailingIcon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _StepName extends StatelessWidget {
  const _StepName({required this.name, required this.species, required this.onNameChanged, required this.onNext});
  final String name;
  final PetSpecies species;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = species.resolvedAccent(isDark);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, height: 1.1,
                color: pt.ink950,
              ),
              children: [
                const TextSpan(text: "What's "),
                TextSpan(text: "their name", style: TextStyle(color: color)),
                const TextSpan(text: "?"),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "The one you whisper when no one's watching.",
            style: TextStyle(fontSize: 15, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 24),
          
          PfCard(
            padding: const EdgeInsets.all(4),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            child: TextField(
              onChanged: onNameChanged,
              controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: pt.ink950),
              decoration: InputDecoration(
                hintText: "e.g. Mochi, Biscuit...",
                hintStyle: TextStyle(color: pt.ink300),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Mochi', 'Biscuit', 'Pepper', 'Luna', 'Coco', 'Tofu'].map((n) {
              return GestureDetector(
                onTap: () => onNameChanged(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(n, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                ),
              );
            }).toList(),
          ),
          
          const Spacer(),
          PrimaryPillButton(
            label: 'Lovely name',
            onPressed: name.trim().isNotEmpty ? onNext : null,
            isFullWidth: true,
            size: PillButtonSize.xl,
            trailingIcon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _StepAge extends StatelessWidget {
  const _StepAge({required this.ageMonths, required this.name, required this.species, required this.onAgeChanged, required this.onNext});
  final int ageMonths;
  final String name;
  final PetSpecies species;
  final ValueChanged<int> onAgeChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = species.resolvedAccent(isDark);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    
    final years = ageMonths / 12;
    final displayNum = years < 1 ? ageMonths : years.floor();
    final displayLabel = years < 1 
        ? (ageMonths == 1 ? 'month' : 'months') 
        : (years.floor() == 1 ? 'year young' : 'years young');

    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, height: 1.1,
                color: pt.ink950,
              ),
              children: [
                const TextSpan(text: "How old is "),
                TextSpan(text: name.isEmpty ? 'they' : name, style: TextStyle(color: color)),
                const TextSpan(text: "?"),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Slide the bone — it's about right, no need to be exact.",
            style: TextStyle(fontSize: 15, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 24),
          
          PfCard(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayNum',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: pt.ink950),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayLabel,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                BoneSliderWidget(
                  value: ageMonths.toDouble(),
                  min: 1,
                  max: 216,
                  color: color,
                  onChanged: (v) => onAgeChanged(v.toInt()),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PUPPY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF64748B))),
                    Text('ADULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF64748B))),
                    Text('SENIOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          PrimaryPillButton(
            label: 'Continue',
            onPressed: onNext,
            isFullWidth: true,
            size: PillButtonSize.xl,
            trailingIcon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _StepPersonality extends StatelessWidget {
  const _StepPersonality({required this.personality, required this.name, required this.species, required this.onToggle, required this.onNext});
  final List<String> personality;
  final String name;
  final PetSpecies species;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  static const traits = [
    {'id': 'Cuddly', 'emoji': '🤗'},
    {'id': 'Playful', 'emoji': '🎾'},
    {'id': 'Shy', 'emoji': '🙈'},
    {'id': 'Chaos goblin', 'emoji': '😈'},
    {'id': 'Treat fiend', 'emoji': '🦴'},
    {'id': 'Adventurer', 'emoji': '🏕️'},
    {'id': 'Couch potato', 'emoji': '🛋️'},
    {'id': 'Chatty', 'emoji': '💬'},
    {'id': 'Loyal guard', 'emoji': '🛡️'},
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = species.resolvedAccent(isDark);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, height: 1.1,
                color: pt.ink950,
              ),
              children: [
                const TextSpan(text: "How would you describe their\n"),
                TextSpan(text: "vibe", style: TextStyle(color: color)),
                const TextSpan(text: "?"),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick a few. We won't tell anyone.",
            style: TextStyle(fontSize: 15, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 22),
          
          Wrap(
            spacing: 8, runSpacing: 8,
            children: traits.map((t) {
              final on = personality.contains(t['id']);
              return GestureDetector(
                onTap: () => onToggle(t['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: on ? color : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: on ? color : const Color(0xFFE2E8F0), width: 2),
                    boxShadow: on ? [BoxShadow(color: color.withAlpha(100), blurRadius: 14, offset: const Offset(0, 6))] : [],
                  ),
                  transform: Matrix4.diagonal3Values(on ? 1.04 : 1.0, on ? 1.04 : 1.0, 1.0),
                  transformAlignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t['emoji']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        t['id']!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: on ? Colors.white : pt.ink950),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const Spacer(),
          PrimaryPillButton(
            label: 'Meet ${name.isEmpty ? 'them' : name}',
            color: color,
            onPressed: onNext,
            isFullWidth: true,
            size: PillButtonSize.xl,
            trailingIcon: const Icon(Icons.pets_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StepDone extends StatelessWidget {
  const _StepDone({required this.name, required this.species, required this.isLoading});
  final String name;
  final PetSpecies species;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pc = Theme.of(context).extension<PetFolioColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 50, 22, 100),
      child: Column(
        children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: species.resolvedTint(isDark),
              border: Border.all(color: species.resolvedAccent(isDark), width: 4),
              boxShadow: [
                BoxShadow(color: species.resolvedAccent(isDark).withAlpha(100), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(species.emoji, style: const TextStyle(fontSize: 70)),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome, $name!",
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text("Let's set up their world...", style: TextStyle(fontSize: 16, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink700)),
          const SizedBox(height: 40),
          if (isLoading)
            TailWagLoader(
              size: 80,
              color: species.resolvedAccent(isDark),
              label: 'Setting up...',
            ),
        ],
      ),
    );
  }
}
