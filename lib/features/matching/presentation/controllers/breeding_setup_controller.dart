import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match_mode.dart';
import '../../data/models/match_profile.dart';
import '../../data/models/pet_health_cert.dart';
import '../../data/models/pet_pedigree.dart';
import '../../data/repositories/matching_repository.dart';

class BreedingSetupState {
  const BreedingSetupState({
    required this.profile,
    required this.pedigree,
    required this.certs,
  });

  final MatchProfile? profile;
  final PetPedigree? pedigree;
  final List<PetHealthCert> certs;

  bool get hasVerifiedVaccination => certs.any(
        (c) =>
            c.certType == HealthCertType.vaccination &&
            c.verified &&
            (c.expiresAt == null || c.expiresAt!.isAfter(DateTime.now())),
      );

  bool get isReady => (profile?.isActive ?? false) && hasVerifiedVaccination;
}

final breedingSetupControllerProvider = AsyncNotifierProvider.family<
    BreedingSetupController, BreedingSetupState, String>(
  BreedingSetupController.new,
);

class BreedingSetupController extends AsyncNotifier<BreedingSetupState> {
  BreedingSetupController(this.arg);

  final String arg;

  String get _petId => arg;

  @override
  Future<BreedingSetupState> build() => _load();

  Future<BreedingSetupState> _load() async {
    final repo = ref.read(matchingRepositoryProvider);
    final profile = await repo.fetchMatchProfile(_petId, MatchMode.breeding);
    final pedigree = await repo.fetchPedigree(_petId);
    final certs = await repo.fetchHealthCerts(_petId);
    return BreedingSetupState(
      profile: profile,
      pedigree: pedigree,
      certs: certs,
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _load());
  }

  Future<void> saveProfile({
    required bool isActive,
    String? playStyle,
    String? energyLevel,
    String? preferredSize,
    String? availability,
  }) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.saveMatchProfile(
      MatchProfile(
        petId: _petId,
        mode: MatchMode.breeding,
        isActive: isActive,
        playStyle: playStyle,
        energyLevel: energyLevel,
        preferredSize: preferredSize,
        availability: availability,
      ),
    );
    await _refresh();
  }

  Future<void> savePedigree({
    String? sireRef,
    String? damRef,
    String? registryName,
    String? registryId,
    String? titles,
  }) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.savePedigree(
      PetPedigree(
        petId: _petId,
        sireRef: sireRef,
        damRef: damRef,
        registryName: registryName,
        registryId: registryId,
        titles: titles,
      ),
    );
    await _refresh();
  }

  Future<void> addCert({
    required HealthCertType certType,
    required Uint8List bytes,
    required String ext,
    required String contentType,
    DateTime? expiresAt,
  }) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.addHealthCert(
      petId: _petId,
      certType: certType,
      bytes: bytes,
      ext: ext,
      contentType: contentType,
      expiresAt: expiresAt,
    );
    await _refresh();
  }

  Future<void> deleteCert(String id) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.deleteHealthCert(id);
    await _refresh();
  }
}
