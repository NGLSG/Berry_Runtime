/// Script Executor for VN Runtime
///
/// Executes custom scripts in a sandboxed environment with access to
/// engine state and variables.

import 'dart:async';

import 'script_sandbox.dart';
import 'script_context.dart';
import 'script_api.dart';
import 'script_parser.dart';

/// Executes scripts in a sandboxed environment
class ScriptExecutor {
  /// Configuration for script execution
  final ScriptExecutionConfig config;

  /// Script API instance
  final ScriptAPI? api;

  ScriptExecutor({
    this.config = ScriptExecutionConfig.defaultConfig,
    this.api,
  });

  /// Execute a script with the given context
  Future<ScriptExecutionResult> execute(
    String script,
    ScriptContext context,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Parse the script
      final parser = ScriptParser();
      final parseResult = parser.parse(script);

      if (!parseResult.success) {
        stopwatch.stop();
        return ScriptExecutionResult.error(
          'Parse error: ${parseResult.errorMessage}',
          executionTime: stopwatch.elapsed,
        );
      }

      // Execute with timeout
      final result = await _executeWithTimeout(
        parseResult.statements,
        context,
        stopwatch,
      );

      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      return ScriptExecutionResult.error(
        'Execution error: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  Future<ScriptExecutionResult> _executeWithTimeout(
    List<ScriptStatement> statements,
    ScriptContext context,
    Stopwatch stopwatch,
  ) async {
    try {
      final result = await Future.any([
        _executeStatements(statements, context),
        Future.delayed(config.timeout).then((_) => throw TimeoutException(
              'Script execution timed out after ${config.timeout.inSeconds}s',
            )),
      ]);

      return ScriptExecutionResult.success(
        returnValue: result,
        executionTime: stopwatch.elapsed,
        modifiedVariables: context.getModifiedVariables(),
      );
    } on TimeoutException catch (e) {
      return ScriptExecutionResult.error(
        e.message ?? 'Script execution timed out',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  Future<dynamic> _executeStatements(
    List<ScriptStatement> statements,
    ScriptContext context,
  ) async {
    dynamic lastResult;

    for (final statement in statements) {
      lastResult = await _executeStatement(statement, context);
    }

    return lastResult;
  }

  Future<dynamic> _executeStatement(
    ScriptStatement statement,
    ScriptContext context,
  ) async {
    switch (statement.type) {
      case StatementType.variableAssignment:
        return _executeAssignment(statement, context);
      case StatementType.functionCall:
        return _executeFunctionCall(statement, context);
      case StatementType.conditional:
        return _executeConditional(statement, context);
      case StatementType.loop:
        return _executeLoop(statement, context);
      case StatementType.returnStatement:
        return _evaluateExpression(statement.data['value'], context);
      case StatementType.expression:
        return _evaluateExpression(statement.data['expression'], context);
    }
  }

  Future<dynamic> _executeAssignment(
    ScriptStatement statement,
    ScriptContext context,
  ) async {
    final varName = statement.data['variable'] as String;
    final value = await _evaluateExpression(statement.data['value'], context);

    if (!context.setVariable(varName, value)) {
      throw SecurityException('Cannot modify variable in read-only mode');
    }

    return value;
  }

  Future<dynamic> _executeFunctionCall(
    ScriptStatement statement,
    ScriptContext context,
  ) async {
    final funcName = statement.data['function'] as String;
    final args = statement.data['arguments'] as List<dynamic>? ?? [];

    // Evaluate arguments
    final evaluatedArgs = <dynamic>[];
    for (final arg in args) {
      evaluatedArgs.add(await _evaluateExpression(arg, context));
    }

    // Execute built-in functions
    return _executeBuiltInFunction(funcName, evaluatedArgs, context);
  }

  Future<dynamic> _executeBuiltInFunction(
    String funcName,
    List<dynamic> args,
    ScriptContext context,
  ) async {
    switch (funcName) {
      // Variable functions
      case 'get':
        if (args.isEmpty) throw ArgumentError('get() requires a variable name');
        return context.getVariable(args[0] as String);

      case 'set':
        if (args.length < 2) {
          throw ArgumentError('set() requires variable name and value');
        }
        context.setVariable(args[0] as String, args[1]);
        return args[1];

      case 'has':
        if (args.isEmpty) throw ArgumentError('has() requires a variable name');
        return context.hasVariable(args[0] as String);

      // Math functions
      case 'abs':
        return (args[0] as num).abs();
      case 'min':
        return args.reduce((a, b) => (a as num) < (b as num) ? a : b);
      case 'max':
        return args.reduce((a, b) => (a as num) > (b as num) ? a : b);
      case 'floor':
        return (args[0] as num).floor();
      case 'ceil':
        return (args[0] as num).ceil();
      case 'round':
        return (args[0] as num).round();
      case 'random':
        return _random(args);

      // String functions
      case 'concat':
        return args.map((a) => a.toString()).join();
      case 'length':
        return (args[0] as String).length;
      case 'substring':
        final str = args[0] as String;
        final start = args[1] as int;
        final end = args.length > 2 ? args[2] as int : str.length;
        return str.substring(start, end);
      case 'toUpper':
        return (args[0] as String).toUpperCase();
      case 'toLower':
        return (args[0] as String).toLowerCase();
      case 'contains':
        return (args[0] as String).contains(args[1] as String);

      // Utility functions
      case 'log':
        context.log(args.map((a) => a.toString()).join(' '));
        return null;

      case 'wait':
        if (config.allowAsync) {
          final ms = args.isNotEmpty ? (args[0] as num).toInt() : 1000;
          await context.wait(Duration(milliseconds: ms));
        }
        return null;

      // Type conversion
      case 'toInt':
        return (args[0] as num).toInt();
      case 'toDouble':
        return (args[0] as num).toDouble();
      case 'toString':
        return args[0].toString();
      case 'toBool':
        return _toBool(args[0]);

      // API functions (if available)
      default:
        if (api != null) {
          return api!.callFunction(funcName, args, context);
        }
        throw UnimplementedError('Unknown function: $funcName');
    }
  }

  dynamic _random(List<dynamic> args) {
    final random = DateTime.now().millisecondsSinceEpoch;
    if (args.isEmpty) {
      return (random % 1000) / 1000.0; // 0.0 to 1.0
    } else if (args.length == 1) {
      return random % (args[0] as int); // 0 to max-1
    } else {
      final min = args[0] as int;
      final max = args[1] as int;
      return min + (random % (max - min)); // min to max-1
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty && value.toLowerCase() != 'false';
    return value != null;
  }

  Future<dynamic> _executeConditional(
    ScriptStatement statement,
    ScriptContext context,
  ) async {
    final condition = await _evaluateExpression(
      statement.data['condition'],
      context,
    );

    if (_toBool(condition)) {
      final thenStatements = statement.data['then'] as List<ScriptStatement>;
      return _executeStatements(thenStatements, context);
    } else if (statement.data['else'] != null) {
      final elseStatements = statement.data['else'] as List<ScriptStatement>;
      return _executeStatements(elseStatements, context);
    }

    return null;
  }

  Future<dynamic> _executeLoop(
    ScriptStatement statement,
    ScriptContext context,
  ) async {
    final loopType = statement.data['loopType'] as String;
    var iterations = 0;

    switch (loopType) {
      case 'while':
        while (iterations < config.maxLoopIterations) {
          final condition = await _evaluateExpression(
            statement.data['condition'],
            context,
          );
          if (!_toBool(condition)) break;

          final body = statement.data['body'] as List<ScriptStatement>;
          await _executeStatements(body, context);
          iterations++;
        }
        break;

      case 'for':
        final count = await _evaluateExpression(
          statement.data['count'],
          context,
        ) as int;
        final varName = statement.data['variable'] as String?;

        for (var i = 0; i < count && i < config.maxLoopIterations; i++) {
          if (varName != null) {
            context.setVariable(varName, i);
          }
          final body = statement.data['body'] as List<ScriptStatement>;
          await _executeStatements(body, context);
          iterations++;
        }
        break;
    }

    if (iterations >= config.maxLoopIterations) {
      throw LoopLimitException(
        'Loop exceeded maximum iterations (${config.maxLoopIterations})',
      );
    }

    return null;
  }

  Future<dynamic> _evaluateExpression(
    dynamic expression,
    ScriptContext context,
  ) async {
    if (expression == null) return null;

    // Literal values
    if (expression is num || expression is bool) return expression;
    if (expression is String) {
      // Check if it's a variable reference
      if (expression.startsWith('\$')) {
        return context.getVariable(expression.substring(1));
      }
      return expression;
    }

    // Expression object
    if (expression is Map<String, dynamic>) {
      final type = expression['type'] as String?;

      switch (type) {
        case 'variable':
          return context.getVariable(expression['name'] as String);

        case 'literal':
          return expression['value'];

        case 'binary':
          final left = await _evaluateExpression(expression['left'], context);
          final right = await _evaluateExpression(expression['right'], context);
          return _evaluateBinaryOp(
            expression['operator'] as String,
            left,
            right,
          );

        case 'unary':
          final operand = await _evaluateExpression(
            expression['operand'],
            context,
          );
          return _evaluateUnaryOp(expression['operator'] as String, operand);

        case 'call':
          final funcName = expression['function'] as String;
          final args = expression['arguments'] as List<dynamic>? ?? [];
          final evaluatedArgs = <dynamic>[];
          for (final arg in args) {
            evaluatedArgs.add(await _evaluateExpression(arg, context));
          }
          return _executeBuiltInFunction(funcName, evaluatedArgs, context);
      }
    }

    return expression;
  }

  dynamic _evaluateBinaryOp(String op, dynamic left, dynamic right) {
    switch (op) {
      // Arithmetic
      case '+':
        if (left is String || right is String) {
          return '$left$right';
        }
        return (left as num) + (right as num);
      case '-':
        return (left as num) - (right as num);
      case '*':
        return (left as num) * (right as num);
      case '/':
        return (left as num) / (right as num);
      case '%':
        return (left as num) % (right as num);

      // Comparison
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '<':
        return (left as num) < (right as num);
      case '>':
        return (left as num) > (right as num);
      case '<=':
        return (left as num) <= (right as num);
      case '>=':
        return (left as num) >= (right as num);

      // Logical
      case '&&':
        return _toBool(left) && _toBool(right);
      case '||':
        return _toBool(left) || _toBool(right);

      default:
        throw UnimplementedError('Unknown operator: $op');
    }
  }

  dynamic _evaluateUnaryOp(String op, dynamic operand) {
    switch (op) {
      case '!':
        return !_toBool(operand);
      case '-':
        return -(operand as num);
      default:
        throw UnimplementedError('Unknown unary operator: $op');
    }
  }
}

/// Exception thrown when security constraints are violated
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

/// Exception thrown when loop limit is exceeded
class LoopLimitException implements Exception {
  final String message;
  LoopLimitException(this.message);

  @override
  String toString() => 'LoopLimitException: $message';
}
