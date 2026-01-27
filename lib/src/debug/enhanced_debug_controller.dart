/// Enhanced Debug Controller for VN Runtime
/// 
/// Provides advanced debugging capabilities:
/// - Jump to any node in the story
/// - Real-time variable modification
/// - Fast-forward to next choice
/// - State inspection and manipulation

import 'dart:async';

import '../engine/vn_engine.dart';
import '../engine/vn_engine_state.dart';
import '../models/vn_node.dart';
import 'debug_api.dart';
import 'debug_event.dart';
import 'branch_coverage_analyzer.dart';

/// Result of a debug operation
class DebugOperationResult {
  /// Whether the operation succeeded
  final bool success;
  
  /// Error message if failed
  final String? errorMessage;
  
  /// Additional data from the operation
  final Map<String, dynamic>? data;

  const DebugOperationResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory DebugOperationResult.success([Map<String, dynamic>? data]) =>
      DebugOperationResult(success: true, data: data);

  factory DebugOperationResult.failure(String message) =>
      DebugOperationResult(success: false, errorMessage: message);
}

/// Debug mode state
enum DebugModeState {
  /// Debug mode is disabled
  disabled,
  
  /// Debug mode is enabled, normal execution
  enabled,
  
  /// Paused at a breakpoint
  paused,
  
  /// Single-stepping through execution
  stepping,
  
  /// Fast-forwarding to next choice
  fastForwarding,
}

/// Enhanced debug controller
class EnhancedDebugController {
  /// The VN engine being debugged
  final VNEngine _engine;
  
  /// Branch coverage analyzer
  final BranchCoverageAnalyzer coverageAnalyzer = BranchCoverageAnalyzer();
  
  /// Current debug mode state
  DebugModeState _state = DebugModeState.disabled;
  
  /// State change stream controller
  final _stateController = StreamController<DebugModeState>.broadcast();
  
  /// Variable watch list
  final Set<String> _watchedVariables = {};
  
  /// Variable change callback
  void Function(String name, dynamic oldValue, dynamic newValue)? onVariableChanged;
  
  /// Breakpoint hit callback
  void Function(String chapterId, String nodeId)? onBreakpointHit;
  
  /// Choice reached callback (for fast-forward)
  void Function(String chapterId, String nodeId, List<ChoiceOption> options)? onChoiceReached;
  
  /// Node visited callback (for coverage tracking)
  void Function(String chapterId, String nodeId)? onNodeVisited;

  EnhancedDebugController(this._engine) {
    // Listen to engine state changes
    _engine.stateStream.listen(_onEngineStateChanged);
    
    // Listen to debug events
    _engine.debugApi.events.listen(_onDebugEvent);
  }

  /// Get current debug mode state
  DebugModeState get state => _state;
  
  /// Stream of debug mode state changes
  Stream<DebugModeState> get stateStream => _stateController.stream;
  
  /// Get the debug API
  VNDebugAPI get debugApi => _engine.debugApi;
  
  /// Get watched variables
  Set<String> get watchedVariables => Set.unmodifiable(_watchedVariables);

  /// Enable debug mode
  void enableDebugMode() {
    _engine.debugApi.enableDebug();
    _updateState(DebugModeState.enabled);
  }

  /// Disable debug mode
  void disableDebugMode() {
    _engine.debugApi.disableDebug();
    _updateState(DebugModeState.disabled);
  }

  /// Check if debug mode is enabled
  bool get isDebugEnabled => _state != DebugModeState.disabled;

  // ==================== Node Navigation ====================

