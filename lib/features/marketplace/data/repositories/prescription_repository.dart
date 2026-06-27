import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prescription.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>(
  (_) => PrescriptionRepository(Supabase.instance.client),
);

class PrescriptionRepository {
  const PrescriptionRepository(this._client);

  final SupabaseClient _client;

  Future<Prescription?> fetchPrescription(String orderId) async {
    final row = await _client
        .from('prescriptions')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .maybeSingle();
    if (row == null) return null;
    return Prescription.fromJson(row);
  }

  Future<Prescription> uploadPrescription({
    required String orderId,
    required File file,
    String? vetName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/$orderId/rx_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('prescriptions').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: _mimeFor(ext), upsert: true),
        );

    final row = await _client.from('prescriptions').insert({
      'order_id': orderId,
      'file_path': path,
      if (vetName != null && vetName.isNotEmpty) 'vet_name': vetName,
    }).select().single();

    return Prescription.fromJson(row);
  }

  Future<String> signedUrl(String filePath) async =>
      await _client.storage
          .from('prescriptions')
          .createSignedUrl(filePath, 604800);

  static String _mimeFor(String ext) => switch (ext.toLowerCase()) {
        'pdf'  => 'application/pdf',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        _      => 'application/octet-stream',
      };
}
