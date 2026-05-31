import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/notification_service.dart';
import '../models/care_streak.dart';
import '../models/care_task.dart';
import '../models/care_task_log.dart';

/// Snapshot of everything the care dashboard needs, fetched in one RPC call.
class CareDashboardSnapshot {
  const CareDashboardSnapshot({
    required this.tasks,
    required this.todayTasks,
    required this.badgeTypes,
    required this.weekGoalHit,
  });

  final List<CareTask> tasks;
  final List<CareTask> todayTasks;
  final Set<String> badgeTypes;
  final List<bool> weekGoalHit;
}

class ToggleCompletionResult {
  const ToggleCompletionResult({
    required this.task,
    required this.badgeUnlocked,
    this.unlockedBadges = const [],
  });

  final CareTask task;
  final bool badgeUnlocked;
  final List<String> unlockedBadges;
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
      throw NetworkException(message: e.toString());
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
      throw NetworkException(message: e.toString());
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

  static String _frequencyToDbString(CareFrequency f) {
    switch (f) {
      case CareFrequency.twiceDaily:  return 'twice_daily';
      case CareFrequency.asNeeded:    return 'as_needed';
      default:                        return f.name;
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
        final lastDayOfMonth =
            DateTime(dayLocal.year, dayLocal.month + 1, 0).day;
        final anchorDay =
            start.day > lastDayOfMonth ? lastDayOfMonth : start.day;
        if (dayLocal.day != anchorDay) return false;
        if (dayLocal.year == start.year && dayLocal.month == start.month) {
          return !dayLocal.isBefore(start);
        }
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
      throw NetworkException(message: e.toString());
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
      final saved = CareTask.fromJson(row);
      _scheduleNotificationIfNeeded(saved);
      return saved;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<List<CareTask>> bulkCreateTasks(
    List<CareTask> tasks, {
    bool isAiSuggested = false,
  }) async {
    try {
      if (tasks.isEmpty) return [];
      _requireAuth();
      final petId = tasks.first.petId;
      final existingRows = await _client
          .from('care_tasks')
          .select('title, task_type, frequency')
          .eq('pet_id', petId);

      // Both sides normalised to DB snake_case so multi-word types like
      // vetVisit/vet_visit and frequencies like twiceDaily/twice_daily match.
      final existingTaskSet = existingRows
          .map((r) =>
              '${r['task_type']}'
              '|${r['frequency']}'
              '|${(r['title'] as String).toLowerCase().trim()}')
          .toSet();

      final payloads = tasks.where((t) {
        final key =
            '${_taskTypeToLogCareType(t.taskType)}'
            '|${_frequencyToDbString(t.frequency)}'
            '|${t.title.toLowerCase().trim()}';
        return !existingTaskSet.contains(key);
      }).map((task) {
        final payload = Map<String, dynamic>.from(task.toJson())
          ..remove('id')
          ..remove('category_icon');
        if (isAiSuggested) payload['is_ai_suggested'] = true;
        return payload;
      }).toList();

      if (payloads.isEmpty) return [];

      final rows = await _client
          .from('care_tasks')
          .insert(payloads)
          .select();

      final savedTasks = rows.map((row) => CareTask.fromJson(row)).toList();
      for (final saved in savedTasks) {
        _scheduleNotificationIfNeeded(saved);
      }
      return savedTasks;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
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
      final saved = CareTask.fromJson(row);
      _scheduleNotificationIfNeeded(saved);
      return saved;
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
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
      NotificationService.instance.cancelForTask(taskId).ignore();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  // ── Dashboard snapshot (single-RPC fetch) ────────────────────────────────

  /// Fetches all care dashboard data in one `get_care_dashboard_snapshot` RPC
  /// call, replacing the previous four parallel round-trips.
  Future<CareDashboardSnapshot> fetchDashboardSnapshot({
    required String petId,
    required DateTime selectedDate,
    required List<DateTime> weekDates,
  }) async {
    try {
      _requireAuth();
      final dSel = DateUtils.dateOnly(selectedDate);
      final dToday = DateUtils.dateOnly(DateTime.now().toLocal());
      final weekDays = weekDates.map(DateUtils.dateOnly).toList();
      final minD = weekDays.reduce((a, b) => a.isBefore(b) ? a : b);
      final maxD = weekDays.reduce((a, b) => a.isAfter(b) ? a : b);

      final raw = await _client.rpc(
        'get_care_dashboard_snapshot',
        params: {
          'p_pet_id': petId,
          'p_selected_date': _fmtYmd(dSel),
          'p_week_start': _fmtYmd(minD),
          'p_week_end': _fmtYmd(maxD),
        },
      );

      final data = raw as Map<String, dynamic>;

      final definitions = (data['tasks'] as List)
          .cast<Map<String, dynamic>>()
          .map(CareTask.fromJson)
          .toList();

      final logsSelected =
          (data['logs_selected'] as List).cast<Map<String, dynamic>>();
      final tasks =
          _buildTasksFromSnapshotData(petId, definitions, logsSelected, dSel);

      final logsToday =
          (data['logs_today'] as List).cast<Map<String, dynamic>>();
      final todayTasks = dSel == dToday
          ? tasks
          : _buildTasksFromSnapshotData(
              petId, definitions, logsToday, dToday);

      final badgeTypes = (data['badge_types'] as List)
          .whereType<String>()
          .toSet();

      final logsWeek =
          (data['logs_week'] as List).cast<Map<String, dynamic>>();
      final weekGoalHit = _computeWeekGoalHitFromSnapshotData(
        definitions,
        logsWeek,
        weekDays,
      );

      return CareDashboardSnapshot(
        tasks: tasks,
        todayTasks: todayTasks,
        badgeTypes: badgeTypes,
        weekGoalHit: weekGoalHit,
      );
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  /// Builds the per-day task list (applies-on-day + done state) from
  /// pre-fetched snapshot data.
  List<CareTask> _buildTasksFromSnapshotData(
    String petId,
    List<CareTask> definitions,
    List<Map<String, dynamic>> logs,
    DateTime dayLocal,
  ) {
    final doneTypes = logs
        .map((r) => r['care_type'] as String?)
        .whereType<String>()
        .toSet();

    final out = <CareTask>[];
    for (final task in definitions) {
      if (!_appliesOnDay(task, dayLocal)) continue;
      final careType = _taskTypeToLogCareType(task.taskType);
      final fromLog = doneTypes.contains(careType);
      final done = _doneForDay(task, dayLocal, fromLog);
      out.add(task.copyWith(
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      ));
    }

    // Synthesise tasks for care types that appear in logs but have no
    // matching care_task definition (e.g. ad-hoc log entries).
    final byCareTypeFirstRow = <String, Map<String, dynamic>>{};
    for (final row in logs) {
      final ct = row['care_type'] as String?;
      if (ct == null) continue;
      byCareTypeFirstRow.putIfAbsent(ct, () => row);
    }
    for (final entry in byCareTypeFirstRow.entries) {
      final ct = entry.key;
      if (out.any((t) => _taskTypeToLogCareType(t.taskType) == ct)) continue;
      out.add(_careTaskFromLogRow(entry.value, petId, dayLocal));
    }

    out.sort((a, b) {
      final la = a.isLogDerived;
      final lb = b.isLogDerived;
      if (la != lb) return la ? 1 : -1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return out;
  }

  /// Computes whether each day's expected daily tasks were all completed,
  /// from pre-fetched snapshot data.
  List<bool> _computeWeekGoalHitFromSnapshotData(
    List<CareTask> definitions,
    List<Map<String, dynamic>> logsWeek,
    List<DateTime> weekDays,
  ) {
    final expected = <String>{};
    for (final task in definitions) {
      if (task.frequency == CareFrequency.daily ||
          task.frequency == CareFrequency.twiceDaily) {
        expected.add(_taskTypeToLogCareType(task.taskType));
      }
    }
    if (expected.isEmpty) {
      expected.addAll({'feeding', 'walk', 'medication'});
    }

    final byDay = <String, Set<String>>{};
    for (final d in weekDays) {
      byDay[_fmtYmd(d)] = {};
    }
    for (final row in logsWeek) {
      final day = _loggedDayKey(row['logged_date']);
      final ct = row['care_type'] as String?;
      if (day.isEmpty || ct == null) continue;
      byDay.putIfAbsent(day, () => {}).add(ct);
    }

    return weekDays.map((d) {
      final key = _fmtYmd(DateUtils.dateOnly(d));
      final done = byDay[key] ?? const {};
      return expected.every((e) => done.contains(e));
    }).toList();
  }

  static void _scheduleNotificationIfNeeded(CareTask task) {
    final raw = task.scheduledTime;
    if (raw == null || raw.isEmpty) return;
    final parts = raw.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final tod = TimeOfDay(hour: hour, minute: minute);
    final repeating = task.frequency == CareFrequency.daily ||
        task.frequency == CareFrequency.twiceDaily;

    NotificationService.instance.scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      tod: tod,
      repeating: repeating,
    ).ignore();
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

      var badgeUnlocked   = false;
      var unlockedBadges  = <String>[];

      if (isCompleted) {
        final raw = await _client.rpc(
          'check_daily_completion',
          params: {
            'target_pet_id':  petId,
            'completion_date': dayStr,
          },
        );
        if (raw is Map) {
          final v = raw['badge_unlocked'];
          badgeUnlocked = v == true || v == 'true';
          final arr = raw['unlocked_badges'];
          if (arr is List) {
            unlockedBadges = arr.whereType<String>().toList();
          }
        }
      }

      final merged = task.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
      return ToggleCompletionResult(
        task: merged,
        badgeUnlocked: badgeUnlocked,
        unlockedBadges: unlockedBadges,
      );
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }
}
