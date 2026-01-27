/// Mini-Game Variable Bridge for VN Runtime
/// 
/// Handles variable passing between the VN story and mini-games.
/// Provides input variable resolution and output variable mapping.
/// 
/// Requirements: 17.2, 17.5

import 'mini_game_interface.dart';

/// Variable type for mini-game I/O
enum MiniGameVariableType {
  string,
  number,
  boolean,
  list,
  map,
}

/// Definition of an input variable for a mini-game
class MiniGameInputVariable {
  /// Variable name in the mini-game
  final String name;
  
  /// Display label for the variable
  final String label;
  
  /// Description of what this variable is used for
  final String? description;
  
  /// Expected type of the variable
  final MiniGameVariableType type;
  
  /// Whether this variable is required
  final bool required;
  
  /// Default value if not provided
  final dynamic defaultValue;
  
  /// Story variable name to read from (if using variable reference)
  final String? storyVariableName;

  const MiniGameInputVariable({
    required this.name,
    required this.label,
    this.description,
    this.type = MiniGameVariableType.string,
    this.required = false,
    this.defaultValue,
    this.storyVariableName,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
    if (description != null) 'description': description,
    'type': type.name,
    'required': required,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (storyVariableName != null) 'storyVariableName': storyVariableName,
  };

  factory MiniGameInputVariable.fromJson(Map<String, dynamic> json) {
    return MiniGameInputVariable(
      name: json['name'] as String,
      label: json['label'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      type: MiniGameVariableType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MiniGameVariableType.string,
      ),
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      storyVariableName: json['storyVariableName'] as String?,
    );
  }
}

/// Definition of an output variable from a mini-game
class MiniGameOutputVariable {
  /// Variable name in the mini-game output
  final String name;
  
  /// Display label for the variable
  final String label;
  
  /// Description of what this variable represents
  final String? description;
  
  /// Type of the variable
  final MiniGameVariableType type;
  
  /// Story variable name to write to
  final String storyVariableName;
  
  /// Default value if mini-game is skipped
  final dynamic skipDefault;

  const MiniGameOutputVariable({
    required this.name,
    required this.label,
    this.description,
    this.type = MiniGameVariableType.string,
    required this.storyVariableName,
    this.skipDefault,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
    if (description != null) 'description': description,
    'type': type.name,
    'storyVariableName': storyVariableName,
    if (skipDefault != null) 'skipDefault': skipDefault,
  };

  factory MiniGameOutputVariable.fromJson(Map<String, dynamic> json) {
    return MiniGameOutputVariable(
      name: json['name'] as String,
      label: json['label'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      type: MiniGameVariableType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MiniGameVariableType.string,
      ),
      storyVariableName: json['storyVariableName'] as String? ?? json['name'] as String,
      skipDefault: json['skipDefault'],
    );
  }
}


/// Bridge for passing variables between VN story and mini-games
class MiniGameVariableBridge {
  /// Resolve input variables from story variables
  /// 
  /// [inputDefs] - Input variable definitions
  /// [configInputs] - Input values from the mini-game config
  /// [storyVariables] - Current story variables
  /// 
  /// Returns resolved input values for the mini-game
  static Map<String, dynamic> resolveInputs({
    required List<MiniGameInputVariable> inputDefs,
    required Map<String, dynamic> configInputs,
    required Map<String, dynamic> storyVariables,
  }) {
    final resolved = <String, dynamic>{};

    for (final def in inputDefs) {
      dynamic value;

      // Check if there's a config value
      if (configInputs.containsKey(def.name)) {
        final configValue = configInputs[def.name];
        
        // Check if it's a variable reference
        if (configValue is String && configValue.startsWith('\$')) {
          final varName = configValue.substring(1);
          value = storyVariables[varName];
        } else {
          value = configValue;
        }
      }
      // Check if there's a story variable reference in the definition
      else if (def.storyVariableName != null) {
        value = storyVariables[def.storyVariableName];
      }

      // Use default if no value found
      value ??= def.defaultValue;

      // Validate required variables
      if (def.required && value == null) {
        throw MiniGameVariableException(
          'Required input variable "${def.name}" is missing',
        );
      }

      // Type coercion
      if (value != null) {
        value = _coerceType(value, def.type);
      }

      resolved[def.name] = value;
    }

    return resolved;
  }

