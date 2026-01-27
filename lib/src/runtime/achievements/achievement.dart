/// Achievement Model for VNBS
///
/// Defines the Achievement class and related types.
/// Requirements: 2.2

import 'achievement_condition.dart';

/// Achievement definition
class Achievement {
  /// Unique achievement identifier
  final String id;

  /// Display name
  final String name;

  /// Description (shown when unlocked or if not hidden)
  final String description;

  /// Icon path (relative to assets)
  final String? iconPath;

  /// Unlock condition
  final AchievementCondition condition;

  /// Whether this achievement is hidden until unlocked
  final bool isHidden;

  /// Point value for this achievement
  final int points;

  /// Category for grouping
  final String? category;

  /// Localized names by language code
  final Map<String, String> localizedNames;

  /// Localized descriptions by language code
  final Map<String, String> localizedDescriptions;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconPath,
    required this.condition,
    this.isHidden = false,
    this.points = 10,
    this.category,
    this.localizedNames = const {},
    this.localizedDescriptions = const {},
  });

  /// Get localized name
  String getLocalizedName(String languageCode) {
    return localizedNames[languageCode] ?? name;
  }

  /// Get localized description
  String getLocalizedDescription(String languageCode) {
    return localizedDescriptions[languageCode] ?? description;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (iconPath != null) 'iconPath': iconPath,
        'condition': condition.toJson(),
        'isHidden': isHidden,
        'points': points,
        if (category != null) 'category': category,
        if (localizedNames.isNotEmpty) 'localizedNames': localizedNames,
        if (localizedDescriptions.isNotEmpty)
          'localizedDescriptions': localizedDescriptions,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      iconPath: json['iconPath'] as String?,
      condition: json['condition'] != null
          ? AchievementCondition.fromJson(
              json['condition'] as Map<String, dynamic>)
          : const ManualAchievementCondition(),
      isHidden: json['isHidden'] as bool? ?? false,
      points: json['points'] as int? ?? 10,
      category: json['category'] as String?,
      localizedNames:
          (json['localizedNames'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      localizedDescriptions:
          (json['localizedDescriptions'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
    );
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    AchievementCondition? condition,
    bool? isHidden,
    int? points,
    String? category,
    Map<String, String>? localizedNames,
    Map<String, String>? localizedDescriptions,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      condition: condition ?? this.condition,
      isHidden: isHidden ?? this.isHidden,
      points: points ?? this.points,
      category: category ?? this.category,
      localizedNames: localizedNames ?? this.localizedNames,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Achievement status for UI display
class AchievementStatus {
  /// The achievement definition
  final Achievement achievement;

  /// Whether the achievement is unlocked
  final bool isUnlocked;

  /// When the achievement was unlocked (null if not unlocked)
  final DateTime? unlockDate;

  /// Progress towards unlocking (0.0 - 1.0)
  final double progress;

  const AchievementStatus({
    required this.achievement,
    required this.isUnlocked,
    this.unlockDate,
    required this.progress,
  });

  /// Whether this achievement should be visible in the list
  bool get isVisible => isUnlocked || !achievement.isHidden;

  /// Get display name (hidden achievements show "???" until unlocked)
  String getDisplayName(String languageCode) {
    if (!isVisible) return '???';
    return achievement.getLocalizedName(languageCode);
  }

  /// Get display description (hidden achievements show "???" until unlocked)
  String getDisplayDescription(String languageCode) {
    if (!isVisible) return '???';
    return achievement.getLocalizedDescription(languageCode);
  }
}
