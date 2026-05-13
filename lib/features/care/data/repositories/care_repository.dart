import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/care_task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final careTaskRepositoryProvider = Provider<CareTaskRepository>(
  (_) => CareTaskRepository(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────────────────
// Repository — care_tasks table
//
// All write operations require an authenticated user (RLS enforced).
// Throws [AppException] subclasses; never leaks raw [PostgrestException].
// ─────────────────────────────────────────────────────────────────────────────

class CareTaskRepository {
  const CareTaskRepository(this._client);

  final SupabaseClient _client;

  // ── Auth guard ──────────────────────────────────────────────────────────────

  void _requireAuth() {
    if (_client.auth.currentUser == null) throw const NotAuthenticatedException();
  }

  // ── Fetch all tasks for a pet ───────────────────────────────────────────────

  Future<List<CareTask>> fetchTasksForPet(String petId) async {
    try {
      _requireAuth();
      final rows = await _client
          .from('care_tasks')
          .select()
          .eq('pet_id', petId)
          .order('created_at');
      return rows.map(CareTask.fromJson).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Fetch tasks relevant to a specific date ─────────────────────────────────
  //
  // Returns:
  //   • all uncompleted tasks (pending, due on any day)
  //   • tasks completed on [date] (for history / streak views)
  //
  // Two queries are issued and merged client-side to avoid complex OR filters.

  Future<List<CareTask>> fetchTasksForDate(String petId, DateTime date) async {
    try {
      _requireAuth();

      final day = DateUtils.dateOnly(date);
      final startOfDay = DateTime.utc(day.year, day.month, day.day);
      final endOfDay   = DateTime.utc(day.year, day.month, day.day, 23, 59, 59, 999);

      final pendingRows = await _client
          .from('care_tasks')
          .select()
          .eq('pet_id', petId)
          .eq('is_completed', false)
          .order('created_at');

      final completedRows = await _client
          .from('care_tasks')
          .select()
          .eq('pet_id', petId)
          .eq('is_completed', true)
          .gte('completed_at', startOfDay.toIso8601String())
          .lte('completed_at', endOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      return [
        ...pendingRows.map(CareTask.fromJson),
        ...completedRows.map(CareTask.fromJson),
      ];
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<CareTask> createTask(CareTask task) async {
    try {
      _requireAuth();
      final payload = task.toJson()..remove('id');
      final row = await _client
          .from('care_tasks')
          .insert(payload)
          .select()
          .single();
      return CareTask.fromJson(row);
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

  Future<CareTask> updateTask(CareTask task) async {
    try {
      _requireAuth();
      final row = await _client
          .from('care_tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();
      return CareTask.fromJson(row);
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

  Future<void> deleteTask(String taskId) async {
    try {
      _requireAuth();
      await _client.from('care_tasks').delete().eq('id', taskId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── Toggle completion ───────────────────────────────────────────────────────
  //
  // Sets is_completed + completed_at atomically.
  // Returns the updated task with DB-assigned updated_at.

  Future<CareTask> toggleCompletion(String taskId, {required bool isCompleted}) async {
    try {
      _requireAuth();
      final row = await _client
          .from('care_tasks')
          .update({
            'is_completed': isCompleted,
            'completed_at': isCompleted ? DateTime.now().toUtc().toIso8601String() : null,
          })
          .eq('id', taskId)
          .select()
          .single();
      return CareTask.fromJson(row);
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
