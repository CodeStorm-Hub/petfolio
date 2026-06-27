import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/platform/media_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/social_controller.dart';
import '../controllers/story_controller.dart';

enum ContentMode { post, story }

class CreateContentScreen extends ConsumerStatefulWidget {
  const CreateContentScreen({super.key, this.initialMode = ContentMode.post});

  final ContentMode initialMode;

  @override
  ConsumerState<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends ConsumerState<CreateContentScreen>
    with TickerProviderStateMixin {
  late ContentMode _mode;
  final _captionController = TextEditingController();
  Uint8List? _previewBytes;

  late final AnimationController _pulseController;
  bool _isRedDotVisible = true;
  Timer? _redDotTimer;
  static const _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _redDotTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _isRedDotVisible = !_isRedDotVisible);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createPostControllerProvider.notifier).setIsStory(_mode == ContentMode.story);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pulseController.dispose();
    _redDotTimer?.cancel();
    super.dispose();
  }

  void _setMode(ContentMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _previewBytes = null;
    });
    ref.read(createPostControllerProvider.notifier)
      ..removeImage()
      ..setIsStory(mode == ContentMode.story);
  }

  Future<void> _pickFromGallery() async {
    final file = await pickGalleryImage(maxWidth: 1920, imageQuality: 85);
    if (file != null && mounted) {
      ref.read(createPostControllerProvider.notifier).setImage(file);
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _previewBytes = bytes);
    }
  }

  Future<void> _pickFromCamera() async {
    final file = await pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
    if (file != null && mounted) {
      ref.read(createPostControllerProvider.notifier).setImage(file);
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _previewBytes = bytes);
    }
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null || !mounted) return;
    if (source == ImageSource.gallery) {
      await _pickFromGallery();
    } else {
      await _pickFromCamera();
    }
  }

  void _submit() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;

    final notifier = ref.read(createPostControllerProvider.notifier);
    if (_mode == ContentMode.post) {
      notifier.setCaption(_captionController.text);
    } else {
      notifier.setCaption('');
    }

    final success = await notifier.submit(pet.id);
    if (success && mounted) {
      if (_mode == ContentMode.post) {
        ref.read(socialControllerProvider(pet.id).notifier).refresh();
      } else {
        ref.invalidate(storiesProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(_mode == ContentMode.post ? 'Post shared!' : 'Story shared!'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostControllerProvider);
    final pet = ref.watch(activePetControllerProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    if (_mode == ContentMode.story && state.image != null) {
      return _buildStoryPreview(state, pet, cs, pt);
    }

    final chars = _captionController.text.length;
    final canSubmit = !state.isSubmitting &&
        (state.image != null ||
            (_mode == ContentMode.post && _captionController.text.trim().isNotEmpty));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: pt.surface1,
          appBar: _buildAppBar(context, pt, cs, state, canSubmit),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.error != null) _ErrorBanner(message: state.error!),
                    const SizedBox(height: 12),

                    if (pet != null && _mode == ContentMode.post)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PetIdentityRow(
                          avatarUrl: pet.avatarUrl,
                          petName: pet.name,
                          species: pet.species,
                        ),
                      ),

                    const SizedBox(height: 16),

                    if (_mode == ContentMode.post) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ImageWell(
                          image: state.image,
                          previewBytes: _previewBytes,
                          isSubmitting: state.isSubmitting,
                          onTap: _showImageSourceSheet,
                          onRemove: () {
                            setState(() => _previewBytes = null);
                            ref.read(createPostControllerProvider.notifier).removeImage();
                          },
                          aspectRatio: 4 / 5,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _VisibilityInfo(pt: pt),
                      ),
                    ] else ...[
                      _CameraViewfinderCard(
                        onTap: _pickFromCamera,
                        pulseController: _pulseController,
                        isRedDotVisible: _isRedDotVisible,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Text(
                          'Photos',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: pt.ink500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _BrowseLibraryTile(onTap: _pickFromGallery),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.isSubmitting) _UploadOverlay(step: state.step, cs: cs, isStory: _mode == ContentMode.story),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    PetfolioThemeExtension pt,
    ColorScheme cs,
    CreatePostState state,
    bool canSubmit,
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
      title: SegmentedButton<ContentMode>(
        segments: const [
          ButtonSegment(value: ContentMode.post, label: Text('Post')),
          ButtonSegment(value: ContentMode.story, label: Text('Story')),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => _setMode(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: pt.pillarSocial.withAlpha(30),
          selectedForegroundColor: pt.pillarSocial,
          side: BorderSide(color: pt.line),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunset500,
              disabledBackgroundColor: pt.line,
              foregroundColor: Colors.white,
              disabledForegroundColor: pt.ink300,
              minimumSize: const Size(72, 36),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            child: Text(_mode == ContentMode.post ? 'Share' : 'Add'),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryPreview(CreatePostState state, Pet? pet, ColorScheme cs, PetfolioThemeExtension pt) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _previewBytes != null
                ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                : const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(160), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(180), Colors.transparent],
                ),
              ),
            ),
          ),
          if (pet != null)
            Positioned(
              top: 54, left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withAlpha(50),
                    backgroundImage: pet.avatarUrl != null ? CachedNetworkImageProvider(pet.avatarUrl!) : null,
                    child: pet.avatarUrl == null
                        ? Text(pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                          shadows: [Shadow(blurRadius: 3, color: Colors.black45, offset: Offset(1, 1))])),
                      const Text('Your story preview', style: TextStyle(color: Colors.white70, fontSize: 11,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black45, offset: Offset(1, 1))])),
                    ],
                  ),
                ],
              ),
            ),
          Positioned(
            top: 48, right: 16,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(100)),
              child: IconButton(
                tooltip: 'Remove image',
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  ref.read(createPostControllerProvider.notifier).removeImage();
                  setState(() => _previewBytes = null);
                },
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(colors: [AppColors.sunset500, AppColors.coral500]),
                    boxShadow: [BoxShadow(color: AppColors.sunset500.withAlpha(100), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Share to Story', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Stories expire automatically after 24 hours',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          if (state.isSubmitting) _UploadOverlay(step: state.step, cs: cs, isStory: true),
        ],
      ),
    );
  }
}

