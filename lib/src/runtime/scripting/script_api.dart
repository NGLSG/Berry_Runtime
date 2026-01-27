/// Script API for VN Runtime
///
/// Provides the API that scripts can use to interact with the VN engine.
/// This includes access to engine state, variables, and async operations.

import 'dart:async';

import 'script_context.dart';
import 'script_sandbox.dart';

/// API exposed to scripts for interacting with the VN engine
class ScriptAPI {
  /// Engine state accessor
  final ScriptEngineStateAccessor? engineState;

  /// Custom function handlers
  final Map<String, ScriptFunction> _customFunctions = {};

  /// Event handlers
  final Map<String, List<ScriptEventHandler>> _eventHandlers = {};

  ScriptAPI({this.engineState});

  /// Register a custom function
  void registerFunction(String name, ScriptFunction function) {
    _customFunctions[name] = function;
  }

  /// Unregister a custom function
  void unregisterFunction(String name) {
    _customFunctions.remove(name);
  }

  /// Register an event handler
  void on(String event, ScriptEventHandler handler) {
    _eventHandlers.putIfAbsent(event, () => []).add(handler);
  }

  /// Remove an event handler
  void off(String event, ScriptEventHandler handler) {
    _eventHandlers[event]?.remove(handler);
  }

  /// Emit an event
  Future<void> emit(String event, [dynamic data]) async {
    final handlers = _eventHandlers[event];
    if (handlers != null) {
      for (final handler in handlers) {
        await handler(data);
      }
    }
  }

  /// Call a function (built-in or custom)
  Future<dynamic> callFunction(
    String name,
    List<dynamic> args,
    ScriptContext context,
  ) async {
    // Check custom functions first
    if (_customFunctions.containsKey(name)) {
      return _customFunctions[name]!(args, context);
    }

    // Engine state functions
    if (engineState != null) {
      switch (name) {
        case 'getCurrentChapter':
          return engineState!.currentChapterId;

        case 'getCurrentNode':
          return engineState!.currentNodeId;

        case 'getDialogueIndex':
          return engineState!.currentDialogueIndex;

        case 'isDialogueRead':
          if (args.length < 3) {
            throw ArgumentError(
              'isDialogueRead() requires chapterId, nodeId, and dialogueIndex',
            );
          }
          return engineState!.isDialogueRead(
            args[0] as String,
            args[1] as String,
            args[2] as int,
          );

        case 'getBackground':
          return engineState!.currentBackgroundId;

        case 'getBGM':
          return engineState!.currentBgmId;

        case 'getDisplayedCharacters':
          return engineState!.displayedCharacterIds;

        case 'isCharacterDisplayed':
          if (args.isEmpty) {
            throw ArgumentError('isCharacterDisplayed() requires a character ID');
          }
          return engineState!.displayedCharacterIds.contains(args[0] as String);
      }
    }

    throw UnimplementedError('Unknown function: $name');
  }

  /// Get all registered function names
  List<String> getRegisteredFunctions() {
    return _customFunctions.keys.toList();
  }
}

/// Type for custom script functions
typedef ScriptFunction = FutureOr<dynamic> Function(
  List<dynamic> args,
  ScriptContext context,
);

/// Type for script event handlers
typedef ScriptEventHandler = FutureOr<void> Function(dynamic data);

/// Builder for creating ScriptAPI with common functions
class ScriptAPIBuilder {
  final ScriptAPI _api;

  ScriptAPIBuilder({ScriptEngineStateAccessor? engineState})
      : _api = ScriptAPI(engineState: engineState);

