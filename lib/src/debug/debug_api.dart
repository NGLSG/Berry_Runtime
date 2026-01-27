/// Debug API for VN Runtime
/// 
/// Provides debugging capabilities for the VN engine including:
/// - Breakpoint management
/// - Single-step execution
/// - State inspection
/// - Event logging

import 'dart:async';

import '../engine/vn_engine_state.dart';
import 'debug_event.dart';

/// Debug API for controlling and inspecting the VN engine
class VNDebugAPI {
  /// Set of breakpoint node IDs
  final Set<String> _breakpoints = {};
  
  /// Whether debug mode is enabled
  bool _debugEnabled = false;
  
  /// Whether single-step mode is active
  bool _stepMode = false;
  
  /// Event log (limited size)
  final List<VNDebugEvent> _eventLog = [];
  
  /// Maximum event log size
  static const int maxEventLogSize = 1000;
  
  /// Event stream controller
  final _eventController = StreamController<VNDebugEvent>.broadcast();
  
  /// Callback when a breakpoint is hit
  void Function(String nodeId)? onBreakpointHit;
  
  /// Callback when step mode should pause
  void Function()? onStepPause;

  /// Stream of debug events
  Stream<VNDebugEvent> get events => _eventController.stream;

  /// Whether debug mode is enabled
  bool get isDebugEnabled => _debugEnabled;

  /// Whether single-step mode is active
  bool get isStepMode => _stepMode;

  /// Get all breakpoints
  Set<String> get breakpoints => Set.unmodifiable(_breakpoints);

  /// Get event log
  List<VNDebugEvent> get eventLog => List.unmodifiable(_eventLog);

  /// Enable debug mode
  void enableDebug() {
    _debugEnabled = true;
  }

  /// Disable debug mode
  void disableDebug() {
    _debugEnabled = false;
    _stepMode = false;
  }

  /// Set a breakpoint on a node
  void setBreakpoint(String nodeId) {
    _breakpoints.add(nodeId);
  }

  /// Remove a breakpoint from a node
  void removeBreakpoint(String nodeId) {
    _breakpoints.remove(nodeId);
  }

  /// Toggle a breakpoint on a node
  bool toggleBreakpoint(String nodeId) {
    if (_breakpoints.contains(nodeId)) {
      _breakpoints.remove(nodeId);
      return false;
    } else {
      _breakpoints.add(nodeId);
      return true;
    }
  }

  /// Clear all breakpoints
  void clearBreakpoints() {
    _breakpoints.clear();
  }

  /// Check if a node has a breakpoint
  bool hasBreakpoint(String nodeId) {
    return _breakpoints.contains(nodeId);
  }

  /// Enable single-step mode
  void enableStepMode() {
    _stepMode = true;
  }

  /// Disable single-step mode
  void disableStepMode() {
    _stepMode = false;
  }

  /// Check if execution should pause at a node
  /// Returns true if a breakpoint is hit or step mode is active
  bool shouldPauseAt(String nodeId) {
    if (!_debugEnabled) return false;
    if (_stepMode) return true;
    return _breakpoints.contains(nodeId);
  }

  /// Log a debug event
  void logEvent(VNDebugEvent event) {
    if (!_debugEnabled) return;
    
    _eventLog.add(event);
    if (_eventLog.length > maxEventLogSize) {
      _eventLog.removeAt(0);
    }
    
    _eventController.add(event);
  }

  /// Log a state change
  void logStateChange(VNPlaybackState previous, VNPlaybackState current, {String? reason}) {
    logEvent(StateChangeEvent(
      previousState: previous,
      newState: current,
      reason: reason,
    ));
  }

  /// Log entering a node
  void logNodeEnter(String chapterId, String nodeId, String nodeType) {
    logEvent(NodeEnterEvent(
      chapterId: chapterId,
      nodeId: nodeId,
      nodeType: nodeType,
    ));
  }

  /// Log exiting a node
  void logNodeExit(String chapterId, String nodeId, {String? nextNodeId}) {
    logEvent(NodeExitEvent(
      chapterId: chapterId,
      nodeId: nodeId,
      nextNodeId: nextNodeId,
    ));
  }

  /// Log a variable change
  void logVariableChange(
    String name,
    dynamic previousValue,
    dynamic newValue, {
    String? operation,
  }) {
    logEvent(VariableChangeEvent(
      variableName: name,
      previousValue: previousValue,
      newValue: newValue,
      operation: operation,
    ));
  }

  /// Log a choice selection
  void logChoiceSelected(
    String nodeId,
    int optionIndex,
    String optionText, {
    String? targetNodeId,
  }) {
    logEvent(ChoiceSelectedEvent(
      nodeId: nodeId,
      optionIndex: optionIndex,
      optionText: optionText,
      targetNodeId: targetNodeId,
    ));
  }

  /// Log a condition evaluation
  void logConditionEvaluated(
    String nodeId,
    String expression,
    bool result, {
    Map<String, dynamic> usedVariables = const {},
  }) {
    logEvent(ConditionEvaluatedEvent(
      nodeId: nodeId,
      expression: expression,
      result: result,
      usedVariables: usedVariables,
    ));
  }

  /// Log a breakpoint hit
  void logBreakpointHit(String nodeId, String chapterId) {
    logEvent(BreakpointHitEvent(
      nodeId: nodeId,
      chapterId: chapterId,
    ));
    onBreakpointHit?.call(nodeId);
  }

  /// Log an error
  void logError(String message, {String? code, String? nodeId, String? stackTrace}) {
    logEvent(ErrorEvent(
      message: message,
      code: code,
      nodeId: nodeId,
      stackTrace: stackTrace,
    ));
  }

  /// Log a chapter change
  void logChapterChange(String newChapterId, {String? previousChapterId}) {
    logEvent(ChapterChangeEvent(
      previousChapterId: previousChapterId,
      newChapterId: newChapterId,
    ));
  }

  /// Log dialogue advance
  void logDialogueAdvance(
    String nodeId,
    int dialogueIndex,
    String text, {
    String? speakerId,
  }) {
    logEvent(DialogueAdvanceEvent(
      nodeId: nodeId,
      dialogueIndex: dialogueIndex,
      speakerId: speakerId,
      text: text,
    ));
  }

  /// Clear the event log
  void clearEventLog() {
    _eventLog.clear();
  }

  /// Get events of a specific type
  List<T> getEventsOfType<T extends VNDebugEvent>() {
    return _eventLog.whereType<T>().toList();
  }

  /// Get events for a specific node
  List<VNDebugEvent> getEventsForNode(String nodeId) {
    return _eventLog.where((e) {
      if (e is NodeEnterEvent) return e.nodeId == nodeId;
      if (e is NodeExitEvent) return e.nodeId == nodeId;
      if (e is ChoiceSelectedEvent) return e.nodeId == nodeId;
      if (e is ConditionEvaluatedEvent) return e.nodeId == nodeId;
      if (e is BreakpointHitEvent) return e.nodeId == nodeId;
      if (e is ErrorEvent) return e.nodeId == nodeId;
      if (e is DialogueAdvanceEvent) return e.nodeId == nodeId;
      return false;
    }).toList();
  }

  /// Export event log as JSON
  List<Map<String, dynamic>> exportEventLog() {
    return _eventLog.map((e) => e.toJson()).toList();
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}
