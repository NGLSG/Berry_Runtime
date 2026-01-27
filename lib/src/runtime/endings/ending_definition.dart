/// Ending Definition Model for VNBS
///
/// Defines the EndingDefinition class and EndingType enum.
/// Requirements: 3.5

/// Ending type categorization
enum EndingType {
  /// True/Best ending
  trueEnding,

  /// Normal ending
  normal,

  /// Bad ending
  bad,

  /// Secret/Hidden ending
  secret,
}

/// Extension methods for EndingType
extension EndingTypeExtension on EndingType {
  /// Get display name for the ending type
  String get displayName {
    switch (this) {
      case EndingType.trueEnding:
        return 'True Ending';
      case EndingType.normal:
        return 'Normal';
      case EndingType.bad:
        return 'Bad';
      case EndingType.secret:
        return 'Secret';
    }
  }

  /// Get localized display name
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        switch (this) {
          case EndingType.trueEnding:
            return 'トゥルーエンド';
          case EndingType.normal:
            return 'ノーマル';
          case EndingType.bad:
            return 'バッド';
          case EndingType.secret:
            return 'シークレット';
        }
      case 'zh':
        switch (this) {
          case EndingType.trueEnding:
            return '真结局';
          case EndingType.normal:
            return '普通';
          case EndingType.bad:
            return '坏结局';
          case EndingType.secret:
            return '隐藏';
        }
      default:
        return displayName;
    }
  }

  /// Convert to JSON string
  String toJson() => name;

  /// Parse from JSON string
  static EndingType fromJson(String json) {
    return EndingType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EndingType.normal,
    );
  }
}

/// Ending definition
///
/// Represents a single ending in the visual novel.
class EndingDefinition {
  /// Unique ending identifier
  final String id;

  /// Display name
  final String name;

  /// Description (shown when unlocked)
  final String? description;

  /// Thumbnail image path (relative to assets)
  final String? thumbnailPath;

  /// Ending type/category
  final EndingType type;

  /// Display order (lower = first)
  final int order;

  /// Localized names by language code
  final Map<String, String> localizedNames;

  /// Localized descriptions by language code
  final Map<String, String> localizedDescriptions;

  /// Hint text shown when locked (optional)
  final String? unlockHint;

  /// Localized unlock hints by language code
  final Map<String, String> localizedUnlockHints;

  const EndingDefinition({
    required this.id,
    required this.name,
    this.description,
    this.thumbnailPath,
    this.type = EndingType.normal,
    this.order = 0,
    this.localizedNames = const {},
    this.localizedDescriptions = const {},
    this.unlockHint,
    this.localizedUnlockHints = const {},
  });

  /// Get localized name
  String getLocalizedName(String languageCode) {
    return localizedNames[languageCode] ?? name;
  }

  /// Get localized description
  String? getLocalizedDescription(String languageCode) {
    return localizedDescriptions[languageCode] ?? description;
  }

  /// Get localized unlock hint
  String? getLocalizedUnlockHint(String languageCode) {
    return localizedUnlockHints[languageCode] ?? unlockHint;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'type': type.toJson(),
        'order': order,
        if (localizedNames.isNotEmpty) 'localizedNames': localizedNames,
        if (localizedDescriptions.isNotEmpty)
          'localizedDescriptions': localizedDescriptions,
        if (unlockHint != null) 'unlockHint': unlockHint,
        if (localizedUnlockHints.isNotEmpty)
          'localizedUnlockHints': localizedUnlockHints,
      };

  /// Create from JSON
  factory EndingDefinition.fromJson(Map<String, dynamic> json) {
    return EndingDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      type: json['type'] != null
          ? EndingTypeExtension.fromJson(json['type'] as String)
          : EndingType.normal,
      order: json['order'] as int? ?? 0,
      localizedNames:
          (json['localizedNames'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      localizedDescriptions:
          (json['localizedDescriptions'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
      unlockHint: json['unlockHint'] as String?,
      localizedUnlockHints:
          (json['localizedUnlockHints'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
    );
  }

  /// Create a copy with modified fields
  EndingDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? thumbnailPath,
    EndingType? type,
    int? order,
    Map<String, String>? localizedNames,
    Map<String, String>? localizedDescriptions,
    String? unlockHint,
    Map<String, String>? localizedUnlockHints,
  }) {
    return EndingDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      type: type ?? this.type,
      order: order ?? this.order,
      localizedNames: localizedNames ?? this.localizedNames,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
      unlockHint: unlockHint ?? this.unlockHint,
      localizedUnlockHints: localizedUnlockHints ?? this.localizedUnlockHints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndingDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EndingDefinition(id: $id, name: $name, type: $type)';
}

/// Ending status for UI display
class EndingStatus {
  /// The ending definition
  final EndingDefinition definition;

  /// Whether the ending has been reached
  final bool isReached;

  /// When the ending was reached (null if not reached)
  final DateTime? reachDate;

  /// Order in which this ending was reached (0 = not reached)
  final int reachOrder;

  const EndingStatus({
    required this.definition,
    required this.isReached,
    this.reachDate,
    this.reachOrder = 0,
  });

  /// Get display name (shows name if reached, "???" if secret and not reached)
  String getDisplayName(String languageCode) {
    if (!isReached && definition.type == EndingType.secret) {
      return '???';
    }
    return definition.getLocalizedName(languageCode);
  }

  /// Get display description (shows description if reached, hint or "???" if not)
  String? getDisplayDescription(String languageCode) {
    if (!isReached) {
      return definition.getLocalizedUnlockHint(languageCode) ?? '???';
    }
    return definition.getLocalizedDescription(languageCode);
  }

  /// Whether this ending should show its thumbnail
  bool get shouldShowThumbnail => isReached;

  @override
  String toString() =>
      'EndingStatus(id: ${definition.id}, isReached: $isReached, order: $reachOrder)';
}