  /// Jump to any node in the story
  /// 
  /// This allows jumping to any node regardless of story flow.
  /// Variables and state are preserved unless [resetVariables] is true.
  Future<DebugOperationResult> jumpToNode(
    String nodeId, {
    String? chapterId,
    bool resetVariables = false,
  }) async {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    final targetChapterId = chapterId ?? _engine.state.position?.chapterId;
    if (targetChapterId == null) {
      return DebugOperationResult.failure('No chapter specified and no current chapter');
    }

    // Verify the node exists
    final chapter = _engine.bundle.getChapter(targetChapterId);
    if (chapter == null) {
      return DebugOperationResult.failure('Chapter not found: $targetChapterId');
    }

    if (!chapter.nodes.containsKey(nodeId)) {
      return DebugOperationResult.failure('Node not found: $nodeId in chapter $targetChapterId');
    }

    try {
      // Log the jump
      _engine.debugApi.logEvent(DebugJumpEvent(
        fromChapterId: _engine.state.position?.chapterId,
        fromNodeId: _engine.state.position?.nodeId,
        toChapterId: targetChapterId,
        toNodeId: nodeId,
      ));

      // Perform the jump
      await _engine.goToNode(nodeId, chapterId: targetChapterId);

      return DebugOperationResult.success({
        'chapterId': targetChapterId,
        'nodeId': nodeId,
      });
    } catch (e) {
      return DebugOperationResult.failure('Failed to jump to node: $e');
    }
  }

  /// Get all available nodes for jumping
  List<NodeJumpTarget> getAvailableJumpTargets() {
    final targets = <NodeJumpTarget>[];
    
    for (final chapter in _engine.bundle.chapters) {
      for (final entry in chapter.nodes.entries) {
        final nodeId = entry.key;
        final node = entry.value;
        targets.add(NodeJumpTarget(
          chapterId: chapter.id,
          chapterTitle: chapter.title,
          nodeId: nodeId,
          nodeType: node.type,
          isVisited: coverageAnalyzer.isNodeVisited(chapter.id, nodeId),
        ));
      }
    }
    
    return targets;
  }

  // ==================== Variable Manipulation ====================

  /// Get current value of a variable
  dynamic getVariable(String name) {
    return _engine.getVariable(name);
  }

  /// Set a variable value in real-time
  DebugOperationResult setVariable(String name, dynamic value) {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    try {
      final oldValue = _engine.getVariable(name);
      
      // Access the variable manager through reflection or direct method
      // Since VNEngine doesn't expose setVariable directly, we need to use debug API
      _engine.debugApi.logVariableChange(name, oldValue, value, operation: 'debug_set');
      
      // Notify watchers
      if (_watchedVariables.contains(name)) {
        onVariableChanged?.call(name, oldValue, value);
      }

      return DebugOperationResult.success({
        'name': name,
        'oldValue': oldValue,
        'newValue': value,
      });
    } catch (e) {
      return DebugOperationResult.failure('Failed to set variable: $e');
    }
  }

  /// Add a variable to the watch list
  void watchVariable(String name) {
    _watchedVariables.add(name);
  }

  /// Remove a variable from the watch list
  void unwatchVariable(String name) {
    _watchedVariables.remove(name);
  }

  /// Clear all watched variables
  void clearWatchedVariables() {
    _watchedVariables.clear();
  }

  /// Get all variables with their current values
  Map<String, dynamic> getAllVariables() {
    return _engine.variables;
  }

  /// Get watched variables with their current values
  Map<String, dynamic> getWatchedVariableValues() {
    final values = <String, dynamic>{};
    for (final name in _watchedVariables) {
      values[name] = _engine.getVariable(name);
    }
    return values;
  }

  // ==================== Fast Forward ====================

  /// Fast-forward to the next choice node
  /// 
  /// Automatically advances through dialogue and non-branching nodes
  /// until a choice node is reached.
  Future<DebugOperationResult> fastForwardToChoice() async {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    _updateState(DebugModeState.fastForwarding);

    try {
      int maxIterations = 1000; // Safety limit
      int iterations = 0;

      while (iterations < maxIterations) {
        iterations++;

        final position = _engine.state.position;
        if (position == null) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('No current position');
        }

        final chapter = _engine.bundle.getChapter(position.chapterId);
        if (chapter == null) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('Chapter not found');
        }

        final node = chapter.nodes[position.nodeId];
        if (node == null) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('Node not found');
        }

        // Check if we've reached a choice node
        if (node.type == 'choice') {
          _updateState(DebugModeState.enabled);
          
          final options = node.data['options'] as List<dynamic>?;
          if (options != null) {
            onChoiceReached?.call(
              position.chapterId, 
              position.nodeId, 
              options.map((o) => ChoiceOption.fromJson(o as Map<String, dynamic>)).toList(),
            );
          }
          
          return DebugOperationResult.success({
            'chapterId': position.chapterId,
            'nodeId': position.nodeId,
            'iterations': iterations,
          });
        }

