import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/communities_controller.dart';

Future<void> showCreateCommunitySheet(BuildContext context, WidgetRef ref) {
  final petId = ref.read(activePetIdProvider);
  if (petId == null) {
    AppSnackBar.showError('Select an active pet before creating a community');
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: const _CreateCommunitySheet(),
    ),
  );
}

class _CreateCommunitySheet extends ConsumerStatefulWidget {
  const _CreateCommunitySheet();

  @override
  ConsumerState<_CreateCommunitySheet> createState() =>
      _CreateCommunitySheetState();
}

class _CreateCommunitySheetState extends ConsumerState<_CreateCommunitySheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final community =
          await ref.read(communitiesControllerProvider.notifier).createCommunity(
                name: name,
                description: _descCtrl.text.trim(),
              );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (community != null) {
        context.push(
          '/social/communities/${community.id}',
          extra: community,
        );
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pt.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create community',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a group for pet parents with similar interests.',
            style: TextStyle(fontSize: 14, color: pt.ink500, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Community name',
              hintText: 'e.g. Bengal Cat Lovers',
              counterText: '',
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: pt.line),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What is this group about?',
              alignLabelWithHint: true,
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: pt.line),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryPillButton(
            label: 'Create community',
            isLoading: _saving,
            isFullWidth: true,
            leadingIcon: const Icon(Icons.groups_rounded, color: Colors.white),
            onPressed: _nameCtrl.text.trim().isEmpty || _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
