/// New Game+ Configuration Model
///
/// Defines configuration for New Game+ mode including variable carryover.
/// Requirements: 8.4, 8.5

/// New Game+ configuration
class NewGamePlusConfig {
  /// Set of variable names that carry over to New Game+
  final Set<String> carryOverVariables;

  /// Whether to carry over unlock progress (CGs, BGMs, etc.)
  final bool carryOverUnlocks;

  /// Whether to carry over read state (dialogue read markers)
  final bool carryOverReadState;

  /// Whether to carry over affection values
  final bool carryOverAffection;

  /// Whether to carry over statistics
  final bool carryOverStatistics;

  /// Custom initial values for New Game+ (overrides defaults)
  final Map<String, dynamic> customInitialValues;

  /// Whether New Game+ is enabled for this project
  final bool enabled;

  /// Minimum number of endings required to unlock New Game+
  final int requiredEndingsForUnlock;

  /// Whether first playthrough completion is required
  final bool requireFirstPlaythrough;

  const NewGamePlusConfig({
    this.carryOverVariables = const {},
    this.carryOverUnlocks = true,
    this.carryOverReadState = true,
    this.carryOverAffection = false,
    this.carryOverStatistics = false,
    this.customInitialValues = const {},
    this.enabled = true,
    this.requiredEndingsForUnlock = 0,
    this.requireFirstPlaythrough = true,
  });

  /// Default configuration with common settings
  factory NewGamePlusConfig.defaults() {
    return const NewGamePlusConfig(
      carryOverUnlocks: true,
      carryOverReadState: true,
      carryOverAffection: false,
      carryOverStatistics: false,
      enabled: true,
      requireFirstPlaythrough: true,
    );
  }

