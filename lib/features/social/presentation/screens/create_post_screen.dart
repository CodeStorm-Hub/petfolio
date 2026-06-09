import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/platform/media_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/social_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreatePostScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  Uint8List? _previewBytes;
  static const _maxChars = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createPostControllerProvider.notifier).setIsStory(false);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    final XFile? pickedFile = await pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (pickedFile != null && mounted) {
      ref.read(createPostControllerProvider.notifier).setImage(pickedFile);
      final bytes = await pickedFile.readAsBytes();
      if (mounted) setState(() => _previewBytes = bytes);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;

    final notifier = ref.read(createPostControllerProvider.notifier);
    notifier.setCaption(_captionController.text);
    final success = await notifier.submit(pet.id);

    if (success && mounted) {
      ref.read(socialControllerProvider(pet.id).notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Post shared!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(createPostControllerProvider);
    final pet    = ref.watch(activePetControllerProvider);
    final pt     = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs     = Theme.of(context).colorScheme;
    final chars  = _captionController.text.length;
    final canPost = !state.isSubmitting &&
        (state.image != null || _captionController.text.trim().isNotEmpty);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: pt.surface1,
          appBar: _buildAppBar(context, pt, cs, state, canPost),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Error banner ───────────────────────────────────────
                    if (state.error != null) _ErrorBanner(message: state.error!),

                    const SizedBox(height: 12),

                    // ── Posting-as pet row ─────────────────────────────────
                    if (pet != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PetIdentityRow(
                          avatarUrl: pet.avatarUrl,
                          petName: pet.name,
                          species: pet.species,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Image well ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ImageWell(
                        image: state.image,
                        previewBytes: _previewBytes,
                        isSubmitting: state.isSubmitting,
                        onTap: _showImageSourceSheet,
                        onRemove: () {
                          setState(() => _previewBytes = null);
                          ref
                              .read(createPostControllerProvider.notifier)
                              .removeImage();
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Caption card ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CaptionCard(
                        controller: _captionController,
                        enabled: !state.isSubmitting,
                        maxChars: _maxChars,
                        charCount: chars,
                        pt: pt,
                        cs: cs,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Visibility row ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _VisibilityInfo(pt: pt),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Full-screen upload overlay ─────────────────────────────────────
        if (state.isSubmitting)
          _UploadOverlay(step: state.step, cs: cs),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    PetfolioThemeExtension pt,
    ColorScheme cs,
    CreatePostState state,
    bool canPost,
  ) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: pt.line,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: cs.onSurface, size: 22),
        onPressed: state.isSubmitting ? null : () => context.pop(),
        tooltip: 'Discard',
      ),
      title: Text(
        'New Post',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: canPost ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunset500,
              disabledBackgroundColor: pt.line,
              foregroundColor: Colors.white,
              disabledForegroundColor: pt.ink300,
              minimumSize: const Size(72, 36),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            child: const Text('Share'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PetIdentityRow
// ─────────────────────────────────────────────────────────────────────────────

class _PetIdentityRow extends StatelessWidget {
  const _PetIdentityRow({
    required this.avatarUrl,
    required this.petName,
    required this.species,
  });

  final String? avatarUrl;
  final String petName;
  final String species;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Row(
        children: [
          PetAvatar(
            imageUrl: avatarUrl,
            size: PetAvatarSize.md,
            initials: petName.isNotEmpty ? petName[0].toUpperCase() : '?',
            semanticLabel: petName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Posting as this pet',
                  style: TextStyle(
                    fontSize: 12,
                    color: pt.ink300,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sunset500.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded, size: 12, color: AppColors.sunset500),
                const SizedBox(width: 4),
                Text(
                  'Public',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sunset500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ImageWell
// ─────────────────────────────────────────────────────────────────────────────

class _ImageWell extends StatelessWidget {
  const _ImageWell({
    required this.image,
    required this.previewBytes,
    required this.isSubmitting,
    required this.onTap,
    required this.onRemove,
  });

  final XFile? image;
  final Uint8List? previewBytes;
  final bool isSubmitting;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background / image ──────────────────────────────────────────
          GestureDetector(
            onTap: isSubmitting ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: image != null ? Colors.transparent : pt.line,
                  width: 1.5,
                ),
                image: image != null && previewBytes != null
                    ? DecorationImage(
                        image: MemoryImage(previewBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: image == null ? _EmptyImagePlaceholder(pt: pt) : null,
            ),
          ),

          // ── Remove / change overlay when image selected ─────────────────
          if (image != null && !isSubmitting) ...[
            // Dark gradient at top for the remove button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black45, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Remove button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 17),
                ),
              ),
            ),
            // "Change photo" chip at bottom
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text(
                          'Change photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyImagePlaceholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyImagePlaceholder extends StatelessWidget {
  const _EmptyImagePlaceholder({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.sunset500.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 34,
                      color: AppColors.sunset500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Add a photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: pt.ink500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JPG, PNG, WebP or GIF · Max 10 MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: pt.ink300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Gallery / Camera action row
          Container(
            decoration: BoxDecoration(
              color: pt.surface2,
              border: Border(top: BorderSide(color: pt.line)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _SourceChip(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  color: AppColors.blue500,
                ),
                const SizedBox(width: 10),
                _SourceChip(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  color: AppColors.meadow500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CaptionCard
// ─────────────────────────────────────────────────────────────────────────────

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.controller,
    required this.enabled,
    required this.maxChars,
    required this.charCount,
    required this.pt,
    required this.cs,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final int maxChars;
  final int charCount;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final nearLimit = charCount > (maxChars * 0.85).floor();
    final atLimit   = charCount >= maxChars;
    final counterColor = atLimit
        ? cs.error
        : nearLimit
            ? AppColors.warning
            : pt.ink300;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 6,
              minLines: 3,
              maxLength: maxChars,
              onChanged: onChanged,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "What's your pet up to? 🐾",
                hintStyle: TextStyle(
                  color: pt.ink300,
                  fontSize: 15,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 15, color: pt.ink300),
                const SizedBox(width: 4),
                Text(
                  'Add hashtags to reach more pet lovers',
                  style: TextStyle(
                    fontSize: 12,
                    color: pt.ink300,
                  ),
                ),
                const Spacer(),
                Text(
                  '$charCount/$maxChars',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: counterColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VisibilityInfo
// ─────────────────────────────────────────────────────────────────────────────

class _VisibilityInfo extends StatelessWidget {
  const _VisibilityInfo({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.sunset500.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.public_rounded, size: 18, color: AppColors.sunset500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public post',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Visible to all PetFolio members',
                  style: TextStyle(
                    fontSize: 12,
                    color: pt.ink300,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ImageSourceSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: pt.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add Photo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              color: AppColors.blue500,
              title: 'Photo Library',
              subtitle: 'Choose from your gallery',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              color: AppColors.meadow500,
              title: 'Take Photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: pt.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: pt.ink500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: pt.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: pt.ink300,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UploadOverlay
// ─────────────────────────────────────────────────────────────────────────────

class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay({required this.step, required this.cs});
  final PostStep step;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final label = step == PostStep.uploading ? 'Uploading photo…' : 'Sharing post…';
    final sub   = step == PostStep.uploading
        ? 'Please wait while we upload your image'
        : 'Almost there, hang tight!';

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.sunset500,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.coral500.withAlpha(20),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral500, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.coral500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
