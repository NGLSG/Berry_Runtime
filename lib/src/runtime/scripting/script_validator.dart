/// Script Validator for VN Runtime
///
/// Validates scripts before execution to catch errors early and
/// provide helpful error messages to developers.

import 'script_parser.dart';

/// Result of script validation
class ScriptValidationResult {
  /// Whether the script is valid
  final bool isValid;

  /// List of errors found
  final List<ScriptValidationError> errors;

  /// List of warnings found
  final List<ScriptValidationWarning> warnings;

  const ScriptValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ScriptValidationResult.valid({
    List<ScriptValidationWarning> warnings = const [],
  }) {
    return ScriptValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  factory ScriptValidationResult.invalid(List<ScriptValidationError> errors, {
    List<ScriptValidationWarning> warnings = const [],
  }) {
    return ScriptValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// A validation error
class ScriptValidationError {
  final String message;
  final int? line;
  final int? column;
  final ScriptErrorType type;

  const ScriptValidationError({
    required this.message,
    this.line,
    this.column,
    this.type = ScriptErrorType.syntax,
  });

  @override
  String toString() {
    if (line != null && column != null) {
      return '[$type] Line $line, Column $column: $message';
    }
    return '[$type] $message';
  }
}

/// A validation warning
class ScriptValidationWarning {
  final String message;
  final int? line;
  final int? column;
  final ScriptWarningType type;

  const ScriptValidationWarning({
    required this.message,
    this.line,
    this.column,
    this.type = ScriptWarningType.style,
  });

  @override
  String toString() {
    if (line != null && column != null) {
      return '[$type] Line $line, Column $column: $message';
    }
    return '[$type] $message';
  }
}

/// Types of validation errors
enum ScriptErrorType {
  syntax,
  semantic,
  reference,
  type,
}

/// Types of validation warnings
enum ScriptWarningType {
  style,
  performance,
  deprecated,
  unused,
}

/// Validates scripts for correctness
class ScriptValidator {
  /// Known variable names (for reference checking)
  final Set<String> knownVariables;

  /// Known function names (for reference checking)
  final Set<String> knownFunctions;

  ScriptValidator({
    this.knownVariables = const {},
    this.knownFunctions = const {},
  });

  /// Default known functions
  static const defaultFunctions = {
    // Variable functions
    'get', 'set', 'has',
    // Math functions
    'abs', 'min', 'max', 'floor', 'ceil', 'round', 'random',
    'clamp', 'lerp', 'pow', 'sqrt',
    // String functions
    'concat', 'length', 'substring', 'toUpper', 'toLower', 'contains',
    'format', 'split', 'join', 'trim', 'replace',
    // List functions
    'list', 'listGet', 'listSet', 'listAdd', 'listRemove',
    'listLength', 'listContains',
    // Utility functions
    'log', 'wait', 'delay', 'timeout',
    // Type conversion
    'toInt', 'toDouble', 'toString', 'toBool',
    // Engine state functions
    'getCurrentChapter', 'getCurrentNode', 'getDialogueIndex',
    'isDialogueRead', 'getBackground', 'getBGM',
    'getDisplayedCharacters', 'isCharacterDisplayed',
    // Variable shortcuts
    'getVar', 'setVar', 'hasVar', 'incrementVar', 'decrementVar', 'toggleVar',
  };

  /// Validate a script
  ScriptValidationResult validate(String script) {
    final errors = <ScriptValidationError>[];
    final warnings = <ScriptValidationWarning>[];

    // First, try to parse the script
    final parser = ScriptParser();
    final parseResult = parser.parse(script);

    if (!parseResult.success) {
      errors.add(ScriptValidationError(
        message: parseResult.errorMessage ?? 'Unknown parse error',
        line: parseResult.errorLine,
        column: parseResult.errorColumn,
        type: ScriptErrorType.syntax,
      ));
      return ScriptValidationResult.invalid(errors);
    }

    // Validate each statement
    final declaredVariables = <String>{};

    for (final statement in parseResult.statements) {
      _validateStatement(
        statement,
        errors,
        warnings,
        declaredVariables,
      );
    }

    if (errors.isEmpty) {
      return ScriptValidationResult.valid(warnings: warnings);
    }

    return ScriptValidationResult.invalid(errors, warnings: warnings);
  }

  void _validateStatement(
    ScriptStatement statement,
    List<ScriptValidationError> errors,
    List<ScriptValidationWarning> warnings,
    Set<String> declaredVariables,
  ) {
    switch (statement.type) {
      case StatementType.variableAssignment:
        final varName = statement.data['variable'] as String;
        declaredVariables.add(varName);
        _validateExpression(
          statement.data['value'],
          errors,
          warnings,
          declaredVariables,
        );
        break;

      case StatementType.functionCall:
        final funcName = statement.data['function'] as String;
        _validateFunctionCall(funcName, statement.data['arguments'] as List?,
            errors, warnings, declaredVariables);
        break;

      case StatementType.conditional:
        _validateExpression(
          statement.data['condition'],
          errors,
          warnings,
          declaredVariables,
        );
        final thenStatements = statement.data['then'] as List<ScriptStatement>?;
        if (thenStatements != null) {
          for (final s in thenStatements) {
            _validateStatement(s, errors, warnings, declaredVariables);
          }
        }
        final elseStatements = statement.data['else'] as List<ScriptStatement>?;
        if (elseStatements != null) {
          for (final s in elseStatements) {
            _validateStatement(s, errors, warnings, declaredVariables);
          }
        }
        break;

      case StatementType.loop:
        if (statement.data['condition'] != null) {
          _validateExpression(
            statement.data['condition'],
            errors,
            warnings,
            declaredVariables,
          );
        }
        if (statement.data['count'] != null) {
          _validateExpression(
            statement.data['count'],
            errors,
            warnings,
            declaredVariables,
          );
        }
        final loopVar = statement.data['variable'] as String?;
        if (loopVar != null) {
          declaredVariables.add(loopVar);
        }
        final body = statement.data['body'] as List<ScriptStatement>?;
        if (body != null) {
          for (final s in body) {
            _validateStatement(s, errors, warnings, declaredVariables);
          }
        }
        break;

      case StatementType.returnStatement:
        _validateExpression(
          statement.data['value'],
          errors,
          warnings,
          declaredVariables,
        );
        break;

      case StatementType.expression:
        _validateExpression(
          statement.data['expression'],
          errors,
          warnings,
          declaredVariables,
        );
        break;
    }
  }

  void _validateExpression(
    dynamic expression,
    List<ScriptValidationError> errors,
    List<ScriptValidationWarning> warnings,
    Set<String> declaredVariables,
  ) {
    if (expression == null) return;
    if (expression is! Map<String, dynamic>) return;

    final type = expression['type'] as String?;

    switch (type) {
      case 'variable':
        final varName = expression['name'] as String;
        if (!declaredVariables.contains(varName) &&
            !knownVariables.contains(varName)) {
          warnings.add(ScriptValidationWarning(
            message: 'Variable "$varName" may not be defined',
            type: ScriptWarningType.unused,
          ));
        }
        break;

      case 'call':
        final funcName = expression['function'] as String;
        _validateFunctionCall(
          funcName,
          expression['arguments'] as List?,
          errors,
          warnings,
          declaredVariables,
        );
        break;

      case 'binary':
        _validateExpression(
          expression['left'],
          errors,
          warnings,
          declaredVariables,
        );
        _validateExpression(
          expression['right'],
          errors,
          warnings,
          declaredVariables,
        );
        break;

      case 'unary':
        _validateExpression(
          expression['operand'],
          errors,
          warnings,
          declaredVariables,
        );
        break;
    }
  }

  void _validateFunctionCall(
    String funcName,
    List<dynamic>? args,
    List<ScriptValidationError> errors,
    List<ScriptValidationWarning> warnings,
    Set<String> declaredVariables,
  ) {
    // Check if function is known
    if (!defaultFunctions.contains(funcName) &&
        !knownFunctions.contains(funcName)) {
      warnings.add(ScriptValidationWarning(
        message: 'Unknown function "$funcName"',
        type: ScriptWarningType.unused,
      ));
    }

    // Validate arguments
    if (args != null) {
      for (final arg in args) {
        _validateExpression(arg, errors, warnings, declaredVariables);
      }
    }
  }
}
