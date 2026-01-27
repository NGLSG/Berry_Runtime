/// Script Parser for VN Runtime
///
/// Parses custom script syntax into executable statements.

/// Statement types in the script language
enum StatementType {
  variableAssignment,
  functionCall,
  conditional,
  loop,
  returnStatement,
  expression,
}

/// Represents a parsed script statement
class ScriptStatement {
  final StatementType type;
  final Map<String, dynamic> data;

  const ScriptStatement({
    required this.type,
    required this.data,
  });
}

/// Result of parsing a script
class ScriptParseResult {
  final bool success;
  final List<ScriptStatement> statements;
  final String? errorMessage;
  final int? errorLine;
  final int? errorColumn;

  const ScriptParseResult({
    required this.success,
    this.statements = const [],
    this.errorMessage,
    this.errorLine,
    this.errorColumn,
  });

  factory ScriptParseResult.success(List<ScriptStatement> statements) {
    return ScriptParseResult(success: true, statements: statements);
  }

  factory ScriptParseResult.error(String message, {int? line, int? column}) {
    return ScriptParseResult(
      success: false,
      errorMessage: message,
      errorLine: line,
      errorColumn: column,
    );
  }
}

/// Parses script text into statements
class ScriptParser {
  int _pos = 0;
  String _source = '';
  int _line = 1;
  int _column = 1;

  /// Parse a script string into statements
  ScriptParseResult parse(String source) {
    _source = source.trim();
    _pos = 0;
    _line = 1;
    _column = 1;

    try {
      final statements = <ScriptStatement>[];

      while (!_isAtEnd()) {
        _skipWhitespaceAndComments();
        if (_isAtEnd()) break;

        final statement = _parseStatement();
        if (statement != null) {
          statements.add(statement);
        }
      }

      return ScriptParseResult.success(statements);
    } catch (e) {
      return ScriptParseResult.error(
        e.toString(),
        line: _line,
        column: _column,
      );
    }
  }

  ScriptStatement? _parseStatement() {
    _skipWhitespaceAndComments();
    if (_isAtEnd()) return null;

    // Check for keywords
    if (_matchKeyword('if')) {
      return _parseConditional();
    }
    if (_matchKeyword('while')) {
      return _parseWhileLoop();
    }
    if (_matchKeyword('for')) {
      return _parseForLoop();
    }
    if (_matchKeyword('return')) {
      return _parseReturn();
    }

    // Check for variable assignment or function call
    final identifier = _parseIdentifier();
    if (identifier != null) {
      _skipWhitespace();

      // Assignment
      if (_match('=')) {
        final value = _parseExpression();
        _consumeSemicolon();
        return ScriptStatement(
          type: StatementType.variableAssignment,
          data: {'variable': identifier, 'value': value},
        );
      }

      // Function call
      if (_match('(')) {
        final args = _parseArgumentList();
        _expect(')');
        _consumeSemicolon();
        return ScriptStatement(
          type: StatementType.functionCall,
          data: {'function': identifier, 'arguments': args},
        );
      }

      // Expression statement
      _consumeSemicolon();
      return ScriptStatement(
        type: StatementType.expression,
        data: {
          'expression': {'type': 'variable', 'name': identifier}
        },
      );
    }

    throw ParseException('Unexpected token at line $_line, column $_column');
  }

  ScriptStatement _parseConditional() {
    _skipWhitespace();
    _expect('(');
    final condition = _parseExpression();
    _expect(')');

    final thenStatements = _parseBlock();

    List<ScriptStatement>? elseStatements;
    _skipWhitespaceAndComments();
    if (_matchKeyword('else')) {
      elseStatements = _parseBlock();
    }

    return ScriptStatement(
      type: StatementType.conditional,
      data: {
        'condition': condition,
        'then': thenStatements,
        if (elseStatements != null) 'else': elseStatements,
      },
    );
  }

  ScriptStatement _parseWhileLoop() {
    _skipWhitespace();
    _expect('(');
    final condition = _parseExpression();
    _expect(')');

    final body = _parseBlock();

    return ScriptStatement(
      type: StatementType.loop,
      data: {
        'loopType': 'while',
        'condition': condition,
        'body': body,
      },
    );
  }

