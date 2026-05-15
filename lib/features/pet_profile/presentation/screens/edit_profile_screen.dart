import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/pet.dart';
import '../controllers/edit_profile_controller.dart';

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
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed ?? '');
    _bioController = TextEditingController(text: widget.pet.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(editProfileControllerProvider.notifier).setImage(File(picked.path));
    }
  }

  Future<void> _save() async {
    final success = await ref.read(editProfileControllerProvider.notifier).submit(
          originalPet: widget.pet,
          name: _nameController.text,
          breed: _breedController.text,
          bio: _bioController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Profile updated successfully!',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (state.isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: cs.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar edit
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pt.surface2,
                          border: Border.all(color: pt.line200, width: 2),
                          image: state.newImage != null
                              ? DecorationImage(
                                  image: FileImage(state.newImage!),
                                  fit: BoxFit.cover,
                                )
                              : widget.pet.avatarUrl != null && widget.pet.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(widget.pet.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: state.newImage == null &&
                                (widget.pet.avatarUrl == null || widget.pet.avatarUrl!.isEmpty)
                            ? Center(
                                child: Text(
                                  widget.pet.name.isNotEmpty ? widget.pet.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    color: pt.ink500,
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
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              if (state.errorMessage != null) ...[
                Container(
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
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: pt.warning, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: pt.ink500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => ref.read(editProfileControllerProvider.notifier).clearError(),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Pet Name',
                      hintStyle: TextStyle(color: pt.ink300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Breed Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Breed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: pt.ink500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _breedController,
                    onChanged: (_) => ref.read(editProfileControllerProvider.notifier).clearError(),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. Golden Retriever',
                      hintStyle: TextStyle(color: pt.ink300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bio Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bio',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: pt.ink500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    onChanged: (_) => ref.read(editProfileControllerProvider.notifier).clearError(),
                    maxLines: 3,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'A little bit about your pet...',
                      hintStyle: TextStyle(color: pt.ink300),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
