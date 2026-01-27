/// Visual Novel Save System - Data Models
/// 
/// Implements commercial-grade save data structures for VN runtime.
/// Requirements: 13.9

/// User settings stored with save data
class VNUserSettings {
  /// Text display speed (0.0 - 1.0)
  final double textSpeed;
  
  /// Auto mode delay in seconds
  final double autoSpeed;
  
  /// BGM volume (0.0 - 1.0)
  final double bgmVolume;
  
  /// SFX volume (0.0 - 1.0)
  final double sfxVolume;
  
  /// Voice volume (0.0 - 1.0)
  final double voiceVolume;
  
  /// Whether to skip unread text in skip mode
  final bool skipUnread;
  
  /// Fullscreen mode
  final bool fullscreen;

  const VNUserSettings({
    this.textSpeed = 0.5,
    this.autoSpeed = 1.5,
    this.bgmVolume = 0.8,
    this.sfxVolume = 0.8,
    this.voiceVolume = 1.0,
    this.skipUnread = false,
    this.fullscreen = false,
  });

  VNUserSettings copyWith({
    double? textSpeed,
    double? autoSpeed,
    double? bgmVolume,
    double? sfxVolume,
    double? voiceVolume,
    bool? skipUnread,
    bool? fullscreen,
  }) {
    return VNUserSettings(
      textSpeed: textSpeed ?? this.textSpeed,
      autoSpeed: autoSpeed ?? this.autoSpeed,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      skipUnread: skipUnread ?? this.skipUnread,
      fullscreen: fullscreen ?? this.fullscreen,
    );
  }

  Map<String, dynamic> toJson() => {
    'textSpeed': textSpeed,
    'autoSpeed': autoSpeed,
    'bgmVolume': bgmVolume,
    'sfxVolume': sfxVolume,
    'voiceVolume': voiceVolume,
    'skipUnread': skipUnread,
    'fullscreen': fullscreen,
  };

