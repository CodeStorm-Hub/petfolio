import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/platform/media_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/breed_identification_service.dart';

class BreedIdentifierWidget extends ConsumerStatefulWidget {
  const BreedIdentifierWidget({
    super.key,
    required this.onBreedIdentified,
  });

  final void Function(String breed, String species) onBreedIdentified;

  @override
  ConsumerState<BreedIdentifierWidget> createState() =>
      _BreedIdentifierWidgetState();
}

class _BreedIdentifierWidgetState
    extends ConsumerState<BreedIdentifierWidget> {
  File? _imageFile;
  bool _loading = false;
  String? _error;
  String? _resultBreed;
  String? _resultSpecies;
  double? _confidence;
  String? _description;

  Future<void> _pickAndIdentify(ImageSource source) async {
    final picked = await pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _loading = true;
      _error = null;
      _resultBreed = null;
    });

    try {
      final result = await ref
          .read(breedIdentificationServiceProvider)
          .identifyBreed(_imageFile!);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _resultBreed = result.breed;
        _resultSpecies = result.species;
        _confidence = result.confidence;
        _description = result.description;
      });
    } on BreedIdentificationException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _apply() {
    if (_resultBreed != null && _resultSpecies != null) {
      widget.onBreedIdentified(_resultBreed!, _resultSpecies!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImagePicker(
          imageFile: _imageFile,
          loading: _loading,
          onCamera: () => _pickAndIdentify(ImageSource.camera),
          onGallery: () => _pickAndIdentify(ImageSource.gallery),
          pt: pt,
        ),
        if (_loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Identifying breed…',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: pt.ink500)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(error: _error!, cs: cs),
        ],
        if (_resultBreed != null) ...[
          const SizedBox(height: 16),
          _ResultCard(
            breed: _resultBreed!,
            species: _resultSpecies!,
            confidence: _confidence ?? 0,
            description: _description,
            pt: pt,
            tt: tt,
            onApply: _apply,
          ),
        ],
      ],
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageFile,
    required this.loading,
    required this.onCamera,
    required this.onGallery,
    required this.pt,
  });
  final File? imageFile;
  final bool loading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: pt.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageFile != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(imageFile!, fit: BoxFit.cover),
                if (loading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: onCamera,
                  pt: pt,
                ),
                const SizedBox(width: 24),
                _PickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: onGallery,
                  pt: pt,
                ),
              ],
            ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.pt,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.mint, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: tt.labelSmall?.copyWith(color: pt.ink500)),
        ],
      ),
    ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.breed,
    required this.species,
    required this.confidence,
    this.description,
    required this.pt,
    required this.tt,
    required this.onApply,
  });
  final String breed;
  final String species;
  final double confidence;
  final String? description;
  final PetfolioThemeExtension pt;
  final TextTheme tt;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.mint, size: 18),
              const SizedBox(width: 6),
              Text('Breed identified',
                  style: tt.labelMedium?.copyWith(
                      color: AppColors.mint, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pct% confident',
                    style: tt.labelSmall?.copyWith(color: AppColors.mint)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(breed,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text('Species: $species',
              style: tt.bodySmall?.copyWith(color: pt.ink500)),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!,
                style: tt.bodySmall?.copyWith(color: pt.ink500)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text('Use "$breed"'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.cs});
  final String error;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(error,
          style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
    );
  }
}
