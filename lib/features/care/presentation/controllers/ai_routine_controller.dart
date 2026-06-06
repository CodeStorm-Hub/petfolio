import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/models/pet.dart';
import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/domain/services/care_recommendation_service.dart';

class AiSuggestion {
  AiSuggestion({
    required this.task,
    required this.isDuplicate,
    this.conflictTitle,
    bool? isSelected,
  }) : isSelected = isSelected ?? false;

  final CareTask task;
  final bool isDuplicate;
  final String? conflictTitle;
  bool isSelected;

  AiSuggestion copyWith({bool? isSelected}) => AiSuggestion(
        task: task,
        isDuplicate: isDuplicate,
        conflictTitle: conflictTitle,
        isSelected: isSelected ?? this.isSelected,
      );
}

enum AiRoutineStatus { idle, loading, success, error }

class AiRoutineState {
  const AiRoutineState({
    this.status = AiRoutineStatus.idle,
    this.suggestions = const [],
    this.error,
    this.isConfigError = false,
    this.cachedForPetId,
    this.cachedAt,
  });

  final AiRoutineStatus status;
  final List<AiSuggestion> suggestions;
  final String? error;
  final bool isConfigError;
  final String? cachedForPetId;
  final DateTime? cachedAt;

  bool get isLoading => status == AiRoutineStatus.loading;
  bool get hasError => status == AiRoutineStatus.error;
  bool get hasResults => status == AiRoutineStatus.success && suggestions.isNotEmpty;

  bool isCacheValid(String petId) {
    if (cachedForPetId != petId) return false;
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) < const Duration(hours: 24);
  }

  AiRoutineState copyWith({
    AiRoutineStatus? status,
    List<AiSuggestion>? suggestions,
    String? error,
    bool? isConfigError,
    String? cachedForPetId,
    DateTime? cachedAt,
  }) =>
      AiRoutineState(
        status: status ?? this.status,
        suggestions: suggestions ?? this.suggestions,
        error: error ?? this.error,
        isConfigError: isConfigError ?? this.isConfigError,
        cachedForPetId: cachedForPetId ?? this.cachedForPetId,
        cachedAt: cachedAt ?? this.cachedAt,
      );
}

class AiRoutineNotifier extends Notifier<AiRoutineState> {

  @override
  AiRoutineState build() => const AiRoutineState();

  Future<void> generate(Pet pet, List<CareTask> existingTasks) async {
    if (state.isCacheValid(pet.id)) return;
    if (state.isLoading) return; // already in-flight — callers should watch state

    state = state.copyWith(status: AiRoutineStatus.loading, error: null, isConfigError: false);

    try {
      final service = ref.read(careRecommendationServiceProvider);
      final result = await service.generateRecommendations(pet);
      // Use the DB-sourced existing titles (all tasks, not just today's view)
      // so weekly/monthly tasks that don't apply today are still caught as dupes.
      final suggestions = _buildSuggestions(result.suggestions, result.existingNormalised);
      state = state.copyWith(
        status: AiRoutineStatus.success,
        suggestions: suggestions,
        cachedForPetId: pet.id,
        cachedAt: DateTime.now(),
      );
    } on CareRecommendationException catch (e) {
      state = state.copyWith(
        status: AiRoutineStatus.error,
        error: e.message,
        isConfigError: e.isConfigError,
      );
    } catch (e) {
      state = state.copyWith(
        status: AiRoutineStatus.error,
        error: 'Could not generate care suggestions. Please try again.',
      );
    }
  }

  Future<void> forceRefresh(Pet pet, List<CareTask> existingTasks) async {
    state = const AiRoutineState();
    await generate(pet, existingTasks);
  }

  void invalidateCache() {
    if (state.status == AiRoutineStatus.success) {
      state = const AiRoutineState();
    }
  }

  void toggleSelection(String taskId) {
    final updated = state.suggestions.map((s) {
      if (s.task.id == taskId) return s.copyWith(isSelected: !s.isSelected);
      return s;
    }).toList();
    state = state.copyWith(suggestions: updated);
  }

  void selectAll() {
    final updated = state.suggestions
        .map((s) => s.isDuplicate ? s : s.copyWith(isSelected: true))
        .toList();
    state = state.copyWith(suggestions: updated);
  }

  void deselectAll() {
    final updated = state.suggestions.map((s) => s.copyWith(isSelected: false)).toList();
    state = state.copyWith(suggestions: updated);
  }

  List<AiSuggestion> get selectedSuggestions =>
      state.suggestions.where((s) => s.isSelected && !s.isDuplicate).toList();

  /// Builds AiSuggestion list from raw AI tasks, marking duplicates against
  /// the full set of normalised existing task titles from the DB.
  static List<AiSuggestion> _buildSuggestions(
    List<CareTask> rawTasks,
    Set<String> existingNormalised,
  ) {
    return rawTasks.map((task) {
      final isDupe = _isDuplicate(task.title, existingNormalised);
      return AiSuggestion(
        task: task,
        isDuplicate: isDupe,
        conflictTitle: isDupe ? task.title : null,
        isSelected: false,
      );
    }).toList();
  }

  /// Returns true if the candidate title is similar enough to any existing
  /// normalised title to count as a duplicate.
  static bool _isDuplicate(String candidateTitle, Set<String> existingNormalised) {
    final norm = _normalize(candidateTitle);
    if (existingNormalised.contains(norm)) return true;
    // Fuzzy: candidate is a substring of existing or vice-versa (catches
    // "Morning Feeding" vs "Morning Feed", "Dental Care" vs "Dental", etc.)
    for (final e in existingNormalised) {
      if (_similarity(norm, e) >= 0.80) return true;
    }
    return false;
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static double _similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;
    if (a.contains(b) || b.contains(a)) return 0.85;
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    int matches = 0;
    for (var i = 0; i < shorter.length; i++) {
      if (longer.contains(shorter[i])) matches++;
    }
    return matches / longer.length;
  }
}

final aiRoutineProvider = NotifierProvider<AiRoutineNotifier, AiRoutineState>(
  AiRoutineNotifier.new,
);
