/// Affection Manager for VNBS Affection System
///
/// Manages affection values, threshold detection, and events.
/// Requirements: 18.2, 18.4

import 'dart:async';

import 'affection_definition.dart';
import 'affection_threshold.dart';
import 'affection_change_event.dart';
import '../progress/global_progress_manager.dart';

/// Manages affection values for all characters
///
/// Provides:
/// - Affection value management with bounds checking
/// - Threshold detection and events
/// - Integration with GlobalProgressManager for persistence
/// - Event streaming for UI notifications
class AffectionManager {
  /// Affection definitions for all characters
  final List<AffectionDefinition> _definitions;

  /// Reference to global progress manager for persistence
  final GlobalProgressManager _progressManager;

  /// Stream controller for affection change events
  final StreamController<AffectionChangeEvent> _changeController =
      StreamController<AffectionChangeEvent>.broadcast();

  /// Stream controller for threshold crossed events
  final StreamController<ThresholdCrossedEvent> _thresholdController =
      StreamController<ThresholdCrossedEvent>.broadcast();

  /// Stream of affection change events
  Stream<AffectionChangeEvent> get onAffectionChange => _changeController.stream;

  /// Stream of threshold crossed events
  Stream<ThresholdCrossedEvent> get onThresholdCrossed =>
      _thresholdController.stream;

  AffectionManager({
    required List<AffectionDefinition> definitions,
    required GlobalProgressManager progressManager,
  })  : _definitions = List.from(definitions),
        _progressManager = progressManager {
    // Initialize default values for any characters not yet in progress
    _initializeDefaults();
  }

  /// Initialize default values for characters
  void _initializeDefaults() {
    for (final def in _definitions) {
      final current = _progressManager.getAffection(def.characterId);
      if (current == 0 && def.defaultValue != 0) {
        // Set default value without triggering events
        _progressManager.setAffection(def.characterId, def.defaultValue);
      }
    }
  }

  /// Get all affection definitions
  List<AffectionDefinition> get definitions => List.unmodifiable(_definitions);

  /// Get definition for a character
  AffectionDefinition? getDefinition(String characterId) {
    try {
      return _definitions.firstWhere((d) => d.characterId == characterId);
    } catch (_) {
      return null;
    }
  }

  /// Get current affection value for a character
  int getValue(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return 0;

    final value = _progressManager.getAffection(characterId);
    return def.clampValue(value);
  }

  /// Set affection value for a character
  ///
  /// Returns the AffectionChangeEvent if the value changed, null otherwise.
  AffectionChangeEvent? setValue(String characterId, int value) {
    final def = getDefinition(characterId);
    if (def == null) return null;

    final oldValue = getValue(characterId);
    final newValue = def.clampValue(value);

    if (oldValue == newValue) return null;

    // Detect crossed thresholds
    final crossedThresholds = _detectCrossedThresholds(def, oldValue, newValue);

    // Update value in progress manager
    _progressManager.setAffection(characterId, newValue);

    // Create and emit change event
    final event = AffectionChangeEvent(
      characterId: characterId,
      characterName: def.characterName,
      oldValue: oldValue,
      newValue: newValue,
      crossedThresholds: crossedThresholds,
    );

    _changeController.add(event);

    // Emit individual threshold events
    for (final threshold in crossedThresholds) {
      final thresholdEvent = ThresholdCrossedEvent(
        characterId: characterId,
        characterName: def.characterName,
        threshold: threshold,
        isUpward: newValue > oldValue,
        currentValue: newValue,
      );
      _thresholdController.add(thresholdEvent);

      // Handle threshold unlocks
      _handleThresholdUnlocks(threshold);
    }

    return event;
  }

  /// Add to affection value for a character
  ///
  /// Returns the AffectionChangeEvent if the value changed, null otherwise.
  AffectionChangeEvent? addValue(String characterId, int delta) {
    final currentValue = getValue(characterId);
    return setValue(characterId, currentValue + delta);
  }

  /// Subtract from affection value for a character
  ///
  /// Returns the AffectionChangeEvent if the value changed, null otherwise.
  AffectionChangeEvent? subtractValue(String characterId, int delta) {
    return addValue(characterId, -delta);
  }

  /// Detect thresholds crossed between old and new values
  List<AffectionThreshold> _detectCrossedThresholds(
    AffectionDefinition def,
    int oldValue,
    int newValue,
  ) {
    final crossed = <AffectionThreshold>[];

    for (final threshold in def.thresholds) {
      // Check if threshold was crossed (in either direction)
      final wasBelow = oldValue < threshold.value;
      final isBelow = newValue < threshold.value;

      if (wasBelow != isBelow) {
        crossed.add(threshold);
      }
    }

    // Sort by value (ascending for increases, descending for decreases)
    if (newValue > oldValue) {
      crossed.sort((a, b) => a.value.compareTo(b.value));
    } else {
      crossed.sort((a, b) => b.value.compareTo(a.value));
    }

    return crossed;
  }