  /// Add variable manipulation functions
  ScriptAPIBuilder withVariableFunctions() {
    _api.registerFunction('getVar', (args, context) {
      if (args.isEmpty) throw ArgumentError('getVar() requires a variable name');
      return context.getVariable(args[0] as String);
    });

    _api.registerFunction('setVar', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('setVar() requires variable name and value');
      }
      context.setVariable(args[0] as String, args[1]);
      return args[1];
    });

    _api.registerFunction('hasVar', (args, context) {
      if (args.isEmpty) throw ArgumentError('hasVar() requires a variable name');
      return context.hasVariable(args[0] as String);
    });

    _api.registerFunction('incrementVar', (args, context) {
      if (args.isEmpty) {
        throw ArgumentError('incrementVar() requires a variable name');
      }
      final name = args[0] as String;
      final amount = args.length > 1 ? (args[1] as num) : 1;
      final current = context.getVariable(name) ?? 0;
      final newValue = (current as num) + amount;
      context.setVariable(name, newValue);
      return newValue;
    });

    _api.registerFunction('decrementVar', (args, context) {
      if (args.isEmpty) {
        throw ArgumentError('decrementVar() requires a variable name');
      }
      final name = args[0] as String;
      final amount = args.length > 1 ? (args[1] as num) : 1;
      final current = context.getVariable(name) ?? 0;
      final newValue = (current as num) - amount;
      context.setVariable(name, newValue);
      return newValue;
    });

    _api.registerFunction('toggleVar', (args, context) {
      if (args.isEmpty) {
        throw ArgumentError('toggleVar() requires a variable name');
      }
      final name = args[0] as String;
      final current = context.getVariable(name) ?? false;
      final newValue = !(current as bool);
      context.setVariable(name, newValue);
      return newValue;
    });

    return this;
  }

  /// Add math utility functions
  ScriptAPIBuilder withMathFunctions() {
    _api.registerFunction('clamp', (args, context) {
      if (args.length < 3) {
        throw ArgumentError('clamp() requires value, min, and max');
      }
      final value = args[0] as num;
      final min = args[1] as num;
      final max = args[2] as num;
      return value.clamp(min, max);
    });

    _api.registerFunction('lerp', (args, context) {
      if (args.length < 3) {
        throw ArgumentError('lerp() requires a, b, and t');
      }
      final a = args[0] as num;
      final b = args[1] as num;
      final t = args[2] as num;
      return a + (b - a) * t;
    });

    _api.registerFunction('pow', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('pow() requires base and exponent');
      }
      final base = args[0] as num;
      final exp = args[1] as num;
      return _pow(base.toDouble(), exp.toDouble());
    });

    _api.registerFunction('sqrt', (args, context) {
      if (args.isEmpty) throw ArgumentError('sqrt() requires a number');
      return _sqrt((args[0] as num).toDouble());
    });

    return this;
  }

  /// Add string utility functions
  ScriptAPIBuilder withStringFunctions() {
    _api.registerFunction('format', (args, context) {
      if (args.isEmpty) throw ArgumentError('format() requires a template');
      var template = args[0] as String;

      // Replace {0}, {1}, etc. with arguments
      for (var i = 1; i < args.length; i++) {
        template = template.replaceAll('{${i - 1}}', args[i].toString());
      }

      // Replace {varName} with variable values
      template = template.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (match) {
          final varName = match.group(1)!;
          final value = context.getVariable(varName);
          return value?.toString() ?? '{$varName}';
        },
      );

      return template;
    });

    _api.registerFunction('split', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('split() requires string and delimiter');
      }
      return (args[0] as String).split(args[1] as String);
    });

    _api.registerFunction('join', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('join() requires list and delimiter');
      }
      return (args[0] as List).join(args[1] as String);
    });

    _api.registerFunction('trim', (args, context) {
      if (args.isEmpty) throw ArgumentError('trim() requires a string');
      return (args[0] as String).trim();
    });

    _api.registerFunction('replace', (args, context) {
      if (args.length < 3) {
        throw ArgumentError('replace() requires string, from, and to');
      }
      return (args[0] as String).replaceAll(
        args[1] as String,
        args[2] as String,
      );
    });

    return this;
  }

  /// Add list utility functions
  ScriptAPIBuilder withListFunctions() {
    _api.registerFunction('list', (args, context) {
      return args.toList();
    });

    _api.registerFunction('listGet', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('listGet() requires list and index');
      }
      final list = args[0] as List;
      final index = args[1] as int;
      if (index < 0 || index >= list.length) return null;
      return list[index];
    });

    _api.registerFunction('listSet', (args, context) {
      if (args.length < 3) {
        throw ArgumentError('listSet() requires list, index, and value');
      }
      final list = args[0] as List;
      final index = args[1] as int;
      if (index >= 0 && index < list.length) {
        list[index] = args[2];
      }
      return list;
    });

    _api.registerFunction('listAdd', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('listAdd() requires list and value');
      }
      final list = args[0] as List;
      list.add(args[1]);
      return list;
    });

    _api.registerFunction('listRemove', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('listRemove() requires list and value');
      }
      final list = args[0] as List;
      list.remove(args[1]);
      return list;
    });

    _api.registerFunction('listLength', (args, context) {
      if (args.isEmpty) throw ArgumentError('listLength() requires a list');
      return (args[0] as List).length;
    });

    _api.registerFunction('listContains', (args, context) {
      if (args.length < 2) {
        throw ArgumentError('listContains() requires list and value');
      }
      return (args[0] as List).contains(args[1]);
    });

    return this;
  }

  /// Add async utility functions
  ScriptAPIBuilder withAsyncFunctions() {
    _api.registerFunction('delay', (args, context) async {
      final ms = args.isNotEmpty ? (args[0] as num).toInt() : 1000;
      await context.wait(Duration(milliseconds: ms));
      return null;
    });

    _api.registerFunction('timeout', (args, context) async {
      if (args.length < 2) {
        throw ArgumentError('timeout() requires callback and milliseconds');
      }
      final ms = (args[1] as num).toInt();
      await context.wait(Duration(milliseconds: ms));
      // Note: In a real implementation, this would execute the callback
      return null;
    });

    return this;
  }

  /// Build the ScriptAPI
  ScriptAPI build() => _api;
}

// Simple math implementations to avoid dart:math import issues
double _pow(double base, double exp) {
  if (exp == 0) return 1;
  if (exp == 1) return base;
  if (exp < 0) return 1 / _pow(base, -exp);

  var result = 1.0;
  var intExp = exp.toInt();
  for (var i = 0; i < intExp; i++) {
    result *= base;
  }
  return result;
}

double _sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;

  var guess = x / 2;
  for (var i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
