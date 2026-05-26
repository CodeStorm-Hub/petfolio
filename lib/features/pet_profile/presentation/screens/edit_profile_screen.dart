import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/app_snack_bar.dart';
import 'package:petfolio/core/widgets/primary_pill_button.dart';
import 'package:petfolio/core/domain/models/pet.dart';
import 'package:petfolio/core/domain/models/pet_gender.dart';
import 'package:petfolio/core/domain/models/pet_species.dart';
import 'package:petfolio/core/domain/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/discovery_visibility_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/edit_profile_controller.dart';
import 'package:petfolio/core/domain/controllers/pet_list_controller.dart';
import 'package:petfolio/core/domain/models/activity_level.dart';


class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.pet});
  final Pet pet;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _bioController;
  late final TextEditingController _weightController;
  final _picker = ImagePicker();

  DateTime? _dateOfBirth;
  PetGender _gender = PetGender.unknown;
  String? _activityLevel;
  bool _isPublic = true;
  bool _syncLocationOnSave = true;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet.name);
    _breedController = TextEditingController(text: pet.breed ?? '');
    _bioController = TextEditingController(text: pet.bio ?? '');
    _weightController = TextEditingController(
      text: pet.weightKg != null
          ? (pet.weightKg! % 1 == 0
              ? pet.weightKg!.toStringAsFixed(0)
              : pet.weightKg!.toStringAsFixed(1))
          : '',
    );
    _dateOfBirth = pet.dateOfBirth;
    _gender = pet.gender;
    _activityLevel = pet.activityLevel;
    _isPublic = pet.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _bioController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  PetSpecies get _species {
    for (final s in PetSpecies.values) {
      if (s.name == widget.pet.species) return s;
    }
    return PetSpecies.dog;
  }

  Pet _resolvedPet(WidgetRef ref) {
    final list = ref.watch(petListProvider).value;
    if (list != null) {
      for (final p in list) {
        if (p.id == widget.pet.id) return p;
      }
    }
    final active = ref.watch(activePetControllerProvider);
    if (active != null && active.id == widget.pet.id) return active;
    return widget.pet;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(editProfileControllerProvider.notifier).setImage(picked);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Date of birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).extension<PetfolioThemeExtension>()!.info,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
      ref.read(editProfileControllerProvider.notifier).clearError();
    }
  }

  void _clearDateOfBirth() {
    setState(() => _dateOfBirth = null);
    ref.read(editProfileControllerProvider.notifier).clearError();
  }

  double? _parseWeightKg() {
    final text = _weightController.text.trim();
    if (text.isEmpty) return null;
    final v = double.tryParse(text);
    if (v == null || v <= 0) return null;
    return v;
  }

  Future<void> _onDiscoverableChanged(bool value) async {
    try {
      await ref
          .read(discoveryVisibilityControllerProvider.notifier)
          .setDiscoverable(value);
      if (mounted && value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Match discovery enabled',
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    }
  }

  Future<void> _syncLocationNow() async {
    final ok = await ref
        .read(editProfileControllerProvider.notifier)
        .syncMatchLocation(widget.pet.id);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(petMatchLocationProvider(widget.pet.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Match location updated'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _save() async {
    final weight = _parseWeightKg();
    final weightText = _weightController.text.trim();
    if (weightText.isNotEmpty && weight == null) {
      ref.read(editProfileControllerProvider.notifier).clearError();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight in kg')),
      );
      return;
    }

    final pet = _resolvedPet(ref);
    final success = await ref.read(editProfileControllerProvider.notifier).submit(
          originalPet: pet,
          name: _nameController.text,
          breed: _breedController.text,
          bio: _bioController.text,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          weightKg: weight,
          activityLevel: _activityLevel,
          isPublic: _isPublic,
          isDiscoverable: pet.isDiscoverable,
          syncLocationIfDiscoverable: _syncLocationOnSave,
        );

    if (success && mounted) {
      ref.invalidate(petMatchLocationProvider(widget.pet.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Profile saved',
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider);
    final discoverableBusy = ref.watch(discoveryVisibilityControllerProvider);
    final activePet = ref.watch(activePetControllerProvider);
    final pet = _resolvedPet(ref);
    final showDiscovery = activePet != null && activePet.id == widget.pet.id;
    final locationAsync = showDiscovery
        ? ref.watch(petMatchLocationProvider(widget.pet.id))
        : null;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = _species;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: state.isSubmitting ? null : () => context.pop(),
        ),
        title: Text(
          'Edit profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  _SectionCard(
                    title: 'Photo & name',
                    subtitle: 'Required',
                    child: Column(
                      children: [
                        Center(child: _AvatarEditor(pet: pet, state: state, onTap: _pickImage)),
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'Name',
                          required: true,
                          child: TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => ref
                                .read(editProfileControllerProvider.notifier)
                                .clearError(),
                            decoration: const InputDecoration(hintText: 'Pet name'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'About',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Species', style: _fieldLabelStyle(pt)),
                        const SizedBox(height: 8),
                        _SpeciesChip(species: species),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Breed',
                          child: TextField(
                            controller: _breedController,
                            onChanged: (_) => ref
                                .read(editProfileControllerProvider.notifier)
                                .clearError(),
                            decoration: InputDecoration(
                              hintText: 'e.g. ${species.breeds.first}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Bio',
                          optional: true,
                          child: TextField(
                            controller: _bioController,
                            maxLines: 4,
                            maxLength: 280,
                            onChanged: (_) => ref
                                .read(editProfileControllerProvider.notifier)
                                .clearError(),
                            decoration: const InputDecoration(
                              hintText: 'Personality, favorites, fun facts…',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Date of birth', style: _fieldLabelStyle(pt)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDateOfBirth,
                                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                                label: Text(
                                  _dateOfBirth == null
                                      ? 'Add birthday'
                                      : _formatDate(_dateOfBirth!),
                                ),
                              ),
                            ),
                            if (_dateOfBirth != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Clear birthday',
                                onPressed: _clearDateOfBirth,
                                icon: Icon(Icons.close_rounded, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                        if (_dateOfBirth != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _ageLabel(_dateOfBirth!),
                            style: TextStyle(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text('Sex', style: _fieldLabelStyle(pt)),
                        const SizedBox(height: 8),
                        _GenderSelector(
                          value: _gender,
                          onChanged: (g) {
                            setState(() => _gender = g);
                            ref.read(editProfileControllerProvider.notifier).clearError();
                          },
                        ),
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'Weight',
                          optional: true,
                          suffix: 'kg',
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => ref
                                .read(editProfileControllerProvider.notifier)
                                .clearError(),
                            decoration: const InputDecoration(hintText: 'e.g. 12.5'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Activity',
                    subtitle: 'Helps nutrition & match filters',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opt in ActivityLevel.values)
                          _ActivityChip(
                            label: opt.label,
                            icon: opt.icon,
                            selected: _activityLevel == opt.id,
                            accent: species.accent,
                            onTap: () {
                              setState(() {
                                _activityLevel =
                                    _activityLevel == opt.id ? null : opt.id;
                              });
                              ref
                                  .read(editProfileControllerProvider.notifier)
                                  .clearError();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Visibility & matching',
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Public profile',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Show this pet on social posts and public views.',
                            style: TextStyle(fontSize: 13, height: 1.35, color: const Color(0xFF64748B)),
                          ),
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                        if (showDiscovery) ...[
                          const Divider(height: 24),
                          Semantics(
                            label: 'Match Discovery On/Off',
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Match discovery',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Let nearby owners find this pet in Playdates.',
                                style: TextStyle(fontSize: 13, height: 1.35, color: const Color(0xFF64748B)),
                              ),
                              value: pet.isDiscoverable,
                              onChanged:
                                  discoverableBusy ? null : _onDiscoverableChanged,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LocationRow(
                            locationAsync: locationAsync,
                            isSyncing: state.isSyncingLocation,
                            syncOnSave: _syncLocationOnSave,
                            onSyncOnSaveChanged: (v) => setState(() => _syncLocationOnSave = v),
                            onUpdateNow: _syncLocationNow,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 0.5)),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowE1L,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryPillButton(
                label: state.isSubmitting ? 'Saving…' : 'Save changes',
                onPressed: state.isSubmitting ? null : _save,
                isLoading: state.isSubmitting,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _fieldLabelStyle(PetfolioThemeExtension pt) => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: const Color(0xFF64748B),
      );

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _ageLabel(DateTime dob) {
    final now = DateTime.now();
    var years = now.year - dob.year;
    var months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0 && months > 0) return '$years yr $months mo';
    if (years > 0) return '$years year${years > 1 ? 's' : ''}';
    if (months > 0) return '$months month${months > 1 ? 's' : ''}';
    return 'Under 1 month';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowE1L,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
    this.optional = false,
    this.suffix,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool optional;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _EditProfileScreenState._fieldLabelStyle(pt)),
            if (required)
              Text(' *', style: TextStyle(color: pt.warning, fontWeight: FontWeight.w700)),
            if (optional)
              Text(' (optional)', style: TextStyle(fontSize: 12, color: pt.ink300)),
            if (suffix != null) ...[
              const Spacer(),
              Text(suffix!, style: TextStyle(fontSize: 13, color: const Color(0xFF64748B))),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.pet,
    required this.state,
    required this.onTap,
  });

  final Pet pet;
  final EditProfileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pt.surface2,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              image: state.newImage != null
                  ? DecorationImage(image: FileImage(File(state.newImage!.path)), fit: BoxFit.cover)
                  : pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(pet.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: state.newImage == null &&
                    (pet.avatarUrl == null || pet.avatarUrl!.isEmpty)
                ? Center(
                    child: Text(
                      pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  const _SpeciesChip({required this.species});
  final PetSpecies species;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: species.tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: species.accent.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(species.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            species.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.lock_outline_rounded, size: 16, color: const Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final PetGender value;
  final ValueChanged<PetGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SegmentedButton<PetGender>(
      segments: const [
        ButtonSegment(value: PetGender.male, label: Text('Male'), icon: Icon(Icons.male_rounded)),
        ButtonSegment(
          value: PetGender.female,
          label: Text('Female'),
          icon: Icon(Icons.female_rounded),
        ),
        ButtonSegment(
          value: PetGender.unknown,
          label: Text('Skip'),
          icon: Icon(Icons.remove_rounded),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.onPrimary;
          return cs.onSurface;
        }),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: selected ? accent.withAlpha(30) : cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? accent : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? accent : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.locationAsync,
    required this.isSyncing,
    required this.syncOnSave,
    required this.onSyncOnSaveChanged,
    required this.onUpdateNow,
  });

  final AsyncValue<bool>? locationAsync;
  final bool isSyncing;
  final bool syncOnSave;
  final ValueChanged<bool> onSyncOnSaveChanged;
  final VoidCallback onUpdateNow;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final statusText = locationAsync == null
        ? ''
        : locationAsync!.when(
            data: (has) => has ? 'Location saved for matching' : 'No location on file',
            loading: () => 'Checking location…',
            error: (_, _) => 'Could not load location status',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Match location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Uses your device GPS for nearby discovery. Update after you move.',
          style: TextStyle(fontSize: 13, height: 1.35, color: const Color(0xFF64748B)),
        ),
        if (statusText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                statusText.contains('saved') ? Icons.place_rounded : Icons.place_outlined,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(statusText, style: TextStyle(fontSize: 13, color: const Color(0xFF64748B))),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isSyncing ? null : onUpdateNow,
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(isSyncing ? 'Updating…' : 'Update location now'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'Refresh location when saving',
            style: TextStyle(fontSize: 14, color: cs.onSurface),
          ),
          value: syncOnSave,
          onChanged: (v) => onSyncOnSaveChanged(v ?? true),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pt.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pt.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: pt.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: pt.warning, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
