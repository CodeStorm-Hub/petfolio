import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'my_shop_controller.dart';

// Minimal valid 1×1 white PNG (67 bytes) — used only in debug builds
const _kOnePxPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x00, 0x00, 0x00, 0x00, 0x3A, 0x7E, 0x9B,
  0x55, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x62, 0x60, 0x00, 0x00, 0x00,
  0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

final manualKycControllerProvider =
    NotifierProvider<ManualKycNotifier, KycFormState>(
  ManualKycNotifier.new,
);

class KycFormState {
  const KycFormState({
    this.step = 0,
    this.nidBytes,
    this.tradeLicenseBytes,
    this.submitting = false,
    this.docError,
  });

  final int step;
  final Uint8List? nidBytes;
  final Uint8List? tradeLicenseBytes;
  final bool submitting;
  final String? docError;

  KycFormState copyWith({
    int? step,
    Uint8List? nidBytes,
    Uint8List? tradeLicenseBytes,
    bool? submitting,
    String? docError,
    bool clearDocError = false,
  }) =>
      KycFormState(
        step: step ?? this.step,
        nidBytes: nidBytes ?? this.nidBytes,
        tradeLicenseBytes: tradeLicenseBytes ?? this.tradeLicenseBytes,
        submitting: submitting ?? this.submitting,
        docError: clearDocError ? null : (docError ?? this.docError),
      );
}

class ManualKycNotifier extends Notifier<KycFormState> {
  late final TextEditingController bizNameCtrl;
  late final TextEditingController bizAddressCtrl;
  late final TextEditingController bizPhoneCtrl;
  late final TextEditingController holderCtrl;
  late final TextEditingController accountCtrl;
  late final TextEditingController bankCtrl;
  late final TextEditingController branchCtrl;

  final formKey1 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();

  @override
  KycFormState build() {
    bizNameCtrl    = TextEditingController();
    bizAddressCtrl = TextEditingController();
    bizPhoneCtrl   = TextEditingController();
    holderCtrl     = TextEditingController();
    accountCtrl    = TextEditingController();
    bankCtrl       = TextEditingController();
    branchCtrl     = TextEditingController();

    ref.onDispose(() {
      bizNameCtrl.dispose();
      bizAddressCtrl.dispose();
      bizPhoneCtrl.dispose();
      holderCtrl.dispose();
      accountCtrl.dispose();
      bankCtrl.dispose();
      branchCtrl.dispose();
    });

    return const KycFormState();
  }

  bool nextStep() {
    if (state.step == 0 && !(formKey1.currentState?.validate() ?? false)) {
      return false;
    }
    if (state.step == 1 &&
        state.nidBytes == null &&
        state.tradeLicenseBytes == null) {
      state = state.copyWith(
        docError: 'Upload at least one document to continue.',
      );
      return false;
    }
    state = state.copyWith(step: state.step + 1, clearDocError: true);
    return true;
  }

  void prevStep() => state = state.copyWith(step: state.step - 1, clearDocError: true);

  Future<void> pickNidImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    state = state.copyWith(nidBytes: await file.readAsBytes(), clearDocError: true);
  }

  Future<void> pickTradeLicenseImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    state = state.copyWith(tradeLicenseBytes: await file.readAsBytes(), clearDocError: true);
  }

  void loadTestDocument() {
    assert(kDebugMode, 'loadTestDocument is only available in debug builds');
    if (!kDebugMode) return;
    state = state.copyWith(
      nidBytes: Uint8List.fromList(_kOnePxPng),
      clearDocError: true,
    );
  }

  Future<bool> submit() async {
    if (!(formKey3.currentState?.validate() ?? false)) return false;
    state = state.copyWith(submitting: true);

    final ok = await ref.read(myShopProvider.notifier).submitKyc(
          bankDetails: {
            'account_holder': holderCtrl.text.trim(),
            'account_number': accountCtrl.text.trim(),
            'bank_name':      bankCtrl.text.trim(),
            'branch':         branchCtrl.text.trim(),
          },
          nidBytes:          state.nidBytes,
          tradeLicenseBytes: state.tradeLicenseBytes,
        );

    state = state.copyWith(submitting: false);
    return ok;
  }
}