  /// Configuration that carries over everything
  factory NewGamePlusConfig.carryAll({
    Set<String> carryOverVariables = const {},
  }) {
    return NewGamePlusConfig(
      carryOverVariables: carryOverVariables,
      carryOverUnlocks: true,
      carryOverReadState: true,
      carryOverAffection: true,
      carryOverStatistics: true,
      enabled: true,
      requireFirstPlaythrough: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'carryOverVariables': carryOverVariables.toList(),
        'carryOverUnlocks': carryOverUnlocks,
        'carryOverReadState': carryOverReadState,
        'carryOverAffection': carryOverAffection,
        'carryOverStatistics': carryOverStatistics,
        'customInitialValues': customInitialValues,
        'enabled': enabled,
        'requiredEndingsForUnlock': requiredEndingsForUnlock,
        'requireFirstPlaythrough': requireFirstPlaythrough,
      };

  factory NewGamePlusConfig.fromJson(Map<String, dynamic> json) {
    return NewGamePlusConfig(
      carryOverVariables:
          Set<String>.from(json['carryOverVariables'] as List? ?? []),
      carryOverUnlocks: json['carryOverUnlocks'] as bool? ?? true,
      carryOverReadState: json['carryOverReadState'] as bool? ?? true,
      carryOverAffection: json['carryOverAffection'] as bool? ?? false,
      carryOverStatistics: json['carryOverStatistics'] as bool? ?? false,
      customInitialValues: Map<String, dynamic>.from(
          json['customInitialValues'] as Map? ?? {}),
      enabled: json['enabled'] as bool? ?? true,
      requiredEndingsForUnlock: json['requiredEndingsForUnlock'] as int? ?? 0,
      requireFirstPlaythrough: json['requireFirstPlaythrough'] as bool? ?? true,
    );
  }

  NewGamePlusConfig copyWith({
    Set<String>? carryOverVariables,
    bool? carryOverUnlocks,
    bool? carryOverReadState,
    bool? carryOverAffection,
    bool? carryOverStatistics,
    Map<String, dynamic>? customInitialValues,
    bool? enabled,
    int? requiredEndingsForUnlock,
    bool? requireFirstPlaythrough,
  }) {
    return NewGamePlusConfig(
      carryOverVariables: carryOverVariables ?? Set.from(this.carryOverVariables),
      carryOverUnlocks: carryOverUnlocks ?? this.carryOverUnlocks,
      carryOverReadState: carryOverReadState ?? this.carryOverReadState,
      carryOverAffection: carryOverAffection ?? this.carryOverAffection,
      carryOverStatistics: carryOverStatistics ?? this.carryOverStatistics,
      customInitialValues:
          customInitialValues ?? Map.from(this.customInitialValues),
      enabled: enabled ?? this.enabled,
      requiredEndingsForUnlock:
          requiredEndingsForUnlock ?? this.requiredEndingsForUnlock,
      requireFirstPlaythrough:
          requireFirstPlaythrough ?? this.requireFirstPlaythrough,
    );
  }

  /// Add a variable to the carryover list
  NewGamePlusConfig addCarryOverVariable(String variableName) {
    return copyWith(
      carryOverVariables: Set.from(carryOverVariables)..add(variableName),
    );
  }

  /// Remove a variable from the carryover list
  NewGamePlusConfig removeCarryOverVariable(String variableName) {
    return copyWith(
      carryOverVariables: Set.from(carryOverVariables)..remove(variableName),
    );
  }

  /// Check if a variable should be carried over
  bool shouldCarryOver(String variableName) {
    return carryOverVariables.contains(variableName);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewGamePlusConfig &&
          runtimeType == other.runtimeType &&
          _setEquals(carryOverVariables, other.carryOverVariables) &&
          carryOverUnlocks == other.carryOverUnlocks &&
          carryOverReadState == other.carryOverReadState &&
          carryOverAffection == other.carryOverAffection &&
          carryOverStatistics == other.carryOverStatistics &&
          enabled == other.enabled &&
          requiredEndingsForUnlock == other.requiredEndingsForUnlock &&
          requireFirstPlaythrough == other.requireFirstPlaythrough;

  @override
  int get hashCode => Object.hash(
        carryOverVariables.length,
        carryOverUnlocks,
        carryOverReadState,
        carryOverAffection,
        carryOverStatistics,
        enabled,
        requiredEndingsForUnlock,
        requireFirstPlaythrough,
      );
}

/// New Game+ state containing carried over data
class NewGamePlusState {
  /// Variables carried over from previous playthrough
  final Map<String, dynamic> carryOverVariables;

  /// Read dialogue IDs carried over (if enabled)
  final Set<String> carryOverReadState;

  /// Affection values carried over (if enabled)
  final Map<String, int> carryOverAffection;

  /// Whether this is a New Game+ playthrough
  final bool isNewGamePlus;

  /// Number of times New Game+ has been started
  final int newGamePlusCount;

  /// Timestamp when New Game+ was started
  final DateTime? startedAt;

  const NewGamePlusState({
    this.carryOverVariables = const {},
    this.carryOverReadState = const {},
    this.carryOverAffection = const {},
    this.isNewGamePlus = false,
    this.newGamePlusCount = 0,
    this.startedAt,
  });

  /// Create an empty state (not New Game+)
  factory NewGamePlusState.empty() {
    return const NewGamePlusState();
  }

  /// Create a New Game+ state from completed save data
  factory NewGamePlusState.fromCompletedSave({
    required Map<String, dynamic> variables,
    required Set<String> readDialogueIds,
    required Map<String, int> affectionValues,
    required NewGamePlusConfig config,
    int previousCount = 0,
  }) {
    // Filter variables based on config
    final carryOverVars = <String, dynamic>{};
    for (final varName in config.carryOverVariables) {
      if (variables.containsKey(varName)) {
        carryOverVars[varName] = variables[varName];
      }
    }

    // Apply custom initial values
    for (final entry in config.customInitialValues.entries) {
      carryOverVars[entry.key] = entry.value;
    }

    return NewGamePlusState(
      carryOverVariables: carryOverVars,
      carryOverReadState:
          config.carryOverReadState ? Set.from(readDialogueIds) : const {},
      carryOverAffection:
          config.carryOverAffection ? Map.from(affectionValues) : const {},
      isNewGamePlus: true,
      newGamePlusCount: previousCount + 1,
      startedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'carryOverVariables': carryOverVariables,
        'carryOverReadState': carryOverReadState.toList(),
        'carryOverAffection': carryOverAffection,
        'isNewGamePlus': isNewGamePlus,
        'newGamePlusCount': newGamePlusCount,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      };

  factory NewGamePlusState.fromJson(Map<String, dynamic> json) {
    return NewGamePlusState(
      carryOverVariables:
          Map<String, dynamic>.from(json['carryOverVariables'] as Map? ?? {}),
      carryOverReadState:
          Set<String>.from(json['carryOverReadState'] as List? ?? []),
      carryOverAffection: (json['carryOverAffection'] as Map? ?? {})
          .map((k, v) => MapEntry(k as String, v as int)),
      isNewGamePlus: json['isNewGamePlus'] as bool? ?? false,
      newGamePlusCount: json['newGamePlusCount'] as int? ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
    );
  }

  NewGamePlusState copyWith({
    Map<String, dynamic>? carryOverVariables,
    Set<String>? carryOverReadState,
    Map<String, int>? carryOverAffection,
    bool? isNewGamePlus,
    int? newGamePlusCount,
    DateTime? startedAt,
  }) {
    return NewGamePlusState(
      carryOverVariables:
          carryOverVariables ?? Map.from(this.carryOverVariables),
      carryOverReadState:
          carryOverReadState ?? Set.from(this.carryOverReadState),
      carryOverAffection:
          carryOverAffection ?? Map.from(this.carryOverAffection),
      isNewGamePlus: isNewGamePlus ?? this.isNewGamePlus,
      newGamePlusCount: newGamePlusCount ?? this.newGamePlusCount,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// Get a carried over variable value
  T? getVariable<T>(String name) {
    final value = carryOverVariables[name];
    if (value is T) return value;
    return null;
  }

  /// Check if a dialogue has been read in previous playthrough
  bool wasDialogueRead(String dialogueId) {
    return carryOverReadState.contains(dialogueId);
  }

  /// Get carried over affection value
  int getAffection(String characterId) {
    return carryOverAffection[characterId] ?? 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewGamePlusState &&
          runtimeType == other.runtimeType &&
          isNewGamePlus == other.isNewGamePlus &&
          newGamePlusCount == other.newGamePlusCount;

  @override
  int get hashCode => Object.hash(isNewGamePlus, newGamePlusCount);
}

// Helper function
bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
