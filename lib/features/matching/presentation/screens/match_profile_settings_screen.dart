import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/media_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/pet_health_cert.dart';
import '../../data/models/verification.dart';
import '../controllers/breeding_setup_controller.dart';
import '../controllers/verification_controller.dart';

class MatchProfileSettingsScreen extends ConsumerStatefulWidget {
  const MatchProfileSettingsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MatchProfileSettingsScreen> createState() =>
      _MatchProfileSettingsScreenState();
}

class _MatchProfileSettingsScreenState
    extends ConsumerState<MatchProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final pet = ref.watch(activePetControllerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        title: const Text('Match Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: pt.line,
        bottom: TabBar(
          controller: _tabController,
          labelColor: pt.pillarMatch,
          unselectedLabelColor: pt.ink300,
          indicatorColor: pt.pillarMatch,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Breeding'),
            Tab(text: 'Verification'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (pet == null)
            const Center(
              child: PetfolioEmptyState(
                icon: Icons.pets_outlined,
                title: 'No active pet',
              ),
            )
          else
            _BreedingTab(
              petId: pet.id,
              onGoToVerification: () => _tabController.animateTo(1),
            ),
          const _VerificationTab(),
        ],
      ),
    );
  }
}

// ─── Breeding tab ─────────────────────────────────────────────────────────────

class _BreedingTab extends ConsumerStatefulWidget {
  const _BreedingTab({
    required this.petId,
    required this.onGoToVerification,
  });

  final String petId;
  final VoidCallback onGoToVerification;

  @override
  ConsumerState<_BreedingTab> createState() => _BreedingTabState();
}

