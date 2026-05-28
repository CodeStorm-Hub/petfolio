import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/create_post_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateStoryScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _picker = ImagePicker();
  bool _isDownloadingMock = false;
  Uint8List? _previewBytes;

  // Fallback mock images used on emulators or when the device gallery is empty.
  static const _mockPetImages = [
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600&auto=format&fit=crop', // Golden Retriever
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&auto=format&fit=crop', // Cat close-up
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600&auto=format&fit=crop', // Dog with glasses
    'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600&auto=format&fit=crop', // Cat sleeping
    'https://images.unsplash.com/photo-1537151608828-ea2b117b6281?w=600&auto=format&fit=crop', // Puppy
    'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?w=600&auto=format&fit=crop', // Cat looking up
    'https://images.unsplash.com/photo-1477884213960-b13d27793fc8?w=600&auto=format&fit=crop', // Dog running
    'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600&auto=format&fit=crop', // Cat in sunglasses
    'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=600&auto=format&fit=crop', // Pug
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createPostControllerProvider.notifier).setIsStory(true);
    });
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _loadPreviewBytes(XFile file) async {
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _previewBytes = bytes);
  }

  Future<void> _pickFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (pickedFile != null && mounted) {
      ref.read(createPostControllerProvider.notifier).setImage(pickedFile);
      await _loadPreviewBytes(pickedFile);
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (pickedFile != null && mounted) {
      ref.read(createPostControllerProvider.notifier).setImage(pickedFile);
      await _loadPreviewBytes(pickedFile);
    }
  }

  Future<void> _selectMockImage(String url) async {
    setState(() => _isDownloadingMock = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final xFile = XFile.fromData(
          response.bodyBytes,
          mimeType: 'image/jpeg',
          name: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        ref.read(createPostControllerProvider.notifier).setImage(xFile);
        if (mounted) setState(() => _previewBytes = response.bodyBytes);
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      AppSnackBar.showError('Could not load mock photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloadingMock = false);
      }
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;

    final notifier = ref.read(createPostControllerProvider.notifier);
    notifier.setCaption(''); // Stories don't have captions
    final success = await notifier.submit(pet.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Story shared!'),
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
    final state = ref.watch(createPostControllerProvider);
    final pet = ref.watch(activePetControllerProvider);

    if (state.image != null) {
      return _buildStoryPreview(state, pet);
    } else {
      return _buildMediaSelector();
    }
  }

  // ── State 1: Media Selector View ───────────────────────────────────────────

  Widget _buildMediaSelector() {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: pt.surface1,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurface, size: 22),
              onPressed: () => context.pop(),
              tooltip: 'Close',
            ),
            title: const Text(
              'Add to Story',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: CustomScrollView(
            slivers: [
              // Viewfinder camera button
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CameraViewfinderCard(onTap: _pickFromCamera),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Recent Gallery Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    'Recent Photos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: pt.ink500,
                    ),
                  ),
                ),
              ),

              // Gallery grid list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _BrowseLibraryTile(onTap: _pickFromGallery);
                      }
                      final url = _mockPetImages[index - 1];
                      return _MockImageTile(
                        url: url,
                        onTap: () => _selectMockImage(url),
                      );
                    },
                    childCount: _mockPetImages.length + 1,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),

        // Download Loader Overlay
        if (_isDownloadingMock)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.tangerine,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading photo…',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── State 2: Fullscreen 9:16 Preview View ──────────────────────────────────

  Widget _buildStoryPreview(CreatePostState state, Pet? pet) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Preview Image
          Positioned.fill(
            child: _previewBytes != null
                ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                : const Center(child: CircularProgressIndicator()),
          ),

          // 2. Gradients overlay for visual text readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(160),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Pet Badge (Top-Left)
          if (pet != null)
            Positioned(
              top: 54,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withAlpha(50),
                    backgroundImage: pet.avatarUrl != null
                        ? CachedNetworkImageProvider(pet.avatarUrl!)
                        : null,
                    child: pet.avatarUrl == null
                        ? Text(
                            pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(blurRadius: 3.0, color: Colors.black45, offset: Offset(1.0, 1.0)),
                          ],
                        ),
                      ),
                      const Text(
                        'Your story preview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          shadows: [
                            Shadow(blurRadius: 2.0, color: Colors.black45, offset: Offset(1.0, 1.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 4. Discard button (Top-Right)
          Positioned(
            top: 48,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(100),
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  ref.read(createPostControllerProvider.notifier).removeImage();
                  setState(() => _previewBytes = null);
                },
              ),
            ),
          ),

          // 5. Bottom Share controller
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [AppColors.tangerine, AppColors.poppy],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tangerine.withAlpha(100),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Share to Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Stories expire automatically after 24 hours',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 6. Full-screen upload overlay
          if (state.isSubmitting)
            _UploadOverlay(step: state.step, cs: Theme.of(context).colorScheme),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BrowseLibraryTile
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseLibraryTile extends StatelessWidget {
  const _BrowseLibraryTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
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
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.tangerine,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: pt.ink500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MockImageTile
// ─────────────────────────────────────────────────────────────────────────────

class _MockImageTile extends StatelessWidget {
  const _MockImageTile({required this.url, required this.onTap});
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          placeholder: (context, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error_outline_rounded, size: 16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CameraViewfinderCard
// ─────────────────────────────────────────────────────────────────────────────

class _CameraViewfinderCard extends StatefulWidget {
  const _CameraViewfinderCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CameraViewfinderCard> createState() => _CameraViewfinderCardState();
}

class _CameraViewfinderCardState extends State<_CameraViewfinderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isRedDotVisible = true;
  Timer? _redDotTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _redDotTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() => _isRedDotVisible = !_isRedDotVisible);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _redDotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black87,
                Colors.black,
              ],
            ),
            boxShadow: pt.shadowE2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Grid lines
                CustomPaint(
                  painter: _CameraGridPainter(color: Colors.white.withAlpha(30)),
                ),

                // 2. Viewfinder corners
                CustomPaint(
                  painter: _CameraViewfinderBracketsPainter(color: Colors.white.withAlpha(160)),
                ),

                // 3. REC blinking light
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRedDotVisible ? Colors.red : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Info badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    'RAW · 4:3 · HDR',
                    style: TextStyle(
                      color: Colors.white.withAlpha(140),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 5. Central capture trigger
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(30),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Autofocus box indicator
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.center_focus_weak_rounded, color: AppColors.tangerine, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'AF-S Auto',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewfinder Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

class _CameraGridPainter extends CustomPainter {
  const _CameraGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);

    // Draw vertical lines
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const length = 20.0;
    const padding = 16.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + length)
        ..lineTo(padding, padding)
        ..lineTo(padding + length, padding),
      paint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + length),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - length)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + length, size.height - padding),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final label = step == PostStep.uploading ? 'Uploading photo…' : 'Sharing story…';
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
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, 8),
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
                color: AppColors.tangerine,
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


