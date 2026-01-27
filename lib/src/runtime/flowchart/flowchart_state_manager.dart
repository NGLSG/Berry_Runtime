/// Flowchart State Manager
///
/// Manages the visited state of flowchart nodes and edges.
/// Tracks player progress through the story graph.
/// Requirements: 4.3

import 'dart:async';
import 'flowchart_data.dart';
import 'flowchart_node.dart';

/// Event emitted when flowchart state changes
abstract class FlowchartStateEvent {
  final DateTime timestamp;
  FlowchartStateEvent() : timestamp = DateTime.now();
}

/// Event emitted when a node is visited
class NodeVisitedEvent extends FlowchartStateEvent {
  final String nodeId;
  final bool isFirstVisit;

  NodeVisitedEvent({
    required this.nodeId,
    required this.isFirstVisit,
  });
}

/// Event emitted when an edge is traversed
class EdgeVisitedEvent extends FlowchartStateEvent {
  final String fromNodeId;
  final String toNodeId;
  final bool isFirstVisit;

  EdgeVisitedEvent({
    required this.fromNodeId,
    required this.toNodeId,
    required this.isFirstVisit,
  });
}

/// Status of a flowchart node
class FlowchartNodeStatus {
  final FlowchartNode node;
  final bool isVisited;
  final int visitCount;
  final DateTime? firstVisitTime;
  final DateTime? lastVisitTime;

  const FlowchartNodeStatus({
    required this.node,
    required this.isVisited,
    this.visitCount = 0,
    this.firstVisitTime,
    this.lastVisitTime,
  });
}

/// Status of a flowchart edge
class FlowchartEdgeStatus {
  final String fromNodeId;
  final String toNodeId;
  final bool isVisited;
  final int visitCount;

  const FlowchartEdgeStatus({
    required this.fromNodeId,
    required this.toNodeId,
    required this.isVisited,
    this.visitCount = 0,
  });

  String get edgeKey => '$fromNodeId->$toNodeId';
}

/// Manages flowchart visited state
class FlowchartStateManager {
  /// Set of visited node IDs
  final Set<String> _visitedNodeIds;

  /// Set of visited edges (format: "fromId->toId")
  final Set<String> _visitedEdges;

  /// Visit counts per node
  final Map<String, int> _nodeVisitCounts;

  /// Visit counts per edge
  final Map<String, int> _edgeVisitCounts;

  /// First visit timestamps
  final Map<String, DateTime> _firstVisitTimes;

  /// Last visit timestamps
  final Map<String, DateTime> _lastVisitTimes;

  /// Event stream controller
  final StreamController<FlowchartStateEvent> _eventController =
      StreamController<FlowchartStateEvent>.broadcast();

  /// Stream of state change events
  Stream<FlowchartStateEvent> get events => _eventController.stream;

  FlowchartStateManager({
    Set<String>? visitedNodeIds,
    Set<String>? visitedEdges,
    Map<String, int>? nodeVisitCounts,
    Map<String, int>? edgeVisitCounts,
    Map<String, DateTime>? firstVisitTimes,
    Map<String, DateTime>? lastVisitTimes,
  })  : _visitedNodeIds = visitedNodeIds ?? {},
        _visitedEdges = visitedEdges ?? {},
        _nodeVisitCounts = nodeVisitCounts ?? {},
        _edgeVisitCounts = edgeVisitCounts ?? {},
        _firstVisitTimes = firstVisitTimes ?? {},
        _lastVisitTimes = lastVisitTimes ?? {};

  // ============================================================
  // Node Visit Tracking
  // ============================================================

