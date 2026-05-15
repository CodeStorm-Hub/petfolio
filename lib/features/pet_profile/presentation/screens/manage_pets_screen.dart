import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../data/models/pet.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ManagePetsScreen — opened from the pet-switcher "Manage" link.
//
// Three things live here, intentionally consolidated so the switcher sheet can
// stay focused on _switching_:
//   1. Reorder (drag handle, persists display_order to Supabase)
//   2. Share access — opens a future-state sheet; we render real UI but do not
//      hit the backend yet (no invitations table). This communicates intent
//      without faking success.
//   3. Archive — soft delete (sets archived_at), supports Undo from a snackbar.
//
// We chose Reorderable + per-row menu over a multi-select bar because users
// in this app typically own 1-4 pets; bulk operations are not worth the
// cognitive overhead.
// ─────────────────────────────────────────────────────────────────────────────

class ManagePetsScreen extends ConsumerStatefulWidget {
  const ManagePetsScreen({super.key});

  @override
  ConsumerState<ManagePetsScreen> createState() => _ManagePetsScreenState();
}

class _ManagePetsScreenState extends ConsumerState<ManagePetsScreen> {
  bool _reordering = false;

  Future<void> _onReorder(List<Pet> pets, int oldIndex, int newIndex) async {
    if (_reordering) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final next = [...pets];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);

    setState(() => _reordering = true);
    try {
      await ref.read(petListProvider.notifier).reorder(next);
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _onArchive(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${pet.name}?'),
        content: Text(
          "${pet.name} will be hidden from the switcher and care lists. "
          'Your care history, photos, and records stay in the archive — '
          'you can restore them anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(petListProvider.notifier).archive(pet.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${pet.name} archived.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await ref.read(petListProvider.notifier).unarchive(pet.id);
              } catch (e) {
                if (mounted) AppSnackBar.showError(e);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    }
  }

  void _openShareSheet(Pet pet) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareAccessSheet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    final activePet = ref.watch(activePetControllerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ManageHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: petsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => _ErrorState(
                  message: 'Could not load pets',
                  onRetry: () => ref.invalidate(petListProvider),
                ),
                data: (pets) => pets.isEmpty
                    ? _EmptyState(
                        onAddPet: () => context.push('/onboarding?mode=add'),
                      )
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          final body = _PetList(
                            pets: pets,
                            activeId: activePet?.id,
                            isReordering: _reordering,
                            onReorder: (oldIdx, newIdx) =>
                                _onReorder(pets, oldIdx, newIdx),
                            onArchive: _onArchive,
                            onShare: _openShareSheet,
                            onAddPet: () =>
                                context.push('/onboarding?mode=add'),
                          );
                          final maxW =
                              constraints.maxWidth >= 600 ? 560.0 : double.infinity;
                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxW),
                              child: body,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ManageHeader extends StatelessWidget {
  const _ManageHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pt.line200, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          children: [
            GestureDetector(
              key: const ValueKey<String>('manage_pets_back'),
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    const BoxShadow(
                      color: AppColors.shadowE1L,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: pt.line200.withAlpha(128),
                      blurRadius: 0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 24,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MANAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 11,
                      color: pt.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your pets',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pet list
// ─────────────────────────────────────────────────────────────────────────────

class _PetList extends StatelessWidget {
  const _PetList({
    required this.pets,
    required this.activeId,
    required this.isReordering,
    required this.onReorder,
    required this.onArchive,
    required this.onShare,
    required this.onAddPet,
  });

  final List<Pet> pets;
  final String? activeId;
  final bool isReordering;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Pet pet) onArchive;
  final void Function(Pet pet) onShare;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(Icons.drag_indicator_rounded, size: 16, color: pt.ink300),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Long-press the handle to reorder · tap ⋯ to share or archive',
                    style: TextStyle(fontSize: 12, color: pt.ink500, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverReorderableList(
            itemCount: pets.length,
            onReorder: onReorder,
            proxyDecorator: (child, _, animation) => Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, _) => Transform.scale(
                  scale: 1 + 0.03 * animation.value,
                  child: child,
                ),
              ),
            ),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _PetRow(
                key: ValueKey<String>('manage_pet_row_${pet.id}'),
                pet: pet,
                index: index,
                isActive: pet.id == activeId,
                onArchive: () => onArchive(pet),
                onShare: () => onShare(pet),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _AddPetCallout(onTap: onAddPet),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pet row
// ─────────────────────────────────────────────────────────────────────────────

class _PetRow extends StatelessWidget {
  const _PetRow({
    super.key,
    required this.pet,
    required this.index,
    required this.isActive,
    required this.onArchive,
    required this.onShare,
  });

  final Pet pet;
  final int index;
  final bool isActive;
  final VoidCallback onArchive;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = pet.speciesEnum;

    final subtitleParts = <String>[
      species.label,
      if (pet.breed != null && !pet.breed!.startsWith("Don't")) pet.breed!,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? species.accent : pt.line200,
            width: isActive ? 1.5 : 0.5,
          ),
          boxShadow: [
            const BoxShadow(
              color: AppColors.shadowE1L,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 22,
                  color: pt.ink300,
                ),
              ),
            ),
            PetAvatar(
              imageUrl: pet.avatarUrl,
              size: PetAvatarSize.lg,
              initials: pet.name.isNotEmpty ? pet.name[0] : null,
              borderColor: isActive ? species.accent : null,
              semanticLabel: pet.name,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.15,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: species.tint,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: species.accent.withAlpha(85), width: 0.5),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.08 * 10,
                              color: species.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              key: ValueKey<String>('manage_pet_menu_${pet.id}'),
              tooltip: '${pet.name} options',
              icon: Icon(Icons.more_vert_rounded, color: pt.ink500),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    onShare();
                  case 'archive':
                    onArchive();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.person_add_alt_1_rounded),
                    title: Text('Share access'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive_outlined),
                    title: Text('Archive pet'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-pet callout
// ─────────────────────────────────────────────────────────────────────────────

class _AddPetCallout extends StatelessWidget {
  const _AddPetCallout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      key: const ValueKey<String>('manage_pets_add_button'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blue400.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add another pet',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Name, breed, photo — 30 seconds',
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share access — opt-in future UI. No backend yet, so we communicate the
// timeline honestly rather than fake a success state.
// ─────────────────────────────────────────────────────────────────────────────

class _ShareAccessSheet extends StatelessWidget {
  const _ShareAccessSheet({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = pet.speciesEnum;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: pt.ink300.withAlpha(80),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                PetAvatar(
                  imageUrl: pet.avatarUrl,
                  size: PetAvatarSize.md,
                  initials: pet.name.isNotEmpty ? pet.name[0] : null,
                  borderColor: species.accent,
                  semanticLabel: pet.name,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Share ${pet.name}',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Invite a partner or sitter as a co-carer',
                        style: TextStyle(fontSize: 13, color: pt.ink500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'partner@example.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue400.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 18, color: AppColors.blue600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Co-carer invites are coming soon. We'll surface this "
                      'once the backend invitation flow ships — no fake '
                      'placeholders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPet});
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No pets to manage yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first pet to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: pt.ink500),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey<String>('manage_pets_empty_add'),
              onPressed: onAddPet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add a pet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 15, color: pt.ink500)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
