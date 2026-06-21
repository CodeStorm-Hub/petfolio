import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/breed_identifier_controller.dart';

class BreedIdentifierWidget extends ConsumerWidget {
  const BreedIdentifierWidget({
    super.key,
    required this.onBreedIdentified,
  });

  final void Function(String breed, String species) onBreedIdentified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(breedIdentifierControllerProvider);
    final controller = ref.read(breedIdentifierControllerProvider.notifier);
    final result = state.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImagePicker(
          imageFile: state.imageFile,
          loading: state.loading,
          onCamera: () => controller.pickAndIdentify(ImageSource.camera),
          onGallery: () => controller.pickAndIdentify(ImageSource.gallery),
          pt: pt,
        ),
        if (state.loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Identifying breed…',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: pt.ink500)),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(error: state.error!, cs: cs),
        ],
        if (result != null) ...[
          const SizedBox(height: 16),
          _ResultCard(
            breed: result.breed,
            species: result.species,
            confidence: result.confidence,
            description: result.description,
            pt: pt,
            tt: tt,
            onApply: () => onBreedIdentified(result.breed, result.species),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mint = isDark ? AppColors.mintD : AppColors.mint;
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
              color: mint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mint, size: 26),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mint = isDark ? AppColors.mintD : AppColors.mint;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: mint, size: 18),
              const SizedBox(width: 6),
              Text('Breed identified',
                  style: tt.labelMedium?.copyWith(
                      color: mint, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pct% confident',
                    style: tt.labelSmall?.copyWith(color: mint)),
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
                backgroundColor: mint,
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
