import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../../data/models/shop.dart';
import '../../controllers/my_shop_controller.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;
  bool _isEdit = false;
  PayoutMethod _selectedPayout = PayoutMethod.stripe;

  @override
  void initState() {
    super.initState();
    final shop = ref.read(myShopProvider).value;
    _isEdit = shop != null && shop.isActive;
    _nameCtrl = TextEditingController(text: _isEdit ? shop!.shopName : '');
    _slugCtrl = TextEditingController(text: _isEdit ? shop!.slug : '');
    _descCtrl = TextEditingController(text: _isEdit ? (shop!.description ?? '') : '');
    if (_isEdit) _selectedPayout = shop!.payoutMethod;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    bool ok;
    if (_isEdit) {
      ok = await ref.read(myShopProvider.notifier).updateShop(
            shopName: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
          );
    } else {
      final slug = _slugCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
      ok = await ref.read(myShopProvider.notifier).createShop(
            name: _nameCtrl.text.trim(),
            slug: slug,
            description: _descCtrl.text.trim(),
            payoutMethod: _selectedPayout,
          );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save shop. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!_isEdit && _selectedPayout == PayoutMethod.manual) {
      context.pushReplacement('/seller/kyc');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Shop' : 'Create Shop',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.ink950,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Shop name'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _nameCtrl,
                        hint: 'e.g. Pawsome Treats Co.',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (!_isEdit) ...[
                        _Label('URL slug'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _slugCtrl,
                          hint: 'e.g. pawsome-treats',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(v.trim())) {
                              return 'Use lowercase letters, numbers, and hyphens only';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _Label('Description'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _descCtrl,
                        hint: 'Tell buyers what makes your shop special…',
                        maxLines: 4,
                      ),
                      if (!_isEdit) ...[
                        const SizedBox(height: 24),
                        _Label('Payment location'),
                        const SizedBox(height: 10),
                        _LocationTile(
                          title: 'International',
                          subtitle: 'Receive payouts via Stripe',
                          icon: Icons.public_rounded,
                          selected: _selectedPayout == PayoutMethod.stripe,
                          onTap: () => setState(
                              () => _selectedPayout = PayoutMethod.stripe),
                        ),
                        const SizedBox(height: 10),
                        _LocationTile(
                          title: 'Bangladesh',
                          subtitle: 'Receive payouts via bank transfer',
                          icon: Icons.account_balance_rounded,
                          selected: _selectedPayout == PayoutMethod.manual,
                          onTap: () => setState(
                              () => _selectedPayout = PayoutMethod.manual),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryPillButton(
            label: _isEdit ? 'Save changes' : 'Create shop',
            size: PillButtonSize.xl,
            isFullWidth: true,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface0,
          border: Border.all(
            color: selected ? AppColors.tangerine : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.tangerine.withAlpha(20)
                    : AppColors.surface2,
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? AppColors.tangerine : AppColors.ink300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.tangerine : AppColors.ink950,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink500),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.tangerine : AppColors.ink300,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink700,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface0,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.tangerine, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink700),
      ),
    );
  }
}
