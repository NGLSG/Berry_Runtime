/// Achievement Condition System for VNBS
///
/// Defines various condition types for achievement unlocking.
/// Requirements: 2.2, 2.3, 2.7

import '../progress/global_progress_manager.dart';

/// Game state interface for condition evaluation
abstract class GameState {
  /// Get a variable value by name
  dynamic getVariable(String name);

  /// Get all variable names
  Set<String> get variableNames;
}

/// Base class for achievement conditions
abstract class AchievementCondition {
  const AchievementCondition();

  /// Evaluate if the condition is met
  bool evaluate(GameState state, GlobalProgressManager progress);

  /// Get progress towards completion (0.0 - 1.0)
  double getProgress(GameState state, GlobalProgressManager progress);

  /// Convert to JSON
  Map<String, dynamic> toJson();

  /// Create from JSON
  factory AchievementCondition.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'manual':
        return ManualAchievementCondition.fromJson(json);
      case 'variable':
        return VariableCondition.fromJson(json);
      case 'endingCount':
        return EndingCountCondition.fromJson(json);
      case 'readPercentage':
        return ReadPercentageCondition.fromJson(json);
      case 'playTime':
        return PlayTimeCondition.fromJson(json);
      case 'allOf':
        return AllOfCondition.fromJson(json);
      case 'anyOf':
        return AnyOfCondition.fromJson(json);
      case 'sceneUnlocked':
        return SceneUnlockedCondition.fromJson(json);
      case 'cgUnlocked':
        return CGUnlockedCondition.fromJson(json);
      default:
        return const ManualAchievementCondition();
    }
  }

  /// Factory constructors for convenience
  static AchievementCondition manual() => const ManualAchievementCondition();

  static AchievementCondition variable(String name, dynamic value,
          {VariableComparison comparison = VariableComparison.equals}) =>
      VariableCondition(name: name, value: value, comparison: comparison);

  static AchievementCondition endingCount(int count) =>
      EndingCountCondition(requiredCount: count);

  static AchievementCondition readPercentage(double percentage) =>
      ReadPercentageCondition(requiredPercentage: percentage);

  static AchievementCondition playTime(Duration duration) =>
      PlayTimeCondition(requiredDuration: duration);

  static AchievementCondition allOf(List<AchievementCondition> conditions) =>
      AllOfCondition(conditions: conditions);

  static AchievementCondition anyOf(List<AchievementCondition> conditions) =>
      AnyOfCondition(conditions: conditions);
}

/// Manual achievement - unlocked only via explicit trigger
class ManualAchievementCondition extends AchievementCondition {
  const ManualAchievementCondition();

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) => false;

  @override
  double getProgress(GameState state, GlobalProgressManager progress) => 0.0;

  @override
  Map<String, dynamic> toJson() => {'type': 'manual'};

  factory ManualAchievementCondition.fromJson(Map<String, dynamic> json) {
    return const ManualAchievementCondition();
  }
}

/// Variable comparison types
enum VariableComparison {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
}

/// Variable-based condition
class VariableCondition extends AchievementCondition {
  final String name;
  final dynamic value;
  final VariableComparison comparison;

  const VariableCondition({
    required this.name,
    required this.value,
    this.comparison = VariableComparison.equals,
  });

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    final currentValue = state.getVariable(name);
    if (currentValue == null) return false;

    switch (comparison) {
      case VariableComparison.equals:
        return currentValue == value;
      case VariableComparison.notEquals:
        return currentValue != value;
      case VariableComparison.greaterThan:
        return _compareNumeric(currentValue, value) > 0;
      case VariableComparison.greaterThanOrEquals:
        return _compareNumeric(currentValue, value) >= 0;
      case VariableComparison.lessThan:
        return _compareNumeric(currentValue, value) < 0;
      case VariableComparison.lessThanOrEquals:
        return _compareNumeric(currentValue, value) <= 0;
    }
  }

  int _compareNumeric(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    return 0;
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    if (evaluate(state, progress)) return 1.0;

    // For numeric comparisons, calculate progress
    if (value is num) {
      final currentValue = state.getVariable(name);
      if (currentValue is num && value != 0) {
        switch (comparison) {
          case VariableComparison.greaterThan:
          case VariableComparison.greaterThanOrEquals:
            return (currentValue / (value as num)).clamp(0.0, 1.0);
          default:
            break;
        }
      }
    }
    return 0.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'variable',
        'name': name,
        'value': value,
        'comparison': comparison.name,
      };

  factory VariableCondition.fromJson(Map<String, dynamic> json) {
    return VariableCondition(
      name: json['name'] as String,
      value: json['value'],
      comparison: VariableComparison.values.firstWhere(
        (e) => e.name == json['comparison'],
        orElse: () => VariableComparison.equals,
      ),
    );
  }
}


/// Ending count condition - requires reaching N endings
class EndingCountCondition extends AchievementCondition {
  final int requiredCount;

