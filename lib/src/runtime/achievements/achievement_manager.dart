/// Achievement Manager for VNBS
///
/// Manages achievement definitions, unlocking, and progress tracking.
/// Requirements: 2.3, 2.6, 2.7

import 'dart:async';

import 'achievement.dart';
import 'achievement_condition.dart';
import '../progress/global_progress_manager.dart';

/// Achievement Manager
///
/// Manages all achievements for a VN project, including:
/// - Achievement definitions
/// - Unlock logic and condition evaluation
/// - Progress calculation
/// - Event streaming for UI notifications
class AchievementManager {
  /// Achievement definitions
  final List<Achievement> _definitions;

  /// Reference to global progress manager
  final GlobalProgressManager _progressManager;

  /// Stream controller for unlock events
  final StreamController<Achievement> _unlockController =
      StreamController<Achievement>.broadcast();

  /// Stream of achievement unlock events
  Stream<Achievement> get onUnlock => _unlockController.stream;

  AchievementManager({
    required List<Achievement> definitions,
    required GlobalProgressManager progressManager,
  })  : _definitions = List.from(definitions),
        _progressManager = progressManager;

  /// Get all achievement definitions
  List<Achievement> get definitions => List.unmodifiable(_definitions);

  /// Get achievement by ID
  Achievement? getById(String id) {
    try {
      return _definitions.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if an achievement is unlocked
  bool isUnlocked(String achievementId) {
    return _progressManager.isAchievementUnlocked(achievementId);
  }

  /// Get unlock date for an achievement
  DateTime? getUnlockDate(String achievementId) {
    return _progressManager.getAchievementUnlockDate(achievementId);
  }

  /// Manually unlock an achievement
  ///
  /// Use this for achievements triggered by Achievement_Node in the story.
  void unlock(String achievementId) {
    if (isUnlocked(achievementId)) return;

    final achievement = getById(achievementId);
    if (achievement == null) return;

    _progressManager.unlockAchievement(achievementId, name: achievement.name);
    _unlockController.add(achievement);
  }

  /// Check and unlock achievements based on current game state
  ///
  /// Call this after game state changes to evaluate automatic conditions.
  void checkAchievements(GameState state) {
    for (final achievement in _definitions) {
      if (isUnlocked(achievement.id)) continue;

      // Skip manual achievements - they must be explicitly unlocked
      if (achievement.condition is ManualAchievementCondition) continue;

      if (achievement.condition.evaluate(state, _progressManager)) {
        unlock(achievement.id);
      }
    }
  }

  /// Get progress for a specific achievement
  double getProgress(String achievementId, GameState state) {
    if (isUnlocked(achievementId)) return 1.0;

    final achievement = getById(achievementId);
    if (achievement == null) return 0.0;

    return achievement.condition.getProgress(state, _progressManager);
  }

  /// Get status for all achievements
  List<AchievementStatus> getAllStatuses(GameState state) {
    return _definitions.map((achievement) {
      final unlocked = isUnlocked(achievement.id);
      return AchievementStatus(
        achievement: achievement,
        isUnlocked: unlocked,
        unlockDate: unlocked ? getUnlockDate(achievement.id) : null,
        progress: unlocked ? 1.0 : getProgress(achievement.id, state),
      );
    }).toList();
  }

  /// Get achievements grouped by category
  Map<String, List<AchievementStatus>> getGroupedAchievements(GameState state) {
    final statuses = getAllStatuses(state);
    final grouped = <String, List<AchievementStatus>>{};

    for (final status in statuses) {
      final category = status.achievement.category ?? 'General';
      grouped.putIfAbsent(category, () => []).add(status);
    }

    // Sort each category by unlock status (unlocked first) then by name
    for (final list in grouped.values) {
      list.sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        return a.achievement.name.compareTo(b.achievement.name);
      });
    }

    return grouped;
  }

  /// Get visible achievements (excludes hidden achievements that aren't unlocked)
  List<AchievementStatus> getVisibleAchievements(GameState state) {
    return getAllStatuses(state).where((s) => s.isVisible).toList();
  }

  /// Get total points possible
  int get totalPoints => _definitions.fold(0, (sum, a) => sum + a.points);

  /// Get earned points
  int get earnedPoints {
    return _definitions.fold(0, (sum, a) {
      return sum + (isUnlocked(a.id) ? a.points : 0);
    });
  }

  /// Get completion percentage
  double get completionPercentage {
    if (_definitions.isEmpty) return 0.0;
    final unlocked = _definitions.where((a) => isUnlocked(a.id)).length;
    return unlocked / _definitions.length;
  }

  /// Get unlocked count
  int get unlockedCount {
    return _definitions.where((a) => isUnlocked(a.id)).length;
  }

  /// Get total count
  int get totalCount => _definitions.length;

  /// Add a new achievement definition
  void addDefinition(Achievement achievement) {
    if (_definitions.any((a) => a.id == achievement.id)) {
      throw ArgumentError('Achievement with id ${achievement.id} already exists');
    }
    _definitions.add(achievement);
  }

  /// Remove an achievement definition
  bool removeDefinition(String achievementId) {
    final lengthBefore = _definitions.length;
    _definitions.removeWhere((a) => a.id == achievementId);
    return _definitions.length < lengthBefore;
  }

  /// Update an achievement definition
  void updateDefinition(Achievement achievement) {
    final index = _definitions.indexWhere((a) => a.id == achievement.id);
    if (index >= 0) {
      _definitions[index] = achievement;
    }
  }

  /// Export definitions to JSON
  List<Map<String, dynamic>> exportDefinitions() {
    return _definitions.map((a) => a.toJson()).toList();
  }

  /// Import definitions from JSON
  void importDefinitions(List<dynamic> jsonList) {
    _definitions.clear();
    for (final json in jsonList) {
      _definitions.add(Achievement.fromJson(json as Map<String, dynamic>));
    }
  }

  /// Dispose resources
  void dispose() {
    _unlockController.close();
  }
}

/// Simple game state implementation for testing
class SimpleGameState implements GameState {
  final Map<String, dynamic> _variables;

  SimpleGameState([Map<String, dynamic>? variables])
      : _variables = variables ?? {};

  @override
  dynamic getVariable(String name) => _variables[name];

  @override
  Set<String> get variableNames => _variables.keys.toSet();

  void setVariable(String name, dynamic value) {
    _variables[name] = value;
  }
}
