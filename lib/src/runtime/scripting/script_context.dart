/// Script Context for VN Runtime
///
/// Provides the execution context for scripts, including access to
/// variables, engine state, and allowed operations.

import 'dart:async';

import 'script_sandbox.dart';

/// Context provided to scripts during execution
class ScriptContext {
  /// Current variable values (read-only snapshot)
  final Map<String, dynamic> _variables;

  /// Variables modified during script execution
  final Map<String, dynamic> _modifiedVariables = {};

  /// Security level for this context
  final ScriptSecurityLevel securityLevel;

  /// Engine state accessor
  final ScriptEngineStateAccessor? engineState;

  /// Async operation handler
  final ScriptAsyncHandler? asyncHandler;

  ScriptContext({
    required Map<String, dynamic> variables,
    required this.securityLevel,
    this.engineState,
    this.asyncHandler,
  }) : _variables = Map.from(variables);

  /// Get a variable value
  dynamic getVariable(String name) {
    if (_modifiedVariables.containsKey(name)) {
      return _modifiedVariables[name];
    }
    return _variables[name];
  }

  /// Set a variable value (if allowed by security level)
  bool setVariable(String name, dynamic value) {
    if (securityLevel == ScriptSecurityLevel.readOnly) {
      return false;
    }
    _modifiedVariables[name] = value;
    return true;
  }

  /// Check if a variable exists
  bool hasVariable(String name) {
    return _modifiedVariables.containsKey(name) || _variables.containsKey(name);
  }

  /// Get all current variable values
  Map<String, dynamic> getAllVariables() {
    return {..._variables, ..._modifiedVariables};
  }

  /// Get variables that were modified during execution
  Map<String, dynamic> getModifiedVariables() {
    return Map.from(_modifiedVariables);
  }

  /// Log a message (for debugging)
  void log(String message) {
    // In production, this could be routed to a debug console
    print('[Script] $message');
  }

  /// Wait for a duration (async operation)
  Future<void> wait(Duration duration) async {
    if (asyncHandler != null) {
      await asyncHandler!.wait(duration);
    } else {
      await Future.delayed(duration);
    }
  }
}

/// Accessor for engine state (limited access for security)
abstract class ScriptEngineStateAccessor {
  /// Get current chapter ID
  String? get currentChapterId;

  /// Get current node ID
  String? get currentNodeId;

  /// Get current dialogue index
  int get currentDialogueIndex;

  /// Check if a dialogue has been read
  bool isDialogueRead(String chapterId, String nodeId, int dialogueIndex);

  /// Get current background ID
  String? get currentBackgroundId;

  /// Get current BGM ID
  String? get currentBgmId;

  /// Get displayed character IDs
  List<String> get displayedCharacterIds;
}

/// Handler for async operations in scripts
abstract class ScriptAsyncHandler {
  /// Wait for a duration
  Future<void> wait(Duration duration);

  /// Execute a callback after a delay
  Future<T> delayed<T>(Duration duration, T Function() callback);
}

/// Default implementation of async handler
class DefaultScriptAsyncHandler implements ScriptAsyncHandler {
  @override
  Future<void> wait(Duration duration) => Future.delayed(duration);

  @override
  Future<T> delayed<T>(Duration duration, T Function() callback) async {
    await Future.delayed(duration);
    return callback();
  }
}
