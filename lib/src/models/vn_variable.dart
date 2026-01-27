/// Variable types supported in VN
enum VariableType {
  boolean,
  number,
  string,
}

/// Variable scope
enum VariableScope {
  global,   // Persists across chapters
  chapter,  // Resets on chapter change
  local,    // Temporary, within current node
}

/// A story variable definition
class VNVariable {
  /// Variable name (identifier)
  final String name;

  /// Variable type
  final VariableType type;

  /// Default value
  final dynamic defaultValue;

  /// Variable scope
  final VariableScope scope;

  /// Optional description for editor
  final String? description;

  /// Chapter ID (only for chapter-scoped variables)
  final String? chapterId;

  /// Whether this variable should be carried over in New Game+
  /// Only applicable for global-scoped variables
  final bool ngPlusCarryover;

  const VNVariable({
    required this.name,
    required this.type,
    this.defaultValue,
    this.scope = VariableScope.global,
    this.description,
    this.chapterId,
    this.ngPlusCarryover = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        if (defaultValue != null) 'defaultValue': defaultValue,
        'scope': scope.name,
        if (description != null) 'description': description,
        if (chapterId != null) 'chapterId': chapterId,
        if (ngPlusCarryover) 'ngPlusCarryover': ngPlusCarryover,
      };

  factory VNVariable.fromJson(Map<String, dynamic> json) {
    return VNVariable(
      name: json['name'] as String,
      type: VariableType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VariableType.string,
      ),
      defaultValue: json['defaultValue'],
      scope: VariableScope.values.firstWhere(
        (e) => e.name == json['scope'],
        orElse: () => VariableScope.global,
      ),
      description: json['description'] as String?,
      chapterId: json['chapterId'] as String?,
      ngPlusCarryover: json['ngPlusCarryover'] as bool? ?? false,
    );
  }

  VNVariable copyWith({
    String? name,
    VariableType? type,
    dynamic defaultValue,
    VariableScope? scope,
    String? description,
    String? chapterId,
    bool? ngPlusCarryover,
  }) {
    return VNVariable(
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      scope: scope ?? this.scope,
      description: description ?? this.description,
      chapterId: chapterId ?? this.chapterId,
      ngPlusCarryover: ngPlusCarryover ?? this.ngPlusCarryover,
    );
  }

  /// Get the typed default value
  T? getDefaultValue<T>() {
    if (defaultValue == null) return null;
    if (defaultValue is T) return defaultValue as T;
    return null;
  }

  /// Validate the variable definition
  List<String> validate() {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Variable name is empty');
    }
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      errors.add('Variable name "$name" is not a valid identifier');
    }
    if (scope == VariableScope.chapter && chapterId == null) {
      errors.add('Chapter-scoped variable "$name" has no chapter ID');
    }

    // Type-check default value
    if (defaultValue != null) {
      switch (type) {
        case VariableType.boolean:
          if (defaultValue is! bool) {
            errors.add('Variable "$name" has non-boolean default value');
          }
          break;
        case VariableType.number:
          if (defaultValue is! num) {
            errors.add('Variable "$name" has non-numeric default value');
          }
          break;
        case VariableType.string:
          if (defaultValue is! String) {
            errors.add('Variable "$name" has non-string default value');
          }
          break;
      }
    }

    return errors;
  }
}


/// Comparison operators for conditions
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  contains,
  startsWith,
  endsWith,
}

/// Logical operators for combining conditions
enum LogicalOperator {
  and,
  or,
  not,
}

/// A condition expression token
abstract class ConditionToken {
  Map<String, dynamic> toJson();
  
  factory ConditionToken.fromJson(Map<String, dynamic> json) {
    final tokenType = json['tokenType'] as String;
    switch (tokenType) {
      case 'variable':
        return VariableToken.fromJson(json);
      case 'literal':
        return LiteralToken.fromJson(json);
      case 'comparison':
        return ComparisonToken.fromJson(json);
      case 'logical':
        return LogicalToken.fromJson(json);
      default:
        throw ArgumentError('Unknown token type: $tokenType');
    }
  }
}

/// Variable reference token
class VariableToken implements ConditionToken {
  final String variableName;

  const VariableToken(this.variableName);

  @override
  Map<String, dynamic> toJson() => {
        'tokenType': 'variable',
        'variableName': variableName,
      };

  factory VariableToken.fromJson(Map<String, dynamic> json) {
    return VariableToken(json['variableName'] as String);
  }
}

