import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/prescription.dart';
import '../controllers/prescription_controller.dart';
import '../widgets/marketplace_back_button.dart';

class PrescriptionUploadScreen extends ConsumerStatefulWidget {
  const PrescriptionUploadScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState
    extends ConsumerState<PrescriptionUploadScreen> {
  File? _pickedFile;
  final _vetController = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _vetController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.camera);
                if (sheetCtx.mounted) Navigator.pop(sheetCtx, f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.gallery);
                if (sheetCtx.mounted) Navigator.pop(sheetCtx, f);
              },
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final file = File(result.path);
      final sizeBytes = await file.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        if (mounted) AppSnackBar.show('File too large. Maximum size is 10 MB.');
        return;
      }
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    setState(() => _uploading = true);
    await ref
        .read(prescriptionUploadProvider(widget.orderId).notifier)
        .upload(_pickedFile!, vetName: _vetController.text.trim());
    if (!mounted) return;
    setState(() => _uploading = false);
    final state = ref.read(prescriptionUploadProvider(widget.orderId));
    if (state.hasError) {
      AppSnackBar.show('Upload failed. Please try again.');
    } else {
      AppSnackBar.show('Prescription submitted for review.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final rxAsync = ref.watch(prescriptionUploadProvider(widget.orderId));
    final existing = rxAsync.asData?.value;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const MarketplaceBackButton(),
                    const SizedBox(width: 4),
                    Text(
                      'Upload Prescription',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (existing != null) ...[
                      _StatusBanner(status: existing.status),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.info),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please upload a clear photo or scan of your veterinarian\'s prescription.',
                              style: TextStyle(
                                  fontSize: 13, color: pt.ink700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: _pickedFile != null ? 'Change prescription image' : 'Upload prescription image',
                      button: true,
                      child: GestureDetector(
                      onTap: _pick,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _pickedFile != null
                                ? AppColors.mint
                                : pt.line,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          color: cs.surface,
                        ),
                        child: _pickedFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_pickedFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file_outlined,
                                      size: 40, color: pt.ink300),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap to upload prescription',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: pt.ink500,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'JPG, PNG or PDF',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: pt.ink500.withAlpha(150)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _vetController,
                      decoration: InputDecoration(
                        labelText: 'Veterinarian name (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryPillButton(
                      label: existing != null
                          ? 'Resubmit Prescription'
                          : 'Submit Prescription',
                      size: PillButtonSize.lg,
                      isFullWidth: true,
                      isLoading: _uploading,
                      onPressed: _pickedFile == null ? null : _upload,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final PrescriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      PrescriptionStatus.pending  => (AppColors.warning, Icons.hourglass_empty_rounded),
      PrescriptionStatus.approved => (AppColors.success, Icons.check_circle_outline_rounded),
      PrescriptionStatus.rejected => (AppColors.danger, Icons.cancel_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
