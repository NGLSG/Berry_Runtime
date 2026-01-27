/// Mini-Game Manager for VN Runtime
/// 
/// Manages registration and execution of mini-games within the VN runtime.
/// 
/// Requirements: 17.1, 17.2, 17.5

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'mini_game_interface.dart';

/// Event emitted when a mini-game completes
class MiniGameCompleteEvent {
  final String gameTypeId;
  final MiniGameResult result;
  final DateTime timestamp;

  MiniGameCompleteEvent({
    required this.gameTypeId,
    required this.result,
  }) : timestamp = DateTime.now();
}

/// Manager for mini-game registration and execution
class MiniGameManager {
  /// Registered mini-game implementations
  final Map<String, MiniGameInterface> _registeredGames = {};
  
  /// Event stream for mini-game completions
  final _completeController = StreamController<MiniGameCompleteEvent>.broadcast();
  
  /// Stream of mini-game completion events
  Stream<MiniGameCompleteEvent> get onComplete => _completeController.stream;
  
  /// Currently active mini-game config (if any)
  MiniGameConfig? _activeConfig;
  
  /// Completer for the current mini-game
  Completer<MiniGameResult>? _activeCompleter;

  /// Register a mini-game implementation
  void registerGame(MiniGameInterface game) {
    _registeredGames[game.gameTypeId] = game;
  }

  /// Unregister a mini-game implementation
  void unregisterGame(String gameTypeId) {
    _registeredGames.remove(gameTypeId);
  }

  /// Check if a mini-game type is registered
  bool isRegistered(String gameTypeId) {
    return _registeredGames.containsKey(gameTypeId);
  }

  /// Get a registered mini-game by type ID
  MiniGameInterface? getGame(String gameTypeId) {
    return _registeredGames[gameTypeId];
  }

  /// Get all registered mini-game types
  List<String> get registeredTypes => _registeredGames.keys.toList();

  /// Get all registered mini-games
  List<MiniGameInterface> get registeredGames => _registeredGames.values.toList();

  /// Validate a mini-game configuration
  String? validateConfig(MiniGameConfig config) {
    final game = _registeredGames[config.gameTypeId];
    if (game == null) {
      return 'Mini-game type not registered: ${config.gameTypeId}';
    }
    return game.validateConfig(config);
  }

  /// Check if a mini-game is currently active
  bool get isActive => _activeConfig != null;

  /// Get the currently active mini-game config
  MiniGameConfig? get activeConfig => _activeConfig;


  /// Start a mini-game and return a Future that completes when the game finishes
  /// 
  /// [config] - Configuration for the mini-game instance
  /// [storyVariables] - Current story variables (for input variable resolution)
  /// 
  /// Returns a Future that completes with the mini-game result
  Future<MiniGameResult> startGame(
    MiniGameConfig config,
    Map<String, dynamic> storyVariables,
  ) async {
    if (_activeConfig != null) {
      return MiniGameResult.failure('A mini-game is already active');
    }

    final game = _registeredGames[config.gameTypeId];
    if (game == null) {
      return MiniGameResult.failure('Mini-game type not registered: ${config.gameTypeId}');
    }

    // Resolve input variables from story variables
    final resolvedConfig = _resolveInputVariables(config, storyVariables);

    // Validate configuration
    final validationError = game.validateConfig(resolvedConfig);
    if (validationError != null) {
      return MiniGameResult.failure(validationError);
    }

    _activeConfig = resolvedConfig;
    _activeCompleter = Completer<MiniGameResult>();

    return _activeCompleter!.future;
  }

  /// Build the widget for the currently active mini-game
  /// 
  /// Returns null if no mini-game is active
  Widget? buildActiveGame(BuildContext context) {
    if (_activeConfig == null) return null;

    final game = _registeredGames[_activeConfig!.gameTypeId];
    if (game == null) return null;

    return game.build(context, _activeConfig!, _onGameComplete);
  }

  /// Complete the currently active mini-game
  void _onGameComplete(MiniGameResult result) {
    if (_activeConfig == null || _activeCompleter == null) return;

    final config = _activeConfig!;
    _activeConfig = null;

    // Emit completion event
    _completeController.add(MiniGameCompleteEvent(
      gameTypeId: config.gameTypeId,
      result: result,
    ));

    // Complete the future
    _activeCompleter!.complete(result);
    _activeCompleter = null;
  }

  /// Skip the currently active mini-game
  void skipActiveGame() {
    if (_activeConfig == null) return;

    final skipResult = MiniGameResult(
      completed: false,
      skipped: true,
      outputVariables: _activeConfig!.skipDefaults,
    );

    _onGameComplete(skipResult);
  }

  /// Cancel the currently active mini-game (without completing)
  void cancelActiveGame() {
    if (_activeConfig == null || _activeCompleter == null) return;

    _activeConfig = null;
    _activeCompleter!.complete(MiniGameResult.failure('Mini-game cancelled'));
    _activeCompleter = null;
  }

  /// Resolve input variables from story variables
  MiniGameConfig _resolveInputVariables(
    MiniGameConfig config,
    Map<String, dynamic> storyVariables,
  ) {
    if (config.inputVariables.isEmpty) return config;

    final resolvedInputs = <String, dynamic>{};
    
    for (final entry in config.inputVariables.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String && value.startsWith('\$')) {
        // Variable reference: $variableName
        final varName = value.substring(1);
        resolvedInputs[key] = storyVariables[varName] ?? value;
      } else {
        // Literal value
        resolvedInputs[key] = value;
      }
    }

    return config.copyWith(inputVariables: resolvedInputs);
  }

  /// Map mini-game output variables to story variables
  /// 
  /// [result] - The mini-game result
  /// [config] - The mini-game configuration (for output mappings)
  /// 
  /// Returns a map of story variable names to values
  Map<String, dynamic> mapOutputVariables(
    MiniGameResult result,
    MiniGameConfig config,
  ) {
    final storyVariables = <String, dynamic>{};

    // If skipped, use skip defaults
    if (result.skipped) {
      for (final entry in config.skipDefaults.entries) {
        final storyVarName = config.outputMappings[entry.key] ?? entry.key;
        storyVariables[storyVarName] = entry.value;
      }
      return storyVariables;
    }

    // Map output variables using the output mappings
    for (final entry in result.outputVariables.entries) {
      final outputName = entry.key;
      final value = entry.value;
      
      // Use mapping if defined, otherwise use the output name directly
      final storyVarName = config.outputMappings[outputName] ?? outputName;
      storyVariables[storyVarName] = value;
    }

    return storyVariables;
  }

  /// Dispose of the manager
  void dispose() {
    _completeController.close();
    _registeredGames.clear();
    _activeConfig = null;
    _activeCompleter = null;
  }
}