class _BreedingTabState extends ConsumerState<_BreedingTab> {
  final _registryName = TextEditingController();
  final _registryId = TextEditingController();
  final _sire = TextEditingController();
  final _dam = TextEditingController();
  final _titles = TextEditingController();
  bool _isActive = true;
  bool _hydrated = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _registryName.dispose();
    _registryId.dispose();
    _sire.dispose();
    _dam.dispose();
    _titles.dispose();
    super.dispose();
  }

  void _hydrate(BreedingSetupState s) {
    if (_hydrated) return;
    _hydrated = true;
    _isActive = s.profile?.isActive ?? true;
    _registryName.text = s.pedigree?.registryName ?? '';
    _registryId.text = s.pedigree?.registryId ?? '';
    _sire.text = s.pedigree?.sireRef ?? '';
    _dam.text = s.pedigree?.damRef ?? '';
    _titles.text = s.pedigree?.titles ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ctrl = ref.read(
        breedingSetupControllerProvider(widget.petId).notifier);
    try {
      await ctrl.saveProfile(isActive: _isActive);
      await ctrl.savePedigree(
        sireRef: _sire.text.trim().isEmpty ? null : _sire.text.trim(),
        damRef: _dam.text.trim().isEmpty ? null : _dam.text.trim(),
        registryName: _registryName.text.trim().isEmpty
            ? null
            : _registryName.text.trim(),
        registryId: _registryId.text.trim().isEmpty
            ? null
            : _registryId.text.trim(),
        titles: _titles.text.trim().isEmpty ? null : _titles.text.trim(),
      );
      if (mounted) AppSnackBar.showSuccess('Breeding profile saved');
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadCert(HealthCertType type) async {
    final picked = await pickGalleryImage(maxWidth: 1400, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await ref
          .read(breedingSetupControllerProvider(widget.petId).notifier)
          .addCert(
            certType: type,
            bytes: bytes,
            ext: 'jpg',
            contentType: 'image/jpeg',
          );
      if (mounted) AppSnackBar.showSuccess('${type.label} uploaded');
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final async =
        ref.watch(breedingSetupControllerProvider(widget.petId));

    return async.when(
      loading: () => const Center(child: TailWagLoader()),
      error: (_, _) => const Center(
        child: PetfolioEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load breeding profile',
        ),
      ),
      data: (s) {
        _hydrate(s);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _StatusBanner(ready: s.isReady),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('List for breeding matches'),
              subtitle: const Text(
                'Others can discover you in breeding mode when this is on.',
              ),
            ),
            const SizedBox(height: 8),
            Text('Pedigree', style: tt.titleMedium),
            const SizedBox(height: 8),
            _Field(controller: _registryName, label: 'Registry name'),
            _Field(controller: _registryId, label: 'Registry ID'),
            _Field(controller: _sire, label: 'Sire (father) ref'),
            _Field(controller: _dam, label: 'Dam (mother) ref'),
            _Field(controller: _titles, label: 'Titles / awards'),
            const SizedBox(height: 16),
            Text('Health certificates', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'A verified, non-expired vaccination certificate is required to appear in breeding discovery.',
              style: tt.bodySmall?.copyWith(color: pt.ink500),
            ),
            const SizedBox(height: 12),
            if (s.certs.isEmpty)
              Text('No certificates uploaded yet.',
                  style: tt.bodySmall?.copyWith(color: pt.ink500)),
            for (final cert in s.certs)
              _CertTile(
                cert: cert,
                onDelete: () => ref
                    .read(breedingSetupControllerProvider(widget.petId)
                        .notifier)
                    .deleteCert(cert.id),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in HealthCertType.values)
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _uploadCert(t),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(t.label),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'Save breeding profile',
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onGoToVerification,
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text('Verification center'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Verification tab ─────────────────────────────────────────────────────────

class _VerificationTab extends ConsumerWidget {
  const _VerificationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(verificationControllerProvider);

    return async.when(
      loading: () => const Center(child: TailWagLoader()),
      error: (_, _) => const Center(
        child: PetfolioEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load verifications',
        ),
      ),
      data: (items) {
        final byType = {for (final v in items) v.type: v};
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(
              'Verified badges build trust with other owners and breeders.',
              style: tt.bodyMedium?.copyWith(color: pt.ink500),
            ),
            const SizedBox(height: 16),
            for (final type in VerificationType.values)
              _VerificationTile(
                type: type,
                existing: byType[type],
                onRequest: () => ref
                    .read(verificationControllerProvider.notifier)
                    .request(type)
                    .then((_) => AppSnackBar.showSuccess('Verification requested'))
                    .catchError((Object e) => AppSnackBar.showError(e)),
              ),
          ],
        );
      },
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.type,
    required this.existing,
    required this.onRequest,
  });

  final VerificationType type;
  final Verification? existing;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final status = existing?.status;

    final Color color;
    final IconData icon;
    switch (status) {
      case VerificationStatus.approved:
        color = pt.success;
        icon = Icons.verified;
      case VerificationStatus.rejected:
        color = pt.warning;
        icon = Icons.cancel_outlined;
      case VerificationStatus.pending:
        color = pt.ink500;
        icon = Icons.hourglass_top_outlined;
      case null:
        color = pt.ink300;
        icon = Icons.shield_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(type.label),
        subtitle: Text(
          status?.label ?? 'Not requested',
          style: tt.bodySmall?.copyWith(color: pt.ink500),
        ),
        trailing: (status == null || status == VerificationStatus.rejected)
            ? TextButton(onPressed: onRequest, child: const Text('Request'))
            : null,
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final color = ready ? pt.success : pt.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(ready ? Icons.verified_outlined : Icons.info_outline,
              color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ready
                  ? 'Ready — your pet can appear in breeding discovery.'
                  : 'Turn on listing and add a verified vaccination certificate to appear in breeding discovery.',
              style: tt.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  const _CertTile({required this.cert, required this.onDelete});
  final PetHealthCert cert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        cert.verified ? Icons.verified : Icons.hourglass_top_outlined,
        color: cert.verified ? pt.success : pt.ink300,
      ),
      title: Text(cert.certType.label),
      subtitle: Text(
        cert.verified ? 'Verified' : 'Pending verification',
        style: tt.bodySmall?.copyWith(color: pt.ink500),
      ),
      trailing:
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