  const EndingCountCondition({required this.requiredCount});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    return progress.data.endings.reachedIds.length >= requiredCount;
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    if (requiredCount <= 0) return 1.0;
    return (progress.data.endings.reachedIds.length / requiredCount)
        .clamp(0.0, 1.0);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'endingCount',
        'requiredCount': requiredCount,
      };

  factory EndingCountCondition.fromJson(Map<String, dynamic> json) {
    return EndingCountCondition(
      requiredCount: json['requiredCount'] as int? ?? 1,
    );
  }
}

/// Read percentage condition - requires reading N% of dialogues
class ReadPercentageCondition extends AchievementCondition {
  final double requiredPercentage;
  final int? totalDialogues;

  const ReadPercentageCondition({
    required this.requiredPercentage,
    this.totalDialogues,
  });

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    final total = totalDialogues ?? _getTotalFromState(state);
    if (total <= 0) return false;

    final readCount = progress.data.statistics.uniqueDialoguesRead.length;
    final percentage = readCount / total;
    return percentage >= requiredPercentage;
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    final total = totalDialogues ?? _getTotalFromState(state);
    if (total <= 0) return 0.0;

    final readCount = progress.data.statistics.uniqueDialoguesRead.length;
    final currentPercentage = readCount / total;
    return (currentPercentage / requiredPercentage).clamp(0.0, 1.0);
  }

  int _getTotalFromState(GameState state) {
    // Try to get total dialogues from game state
    final total = state.getVariable('_totalDialogues');
    return total is int ? total : 0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'readPercentage',
        'requiredPercentage': requiredPercentage,
        if (totalDialogues != null) 'totalDialogues': totalDialogues,
      };

  factory ReadPercentageCondition.fromJson(Map<String, dynamic> json) {
    return ReadPercentageCondition(
      requiredPercentage: (json['requiredPercentage'] as num?)?.toDouble() ?? 0.5,
      totalDialogues: json['totalDialogues'] as int?,
    );
  }
}

/// Play time condition - requires playing for N duration
class PlayTimeCondition extends AchievementCondition {
  final Duration requiredDuration;

  const PlayTimeCondition({required this.requiredDuration});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    return progress.data.statistics.totalPlayTime >= requiredDuration;
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    if (requiredDuration.inMilliseconds <= 0) return 1.0;
    return (progress.data.statistics.totalPlayTimeMs /
            requiredDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playTime',
        'requiredDurationMs': requiredDuration.inMilliseconds,
      };

  factory PlayTimeCondition.fromJson(Map<String, dynamic> json) {
    return PlayTimeCondition(
      requiredDuration: Duration(
        milliseconds: json['requiredDurationMs'] as int? ?? 0,
      ),
    );
  }
}

/// All-of condition - all sub-conditions must be met
class AllOfCondition extends AchievementCondition {
  final List<AchievementCondition> conditions;

  const AllOfCondition({required this.conditions});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    if (conditions.isEmpty) return true;
    return conditions.every((c) => c.evaluate(state, progress));
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    if (conditions.isEmpty) return 1.0;
    final total = conditions.fold<double>(
      0.0,
      (sum, c) => sum + c.getProgress(state, progress),
    );
    return total / conditions.length;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'allOf',
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory AllOfCondition.fromJson(Map<String, dynamic> json) {
    return AllOfCondition(
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((c) =>
                  AchievementCondition.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Any-of condition - at least one sub-condition must be met
class AnyOfCondition extends AchievementCondition {
  final List<AchievementCondition> conditions;

  const AnyOfCondition({required this.conditions});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    if (conditions.isEmpty) return false;
    return conditions.any((c) => c.evaluate(state, progress));
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    if (conditions.isEmpty) return 0.0;
    // Return the maximum progress among all conditions
    return conditions.fold<double>(
      0.0,
      (max, c) {
        final p = c.getProgress(state, progress);
        return p > max ? p : max;
      },
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'anyOf',
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory AnyOfCondition.fromJson(Map<String, dynamic> json) {
    return AnyOfCondition(
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((c) =>
                  AchievementCondition.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Scene unlocked condition - requires a specific scene to be unlocked
class SceneUnlockedCondition extends AchievementCondition {
  final String sceneId;

  const SceneUnlockedCondition({required this.sceneId});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    return progress.isSceneUnlocked(sceneId);
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    return evaluate(state, progress) ? 1.0 : 0.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'sceneUnlocked',
        'sceneId': sceneId,
      };

  factory SceneUnlockedCondition.fromJson(Map<String, dynamic> json) {
    return SceneUnlockedCondition(
      sceneId: json['sceneId'] as String,
    );
  }
}

/// CG unlocked condition - requires a specific CG to be unlocked
class CGUnlockedCondition extends AchievementCondition {
  final String cgId;

  const CGUnlockedCondition({required this.cgId});

  @override
  bool evaluate(GameState state, GlobalProgressManager progress) {
    return progress.isCGUnlocked(cgId);
  }

  @override
  double getProgress(GameState state, GlobalProgressManager progress) {
    return evaluate(state, progress) ? 1.0 : 0.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cgUnlocked',
        'cgId': cgId,
      };

  factory CGUnlockedCondition.fromJson(Map<String, dynamic> json) {
    return CGUnlockedCondition(
      cgId: json['cgId'] as String,
    );
  }
}