  ScriptStatement _parseForLoop() {
    _skipWhitespace();
    _expect('(');

    String? varName;
    if (!_check('0') && !_check('1') && !_check('2') && !_check('3') &&
        !_check('4') && !_check('5') && !_check('6') && !_check('7') &&
        !_check('8') && !_check('9')) {
      varName = _parseIdentifier();
      _skipWhitespace();
      if (_matchKeyword('in')) {
        _skipWhitespace();
      }
    }

    final count = _parseExpression();
    _expect(')');

    final body = _parseBlock();

    return ScriptStatement(
      type: StatementType.loop,
      data: {
        'loopType': 'for',
        'variable': varName,
        'count': count,
        'body': body,
      },
    );
  }

  ScriptStatement _parseReturn() {
    _skipWhitespace();
    final value = _parseExpression();
    _consumeSemicolon();

    return ScriptStatement(
      type: StatementType.returnStatement,
      data: {'value': value},
    );
  }

  List<ScriptStatement> _parseBlock() {
    _skipWhitespaceAndComments();
    _expect('{');

    final statements = <ScriptStatement>[];
    while (!_check('}') && !_isAtEnd()) {
      _skipWhitespaceAndComments();
      if (_check('}')) break;

      final statement = _parseStatement();
      if (statement != null) {
        statements.add(statement);
      }
    }

    _expect('}');
    return statements;
  }

  dynamic _parseExpression() {
    return _parseOr();
  }

