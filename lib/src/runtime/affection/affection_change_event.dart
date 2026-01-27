/// Affection Change Event for VNBS Affection System
///
/// Events emitted when affection values change.
/// Requirements: 18.2, 18.4

import 'affection_threshold.dart';

/// Event emitted when an affection value changes
class AffectionChangeEvent {
  /// Character ID whose affection changed
  final String characterId;

  /// Character display name
  final String characterName;

  /// Previous affection value
  final int oldValue;

  /// New affection value
  final int newValue;

  /// Thresholds that were crossed during this change
  final List<AffectionThreshold> crossedThresholds;

  /// Timestamp of the change
  final DateTime timestamp;

  AffectionChangeEvent({
    required this.characterId,
    required this.characterName,
    required this.oldValue,
    required this.newValue,
    required this.crossedThresholds,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// The change in value (positive = increase, negative = decrease)
  int get delta => newValue - oldValue;

  /// Whether the affection increased
  bool get isIncrease => delta > 0;

  /// Whether the affection decreased
  bool get isDecrease => delta < 0;

  /// Whether any thresholds were crossed
  bool get hasCrossedThresholds => crossedThresholds.isNotEmpty;

  /// Whether this was a positive threshold crossing (going up)
  bool get isPositiveThresholdCrossing => isIncrease && hasCrossedThresholds;

  /// Whether this was a negative threshold crossing (going down)
  bool get isNegativeThresholdCrossing => isDecrease && hasCrossedThresholds;

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'characterName': characterName,
        'oldValue': oldValue,
        'newValue': newValue,
        'crossedThresholds': crossedThresholds.map((t) => t.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory AffectionChangeEvent.fromJson(Map<String, dynamic> json) {
    return AffectionChangeEvent(
      characterId: json['characterId'] as String,
      characterName: json['characterName'] as String,
      oldValue: json['oldValue'] as int,
      newValue: json['newValue'] as int,
      crossedThresholds: (json['crossedThresholds'] as List? ?? [])
          .map((t) => AffectionThreshold.fromJson(t as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'AffectionChangeEvent(characterId: $characterId, $oldValue -> $newValue, '
      'crossed: ${crossedThresholds.length} thresholds)';
}

/// Event emitted when a threshold is crossed
class ThresholdCrossedEvent {
  /// Character ID whose threshold was crossed
  final String characterId;

  /// Character display name
  final String characterName;

  /// The threshold that was crossed
  final AffectionThreshold threshold;

  /// Whether crossing was upward (true) or downward (false)
  final bool isUpward;

  /// Current affection value
  final int currentValue;

  /// Timestamp of the crossing
  final DateTime timestamp;

  ThresholdCrossedEvent({
    required this.characterId,
    required this.characterName,
    required this.threshold,
    required this.isUpward,
    required this.currentValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'characterName': characterName,
        'threshold': threshold.toJson(),
        'isUpward': isUpward,
        'currentValue': currentValue,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ThresholdCrossedEvent.fromJson(Map<String, dynamic> json) {
    return ThresholdCrossedEvent(
      characterId: json['characterId'] as String,
      characterName: json['characterName'] as String,
      threshold:
          AffectionThreshold.fromJson(json['threshold'] as Map<String, dynamic>),
      isUpward: json['isUpward'] as bool,
      currentValue: json['currentValue'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'ThresholdCrossedEvent(characterId: $characterId, '
      'threshold: ${threshold.label}, isUpward: $isUpward)';
}