/// Literal value token
class LiteralToken implements ConditionToken {
  final dynamic value;
  final VariableType type;

  const LiteralToken(this.value, this.type);

  @override
  Map<String, dynamic> toJson() => {
        'tokenType': 'literal',
        'value': value,
        'type': type.name,
      };

  factory LiteralToken.fromJson(Map<String, dynamic> json) {
    return LiteralToken(
      json['value'],
      VariableType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VariableType.string,
      ),
    );
  }
}

/// Comparison expression token
class ComparisonToken implements ConditionToken {
  final ConditionToken left;
  final ComparisonOperator operator;
  final ConditionToken right;

  const ComparisonToken({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  Map<String, dynamic> toJson() => {
        'tokenType': 'comparison',
        'left': left.toJson(),
        'operator': operator.name,
        'right': right.toJson(),
      };

  factory ComparisonToken.fromJson(Map<String, dynamic> json) {
    return ComparisonToken(
      left: ConditionToken.fromJson(json['left'] as Map<String, dynamic>),
      operator: ComparisonOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => ComparisonOperator.equals,
      ),
      right: ConditionToken.fromJson(json['right'] as Map<String, dynamic>),
    );
  }
}

/// Logical expression token
class LogicalToken implements ConditionToken {
  final LogicalOperator operator;
  final List<ConditionToken> operands;

  const LogicalToken({
    required this.operator,
    required this.operands,
  });

  @override
  Map<String, dynamic> toJson() => {
        'tokenType': 'logical',
        'operator': operator.name,
        'operands': operands.map((o) => o.toJson()).toList(),
      };

