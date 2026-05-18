import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/my_shop_controller.dart';

class ManualKycScreen extends ConsumerStatefulWidget {
  const ManualKycScreen({super.key});

  @override
  ConsumerState<ManualKycScreen> createState() => _ManualKycScreenState();
}

class _ManualKycScreenState extends ConsumerState<ManualKycScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Step 1 — business info
  final _bizNameCtrl    = TextEditingController();
  final _bizAddressCtrl = TextEditingController();
  final _bizPhoneCtrl   = TextEditingController();

  // Step 2 — documents
  Uint8List? _nidBytes;
  Uint8List? _tradeLicenseBytes;

  // Step 3 — bank details
  final _holderCtrl  = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bankCtrl    = TextEditingController();
  final _branchCtrl  = TextEditingController();

  int _step = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _bizAddressCtrl.dispose();
    _bizPhoneCtrl.dispose();
    _holderCtrl.dispose();
    _accountCtrl.dispose();
    _bankCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isNid) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (isNid) {
        _nidBytes = bytes;
      } else {
        _tradeLicenseBytes = bytes;
      }
    });
  }

  void _nextStep() {
    if (_step == 0 && !_formKey1.currentState!.validate()) return;
    if (_step == 1 && _nidBytes == null && _tradeLicenseBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload at least one document to continue.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _step++);
  }

  Future<void> _submit() async {
    if (!_formKey3.currentState!.validate()) return;
    setState(() => _submitting = true);

    final ok = await ref.read(myShopProvider.notifier).submitKyc(
          bankDetails: {
            'account_holder': _holderCtrl.text.trim(),
            'account_number': _accountCtrl.text.trim(),
            'bank_name':      _bankCtrl.text.trim(),
            'branch':         _branchCtrl.text.trim(),
          },
          nidBytes:          _nidBytes,
          tradeLicenseBytes: _tradeLicenseBytes,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      context.go('/seller');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission failed. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
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
            _Header(step: _step, onBack: _step == 0 ? () => context.pop() : () => setState(() => _step--)),
            _StepIndicator(step: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: [
                  _Step1(formKey: _formKey1, nameCtrl: _bizNameCtrl, addressCtrl: _bizAddressCtrl, phoneCtrl: _bizPhoneCtrl),
                  _Step2(nidBytes: _nidBytes, tradeLicenseBytes: _tradeLicenseBytes, onPick: _pickImage),
                  _Step3(formKey: _formKey3, holderCtrl: _holderCtrl, accountCtrl: _accountCtrl, bankCtrl: _bankCtrl, branchCtrl: _branchCtrl),
                ][_step],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryPillButton(
            label: _step < 2 ? 'Continue' : 'Submit documents',
            size: PillButtonSize.xl,
            isFullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : (_step < 2 ? _nextStep : _submit),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  static const _titles = ['Business Info', 'Documents', 'Bank Details'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface0,
                boxShadow: const [BoxShadow(color: AppColors.line200, spreadRadius: 0.5)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _titles[step],
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.ink950,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active ? AppColors.blue500 : AppColors.line200,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Business name'),
          const SizedBox(height: 6),
          _Field(controller: nameCtrl, hint: 'e.g. Pawsome Pets Ltd.', validator: _required),
          const SizedBox(height: 16),
          const _Label('Business address'),
          const SizedBox(height: 6),
          _Field(controller: addressCtrl, hint: 'e.g. 12 Gulshan Ave, Dhaka', maxLines: 2, validator: _required),
          const SizedBox(height: 16),
          const _Label('Phone number'),
          const SizedBox(height: 6),
          _Field(
            controller: phoneCtrl,
            hint: 'e.g. +880 1700 000000',
            keyboardType: TextInputType.phone,
            validator: _required,
          ),
        ],
      ),
    );
  }

  static String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;
}

class _Step2 extends StatelessWidget {
  const _Step2({
    required this.nidBytes,
    required this.tradeLicenseBytes,
    required this.onPick,
  });

  final Uint8List? nidBytes;
  final Uint8List? tradeLicenseBytes;
  final void Function(bool isNid) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload at least one of the following documents. Both are accepted.',
          style: TextStyle(fontSize: 13, color: AppColors.ink500),
        ),
        const SizedBox(height: 20),
        _DocPicker(
          label: 'National ID (NID)',
          icon: Icons.badge_outlined,
          hasFile: nidBytes != null,
          onTap: () => onPick(true),
        ),
        const SizedBox(height: 12),
        _DocPicker(
          label: 'Trade License',
          icon: Icons.description_outlined,
          hasFile: tradeLicenseBytes != null,
          onTap: () => onPick(false),
        ),
      ],
    );
  }
}

class _DocPicker extends StatelessWidget {
  const _DocPicker({
    required this.label,
    required this.icon,
    required this.hasFile,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool hasFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface0,
          border: Border.all(
            color: hasFile ? AppColors.blue500 : AppColors.line200,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: hasFile
                    ? AppColors.blue500.withAlpha(20)
                    : AppColors.surface2,
              ),
              child: Icon(
                hasFile ? Icons.check_circle_outline_rounded : icon,
                size: 20,
                color: hasFile ? AppColors.blue500 : AppColors.ink300,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink950,
                    ),
                  ),
                  Text(
                    hasFile ? 'Image selected — tap to replace' : 'Tap to pick from gallery',
                    style: const TextStyle(fontSize: 12, color: AppColors.ink500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.upload_rounded,
              size: 18,
              color: hasFile ? AppColors.blue500 : AppColors.ink300,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({
    required this.formKey,
    required this.holderCtrl,
    required this.accountCtrl,
    required this.bankCtrl,
    required this.branchCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController holderCtrl;
  final TextEditingController accountCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController branchCtrl;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Account holder name'),
          const SizedBox(height: 6),
          _Field(controller: holderCtrl, hint: 'Full name as on bank account', validator: _required),
          const SizedBox(height: 16),
          const _Label('Account number'),
          const SizedBox(height: 6),
          _Field(controller: accountCtrl, hint: 'e.g. 1234567890', keyboardType: TextInputType.number, validator: _required),
          const SizedBox(height: 16),
          const _Label('Bank name'),
          const SizedBox(height: 6),
          _Field(controller: bankCtrl, hint: 'e.g. Dutch-Bangla Bank', validator: _required),
          const SizedBox(height: 16),
          const _Label('Branch'),
          const SizedBox(height: 6),
          _Field(controller: branchCtrl, hint: 'e.g. Gulshan Branch', validator: _required),
        ],
      ),
    );
  }

  static String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;
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
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}