// ─── Shared: Pet identity row ─────────────────────────────────────────────────

class _PetIdentityRow extends StatelessWidget {
  const _PetIdentityRow({required this.avatarUrl, required this.petName, required this.species});

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
                Text(petName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                const SizedBox(height: 1),
                Text('Posting as this pet', style: TextStyle(fontSize: 12, color: pt.ink300)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sunset500.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded, size: 12, color: AppColors.sunset500),
                SizedBox(width: 4),
                Text('Public', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sunset500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post mode: image well ────────────────────────────────────────────────────

class _ImageWell extends StatelessWidget {
  const _ImageWell({
    required this.image, required this.previewBytes, required this.isSubmitting,
    required this.onTap, required this.onRemove, this.aspectRatio = 4 / 5,
  });

  final XFile? image;
  final Uint8List? previewBytes;
  final bool isSubmitting;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: image != null ? 'Change photo' : 'Add photo',
            button: true,
            child: GestureDetector(
            onTap: isSubmitting ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: image != null ? Colors.transparent : pt.line, width: 1.5),
                image: image != null && previewBytes != null
                    ? DecorationImage(image: MemoryImage(previewBytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: image == null ? _EmptyImagePlaceholder(pt: pt) : null,
            ),
          ),
          ),
          if (image != null && !isSubmitting) ...[
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black45, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: Semantics(
                label: 'Remove photo',
                button: true,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Center(
                child: Semantics(
                  label: 'Change photo',
                  button: true,
                  child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text('Change photo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
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
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppColors.sunset500.withAlpha(20), shape: BoxShape.circle),
                    child: const Icon(Icons.add_photo_alternate_rounded, size: 34, color: AppColors.sunset500),
                  ),
                  const SizedBox(height: 14),
                  Text('Add a photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: pt.ink500)),
                  const SizedBox(height: 6),
                  Text('JPG, PNG, WebP or GIF · Max 10 MB', style: TextStyle(fontSize: 12, color: pt.ink300)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: pt.surface2, border: Border(top: BorderSide(color: pt.line))),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                _SourceChip(icon: Icons.photo_library_outlined, label: 'Gallery', color: AppColors.blue500),
                SizedBox(width: 10),
                _SourceChip(icon: Icons.camera_alt_outlined, label: 'Camera', color: AppColors.meadow500),
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
        decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Post mode: caption card ──────────────────────────────────────────────────

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.controller, required this.enabled, required this.maxChars,
    required this.charCount, required this.pt, required this.cs, required this.onChanged,
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
    final atLimit = charCount >= maxChars;
    final counterColor = atLimit ? cs.error : nearLimit ? AppColors.warning : pt.ink300;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pt.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Semantics(
              label: 'Caption',
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
                  hintStyle: TextStyle(color: pt.ink300, fontSize: 15),
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 15, height: 1.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 15, color: pt.ink300),
                const SizedBox(width: 4),
                Text('Add hashtags to reach more pet lovers', style: TextStyle(fontSize: 12, color: pt.ink300)),
                const Spacer(),
                Text('$charCount/$maxChars',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: counterColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post mode: visibility info ───────────────────────────────────────────────

class _VisibilityInfo extends StatelessWidget {
  const _VisibilityInfo({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pt.line)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.sunset500.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.public_rounded, size: 18, color: AppColors.sunset500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Public post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                Text('Visible to all PetFolio members', style: TextStyle(fontSize: 12, color: pt.ink300)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 20),
        ],
      ),
    );
  }
}

// ─── Story mode: camera viewfinder ───────────────────────────────────────────

class _CameraViewfinderCard extends StatelessWidget {
  const _CameraViewfinderCard({
    required this.onTap,
    required this.pulseController,
    required this.isRedDotVisible,
  });

  final VoidCallback onTap;
  final AnimationController pulseController;
  final bool isRedDotVisible;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Take photo with camera',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.black87, Colors.black],
              ),
              boxShadow: pt.shadowE2,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(child: CustomPaint(painter: _CameraGridPainter(color: Colors.white.withAlpha(30)))),
                  ExcludeSemantics(child: CustomPaint(painter: _CameraViewfinderBracketsPainter(color: Colors.white.withAlpha(160)))),
                  Positioned(
                    top: 16, left: 16,
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRedDotVisible ? Colors.red : Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('REC', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16, right: 16,
                    child: ExcludeSemantics(
                      child: Text('RAW · 4:3 · HDR', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(30), border: Border.all(color: Colors.white, width: 3)),
                        alignment: Alignment.center,
                        child: Container(
                          width: 60, height: 60,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          alignment: Alignment.center,
                          child: Icon(Icons.camera_alt_rounded, color: cs.primary, size: 28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24, left: 24,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withAlpha(120), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.center_focus_weak_rounded, color: AppColors.sunset500, size: 14),
                            const SizedBox(width: 4),
                            Text('AF-S Auto', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  const _CameraGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraViewfinderBracketsPainter extends CustomPainter {
  const _CameraViewfinderBracketsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
    const length = 20.0;
    const padding = 16.0;
    canvas.drawPath(Path()..moveTo(padding, padding + length)..lineTo(padding, padding)..lineTo(padding + length, padding), paint);
    canvas.drawPath(Path()..moveTo(size.width - padding - length, padding)..lineTo(size.width - padding, padding)..lineTo(size.width - padding, padding + length), paint);
    canvas.drawPath(Path()..moveTo(padding, size.height - padding - length)..lineTo(padding, size.height - padding)..lineTo(padding + length, size.height - padding), paint);
    canvas.drawPath(Path()..moveTo(size.width - padding - length, size.height - padding)..lineTo(size.width - padding, size.height - padding)..lineTo(size.width - padding, size.height - padding - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Story mode: gallery tiles ────────────────────────────────────────────────

class _BrowseLibraryTile extends StatelessWidget {
  const _BrowseLibraryTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Browse photo library',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pt.line, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.sunset500, size: 18),
              ),
              const SizedBox(height: 8),
              Text('Browse', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: pt.ink500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared: image source sheet ───────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: pt.line, borderRadius: BorderRadius.circular(2))),
            Text('Add Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.photo_library_rounded, color: AppColors.blue500,
              title: 'Photo Library', subtitle: 'Choose from your gallery',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.camera_alt_rounded, color: AppColors.meadow500,
              title: 'Take Photo', subtitle: 'Use your camera',
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
                child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: pt.ink500)),
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
  const _SheetOption({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: title,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: pt.surface2, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: pt.ink300)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared: upload overlay ───────────────────────────────────────────────────

class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay({required this.step, required this.cs, required this.isStory});
  final PostStep step;
  final ColorScheme cs;
  final bool isStory;

  @override
  Widget build(BuildContext context) {
    final label = step == PostStep.uploading ? 'Uploading photo…' : (isStory ? 'Sharing story…' : 'Sharing post…');
    final sub = step == PostStep.uploading ? 'Please wait while we upload your image' : 'Almost there, hang tight!';

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 48, height: 48,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.sunset500)),
            const SizedBox(height: 20),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(140))),
          ],
        ),
      ),
    );
  }
}

// ─── Shared: error banner ─────────────────────────────────────────────────────

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
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.coral500, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