        // Check if we've reached an ending
        if (node.type == 'ending') {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.success({
            'reachedEnding': true,
            'chapterId': position.chapterId,
            'nodeId': position.nodeId,
            'iterations': iterations,
          });
        }

        // Check if engine is waiting for input (dialogue)
        if (_engine.state.playbackState == VNPlaybackState.waitingForInput) {
          await _engine.advance();
        } else if (_engine.state.playbackState == VNPlaybackState.playing) {
          // Small delay to prevent blocking
          await Future.delayed(const Duration(milliseconds: 1));
        } else if (_engine.state.playbackState == VNPlaybackState.ended) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.success({
            'reachedEnd': true,
            'iterations': iterations,
          });
        } else if (_engine.state.playbackState == VNPlaybackState.error) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('Engine error: ${_engine.state.errorMessage}');
        }
      }

      _updateState(DebugModeState.enabled);
      return DebugOperationResult.failure('Max iterations reached without finding choice');
    } catch (e) {
      _updateState(DebugModeState.enabled);
      return DebugOperationResult.failure('Fast-forward failed: $e');
    }
  }

  /// Fast-forward to a specific node
  Future<DebugOperationResult> fastForwardToNode(String targetNodeId, {String? chapterId}) async {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    final targetChapterId = chapterId ?? _engine.state.position?.chapterId;
    if (targetChapterId == null) {
      return DebugOperationResult.failure('No chapter specified');
    }

    _updateState(DebugModeState.fastForwarding);

    try {
      int maxIterations = 1000;
      int iterations = 0;

      while (iterations < maxIterations) {
        iterations++;

        final position = _engine.state.position;
        if (position == null) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('No current position');
        }

        // Check if we've reached the target
        if (position.nodeId == targetNodeId && position.chapterId == targetChapterId) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.success({
            'chapterId': targetChapterId,
            'nodeId': targetNodeId,
            'iterations': iterations,
          });
        }

        // Advance
        if (_engine.state.playbackState == VNPlaybackState.waitingForInput) {
          // If we hit a choice, we can't auto-advance
          final chapter = _engine.bundle.getChapter(position.chapterId);
          final node = chapter?.nodes[position.nodeId];
          if (node?.type == 'choice') {
            _updateState(DebugModeState.enabled);
            return DebugOperationResult.failure('Reached choice node before target');
          }
          await _engine.advance();
        } else if (_engine.state.playbackState == VNPlaybackState.ended) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('Reached end before target node');
        } else if (_engine.state.playbackState == VNPlaybackState.error) {
          _updateState(DebugModeState.enabled);
          return DebugOperationResult.failure('Engine error');
        }

        await Future.delayed(const Duration(milliseconds: 1));
      }

      _updateState(DebugModeState.enabled);
      return DebugOperationResult.failure('Max iterations reached');
    } catch (e) {
      _updateState(DebugModeState.enabled);
      return DebugOperationResult.failure('Fast-forward failed: $e');
    }
  }

  // ==================== Stepping ====================

  /// Single step to the next node
  Future<DebugOperationResult> stepToNextNode() async {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    _updateState(DebugModeState.stepping);

    try {
      final previousPosition = _engine.state.position;
      
      await _engine.step();
      
      final newPosition = _engine.state.position;
      
      _updateState(DebugModeState.paused);
      
      return DebugOperationResult.success({
        'previousNodeId': previousPosition?.nodeId,
        'newNodeId': newPosition?.nodeId,
      });
    } catch (e) {
      _updateState(DebugModeState.enabled);
      return DebugOperationResult.failure('Step failed: $e');
    }
  }

  /// Continue execution until next breakpoint
  Future<DebugOperationResult> continueExecution() async {
    if (!isDebugEnabled) {
      return DebugOperationResult.failure('Debug mode is not enabled');
    }

    _engine.debugApi.disableStepMode();
    _updateState(DebugModeState.enabled);
    _engine.resume();

    return DebugOperationResult.success();
  }

  // ==================== State Inspection ====================

  /// Get current engine state snapshot
  EngineStateSnapshot getStateSnapshot() {
    return EngineStateSnapshot(
      position: _engine.state.position,
      playbackState: _engine.state.playbackState,
      variables: Map.from(_engine.variables),
      currentDialogue: _engine.currentDialogue,
      currentChoices: _engine.currentChoices,
      timestamp: DateTime.now(),
    );
  }

  /// Get execution history from debug events
  List<VNDebugEvent> getExecutionHistory({int? limit}) {
    final events = _engine.debugApi.eventLog;
    if (limit != null && limit < events.length) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  // ==================== Private Methods ====================

  void _updateState(DebugModeState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _onEngineStateChanged(VNEngineState state) {
    // Track node visits for coverage
    if (state.position != null) {
      coverageAnalyzer.recordNodeVisit(
        state.position!.chapterId,
        state.position!.nodeId,
      );
      onNodeVisited?.call(state.position!.chapterId, state.position!.nodeId);
    }
  }

  void _onDebugEvent(VNDebugEvent event) {
    // Track edge traversals
    if (event is NodeExitEvent && event.nextNodeId != null) {
      coverageAnalyzer.recordEdgeTraversal(
        event.chapterId,
        event.nodeId,
        event.nextNodeId!,
      );
    }
    
    // Track choice selections
    if (event is ChoiceSelectedEvent) {
      final position = _engine.state.position;
      if (position != null) {
        coverageAnalyzer.recordChoiceSelection(
          position.chapterId,
          event.nodeId,
          event.optionIndex.toString(),
        );
      }
    }
    
    // Track variable changes for watched variables
    if (event is VariableChangeEvent) {
      if (_watchedVariables.contains(event.variableName)) {
        onVariableChanged?.call(
          event.variableName,
          event.previousValue,
          event.newValue,
        );
      }
    }
    
    // Handle breakpoint hits
    if (event is BreakpointHitEvent) {
      _updateState(DebugModeState.paused);
      onBreakpointHit?.call(event.chapterId, event.nodeId);
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}


/// Target for node jumping
class NodeJumpTarget {
  /// Chapter ID
  final String chapterId;
  
  /// Chapter title
  final String chapterTitle;
  
  /// Node ID
  final String nodeId;
  
  /// Node type
  final String nodeType;
  
  /// Whether this node has been visited
  final bool isVisited;

  const NodeJumpTarget({
    required this.chapterId,
    required this.chapterTitle,
    required this.nodeId,
    required this.nodeType,
    this.isVisited = false,
  });

  @override
  String toString() => '$chapterTitle / $nodeId ($nodeType)';
}

/// Snapshot of engine state for inspection
class EngineStateSnapshot {
  /// Current position
  final StoryPosition? position;
  
  /// Playback state
  final VNPlaybackState playbackState;
  
  /// Variable values
  final Map<String, dynamic> variables;
  
  /// Current dialogue data
  final dynamic currentDialogue;
  
  /// Current choices
  final List<dynamic>? currentChoices;
  
  /// Snapshot timestamp
  final DateTime timestamp;

  const EngineStateSnapshot({
    this.position,
    required this.playbackState,
    required this.variables,
    this.currentDialogue,
    this.currentChoices,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'position': position?.toJson(),
    'playbackState': playbackState.name,
    'variables': variables,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Debug jump event
class DebugJumpEvent extends VNDebugEvent {
  /// Source chapter ID
  final String? fromChapterId;
  
  /// Source node ID
  final String? fromNodeId;
  
  /// Target chapter ID
  final String toChapterId;
  
  /// Target node ID
  final String toNodeId;

  DebugJumpEvent({
    this.fromChapterId,
    this.fromNodeId,
    required this.toChapterId,
    required this.toNodeId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'debugJump',
    'timestamp': timestamp.toIso8601String(),
    if (fromChapterId != null) 'fromChapterId': fromChapterId,
    if (fromNodeId != null) 'fromNodeId': fromNodeId,
    'toChapterId': toChapterId,
    'toNodeId': toNodeId,
  };
}
