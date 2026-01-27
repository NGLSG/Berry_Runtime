import 'dart:ui';

/// VN node types
enum VNNodeType {
  start,      // Entry point for chapter
  scene,      // Scene with dialogues
  choice,     // Player choice branching
  jump,       // Jump to another node/chapter
  condition,  // Conditional branching (if/else)
  switch_,    // Multi-condition branching (if/elif/elif/.../else)
  variable,   // Variable operation
  effect,     // Visual/audio effect
  audio,      // Audio control
  ending,     // Story ending
  background, // Change background
  character,  // Show/hide/move character
  wait,       // Wait for time
  label,      // Label for jumping
  input,      // Player text input
  cg,         // Show CG image
  video,      // Play video
  achievement, // Unlock achievement
  particle,   // Particle effect (rain, snow, sakura, etc.)
  affection,  // Modify character affection value
  journal,    // Unlock journal entry
  minigame,   // Trigger mini-game
  script,     // Custom script execution
}

/// Text effect types for dialogue
enum TextEffectType {
  shake,
  wave,
  rainbow,
  fadeIn,
  typewriter,
}

/// Text effect configuration
class TextEffect {
  final TextEffectType type;
  final int startIndex;
  final int endIndex;
  final Map<String, dynamic> params;

  const TextEffect({
    required this.type,
    required this.startIndex,
    required this.endIndex,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'startIndex': startIndex,
        'endIndex': endIndex,
        'params': params,
      };

  factory TextEffect.fromJson(Map<String, dynamic> json) {
    return TextEffect(
      type: TextEffectType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TextEffectType.typewriter,
      ),
      startIndex: json['startIndex'] as int,
      endIndex: json['endIndex'] as int,
      params: (json['params'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// A single line of dialogue
class DialogueLine {
  /// Speaker character ID (null for narration)
  final String? speakerId;

  /// Character expression name
  final String? expression;

  /// Dialogue text content
  final String text;

  /// Localized text by language code
  final Map<String, String> localizedText;

  /// Voice audio file ID (default/fallback voice)
  final String? voiceId;

  /// Localized voice files by language code
  /// Maps language code to voice file ID
  final Map<String, String> localizedVoice;

  /// Text effects applied to this line
  final List<TextEffect> effects;

  /// Character position slot for this dialogue line (overrides scene default)
  final CharacterSlot? characterSlot;

  /// Custom X position (0.0 - 1.0, overrides slot if set)
  final double? characterX;

  /// Custom Y position (0.0 - 1.0, overrides slot if set)
  final double? characterY;

  /// Character scale for this dialogue line
  final double? characterScale;

  /// Whether to flip character horizontally
  final bool? characterFlipped;

  const DialogueLine({
    this.speakerId,
    this.expression,
    required this.text,
    this.localizedText = const {},
    this.voiceId,
    this.localizedVoice = const {},
    this.effects = const [],
    this.characterSlot,
    this.characterX,
    this.characterY,
    this.characterScale,
    this.characterFlipped,
  });

  /// Gets the voice ID for a specific language, with fallback to default
  String? getVoiceForLanguage(String languageCode) {
    // First try the specific language
    if (localizedVoice.containsKey(languageCode)) {
      return localizedVoice[languageCode];
    }
    // Fall back to default voice
    return voiceId;
  }

  Map<String, dynamic> toJson() => {
        if (speakerId != null) 'speakerId': speakerId,
        if (expression != null) 'expression': expression,
        'text': text,
        if (localizedText.isNotEmpty) 'localizedText': localizedText,
        if (voiceId != null) 'voiceId': voiceId,
        if (localizedVoice.isNotEmpty) 'localizedVoice': localizedVoice,
        if (effects.isNotEmpty) 'effects': effects.map((e) => e.toJson()).toList(),
        if (characterSlot != null) 'characterSlot': characterSlot!.name,
        if (characterX != null) 'characterX': characterX,
        if (characterY != null) 'characterY': characterY,
        if (characterScale != null) 'characterScale': characterScale,
        if (characterFlipped != null) 'characterFlipped': characterFlipped,
      };

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speakerId: json['speakerId'] as String?,
      expression: json['expression'] as String?,
      text: json['text'] as String,
      localizedText:
          (json['localizedText'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      voiceId: json['voiceId'] as String?,
      localizedVoice:
          (json['localizedVoice'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => TextEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      characterSlot: json['characterSlot'] != null
          ? CharacterSlot.values.firstWhere(
              (e) => e.name == json['characterSlot'],
              orElse: () => CharacterSlot.center,
            )
          : null,
      characterX: (json['characterX'] as num?)?.toDouble(),
      characterY: (json['characterY'] as num?)?.toDouble(),
      characterScale: (json['characterScale'] as num?)?.toDouble(),
      characterFlipped: json['characterFlipped'] as bool?,
    );
  }

  DialogueLine copyWith({
    String? speakerId,
    String? expression,
    String? text,
    Map<String, String>? localizedText,
    String? voiceId,
    Map<String, String>? localizedVoice,
    List<TextEffect>? effects,
    CharacterSlot? characterSlot,
    double? characterX,
    double? characterY,
    double? characterScale,
    bool? characterFlipped,
    bool clearVoiceId = false,
    bool clearCharacterSlot = false,
    bool clearCharacterX = false,
    bool clearCharacterY = false,
    bool clearCharacterScale = false,
    bool clearCharacterFlipped = false,
  }) {
    return DialogueLine(
      speakerId: speakerId ?? this.speakerId,
      expression: expression ?? this.expression,
      text: text ?? this.text,
      localizedText: localizedText ?? this.localizedText,
      voiceId: clearVoiceId ? null : (voiceId ?? this.voiceId),
      localizedVoice: localizedVoice ?? this.localizedVoice,
      effects: effects ?? this.effects,
      characterSlot: clearCharacterSlot ? null : (characterSlot ?? this.characterSlot),
      characterX: clearCharacterX ? null : (characterX ?? this.characterX),
      characterY: clearCharacterY ? null : (characterY ?? this.characterY),
      characterScale: clearCharacterScale ? null : (characterScale ?? this.characterScale),
      characterFlipped: clearCharacterFlipped ? null : (characterFlipped ?? this.characterFlipped),
    );
  }
}


/// Choice option for ChoiceNode
class ChoiceOption {
  /// Unique option identifier
  final String id;

  /// Option display text
  final String text;

  /// Localized text by language code
  final Map<String, String> localizedText;

  /// Condition expression for visibility (null = always visible)
  final String? condition;

  /// Target node ID when selected
  final String? targetNodeId;

  const ChoiceOption({
    required this.id,
    required this.text,
    this.localizedText = const {},
    this.condition,
    this.targetNodeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (localizedText.isNotEmpty) 'localizedText': localizedText,
        if (condition != null) 'condition': condition,
        if (targetNodeId != null) 'targetNodeId': targetNodeId,
      };

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    return ChoiceOption(
      id: json['id'] as String,
      text: json['text'] as String,
      localizedText:
          (json['localizedText'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      condition: json['condition'] as String?,
      targetNodeId: json['targetNodeId'] as String?,
    );
  }

  ChoiceOption copyWith({
    String? id,
    String? text,
    Map<String, String>? localizedText,
    String? condition,
    String? targetNodeId,
  }) {
    return ChoiceOption(
      id: id ?? this.id,
      text: text ?? this.text,
      localizedText: localizedText ?? this.localizedText,
      condition: condition ?? this.condition,
      targetNodeId: targetNodeId ?? this.targetNodeId,
    );
  }
}

/// Character position in scene
class CharacterPosition {
  final String characterId;
  final String? expression;
  final CharacterSlot slot;
  final double? customX;
  final double? customY;
  final double scale;
  final bool flipped;

  const CharacterPosition({
    required this.characterId,
    this.expression,
    this.slot = CharacterSlot.center,
    this.customX,
    this.customY,
    this.scale = 1.0,
    this.flipped = false,
  });

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        if (expression != null) 'expression': expression,
        'slot': slot.name,
        if (customX != null) 'customX': customX,
        if (customY != null) 'customY': customY,
        'scale': scale,
        'flipped': flipped,
      };

  factory CharacterPosition.fromJson(Map<String, dynamic> json) {
    return CharacterPosition(
      characterId: json['characterId'] as String,
      expression: json['expression'] as String?,
      slot: CharacterSlot.values.firstWhere(
        (e) => e.name == json['slot'],
        orElse: () => CharacterSlot.center,
      ),
      customX: (json['customX'] as num?)?.toDouble(),
      customY: (json['customY'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      flipped: json['flipped'] as bool? ?? false,
    );
  }
}

/// Standard character positions
enum CharacterSlot {
  farLeft,
  left,
  center,
  right,
  farRight,
  custom,
}


/// Base class for all VN nodes
abstract class VNNode {
  /// Unique node identifier
  final String id;

  /// Node type
  final VNNodeType type;

  /// Position on canvas
  final Offset position;

  /// Node size
  final Size size;

  /// Additional properties
  final Map<String, dynamic> properties;

  const VNNode({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.size = const Size(200, 100),
    this.properties = const {},
  });

  Map<String, dynamic> toJson();

  factory VNNode.fromJson(Map<String, dynamic> json) {
    final type = VNNodeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => VNNodeType.scene,
    );

    switch (type) {
      case VNNodeType.start:
        return StartNode.fromJson(json);
      case VNNodeType.scene:
        return SceneNode.fromJson(json);
      case VNNodeType.choice:
        return ChoiceNode.fromJson(json);
      case VNNodeType.jump:
        return JumpNode.fromJson(json);
      case VNNodeType.condition:
        return ConditionNode.fromJson(json);
      case VNNodeType.switch_:
        return SwitchNode.fromJson(json);
      case VNNodeType.variable:
        return VariableNode.fromJson(json);
      case VNNodeType.effect:
        return EffectNode.fromJson(json);
      case VNNodeType.audio:
        return AudioNode.fromJson(json);
      case VNNodeType.ending:
        return EndingNode.fromJson(json);
      case VNNodeType.background:
        return BackgroundNode.fromJson(json);
      case VNNodeType.character:
        return CharacterNode.fromJson(json);
      case VNNodeType.wait:
        return WaitNode.fromJson(json);
      case VNNodeType.label:
        return LabelNode.fromJson(json);
      case VNNodeType.input:
        return InputNode.fromJson(json);
      case VNNodeType.cg:
        return CGNode.fromJson(json);
      case VNNodeType.video:
        return VideoNode.fromJson(json);
      case VNNodeType.achievement:
        return AchievementNode.fromJson(json);
      case VNNodeType.particle:
        return ParticleNode.fromJson(json);
      case VNNodeType.affection:
        return AffectionNode.fromJson(json);
      case VNNodeType.journal:
        return JournalEntryNode.fromJson(json);
      case VNNodeType.minigame:
        return MiniGameNode.fromJson(json);
      case VNNodeType.script:
        return ScriptNode.fromJson(json);
    }
  }

  VNNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
  });

  /// Helper to parse position from JSON
  static Offset parsePosition(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>?;
    if (pos == null) return Offset.zero;
    return Offset(
      (pos['x'] as num?)?.toDouble() ?? 0,
      (pos['y'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Helper to parse size from JSON
  static Size parseSize(Map<String, dynamic> json) {
    final s = json['size'] as Map<String, dynamic>?;
    if (s == null) return const Size(200, 100);
    return Size(
      (s['width'] as num?)?.toDouble() ?? 200,
      (s['height'] as num?)?.toDouble() ?? 100,
    );
  }

  /// Helper to serialize position
  Map<String, dynamic> positionToJson() => {
        'x': position.dx,
        'y': position.dy,
      };

  /// Helper to serialize size
  Map<String, dynamic> sizeToJson() => {
        'width': size.width,
        'height': size.height,
      };
}

/// Start node - entry point for a chapter
class StartNode extends VNNode {
  const StartNode({
    required super.id,
    super.position,
    super.size = const Size(120, 60),
    super.properties,
  }) : super(type: VNNodeType.start);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
      };

  factory StartNode.fromJson(Map<String, dynamic> json) {
    return StartNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  StartNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
  }) {
    return StartNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
    );
  }
}


/// Scene node - contains dialogues and scene setup
class SceneNode extends VNNode {
  /// Background resource ID
  final String? backgroundId;

  /// BGM resource ID
  final String? bgmId;

  /// List of dialogue lines
  final List<DialogueLine> dialogues;

  /// Characters displayed in this scene
  final List<CharacterPosition> characters;

  const SceneNode({
    required super.id,
    super.position,
    super.size = const Size(240, 140),
    super.properties,
    this.backgroundId,
    this.bgmId,
    this.dialogues = const [],
    this.characters = const [],
  }) : super(type: VNNodeType.scene);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (backgroundId != null) 'backgroundId': backgroundId,
        if (bgmId != null) 'bgmId': bgmId,
        'dialogues': dialogues.map((d) => d.toJson()).toList(),
        'characters': characters.map((c) => c.toJson()).toList(),
      };

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    return SceneNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      backgroundId: json['backgroundId'] as String?,
      bgmId: json['bgmId'] as String?,
      dialogues: (json['dialogues'] as List<dynamic>?)
              ?.map((d) => DialogueLine.fromJson(d as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((c) => CharacterPosition.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  SceneNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? backgroundId,
    String? bgmId,
    List<DialogueLine>? dialogues,
    List<CharacterPosition>? characters,
  }) {
    return SceneNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      backgroundId: backgroundId ?? this.backgroundId,
      bgmId: bgmId ?? this.bgmId,
      dialogues: dialogues ?? this.dialogues,
      characters: characters ?? this.characters,
    );
  }
}

/// Choice node - player decision point
class ChoiceNode extends VNNode {
  /// Available choices
  final List<ChoiceOption> options;

  /// Whether this is a timed choice
  final bool isTimed;

  /// Time limit in seconds (if timed)
  final double? timeLimit;

  /// Default choice index if time runs out
  final int? defaultChoiceIndex;

  const ChoiceNode({
    required super.id,
    super.position,
    super.size = const Size(200, 160),
    super.properties,
    this.options = const [],
    this.isTimed = false,
    this.timeLimit,
    this.defaultChoiceIndex,
  }) : super(type: VNNodeType.choice);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'options': options.map((o) => o.toJson()).toList(),
        'isTimed': isTimed,
        if (timeLimit != null) 'timeLimit': timeLimit,
        if (defaultChoiceIndex != null) 'defaultChoiceIndex': defaultChoiceIndex,
      };

  factory ChoiceNode.fromJson(Map<String, dynamic> json) {
    return ChoiceNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ChoiceOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          const [],
      isTimed: json['isTimed'] as bool? ?? false,
      timeLimit: (json['timeLimit'] as num?)?.toDouble(),
      defaultChoiceIndex: json['defaultChoiceIndex'] as int?,
    );
  }

  @override
  ChoiceNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    List<ChoiceOption>? options,
    bool? isTimed,
    double? timeLimit,
    int? defaultChoiceIndex,
  }) {
    return ChoiceNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      options: options ?? this.options,
      isTimed: isTimed ?? this.isTimed,
      timeLimit: timeLimit ?? this.timeLimit,
      defaultChoiceIndex: defaultChoiceIndex ?? this.defaultChoiceIndex,
    );
  }
}


/// Jump node - jump to another node or chapter
class JumpNode extends VNNode {
  /// Target node ID (within same chapter)
  final String? targetNodeId;

  /// Target chapter ID (for cross-chapter jumps)
  final String? targetChapterId;

  const JumpNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    this.targetNodeId,
    this.targetChapterId,
  }) : super(type: VNNodeType.jump);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (targetNodeId != null) 'targetNodeId': targetNodeId,
        if (targetChapterId != null) 'targetChapterId': targetChapterId,
      };

  factory JumpNode.fromJson(Map<String, dynamic> json) {
    return JumpNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      targetNodeId: json['targetNodeId'] as String?,
      targetChapterId: json['targetChapterId'] as String?,
    );
  }

  @override
  JumpNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? targetNodeId,
    String? targetChapterId,
  }) {
    return JumpNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      targetChapterId: targetChapterId ?? this.targetChapterId,
    );
  }
}

