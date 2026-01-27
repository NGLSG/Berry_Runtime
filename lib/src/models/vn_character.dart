import 'dart:ui';

/// A character in the visual novel
class VNCharacter {
  /// Unique character identifier
  final String id;

  /// Display name shown in dialogue
  final String displayName;

  /// Localized display names by language code
  final Map<String, String> localizedNames;

  /// Color for the name plate
  final Color nameColor;

  /// Default sprite path
  final String defaultSprite;

  /// Expression sprites (expression name -> sprite path)
  final Map<String, String> expressions;

  /// Pose variants (pose name -> sprite path)
  final Map<String, String> poses;

  /// Voice actor name (optional)
  final String? voiceActor;

  /// Character description (for editor reference)
  final String? description;

  const VNCharacter({
    required this.id,
    required this.displayName,
    this.localizedNames = const {},
    this.nameColor = const Color(0xFFFFFFFF),
    required this.defaultSprite,
    this.expressions = const {},
    this.poses = const {},
    this.voiceActor,
    this.description,
  });

  /// Get localized name for a language
  String getLocalizedName(String languageCode) {
    return localizedNames[languageCode] ?? displayName;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (localizedNames.isNotEmpty) 'localizedNames': localizedNames,
        'nameColor': nameColor.value,
        'defaultSprite': defaultSprite,
        'expressions': expressions,
        'poses': poses,
        if (voiceActor != null) 'voiceActor': voiceActor,
        if (description != null) 'description': description,
      };

  factory VNCharacter.fromJson(Map<String, dynamic> json) {
    return VNCharacter(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      localizedNames:
          (json['localizedNames'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      nameColor: Color(json['nameColor'] as int? ?? 0xFFFFFFFF),
      defaultSprite: json['defaultSprite'] as String? ?? '',
      expressions:
          (json['expressions'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      poses:
          (json['poses'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      voiceActor: json['voiceActor'] as String?,
      description: json['description'] as String?,
    );
  }

  VNCharacter copyWith({
    String? id,
    String? displayName,
    Map<String, String>? localizedNames,
    Color? nameColor,
    String? defaultSprite,
    Map<String, String>? expressions,
    Map<String, String>? poses,
    String? voiceActor,
    String? description,
  }) {
    return VNCharacter(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      localizedNames: localizedNames ?? this.localizedNames,
      nameColor: nameColor ?? this.nameColor,
      defaultSprite: defaultSprite ?? this.defaultSprite,
      expressions: expressions ?? this.expressions,
      poses: poses ?? this.poses,
      voiceActor: voiceActor ?? this.voiceActor,
      description: description ?? this.description,
    );
  }

  /// Check if an expression exists
  bool hasExpression(String name) => expressions.containsKey(name);

  /// Check if a pose exists
  bool hasPose(String name) => poses.containsKey(name);

  /// Get sprite path for an expression (falls back to default, then first available)
  String getSpriteForExpression(String? expression) {
    // Try exact expression match
    if (expression != null && expressions.containsKey(expression)) {
      final path = expressions[expression];
      if (path != null && path.isNotEmpty) return path;
    }

    // Fall back to default sprite
    if (defaultSprite.isNotEmpty) return defaultSprite;

    // Fall back to first available expression with non-empty path
    for (final path in expressions.values) {
      if (path.isNotEmpty) return path;
    }

    return '';
  }

  /// Get sprite path for a pose (falls back to default)
  String getSpriteForPose(String? pose) {
    if (pose == null) return defaultSprite;
    return poses[pose] ?? defaultSprite;
  }

  /// Get all available expression names
  List<String> get expressionNames => expressions.keys.toList();

  /// Get all available pose names
  List<String> get poseNames => poses.keys.toList();

  /// Validate character data
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Character ID is empty');
    }
    if (displayName.isEmpty) {
      errors.add('Character display name is empty');
    }
    if (defaultSprite.isEmpty) {
      errors.add('Character default sprite is not set');
    }
    
    return errors;
  }
}
