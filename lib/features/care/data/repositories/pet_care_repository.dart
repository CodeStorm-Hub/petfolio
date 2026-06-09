import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/platform/platform_notifications.dart';
import '../models/care_streak.dart';
import '../models/care_task.dart';

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

  /// Public accessor used by callers that need the DB snake_case care_type
  /// from an enum value (e.g. the dashboard controller pre-resolving it before
  /// calling [toggleCompletion]).
  String taskTypeToCareType(CareTaskType t) => _taskTypeToLogCareType(t);

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

  static bool _appliesOnDay(CareTask task, DateTime dayLocal) =>
      task.appliesToDay(dayLocal);

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

      // Today's local date — used to anchor new tasks so they always
      // appear on the correct day of week / month regardless of the UTC
      // offset between the client and the Supabase server.
      final todayLocal = DateUtils.dateOnly(DateTime.now().toLocal());
      final todayStr = _fmtYmd(todayLocal);

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
        // Always pin anchor_date to today (local). Without this, the DB
        // stores NULL and effectiveAnchor falls back to created_at UTC,
        // which may differ by a day in positive-offset timezones — causing
        // weekly tasks to only appear on the wrong day of the week.
        if (payload['anchor_date'] == null) {
          payload['anchor_date'] = todayStr;
        }
        if (isAiSuggested) payload['is_ai_suggested'] = true;
        return payload;
      }).toList();

      if (payloads.isEmpty) return [];

      // The DB unique index uses an expression (lower(btrim(title))) which
      // cannot be referenced by column name in onConflict. Use ignoreDuplicates
      // so Postgres generates ON CONFLICT DO NOTHING against any constraint.
      // The client-side pre-filter above is a best-effort optimisation only.
      final rows = await _client
          .from('care_tasks')
          .upsert(payloads, ignoreDuplicates: true)
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
      // Cancel old notification before scheduling the (possibly new) time.
      PlatformNotifications.instance.cancelForTask(saved.id).ignore();
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
      PlatformNotifications.instance.cancelForTask(taskId).ignore();
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
          'p_client_today': _fmtYmd(dToday),
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
    // Primary: task_id-based map (new schema — one log entry per real task per day).
    // Fallback: care_type-based map for legacy null-task_id entries and
    // log-derived synthetic tasks.
    final logByTaskId = <String, DateTime?>{};
    final logByType = <String, DateTime?>{};

    for (final row in logs) {
      final taskId = row['task_id'] as String?;
      final ct = row['care_type'] as String?;
      final raw = row['occurred_at'];
      final ts = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
      if (taskId != null) {
        logByTaskId.putIfAbsent(taskId, () => ts);
      }
      if (ct != null) {
        logByType.putIfAbsent(ct, () => ts);
      }
    }

    // Count how many applicable tasks share each care_type on this day.
    // Used to guard legacy care_type fallback: if multiple tasks share the
    // same care_type, one log entry cannot reliably say which task was done.
    final taskCountByCareType = <String, int>{};
    for (final task in definitions) {
      if (!_appliesOnDay(task, dayLocal)) continue;
      final ct = _taskTypeToLogCareType(task.taskType);
      taskCountByCareType[ct] = (taskCountByCareType[ct] ?? 0) + 1;
    }

    final out = <CareTask>[];
    for (final task in definitions) {
      if (!_appliesOnDay(task, dayLocal)) continue;
      final careType = _taskTypeToLogCareType(task.taskType);

      final bool fromLog;
      final DateTime? loggedAt;

      if (logByTaskId.containsKey(task.id)) {
        // New schema: this task has its own log entry — unambiguous.
        fromLog = true;
        loggedAt = logByTaskId[task.id];
      } else {
        // Legacy fallback (null-task_id logs from before the task_id migration).
        // Only trust care_type matching when exactly one task of this type
        // exists today — otherwise it's ambiguous which task was completed.
        final count = taskCountByCareType[careType] ?? 0;
        fromLog = count == 1 && logByType.containsKey(careType);
        loggedAt = fromLog ? logByType[careType] : null;
      }

      final done = _doneForDay(task, dayLocal, fromLog);
      out.add(task.copyWith(
        isCompleted: done,
        completedAt: done ? (loggedAt ?? task.completedAt) : null,
      ));
    }

    // Synthesise tasks for log entries with no matching care_task definition
    // (ad-hoc entries that have no real task — always null task_id).
    final byCareTypeFirstRow = <String, Map<String, dynamic>>{};
    for (final row in logs) {
      final taskId = row['task_id'] as String?;
      if (taskId != null) continue; // skip real-task logs
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
    // Collect all daily tasks grouped by care_type to detect ambiguity.
    final dailyTasks = definitions
        .where((t) =>
            t.frequency == CareFrequency.daily ||
            t.frequency == CareFrequency.twiceDaily)
        .toList();

    if (dailyTasks.isEmpty) {
      return List.filled(weekDays.length, true);
    }

    // Count tasks per care_type to know when legacy care_type fallback is safe.
    final dailyCountByCareType = <String, int>{};
    for (final task in dailyTasks) {
      final ct = _taskTypeToLogCareType(task.taskType);
      dailyCountByCareType[ct] = (dailyCountByCareType[ct] ?? 0) + 1;
    }

    // Build per-day lookup maps (both task_id and care_type).
    final byDayTaskIds = <String, Set<String>>{};
    final byDayCareTypes = <String, Set<String>>{};
    for (final d in weekDays) {
      byDayTaskIds[_fmtYmd(d)] = {};
      byDayCareTypes[_fmtYmd(d)] = {};
    }
    for (final row in logsWeek) {
      final day = _loggedDayKey(row['logged_date']);
      if (day.isEmpty) continue;
      final taskId = row['task_id'] as String?;
      final ct = row['care_type'] as String?;
      if (taskId != null) byDayTaskIds.putIfAbsent(day, () => {}).add(taskId);
      if (ct != null) byDayCareTypes.putIfAbsent(day, () => {}).add(ct);
    }

    return weekDays.map((d) {
      final key = _fmtYmd(DateUtils.dateOnly(d));
      final completedIds = byDayTaskIds[key] ?? const <String>{};
      final completedTypes = byDayCareTypes[key] ?? const <String>{};

      return dailyTasks.every((task) {
        // Primary: task_id log (new schema — unambiguous).
        if (completedIds.contains(task.id)) return true;

        // Legacy fallback: care_type log, only when unambiguous (1 task of type).
        final ct = _taskTypeToLogCareType(task.taskType);
        final count = dailyCountByCareType[ct] ?? 0;
        return count == 1 && completedTypes.contains(ct);
      });
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

    PlatformNotifications.instance.scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      tod: tod,
      repeating: repeating,
    ).ignore();
  }

  /// Toggles task completion via a single `toggle_care_task` RPC call.
  ///
  /// [careType] must be the DB snake_case string (e.g. 'vet_visit') and is
  /// provided by the caller (already known from the local dashboard state),
  /// avoiding an extra round-trip to fetch the task row.
  Future<ToggleCompletionResult> toggleCompletion(
    String taskId, {
    required bool isCompleted,
    required String petId,
    required String careType,
    required DateTime forDay,
    required CareTask localTask,
  }) async {
    try {
      _requireAuth();
      final now = DateTime.now();
      final occurredAt = now.toUtc();
      final day = DateUtils.dateOnly(forDay);

      final raw = await _client.rpc(
        'toggle_care_task',
        params: {
          'p_task_id':      taskId,
          'p_pet_id':       petId,
          'p_care_type':    careType,
          'p_is_completed': isCompleted,
          'p_day':          _fmtYmd(day),
          'p_occurred_at':  occurredAt.toIso8601String(),
        },
      );

      if (raw == null) throw const NetworkException(message: 'Empty RPC response');

      final result = raw as Map<String, dynamic>;
      final badgeUnlocked = result['badge_unlocked'] == true;
      final unlockedBadges = (result['unlocked_badges'] as List?)
              ?.whereType<String>()
              .toList() ??
          [];

      final rawCompletedAt = result['completed_at'];
      final completedAt = rawCompletedAt is String
          ? DateTime.tryParse(rawCompletedAt)?.toLocal()
          : null;

      final merged = localTask.copyWith(
        isCompleted: isCompleted,
        completedAt: completedAt,
        updatedAt: now,
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