/// Condition node - conditional branching
class ConditionNode extends VNNode {
  /// Condition expression to evaluate
  final String expression;

  /// Node ID for true branch
  final String? trueNodeId;

  /// Node ID for false branch
  final String? falseNodeId;

  const ConditionNode({
    required super.id,
    super.position,
    super.size = const Size(180, 100),
    super.properties,
    required this.expression,
    this.trueNodeId,
    this.falseNodeId,
  }) : super(type: VNNodeType.condition);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'expression': expression,
        if (trueNodeId != null) 'trueNodeId': trueNodeId,
        if (falseNodeId != null) 'falseNodeId': falseNodeId,
      };

  factory ConditionNode.fromJson(Map<String, dynamic> json) {
    return ConditionNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      expression: json['expression'] as String? ?? '',
      trueNodeId: json['trueNodeId'] as String?,
      falseNodeId: json['falseNodeId'] as String?,
    );
  }

  @override
  ConditionNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? expression,
    String? trueNodeId,
    String? falseNodeId,
  }) {
    return ConditionNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      expression: expression ?? this.expression,
      trueNodeId: trueNodeId ?? this.trueNodeId,
      falseNodeId: falseNodeId ?? this.falseNodeId,
    );
  }
}


/// A single case in a switch node (if/elif condition)
class SwitchCase {
  /// Unique case identifier
  final String id;
  
