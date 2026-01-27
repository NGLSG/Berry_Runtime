/// Variable Manager for VN Runtime
/// 
/// Manages story variables with support for different scopes:
/// - Global: Persists across chapters
/// - Chapter: Resets on chapter change
/// - Local: Temporary, within current node

import '../models/vn_variable.dart';
import '../models/vn_node.dart' show VariableOperation;

/// Manages variable state during runtime
class VariableManager {
  /// Variable definitions from the story bundle
  final List<VNVariable> _definitions;
  
  /// Global variables (persist across chapters)
  final Map<String, dynamic> _globalVariables = {};
  
  /// Chapter variables (per chapter)
  final Map<String, Map<String, dynamic>> _chapterVariables = {};
  
  /// Local variables (temporary)
  final Map<String, dynamic> _localVariables = {};
  
  /// Current chapter ID
  String? _currentChapterId;

  VariableManager(this._definitions) {
    _initializeDefaults();
  }

  /// Initialize all variables to their default values
  void _initializeDefaults() {
    for (final def in _definitions) {
      switch (def.scope) {
        case VariableScope.global:
          _globalVariables[def.name] = def.defaultValue;
          break;
        case VariableScope.chapter:
          // Chapter variables are initialized when entering a chapter
          break;
        case VariableScope.local:
          // Local variables are initialized when needed
          break;
      }
    }
  }

  /// Set the current chapter (called on chapter change)
  void setCurrentChapter(String chapterId) {
    if (_currentChapterId == chapterId) return;
    _currentChapterId = chapterId;
    _localVariables.clear();
    
    // Initialize chapter variables if not already done
    if (!_chapterVariables.containsKey(chapterId)) {
      _chapterVariables[chapterId] = {};
      for (final def in _definitions) {
        if (def.scope == VariableScope.chapter) {
          if (def.chapterId == null || def.chapterId == chapterId) {
            _chapterVariables[chapterId]![def.name] = def.defaultValue;
          }
        }
      }
    }
  }

  /// Get the current chapter ID
  String? get currentChapterId => _currentChapterId;

  /// Get a variable value by name
  dynamic getValue(String name) {
    final def = _getDefinition(name);
    if (def == null) {
      // Unknown variable, check all scopes
      if (_localVariables.containsKey(name)) return _localVariables[name];
      if (_currentChapterId != null &&
          _chapterVariables[_currentChapterId]?.containsKey(name) == true) {
        return _chapterVariables[_currentChapterId]![name];
      }
      return _globalVariables[name];
    }

    switch (def.scope) {
      case VariableScope.global:
        return _globalVariables[name];
      case VariableScope.chapter:
        return _chapterVariables[_currentChapterId]?[name] ?? def.defaultValue;
      case VariableScope.local:
        return _localVariables[name] ?? def.defaultValue;
    }
  }

  /// Set a variable value
  void setValue(String name, dynamic value) {
    final def = _getDefinition(name);
    if (def == null) {
      // Unknown variable, store as global
      _globalVariables[name] = value;
      return;
    }

    switch (def.scope) {
      case VariableScope.global:
        _globalVariables[name] = value;
        break;
      case VariableScope.chapter:
        if (_currentChapterId != null) {
          _chapterVariables[_currentChapterId]![name] = value;
        }
        break;
      case VariableScope.local:
        _localVariables[name] = value;
        break;
    }
  }

  /// Apply a variable operation
  void applyOperation(String name, VariableOperation operation, dynamic operand) {
    final currentValue = getValue(name);
    final def = _getDefinition(name);
    final type = def?.type ?? _inferType(currentValue);

    dynamic newValue;
    switch (operation) {
      case VariableOperation.set:
        newValue = operand;
        break;
      case VariableOperation.add:
        if (type == VariableType.number && currentValue is num && operand is num) {
          newValue = currentValue + operand;
        } else if (type == VariableType.string) {
          newValue = '${currentValue ?? ''}$operand';
        } else {
          newValue = currentValue;
        }
        break;
      case VariableOperation.subtract:
        if (type == VariableType.number && currentValue is num && operand is num) {
          newValue = currentValue - operand;
        } else {
          newValue = currentValue;
        }
        break;
      case VariableOperation.toggle:
        if (type == VariableType.boolean && currentValue is bool) {
          newValue = !currentValue;
        } else {
          newValue = currentValue;
        }
        break;
    }

    setValue(name, newValue);
  }

  /// Get all current variable values (for debugging/saving)
  Map<String, dynamic> getAllVariables() {
    final result = <String, dynamic>{};
    
    // Add global variables
    result.addAll(_globalVariables);
    
    // Add current chapter variables
    if (_currentChapterId != null) {
      result.addAll(_chapterVariables[_currentChapterId] ?? {});
    }
    
    // Add local variables
    result.addAll(_localVariables);
    
    return result;
  }

  /// Get only global variables (for saving)
  Map<String, dynamic> getGlobalVariables() {
    return Map.from(_globalVariables);
  }

  /// Get chapter variables for a specific chapter
  Map<String, dynamic> getChapterVariables(String chapterId) {
    return Map.from(_chapterVariables[chapterId] ?? {});
  }

  /// Restore variables from saved state
  void restoreFromSave(Map<String, dynamic> savedState) {
    final global = savedState['global'];
    final chapters = savedState['chapters'];

    if (global != null && global is Map) {
      _globalVariables.clear();
      _globalVariables.addAll(Map<String, dynamic>.from(global));
    }

    if (chapters != null && chapters is Map) {
      _chapterVariables.clear();
      chapters.forEach((key, value) {
        if (value is Map) {
          _chapterVariables[key as String] = Map<String, dynamic>.from(value);
        }
      });
    }
  }

  /// Export variables for saving
  Map<String, dynamic> exportForSave() {
    return {
      'global': Map.from(_globalVariables),
      'chapters': _chapterVariables.map(
        (k, v) => MapEntry(k, Map.from(v)),
      ),
    };
  }

  /// Clear local variables (called on node exit)
  void clearLocalVariables() {
    _localVariables.clear();
  }

  /// Reset chapter variables for a specific chapter
  void resetChapterVariables(String chapterId) {
    _chapterVariables[chapterId] = {};
    for (final def in _definitions) {
      if (def.scope == VariableScope.chapter) {
        if (def.chapterId == null || def.chapterId == chapterId) {
          _chapterVariables[chapterId]![def.name] = def.defaultValue;
        }
      }
    }
  }

  /// Reset all variables to defaults
  void reset() {
    _globalVariables.clear();
    _chapterVariables.clear();
    _localVariables.clear();
    _currentChapterId = null;
    _initializeDefaults();
  }

  VNVariable? _getDefinition(String name) {
    try {
      return _definitions.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }

  VariableType _inferType(dynamic value) {
    if (value is bool) return VariableType.boolean;
    if (value is num) return VariableType.number;
    return VariableType.string;
  }
}
