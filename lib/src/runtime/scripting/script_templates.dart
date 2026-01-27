/// Script Templates for VN Runtime
///
/// Provides pre-built script templates for common operations.

/// A script template with metadata
class ScriptTemplate {
  /// Template identifier
  final String id;

  /// Display name
  final String name;

  /// Description of what the template does
  final String description;

  /// Category for organization
  final ScriptTemplateCategory category;

  /// The script code
  final String code;

  /// Parameters that can be customized
  final List<ScriptTemplateParameter> parameters;

  const ScriptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.code,
    this.parameters = const [],
  });

  /// Generate the script with parameter values
  String generate(Map<String, dynamic> parameterValues) {
    var result = code;

    for (final param in parameters) {
      final value = parameterValues[param.name] ?? param.defaultValue;
      result = result.replaceAll('{{${param.name}}}', value.toString());
    }

    return result;
  }
}

/// A parameter in a script template
class ScriptTemplateParameter {
  /// Parameter name
  final String name;

  /// Display label
  final String label;

  /// Description
  final String description;

  /// Parameter type
  final ScriptParameterType type;

  /// Default value
  final dynamic defaultValue;

  /// Options for select type
  final List<String>? options;

  const ScriptTemplateParameter({
    required this.name,
    required this.label,
    required this.description,
    required this.type,
    this.defaultValue,
    this.options,
  });
}

/// Types of template parameters
enum ScriptParameterType {
  string,
  number,
  boolean,
  select,
  variable,
}

/// Categories for organizing templates
enum ScriptTemplateCategory {
  variables,
  math,
  conditions,
  loops,
  utility,
  gameLogic,
}

/// Built-in script templates
class ScriptTemplates {
  static const List<ScriptTemplate> all = [
    // Variable templates
    _setVariable,
    _incrementVariable,
    _toggleVariable,
    _conditionalSet,

    // Math templates
    _randomNumber,
    _clampValue,
    _calculatePercentage,

    // Condition templates
    _simpleCondition,
    _multiCondition,
    _rangeCheck,

    // Loop templates
    _countLoop,
    _whileLoop,

    // Utility templates
    _logMessage,
    _formatString,
    _waitDelay,

    // Game logic templates
    _affectionChange,
    _flagCheck,
    _scoreCalculation,
  ];