  /// Condition expression (empty for 'else' case)
  final String expression;
  
  /// Label for this case (optional, for display)
  final String? label;
  
  /// Target node ID when this case matches
  final String? targetNodeId;

  const SwitchCase({
    required this.id,
    required this.expression,
    this.label,
    this.targetNodeId,
  });

  /// Whether this is the default/else case
  bool get isDefault => expression.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'expression': expression,
        if (label != null) 'label': label,
        if (targetNodeId != null) 'targetNodeId': targetNodeId,
      };

  factory SwitchCase.fromJson(Map<String, dynamic> json) {
    return SwitchCase(
      id: json['id'] as String,
      expression: json['expression'] as String? ?? '',
      label: json['label'] as String?,
      targetNodeId: json['targetNodeId'] as String?,
    );
  }

  SwitchCase copyWith({
    String? id,
    String? expression,
    String? label,
    String? targetNodeId,
  }) {
    return SwitchCase(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      label: label ?? this.label,
      targetNodeId: targetNodeId ?? this.targetNodeId,
    );
  }
}

/// Switch node - multi-condition branching (if/elif/elif/.../else)
class SwitchNode extends VNNode {
  /// List of cases to evaluate in order
  /// The first case with a matching condition is taken
  /// An empty expression means 'else' (default case)
  final List<SwitchCase> cases;

