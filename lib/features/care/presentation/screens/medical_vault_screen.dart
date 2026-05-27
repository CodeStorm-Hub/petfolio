import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/dashed_rect_painter.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
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
      return const Scaffold(body: Center(child: TailWagLoader()));
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
    final asyncRecords = ref.watch(healthVaultControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.mintSoft, AppColors.cream],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.surface0,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: AppColors.ink700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${petName.toUpperCase()} · MEDICAL VAULT',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.mint700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openAddSheet(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.mint,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.shadowE1L, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: AppColors.ink950,
                        ),
                        children: [
                          TextSpan(text: 'Everything '),
                          TextSpan(text: 'healthy', style: TextStyle(color: AppColors.mint700)),
                          TextSpan(text: ',\nin one cozy spot.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vaccines, meds, and vet visits — synced live from $petName\'s clinic.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: _HealthPill(icon: '💚', label: 'Vitals', value: 'Strong')),
                        SizedBox(width: 8),
                        Expanded(child: _HealthPill(icon: '💉', label: 'Vaccines', value: 'Up to date')),
                        SizedBox(width: 8),
                        Expanded(child: _HealthPill(icon: '📅', label: 'Next visit', value: '14 Jun')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: asyncRecords.when(
                loading: () => SliverList(
                  delegate: SliverChildListDelegate([
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
                        const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.ink300),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load medical records',
                          style: TextStyle(fontSize: 15, color: AppColors.ink500),
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
                      _VaultSection(
                        title: 'Vaccines',
                        icon: Icons.vaccines_rounded,
                        accent: AppColors.mint,
                        records: vaccines,
                        emptyLabel: 'No vaccine records yet.',
                      ),
                      const SizedBox(height: 20),
                      _VaultSection(
                        title: 'Medications',
                        icon: Icons.medication_rounded,
                        accent: AppColors.poppy,
                        records: meds,
                        emptyLabel: 'No medication records yet.',
                      ),
                      const SizedBox(height: 20),
                      _VaultSection(
                        title: 'Vet visits',
                        icon: Icons.local_hospital_rounded,
                        accent: AppColors.tangerine,
                        records: vet,
                        emptyLabel: 'No vet visit or clinical notes yet.',
                      ),
                      // Share with vet card
                      CustomPaint(
                        painter: DashedRectPainter(
                          color: AppColors.mint,
                          strokeWidth: 2,
                          dashLength: 8,
                          dashSpace: 6,
                          borderRadius: 24,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [AppColors.mintSoft, AppColors.surface0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🩺', style: TextStyle(fontSize: 36)),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Share with your vet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink950)),
                                    Text('Generate a temporary QR — expires in 24h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink500)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
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

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface0,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: const [BoxShadow(color: AppColors.shadowE1L, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18, height: 1)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: AppColors.ink500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink950)),
        ],
      ),
    );
  }
}

class _VaultSection extends StatelessWidget {
  const _VaultSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.records,
    required this.emptyLabel,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<MedicalRecord> records;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color.lerp(accent, AppColors.surface0, 0.78),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, size: 18, color: accent)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink950,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(accent, AppColors.surface0, 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${records.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface0,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
          child: records.isEmpty
              ? PetfolioEmptyState(
                  icon: icon,
                  title: emptyLabel,
                )
              : Column(
                  children: [
                    for (int i = 0; i < records.length; i++) ...[
                      _MedicalRecordCard(record: records[i], accent: accent, icon: icon),
                      if (i < records.length - 1)
                        const Divider(height: 1, thickness: 1, color: AppColors.line),
                    ]
                  ],
                ),
        ),
      ],
    );
  }
}

class _MedicalRecordCard extends ConsumerWidget {
  const _MedicalRecordCard({required this.record, required this.accent, required this.icon});

  final MedicalRecord record;
  final Color accent;
  final IconData icon;

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
    final warn = record.isExpiringSoon;
    final statusBg = warn ? AppColors.sunnySoft : Color.lerp(accent, AppColors.surface0, 0.85)!;
    final statusColor = warn ? AppColors.sunny700 : Color.lerp(accent, AppColors.ink950, 0.5)!;
    final statusLabel = warn ? 'Due soon' : (record.isActive ? 'Active' : 'Archived');
    
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(230),
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await ref.read(healthVaultControllerProvider.notifier).deactivateRecord(record.id);
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color.lerp(accent, AppColors.surface0, 0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(icon, size: 20, color: accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink950,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLine(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink500,
                    ),
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.notes!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.ink700,
                      ),
                    ),
                  ],
                  if (record.documentUrl != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openDocument(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 14,
                            color: AppColors.tangerine,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'View document',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tangerine,
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
                    color: pt.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text(
              'Log medical record',
              style: TextStyle(
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
                        color: selected ? Colors.transparent : pt.line,
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
                  borderSide: BorderSide(color: pt.line, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line, width: 0.5),
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
                  borderSide: BorderSide(color: pt.line, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line, width: 0.5),
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
                  borderSide: BorderSide(color: pt.line, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line, width: 0.5),
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
                  borderSide: BorderSide(color: pt.line, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line, width: 0.5),
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
                  border: Border.all(color: pt.line, width: 0.5),
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
              border: Border.all(color: pt.line, width: 0.5),
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
