/// Script Sandbox for VN Runtime
///
/// Provides a sandboxed execution environment for custom Dart scripts.
/// Scripts have limited access to engine state and variables for security.

import 'dart:async';

/// Result of script execution
class ScriptExecutionResult {
  /// Whether execution was successful
  final bool success;

  /// Return value from the script (if any)
  final dynamic returnValue;

  /// Error message if execution failed
  final String? errorMessage;

  /// Execution duration
  final Duration executionTime;

  /// Variables modified by the script
  final Map<String, dynamic> modifiedVariables;

  const ScriptExecutionResult({
    required this.success,
    this.returnValue,
    this.errorMessage,
    required this.executionTime,
    this.modifiedVariables = const {},
  });

  factory ScriptExecutionResult.success({
    dynamic returnValue,
    required Duration executionTime,
    Map<String, dynamic> modifiedVariables = const {},
  }) {
    return ScriptExecutionResult(
      success: true,
      returnValue: returnValue,
      executionTime: executionTime,
      modifiedVariables: modifiedVariables,
    );
  }

  factory ScriptExecutionResult.error(
    String message, {
    required Duration executionTime,
  }) {
    return ScriptExecutionResult(
      success: false,
      errorMessage: message,
      executionTime: executionTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (returnValue != null) 'returnValue': returnValue,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'executionTimeMs': executionTime.inMilliseconds,
        if (modifiedVariables.isNotEmpty) 'modifiedVariables': modifiedVariables,
      };
}

/// Security level for script execution
enum ScriptSecurityLevel {
  /// Read-only access to variables
  readOnly,

  /// Can read and modify variables
  readWrite,

  /// Full access including engine state modification
  full,
}

/// Configuration for script execution
class ScriptExecutionConfig {
  /// Maximum execution time before timeout
  final Duration timeout;

  /// Security level for the script
  final ScriptSecurityLevel securityLevel;

  /// Whether to allow async operations
  final bool allowAsync;

  /// Maximum recursion depth
  final int maxRecursionDepth;

  /// Maximum loop iterations
  final int maxLoopIterations;

  const ScriptExecutionConfig({
    this.timeout = const Duration(seconds: 5),
    this.securityLevel = ScriptSecurityLevel.readWrite,
    this.allowAsync = true,
    this.maxRecursionDepth = 100,
    this.maxLoopIterations = 10000,
  });

  static const defaultConfig = ScriptExecutionConfig();

  static const readOnlyConfig = ScriptExecutionConfig(
    securityLevel: ScriptSecurityLevel.readOnly,
    allowAsync: false,
  );
}
