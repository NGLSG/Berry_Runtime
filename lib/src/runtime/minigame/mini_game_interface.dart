/// Mini-Game Interface for VN Runtime
/// 
/// Provides an abstract interface for embedding custom mini-games
/// within visual novel stories.
/// 
/// Requirements: 17.1

import 'package:flutter/widgets.dart';

/// Result of a mini-game execution
class MiniGameResult {
  /// Whether the mini-game was completed successfully
  final bool completed;
  
  /// Whether the mini-game was skipped by the player
  final bool skipped;
  
  /// Output variables from the mini-game
  /// These will be merged into the story variables
  final Map<String, dynamic> outputVariables;
  
  /// Optional result data (game-specific)
  final Map<String, dynamic>? resultData;
  
  /// Error message if the mini-game failed
  final String? errorMessage;

  const MiniGameResult({
    this.completed = true,
    this.skipped = false,
    this.outputVariables = const {},
    this.resultData,
    this.errorMessage,
  });

  /// Create a successful completion result
  factory MiniGameResult.success({
    Map<String, dynamic> outputVariables = const {},
    Map<String, dynamic>? resultData,
  }) {
    return MiniGameResult(
      completed: true,
      skipped: false,
      outputVariables: outputVariables,
      resultData: resultData,
    );
  }

  /// Create a skipped result
  factory MiniGameResult.skip() {
    return const MiniGameResult(
      completed: false,
      skipped: true,
    );
  }

  /// Create a failure result
  factory MiniGameResult.failure(String errorMessage) {
    return MiniGameResult(
      completed: false,
      skipped: false,
      errorMessage: errorMessage,
    );
  }

  /// Whether the result indicates success (completed or skipped)
  bool get isSuccess => completed || skipped;
}

/// Configuration for a mini-game instance
class MiniGameConfig {
  /// Unique identifier for this mini-game type
  final String gameTypeId;
  
  /// Display name for the mini-game
  final String displayName;
  
  /// Description of the mini-game
  final String? description;
  
  /// Input variables passed from the story
  final Map<String, dynamic> inputVariables;
  
  /// Variable mappings: mini-game output name -> story variable name
  final Map<String, String> outputMappings;
  
  /// Whether the player can skip this mini-game
  final bool skippable;
  
  /// Default result if skipped (for story variable outputs)
  final Map<String, dynamic> skipDefaults;
  
  /// Custom configuration for the specific mini-game type
  final Map<String, dynamic> customConfig;
  
  /// Time limit in seconds (null = no limit)
  final double? timeLimit;

  const MiniGameConfig({
    required this.gameTypeId,
    required this.displayName,
    this.description,
    this.inputVariables = const {},
    this.outputMappings = const {},
    this.skippable = true,
    this.skipDefaults = const {},
    this.customConfig = const {},
    this.timeLimit,
  });

  Map<String, dynamic> toJson() => {
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

  factory MiniGameConfig.fromJson(Map<String, dynamic> json) {
    return MiniGameConfig(
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

  MiniGameConfig copyWith({
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
    return MiniGameConfig(
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


/// Abstract interface for mini-games
/// 
/// Implement this interface to create custom mini-games that can be
/// embedded in visual novel stories.
abstract class MiniGameInterface {
  /// Unique identifier for this mini-game type
  String get gameTypeId;
  
  /// Display name for this mini-game type
  String get displayName;
  
  /// Description of this mini-game type
  String get description;
  
  /// Build the mini-game widget
  /// 
  /// [config] contains the configuration for this instance
  /// [onComplete] should be called when the mini-game finishes
  Widget build(
    BuildContext context,
    MiniGameConfig config,
    void Function(MiniGameResult result) onComplete,
  );
  
  /// Validate the configuration for this mini-game
  /// 
  /// Returns null if valid, or an error message if invalid
  String? validateConfig(MiniGameConfig config) => null;
  
  /// Get the default configuration for this mini-game type
  MiniGameConfig getDefaultConfig() {
    return MiniGameConfig(
      gameTypeId: gameTypeId,
      displayName: displayName,
    );
  }
}

/// Common mini-game types (suggestions, not exhaustive)
class MiniGameTypes {
  static const String puzzle = 'puzzle';
  static const String qte = 'qte';           // Quick Time Event
  static const String memory = 'memory';      // Memory matching game
  static const String quiz = 'quiz';          // Quiz/trivia
  static const String slider = 'slider';      // Slider puzzle
  static const String rpgBattle = 'rpg_battle';
  static const String custom = 'custom';
  
  /// Get all predefined types
  static List<String> get predefined => [
    puzzle, qte, memory, quiz, slider, rpgBattle, custom
  ];
  
  /// Get display name for a type
  static String getDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'puzzle': return 'Puzzle';
      case 'qte': return 'Quick Time Event';
      case 'memory': return 'Memory Game';
      case 'quiz': return 'Quiz';
      case 'slider': return 'Slider Puzzle';
      case 'rpg_battle': return 'RPG Battle';
      case 'custom': return 'Custom';
      default: return type;
    }
  }
}

/// Callback type for mini-game completion
typedef MiniGameCompleteCallback = void Function(MiniGameResult result);

/// Callback type for mini-game skip request
typedef MiniGameSkipCallback = void Function();
