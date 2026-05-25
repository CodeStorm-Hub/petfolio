import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/medical_record.dart';
import '../../data/repositories/health_repository.dart';
import '../controllers/health_vault_controller.dart';

extension on MedicalRecord {
  bool get _inVaccinesSection => recordType == MedicalRecordType.vaccine;

  bool get _inMedicationsSection =>
      recordType == MedicalRecordType.medication ||
      recordType == MedicalRecordType.parasitePrevention;

  bool get _inVetVisitsSection =>
      recordType == MedicalRecordType.surgery ||
      recordType == MedicalRecordType.allergy ||
      recordType == MedicalRecordType.other;
}

class MedicalVaultScreen extends ConsumerWidget {
  const MedicalVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }
    return _MedicalVaultBody(petId: pet.id, petName: pet.name);
  }
}

class _MedicalVaultBody extends ConsumerWidget {
  const _MedicalVaultBody({required this.petId, required this.petName});

  final String petId;
  final String petName;

  void _openAddSheet(BuildContext context) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => AddMedicalRecordSheet(petId: petId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final asyncRecords = ref.watch(healthVaultControllerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: pt.surface1,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Medical vault',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: asyncRecords.when(
                loading: () => SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    ...List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 88,
                          borderRadius: 16,
                        ),
                      ),
                    ),
                  ]),
                ),
                error: (err, st) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 44, color: pt.ink300),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load medical records',
                          style: TextStyle(fontSize: 15, color: pt.ink500),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (records) {
                  final vaccines = records.where((r) => r._inVaccinesSection).toList();
                  final meds = records.where((r) => r._inMedicationsSection).toList();
                  final vet = records.where((r) => r._inVetVisitsSection).toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        petName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08 * 11,
                          color: pt.ink500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Automated medical vault',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: -0.2,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vaccines, medications, and vet-linked records stay grouped and update live.',
                        style: TextStyle(fontSize: 14, height: 1.35, color: pt.ink500),
                      ),
                      const SizedBox(height: 24),
                      _VaultSection(
                        title: 'Vaccines',
                        icon: Icons.vaccines_rounded,
                        records: vaccines,
                        emptyLabel: 'No vaccine records yet.',
                      ),
                      const SizedBox(height: 24),
                      _VaultSection(
                        title: 'Medications',
                        icon: Icons.medication_rounded,
                        records: meds,
                        emptyLabel: 'No medication records yet.',
                      ),
                      const SizedBox(height: 24),
                      _VaultSection(
                        title: 'Vet visits',
                        icon: Icons.local_hospital_rounded,
                        records: vet,
                        emptyLabel: 'No vet visit or clinical notes yet.',
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultSection extends StatelessWidget {
  const _VaultSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.emptyLabel,
  });

  final String title;
  final IconData icon;
  final List<MedicalRecord> records;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: pt.pillarHealth),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          PfEmptyState(
            icon: icon,
            title: emptyLabel.replaceAll('.', ''),
            subtitle: 'Add a record with the + button below.',
          )
        else
          ...records.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MedicalRecordCard(record: r),
              )),
      ],
    );
  }
}

class _MedicalRecordCard extends ConsumerWidget {
  const _MedicalRecordCard({required this.record});

  final MedicalRecord record;

