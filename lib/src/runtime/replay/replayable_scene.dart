/// Replayable Scene Data Model
///
/// Defines the data structures for the scene replay system.
/// Requirements: 1.7

/// Replayable scene definition
class ReplayableScene {
  /// Unique scene identifier
  final String id;

  /// Scene display title
  final String title;

  /// Localized titles by language code
  final Map<String, String> localizedTitles;

  /// Scene description (shown when unlocked)
  final String? description;

  /// Localized descriptions by language code
  final Map<String, String> localizedDescriptions;

  /// Thumbnail image path
  final String? thumbnailPath;

  /// Chapter ID containing this scene
  final String chapterId;

  /// Starting node ID for replay
  final String startNodeId;

  /// Ending node ID for replay (null = play until next choice)
  final String? endNodeId;

  /// Category for grouping (e.g., "Chapter 1", "Romance", "Action")
  final String? category;

  /// Display order within category
  final int order;

  /// Unlock hint shown when scene is locked
  final String? unlockHint;

  /// Localized unlock hints by language code
  final Map<String, String> localizedUnlockHints;

  const ReplayableScene({
    required this.id,
    required this.title,
    this.localizedTitles = const {},
    this.description,
    this.localizedDescriptions = const {},
    this.thumbnailPath,
    required this.chapterId,
    required this.startNodeId,
    this.endNodeId,
    this.category,
    this.order = 0,
    this.unlockHint,
    this.localizedUnlockHints = const {},
  });

  /// Get localized title
  String getLocalizedTitle(String languageCode) {
    return localizedTitles[languageCode] ?? title;
  }

  /// Get localized description
  String? getLocalizedDescription(String languageCode) {
    return localizedDescriptions[languageCode] ?? description;
  }

  /// Get localized unlock hint
  String? getLocalizedUnlockHint(String languageCode) {
    return localizedUnlockHints[languageCode] ?? unlockHint;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (localizedTitles.isNotEmpty) 'localizedTitles': localizedTitles,
        if (description != null) 'description': description,
        if (localizedDescriptions.isNotEmpty)
          'localizedDescriptions': localizedDescriptions,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'chapterId': chapterId,
        'startNodeId': startNodeId,
        if (endNodeId != null) 'endNodeId': endNodeId,
        if (category != null) 'category': category,
        'order': order,
        if (unlockHint != null) 'unlockHint': unlockHint,
        if (localizedUnlockHints.isNotEmpty)
          'localizedUnlockHints': localizedUnlockHints,
      };

  factory ReplayableScene.fromJson(Map<String, dynamic> json) {
    return ReplayableScene(
      id: json['id'] as String,
      title: json['title'] as String,
      localizedTitles:
          (json['localizedTitles'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      description: json['description'] as String?,
      localizedDescriptions:
          (json['localizedDescriptions'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
      thumbnailPath: json['thumbnailPath'] as String?,
      chapterId: json['chapterId'] as String,
      startNodeId: json['startNodeId'] as String,
      endNodeId: json['endNodeId'] as String?,
      category: json['category'] as String?,
      order: json['order'] as int? ?? 0,
      unlockHint: json['unlockHint'] as String?,
      localizedUnlockHints:
          (json['localizedUnlockHints'] as Map<String, dynamic>?)
                  ?.cast<String, String>() ??
              const {},
    );
  }

  ReplayableScene copyWith({
    String? id,
    String? title,
    Map<String, String>? localizedTitles,
    String? description,
    Map<String, String>? localizedDescriptions,
    String? thumbnailPath,
    String? chapterId,
    String? startNodeId,
    String? endNodeId,
    String? category,
    int? order,
    String? unlockHint,
    Map<String, String>? localizedUnlockHints,
  }) {
    return ReplayableScene(
      id: id ?? this.id,
      title: title ?? this.title,
      localizedTitles: localizedTitles ?? this.localizedTitles,
      description: description ?? this.description,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      chapterId: chapterId ?? this.chapterId,
      startNodeId: startNodeId ?? this.startNodeId,
      endNodeId: endNodeId ?? this.endNodeId,
      category: category ?? this.category,
      order: order ?? this.order,
      unlockHint: unlockHint ?? this.unlockHint,
      localizedUnlockHints: localizedUnlockHints ?? this.localizedUnlockHints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplayableScene &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          chapterId == other.chapterId &&
          startNodeId == other.startNodeId;

  @override
  int get hashCode => Object.hash(id, title, chapterId, startNodeId);
}

/// Scene replay status (combines definition with unlock state)
class SceneReplayStatus {
  /// Scene definition
  final ReplayableScene scene;

  /// Whether the scene is unlocked
  final bool isUnlocked;

  /// Unlock date (if unlocked)
  final DateTime? unlockDate;

  const SceneReplayStatus({
    required this.scene,
    required this.isUnlocked,
    this.unlockDate,
  });

  /// Get display title based on unlock status
  String getDisplayTitle(String languageCode) {
    if (isUnlocked) {
      return scene.getLocalizedTitle(languageCode);
    }
    return '???';
  }

  /// Get display description based on unlock status
  String? getDisplayDescription(String languageCode) {
    if (isUnlocked) {
      return scene.getLocalizedDescription(languageCode);
    }
    return scene.getLocalizedUnlockHint(languageCode);
  }

  /// Whether to show thumbnail
  bool get shouldShowThumbnail => isUnlocked && scene.thumbnailPath != null;
}
