/// Affection Threshold for VNBS Affection System
///
/// Defines thresholds that trigger events when crossed.
/// Requirements: 18.4

/// Represents a threshold level in the affection system
///
/// When affection value crosses a threshold, events can be triggered
/// and content can be unlocked.
class AffectionThreshold {
  /// The value at which this threshold is reached
  final int value;

  /// Display label for this threshold level (e.g., "Acquaintance", "Friend", "Close Friend")
  final String label;

  /// Optional content ID that gets unlocked when this threshold is reached
  final String? unlocksContent;

  /// Optional achievement ID that gets unlocked when this threshold is reached
  final String? unlocksAchievement;

  /// Optional scene ID that gets unlocked when this threshold is reached
  final String? unlocksScene;

  /// Optional description shown when this threshold is reached
  final String? description;

  /// Localized labels by language code
  final Map<String, String> localizedLabels;

  /// Localized descriptions by language code
  final Map<String, String> localizedDescriptions;

  const AffectionThreshold({
    required this.value,
    required this.label,
    this.unlocksContent,
    this.unlocksAchievement,
    this.unlocksScene,
    this.description,
    this.localizedLabels = const {},
    this.localizedDescriptions = const {},
  });

  /// Get localized label
  String getLocalizedLabel(String languageCode) {
    return localizedLabels[languageCode] ?? label;
  }

  /// Get localized description
  String? getLocalizedDescription(String languageCode) {
    return localizedDescriptions[languageCode] ?? description;
  }

  /// Check if this threshold has any unlockable content
  bool get hasUnlockableContent =>
      unlocksContent != null ||
      unlocksAchievement != null ||
      unlocksScene != null;

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        if (unlocksContent != null) 'unlocksContent': unlocksContent,
        if (unlocksAchievement != null) 'unlocksAchievement': unlocksAchievement,
        if (unlocksScene != null) 'unlocksScene': unlocksScene,
        if (description != null) 'description': description,
        if (localizedLabels.isNotEmpty) 'localizedLabels': localizedLabels,
        if (localizedDescriptions.isNotEmpty)
          'localizedDescriptions': localizedDescriptions,
      };

  factory AffectionThreshold.fromJson(Map<String, dynamic> json) {
    return AffectionThreshold(
      value: json['value'] as int,
      label: json['label'] as String,
      unlocksContent: json['unlocksContent'] as String?,
      unlocksAchievement: json['unlocksAchievement'] as String?,
      unlocksScene: json['unlocksScene'] as String?,
      description: json['description'] as String?,
      localizedLabels:
          (json['localizedLabels'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      localizedDescriptions:
          (json['localizedDescriptions'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
    );
  }

  AffectionThreshold copyWith({
    int? value,
    String? label,
    String? unlocksContent,
    String? unlocksAchievement,
    String? unlocksScene,
    String? description,
    Map<String, String>? localizedLabels,
    Map<String, String>? localizedDescriptions,
  }) {
    return AffectionThreshold(
      value: value ?? this.value,
      label: label ?? this.label,
      unlocksContent: unlocksContent ?? this.unlocksContent,
      unlocksAchievement: unlocksAchievement ?? this.unlocksAchievement,
      unlocksScene: unlocksScene ?? this.unlocksScene,
      description: description ?? this.description,
      localizedLabels: localizedLabels ?? this.localizedLabels,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffectionThreshold &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => Object.hash(value, label);

  @override
  String toString() => 'AffectionThreshold(value: $value, label: $label)';
}

/// Common threshold presets for quick setup
class AffectionThresholdPresets {
  AffectionThresholdPresets._();

  /// Standard 5-level love relationship thresholds (0-100 scale)
  static const List<AffectionThreshold> loveStandard = [
    AffectionThreshold(value: 0, label: 'Stranger'),
    AffectionThreshold(value: 20, label: 'Acquaintance'),
    AffectionThreshold(value: 40, label: 'Friend'),
    AffectionThreshold(value: 60, label: 'Close Friend'),
    AffectionThreshold(value: 80, label: 'Romantic Interest'),
    AffectionThreshold(value: 100, label: 'Soulmate'),
  ];

  /// Standard 5-level friendship thresholds (0-100 scale)
  static const List<AffectionThreshold> friendshipStandard = [
    AffectionThreshold(value: 0, label: 'Stranger'),
    AffectionThreshold(value: 25, label: 'Acquaintance'),
    AffectionThreshold(value: 50, label: 'Friend'),
    AffectionThreshold(value: 75, label: 'Good Friend'),
    AffectionThreshold(value: 100, label: 'Best Friend'),
  ];

  /// Standard 5-level trust thresholds (0-100 scale)
  static const List<AffectionThreshold> trustStandard = [
    AffectionThreshold(value: 0, label: 'Distrustful'),
    AffectionThreshold(value: 25, label: 'Wary'),
    AffectionThreshold(value: 50, label: 'Neutral'),
    AffectionThreshold(value: 75, label: 'Trusting'),
    AffectionThreshold(value: 100, label: 'Complete Trust'),
  ];

  /// Standard rivalry thresholds (can go negative)
  static const List<AffectionThreshold> rivalryStandard = [
    AffectionThreshold(value: -100, label: 'Bitter Enemy'),
    AffectionThreshold(value: -50, label: 'Rival'),
    AffectionThreshold(value: 0, label: 'Neutral'),
    AffectionThreshold(value: 50, label: 'Respected Rival'),
    AffectionThreshold(value: 100, label: 'Worthy Opponent'),
  ];
}