  factory LogicalToken.fromJson(Map<String, dynamic> json) {
    return LogicalToken(
      operator: LogicalOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => LogicalOperator.and,
      ),
      operands: (json['operands'] as List<dynamic>)
          .map((o) => ConditionToken.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}


/// Condition expression parser and evaluator
class ConditionParser {
  /// Parse a condition expression string into tokens
  /// 
  /// Supported syntax:
  /// - Variable references: `variableName`
  /// - Literals: `true`, `false`, `123`, `"string"`
  /// - Comparisons: `var == value`, `var != value`, `var > value`, etc.
  /// - Logical: `cond1 && cond2`, `cond1 || cond2`, `!cond`
  /// - Grouping: `(cond1 && cond2) || cond3`
  static ConditionToken? parse(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    try {
      return _parseExpression(trimmed);
    } catch (e) {
      return null;
    }
  }

  static ConditionToken _parseExpression(String expr) {
    expr = expr.trim();

    // Handle parentheses
    if (expr.startsWith('(') && _findMatchingParen(expr, 0) == expr.length - 1) {
      return _parseExpression(expr.substring(1, expr.length - 1));
    }

    // Handle logical OR (lowest precedence)
    final orIndex = _findOperator(expr, '||');
    if (orIndex != -1) {
      return LogicalToken(
        operator: LogicalOperator.or,
        operands: [
          _parseExpression(expr.substring(0, orIndex)),
          _parseExpression(expr.substring(orIndex + 2)),
        ],
      );
    }

    // Handle logical AND
    final andIndex = _findOperator(expr, '&&');
    if (andIndex != -1) {
      return LogicalToken(
        operator: LogicalOperator.and,
        operands: [
          _parseExpression(expr.substring(0, andIndex)),
          _parseExpression(expr.substring(andIndex + 2)),
        ],
      );
    }

    // Handle logical NOT
    if (expr.startsWith('!')) {
      return LogicalToken(
        operator: LogicalOperator.not,
        operands: [_parseExpression(expr.substring(1))],
      );
    }

    // Handle comparisons
    for (final op in _comparisonOps.entries) {
      final opIndex = _findOperator(expr, op.key);
      if (opIndex != -1) {
        return ComparisonToken(
          left: _parseValue(expr.substring(0, opIndex).trim()),
          operator: op.value,
          right: _parseValue(expr.substring(opIndex + op.key.length).trim()),
        );
      }
    }

    // Must be a simple value
    return _parseValue(expr);
  }

  static ConditionToken _parseValue(String value) {
    value = value.trim();

    // Boolean literals
    if (value == 'true') {
      return const LiteralToken(true, VariableType.boolean);
    }
    if (value == 'false') {
      return const LiteralToken(false, VariableType.boolean);
    }

    // Number literals
    final num? number = num.tryParse(value);
    if (number != null) {
      return LiteralToken(number, VariableType.number);
    }

    // String literals
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return LiteralToken(
        value.substring(1, value.length - 1),
        VariableType.string,
      );
    }

    // Variable reference
    return VariableToken(value);
  }

  static int _findMatchingParen(String expr, int start) {
    int depth = 0;
    for (int i = start; i < expr.length; i++) {
      if (expr[i] == '(') depth++;
      if (expr[i] == ')') depth--;
      if (depth == 0) return i;
    }
    return -1;
  }

  static int _findOperator(String expr, String op) {
    int depth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < expr.length - op.length + 1; i++) {
      final char = expr[i];

      // Handle string literals
      if ((char == '"' || char == "'") && (i == 0 || expr[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
        continue;
      }

      if (inString) continue;

      // Handle parentheses
      if (char == '(') depth++;
      if (char == ')') depth--;

      // Check for operator at current position
      if (depth == 0 && expr.substring(i).startsWith(op)) {
        return i;
      }
    }
    return -1;
  }

  static const _comparisonOps = {
    '==': ComparisonOperator.equals,
    '!=': ComparisonOperator.notEquals,
    '>=': ComparisonOperator.greaterOrEqual,
    '<=': ComparisonOperator.lessOrEqual,
    '>': ComparisonOperator.greaterThan,
    '<': ComparisonOperator.lessThan,
    '.contains': ComparisonOperator.contains,
    '.startsWith': ComparisonOperator.startsWith,
    '.endsWith': ComparisonOperator.endsWith,
  };
}

/// Condition evaluator
class ConditionEvaluator {
  final Map<String, dynamic> variables;

  const ConditionEvaluator(this.variables);

  /// Evaluate a condition token
  dynamic evaluate(ConditionToken token) {
    if (token is VariableToken) {
      return variables[token.variableName];
    }

    if (token is LiteralToken) {
      return token.value;
    }

    if (token is ComparisonToken) {
      final left = evaluate(token.left);
      final right = evaluate(token.right);
      return _compare(left, token.operator, right);
    }

    if (token is LogicalToken) {
      switch (token.operator) {
        case LogicalOperator.and:
          return token.operands.every((o) => evaluate(o) == true);
        case LogicalOperator.or:
          return token.operands.any((o) => evaluate(o) == true);
        case LogicalOperator.not:
          return evaluate(token.operands.first) != true;
      }
    }

    return null;
  }

  bool _compare(dynamic left, ComparisonOperator op, dynamic right) {
    switch (op) {
      case ComparisonOperator.equals:
        return left == right;
      case ComparisonOperator.notEquals:
        return left != right;
      case ComparisonOperator.greaterThan:
        if (left is num && right is num) return left > right;
        return false;
      case ComparisonOperator.lessThan:
        if (left is num && right is num) return left < right;
        return false;
      case ComparisonOperator.greaterOrEqual:
        if (left is num && right is num) return left >= right;
        return false;
      case ComparisonOperator.lessOrEqual:
        if (left is num && right is num) return left <= right;
        return false;
      case ComparisonOperator.contains:
        if (left is String && right is String) return left.contains(right);
        return false;
      case ComparisonOperator.startsWith:
        if (left is String && right is String) return left.startsWith(right);
        return false;
      case ComparisonOperator.endsWith:
        if (left is String && right is String) return left.endsWith(right);
        return false;
    }
  }

  /// Evaluate a condition expression string
  bool evaluateExpression(String expression) {
    final token = ConditionParser.parse(expression);
    if (token == null) return false;
    final result = evaluate(token);
    return result == true;
  }
}

/// Variable operations executor
class VariableOperations {
  /// Apply an operation to a variable value
  static dynamic applyOperation(
    dynamic currentValue,
    VariableType type,
    dynamic operationValue,
    String operation,
  ) {
    switch (operation) {
      case 'set':
        return operationValue;

      case 'add':
        if (type == VariableType.number && currentValue is num && operationValue is num) {
          return currentValue + operationValue;
        }
        if (type == VariableType.string && currentValue is String && operationValue is String) {
          return currentValue + operationValue;
        }
        return currentValue;

      case 'subtract':
        if (type == VariableType.number && currentValue is num && operationValue is num) {
          return currentValue - operationValue;
        }
        return currentValue;

      case 'toggle':
        if (type == VariableType.boolean && currentValue is bool) {
          return !currentValue;
        }
        return currentValue;

      default:
        return currentValue;
    }
  }
}