  factory VNUserSettings.fromJson(Map<String, dynamic> json) {
    return VNUserSettings(
      textSpeed: (json['textSpeed'] as num?)?.toDouble() ?? 0.5,
      autoSpeed: (json['autoSpeed'] as num?)?.toDouble() ?? 1.5,
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 0.8,
      voiceVolume: (json['voiceVolume'] as num?)?.toDouble() ?? 1.0,
      skipUnread: json['skipUnread'] as bool? ?? false,
      fullscreen: json['fullscreen'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VNUserSettings &&
          runtimeType == other.runtimeType &&
          textSpeed == other.textSpeed &&
          autoSpeed == other.autoSpeed &&
          bgmVolume == other.bgmVolume &&
          sfxVolume == other.sfxVolume &&
          voiceVolume == other.voiceVolume &&
          skipUnread == other.skipUnread &&
          fullscreen == other.fullscreen;

  @override
  int get hashCode => Object.hash(
    textSpeed, autoSpeed, bgmVolume, sfxVolume, 
    voiceVolume, skipUnread, fullscreen,
  );
}


/// Backlog entry representing a single dialogue in history
class BacklogEntry {
  /// Chapter ID where this dialogue occurred
  final String chapterId;
  
  /// Node ID containing this dialogue
  final String nodeId;
  
  /// Index of the dialogue line within the node
  final int dialogueIndex;
  
  /// Speaker name (display name, not ID)
  final String speakerName;
  
  /// Dialogue text content
  final String text;
  
  /// Optional voice file ID
  final String? voiceId;
  
  /// Timestamp when this dialogue was displayed
  final DateTime timestamp;

  BacklogEntry({
    required this.chapterId,
    required this.nodeId,
    required this.dialogueIndex,
    required this.speakerName,
    required this.text,
    this.voiceId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Unique identifier for read state tracking
  /// Format: "chapterId:nodeId:dialogueIndex"
  String get dialogueId => '$chapterId:$nodeId:$dialogueIndex';

  Map<String, dynamic> toJson() => {
    'chapterId': chapterId,
    'nodeId': nodeId,
    'dialogueIndex': dialogueIndex,
    'speakerName': speakerName,
    'text': text,
    'voiceId': voiceId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BacklogEntry.fromJson(Map<String, dynamic> json) {
    return BacklogEntry(
      chapterId: json['chapterId'] as String,
      nodeId: json['nodeId'] as String,
      dialogueIndex: json['dialogueIndex'] as int,
      speakerName: json['speakerName'] as String,
      text: json['text'] as String,
      voiceId: json['voiceId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklogEntry &&
          runtimeType == other.runtimeType &&
          chapterId == other.chapterId &&
          nodeId == other.nodeId &&
          dialogueIndex == other.dialogueIndex &&
          speakerName == other.speakerName &&
          text == other.text &&
          voiceId == other.voiceId;

  @override
  int get hashCode => Object.hash(
    chapterId, nodeId, dialogueIndex, speakerName, text, voiceId,
  );
}


/// Complete save data for a single save slot
class VNSaveData {
  /// Unique save identifier
  final String saveId;
  
  /// Story version for compatibility checking
  final String storyVersion;
  
  /// When this save was created
  final DateTime timestamp;
  
  /// Base64 encoded screenshot thumbnail
  final String? thumbnailBase64;
  
  /// Current chapter ID
  final String currentChapterId;
  
  /// Current node ID within the chapter
  final String currentNodeId;
  
  /// Current dialogue index within the scene node
  final int currentDialogueIndex;
  
  /// All variable values (global and chapter)
  final Map<String, dynamic> variables;
  
  /// Set of read dialogue IDs (format: "chapterId:nodeId:dialogueIndex")
  final Set<String> readDialogueIds;
  
  /// Backlog history entries
  final List<BacklogEntry> backlog;
  
  /// Unlocked CG IDs
  final Set<String> unlockedCGs;
  
  /// Unlocked BGM IDs
  final Set<String> unlockedBGM;
  
  /// Unlocked scene IDs for replay
  final Set<String> unlockedScenes;
  
  /// User settings at save time
  final VNUserSettings userSettings;

  VNSaveData({
    required this.saveId,
    required this.storyVersion,
    required this.timestamp,
    this.thumbnailBase64,
    required this.currentChapterId,
    required this.currentNodeId,
    required this.currentDialogueIndex,
    required this.variables,
    required this.readDialogueIds,
    required this.backlog,
    required this.unlockedCGs,
    required this.unlockedBGM,
    required this.unlockedScenes,
    required this.userSettings,
  });

  /// Create a new save with updated position
  VNSaveData copyWith({
    String? saveId,
    String? storyVersion,
    DateTime? timestamp,
    String? thumbnailBase64,
    String? currentChapterId,
    String? currentNodeId,
    int? currentDialogueIndex,
    Map<String, dynamic>? variables,
    Set<String>? readDialogueIds,
    List<BacklogEntry>? backlog,
    Set<String>? unlockedCGs,
    Set<String>? unlockedBGM,
    Set<String>? unlockedScenes,
    VNUserSettings? userSettings,
  }) {
    return VNSaveData(
      saveId: saveId ?? this.saveId,
      storyVersion: storyVersion ?? this.storyVersion,
      timestamp: timestamp ?? this.timestamp,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      currentDialogueIndex: currentDialogueIndex ?? this.currentDialogueIndex,
      variables: variables ?? Map.from(this.variables),
      readDialogueIds: readDialogueIds ?? Set.from(this.readDialogueIds),
      backlog: backlog ?? List.from(this.backlog),
      unlockedCGs: unlockedCGs ?? Set.from(this.unlockedCGs),
      unlockedBGM: unlockedBGM ?? Set.from(this.unlockedBGM),
      unlockedScenes: unlockedScenes ?? Set.from(this.unlockedScenes),
      userSettings: userSettings ?? this.userSettings,
    );
  }

  Map<String, dynamic> toJson() => {
    'saveId': saveId,
    'storyVersion': storyVersion,
    'timestamp': timestamp.toIso8601String(),
    'thumbnailBase64': thumbnailBase64,
    'currentChapterId': currentChapterId,
    'currentNodeId': currentNodeId,
    'currentDialogueIndex': currentDialogueIndex,
    'variables': variables,
    'readDialogueIds': readDialogueIds.toList(),
    'backlog': backlog.map((e) => e.toJson()).toList(),
    'unlockedCGs': unlockedCGs.toList(),
    'unlockedBGM': unlockedBGM.toList(),
    'unlockedScenes': unlockedScenes.toList(),
    'userSettings': userSettings.toJson(),
  };

  factory VNSaveData.fromJson(Map<String, dynamic> json) {
    return VNSaveData(
      saveId: json['saveId'] as String,
      storyVersion: json['storyVersion'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      thumbnailBase64: json['thumbnailBase64'] as String?,
      currentChapterId: json['currentChapterId'] as String,
      currentNodeId: json['currentNodeId'] as String,
      currentDialogueIndex: json['currentDialogueIndex'] as int,
      variables: Map<String, dynamic>.from(json['variables'] as Map),
      readDialogueIds: Set<String>.from(json['readDialogueIds'] as List),
      backlog: (json['backlog'] as List)
          .map((e) => BacklogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedCGs: Set<String>.from(json['unlockedCGs'] as List),
      unlockedBGM: Set<String>.from(json['unlockedBGM'] as List),
      unlockedScenes: Set<String>.from(json['unlockedScenes'] as List),
      userSettings: VNUserSettings.fromJson(
        json['userSettings'] as Map<String, dynamic>,
      ),
    );
  }

  /// Migrate old save data to current version
  static VNSaveData? migrate(
    Map<String, dynamic> oldData, 
    String targetVersion,
  ) {
    final oldVersion = oldData['storyVersion'] as String?;
    if (oldVersion == null) return null;
    
    // Version migration logic
    var data = Map<String, dynamic>.from(oldData);
    
    // Add migration steps as versions evolve
    // Example: if (oldVersion == '0.9.0') { ... migrate to 1.0.0 ... }
    
    // Update version
    data['storyVersion'] = targetVersion;
    
    try {
      return VNSaveData.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VNSaveData &&
          runtimeType == other.runtimeType &&
          saveId == other.saveId &&
          storyVersion == other.storyVersion &&
          currentChapterId == other.currentChapterId &&
          currentNodeId == other.currentNodeId &&
          currentDialogueIndex == other.currentDialogueIndex;

  @override
  int get hashCode => Object.hash(
    saveId, storyVersion, currentChapterId, currentNodeId, currentDialogueIndex,
  );
}


/// Save slot type enumeration
enum SaveSlotType {
  /// Regular save slot (0-99)
  regular,
  /// Quick save slot (100-102)
  quick,
  /// Auto save slot (103-105)
  auto,
}

/// Represents a single save slot
class VNSaveSlot {
  /// Slot index (0-99 regular, 100-102 quick, 103-105 auto)
  final int slotIndex;
  
  /// Save ID if slot is occupied
  final String? saveId;
  
  /// Timestamp of the save
  final DateTime? timestamp;
  
  /// Path to thumbnail image
  final String? thumbnailPath;
  
  /// Full save data (may be null if only metadata loaded)
  final VNSaveData? data;

  const VNSaveSlot({
    required this.slotIndex,
    this.saveId,
    this.timestamp,
    this.thumbnailPath,
    this.data,
  });

  /// Whether this slot is empty
  bool get isEmpty => data == null && saveId == null;
  
  /// Whether this slot has data
  bool get hasData => data != null || saveId != null;

  /// Get the slot type based on index
  SaveSlotType get slotType {
    if (slotIndex >= 103) return SaveSlotType.auto;
    if (slotIndex >= 100) return SaveSlotType.quick;
    return SaveSlotType.regular;
  }

  /// Display name for the slot
  String get displayName {
    switch (slotType) {
      case SaveSlotType.regular:
        return 'Save ${slotIndex + 1}';
      case SaveSlotType.quick:
        return 'Quick Save ${slotIndex - 99}';
      case SaveSlotType.auto:
        return 'Auto Save ${slotIndex - 102}';
    }
  }

  VNSaveSlot copyWith({
    int? slotIndex,
    String? saveId,
    DateTime? timestamp,
    String? thumbnailPath,
    VNSaveData? data,
  }) {
    return VNSaveSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      saveId: saveId ?? this.saveId,
      timestamp: timestamp ?? this.timestamp,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'saveId': saveId,
    'timestamp': timestamp?.toIso8601String(),
    'thumbnailPath': thumbnailPath,
    'data': data?.toJson(),
  };

  factory VNSaveSlot.fromJson(Map<String, dynamic> json) {
    return VNSaveSlot(
      slotIndex: json['slotIndex'] as int,
      saveId: json['saveId'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      thumbnailPath: json['thumbnailPath'] as String?,
      data: json['data'] != null 
          ? VNSaveData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create an empty slot
  factory VNSaveSlot.empty(int slotIndex) {
    return VNSaveSlot(slotIndex: slotIndex);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VNSaveSlot &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          saveId == other.saveId;

  @override
  int get hashCode => Object.hash(slotIndex, saveId);
}
