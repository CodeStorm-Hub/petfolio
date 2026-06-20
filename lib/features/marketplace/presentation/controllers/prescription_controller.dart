import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/prescription.dart';
import '../../data/repositories/prescription_repository.dart';

part 'prescription_controller.g.dart';

@riverpod
class PrescriptionUpload extends _$PrescriptionUpload {
  late String _orderId;

  @override
  Future<Prescription?> build(String orderId) {
    _orderId = orderId;
    return ref.read(prescriptionRepositoryProvider).fetchPrescription(orderId);
  }

  Future<void> upload(File file, {String? vetName}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(prescriptionRepositoryProvider).uploadPrescription(
            orderId: _orderId,
            file: file,
            vetName: vetName,
          ),
    );
  }
}
