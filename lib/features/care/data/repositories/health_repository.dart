import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/health_log.dart';
import '../models/medical_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final healthRepositoryProvider = Provider<HealthRepository>(
  (_) => HealthRepository(Supabase.instance.client),
);

final medicalVaultRepositoryProvider = Provider<MedicalVaultRepository>(
  (_) => MedicalVaultRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────────────────
// HealthRepository — health_logs table
//
// Stores narrative health events: symptoms, weight entries, vet visit notes.
// All operations require an authenticated user (RLS enforced).
// Throws [AppException] subclasses; never leaks raw [PostgrestException].
// ─────────────────────────────────────────────────────────────────────────────

class HealthRepository {
  const HealthRepository(this._client);

  final SupabaseClient _client;

  // ── Auth guard ──────────────────────────────────────────────────────────────

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const NotAuthenticatedException();
    return id;
  }

  // ── Fetch all logs for a pet (newest first) ─────────────────────────────────

  Future<List<HealthLog>> fetchLogsForPet(String petId) async {
    try {
      _requireUserId();
      final rows = await _client
          .from('health_logs')
          .select()
          .eq('pet_id', petId)
          .order('occurred_at', ascending: false);
      return rows.map(HealthLog.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Fetch logs filtered by type ─────────────────────────────────────────────

  Future<List<HealthLog>> fetchLogsByType(
      String petId, HealthLogType type) async {
    try {
      _requireUserId();
      final rows = await _client
          .from('health_logs')
          .select()
          .eq('pet_id', petId)
          .eq('log_type', type.name)
          .order('occurred_at', ascending: false);
      return rows.map(HealthLog.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Fetch weight history (ascending for chart rendering) ────────────────────

  Future<List<HealthLog>> fetchWeightHistory(String petId) async {
    try {
      _requireUserId();
      final rows = await _client
          .from('health_logs')
          .select()
          .eq('pet_id', petId)
          .eq('log_type', HealthLogType.weight.name)
          .not('weight_kg', 'is', null)
          .order('occurred_at');
      return rows.map(HealthLog.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<HealthLog> createLog(HealthLog log) async {
    try {
      final userId = _requireUserId();
      final payload = log.toJson()
        ..remove('id')
        ..['recorded_by'] = userId;
      final row = await _client
          .from('health_logs')
          .insert(payload)
          .select()
          .single();
      return HealthLog.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<HealthLog> updateLog(HealthLog log) async {
    try {
      _requireUserId();
      final row = await _client
          .from('health_logs')
          .update(log.toJson())
          .eq('id', log.id)
          .select()
          .single();
      return HealthLog.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteLog(String logId) async {
    try {
      _requireUserId();
      await _client.from('health_logs').delete().eq('id', logId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MedicalVaultRepository — medical_vault table
//
// Stores vaccines, medications, and allergy records with expiry / renewal dates.
// All operations require an authenticated user (RLS enforced).
// ─────────────────────────────────────────────────────────────────────────────

class MedicalVaultRepository {
  const MedicalVaultRepository(this._client);

  final SupabaseClient _client;

  void _requireAuth() {
    if (_client.auth.currentUser == null) throw const NotAuthenticatedException();
  }

  // ── Fetch all records for a pet ─────────────────────────────────────────────

  Future<List<MedicalRecord>> fetchRecordsForPet(String petId) async {
    try {
      _requireAuth();
      final rows = await _client
          .from('medical_vault')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return rows.map(MedicalRecord.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Fetch active records only ───────────────────────────────────────────────

  Future<List<MedicalRecord>> fetchActiveRecords(String petId) async {
    try {
      _requireAuth();
      final rows = await _client
          .from('medical_vault')
          .select()
          .eq('pet_id', petId)
          .eq('is_active', true)
          .order('next_due_at', ascending: true, nullsFirst: false);
      return rows.map(MedicalRecord.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Fetch records by type ───────────────────────────────────────────────────

  Future<List<MedicalRecord>> fetchRecordsByType(
      String petId, MedicalRecordType type) async {
    try {
      _requireAuth();
      final rows = await _client
          .from('medical_vault')
          .select()
          .eq('pet_id', petId)
          .eq('record_type', type.name)
          .order('created_at', ascending: false);
      return rows.map(MedicalRecord.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<MedicalRecord> createRecord(MedicalRecord record) async {
    try {
      _requireAuth();
      final payload = record.toJson()..remove('id');
      final row = await _client
          .from('medical_vault')
          .insert(payload)
          .select()
          .single();
      return MedicalRecord.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<MedicalRecord> updateRecord(MedicalRecord record) async {
    try {
      _requireAuth();
      final row = await _client
          .from('medical_vault')
          .update(record.toJson())
          .eq('id', record.id)
          .select()
          .single();
      return MedicalRecord.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteRecord(String recordId) async {
    try {
      _requireAuth();
      await _client.from('medical_vault').delete().eq('id', recordId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Soft delete (deactivate) ────────────────────────────────────────────────
  //
  // Preferred over hard delete for audit trail — sets is_active = false.

  Future<MedicalRecord> deactivateRecord(String recordId) async {
    try {
      _requireAuth();
      final row = await _client
          .from('medical_vault')
          .update({'is_active': false})
          .eq('id', recordId)
          .select()
          .single();
      return MedicalRecord.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}
