/// Engine state for VN Runtime
/// 
/// Represents the current state of the VN engine during playback.

/// Playback state of the engine
enum VNPlaybackState {
  /// Engine is not started
  idle,
  
  /// Engine is playing
  playing,
  
  /// Engine is paused
  paused,
  
  /// Engine is waiting for user input (e.g., choice selection)
  waitingForInput,
  
  /// Engine has reached an ending
  ended,
  
  /// Engine encountered an error
  error,
}

/// Current position in the story
class StoryPosition {
  /// Current chapter ID
  final String chapterId;
  
  /// Current node ID
  final String nodeId;
  
  /// Current dialogue index within a scene node (0-based)
  final int dialogueIndex;

  const StoryPosition({
    required this.chapterId,
    required this.nodeId,
    this.dialogueIndex = 0,
  });

  StoryPosition copyWith({
    String? chapterId,
    String? nodeId,
    int? dialogueIndex,
  }) {
    return StoryPosition(
      chapterId: chapterId ?? this.chapterId,
      nodeId: nodeId ?? this.nodeId,
      dialogueIndex: dialogueIndex ?? this.dialogueIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoryPosition &&
        other.chapterId == chapterId &&
        other.nodeId == nodeId &&
        other.dialogueIndex == dialogueIndex;
  }

  @override
  int get hashCode => Object.hash(chapterId, nodeId, dialogueIndex);

  @override
  String toString() => 'StoryPosition($chapterId:$nodeId:$dialogueIndex)';

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'nodeId': nodeId,
        'dialogueIndex': dialogueIndex,
      };

  factory StoryPosition.fromJson(Map<String, dynamic> json) {
    return StoryPosition(
      chapterId: json['chapterId'] as String,
      nodeId: json['nodeId'] as String,
      dialogueIndex: json['dialogueIndex'] as int? ?? 0,
    );
  }
}

/// Complete engine state snapshot
class VNEngineState {
  /// Current playback state
  final VNPlaybackState playbackState;
  
  /// Current position in the story
  final StoryPosition? position;
  
  /// Current variable values
  final Map<String, dynamic> variables;
  
  /// Set of read dialogue IDs (format: "chapterId:nodeId:dialogueIndex")
  final Set<String> readDialogueIds;
  
  /// Current background resource ID
  final String? currentBackgroundId;
  
  /// Current BGM resource ID
  final String? currentBgmId;
  
  /// Currently displayed characters with their positions
  final Map<String, CharacterDisplayState> displayedCharacters;
  
  /// Error message if in error state
  final String? errorMessage;

  const VNEngineState({
    this.playbackState = VNPlaybackState.idle,
    this.position,
    this.variables = const {},
    this.readDialogueIds = const {},
    this.currentBackgroundId,
    this.currentBgmId,
    this.displayedCharacters = const {},
    this.errorMessage,
  });

  VNEngineState copyWith({
    VNPlaybackState? playbackState,
    StoryPosition? position,
    Map<String, dynamic>? variables,
    Set<String>? readDialogueIds,
    String? currentBackgroundId,
    String? currentBgmId,
    Map<String, CharacterDisplayState>? displayedCharacters,
    String? errorMessage,
  }) {
    return VNEngineState(
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      variables: variables ?? this.variables,
      readDialogueIds: readDialogueIds ?? this.readDialogueIds,
      currentBackgroundId: currentBackgroundId ?? this.currentBackgroundId,
      currentBgmId: currentBgmId ?? this.currentBgmId,
      displayedCharacters: displayedCharacters ?? this.displayedCharacters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if a dialogue has been read
  bool isDialogueRead(String chapterId, String nodeId, int dialogueIndex) {
    return readDialogueIds.contains('$chapterId:$nodeId:$dialogueIndex');
  }

  Map<String, dynamic> toJson() => {
        'playbackState': playbackState.name,
        if (position != null) 'position': position!.toJson(),
        'variables': variables,
        'readDialogueIds': readDialogueIds.toList(),
        if (currentBackgroundId != null) 'currentBackgroundId': currentBackgroundId,
        if (currentBgmId != null) 'currentBgmId': currentBgmId,
        'displayedCharacters': displayedCharacters.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory VNEngineState.fromJson(Map<String, dynamic> json) {
    return VNEngineState(
      playbackState: VNPlaybackState.values.firstWhere(
        (e) => e.name == json['playbackState'],
        orElse: () => VNPlaybackState.idle,
      ),
      position: json['position'] != null
          ? StoryPosition.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      variables: (json['variables'] as Map<String, dynamic>?) ?? const {},
      readDialogueIds: (json['readDialogueIds'] as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          const {},
      currentBackgroundId: json['currentBackgroundId'] as String?,
      currentBgmId: json['currentBgmId'] as String?,
      displayedCharacters: (json['displayedCharacters'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                    k,
                    CharacterDisplayState.fromJson(v as Map<String, dynamic>),
                  )) ??
          const {},
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Display state for a character on screen
class CharacterDisplayState {
  /// Character ID
  final String characterId;
  
  /// Current expression
  final String? expression;
  
  /// Position slot
  final String slot;
  
  /// Custom X position (if slot is 'custom')
  final double? customX;
  
  /// Custom Y position (if slot is 'custom')
  final double? customY;
  
  /// Scale factor
  final double scale;
  
  /// Whether the sprite is flipped horizontally
  final bool flipped;
  
  /// Whether this character is currently speaking
  final bool isSpeaking;

  const CharacterDisplayState({
    required this.characterId,
    this.expression,
    this.slot = 'center',
    this.customX,
    this.customY,
    this.scale = 1.0,
    this.flipped = false,
    this.isSpeaking = false,
  });

  CharacterDisplayState copyWith({
    String? characterId,
    String? expression,
    String? slot,
    double? customX,
    double? customY,
    double? scale,
    bool? flipped,
    bool? isSpeaking,
  }) {
    return CharacterDisplayState(
      characterId: characterId ?? this.characterId,
      expression: expression ?? this.expression,
      slot: slot ?? this.slot,
      customX: customX ?? this.customX,
      customY: customY ?? this.customY,
      scale: scale ?? this.scale,
      flipped: flipped ?? this.flipped,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        if (expression != null) 'expression': expression,
        'slot': slot,
        if (customX != null) 'customX': customX,
        if (customY != null) 'customY': customY,
        'scale': scale,
        'flipped': flipped,
        'isSpeaking': isSpeaking,
      };

  factory CharacterDisplayState.fromJson(Map<String, dynamic> json) {
    return CharacterDisplayState(
      characterId: json['characterId'] as String,
      expression: json['expression'] as String?,
      slot: json['slot'] as String? ?? 'center',
      customX: (json['customX'] as num?)?.toDouble(),
      customY: (json['customY'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      flipped: json['flipped'] as bool? ?? false,
      isSpeaking: json['isSpeaking'] as bool? ?? false,
    );
  }
}