  const SwitchNode({
    required super.id,
    super.position,
    super.size = const Size(200, 160),
    super.properties,
    this.cases = const [],
  }) : super(type: VNNodeType.switch_);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'cases': cases.map((c) => c.toJson()).toList(),
      };

  factory SwitchNode.fromJson(Map<String, dynamic> json) {
    return SwitchNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      cases: (json['cases'] as List<dynamic>?)
              ?.map((c) => SwitchCase.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  SwitchNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    List<SwitchCase>? cases,
  }) {
    return SwitchNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      cases: cases ?? this.cases,
    );
  }
  
  /// Get the default (else) case if it exists
  SwitchCase? get defaultCase => cases.where((c) => c.isDefault).firstOrNull;
  
  /// Get all non-default cases
  List<SwitchCase> get conditionalCases => cases.where((c) => !c.isDefault).toList();
}


/// Variable operation types
enum VariableOperation {
  set,       // Set to value
  add,       // Add to current value
  subtract,  // Subtract from current value
  toggle,    // Toggle boolean
}

/// Variable node - modify story variables
class VariableNode extends VNNode {
  /// Variable name to modify
  final String variableName;

  /// Operation to perform
  final VariableOperation operation;

  /// Value for the operation
  final dynamic value;

  const VariableNode({
    required super.id,
    super.position,
    super.size = const Size(180, 80),
    super.properties,
    required this.variableName,
    this.operation = VariableOperation.set,
    this.value,
  }) : super(type: VNNodeType.variable);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'variableName': variableName,
        'operation': operation.name,
        if (value != null) 'value': value,
      };

  factory VariableNode.fromJson(Map<String, dynamic> json) {
    return VariableNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      variableName: json['variableName'] as String? ?? '',
      operation: VariableOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => VariableOperation.set,
      ),
      value: json['value'],
    );
  }

  @override
  VariableNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? variableName,
    VariableOperation? operation,
    dynamic value,
  }) {
    return VariableNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      variableName: variableName ?? this.variableName,
      operation: operation ?? this.operation,
      value: value ?? this.value,
    );
  }
}

/// Screen effect types
enum ScreenEffectType {
  fade,
  shake,
  flash,
  blur,
  vignette,
  colorOverlay,
}

/// Effect node - visual/screen effects
class EffectNode extends VNNode {
  /// Effect type
  final ScreenEffectType effectType;

  /// Effect duration in seconds
  final double duration;

  /// Effect intensity (0.0 - 1.0)
  final double intensity;

  /// Additional effect parameters
  final Map<String, dynamic> effectParams;

  const EffectNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    this.effectType = ScreenEffectType.fade,
    this.duration = 1.0,
    this.intensity = 1.0,
    this.effectParams = const {},
  }) : super(type: VNNodeType.effect);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'effectType': effectType.name,
        'duration': duration,
        'intensity': intensity,
        if (effectParams.isNotEmpty) 'effectParams': effectParams,
      };

  factory EffectNode.fromJson(Map<String, dynamic> json) {
    return EffectNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      effectType: ScreenEffectType.values.firstWhere(
        (e) => e.name == json['effectType'],
        orElse: () => ScreenEffectType.fade,
      ),
      duration: (json['duration'] as num?)?.toDouble() ?? 1.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      effectParams: (json['effectParams'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  EffectNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    ScreenEffectType? effectType,
    double? duration,
    double? intensity,
    Map<String, dynamic>? effectParams,
  }) {
    return EffectNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      effectType: effectType ?? this.effectType,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      effectParams: effectParams ?? this.effectParams,
    );
  }
}


/// Audio action types
enum AudioAction {
  play,
  stop,
  pause,
  resume,
  fadeIn,
  fadeOut,
  crossfade,
}

/// Audio channel types
enum AudioChannel {
  bgm,
  sfx,
  voice,
  ambient,
}

/// Audio node - audio control
class AudioNode extends VNNode {
  /// Audio resource ID
  final String? audioId;

  /// Audio channel
  final AudioChannel channel;

  /// Action to perform
  final AudioAction action;

  /// Volume (0.0 - 1.0)
  final double volume;

  /// Fade duration in seconds
  final double? fadeDuration;

  /// Whether to loop
  final bool loop;

