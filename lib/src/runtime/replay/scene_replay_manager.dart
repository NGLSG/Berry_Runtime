/// Scene Replay Manager
///
/// Manages scene unlock tracking and completion calculation.
/// Requirements: 1.2

import 'dart:async';

import 'replayable_scene.dart';

/// Scene replay manager
class SceneReplayManager {
  /// Scene definitions
  final List<ReplayableScene> _definitions;

  /// Unlocked scene IDs
  final Set<String> _unlockedIds;

  /// Unlock dates
  final Map<String, DateTime> _unlockDates;

  /// Event controller for scene unlocks
  final StreamController<SceneUnlockEvent> _unlockController =
      StreamController<SceneUnlockEvent>.broadcast();

  /// Stream of scene unlock events
  Stream<SceneUnlockEvent> get onSceneUnlock => _unlockController.stream;

  SceneReplayManager({
    List<ReplayableScene> definitions = const [],
    Set<String>? unlockedIds,
    Map<String, DateTime>? unlockDates,
  })  : _definitions = List.from(definitions),
        _unlockedIds = unlockedIds != null ? Set.from(unlockedIds) : {},
        _unlockDates = unlockDates != null ? Map.from(unlockDates) : {};

  /// Get all scene definitions
  List<ReplayableScene> get definitions => List.unmodifiable(_definitions);

  /// Get unlocked scene IDs
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  /// Get unlock dates
  Map<String, DateTime> get unlockDates => Map.unmodifiable(_unlockDates);

  /// Add a scene definition
  void addDefinition(ReplayableScene scene) {
    if (!_definitions.any((s) => s.id == scene.id)) {
      _definitions.add(scene);
    }
  }

  /// Add multiple scene definitions
  void addDefinitions(List<ReplayableScene> scenes) {
    for (final scene in scenes) {
      addDefinition(scene);
    }
  }

  /// Clear all definitions
  void clearDefinitions() {
    _definitions.clear();
  }

  /// Set definitions (replaces existing)
  void setDefinitions(List<ReplayableScene> scenes) {
    _definitions.clear();
    _definitions.addAll(scenes);
  }

  /// Check if a scene is unlocked
  bool isUnlocked(String sceneId) {
    return _unlockedIds.contains(sceneId);
  }

  /// Unlock a scene
  void unlockScene(String sceneId) {
    if (_unlockedIds.contains(sceneId)) return;

    _unlockedIds.add(sceneId);
    _unlockDates[sceneId] = DateTime.now();

    final scene = getSceneById(sceneId);
    _unlockController.add(SceneUnlockEvent(
      sceneId: sceneId,
      sceneName: scene?.title ?? sceneId,
      timestamp: DateTime.now(),
    ));
  }

  /// Unlock multiple scenes
  void unlockScenes(List<String> sceneIds) {
    for (final id in sceneIds) {
      unlockScene(id);
    }
  }

  /// Get unlock date for a scene
  DateTime? getUnlockDate(String sceneId) {
    return _unlockDates[sceneId];
  }

  /// Get scene by ID
  ReplayableScene? getSceneById(String sceneId) {
    try {
      return _definitions.firstWhere((s) => s.id == sceneId);
    } catch (_) {
      return null;
    }
  }

  /// Get completion percentage
  double get completionPercentage {
    if (_definitions.isEmpty) return 0.0;
    return _unlockedIds.length / _definitions.length;
  }

  /// Get completion percentage for a specific category
  double getCategoryCompletionPercentage(String category) {
    final categoryScenes =
        _definitions.where((s) => s.category == category).toList();
    if (categoryScenes.isEmpty) return 0.0;

    final unlockedCount =
        categoryScenes.where((s) => _unlockedIds.contains(s.id)).length;
    return unlockedCount / categoryScenes.length;
  }

  /// Get unlocked count
  int get unlockedCount => _unlockedIds.length;

  /// Get total count
  int get totalCount => _definitions.length;

  /// Get scene statuses (for UI display)
  List<SceneReplayStatus> getSceneStatuses() {
    return _definitions.map((scene) {
      return SceneReplayStatus(
        scene: scene,
        isUnlocked: _unlockedIds.contains(scene.id),
        unlockDate: _unlockDates[scene.id],
      );
    }).toList()
      ..sort((a, b) => a.scene.order.compareTo(b.scene.order));
  }

  /// Get scene statuses grouped by category
  Map<String, List<SceneReplayStatus>> getGroupedByCategory() {
    final grouped = <String, List<SceneReplayStatus>>{};
    final statuses = getSceneStatuses();

    for (final status in statuses) {
      final category = status.scene.category ?? 'Uncategorized';
      grouped.putIfAbsent(category, () => []).add(status);
    }

    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.scene.order.compareTo(b.scene.order));
    }

    return grouped;
  }

  /// Get scene statuses for a specific chapter
  List<SceneReplayStatus> getSceneStatusesForChapter(String chapterId) {
    return getSceneStatuses()
        .where((s) => s.scene.chapterId == chapterId)
        .toList();
  }

  /// Get all categories
  List<String> get categories {
    final cats = _definitions
        .map((s) => s.category ?? 'Uncategorized')
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'unlocked': _unlockedIds.toList(),
        'unlockDates': _unlockDates.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
      };

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    _unlockedIds.clear();
    _unlockDates.clear();

    final unlocked = json['unlocked'] as List?;
    if (unlocked != null) {
      _unlockedIds.addAll(unlocked.cast<String>());
    }

    final dates = json['unlockDates'] as Map<String, dynamic>?;
    if (dates != null) {
      for (final entry in dates.entries) {
        _unlockDates[entry.key] = DateTime.parse(entry.value as String);
      }
    }
  }

  /// Create from JSON with definitions
  factory SceneReplayManager.fromJsonWithDefinitions(
    Map<String, dynamic> json,
    List<ReplayableScene> definitions,
  ) {
    final manager = SceneReplayManager(definitions: definitions);
    manager.fromJson(json);
    return manager;
  }

  /// Reset all unlock data
  void reset() {
    _unlockedIds.clear();
    _unlockDates.clear();
  }

  /// Dispose resources
  void dispose() {
    _unlockController.close();
  }
}

/// Scene unlock event
class SceneUnlockEvent {
  final String sceneId;
  final String sceneName;
  final DateTime timestamp;

  const SceneUnlockEvent({
    required this.sceneId,
    required this.sceneName,
    required this.timestamp,
  });
}
