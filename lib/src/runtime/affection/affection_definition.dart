/// Affection Definition for VNBS Affection System
///
/// Defines the affection tracking configuration for a character.
/// Requirements: 18.1, 18.5

import 'relationship_type.dart';
import 'affection_threshold.dart';

/// Defines affection tracking for a specific character
///
/// Each character can have their own affection definition with
/// custom min/max values, thresholds, and relationship type.
class AffectionDefinition {
  /// Character ID this affection is for
  final String characterId;

  /// Character display name
  final String characterName;

  /// Type of relationship being tracked
  final RelationshipType type;

  /// Custom label for the relationship type (used when type is custom)
  final String? customTypeLabel;

  /// Minimum affection value
  final int minValue;

  /// Maximum affection value
  final int maxValue;

  /// Default/starting affection value
  final int defaultValue;

  /// Thresholds that define relationship levels
  final List<AffectionThreshold> thresholds;

  /// Whether to show affection changes to the player
  final bool showChanges;

  /// Whether to show the affection meter in UI
  final bool showMeter;

  /// Custom icon path for this affection (overrides type default)
  final String? iconPath;

  /// Custom color hex for this affection (overrides type default)
  final String? colorHex;

  /// Localized character names by language code
  final Map<String, String> localizedNames;

  const AffectionDefinition({
    required this.characterId,
    required this.characterName,
    this.type = RelationshipType.love,
    this.customTypeLabel,
    this.minValue = 0,
    this.maxValue = 100,
    this.defaultValue = 0,
    this.thresholds = const [],
    this.showChanges = true,
    this.showMeter = true,
    this.iconPath,
    this.colorHex,
    this.localizedNames = const {},
  });

  /// Get the display label for the relationship type
  String get typeLabel => customTypeLabel ?? type.defaultLabel;

  /// Get the icon for this affection
  String get icon => iconPath ?? type.defaultIcon;

  /// Get the color hex for this affection
  String get color => colorHex ?? type.defaultColorHex;

  /// Get localized character name
  String getLocalizedName(String languageCode) {
    return localizedNames[languageCode] ?? characterName;
  }

  /// Get the threshold for a given value
  AffectionThreshold? getThresholdForValue(int value) {
    if (thresholds.isEmpty) return null;

    // Sort thresholds by value descending
    final sorted = List<AffectionThreshold>.from(thresholds)
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find the highest threshold that the value meets or exceeds
    for (final threshold in sorted) {
      if (value >= threshold.value) {
        return threshold;
      }
    }

    return null;
  }

  /// Get the next threshold above the current value
  AffectionThreshold? getNextThreshold(int currentValue) {
    if (thresholds.isEmpty) return null;

    // Sort thresholds by value ascending
    final sorted = List<AffectionThreshold>.from(thresholds)
      ..sort((a, b) => a.value.compareTo(b.value));

    // Find the first threshold above current value
    for (final threshold in sorted) {
      if (threshold.value > currentValue) {
        return threshold;
      }
    }

    return null;
  }

  /// Calculate progress to next threshold (0.0 - 1.0)
  double getProgressToNextThreshold(int currentValue) {
    final current = getThresholdForValue(currentValue);
    final next = getNextThreshold(currentValue);

    if (next == null) {
      // Already at max threshold
      return 1.0;
    }

    final startValue = current?.value ?? minValue;
    final range = next.value - startValue;

    if (range <= 0) return 1.0;

    return ((currentValue - startValue) / range).clamp(0.0, 1.0);
  }

  /// Get overall percentage (0.0 - 1.0)
  double getPercentage(int currentValue) {
    final range = maxValue - minValue;
    if (range <= 0) return 0.0;
    return ((currentValue - minValue) / range).clamp(0.0, 1.0);
  }

  /// Clamp a value to valid range
  int clampValue(int value) {
    return value.clamp(minValue, maxValue);
  }

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'characterName': characterName,
        'type': type.toJson(),
        if (customTypeLabel != null) 'customTypeLabel': customTypeLabel,
        'minValue': minValue,
        'maxValue': maxValue,
        'defaultValue': defaultValue,
        'thresholds': thresholds.map((t) => t.toJson()).toList(),
        'showChanges': showChanges,
        'showMeter': showMeter,
        if (iconPath != null) 'iconPath': iconPath,
        if (colorHex != null) 'colorHex': colorHex,
        if (localizedNames.isNotEmpty) 'localizedNames': localizedNames,
      };

  factory AffectionDefinition.fromJson(Map<String, dynamic> json) {
    return AffectionDefinition(
      characterId: json['characterId'] as String,
      characterName: json['characterName'] as String,
      type: RelationshipTypeExtension.fromJson(json['type'] as String? ?? 'love'),
      customTypeLabel: json['customTypeLabel'] as String?,
      minValue: json['minValue'] as int? ?? 0,
      maxValue: json['maxValue'] as int? ?? 100,
      defaultValue: json['defaultValue'] as int? ?? 0,
      thresholds: (json['thresholds'] as List? ?? [])
          .map((t) => AffectionThreshold.fromJson(t as Map<String, dynamic>))
          .toList(),
      showChanges: json['showChanges'] as bool? ?? true,
      showMeter: json['showMeter'] as bool? ?? true,
      iconPath: json['iconPath'] as String?,
      colorHex: json['colorHex'] as String?,
      localizedNames:
          (json['localizedNames'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
    );
  }

  AffectionDefinition copyWith({
    String? characterId,
    String? characterName,
    RelationshipType? type,
    String? customTypeLabel,
    int? minValue,
    int? maxValue,
    int? defaultValue,
    List<AffectionThreshold>? thresholds,
    bool? showChanges,
    bool? showMeter,
    String? iconPath,
    String? colorHex,
    Map<String, String>? localizedNames,
  }) {
    return AffectionDefinition(
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      type: type ?? this.type,
      customTypeLabel: customTypeLabel ?? this.customTypeLabel,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      defaultValue: defaultValue ?? this.defaultValue,
      thresholds: thresholds ?? this.thresholds,
      showChanges: showChanges ?? this.showChanges,
      showMeter: showMeter ?? this.showMeter,
      iconPath: iconPath ?? this.iconPath,
      colorHex: colorHex ?? this.colorHex,
      localizedNames: localizedNames ?? this.localizedNames,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffectionDefinition &&
          runtimeType == other.runtimeType &&
          characterId == other.characterId;

  @override
  int get hashCode => characterId.hashCode;

  @override
  String toString() =>
      'AffectionDefinition(characterId: $characterId, characterName: $characterName, type: $type)';
}