  const AudioNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    this.audioId,
    this.channel = AudioChannel.bgm,
    this.action = AudioAction.play,
    this.volume = 1.0,
    this.fadeDuration,
    this.loop = false,
  }) : super(type: VNNodeType.audio);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (audioId != null) 'audioId': audioId,
        'channel': channel.name,
        'action': action.name,
        'volume': volume,
        if (fadeDuration != null) 'fadeDuration': fadeDuration,
        'loop': loop,
      };

  factory AudioNode.fromJson(Map<String, dynamic> json) {
    return AudioNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      audioId: json['audioId'] as String?,
      channel: AudioChannel.values.firstWhere(
        (e) => e.name == json['channel'],
        orElse: () => AudioChannel.bgm,
      ),
      action: AudioAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => AudioAction.play,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      fadeDuration: (json['fadeDuration'] as num?)?.toDouble(),
      loop: json['loop'] as bool? ?? false,
    );
  }

  @override
  AudioNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? audioId,
    AudioChannel? channel,
    AudioAction? action,
    double? volume,
    double? fadeDuration,
    bool? loop,
  }) {
    return AudioNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      audioId: audioId ?? this.audioId,
      channel: channel ?? this.channel,
      action: action ?? this.action,
      volume: volume ?? this.volume,
      fadeDuration: fadeDuration ?? this.fadeDuration,
      loop: loop ?? this.loop,
    );
  }
}

/// Predefined ending types (suggestions, not exhaustive)
class EndingTypes {
  static const String normal = 'normal';
  static const String good = 'good';
  static const String bad = 'bad';
  static const String true_ = 'true';
  static const String secret = 'secret';
  
  /// Get all predefined types
  static List<String> get predefined => [normal, good, bad, true_, secret];
  
  /// Get display name for a type
  static String getDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'normal': return 'Normal';
      case 'good': return 'Good';
      case 'bad': return 'Bad';
      case 'true': return 'True';
      case 'secret': return 'Secret';
      default: return type;
    }
  }
  
  /// Get color for a type
  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal': return const Color(0xFF9E9E9E); // grey
      case 'good': return const Color(0xFF4CAF50); // green
      case 'bad': return const Color(0xFFF44336); // red
      case 'true': return const Color(0xFFFFC107); // amber
      case 'secret': return const Color(0xFF9C27B0); // purple
      default: return const Color(0xFF2196F3); // blue for custom types
    }
  }
}

/// Ending node - story ending
class EndingNode extends VNNode {
  /// Ending identifier
  final String endingId;

  /// Ending display name
  final String endingName;

  /// Ending type (can be predefined or custom)
  final String endingType;

  /// Whether this ending unlocks gallery content
  final bool unlocksGallery;

  /// CG IDs to unlock
  final List<String> unlockedCGs;

  const EndingNode({
    required super.id,
    super.position,
    super.size = const Size(160, 100),
    super.properties,
    required this.endingId,
    required this.endingName,
    this.endingType = EndingTypes.normal,
    this.unlocksGallery = false,
    this.unlockedCGs = const [],
  }) : super(type: VNNodeType.ending);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'endingId': endingId,
        'endingName': endingName,
        'endingType': endingType,
        'unlocksGallery': unlocksGallery,
        if (unlockedCGs.isNotEmpty) 'unlockedCGs': unlockedCGs,
      };

  factory EndingNode.fromJson(Map<String, dynamic> json) {
    return EndingNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      endingId: json['endingId'] as String? ?? '',
      endingName: json['endingName'] as String? ?? 'Ending',
      endingType: json['endingType'] as String? ?? EndingTypes.normal,
      unlocksGallery: json['unlocksGallery'] as bool? ?? false,
      unlockedCGs:
          (json['unlockedCGs'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  @override
  EndingNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? endingId,
    String? endingName,
    String? endingType,
    bool? unlocksGallery,
    List<String>? unlockedCGs,
  }) {
    return EndingNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      endingId: endingId ?? this.endingId,
      endingName: endingName ?? this.endingName,
      endingType: endingType ?? this.endingType,
      unlocksGallery: unlocksGallery ?? this.unlocksGallery,
      unlockedCGs: unlockedCGs ?? this.unlockedCGs,
    );
  }
}


// ==================== New Node Types ====================

/// Background transition types
enum BackgroundTransition {
  none,
  fade,
  dissolve,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
}

/// Background node - change background image
class BackgroundNode extends VNNode {
  /// Background resource ID
  final String? backgroundId;

  /// Transition type
  final BackgroundTransition transition;

  /// Transition duration in seconds
  final double transitionDuration;

  const BackgroundNode({
    required super.id,
    super.position,
    super.size = const Size(180, 120),
    super.properties,
    this.backgroundId,
    this.transition = BackgroundTransition.fade,
    this.transitionDuration = 0.5,
  }) : super(type: VNNodeType.background);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (backgroundId != null) 'backgroundId': backgroundId,
        'transition': transition.name,
        'transitionDuration': transitionDuration,
      };

  factory BackgroundNode.fromJson(Map<String, dynamic> json) {
    return BackgroundNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      backgroundId: json['backgroundId'] as String?,
      transition: BackgroundTransition.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => BackgroundTransition.fade,
      ),
      transitionDuration: (json['transitionDuration'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  BackgroundNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? backgroundId,
    BackgroundTransition? transition,
    double? transitionDuration,
  }) {
    return BackgroundNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      backgroundId: backgroundId ?? this.backgroundId,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }
}

/// Character action types
enum CharacterAction {
  show,
  hide,
  move,
  changeExpression,
}

/// Character node - show/hide/move character
class CharacterNode extends VNNode {
  /// Character ID
  final String? characterId;

  /// Action to perform
  final CharacterAction action;

  /// Character expression
  final String? expression;

  /// Target position slot
  final CharacterSlot slot;

  /// Custom X position (0.0 - 1.0)
  final double? customX;

  /// Custom Y position (0.0 - 1.0)
  final double? customY;

  /// Scale factor
  final double scale;

  /// Whether to flip horizontally
  final bool flipped;

  /// Transition duration
  final double transitionDuration;