  /// Handle unlocks triggered by crossing a threshold
  void _handleThresholdUnlocks(AffectionThreshold threshold) {
    if (threshold.unlocksAchievement != null) {
      _progressManager.unlockAchievement(threshold.unlocksAchievement!);
    }

    if (threshold.unlocksScene != null) {
      _progressManager.unlockScene(threshold.unlocksScene!);
    }

    // Note: unlocksContent is handled by the game logic, not here
  }

  /// Get current threshold label for a character
  String? getCurrentThresholdLabel(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return null;

    final value = getValue(characterId);
    final threshold = def.getThresholdForValue(value);
    return threshold?.label;
  }

  /// Get affection percentage for a character (0.0 - 1.0)
  double getPercentage(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return 0.0;

    final value = getValue(characterId);
    return def.getPercentage(value);
  }

  /// Get progress to next threshold for a character (0.0 - 1.0)
  double getProgressToNextThreshold(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return 0.0;

    final value = getValue(characterId);
    return def.getProgressToNextThreshold(value);
  }

  /// Get next threshold for a character
  AffectionThreshold? getNextThreshold(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return null;

    final value = getValue(characterId);
    return def.getNextThreshold(value);
  }

  /// Get status for all characters
  List<AffectionStatus> getAllStatuses() {
    return _definitions.map((def) {
      final value = getValue(def.characterId);
      return AffectionStatus(
        definition: def,
        currentValue: value,
        currentThreshold: def.getThresholdForValue(value),
        nextThreshold: def.getNextThreshold(value),
        percentage: def.getPercentage(value),
        progressToNext: def.getProgressToNextThreshold(value),
      );
    }).toList();
  }

  /// Get status for a specific character
  AffectionStatus? getStatus(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return null;

    final value = getValue(characterId);
    return AffectionStatus(
      definition: def,
      currentValue: value,
      currentThreshold: def.getThresholdForValue(value),
      nextThreshold: def.getNextThreshold(value),
      percentage: def.getPercentage(value),
      progressToNext: def.getProgressToNextThreshold(value),
    );
  }

  /// Reset affection for a character to default value
  AffectionChangeEvent? resetToDefault(String characterId) {
    final def = getDefinition(characterId);
    if (def == null) return null;

    return setValue(characterId, def.defaultValue);
  }

  /// Reset all affection values to defaults
  void resetAll() {
    for (final def in _definitions) {
      setValue(def.characterId, def.defaultValue);
    }
  }

  /// Add a new affection definition
  void addDefinition(AffectionDefinition definition) {
    if (_definitions.any((d) => d.characterId == definition.characterId)) {
      throw ArgumentError(
          'Affection definition for ${definition.characterId} already exists');
    }
    _definitions.add(definition);

    // Initialize default value
    _progressManager.setAffection(
        definition.characterId, definition.defaultValue);
  }

  /// Remove an affection definition
  bool removeDefinition(String characterId) {
    final lengthBefore = _definitions.length;
    _definitions.removeWhere((d) => d.characterId == characterId);
    return _definitions.length < lengthBefore;
  }

  /// Update an affection definition
  void updateDefinition(AffectionDefinition definition) {
    final index =
        _definitions.indexWhere((d) => d.characterId == definition.characterId);
    if (index >= 0) {
      _definitions[index] = definition;
    }
  }

  /// Export definitions to JSON
  List<Map<String, dynamic>> exportDefinitions() {
    return _definitions.map((d) => d.toJson()).toList();
  }

  /// Import definitions from JSON
  void importDefinitions(List<dynamic> jsonList) {
    _definitions.clear();
    for (final json in jsonList) {
      _definitions.add(AffectionDefinition.fromJson(json as Map<String, dynamic>));
    }
    _initializeDefaults();
  }

  /// Dispose resources
  void dispose() {
    _changeController.close();
    _thresholdController.close();
  }
}

/// Status of affection for a character (for UI display)
class AffectionStatus {
  /// The affection definition
  final AffectionDefinition definition;

  /// Current affection value
  final int currentValue;

  /// Current threshold (may be null if below all thresholds)
  final AffectionThreshold? currentThreshold;

  /// Next threshold to reach (may be null if at max)
  final AffectionThreshold? nextThreshold;

  /// Overall percentage (0.0 - 1.0)
  final double percentage;

  /// Progress to next threshold (0.0 - 1.0)
  final double progressToNext;

  const AffectionStatus({
    required this.definition,
    required this.currentValue,
    this.currentThreshold,
    this.nextThreshold,
    required this.percentage,
    required this.progressToNext,
  });

  /// Character ID
  String get characterId => definition.characterId;

  /// Character name
  String get characterName => definition.characterName;

  /// Current threshold label (or null)
  String? get currentLabel => currentThreshold?.label;

  /// Next threshold label (or null)
  String? get nextLabel => nextThreshold?.label;

  /// Points needed to reach next threshold
  int? get pointsToNext {
    if (nextThreshold == null) return null;
    return nextThreshold!.value - currentValue;
  }

  /// Whether at maximum value
  bool get isAtMax => currentValue >= definition.maxValue;

  /// Whether at minimum value
  bool get isAtMin => currentValue <= definition.minValue;
}