  /// Record visiting a node
  void recordNodeVisit(String nodeId) {
    final isFirstVisit = !_visitedNodeIds.contains(nodeId);
    final now = DateTime.now();

    _visitedNodeIds.add(nodeId);
    _nodeVisitCounts[nodeId] = (_nodeVisitCounts[nodeId] ?? 0) + 1;
    _lastVisitTimes[nodeId] = now;

    if (isFirstVisit) {
      _firstVisitTimes[nodeId] = now;
    }

    _eventController.add(NodeVisitedEvent(
      nodeId: nodeId,
      isFirstVisit: isFirstVisit,
    ));
  }

  /// Check if a node has been visited
  bool isNodeVisited(String nodeId) {
    return _visitedNodeIds.contains(nodeId);
  }

  /// Get visit count for a node
  int getNodeVisitCount(String nodeId) {
    return _nodeVisitCounts[nodeId] ?? 0;
  }

  /// Get first visit time for a node
  DateTime? getNodeFirstVisitTime(String nodeId) {
    return _firstVisitTimes[nodeId];
  }

  /// Get last visit time for a node
  DateTime? getNodeLastVisitTime(String nodeId) {
    return _lastVisitTimes[nodeId];
  }

  /// Get status for a specific node
  FlowchartNodeStatus getNodeStatus(FlowchartNode node) {
    return FlowchartNodeStatus(
      node: node,
      isVisited: isNodeVisited(node.id),
      visitCount: getNodeVisitCount(node.id),
      firstVisitTime: getNodeFirstVisitTime(node.id),
      lastVisitTime: getNodeLastVisitTime(node.id),
    );
  }

  // ============================================================
  // Edge Visit Tracking
  // ============================================================

  /// Generate edge key from node IDs
  static String _edgeKey(String fromId, String toId) => '$fromId->$toId';

  /// Record traversing an edge
  void recordEdgeVisit(String fromNodeId, String toNodeId) {
    final edgeKey = _edgeKey(fromNodeId, toNodeId);
    final isFirstVisit = !_visitedEdges.contains(edgeKey);

    _visitedEdges.add(edgeKey);
    _edgeVisitCounts[edgeKey] = (_edgeVisitCounts[edgeKey] ?? 0) + 1;

    _eventController.add(EdgeVisitedEvent(
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      isFirstVisit: isFirstVisit,
    ));
  }

  /// Check if an edge has been visited
  bool isEdgeVisited(String fromNodeId, String toNodeId) {
    return _visitedEdges.contains(_edgeKey(fromNodeId, toNodeId));
  }

  /// Get visit count for an edge
  int getEdgeVisitCount(String fromNodeId, String toNodeId) {
    return _edgeVisitCounts[_edgeKey(fromNodeId, toNodeId)] ?? 0;
  }

  /// Get status for a specific edge
  FlowchartEdgeStatus getEdgeStatus(String fromNodeId, String toNodeId) {
    return FlowchartEdgeStatus(
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      isVisited: isEdgeVisited(fromNodeId, toNodeId),
      visitCount: getEdgeVisitCount(fromNodeId, toNodeId),
    );
  }

  // ============================================================
  // Completion Statistics
  // ============================================================

  /// Get completion percentage for nodes
  double getNodeCompletionPercentage(FlowchartData data) {
    if (data.nodes.isEmpty) return 0.0;
    final visitedCount = data.nodes.where((n) => isNodeVisited(n.id)).length;
    return visitedCount / data.nodes.length;
  }

  /// Get completion percentage for edges
  double getEdgeCompletionPercentage(FlowchartData data) {
    int totalEdges = 0;
    int visitedEdgeCount = 0;

    for (final node in data.nodes) {
      for (final childId in node.childIds) {
        totalEdges++;
        if (isEdgeVisited(node.id, childId)) {
          visitedEdgeCount++;
        }
      }
    }

    if (totalEdges == 0) return 0.0;
    return visitedEdgeCount / totalEdges;
  }