  const CharacterNode({
    required super.id,
    super.position,
    super.size = const Size(180, 100),
    super.properties,
    this.characterId,
    this.action = CharacterAction.show,
    this.expression,
    this.slot = CharacterSlot.center,
    this.customX,
    this.customY,
    this.scale = 1.0,
    this.flipped = false,
    this.transitionDuration = 0.3,
  }) : super(type: VNNodeType.character);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (characterId != null) 'characterId': characterId,
        'action': action.name,
        if (expression != null) 'expression': expression,
        'slot': slot.name,
        if (customX != null) 'customX': customX,
        if (customY != null) 'customY': customY,
        'scale': scale,
        'flipped': flipped,
        'transitionDuration': transitionDuration,
      };

  factory CharacterNode.fromJson(Map<String, dynamic> json) {
    return CharacterNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      characterId: json['characterId'] as String?,
      action: CharacterAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => CharacterAction.show,
      ),
      expression: json['expression'] as String?,
      slot: CharacterSlot.values.firstWhere(
        (e) => e.name == json['slot'],
        orElse: () => CharacterSlot.center,
      ),
      customX: (json['customX'] as num?)?.toDouble(),
      customY: (json['customY'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      flipped: json['flipped'] as bool? ?? false,
      transitionDuration: (json['transitionDuration'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  CharacterNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? characterId,
    CharacterAction? action,
    String? expression,
    CharacterSlot? slot,
    double? customX,
    double? customY,
    double? scale,
    bool? flipped,
    double? transitionDuration,
  }) {
    return CharacterNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      characterId: characterId ?? this.characterId,
      action: action ?? this.action,
      expression: expression ?? this.expression,
      slot: slot ?? this.slot,
      customX: customX ?? this.customX,
      customY: customY ?? this.customY,
      scale: scale ?? this.scale,
      flipped: flipped ?? this.flipped,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }
}

/// Wait node - pause execution for a duration
class WaitNode extends VNNode {
  /// Wait duration in seconds
  final double duration;

  /// Whether player can skip
  final bool skippable;

  const WaitNode({
    required super.id,
    super.position,
    super.size = const Size(140, 70),
    super.properties,
    this.duration = 1.0,
    this.skippable = true,
  }) : super(type: VNNodeType.wait);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'duration': duration,
        'skippable': skippable,
      };

  factory WaitNode.fromJson(Map<String, dynamic> json) {
    return WaitNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      duration: (json['duration'] as num?)?.toDouble() ?? 1.0,
      skippable: json['skippable'] as bool? ?? true,
    );
  }

  @override
  WaitNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    double? duration,
    bool? skippable,
  }) {
    return WaitNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      duration: duration ?? this.duration,
      skippable: skippable ?? this.skippable,
    );
  }
}

/// Label node - named point for jumping
class LabelNode extends VNNode {
  /// Label name
  final String labelName;

  const LabelNode({
    required super.id,
    super.position,
    super.size = const Size(140, 60),
    super.properties,
    required this.labelName,
  }) : super(type: VNNodeType.label);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'labelName': labelName,
      };

  factory LabelNode.fromJson(Map<String, dynamic> json) {
    return LabelNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      labelName: json['labelName'] as String? ?? '',
    );
  }

  @override
  LabelNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? labelName,
  }) {
    return LabelNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      labelName: labelName ?? this.labelName,
    );
  }
}

/// Input node - player text input
class InputNode extends VNNode {
  /// Prompt text to display
  final String prompt;

  /// Variable name to store input
  final String variableName;

  /// Default value
  final String defaultValue;

  /// Maximum input length
  final int maxLength;

  /// Placeholder text
  final String placeholder;

  const InputNode({
    required super.id,
    super.position,
    super.size = const Size(180, 100),
    super.properties,
    this.prompt = '',
    required this.variableName,
    this.defaultValue = '',
    this.maxLength = 20,
    this.placeholder = '',
  }) : super(type: VNNodeType.input);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'prompt': prompt,
        'variableName': variableName,
        'defaultValue': defaultValue,
        'maxLength': maxLength,
        'placeholder': placeholder,
      };

  factory InputNode.fromJson(Map<String, dynamic> json) {
    return InputNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      prompt: json['prompt'] as String? ?? '',
      variableName: json['variableName'] as String? ?? '',
      defaultValue: json['defaultValue'] as String? ?? '',
      maxLength: json['maxLength'] as int? ?? 20,
      placeholder: json['placeholder'] as String? ?? '',
    );
  }

  @override
  InputNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? prompt,
    String? variableName,
    String? defaultValue,
    int? maxLength,
    String? placeholder,
  }) {
    return InputNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      prompt: prompt ?? this.prompt,
      variableName: variableName ?? this.variableName,
      defaultValue: defaultValue ?? this.defaultValue,
      maxLength: maxLength ?? this.maxLength,
      placeholder: placeholder ?? this.placeholder,
    );
  }
}

/// CG node - display CG image
class CGNode extends VNNode {
  /// CG resource ID
  final String? cgId;

  /// Transition type
  final BackgroundTransition transition;

  /// Transition duration
  final double transitionDuration;

  /// Whether to unlock in gallery
  final bool unlockInGallery;

  const CGNode({
    required super.id,
    super.position,
    super.size = const Size(180, 120),
    super.properties,
    this.cgId,
    this.transition = BackgroundTransition.fade,
    this.transitionDuration = 0.5,
    this.unlockInGallery = true,
  }) : super(type: VNNodeType.cg);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (cgId != null) 'cgId': cgId,
        'transition': transition.name,
        'transitionDuration': transitionDuration,
        'unlockInGallery': unlockInGallery,
      };

  factory CGNode.fromJson(Map<String, dynamic> json) {
    return CGNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      cgId: json['cgId'] as String?,
      transition: BackgroundTransition.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => BackgroundTransition.fade,
      ),
      transitionDuration: (json['transitionDuration'] as num?)?.toDouble() ?? 0.5,
      unlockInGallery: json['unlockInGallery'] as bool? ?? true,
    );
  }

  @override
  CGNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? cgId,
    BackgroundTransition? transition,
    double? transitionDuration,
    bool? unlockInGallery,
  }) {
    return CGNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      cgId: cgId ?? this.cgId,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      unlockInGallery: unlockInGallery ?? this.unlockInGallery,
    );
  }
}

/// Video node - play video
class VideoNode extends VNNode {
  /// Video resource ID
  final String? videoId;

  /// Whether player can skip
  final bool skippable;

