/// Global Progress Manager for VNBS Commercial Features
///
/// Manages cross-save global progress data including:
/// - Achievements
/// - Endings
/// - Scene replay unlocks
/// - Play statistics
/// - Flowchart state
///
/// Requirements: 1.8, 2.9, 3.7, 7.6, 6.1, 6.6

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Progress event base class
abstract class ProgressEvent {
  final DateTime timestamp;
  ProgressEvent() : timestamp = DateTime.now();

  Map<String, dynamic> toJson();
}

/// Event emitted when an achievement is unlocked
class AchievementUnlockedEvent extends ProgressEvent {
  final String achievementId;
  final String achievementName;

  AchievementUnlockedEvent({
    required this.achievementId,
    required this.achievementName,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'achievement_unlocked',
        'achievementId': achievementId,
        'achievementName': achievementName,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when an ending is reached
class EndingReachedEvent extends ProgressEvent {
  final String endingId;
  final String endingName;

  EndingReachedEvent({
    required this.endingId,
    required this.endingName,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ending_reached',
        'endingId': endingId,
        'endingName': endingName,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when a scene is unlocked for replay
class SceneUnlockedEvent extends ProgressEvent {
  final String sceneId;

  SceneUnlockedEvent({required this.sceneId});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'scene_unlocked',
        'sceneId': sceneId,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when a CG is unlocked
class CGUnlockedEvent extends ProgressEvent {
  final String cgId;

  CGUnlockedEvent({required this.cgId});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cg_unlocked',
        'cgId': cgId,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when a BGM is unlocked
class BGMUnlockedEvent extends ProgressEvent {
  final String bgmId;

  BGMUnlockedEvent({required this.bgmId});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'bgm_unlocked',
        'bgmId': bgmId,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when a journal entry is unlocked
class JournalEntryUnlockedEvent extends ProgressEvent {
  final String entryId;
  final String entryTitle;

  JournalEntryUnlockedEvent({
    required this.entryId,
    required this.entryTitle,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'journal_entry_unlocked',
        'entryId': entryId,
        'entryTitle': entryTitle,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event emitted when statistics are updated
class StatisticsUpdatedEvent extends ProgressEvent {
  final String statType;
  final dynamic oldValue;
  final dynamic newValue;

  StatisticsUpdatedEvent({
    required this.statType,
    this.oldValue,
    this.newValue,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'statistics_updated',
        'statType': statType,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': timestamp.toIso8601String(),
      };
}


/// Achievement data stored in global progress
class AchievementProgressData {
  final Set<String> unlockedIds;
  final Map<String, DateTime> unlockDates;

  const AchievementProgressData({
    this.unlockedIds = const {},
    this.unlockDates = const {},
  });

  AchievementProgressData copyWith({
    Set<String>? unlockedIds,
    Map<String, DateTime>? unlockDates,
  }) {
    return AchievementProgressData(
      unlockedIds: unlockedIds ?? Set.from(this.unlockedIds),
      unlockDates: unlockDates ?? Map.from(this.unlockDates),
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlockedIds.toList(),
        'unlockDates': unlockDates.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
      };

  factory AchievementProgressData.fromJson(Map<String, dynamic> json) {
    return AchievementProgressData(
      unlockedIds: Set<String>.from(json['unlocked'] as List? ?? []),
      unlockDates: (json['unlockDates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, DateTime.parse(v as String)),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementProgressData &&
          runtimeType == other.runtimeType &&
          _setEquals(unlockedIds, other.unlockedIds) &&
          _mapEquals(unlockDates, other.unlockDates);

  @override
  int get hashCode => Object.hash(unlockedIds.length, unlockDates.length);
}

/// Ending data stored in global progress
class EndingProgressData {
  final Set<String> reachedIds;
  final Map<String, DateTime> reachDates;
  final List<String> reachOrder;

  const EndingProgressData({
    this.reachedIds = const {},
    this.reachDates = const {},
    this.reachOrder = const [],
  });

  EndingProgressData copyWith({
    Set<String>? reachedIds,
    Map<String, DateTime>? reachDates,
    List<String>? reachOrder,
  }) {
    return EndingProgressData(
      reachedIds: reachedIds ?? Set.from(this.reachedIds),
      reachDates: reachDates ?? Map.from(this.reachDates),
      reachOrder: reachOrder ?? List.from(this.reachOrder),
    );
  }

  Map<String, dynamic> toJson() => {
        'reached': reachedIds.toList(),
        'reachDates': reachDates.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'reachOrder': reachOrder,
      };

  factory EndingProgressData.fromJson(Map<String, dynamic> json) {
    return EndingProgressData(
      reachedIds: Set<String>.from(json['reached'] as List? ?? []),
      reachDates: (json['reachDates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, DateTime.parse(v as String)),
      ),
      reachOrder: List<String>.from(json['reachOrder'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndingProgressData &&
          runtimeType == other.runtimeType &&
          _setEquals(reachedIds, other.reachedIds) &&
          _listEquals(reachOrder, other.reachOrder);

  @override
  int get hashCode => Object.hash(reachedIds.length, reachOrder.length);
}

/// Scene replay data stored in global progress
class SceneReplayProgressData {
  final Set<String> unlockedIds;

  const SceneReplayProgressData({
    this.unlockedIds = const {},
  });

  SceneReplayProgressData copyWith({Set<String>? unlockedIds}) {
    return SceneReplayProgressData(
      unlockedIds: unlockedIds ?? Set.from(this.unlockedIds),
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlockedIds.toList(),
      };

  factory SceneReplayProgressData.fromJson(Map<String, dynamic> json) {
    return SceneReplayProgressData(
      unlockedIds: Set<String>.from(json['unlocked'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneReplayProgressData &&
          runtimeType == other.runtimeType &&
          _setEquals(unlockedIds, other.unlockedIds);

  @override
  int get hashCode => unlockedIds.length.hashCode;
}


/// Ending record for statistics
class EndingRecord {
  final String endingId;
  final String endingName;
  final DateTime timestamp;

  const EndingRecord({
    required this.endingId,
    required this.endingName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'endingId': endingId,
        'endingName': endingName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EndingRecord.fromJson(Map<String, dynamic> json) {
    return EndingRecord(
      endingId: json['endingId'] as String,
      endingName: json['endingName'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndingRecord &&
          runtimeType == other.runtimeType &&
          endingId == other.endingId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(endingId, timestamp);
}

/// Play statistics data stored in global progress
class PlayStatisticsData {
  /// Total play time in milliseconds
  final int totalPlayTimeMs;

  /// Total dialogues read (including re-reads)
  final int totalDialoguesRead;

  /// Unique dialogue IDs that have been read
  final Set<String> uniqueDialoguesRead;

  /// Choice distribution: choiceNodeId -> {optionId -> count}
  final Map<String, Map<String, int>> choiceDistribution;

  /// History of endings reached
  final List<EndingRecord> endingHistory;

  const PlayStatisticsData({
    this.totalPlayTimeMs = 0,
    this.totalDialoguesRead = 0,
    this.uniqueDialoguesRead = const {},
    this.choiceDistribution = const {},
    this.endingHistory = const [],
  });

  Duration get totalPlayTime => Duration(milliseconds: totalPlayTimeMs);

  PlayStatisticsData copyWith({
    int? totalPlayTimeMs,
    int? totalDialoguesRead,
    Set<String>? uniqueDialoguesRead,
    Map<String, Map<String, int>>? choiceDistribution,
    List<EndingRecord>? endingHistory,
  }) {
    return PlayStatisticsData(
      totalPlayTimeMs: totalPlayTimeMs ?? this.totalPlayTimeMs,
      totalDialoguesRead: totalDialoguesRead ?? this.totalDialoguesRead,
      uniqueDialoguesRead:
          uniqueDialoguesRead ?? Set.from(this.uniqueDialoguesRead),
      choiceDistribution: choiceDistribution ??
          this.choiceDistribution.map(
                (k, v) => MapEntry(k, Map.from(v)),
              ),
      endingHistory: endingHistory ?? List.from(this.endingHistory),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPlayTime': totalPlayTimeMs,
        'totalDialoguesRead': totalDialoguesRead,
        'uniqueDialoguesRead': uniqueDialoguesRead.toList(),
        'choiceDistribution': choiceDistribution,
        'endingHistory': endingHistory.map((e) => e.toJson()).toList(),
      };

  factory PlayStatisticsData.fromJson(Map<String, dynamic> json) {
    return PlayStatisticsData(
      totalPlayTimeMs: json['totalPlayTime'] as int? ?? 0,
      totalDialoguesRead: json['totalDialoguesRead'] as int? ?? 0,
      uniqueDialoguesRead:
          Set<String>.from(json['uniqueDialoguesRead'] as List? ?? []),
      choiceDistribution:
          (json['choiceDistribution'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          (v as Map<String, dynamic>).map(
            (k2, v2) => MapEntry(k2, v2 as int),
          ),
        ),
      ),
      endingHistory: (json['endingHistory'] as List? ?? [])
          .map((e) => EndingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayStatisticsData &&
          runtimeType == other.runtimeType &&
          totalPlayTimeMs == other.totalPlayTimeMs &&
          totalDialoguesRead == other.totalDialoguesRead &&
          _setEquals(uniqueDialoguesRead, other.uniqueDialoguesRead);

  @override
  int get hashCode =>
      Object.hash(totalPlayTimeMs, totalDialoguesRead, uniqueDialoguesRead.length);
}

/// Flowchart state data stored in global progress
class FlowchartStateData {
  final Set<String> visitedNodeIds;
  final Set<String> visitedEdges; // Format: "fromId->toId"

  const FlowchartStateData({
    this.visitedNodeIds = const {},
    this.visitedEdges = const {},
  });

  FlowchartStateData copyWith({
    Set<String>? visitedNodeIds,
    Set<String>? visitedEdges,
  }) {
    return FlowchartStateData(
      visitedNodeIds: visitedNodeIds ?? Set.from(this.visitedNodeIds),
      visitedEdges: visitedEdges ?? Set.from(this.visitedEdges),
    );
  }

  Map<String, dynamic> toJson() => {
        'visitedNodes': visitedNodeIds.toList(),
        'visitedEdges': visitedEdges.toList(),
      };

  factory FlowchartStateData.fromJson(Map<String, dynamic> json) {
    return FlowchartStateData(
      visitedNodeIds: Set<String>.from(json['visitedNodes'] as List? ?? []),
      visitedEdges: Set<String>.from(json['visitedEdges'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowchartStateData &&
          runtimeType == other.runtimeType &&
          _setEquals(visitedNodeIds, other.visitedNodeIds) &&
          _setEquals(visitedEdges, other.visitedEdges);

  @override
  int get hashCode => Object.hash(visitedNodeIds.length, visitedEdges.length);
}


/// Gallery unlock data stored in global progress
class GalleryProgressData {
  final Set<String> unlockedCGs;
  final Set<String> unlockedBGMs;

  const GalleryProgressData({
    this.unlockedCGs = const {},
    this.unlockedBGMs = const {},
  });

  GalleryProgressData copyWith({
    Set<String>? unlockedCGs,
    Set<String>? unlockedBGMs,
  }) {
    return GalleryProgressData(
      unlockedCGs: unlockedCGs ?? Set.from(this.unlockedCGs),
      unlockedBGMs: unlockedBGMs ?? Set.from(this.unlockedBGMs),
    );
  }

  Map<String, dynamic> toJson() => {
        'unlockedCGs': unlockedCGs.toList(),
        'unlockedBGMs': unlockedBGMs.toList(),
      };

  factory GalleryProgressData.fromJson(Map<String, dynamic> json) {
    return GalleryProgressData(
      unlockedCGs: Set<String>.from(json['unlockedCGs'] as List? ?? []),
      unlockedBGMs: Set<String>.from(json['unlockedBGMs'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryProgressData &&
          runtimeType == other.runtimeType &&
          _setEquals(unlockedCGs, other.unlockedCGs) &&
          _setEquals(unlockedBGMs, other.unlockedBGMs);

  @override
  int get hashCode => Object.hash(unlockedCGs.length, unlockedBGMs.length);
}

/// Chapter select data stored in global progress
class ChapterSelectData {
  final Set<String> unlockedChapterIds;
  final bool firstPlaythroughComplete;

  const ChapterSelectData({
    this.unlockedChapterIds = const {},
    this.firstPlaythroughComplete = false,
  });

  ChapterSelectData copyWith({
    Set<String>? unlockedChapterIds,
    bool? firstPlaythroughComplete,
  }) {
    return ChapterSelectData(
      unlockedChapterIds:
          unlockedChapterIds ?? Set.from(this.unlockedChapterIds),
      firstPlaythroughComplete:
          firstPlaythroughComplete ?? this.firstPlaythroughComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlockedChapters': unlockedChapterIds.toList(),
        'firstPlaythroughComplete': firstPlaythroughComplete,
      };

  factory ChapterSelectData.fromJson(Map<String, dynamic> json) {
    return ChapterSelectData(
      unlockedChapterIds:
          Set<String>.from(json['unlockedChapters'] as List? ?? []),
      firstPlaythroughComplete:
          json['firstPlaythroughComplete'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterSelectData &&
          runtimeType == other.runtimeType &&
          _setEquals(unlockedChapterIds, other.unlockedChapterIds) &&
          firstPlaythroughComplete == other.firstPlaythroughComplete;

  @override
  int get hashCode =>
      Object.hash(unlockedChapterIds.length, firstPlaythroughComplete);
}

/// Journal/Codex data stored in global progress
class JournalProgressData {
  final Set<String> unlockedEntryIds;

  const JournalProgressData({
    this.unlockedEntryIds = const {},
  });

  JournalProgressData copyWith({Set<String>? unlockedEntryIds}) {
    return JournalProgressData(
      unlockedEntryIds: unlockedEntryIds ?? Set.from(this.unlockedEntryIds),
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlockedEntryIds.toList(),
      };

  factory JournalProgressData.fromJson(Map<String, dynamic> json) {
    return JournalProgressData(
      unlockedEntryIds: Set<String>.from(json['unlocked'] as List? ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalProgressData &&
          runtimeType == other.runtimeType &&
          _setEquals(unlockedEntryIds, other.unlockedEntryIds);

  @override
  int get hashCode => unlockedEntryIds.length.hashCode;
}

/// Affection data stored in global progress
class AffectionProgressData {
  final Map<String, int> values;

  const AffectionProgressData({
    this.values = const {},
  });

  AffectionProgressData copyWith({Map<String, int>? values}) {
    return AffectionProgressData(
      values: values ?? Map.from(this.values),
    );
  }

  Map<String, dynamic> toJson() => values;

  factory AffectionProgressData.fromJson(Map<String, dynamic> json) {
    return AffectionProgressData(
      values: json.map((k, v) => MapEntry(k, v as int)),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffectionProgressData &&
          runtimeType == other.runtimeType &&
          _mapEquals(values, other.values);

  @override
  int get hashCode => values.length.hashCode;
}


/// Complete global progress data
class GlobalProgressData {
  static const String currentVersion = '1.0.0';

  final String version;
  final DateTime lastModified;
  final AchievementProgressData achievements;
  final EndingProgressData endings;
  final SceneReplayProgressData sceneReplay;
  final PlayStatisticsData statistics;
  final FlowchartStateData flowchart;
  final GalleryProgressData gallery;
  final ChapterSelectData chapterSelect;
  final JournalProgressData journal;
  final AffectionProgressData affection;

  GlobalProgressData({
    this.version = currentVersion,
    DateTime? lastModified,
    this.achievements = const AchievementProgressData(),
    this.endings = const EndingProgressData(),
    this.sceneReplay = const SceneReplayProgressData(),
    this.statistics = const PlayStatisticsData(),
    this.flowchart = const FlowchartStateData(),
    this.gallery = const GalleryProgressData(),
    this.chapterSelect = const ChapterSelectData(),
    this.journal = const JournalProgressData(),
    this.affection = const AffectionProgressData(),
  }) : lastModified = lastModified ?? DateTime.now();

  GlobalProgressData copyWith({
    String? version,
    DateTime? lastModified,
    AchievementProgressData? achievements,
    EndingProgressData? endings,
    SceneReplayProgressData? sceneReplay,
    PlayStatisticsData? statistics,
    FlowchartStateData? flowchart,
    GalleryProgressData? gallery,
    ChapterSelectData? chapterSelect,
    JournalProgressData? journal,
    AffectionProgressData? affection,
  }) {
    return GlobalProgressData(
      version: version ?? this.version,
      lastModified: lastModified ?? DateTime.now(),
      achievements: achievements ?? this.achievements,
      endings: endings ?? this.endings,
      sceneReplay: sceneReplay ?? this.sceneReplay,
      statistics: statistics ?? this.statistics,
      flowchart: flowchart ?? this.flowchart,
      gallery: gallery ?? this.gallery,
      chapterSelect: chapterSelect ?? this.chapterSelect,
      journal: journal ?? this.journal,
      affection: affection ?? this.affection,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastModified': lastModified.toIso8601String(),
        'achievements': achievements.toJson(),
        'endings': endings.toJson(),
        'sceneReplay': sceneReplay.toJson(),
        'statistics': statistics.toJson(),
        'flowchart': flowchart.toJson(),
        'gallery': gallery.toJson(),
        'chapterSelect': chapterSelect.toJson(),
        'journal': journal.toJson(),
        'affection': affection.toJson(),
      };

  factory GlobalProgressData.fromJson(Map<String, dynamic> json) {
    return GlobalProgressData(
      version: json['version'] as String? ?? currentVersion,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
      achievements: json['achievements'] != null
          ? AchievementProgressData.fromJson(
              json['achievements'] as Map<String, dynamic>)
          : const AchievementProgressData(),
      endings: json['endings'] != null
          ? EndingProgressData.fromJson(json['endings'] as Map<String, dynamic>)
          : const EndingProgressData(),
      sceneReplay: json['sceneReplay'] != null
          ? SceneReplayProgressData.fromJson(
              json['sceneReplay'] as Map<String, dynamic>)
          : const SceneReplayProgressData(),
      statistics: json['statistics'] != null
          ? PlayStatisticsData.fromJson(
              json['statistics'] as Map<String, dynamic>)
          : const PlayStatisticsData(),
      flowchart: json['flowchart'] != null
          ? FlowchartStateData.fromJson(
              json['flowchart'] as Map<String, dynamic>)
          : const FlowchartStateData(),
      gallery: json['gallery'] != null
          ? GalleryProgressData.fromJson(
              json['gallery'] as Map<String, dynamic>)
          : const GalleryProgressData(),
      chapterSelect: json['chapterSelect'] != null
          ? ChapterSelectData.fromJson(
              json['chapterSelect'] as Map<String, dynamic>)
          : const ChapterSelectData(),
      journal: json['journal'] != null
          ? JournalProgressData.fromJson(
              json['journal'] as Map<String, dynamic>)
          : const JournalProgressData(),
      affection: json['affection'] != null
          ? AffectionProgressData.fromJson(
              json['affection'] as Map<String, dynamic>)
          : const AffectionProgressData(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalProgressData &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          achievements == other.achievements &&
          endings == other.endings &&
          sceneReplay == other.sceneReplay &&
          statistics == other.statistics &&
          flowchart == other.flowchart &&
          gallery == other.gallery &&
          chapterSelect == other.chapterSelect &&
          journal == other.journal &&
          affection == other.affection;

  @override
  int get hashCode => Object.hash(
        version,
        achievements,
        endings,
        sceneReplay,
        statistics,
        flowchart,
        gallery,
        chapterSelect,
        journal,
        affection,
      );
}


/// Global Progress Manager
///
/// Manages all cross-save global progress data for VNBS commercial features.
/// This includes achievements, endings, scene replay, statistics, and more.
class GlobalProgressManager {
  static const String _defaultFileName = 'global.vnprogress';
  static const String _secretKey = 'vnbs_progress_v1';

  final String _projectId;
  final String? _customPath;

  GlobalProgressData _data = GlobalProgressData();
  DateTime? _sessionStartTime;
  bool _isDirty = false;

  final StreamController<ProgressEvent> _eventController =
      StreamController<ProgressEvent>.broadcast();

  /// Stream of progress events
  Stream<ProgressEvent> get progressEvents => _eventController.stream;

  /// Current progress data (read-only)
  GlobalProgressData get data => _data;

  /// Whether there are unsaved changes
  bool get isDirty => _isDirty;

  GlobalProgressManager({
    required String projectId,
    String? customPath,
  })  : _projectId = projectId,
        _customPath = customPath;

  // ============================================================
  // Achievement Methods
  // ============================================================

  /// Check if an achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _data.achievements.unlockedIds.contains(achievementId);
  }

  /// Unlock an achievement
  void unlockAchievement(String achievementId, {String? name}) {
    if (_data.achievements.unlockedIds.contains(achievementId)) return;

    final newUnlocked = Set<String>.from(_data.achievements.unlockedIds)
      ..add(achievementId);
    final newDates = Map<String, DateTime>.from(_data.achievements.unlockDates)
      ..[achievementId] = DateTime.now();

    _data = _data.copyWith(
      achievements: _data.achievements.copyWith(
        unlockedIds: newUnlocked,
        unlockDates: newDates,
      ),
    );
    _isDirty = true;

    _eventController.add(AchievementUnlockedEvent(
      achievementId: achievementId,
      achievementName: name ?? achievementId,
    ));
  }

  /// Get achievement unlock date
  DateTime? getAchievementUnlockDate(String achievementId) {
    return _data.achievements.unlockDates[achievementId];
  }

  // ============================================================
  // Ending Methods
  // ============================================================

  /// Check if an ending has been reached
  bool isEndingReached(String endingId) {
    return _data.endings.reachedIds.contains(endingId);
  }

  /// Record reaching an ending
  void recordEnding(String endingId, {String? name}) {
    if (_data.endings.reachedIds.contains(endingId)) return;

    final newReached = Set<String>.from(_data.endings.reachedIds)
      ..add(endingId);
    final newDates = Map<String, DateTime>.from(_data.endings.reachDates)
      ..[endingId] = DateTime.now();
    final newOrder = List<String>.from(_data.endings.reachOrder)..add(endingId);

    _data = _data.copyWith(
      endings: _data.endings.copyWith(
        reachedIds: newReached,
        reachDates: newDates,
        reachOrder: newOrder,
      ),
    );
    _isDirty = true;

    // Also record in statistics
    _recordEndingInStatistics(endingId, name ?? endingId);

    _eventController.add(EndingReachedEvent(
      endingId: endingId,
      endingName: name ?? endingId,
    ));
  }

  void _recordEndingInStatistics(String endingId, String name) {
    final newHistory = List<EndingRecord>.from(_data.statistics.endingHistory)
      ..add(EndingRecord(
        endingId: endingId,
        endingName: name,
        timestamp: DateTime.now(),
      ));

    _data = _data.copyWith(
      statistics: _data.statistics.copyWith(endingHistory: newHistory),
    );
  }

  /// Get ending reach date
  DateTime? getEndingReachDate(String endingId) {
    return _data.endings.reachDates[endingId];
  }

  /// Get ending completion percentage
  double getEndingCompletionPercentage(int totalEndings) {
    if (totalEndings == 0) return 0.0;
    return _data.endings.reachedIds.length / totalEndings;
  }

  // ============================================================
  // Scene Replay Methods
  // ============================================================

  /// Check if a scene is unlocked for replay
  bool isSceneUnlocked(String sceneId) {
    return _data.sceneReplay.unlockedIds.contains(sceneId);
  }

  /// Unlock a scene for replay
  void unlockScene(String sceneId) {
    if (_data.sceneReplay.unlockedIds.contains(sceneId)) return;

    final newUnlocked = Set<String>.from(_data.sceneReplay.unlockedIds)
      ..add(sceneId);

    _data = _data.copyWith(
      sceneReplay: _data.sceneReplay.copyWith(unlockedIds: newUnlocked),
    );
    _isDirty = true;

    _eventController.add(SceneUnlockedEvent(sceneId: sceneId));
  }

  // ============================================================
  // Gallery Methods
  // ============================================================

  /// Check if a CG is unlocked
  bool isCGUnlocked(String cgId) {
    return _data.gallery.unlockedCGs.contains(cgId);
  }

  /// Unlock a CG
  void unlockCG(String cgId) {
    if (_data.gallery.unlockedCGs.contains(cgId)) return;

    final newUnlocked = Set<String>.from(_data.gallery.unlockedCGs)..add(cgId);

    _data = _data.copyWith(
      gallery: _data.gallery.copyWith(unlockedCGs: newUnlocked),
    );
    _isDirty = true;

    _eventController.add(CGUnlockedEvent(cgId: cgId));
  }

  /// Check if a BGM is unlocked
  bool isBGMUnlocked(String bgmId) {
    return _data.gallery.unlockedBGMs.contains(bgmId);
  }

  /// Unlock a BGM
  void unlockBGM(String bgmId) {
    if (_data.gallery.unlockedBGMs.contains(bgmId)) return;

    final newUnlocked = Set<String>.from(_data.gallery.unlockedBGMs)..add(bgmId);

    _data = _data.copyWith(
      gallery: _data.gallery.copyWith(unlockedBGMs: newUnlocked),
    );
    _isDirty = true;

    _eventController.add(BGMUnlockedEvent(bgmId: bgmId));
  }


  // ============================================================
  // Statistics Methods
  // ============================================================

  /// Start a play session (call when game starts)
  void startSession() {
    _sessionStartTime = DateTime.now();
  }

  /// End a play session (call when game pauses/exits)
  void endSession() {
    if (_sessionStartTime == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    final newPlayTime =
        _data.statistics.totalPlayTimeMs + sessionDuration.inMilliseconds;

    _data = _data.copyWith(
      statistics: _data.statistics.copyWith(totalPlayTimeMs: newPlayTime),
    );
    _isDirty = true;
    _sessionStartTime = null;

    _eventController.add(StatisticsUpdatedEvent(
      statType: 'playTime',
      newValue: newPlayTime,
    ));
  }

  /// Record a dialogue being read
  void recordDialogueRead(String dialogueId) {
    final newTotal = _data.statistics.totalDialoguesRead + 1;
    final newUnique = Set<String>.from(_data.statistics.uniqueDialoguesRead)
      ..add(dialogueId);

    _data = _data.copyWith(
      statistics: _data.statistics.copyWith(
        totalDialoguesRead: newTotal,
        uniqueDialoguesRead: newUnique,
      ),
    );
    _isDirty = true;
  }

  /// Record a choice being made
  void recordChoice(String choiceNodeId, String selectedOptionId) {
    final newDistribution =
        Map<String, Map<String, int>>.from(_data.statistics.choiceDistribution);
    newDistribution.putIfAbsent(choiceNodeId, () => {});
    newDistribution[choiceNodeId]!.update(
      selectedOptionId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );

    _data = _data.copyWith(
      statistics: _data.statistics.copyWith(choiceDistribution: newDistribution),
    );
    _isDirty = true;
  }

  /// Get read progress percentage
  double getReadProgress(int totalDialogues) {
    if (totalDialogues == 0) return 0.0;
    return _data.statistics.uniqueDialoguesRead.length / totalDialogues;
  }

  /// Get choice percentages for a specific choice node
  Map<String, double> getChoicePercentages(String choiceNodeId) {
    final choices = _data.statistics.choiceDistribution[choiceNodeId];
    if (choices == null || choices.isEmpty) return {};

    final total = choices.values.fold(0, (sum, count) => sum + count);
    return choices.map((key, value) => MapEntry(key, value / total));
  }

  // ============================================================
  // Flowchart Methods
  // ============================================================

  /// Record visiting a flowchart node
  void recordNodeVisit(String nodeId) {
    if (_data.flowchart.visitedNodeIds.contains(nodeId)) return;

    final newVisited = Set<String>.from(_data.flowchart.visitedNodeIds)
      ..add(nodeId);

    _data = _data.copyWith(
      flowchart: _data.flowchart.copyWith(visitedNodeIds: newVisited),
    );
    _isDirty = true;
  }

  /// Record traversing an edge in the flowchart
  void recordEdgeVisit(String fromNodeId, String toNodeId) {
    final edgeKey = '$fromNodeId->$toNodeId';
    if (_data.flowchart.visitedEdges.contains(edgeKey)) return;

    final newEdges = Set<String>.from(_data.flowchart.visitedEdges)
      ..add(edgeKey);

    _data = _data.copyWith(
      flowchart: _data.flowchart.copyWith(visitedEdges: newEdges),
    );
    _isDirty = true;
  }

  /// Check if a node has been visited
  bool isNodeVisited(String nodeId) {
    return _data.flowchart.visitedNodeIds.contains(nodeId);
  }

  /// Check if an edge has been visited
  bool isEdgeVisited(String fromNodeId, String toNodeId) {
    return _data.flowchart.visitedEdges.contains('$fromNodeId->$toNodeId');
  }

  // ============================================================
  // Chapter Select Methods
  // ============================================================

  /// Check if a chapter is unlocked
  bool isChapterUnlocked(String chapterId) {
    return _data.chapterSelect.unlockedChapterIds.contains(chapterId);
  }

  /// Unlock a chapter
  void unlockChapter(String chapterId) {
    if (_data.chapterSelect.unlockedChapterIds.contains(chapterId)) return;

    final newUnlocked =
        Set<String>.from(_data.chapterSelect.unlockedChapterIds)..add(chapterId);

    _data = _data.copyWith(
      chapterSelect: _data.chapterSelect.copyWith(
        unlockedChapterIds: newUnlocked,
      ),
    );
    _isDirty = true;
  }

  /// Mark first playthrough as complete
  void markFirstPlaythroughComplete() {
    if (_data.chapterSelect.firstPlaythroughComplete) return;

    _data = _data.copyWith(
      chapterSelect: _data.chapterSelect.copyWith(
        firstPlaythroughComplete: true,
      ),
    );
    _isDirty = true;
  }

  /// Check if first playthrough is complete
  bool get isFirstPlaythroughComplete =>
      _data.chapterSelect.firstPlaythroughComplete;

  // ============================================================
  // Journal Methods
  // ============================================================

  /// Check if a journal entry is unlocked
  bool isJournalEntryUnlocked(String entryId) {
    return _data.journal.unlockedEntryIds.contains(entryId);
  }

  /// Unlock a journal entry
  void unlockJournalEntry(String entryId, {String? title}) {
    if (_data.journal.unlockedEntryIds.contains(entryId)) return;

    final newUnlocked = Set<String>.from(_data.journal.unlockedEntryIds)
      ..add(entryId);

    _data = _data.copyWith(
      journal: _data.journal.copyWith(unlockedEntryIds: newUnlocked),
    );
    _isDirty = true;

    _eventController.add(JournalEntryUnlockedEvent(
      entryId: entryId,
      entryTitle: title ?? entryId,
    ));
  }

  // ============================================================
  // Affection Methods
  // ============================================================

  /// Get affection value for a character
  int getAffection(String characterId) {
    return _data.affection.values[characterId] ?? 0;
  }

  /// Set affection value for a character
  void setAffection(String characterId, int value) {
    final newValues = Map<String, int>.from(_data.affection.values)
      ..[characterId] = value;

    _data = _data.copyWith(
      affection: _data.affection.copyWith(values: newValues),
    );
    _isDirty = true;
  }

  /// Add to affection value for a character
  void addAffection(String characterId, int delta) {
    final current = getAffection(characterId);
    setAffection(characterId, current + delta);
  }


  // ============================================================
  // Persistence Methods
  // ============================================================

  /// Get the file path for the progress file
  Future<String> _getFilePath() async {
    if (_customPath != null) {
      return _customPath!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/vnbs/$_projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    return '${projectDir.path}/$_defaultFileName';
  }

  /// Generate checksum for data integrity validation
  String generateChecksum(String content) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(content);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Validate checksum
  bool validateChecksum(String content, String checksum) {
    return generateChecksum(content) == checksum;
  }

  /// Save progress data to file
  Future<bool> save() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // Update last modified time
      _data = _data.copyWith(lastModified: DateTime.now());

      // Convert to JSON
      final jsonData = _data.toJson();
      final content = jsonEncode(jsonData);

      // Generate checksum
      final checksum = generateChecksum(content);

      // Create file content with checksum
      final fileContent = jsonEncode({
        'checksum': checksum,
        'data': jsonData,
      });

      // Write to file
      await file.writeAsString(fileContent);
      _isDirty = false;

      return true;
    } catch (e) {
      // Log error but don't crash
      print('Error saving global progress: $e');
      return false;
    }
  }

  /// Save progress only when there are pending changes
  Future<bool> saveIfDirty() async {
    if (!_isDirty) return true;
    return save();
  }

  /// Load progress data from file
  Future<bool> load() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        // No existing progress, start fresh
        _data = GlobalProgressData();
        _isDirty = false;
        return true;
      }

      final fileContent = await file.readAsString();
      final parsed = jsonDecode(fileContent) as Map<String, dynamic>;

      final storedChecksum = parsed['checksum'] as String?;
      final jsonData = parsed['data'] as Map<String, dynamic>?;

      if (jsonData == null) {
        // Invalid file format, reset
        _data = GlobalProgressData();
        _isDirty = false;
        return false;
      }

      // Validate checksum if present
      if (storedChecksum != null) {
        final content = jsonEncode(jsonData);
        if (!validateChecksum(content, storedChecksum)) {
          // Checksum mismatch - file may have been tampered with
          print('Warning: Progress file checksum mismatch');
          // Still load the data but mark as potentially corrupted
        }
      }

      _data = GlobalProgressData.fromJson(jsonData);
      _isDirty = false;

      return true;
    } catch (e) {
      // Log error and start fresh
      print('Error loading global progress: $e');
      _data = GlobalProgressData();
      _isDirty = false;
      return false;
    }
  }

  /// Reset all progress data
  Future<void> reset() async {
    _data = GlobalProgressData();
    _isDirty = true;
    await save();
  }

  /// Export progress data as JSON string
  String exportToJson() {
    return jsonEncode(_data.toJson());
  }

  /// Import progress data from JSON string
  bool importFromJson(String jsonString) {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _data = GlobalProgressData.fromJson(jsonData);
      _isDirty = true;
      return true;
    } catch (e) {
      print('Error importing progress: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    // End any active session
    if (_sessionStartTime != null) {
      endSession();
    }
    _eventController.close();
  }
}

// ============================================================
// Helper Functions
// ============================================================

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
