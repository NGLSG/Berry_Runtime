/// Chapter Information Model for Chapter Select System
///
/// Defines chapter metadata for the chapter select screen.
/// Requirements: 8.4, 8.5

/// Chapter information for chapter select screen
class ChapterInfo {
  /// Unique chapter identifier
  final String id;

  /// Chapter display title
  final String title;

  /// Optional chapter description
  final String? description;

  /// Path to chapter thumbnail image
  final String? thumbnailPath;

  /// Estimated play time for this chapter
  final Duration? estimatedPlayTime;

  /// Chapter order in the story (0-based)
  final int order;

  /// Whether this chapter is the starting chapter
  final bool isStartingChapter;

  /// Node ID to start from when selecting this chapter
  final String? startNodeId;

  const ChapterInfo({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.estimatedPlayTime,
    this.order = 0,
    this.isStartingChapter = false,
    this.startNodeId,
  });

  /// Create from Chapter model
  factory ChapterInfo.fromChapter({
    required String id,
    required String title,
    String? description,
    int order = 0,
    Duration? estimatedPlayTime,
    String? thumbnailPath,
    String? startNodeId,
  }) {
    return ChapterInfo(
      id: id,
      title: title,
      description: description,
      order: order,
      estimatedPlayTime: estimatedPlayTime,
      thumbnailPath: thumbnailPath,
      isStartingChapter: order == 0,
      startNodeId: startNodeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        if (estimatedPlayTime != null)
          'estimatedPlayTimeMs': estimatedPlayTime!.inMilliseconds,
        'order': order,
        'isStartingChapter': isStartingChapter,
        if (startNodeId != null) 'startNodeId': startNodeId,
      };

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      estimatedPlayTime: json['estimatedPlayTimeMs'] != null
          ? Duration(milliseconds: json['estimatedPlayTimeMs'] as int)
          : null,
      order: json['order'] as int? ?? 0,
      isStartingChapter: json['isStartingChapter'] as bool? ?? false,
      startNodeId: json['startNodeId'] as String?,
    );
  }

  ChapterInfo copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailPath,
    Duration? estimatedPlayTime,
    int? order,
    bool? isStartingChapter,
    String? startNodeId,
  }) {
    return ChapterInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      estimatedPlayTime: estimatedPlayTime ?? this.estimatedPlayTime,
      order: order ?? this.order,
      isStartingChapter: isStartingChapter ?? this.isStartingChapter,
      startNodeId: startNodeId ?? this.startNodeId,
    );
  }

  /// Format estimated play time for display
  String get formattedPlayTime {
    if (estimatedPlayTime == null) return '';
    final hours = estimatedPlayTime!.inHours;
    final minutes = estimatedPlayTime!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, title, order);

  @override
  String toString() => 'ChapterInfo(id: $id, title: $title, order: $order)';
}

/// Chapter select status for UI display
class ChapterSelectStatus {
  /// Chapter information
  final ChapterInfo chapter;

  /// Whether this chapter is unlocked
  final bool isUnlocked;

  /// Whether this chapter has been completed
  final bool isCompleted;

  /// Unlock date if unlocked
  final DateTime? unlockDate;

  const ChapterSelectStatus({
    required this.chapter,
    required this.isUnlocked,
    this.isCompleted = false,
    this.unlockDate,
  });

  ChapterSelectStatus copyWith({
    ChapterInfo? chapter,
    bool? isUnlocked,
    bool? isCompleted,
    DateTime? unlockDate,
  }) {
    return ChapterSelectStatus(
      chapter: chapter ?? this.chapter,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      unlockDate: unlockDate ?? this.unlockDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterSelectStatus &&
          runtimeType == other.runtimeType &&
          chapter == other.chapter &&
          isUnlocked == other.isUnlocked &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(chapter, isUnlocked, isCompleted);
}