  /// Whether to loop
  final bool loop;

  /// Volume (0.0 - 1.0)
  final double volume;

  const VideoNode({
    required super.id,
    super.position,
    super.size = const Size(180, 100),
    super.properties,
    this.videoId,
    this.skippable = true,
    this.loop = false,
    this.volume = 1.0,
  }) : super(type: VNNodeType.video);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        if (videoId != null) 'videoId': videoId,
        'skippable': skippable,
        'loop': loop,
        'volume': volume,
      };

  factory VideoNode.fromJson(Map<String, dynamic> json) {
    return VideoNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      videoId: json['videoId'] as String?,
      skippable: json['skippable'] as bool? ?? true,
      loop: json['loop'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  VideoNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? videoId,
    bool? skippable,
    bool? loop,
    double? volume,
  }) {
    return VideoNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      videoId: videoId ?? this.videoId,
      skippable: skippable ?? this.skippable,
      loop: loop ?? this.loop,
      volume: volume ?? this.volume,
    );
  }
}


/// Achievement node - unlock an achievement at a story point
/// Requirements: 2.1, 2.8
class AchievementNode extends VNNode {
  /// Achievement ID to unlock
  final String achievementId;

  /// Whether to show unlock notification
  final bool showNotification;

  const AchievementNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    required this.achievementId,
    this.showNotification = true,
  }) : super(type: VNNodeType.achievement);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'achievementId': achievementId,
        'showNotification': showNotification,
      };

  factory AchievementNode.fromJson(Map<String, dynamic> json) {
    return AchievementNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      achievementId: json['achievementId'] as String? ?? '',
      showNotification: json['showNotification'] as bool? ?? true,
    );
  }

  @override
  AchievementNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? achievementId,
    bool? showNotification,
  }) {
    return AchievementNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      achievementId: achievementId ?? this.achievementId,
      showNotification: showNotification ?? this.showNotification,
    );
  }
}


/// Particle action types
enum ParticleAction {
  start,    // Start particle effect
  stop,     // Stop particle effect (gradual fade)
  stopNow,  // Stop particle effect immediately
  setIntensity, // Change effect intensity
}

/// Particle node - control particle effects (rain, snow, sakura, etc.)
/// Requirements: 14.1, 14.2, 14.3, 14.5, 14.6
class ParticleNode extends VNNode {
  /// Particle effect preset name (rain, snow, sakura, sparkles, dust, fireflies, etc.)
  final String presetName;

  /// Action to perform
  final ParticleAction action;

  /// Effect intensity multiplier (0.0 - 2.0+)
  final double intensity;

  /// Custom effect ID (for managing multiple effects)
  final String? effectId;

  /// Whether to stop immediately (for stop action)
  final bool immediate;

  /// Custom configuration overrides (optional)
  final Map<String, dynamic> customConfig;

  const ParticleNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    required this.presetName,
    this.action = ParticleAction.start,
    this.intensity = 1.0,
    this.effectId,
    this.immediate = false,
    this.customConfig = const {},
  }) : super(type: VNNodeType.particle);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'presetName': presetName,
        'action': action.name,
        'intensity': intensity,
        if (effectId != null) 'effectId': effectId,
        'immediate': immediate,
        if (customConfig.isNotEmpty) 'customConfig': customConfig,
      };

  factory ParticleNode.fromJson(Map<String, dynamic> json) {
    return ParticleNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      presetName: json['presetName'] as String? ?? 'rain',
      action: ParticleAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ParticleAction.start,
      ),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      effectId: json['effectId'] as String?,
      immediate: json['immediate'] as bool? ?? false,
      customConfig: (json['customConfig'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  ParticleNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? presetName,
    ParticleAction? action,
    double? intensity,
    String? effectId,
    bool? immediate,
    Map<String, dynamic>? customConfig,
  }) {
    return ParticleNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      presetName: presetName ?? this.presetName,
      action: action ?? this.action,
      intensity: intensity ?? this.intensity,
      effectId: effectId ?? this.effectId,
      immediate: immediate ?? this.immediate,
      customConfig: customConfig ?? this.customConfig,
    );
  }
}


/// Affection operation types
enum AffectionOperation {
  set,       // Set to specific value
  add,       // Add to current value
  subtract,  // Subtract from current value
}

/// Affection node - modify character affection value
/// Requirements: 18.1, 18.6
class AffectionNode extends VNNode {
  /// Character ID whose affection to modify
  final String characterId;

  /// Operation to perform
  final AffectionOperation operation;

  /// Value for the operation
  final int value;

  /// Whether to show change notification
  final bool showNotification;

  const AffectionNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    required this.characterId,
    this.operation = AffectionOperation.add,
    this.value = 1,
    this.showNotification = true,
  }) : super(type: VNNodeType.affection);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'characterId': characterId,
        'operation': operation.name,
        'value': value,
        'showNotification': showNotification,
      };

  factory AffectionNode.fromJson(Map<String, dynamic> json) {
    return AffectionNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      characterId: json['characterId'] as String? ?? '',
      operation: AffectionOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => AffectionOperation.add,
      ),
      value: json['value'] as int? ?? 1,
      showNotification: json['showNotification'] as bool? ?? true,
    );
  }

  @override
  AffectionNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? characterId,
    AffectionOperation? operation,
    int? value,
    bool? showNotification,
  }) {
    return AffectionNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      characterId: characterId ?? this.characterId,
      operation: operation ?? this.operation,
      value: value ?? this.value,
      showNotification: showNotification ?? this.showNotification,
    );
  }
}


/// Journal entry node - unlock a journal entry at a story point
/// Requirements: 19.5
class JournalEntryNode extends VNNode {
  /// Journal entry ID to unlock
  final String entryId;

  /// Whether to show unlock notification
  final bool showNotification;