  /// Get completion percentage for choice branches
  double getChoiceCompletionPercentage(FlowchartData data) {
    final choiceNodes = data.choiceNodes;
    if (choiceNodes.isEmpty) return 0.0;

    int totalBranches = 0;
    int visitedBranches = 0;

    for (final choice in choiceNodes) {
      for (final childId in choice.childIds) {
        totalBranches++;
        if (isEdgeVisited(choice.id, childId)) {
          visitedBranches++;
        }
      }
    }

    if (totalBranches == 0) return 0.0;
    return visitedBranches / totalBranches;
  }

  /// Get completion percentage for endings
  double getEndingCompletionPercentage(FlowchartData data) {
    final endingNodes = data.endingNodes;
    if (endingNodes.isEmpty) return 0.0;

    final visitedEndings = endingNodes.where((n) => isNodeVisited(n.id)).length;
    return visitedEndings / endingNodes.length;
  }

  /// Get list of visited node IDs
  Set<String> get visitedNodeIds => Set.unmodifiable(_visitedNodeIds);

  /// Get list of visited edge keys
  Set<String> get visitedEdges => Set.unmodifiable(_visitedEdges);

  /// Get count of visited nodes
  int get visitedNodeCount => _visitedNodeIds.length;

  /// Get count of visited edges
  int get visitedEdgeCount => _visitedEdges.length;

  // ============================================================
  // Path Analysis
  // ============================================================

  /// Get all visited paths from start to endings
  List<List<String>> getVisitedPaths(FlowchartData data) {
    final paths = <List<String>>[];

    void findPaths(String nodeId, List<String> currentPath, Set<String> visited) {
      if (visited.contains(nodeId)) return; // Prevent cycles
      if (!isNodeVisited(nodeId)) return; // Only follow visited nodes

      final newPath = [...currentPath, nodeId];
      final newVisited = {...visited, nodeId};

      final node = data.getNode(nodeId);
      if (node == null) return;

      if (node.type == FlowchartNodeType.ending) {
        paths.add(newPath);
        return;
      }

      for (final childId in node.childIds) {
        if (isEdgeVisited(nodeId, childId)) {
          findPaths(childId, newPath, newVisited);
        }
      }
    }

    findPaths(data.rootId, [], {});
    return paths;
  }

  /// Get unvisited branches from a specific node
  List<String> getUnvisitedBranches(FlowchartData data, String nodeId) {
    final node = data.getNode(nodeId);
    if (node == null) return [];

    return node.childIds
        .where((childId) => !isEdgeVisited(nodeId, childId))
        .toList();
  }

  // ============================================================
  // Serialization
  // ============================================================

  Map<String, dynamic> toJson() => {
        'visitedNodes': _visitedNodeIds.toList(),
        'visitedEdges': _visitedEdges.toList(),
        'nodeVisitCounts': _nodeVisitCounts,
        'edgeVisitCounts': _edgeVisitCounts,
        'firstVisitTimes': _firstVisitTimes.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'lastVisitTimes': _lastVisitTimes.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
      };

  factory FlowchartStateManager.fromJson(Map<String, dynamic> json) {
    return FlowchartStateManager(
      visitedNodeIds: Set<String>.from(json['visitedNodes'] as List? ?? []),
      visitedEdges: Set<String>.from(json['visitedEdges'] as List? ?? []),
      nodeVisitCounts:
          (json['nodeVisitCounts'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v as int),
              ) ??
              {},
      edgeVisitCounts:
          (json['edgeVisitCounts'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v as int),
              ) ??
              {},
      firstVisitTimes:
          (json['firstVisitTimes'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, DateTime.parse(v as String)),
              ) ??
              {},
      lastVisitTimes:
          (json['lastVisitTimes'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, DateTime.parse(v as String)),
              ) ??
              {},
    );
  }

  /// Reset all state
  void reset() {
    _visitedNodeIds.clear();
    _visitedEdges.clear();
    _nodeVisitCounts.clear();
    _edgeVisitCounts.clear();
    _firstVisitTimes.clear();
    _lastVisitTimes.clear();
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}
