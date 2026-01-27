/// VNBS Scripting System
///
/// Provides custom script execution capabilities for visual novels.
/// Scripts run in a sandboxed environment with controlled access to
/// engine state and variables.
///
/// Example usage:
/// ```dart
/// final executor = ScriptExecutor();
/// final context = ScriptContext(
///   variables: {'playerName': 'Alice', 'score': 100},
///   securityLevel: ScriptSecurityLevel.readWrite,
/// );
///
/// final result = await executor.execute('''
///   score = $score + 10;
///   log("New score: " + $score);
///   return $score;
/// ''', context);
///
/// if (result.success) {
///   print('Script returned: ${result.returnValue}');
///   print('Modified variables: ${result.modifiedVariables}');
/// }
/// ```

export 'script_sandbox.dart';
export 'script_context.dart';
export 'script_executor.dart';
export 'script_parser.dart';
export 'script_api.dart';
export 'script_validator.dart';
export 'script_templates.dart';