  // Variable templates
  static const _setVariable = ScriptTemplate(
    id: 'set_variable',
    name: 'Set Variable',
    description: 'Set a variable to a specific value',
    category: ScriptTemplateCategory.variables,
    code: '{{variable}} = {{value}};',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable Name',
        description: 'The name of the variable to set',
        type: ScriptParameterType.variable,
        defaultValue: 'myVariable',
      ),
      ScriptTemplateParameter(
        name: 'value',
        label: 'Value',
        description: 'The value to set',
        type: ScriptParameterType.string,
        defaultValue: '0',
      ),
    ],
  );

  static const _incrementVariable = ScriptTemplate(
    id: 'increment_variable',
    name: 'Increment Variable',
    description: 'Add a value to a numeric variable',
    category: ScriptTemplateCategory.variables,
    code: '{{variable}} = \${{variable}} + {{amount}};',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable Name',
        description: 'The name of the variable to increment',
        type: ScriptParameterType.variable,
        defaultValue: 'score',
      ),
      ScriptTemplateParameter(
        name: 'amount',
        label: 'Amount',
        description: 'The amount to add',
        type: ScriptParameterType.number,
        defaultValue: 1,
      ),
    ],
  );

  static const _toggleVariable = ScriptTemplate(
    id: 'toggle_variable',
    name: 'Toggle Boolean',
    description: 'Toggle a boolean variable between true and false',
    category: ScriptTemplateCategory.variables,
    code: '{{variable}} = !\${{variable}};',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable Name',
        description: 'The name of the boolean variable to toggle',
        type: ScriptParameterType.variable,
        defaultValue: 'isEnabled',
      ),
    ],
  );

  static const _conditionalSet = ScriptTemplate(
    id: 'conditional_set',
    name: 'Conditional Set',
    description: 'Set a variable based on a condition',
    category: ScriptTemplateCategory.variables,
    code: '''if (\${{condition}}) {
  {{variable}} = {{trueValue}};
} else {
  {{variable}} = {{falseValue}};
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'condition',
        label: 'Condition Variable',
        description: 'The boolean variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'isTrue',
      ),
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Target Variable',
        description: 'The variable to set',
        type: ScriptParameterType.variable,
        defaultValue: 'result',
      ),
      ScriptTemplateParameter(
        name: 'trueValue',
        label: 'Value if True',
        description: 'Value when condition is true',
        type: ScriptParameterType.string,
        defaultValue: '1',
      ),
      ScriptTemplateParameter(
        name: 'falseValue',
        label: 'Value if False',
        description: 'Value when condition is false',
        type: ScriptParameterType.string,
        defaultValue: '0',
      ),
    ],
  );

  // Math templates
  static const _randomNumber = ScriptTemplate(
    id: 'random_number',
    name: 'Random Number',
    description: 'Generate a random number within a range',
    category: ScriptTemplateCategory.math,
    code: '{{variable}} = random({{min}}, {{max}});',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable Name',
        description: 'Variable to store the random number',
        type: ScriptParameterType.variable,
        defaultValue: 'randomValue',
      ),
      ScriptTemplateParameter(
        name: 'min',
        label: 'Minimum',
        description: 'Minimum value (inclusive)',
        type: ScriptParameterType.number,
        defaultValue: 0,
      ),
      ScriptTemplateParameter(
        name: 'max',
        label: 'Maximum',
        description: 'Maximum value (exclusive)',
        type: ScriptParameterType.number,
        defaultValue: 100,
      ),
    ],
  );

  static const _clampValue = ScriptTemplate(
    id: 'clamp_value',
    name: 'Clamp Value',
    description: 'Clamp a variable within a range',
    category: ScriptTemplateCategory.math,
    code: '{{variable}} = clamp(\${{variable}}, {{min}}, {{max}});',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable Name',
        description: 'Variable to clamp',
        type: ScriptParameterType.variable,
        defaultValue: 'value',
      ),
      ScriptTemplateParameter(
        name: 'min',
        label: 'Minimum',
        description: 'Minimum allowed value',
        type: ScriptParameterType.number,
        defaultValue: 0,
      ),
      ScriptTemplateParameter(
        name: 'max',
        label: 'Maximum',
        description: 'Maximum allowed value',
        type: ScriptParameterType.number,
        defaultValue: 100,
      ),
    ],
  );

  static const _calculatePercentage = ScriptTemplate(
    id: 'calculate_percentage',
    name: 'Calculate Percentage',
    description: 'Calculate a percentage of a value',
    category: ScriptTemplateCategory.math,
    code: '{{result}} = floor(\${{value}} * {{percentage}} / 100);',
    parameters: [
      ScriptTemplateParameter(
        name: 'value',
        label: 'Value Variable',
        description: 'The value to calculate percentage of',
        type: ScriptParameterType.variable,
        defaultValue: 'total',
      ),
      ScriptTemplateParameter(
        name: 'percentage',
        label: 'Percentage',
        description: 'The percentage to calculate',
        type: ScriptParameterType.number,
        defaultValue: 50,
      ),
      ScriptTemplateParameter(
        name: 'result',
        label: 'Result Variable',
        description: 'Variable to store the result',
        type: ScriptParameterType.variable,
        defaultValue: 'result',
      ),
    ],
  );

  // Condition templates
  static const _simpleCondition = ScriptTemplate(
    id: 'simple_condition',
    name: 'Simple Condition',
    description: 'Execute code based on a simple condition',
    category: ScriptTemplateCategory.conditions,
    code: '''if (\${{variable}} {{operator}} {{value}}) {
  // Code when condition is true
  log("Condition met");
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable',
        description: 'Variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'score',
      ),
      ScriptTemplateParameter(
        name: 'operator',
        label: 'Operator',
        description: 'Comparison operator',
        type: ScriptParameterType.select,
        defaultValue: '>=',
        options: ['==', '!=', '>', '<', '>=', '<='],
      ),
      ScriptTemplateParameter(
        name: 'value',
        label: 'Value',
        description: 'Value to compare against',
        type: ScriptParameterType.string,
        defaultValue: '50',
      ),
    ],
  );

  static const _multiCondition = ScriptTemplate(
    id: 'multi_condition',
    name: 'Multiple Conditions',
    description: 'Check multiple conditions with AND/OR',
    category: ScriptTemplateCategory.conditions,
    code: '''if (\${{var1}} {{op1}} {{val1}} {{logic}} \${{var2}} {{op2}} {{val2}}) {
  // Code when conditions are met
  log("All conditions met");
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'var1',
        label: 'First Variable',
        description: 'First variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'score',
      ),
      ScriptTemplateParameter(
        name: 'op1',
        label: 'First Operator',
        description: 'First comparison operator',
        type: ScriptParameterType.select,
        defaultValue: '>=',
        options: ['==', '!=', '>', '<', '>=', '<='],
      ),
      ScriptTemplateParameter(
        name: 'val1',
        label: 'First Value',
        description: 'First value to compare',
        type: ScriptParameterType.string,
        defaultValue: '50',
      ),
      ScriptTemplateParameter(
        name: 'logic',
        label: 'Logic Operator',
        description: 'AND or OR',
        type: ScriptParameterType.select,
        defaultValue: '&&',
        options: ['&&', '||'],
      ),
      ScriptTemplateParameter(
        name: 'var2',
        label: 'Second Variable',
        description: 'Second variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'level',
      ),
      ScriptTemplateParameter(
        name: 'op2',
        label: 'Second Operator',
        description: 'Second comparison operator',
        type: ScriptParameterType.select,
        defaultValue: '>=',
        options: ['==', '!=', '>', '<', '>=', '<='],
      ),
      ScriptTemplateParameter(
        name: 'val2',
        label: 'Second Value',
        description: 'Second value to compare',
        type: ScriptParameterType.string,
        defaultValue: '5',
      ),
    ],
  );

  static const _rangeCheck = ScriptTemplate(
    id: 'range_check',
    name: 'Range Check',
    description: 'Check if a value is within a range',
    category: ScriptTemplateCategory.conditions,
    code: '''if (\${{variable}} >= {{min}} && \${{variable}} <= {{max}}) {
  // Value is within range
  log("Value is in range");
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable',
        description: 'Variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'value',
      ),
      ScriptTemplateParameter(
        name: 'min',
        label: 'Minimum',
        description: 'Minimum of range',
        type: ScriptParameterType.number,
        defaultValue: 0,
      ),
      ScriptTemplateParameter(
        name: 'max',
        label: 'Maximum',
        description: 'Maximum of range',
        type: ScriptParameterType.number,
        defaultValue: 100,
      ),
    ],
  );

  // Loop templates
  static const _countLoop = ScriptTemplate(
    id: 'count_loop',
    name: 'Count Loop',
    description: 'Execute code a specific number of times',
    category: ScriptTemplateCategory.loops,
    code: '''for (i in {{count}}) {
  // Code to repeat
  log("Iteration: " + \$i);
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'count',
        label: 'Count',
        description: 'Number of iterations',
        type: ScriptParameterType.number,
        defaultValue: 10,
      ),
    ],
  );

  static const _whileLoop = ScriptTemplate(
    id: 'while_loop',
    name: 'While Loop',
    description: 'Execute code while a condition is true',
    category: ScriptTemplateCategory.loops,
    code: '''while (\${{variable}} {{operator}} {{value}}) {
  // Code to repeat
  {{variable}} = \${{variable}} + 1;
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'variable',
        label: 'Variable',
        description: 'Variable to check',
        type: ScriptParameterType.variable,
        defaultValue: 'counter',
      ),
      ScriptTemplateParameter(
        name: 'operator',
        label: 'Operator',
        description: 'Comparison operator',
        type: ScriptParameterType.select,
        defaultValue: '<',
        options: ['==', '!=', '>', '<', '>=', '<='],
      ),
      ScriptTemplateParameter(
        name: 'value',
        label: 'Value',
        description: 'Value to compare against',
        type: ScriptParameterType.string,
        defaultValue: '10',
      ),
    ],
  );

  // Utility templates
  static const _logMessage = ScriptTemplate(
    id: 'log_message',
    name: 'Log Message',
    description: 'Log a message for debugging',
    category: ScriptTemplateCategory.utility,
    code: 'log("{{message}}");',
    parameters: [
      ScriptTemplateParameter(
        name: 'message',
        label: 'Message',
        description: 'Message to log',
        type: ScriptParameterType.string,
        defaultValue: 'Debug message',
      ),
    ],
  );

  static const _formatString = ScriptTemplate(
    id: 'format_string',
    name: 'Format String',
    description: 'Format a string with variable values',
    category: ScriptTemplateCategory.utility,
    code: '{{result}} = format("{{template}}", \${{var1}}, \${{var2}});',
    parameters: [
      ScriptTemplateParameter(
        name: 'result',
        label: 'Result Variable',
        description: 'Variable to store the formatted string',
        type: ScriptParameterType.variable,
        defaultValue: 'message',
      ),
      ScriptTemplateParameter(
        name: 'template',
        label: 'Template',
        description: 'String template with {0}, {1} placeholders',
        type: ScriptParameterType.string,
        defaultValue: 'Hello {0}, your score is {1}',
      ),
      ScriptTemplateParameter(
        name: 'var1',
        label: 'First Variable',
        description: 'First variable to insert',
        type: ScriptParameterType.variable,
        defaultValue: 'playerName',
      ),
      ScriptTemplateParameter(
        name: 'var2',
        label: 'Second Variable',
        description: 'Second variable to insert',
        type: ScriptParameterType.variable,
        defaultValue: 'score',
      ),
    ],
  );

  static const _waitDelay = ScriptTemplate(
    id: 'wait_delay',
    name: 'Wait/Delay',
    description: 'Wait for a specified duration',
    category: ScriptTemplateCategory.utility,
    code: 'wait({{milliseconds}});',
    parameters: [
      ScriptTemplateParameter(
        name: 'milliseconds',
        label: 'Milliseconds',
        description: 'Duration to wait in milliseconds',
        type: ScriptParameterType.number,
        defaultValue: 1000,
      ),
    ],
  );

  // Game logic templates
  static const _affectionChange = ScriptTemplate(
    id: 'affection_change',
    name: 'Affection Change',
    description: 'Modify character affection with bounds checking',
    category: ScriptTemplateCategory.gameLogic,
    code: '''// Modify affection for {{character}}
{{character}}_affection = clamp(\${{character}}_affection + {{amount}}, 0, 100);
log("{{character}} affection: " + \${{character}}_affection);''',
    parameters: [
      ScriptTemplateParameter(
        name: 'character',
        label: 'Character',
        description: 'Character name (used as variable prefix)',
        type: ScriptParameterType.string,
        defaultValue: 'alice',
      ),
      ScriptTemplateParameter(
        name: 'amount',
        label: 'Amount',
        description: 'Amount to change (positive or negative)',
        type: ScriptParameterType.number,
        defaultValue: 5,
      ),
    ],
  );

  static const _flagCheck = ScriptTemplate(
    id: 'flag_check',
    name: 'Flag Check',
    description: 'Check and set story flags',
    category: ScriptTemplateCategory.gameLogic,
    code: '''if (!\${{flag}}) {
  // First time seeing this
  {{flag}} = true;
  log("Flag {{flag}} set for the first time");
} else {
  // Already seen
  log("Flag {{flag}} was already set");
}''',
    parameters: [
      ScriptTemplateParameter(
        name: 'flag',
        label: 'Flag Name',
        description: 'Name of the flag variable',
        type: ScriptParameterType.variable,
        defaultValue: 'seen_intro',
      ),
    ],
  );

  static const _scoreCalculation = ScriptTemplate(
    id: 'score_calculation',
    name: 'Score Calculation',
    description: 'Calculate a score based on multiple factors',
    category: ScriptTemplateCategory.gameLogic,
    code: '''// Calculate final score
{{result}} = floor(\${{base}} * {{multiplier}});
{{result}} = \${{result}} + {{bonus}};
{{result}} = clamp(\${{result}}, 0, {{max}});
log("Final score: " + \${{result}});''',
    parameters: [
      ScriptTemplateParameter(
        name: 'base',
        label: 'Base Score Variable',
        description: 'Variable containing the base score',
        type: ScriptParameterType.variable,
        defaultValue: 'baseScore',
      ),
      ScriptTemplateParameter(
        name: 'multiplier',
        label: 'Multiplier',
        description: 'Score multiplier',
        type: ScriptParameterType.number,
        defaultValue: 1.5,
      ),
      ScriptTemplateParameter(
        name: 'bonus',
        label: 'Bonus',
        description: 'Bonus points to add',
        type: ScriptParameterType.number,
        defaultValue: 100,
      ),
      ScriptTemplateParameter(
        name: 'max',
        label: 'Maximum Score',
        description: 'Maximum allowed score',
        type: ScriptParameterType.number,
        defaultValue: 9999,
      ),
      ScriptTemplateParameter(
        name: 'result',
        label: 'Result Variable',
        description: 'Variable to store the final score',
        type: ScriptParameterType.variable,
        defaultValue: 'finalScore',
      ),
    ],
  );

  /// Get templates by category
  static List<ScriptTemplate> getByCategory(ScriptTemplateCategory category) {
    return all.where((t) => t.category == category).toList();
  }

  /// Get a template by ID
  static ScriptTemplate? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
