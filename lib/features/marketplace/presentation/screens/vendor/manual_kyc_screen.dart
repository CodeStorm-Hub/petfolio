
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/manual_kyc_controller.dart';
import '../../../../../core/theme/app_theme.dart';


class ManualKycScreen extends ConsumerWidget {
  const ManualKycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycState = ref.watch(manualKycControllerProvider);
    final notifier = ref.read(manualKycControllerProvider.notifier);

    ref.listen<String?>(
      manualKycControllerProvider.select((s) => s.docError),
      (_, error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              step: kycState.step,
              onBack: kycState.step == 0
                  ? () => context.pop()
                  : notifier.prevStep,
            ),
            _StepIndicator(step: kycState.step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: [
                  _Step1(
                    formKey:     notifier.formKey1,
                    nameCtrl:    notifier.bizNameCtrl,
                    addressCtrl: notifier.bizAddressCtrl,
                    phoneCtrl:   notifier.bizPhoneCtrl,
                  ),
                  _Step2(
                    nidBytes:          kycState.nidBytes,
                    tradeLicenseBytes: kycState.tradeLicenseBytes,
                    onPickNid:         notifier.pickNidImage,
                    onPickTrade:       notifier.pickTradeLicenseImage,
                    onLoadTestDoc:     notifier.loadTestDocument,
                  ),
                  _Step3(
                    formKey:    notifier.formKey3,
                    holderCtrl: notifier.holderCtrl,
                    accountCtrl: notifier.accountCtrl,
                    bankCtrl:   notifier.bankCtrl,
                    branchCtrl: notifier.branchCtrl,
                  ),
                ][kycState.step],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryPillButton(
            label: kycState.step < 2 ? 'Continue' : 'Submit documents',
            size: PillButtonSize.xl,
            isFullWidth: true,
            isLoading: kycState.submitting,
            onPressed: kycState.submitting
                ? null
                : () async {
                    if (kycState.step < 2) {
                      notifier.nextStep();
                    } else {
                      final ok = await notifier.submit();
                      if (ok && context.mounted) context.go('/seller');
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Submission failed. Please try again.'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
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
                color: cs.surfaceContainerLowest,
                boxShadow: [BoxShadow(color: const Color(0xFFE2E8F0), spreadRadius: 0.5)],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: const Color(0xFF334155)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _titles[step],
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: pt.ink950,
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
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
                color: active ? pt.info : const Color(0xFFE2E8F0),
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
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
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
    required this.onPickNid,
    required this.onPickTrade,
    required this.onLoadTestDoc,
  });

  final Uint8List? nidBytes;
  final Uint8List? tradeLicenseBytes;
  final VoidCallback onPickNid;
  final VoidCallback onPickTrade;
  final VoidCallback onLoadTestDoc;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload at least one of the following documents. Both are accepted.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        _DocPicker(
          label: 'National ID (NID)',
          icon: Icons.badge_outlined,
          hasFile: nidBytes != null,
          onTap: onPickNid,
        ),
        const SizedBox(height: 12),
        _DocPicker(
          label: 'Trade License',
          icon: Icons.description_outlined,
          hasFile: tradeLicenseBytes != null,
          onTap: onPickTrade,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('load_test_document'),
            onPressed: onLoadTestDoc,
            child: const Text('Load Test Document (QA)'),
          ),
        ],
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cs.surfaceContainerLowest,
          border: Border.all(
            color: hasFile ? pt.info : const Color(0xFFE2E8F0),
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
                    ? pt.info.withAlpha(20)
                    : pt.surface2,
              ),
              child: Icon(
                hasFile ? Icons.check_circle_outline_rounded : icon,
                size: 20,
                color: hasFile ? pt.info : pt.ink300,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: pt.ink950,
                    ),
                  ),
                  Text(
                    hasFile ? 'Image selected — tap to replace' : 'Tap to pick from gallery',
                    style: TextStyle(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.upload_rounded,
              size: 18,
              color: hasFile ? pt.info : pt.ink300,
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
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
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
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pt.info, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
      ),
    );
  }
}