  const JournalEntryNode({
    required super.id,
    super.position,
    super.size = const Size(160, 80),
    super.properties,
    required this.entryId,
    this.showNotification = true,
  }) : super(type: VNNodeType.journal);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'entryId': entryId,
        'showNotification': showNotification,
      };

  factory JournalEntryNode.fromJson(Map<String, dynamic> json) {
    return JournalEntryNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      entryId: json['entryId'] as String? ?? '',
      showNotification: json['showNotification'] as bool? ?? true,
    );
  }

  @override
  JournalEntryNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? entryId,
    bool? showNotification,
  }) {
    return JournalEntryNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      entryId: entryId ?? this.entryId,
      showNotification: showNotification ?? this.showNotification,
    );
  }
}


/// Mini-game node - trigger a mini-game at a story point
/// Requirements: 17.1, 17.4
class MiniGameNode extends VNNode {
  /// Mini-game type identifier
  final String gameTypeId;

  /// Display name for the mini-game
  final String displayName;

  /// Description shown to the player
  final String? description;

  /// Input variables passed to the mini-game
  /// Keys are mini-game variable names, values are either:
  /// - Literal values
  /// - Variable references starting with '$' (e.g., '$playerScore')
  final Map<String, dynamic> inputVariables;

  /// Output variable mappings
  /// Keys are mini-game output names, values are story variable names
  final Map<String, String> outputMappings;

  /// Whether the player can skip this mini-game
  final bool skippable;

  /// Default values for output variables if skipped
  final Map<String, dynamic> skipDefaults;

  /// Custom configuration for the mini-game
  final Map<String, dynamic> customConfig;

  /// Time limit in seconds (null = no limit)
  final double? timeLimit;

  const MiniGameNode({
    required super.id,
    super.position,
    super.size = const Size(200, 120),
    super.properties,
    required this.gameTypeId,
    required this.displayName,
    this.description,
    this.inputVariables = const {},
    this.outputMappings = const {},
    this.skippable = true,
    this.skipDefaults = const {},
    this.customConfig = const {},
    this.timeLimit,
  }) : super(type: VNNodeType.minigame);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'gameTypeId': gameTypeId,
        'displayName': displayName,
        if (description != null) 'description': description,
        if (inputVariables.isNotEmpty) 'inputVariables': inputVariables,
        if (outputMappings.isNotEmpty) 'outputMappings': outputMappings,
        'skippable': skippable,
        if (skipDefaults.isNotEmpty) 'skipDefaults': skipDefaults,
        if (customConfig.isNotEmpty) 'customConfig': customConfig,
        if (timeLimit != null) 'timeLimit': timeLimit,
      };

  factory MiniGameNode.fromJson(Map<String, dynamic> json) {
    return MiniGameNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      gameTypeId: json['gameTypeId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Mini-Game',
      description: json['description'] as String?,
      inputVariables: (json['inputVariables'] as Map<String, dynamic>?) ?? const {},
      outputMappings: (json['outputMappings'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
      skippable: json['skippable'] as bool? ?? true,
      skipDefaults: (json['skipDefaults'] as Map<String, dynamic>?) ?? const {},
      customConfig: (json['customConfig'] as Map<String, dynamic>?) ?? const {},
      timeLimit: (json['timeLimit'] as num?)?.toDouble(),
    );
  }

  @override
  MiniGameNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? gameTypeId,
    String? displayName,
    String? description,
    Map<String, dynamic>? inputVariables,
    Map<String, String>? outputMappings,
    bool? skippable,
    Map<String, dynamic>? skipDefaults,
    Map<String, dynamic>? customConfig,
    double? timeLimit,
  }) {
    return MiniGameNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      gameTypeId: gameTypeId ?? this.gameTypeId,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      inputVariables: inputVariables ?? this.inputVariables,
      outputMappings: outputMappings ?? this.outputMappings,
      skippable: skippable ?? this.skippable,
      skipDefaults: skipDefaults ?? this.skipDefaults,
      customConfig: customConfig ?? this.customConfig,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }
}


/// Script node - execute custom Dart script at a story point
/// Requirements: 25.1, 25.2
class ScriptNode extends VNNode {
  /// The script code to execute
  final String scriptCode;

  /// Display name for the script (for editor)
  final String? displayName;

  /// Description of what the script does
  final String? description;

  /// Whether to run the script asynchronously
  final bool async;

  /// Timeout in milliseconds (0 = no timeout)
  final int timeoutMs;

  /// Whether to continue on error
  final bool continueOnError;

  /// Template ID if this script was generated from a template
  final String? templateId;

  const ScriptNode({
    required super.id,
    super.position,
    super.size = const Size(200, 100),
    super.properties,
    required this.scriptCode,
    this.displayName,
    this.description,
    this.async = true,
    this.timeoutMs = 5000,
    this.continueOnError = false,
    this.templateId,
  }) : super(type: VNNodeType.script);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': positionToJson(),
        'size': sizeToJson(),
        if (properties.isNotEmpty) 'properties': properties,
        'scriptCode': scriptCode,
        if (displayName != null) 'displayName': displayName,
        if (description != null) 'description': description,
        'async': async,
        'timeoutMs': timeoutMs,
        'continueOnError': continueOnError,
        if (templateId != null) 'templateId': templateId,
      };

  factory ScriptNode.fromJson(Map<String, dynamic> json) {
    return ScriptNode(
      id: json['id'] as String,
      position: VNNode.parsePosition(json),
      size: VNNode.parseSize(json),
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      scriptCode: json['scriptCode'] as String? ?? '',
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      async: json['async'] as bool? ?? true,
      timeoutMs: json['timeoutMs'] as int? ?? 5000,
      continueOnError: json['continueOnError'] as bool? ?? false,
      templateId: json['templateId'] as String?,
    );
  }

  @override
  ScriptNode copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? properties,
    String? scriptCode,
    String? displayName,
    String? description,
    bool? async,
    int? timeoutMs,
    bool? continueOnError,
    String? templateId,
  }) {
    return ScriptNode(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      scriptCode: scriptCode ?? this.scriptCode,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      async: async ?? this.async,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      continueOnError: continueOnError ?? this.continueOnError,
      templateId: templateId ?? this.templateId,
    );
  }
}
