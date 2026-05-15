import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/care_streak.dart';
import '../models/care_task.dart';
import '../models/care_task_log.dart';

class ToggleCompletionResult {
  const ToggleCompletionResult({
    required this.task,
    required this.badgeUnlocked,
  });

  final CareTask task;
  final bool badgeUnlocked;
}

final petCareRepositoryProvider = Provider<PetCareRepository>(
  (_) => PetCareRepository(Supabase.instance.client),
);

typedef CareTaskRepository = PetCareRepository;

final careTaskRepositoryProvider = petCareRepositoryProvider;

class PetCareRepository {
  const PetCareRepository(this._client);

  final SupabaseClient _client;

  void _requireAuth() {
    if (_client.auth.currentUser == null) throw const NotAuthenticatedException();
  }

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

  Future<List<CareTask>> fetchTasksForDate(String petId, DateTime date) async {
    try {
      _requireAuth();

      final dayLocal = DateUtils.dateOnly(date);
      final dayStr = _fmtYmd(dayLocal);

      final tasksRows = await _client
          .from('care_tasks')
          .select()
          .eq('pet_id', petId)
          .order('created_at');
      final definitions = tasksRows.map(CareTask.fromJson).toList();

      final logResponse = await _client
          .from('care_logs')
          .select('id, care_type, occurred_at')
          .eq('pet_id', petId)
          .eq('logged_date', dayStr);
      final logRows = (logResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final doneTypes = logRows
          .map((r) => r['care_type'] as String?)
          .whereType<String>()
          .toSet();

      final out = <CareTask>[];
      for (final task in definitions) {
        if (!_appliesOnDay(task, dayLocal)) continue;
        final careType = _taskTypeToLogCareType(task.taskType);
        final fromLog = doneTypes.contains(careType);
        final done = _doneForDay(task, dayLocal, fromLog);
        out.add(
          task.copyWith(
            isCompleted: done,
            completedAt: done ? DateTime.now() : null,
          ),
        );
      }

      final byCareTypeFirstRow = <String, Map<String, dynamic>>{};
      for (final row in logRows) {
        final ct = row['care_type'] as String?;
        if (ct == null) continue;
        byCareTypeFirstRow.putIfAbsent(ct, () => row);
      }
      for (final entry in byCareTypeFirstRow.entries) {
        final ct = entry.key;
        if (out.any((t) => _taskTypeToLogCareType(t.taskType) == ct)) continue;
        final row = entry.value;
        out.add(_careTaskFromLogRow(row, petId, dayLocal));
      }

      out.sort((a, b) {
        final la = a.isLogDerived;
        final lb = b.isLogDerived;
        if (la != lb) return la ? 1 : -1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return out;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Set<String>> fetchPetBadgeTypes(String petId) async {
    try {
      _requireAuth();
      final rows = await _client
          .from('pet_badges')
          .select('badge_type')
          .eq('pet_id', petId);
      return rows
          .map((e) => e['badge_type'] as String?)
          .whereType<String>()
          .toSet();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<List<bool>> fetchDailyGoalsHitForDates(
    String petId,
    List<DateTime> dates,
  ) async {
    try {
      _requireAuth();
      if (dates.isEmpty) return [];

      final normalized = dates.map(DateUtils.dateOnly).toList();
      final minD = normalized.reduce((a, b) => a.isBefore(b) ? a : b);
      final maxD = normalized.reduce((a, b) => a.isAfter(b) ? a : b);
      final minStr = _fmtYmd(minD);
      final maxStr = _fmtYmd(maxD);

      final taskTypeRows = await _client
          .from('care_tasks')
          .select('task_type, frequency')
          .eq('pet_id', petId);

      final expected = <String>{};
      for (final row in taskTypeRows) {
        final f = row['frequency'] as String?;
        final tt = row['task_type'] as String?;
        if (tt == null || f == null) continue;
        if (f == 'daily' || f == 'twice_daily') {
          expected.add(tt);
        }
      }
      if (expected.isEmpty) {
        expected.addAll({'feeding', 'walk', 'medication'});
      }

      final logs = await _client
          .from('care_logs')
          .select('care_type, logged_date')
          .eq('pet_id', petId)
          .gte('logged_date', minStr)
          .lte('logged_date', maxStr);

      final byDay = <String, Set<String>>{};
      for (final d in normalized) {
        byDay[_fmtYmd(d)] = <String>{};
      }
      for (final row in logs) {
        final day = _loggedDayKey(row['logged_date']);
        final ct = row['care_type'] as String?;
        if (day.isEmpty || ct == null) continue;
        byDay.putIfAbsent(day, () => <String>{}).add(ct);
      }

      return dates.map((d) {
        final key = _fmtYmd(DateUtils.dateOnly(d));
        final done = byDay[key] ?? {};
        for (final e in expected) {
          if (!done.contains(e)) return false;
        }
        return true;
      }).toList();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  static String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _loggedDayKey(dynamic v) {
    if (v == null) return '';
    if (v is String) {
      final p = DateTime.tryParse(v);
      if (p != null) return _fmtYmd(DateUtils.dateOnly(p.toLocal()));
      return v.length >= 10 ? v.substring(0, 10) : v;
    }
    if (v is DateTime) return _fmtYmd(DateUtils.dateOnly(v.toLocal()));
    return '';
  }

  static DateTime _localDateOnly(DateTime dt) =>
      DateUtils.dateOnly(dt.toLocal());

  static String _taskTypeToLogCareType(CareTaskType t) {
    switch (t) {
      case CareTaskType.vetVisit:
        return 'vet_visit';
      case CareTaskType.nailTrim:
        return 'nail_trim';
      default:
        return t.name;
    }
  }

  static CareTaskType _logCareTypeToTaskType(String careType) {
    switch (careType) {
      case 'vet_visit':
        return CareTaskType.vetVisit;
      case 'nail_trim':
        return CareTaskType.nailTrim;
      default:
        for (final v in CareTaskType.values) {
          if (v.name == careType) return v;
        }
        return CareTaskType.other;
    }
  }

  static String _titleForTaskType(CareTaskType t, String rawCareType) {
    switch (t) {
      case CareTaskType.feeding:
        return 'Feeding';
      case CareTaskType.walk:
        return 'Walk';
      case CareTaskType.grooming:
        return 'Grooming';
      case CareTaskType.medication:
        return 'Medication';
      case CareTaskType.vetVisit:
        return 'Vet visit';
      case CareTaskType.training:
        return 'Training';
      case CareTaskType.playtime:
        return 'Playtime';
      case CareTaskType.dental:
        return 'Dental';
      case CareTaskType.nailTrim:
        return 'Nail trim';
      case CareTaskType.bath:
        return 'Bath';
      case CareTaskType.other:
        if (rawCareType.isNotEmpty && rawCareType != 'other') {
          return rawCareType
              .split('_')
              .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
              .join(' ');
        }
        return 'Care';
    }
  }

  static CareTask _careTaskFromLogRow(
    Map<String, dynamic> row,
    String petId,
    DateTime dayLocal,
  ) {
    final id = row['id'] as String;
    final ct = row['care_type'] as String;
    final at = row['occurred_at'] as String?;
    final t = _logCareTypeToTaskType(ct);
    final parsedAt = DateTime.tryParse(at ?? '')?.toLocal() ?? dayLocal;
    return CareTask(
      id: 'log:$id',
      petId: petId,
      taskType: t,
      title: _titleForTaskType(t, ct),
      frequency: CareFrequency.asNeeded,
      scheduledTime: null,
      isCompleted: true,
      completedAt: parsedAt,
      gamificationPoints: 0,
      notes: null,
      categoryIcon: null,
      createdAt: dayLocal,
      updatedAt: parsedAt,
    );
  }

  static bool _appliesOnDay(CareTask task, DateTime dayLocal) {
    final start = _localDateOnly(task.createdAt);

    switch (task.frequency) {
      case CareFrequency.daily:
      case CareFrequency.twiceDaily:
      case CareFrequency.asNeeded:
        return true;
      case CareFrequency.once:
        if (dayLocal.isBefore(start)) return false;
        if (task.isCompleted && task.completedAt != null) {
          return dayLocal == _localDateOnly(task.completedAt!);
        }
        return !dayLocal.isBefore(start);
      case CareFrequency.weekly:
        if (dayLocal.isBefore(start)) return false;
        final diff = dayLocal.difference(start).inDays;
        return diff >= 0 && diff % 7 == 0;
      case CareFrequency.biweekly:
        if (dayLocal.isBefore(start)) return false;
        final diff = dayLocal.difference(start).inDays;
        return diff >= 0 && diff % 14 == 0;
      case CareFrequency.monthly:
        if (dayLocal.isBefore(start)) return false;
        return true;
    }
  }

  static bool _doneForDay(
    CareTask task,
    DateTime dayLocal,
    bool fromLog,
  ) {
    if (task.frequency == CareFrequency.once) {
      if (fromLog) return true;
      if (task.isCompleted &&
          task.completedAt != null &&
          _localDateOnly(task.completedAt!) == dayLocal) {
        return true;
      }
      return false;
    }
    return fromLog;
  }

  static bool _usesCareLogsForToggle(CareFrequency f) =>
      f != CareFrequency.once;

  Future<CareStreak> getPetStreak(String petId) async {
    try {
      _requireAuth();
      final row = await _client
          .from('care_streaks')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();
      if (row == null) {
        return CareStreak(
          petId: petId,
          currentStreak: 0,
          lastCompletionDate: null,
          bestStreak: 0,
        );
      }
      return CareStreak.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<CareTask> createTask(CareTask task) async {
    try {
      _requireAuth();
      final payload = Map<String, dynamic>.from(task.toJson())
        ..remove('id')
        ..remove('category_icon');
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

  Future<CareTask> updateTask(CareTask task) async {
    try {
      _requireAuth();
      final payload = Map<String, dynamic>.from(task.toJson())
        ..remove('category_icon')
        ..remove('id')
        ..remove('pet_id')
        ..remove('created_at')
        ..remove('updated_at');
      final row = await _client
          .from('care_tasks')
          .update(payload)
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

  Future<void> deleteTask(String taskId) async {
    try {
      _requireAuth();
      if (taskId.startsWith('log:')) {
        final logId = taskId.substring(4);
        await _client.from('care_logs').delete().eq('id', logId);
        return;
      }
      await _client.from('care_tasks').delete().eq('id', taskId);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<ToggleCompletionResult> toggleCompletion(
    String taskId, {
    required bool isCompleted,
    required String petId,
    required DateTime forDay,
  }) async {
    try {
      _requireAuth();
      final dayStr = _fmtYmd(DateUtils.dateOnly(forDay));
      if (taskId.startsWith('log:')) {
        final logId = taskId.substring(4);
        final row = await _client
            .from('care_logs')
            .select('id, care_type, occurred_at, pet_id, logged_date')
            .eq('id', logId)
            .maybeSingle();
        if (row == null) throw const NotFoundException();
        final map = Map<String, dynamic>.from(row);
        if ((map['pet_id'] as String?) != petId) throw const NotFoundException();
        if (_loggedDayKey(map['logged_date']) != dayStr) throw const NotFoundException();
        final dayLocal = DateUtils.dateOnly(forDay);
        final synthetic = _careTaskFromLogRow(map, petId, dayLocal);
        if (isCompleted) {
          return ToggleCompletionResult(task: synthetic, badgeUnlocked: false);
        }
        await _client.from('care_logs').delete().eq('id', logId);
        return ToggleCompletionResult(
          task: synthetic.copyWith(
            isCompleted: false,
            completedAt: null,
            updatedAt: DateTime.now(),
          ),
          badgeUnlocked: false,
        );
      }

      final userId = _client.auth.currentUser!.id;
      final existing = await _client
          .from('care_tasks')
          .select()
          .eq('id', taskId)
          .single();
      final task = CareTask.fromJson(existing);
      final careType = _taskTypeToLogCareType(task.taskType);

      if (_usesCareLogsForToggle(task.frequency)) {
        if (isCompleted) {
          await _client.from('care_logs').upsert(
            {
              'pet_id': petId,
              'logged_by': userId,
              'care_type': careType,
              'logged_date': dayStr,
              'occurred_at': '${dayStr}T00:00:00.000Z',
            },
            onConflict: 'pet_id, care_type, logged_date',
          );
        } else {
          await _client
              .from('care_logs')
              .delete()
              .eq('pet_id', petId)
              .eq('care_type', careType)
              .eq('logged_date', dayStr);
        }
      } else {
        if (isCompleted) {
          await _client
              .from('care_tasks')
              .update({
                'is_completed': true,
                'completed_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', taskId);
          await _client.from('care_logs').upsert(
            {
              'pet_id': petId,
              'logged_by': userId,
              'care_type': careType,
              'logged_date': dayStr,
              'occurred_at': '${dayStr}T00:00:00.000Z',
            },
            onConflict: 'pet_id, care_type, logged_date',
          );
        } else {
          await _client
              .from('care_tasks')
              .update({
                'is_completed': false,
                'completed_at': null,
              })
              .eq('id', taskId);
          await _client
              .from('care_logs')
              .delete()
              .eq('pet_id', petId)
              .eq('care_type', careType)
              .eq('logged_date', dayStr);
        }
      }

      var badgeUnlocked = false;
      if (isCompleted) {
        final raw = await _client.rpc(
          'check_daily_completion',
          params: {
            'target_pet_id': petId,
            'completion_date': dayStr,
          },
        );
        if (raw is Map) {
          final v = raw['badge_unlocked'];
          badgeUnlocked = v == true || v == 'true';
        }
      }

      final merged = task.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
      return ToggleCompletionResult(task: merged, badgeUnlocked: badgeUnlocked);
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
