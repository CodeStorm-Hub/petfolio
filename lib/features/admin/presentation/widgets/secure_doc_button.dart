import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/kyc_review_controller.dart';

class SecureDocButton extends ConsumerStatefulWidget {
  const SecureDocButton({
    super.key,
    required this.label,
    required this.documentPath,
  });

  final String label;
  final String documentPath;

  @override
  ConsumerState<SecureDocButton> createState() => _SecureDocButtonState();
}

class _SecureDocButtonState extends ConsumerState<SecureDocButton> {
  bool _loading = false;

  Future<void> _open() async {
    setState(() => _loading = true);
    try {
      final url = await ref
          .read(kycReviewProvider.notifier)
          .getDocumentUrl(widget.documentPath);
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) _showError('Could not open document.');
      }
    } catch (e) {
      if (mounted) _showError('Failed to load document: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _open,
      icon: _loading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : const Icon(Icons.open_in_new_rounded, size: 14),
      label: Text(widget.label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: AppColors.line200),
        foregroundColor: AppColors.blue500,
      ),
    );
  }
}
