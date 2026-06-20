import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_address.dart';
import '../controllers/address_controller.dart';

class AddressSheet extends ConsumerWidget {
  const AddressSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddressSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final addressesAsync = ref.watch(addressListProvider);
    final selected = ref.watch(selectedAddressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? pt.surface1 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: pt.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Deliver To',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => AddAddressSheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add New'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.poppy,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: pt.line),
            Expanded(
              child: addressesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return _EmptyAddressState(
                      onAdd: () => AddAddressSheet.show(context),
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(
                      16, 12, 16,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _AddressTile(
                      address: addresses[i],
                      isSelected: selected?.id == addresses[i].id,
                      onTap: () {
                        ref
                            .read(selectedAddressProvider.notifier)
                            .select(addresses[i]);
                        Navigator.pop(context);
                      },
                      onSetDefault: () => ref
                          .read(addressListProvider.notifier)
                          .setDefault(addresses[i].id),
                      onDelete: () => ref
                          .read(addressListProvider.notifier)
                          .deleteAddress(addresses[i].id),
                    ),
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

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  final UserAddress address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Semantics(
      label: '${address.labelName}${isSelected ? ", selected" : ""}',
      button: true,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.poppy
                : pt.line,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.poppy.withAlpha(12)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isSelected ? AppColors.poppy : AppColors.ink500)
                    .withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(address.labelEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.labelName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.poppy : pt.ink950,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withAlpha(25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mint700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.displayLine2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: pt.ink500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!address.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Set as default'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.danger)),
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

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address to get\nyour orders delivered quickly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: pt.ink500),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add New Address'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.poppy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Address bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddAddressSheet(),
      );

  @override
  ConsumerState<AddAddressSheet> createState() => AddAddressSheetState();
}

class AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  AddressLabel _label = AddressLabel.home;
  bool _isDefault = false;
  bool _saving = false;

  static const _labels = [
    AddressLabel.home,
    AddressLabel.work,
    AddressLabel.campus,
    AddressLabel.other,
  ];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zoneCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressListProvider.notifier).addAddress(
            label: _label,
            fullAddress: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            zone: _zoneCtrl.text.trim(),
            area: _areaCtrl.text.trim(),
            isDefault: _isDefault,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? pt.surface1 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: pt.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Address',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: pt.ink950,
                ),
              ),
              const SizedBox(height: 20),

              _Field(
                controller: _addressCtrl,
                hint: 'Enter Full Address',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(controller: _cityCtrl, hint: 'City'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(controller: _zoneCtrl, hint: 'Zone'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(controller: _areaCtrl, hint: 'Area'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Add a label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: pt.ink950,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _labels
                    .map(
                      (l) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _LabelTile(
                            label: l,
                            selected: _label == l,
                            onTap: () => setState(() => _label = l),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.poppy.withAlpha(18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set As Default Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: pt.ink950,
                          ),
                        ),
                        Text(
                          'Use this for future deliveries',
                          style: TextStyle(fontSize: 12, color: pt.ink500),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    activeThumbColor: AppColors.poppy,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.poppy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.poppy.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 14, color: pt.ink950),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: pt.ink500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pt.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pt.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.poppy, width: 1.5),
        ),
      ),
    );
  }
}

class _LabelTile extends StatelessWidget {
  const _LabelTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AddressLabel label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final labelText = switch (label) {
      AddressLabel.home => 'Home',
      AddressLabel.work => 'Work',
      _ => label.name,
    };
    return Semantics(
      label: '$labelText${selected ? ", selected" : ""}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.poppy : pt.line,
            width: selected ? 1.5 : 1,
          ),
          color: selected ? AppColors.poppy.withAlpha(14) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              UserAddress(
                id: '',
                userId: '',
                label: label,
                fullAddress: '',
                city: '',
                zone: '',
                area: '',
                isDefault: false,
                createdAt: DateTime.now(),
              ).labelEmoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              UserAddress(
                id: '',
                userId: '',
                label: label,
                fullAddress: '',
                city: '',
                zone: '',
                area: '',
                isDefault: false,
                createdAt: DateTime.now(),
              ).labelName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.poppy : pt.ink500,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