  /// Map output variables to story variables
  /// 
  /// [outputDefs] - Output variable definitions
  /// [result] - Mini-game result containing output values
  /// 
  /// Returns a map of story variable names to values
  static Map<String, dynamic> mapOutputs({
    required List<MiniGameOutputVariable> outputDefs,
    required MiniGameResult result,
  }) {
    final storyVars = <String, dynamic>{};

    for (final def in outputDefs) {
      dynamic value;

      if (result.skipped) {
        // Use skip default
        value = def.skipDefault;
      } else {
        // Get value from result
        value = result.outputVariables[def.name];
      }

      // Type coercion
      if (value != null) {
        value = _coerceType(value, def.type);
      }

      storyVars[def.storyVariableName] = value;
    }

    return storyVars;
  }

  /// Validate input variables against definitions
  static List<String> validateInputs({
    required List<MiniGameInputVariable> inputDefs,
    required Map<String, dynamic> configInputs,
  }) {
    final errors = <String>[];

    for (final def in inputDefs) {
      if (def.required && !configInputs.containsKey(def.name)) {
        if (def.storyVariableName == null && def.defaultValue == null) {
          errors.add('Required input "${def.name}" is not configured');
        }
      }
    }

    return errors;
  }

  /// Validate output variable mappings
  static List<String> validateOutputMappings({
    required List<MiniGameOutputVariable> outputDefs,
  }) {
    final errors = <String>[];
    final storyVarNames = <String>{};

    for (final def in outputDefs) {
      if (def.storyVariableName.isEmpty) {
        errors.add('Output "${def.name}" has no story variable mapping');
      }
      
      if (storyVarNames.contains(def.storyVariableName)) {
        errors.add('Duplicate story variable mapping: ${def.storyVariableName}');
      }
      storyVarNames.add(def.storyVariableName);
    }

    return errors;
  }

  /// Coerce a value to the expected type
  static dynamic _coerceType(dynamic value, MiniGameVariableType type) {
    switch (type) {
      case MiniGameVariableType.string:
        return value.toString();
      case MiniGameVariableType.number:
        if (value is num) return value;
        if (value is String) {
          return num.tryParse(value) ?? 0;
        }
        return 0;
      case MiniGameVariableType.boolean:
        if (value is bool) return value;
        if (value is String) {
          return value.toLowerCase() == 'true';
        }
        if (value is num) return value != 0;
        return false;
      case MiniGameVariableType.list:
        if (value is List) return value;
        return [value];
      case MiniGameVariableType.map:
        if (value is Map) return value;
        return <String, dynamic>{};
    }
  }
}

/// Exception thrown when there's a variable error
class MiniGameVariableException implements Exception {
  final String message;
  
  MiniGameVariableException(this.message);
  
  @override
  String toString() => 'MiniGameVariableException: $message';
}

/// Extension to create variable definitions from simple maps
extension MiniGameVariableExtensions on MiniGameConfig {
  /// Get input variable definitions from the config
  List<MiniGameInputVariable> getInputDefinitions() {
    final defs = customConfig['inputDefinitions'] as List<dynamic>?;
    if (defs == null) return [];
    
    return defs
        .map((d) => MiniGameInputVariable.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Get output variable definitions from the config
  List<MiniGameOutputVariable> getOutputDefinitions() {
    final defs = customConfig['outputDefinitions'] as List<dynamic>?;
    if (defs == null) return [];
    
    return defs
        .map((d) => MiniGameOutputVariable.fromJson(d as Map<String, dynamic>))
        .toList();
  }
}
