/// Debug events for VN Runtime
/// 
/// Events emitted by the debug API for monitoring engine state.

import '../engine/vn_engine_state.dart';

/// Base class for debug events
abstract class VNDebugEvent {
  /// Timestamp when the event occurred
  final DateTime timestamp;

  VNDebugEvent() : timestamp = DateTime.now();

  Map<String, dynamic> toJson();
}

/// Event emitted when the engine state changes
class StateChangeEvent extends VNDebugEvent {
  /// Previous state
  final VNPlaybackState previousState;
  
  /// New state
  final VNPlaybackState newState;
  
  /// Reason for the state change
  final String? reason;

  StateChangeEvent({
    required this.previousState,
    required this.newState,
    this.reason,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'stateChange',
        'timestamp': timestamp.toIso8601String(),
        'previousState': previousState.name,
        'newState': newState.name,
        if (reason != null) 'reason': reason,
      };
}

/// Event emitted when moving to a new node
class NodeEnterEvent extends VNDebugEvent {
  /// Chapter ID
  final String chapterId;
  
  /// Node ID
  final String nodeId;
  
  /// Node type
  final String nodeType;

  NodeEnterEvent({
    required this.chapterId,
    required this.nodeId,
    required this.nodeType,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'nodeEnter',
        'timestamp': timestamp.toIso8601String(),
        'chapterId': chapterId,
        'nodeId': nodeId,
        'nodeType': nodeType,
      };
}

/// Event emitted when exiting a node
class NodeExitEvent extends VNDebugEvent {
  /// Chapter ID
  final String chapterId;
  
  /// Node ID
  final String nodeId;
  
  /// Next node ID (if any)
  final String? nextNodeId;

  NodeExitEvent({
    required this.chapterId,
    required this.nodeId,
    this.nextNodeId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'nodeExit',
        'timestamp': timestamp.toIso8601String(),
        'chapterId': chapterId,
        'nodeId': nodeId,
        if (nextNodeId != null) 'nextNodeId': nextNodeId,
      };
}

/// Event emitted when a variable changes
class VariableChangeEvent extends VNDebugEvent {
  /// Variable name
  final String variableName;
  
  /// Previous value
  final dynamic previousValue;
  
  /// New value
  final dynamic newValue;
  
  /// Operation that caused the change
  final String? operation;

  VariableChangeEvent({
    required this.variableName,
    this.previousValue,
    required this.newValue,
    this.operation,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'variableChange',
        'timestamp': timestamp.toIso8601String(),
        'variableName': variableName,
        'previousValue': previousValue,
        'newValue': newValue,
        if (operation != null) 'operation': operation,
      };
}

/// Event emitted when a choice is made
class ChoiceSelectedEvent extends VNDebugEvent {
  /// Node ID of the choice node
  final String nodeId;
  
  /// Selected option index
  final int optionIndex;
  
  /// Selected option text
  final String optionText;
  
  /// Target node ID
  final String? targetNodeId;

  ChoiceSelectedEvent({
    required this.nodeId,
    required this.optionIndex,
    required this.optionText,
    this.targetNodeId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'choiceSelected',
        'timestamp': timestamp.toIso8601String(),
        'nodeId': nodeId,
        'optionIndex': optionIndex,
        'optionText': optionText,
        if (targetNodeId != null) 'targetNodeId': targetNodeId,
      };
}

/// Event emitted when a condition is evaluated
class ConditionEvaluatedEvent extends VNDebugEvent {
  /// Node ID of the condition node
  final String nodeId;
  
  /// Condition expression
  final String expression;
  
  /// Evaluation result
  final bool result;
  
  /// Variables used in evaluation
  final Map<String, dynamic> usedVariables;

  ConditionEvaluatedEvent({
    required this.nodeId,
    required this.expression,
    required this.result,
    this.usedVariables = const {},
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'conditionEvaluated',
        'timestamp': timestamp.toIso8601String(),
        'nodeId': nodeId,
        'expression': expression,
        'result': result,
        'usedVariables': usedVariables,
      };
}

/// Event emitted when a breakpoint is hit
class BreakpointHitEvent extends VNDebugEvent {
  /// Node ID where breakpoint was hit
  final String nodeId;
  
  /// Chapter ID
  final String chapterId;

  BreakpointHitEvent({
    required this.nodeId,
    required this.chapterId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'breakpointHit',
        'timestamp': timestamp.toIso8601String(),
        'nodeId': nodeId,
        'chapterId': chapterId,
      };
}

/// Event emitted when an error occurs
class ErrorEvent extends VNDebugEvent {
  /// Error message
  final String message;
  
  /// Error code
  final String? code;
  
  /// Related node ID
  final String? nodeId;
  
  /// Stack trace
  final String? stackTrace;

  ErrorEvent({
    required this.message,
    this.code,
    this.nodeId,
    this.stackTrace,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error',
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        if (code != null) 'code': code,
        if (nodeId != null) 'nodeId': nodeId,
        if (stackTrace != null) 'stackTrace': stackTrace,
      };
}

/// Event emitted when chapter changes
class ChapterChangeEvent extends VNDebugEvent {
  /// Previous chapter ID
  final String? previousChapterId;
  
  /// New chapter ID
  final String newChapterId;

  ChapterChangeEvent({
    this.previousChapterId,
    required this.newChapterId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'chapterChange',
        'timestamp': timestamp.toIso8601String(),
        if (previousChapterId != null) 'previousChapterId': previousChapterId,
        'newChapterId': newChapterId,
      };
}

/// Event emitted when dialogue advances
class DialogueAdvanceEvent extends VNDebugEvent {
  /// Node ID
  final String nodeId;
  
  /// Dialogue index
  final int dialogueIndex;
  
  /// Speaker ID
  final String? speakerId;
  
  /// Dialogue text
  final String text;

  DialogueAdvanceEvent({
    required this.nodeId,
    required this.dialogueIndex,
    this.speakerId,
    required this.text,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dialogueAdvance',
        'timestamp': timestamp.toIso8601String(),
        'nodeId': nodeId,
        'dialogueIndex': dialogueIndex,
        if (speakerId != null) 'speakerId': speakerId,
        'text': text,
      };
}