  Future<void> _openDocument(BuildContext context, WidgetRef ref) async {
    final path = record.documentUrl;
    if (path == null) return;
    try {
      final url = await ref
          .read(medicalVaultRepositoryProvider)
          .createDocumentUrl(path);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) AppSnackBar.showError('Could not open document.');
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.showError(e);
    }
  }

  String _dateLine() {
    final parts = <String>[];
    if (record.administeredAt != null) {
      parts.add('Given ${_fmt(record.administeredAt!)}');
    }
    if (record.nextDueAt != null) {
      parts.add('Next due ${_fmt(record.nextDueAt!)}');
    }
    if (record.expiresAt != null && record.nextDueAt == null) {
      parts.add('Expires ${_fmt(record.expiresAt!)}');
    }
    return parts.isEmpty ? 'No dates set' : parts.join(' · ');
  }

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final warn = record.isExpiringSoon;
    final borderColor = warn ? pt.warning : pt.line200;
    final fill = warn ? pt.warning.withAlpha(22) : cs.surface;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await ref.read(healthVaultControllerProvider.notifier).deactivateRecord(record.id);
        return false;
      },
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: warn ? 1.5 : 0.5),
          boxShadow: [
            if (warn)
              BoxShadow(
                color: pt.warning.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else ...[
              BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
              const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warn)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(Icons.schedule_rounded, size: 22, color: pt.warning),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.name,
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (warn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pt.warning.withAlpha(36),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Due soon',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: pt.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: pt.ink500, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _dateLine(),
                      style: TextStyle(fontSize: 12, color: pt.ink300),
                    ),
                    if (record.documentUrl != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openDocument(context, ref),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View document',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddMedicalRecordSheet extends ConsumerStatefulWidget {
  const AddMedicalRecordSheet({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<AddMedicalRecordSheet> createState() => _AddMedicalRecordSheetState();
}

class _AddMedicalRecordSheetState extends ConsumerState<AddMedicalRecordSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  var _type = MedicalRecordType.vaccine;
  var _reminder = true;
  DateTime? _administeredAt;
  DateTime? _nextDueAt;
  DateTime? _expiresAt;
  var _saving = false;
  XFile? _pickedFile;

  static const int _maxDocBytes = 10 * 1024 * 1024;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null && mounted) setState(() => _pickedFile = file);
  }

  Future<void> _pickDate(ValueChanged<DateTime?> onPick) async {
    final now = DateTime.now();
    final initial = now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (d != null && mounted) onPick(DateUtils.dateOnly(d));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    
    if (_reminder && _nextDueAt == null) {
      AppSnackBar.showError('Please set a next due date to enable a reminder.');
      return;
    }

    setState(() => _saving = true);

    String? documentPath;
    if (_pickedFile != null) {
      final Uint8List bytes = await _pickedFile!.readAsBytes();
      if (bytes.length > _maxDocBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File too large. Maximum size is 10 MB.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }
      try {
        documentPath = await ref.read(medicalVaultRepositoryProvider).uploadDocument(
          petId: widget.petId,
          fileName: _pickedFile!.name,
          bytes: bytes,
          mimeType: _pickedFile!.mimeType ?? 'image/jpeg',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document upload failed. Saving record without attachment.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    final now = DateTime.now();
    final tempId = 'tmp_${now.microsecondsSinceEpoch}';
    final record = MedicalRecord(
      id: tempId,
      petId: widget.petId,
      recordType: _type,
      name: name,
      description: null,
      administeredBy: null,
      administeredAt: _administeredAt,
      expiresAt: _expiresAt,
      nextDueAt: _nextDueAt,
      batchNumber: null,
      dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      frequency: _freqCtrl.text.trim().isEmpty ? null : _freqCtrl.text.trim(),
      isActive: true,
      reminderEnabled: _reminder,
      documentUrl: documentPath,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final ok = await ref
        .read(healthVaultControllerProvider.notifier)
        .addRecord(record);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save record. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(bottom, 24) + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pt.line200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text(
              'Log medical record',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'RECORD TYPE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MedicalRecordType.values.map((t) {
                final selected = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: PetfolioThemeExtension.durationSm,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : pt.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.transparent : pt.line200,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _typeLabel(t),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : pt.ink500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'e.g. Rabies booster',
                filled: true,
                fillColor: pt.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _DateRow(
              label: 'Administered',
              value: _administeredAt,
              onTap: () => _pickDate((d) => setState(() => _administeredAt = d)),
              onClear: () => setState(() => _administeredAt = null),
              pt: pt,
              cs: cs,
            ),
            const SizedBox(height: 10),
            _DateRow(
              label: 'Next due (renewal)',
              value: _nextDueAt,
              onTap: () => _pickDate((d) => setState(() => _nextDueAt = d)),
              onClear: () => setState(() => _nextDueAt = null),
              pt: pt,
              cs: cs,
            ),
            const SizedBox(height: 10),
            _DateRow(
              label: 'Expires',
              value: _expiresAt,
              onTap: () => _pickDate((d) => setState(() => _expiresAt = d)),
              onClear: () => setState(() => _expiresAt = null),
              pt: pt,
              cs: cs,
            ),
            const SizedBox(height: 14),
            Text(
              'DOSAGE & FREQUENCY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dosageCtrl,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Dosage (optional)',
                filled: true,
                fillColor: pt.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _freqCtrl,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Frequency (optional)',
                filled: true,
                fillColor: pt.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'NOTES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Optional notes',
                filled: true,
                fillColor: pt.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line200, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'DOCUMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 12,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickedFile == null ? _pickDocument : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: pt.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pt.line200, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file_rounded, size: 18, color: pt.ink500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedFile == null
                            ? 'Attach image (optional)'
                            : _pickedFile!.name,
                        style: TextStyle(
                          fontSize: 15,
                          color: _pickedFile != null ? cs.onSurface : pt.ink300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_pickedFile != null)
                      GestureDetector(
                        onTap: () => setState(() => _pickedFile = null),
                        child: Icon(Icons.close_rounded, size: 18, color: pt.ink300),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Reminders enabled', style: TextStyle(fontSize: 14, color: cs.onSurface)),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save record', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(MedicalRecordType t) {
  switch (t) {
    case MedicalRecordType.vaccine:
      return 'Vaccine';
    case MedicalRecordType.medication:
      return 'Medication';
    case MedicalRecordType.allergy:
      return 'Allergy';
    case MedicalRecordType.surgery:
      return 'Surgery';
    case MedicalRecordType.parasitePrevention:
      return 'Parasite';
    case MedicalRecordType.other:
      return 'Other';
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
    required this.pt,
    required this.cs,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Tap to set'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 11,
            color: pt.ink500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: pt.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pt.line200, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: pt.ink500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null ? cs.onSurface : pt.ink300,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded, size: 18, color: pt.ink300),
                  )
                else
                  Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