  dynamic _parseOr() {
    var left = _parseAnd();

    while (_match('||')) {
      final right = _parseAnd();
      left = {'type': 'binary', 'operator': '||', 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseAnd() {
    var left = _parseEquality();

    while (_match('&&')) {
      final right = _parseEquality();
      left = {'type': 'binary', 'operator': '&&', 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseEquality() {
    var left = _parseComparison();

    while (true) {
      String? op;
      if (_match('==')) {
        op = '==';
      } else if (_match('!=')) {
        op = '!=';
      } else {
        break;
      }

      final right = _parseComparison();
      left = {'type': 'binary', 'operator': op, 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseComparison() {
    var left = _parseAdditive();

    while (true) {
      String? op;
      if (_match('<=')) {
        op = '<=';
      } else if (_match('>=')) {
        op = '>=';
      } else if (_match('<')) {
        op = '<';
      } else if (_match('>')) {
        op = '>';
      } else {
        break;
      }

      final right = _parseAdditive();
      left = {'type': 'binary', 'operator': op, 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseAdditive() {
    var left = _parseMultiplicative();

    while (true) {
      String? op;
      if (_match('+')) {
        op = '+';
      } else if (_match('-')) {
        op = '-';
      } else {
        break;
      }

      final right = _parseMultiplicative();
      left = {'type': 'binary', 'operator': op, 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseMultiplicative() {
    var left = _parseUnary();

    while (true) {
      String? op;
      if (_match('*')) {
        op = '*';
      } else if (_match('/')) {
        op = '/';
      } else if (_match('%')) {
        op = '%';
      } else {
        break;
      }

      final right = _parseUnary();
      left = {'type': 'binary', 'operator': op, 'left': left, 'right': right};
    }

    return left;
  }

  dynamic _parseUnary() {
    if (_match('!')) {
      final operand = _parseUnary();
      return {'type': 'unary', 'operator': '!', 'operand': operand};
    }
    if (_match('-')) {
      final operand = _parseUnary();
      return {'type': 'unary', 'operator': '-', 'operand': operand};
    }

    return _parsePrimary();
  }

  dynamic _parsePrimary() {
    _skipWhitespace();

    // Parenthesized expression
    if (_match('(')) {
      final expr = _parseExpression();
      _expect(')');
      return expr;
    }

    // Boolean literals
    if (_matchKeyword('true')) return {'type': 'literal', 'value': true};
    if (_matchKeyword('false')) return {'type': 'literal', 'value': false};
    if (_matchKeyword('null')) return {'type': 'literal', 'value': null};

    // String literal
    if (_check('"') || _check("'")) {
      return {'type': 'literal', 'value': _parseString()};
    }

    // Number literal
    if (_isDigit(_peek())) {
      return {'type': 'literal', 'value': _parseNumber()};
    }

    // Variable reference ($varName)
    if (_match('\$')) {
      final name = _parseIdentifier();
      if (name == null) throw ParseException('Expected variable name after \$');
      return {'type': 'variable', 'name': name};
    }

    // Identifier (variable or function call)
    final identifier = _parseIdentifier();
    if (identifier != null) {
      _skipWhitespace();

      // Function call
      if (_match('(')) {
        final args = _parseArgumentList();
        _expect(')');
        return {'type': 'call', 'function': identifier, 'arguments': args};
      }

      // Variable reference
      return {'type': 'variable', 'name': identifier};
    }

    throw ParseException('Unexpected token at line $_line, column $_column');
  }

  List<dynamic> _parseArgumentList() {
    final args = <dynamic>[];

    _skipWhitespace();
    if (_check(')')) return args;

    do {
      _skipWhitespace();
      args.add(_parseExpression());
      _skipWhitespace();
    } while (_match(','));

    return args;
  }

  String _parseString() {
    final quote = _advance();
    final buffer = StringBuffer();

    while (!_isAtEnd() && _peek() != quote) {
      if (_peek() == '\\') {
        _advance();
        if (!_isAtEnd()) {
          final escaped = _advance();
          switch (escaped) {
            case 'n':
              buffer.write('\n');
              break;
            case 't':
              buffer.write('\t');
              break;
            case 'r':
              buffer.write('\r');
              break;
            default:
              buffer.write(escaped);
          }
        }
      } else {
        buffer.write(_advance());
      }
    }

    if (_isAtEnd()) throw ParseException('Unterminated string');
    _advance(); // Consume closing quote

    return buffer.toString();
  }

  num _parseNumber() {
    final buffer = StringBuffer();

    while (!_isAtEnd() && (_isDigit(_peek()) || _peek() == '.')) {
      buffer.write(_advance());
    }

    final str = buffer.toString();
    if (str.contains('.')) {
      return double.parse(str);
    }
    return int.parse(str);
  }

  String? _parseIdentifier() {
    if (!_isAlpha(_peek())) return null;

    final buffer = StringBuffer();
    while (!_isAtEnd() && _isAlphaNumeric(_peek())) {
      buffer.write(_advance());
    }

    return buffer.toString();
  }

  void _skipWhitespace() {
    while (!_isAtEnd() && _isWhitespace(_peek())) {
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      } else {
        _column++;
      }
      _pos++;
    }
  }

  void _skipWhitespaceAndComments() {
    while (!_isAtEnd()) {
      _skipWhitespace();

      // Single-line comment
      if (_check('/') && _checkNext('/')) {
        while (!_isAtEnd() && _peek() != '\n') {
          _advance();
        }
        continue;
      }

      // Multi-line comment
      if (_check('/') && _checkNext('*')) {
        _advance();
        _advance();
        while (!_isAtEnd() && !(_check('*') && _checkNext('/'))) {
          if (_peek() == '\n') {
            _line++;
            _column = 1;
          }
          _advance();
        }
        if (!_isAtEnd()) {
          _advance();
          _advance();
        }
        continue;
      }

      break;
    }
  }

  void _consumeSemicolon() {
    _skipWhitespace();
    _match(';'); // Optional semicolon
  }

  bool _match(String expected) {
    _skipWhitespace();
    if (_source.substring(_pos).startsWith(expected)) {
      _pos += expected.length;
      _column += expected.length;
      return true;
    }
    return false;
  }

  bool _matchKeyword(String keyword) {
    _skipWhitespace();
    if (_source.substring(_pos).startsWith(keyword)) {
      final nextPos = _pos + keyword.length;
      if (nextPos >= _source.length || !_isAlphaNumeric(_source[nextPos])) {
        _pos = nextPos;
        _column += keyword.length;
        return true;
      }
    }
    return false;
  }

  void _expect(String expected) {
    _skipWhitespace();
    if (!_match(expected)) {
      throw ParseException(
        'Expected "$expected" at line $_line, column $_column',
      );
    }
  }

  bool _check(String expected) {
    if (_isAtEnd()) return false;
    return _source.substring(_pos).startsWith(expected);
  }

  bool _checkNext(String expected) {
    if (_pos + 1 >= _source.length) return false;
    return _source[_pos + 1] == expected;
  }

  String _peek() {
    if (_isAtEnd()) return '';
    return _source[_pos];
  }

  String _advance() {
    if (_isAtEnd()) return '';
    final char = _source[_pos];
    _pos++;
    _column++;
    return char;
  }

  bool _isAtEnd() => _pos >= _source.length;

  bool _isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0' to '9'
  }

  bool _isAlpha(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // 'A' to 'Z'
        (code >= 97 && code <= 122) || // 'a' to 'z'
        char == '_';
  }

  bool _isAlphaNumeric(String char) {
    return _isAlpha(char) || _isDigit(char);
  }
}

/// Exception thrown during parsing
class ParseException implements Exception {
  final String message;
  ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}
