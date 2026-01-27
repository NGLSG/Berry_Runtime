/// Flowchart Data Model
///
/// Contains the complete flowchart structure and provides methods
/// to generate flowchart from StoryGraph.
/// Requirements: 4.2

import '../../models/story_graph.dart';
import '../../models/vn_node.dart';
import '../../models/chapter.dart';
import 'flowchart_node.dart';

/// Complete flowchart data structure
class FlowchartData {
  /// All nodes in the flowchart
  final List<FlowchartNode> nodes;

  /// ID of the root/start node
  final String rootId;

  /// Chapter ID this flowchart represents (null for multi-chapter)
  final String? chapterId;

  /// Map of node IDs to their parent IDs for quick lookup
  final Map<String, List<String>> _parentMap;

  FlowchartData({
    required this.nodes,
    required this.rootId,
    this.chapterId,
  }) : _parentMap = _buildParentMap(nodes);

  /// Build parent map from nodes
  static Map<String, List<String>> _buildParentMap(List<FlowchartNode> nodes) {
    final parentMap = <String, List<String>>{};
    for (final node in nodes) {
      for (final childId in node.childIds) {
        parentMap.putIfAbsent(childId, () => []).add(node.id);
      }
    }
    return parentMap;
  }

  /// Get a node by ID
  FlowchartNode? getNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get parent node IDs for a given node
  List<String> getParentIds(String nodeId) {
    return _parentMap[nodeId] ?? [];
  }

  /// Get child nodes for a given node
  List<FlowchartNode> getChildren(String nodeId) {
    final node = getNode(nodeId);
    if (node == null) return [];
    return node.childIds
        .map((id) => getNode(id))
        .whereType<FlowchartNode>()
        .toList();
  }

  /// Get all ending nodes
  List<FlowchartNode> get endingNodes {
    return nodes.where((n) => n.type == FlowchartNodeType.ending).toList();
  }

  /// Get all choice nodes
  List<FlowchartNode> get choiceNodes {
    return nodes.where((n) => n.type == FlowchartNodeType.choice).toList();
  }

  /// Get all branching nodes (nodes with multiple children)
  List<FlowchartNode> get branchingNodes {
    return nodes.where((n) => n.isBranching).toList();
  }

  /// Calculate total number of unique paths to endings
  int get totalPaths {
    int count = 0;
    void countPaths(String nodeId, Set<String> visited) {
      if (visited.contains(nodeId)) return; // Prevent infinite loops
      visited.add(nodeId);

      final node = getNode(nodeId);
      if (node == null) return;

      if (node.type == FlowchartNodeType.ending) {
        count++;
        return;
      }

      for (final childId in node.childIds) {
        countPaths(childId, Set.from(visited));
      }
    }

    countPaths(rootId, {});
    return count;
  }

  /// Create flowchart from a single chapter's story graph
  factory FlowchartData.fromStoryGraph(
    StoryGraph graph, {
    String? chapterId,
  }) {
    final nodes = <FlowchartNode>[];
    final processedIds = <String>{};

    void processNode(VNNode vnNode) {
      if (processedIds.contains(vnNode.id)) return;
      processedIds.add(vnNode.id);

      // Get outgoing edges
      final outgoingEdges = graph.getOutgoingEdges(vnNode.id);
      final childIds = outgoingEdges.map((e) => e.targetNodeId).toList();

      // Convert VNNode type to FlowchartNodeType
      final flowchartType = _vnNodeTypeToFlowchartType(vnNode.type);

      // Generate label based on node type
      final label = _generateNodeLabel(vnNode);

      // Get ending ID if this is an ending node
      String? endingId;
      if (vnNode is EndingNode) {
        endingId = vnNode.endingId ?? vnNode.id;
      }

      nodes.add(FlowchartNode(
        id: vnNode.id,
        label: label,
        type: flowchartType,
        childIds: childIds,
        endingId: endingId,
        chapterId: chapterId,
      ));

      // Process child nodes
      for (final edge in outgoingEdges) {
        final childNode = graph.getNode(edge.targetNodeId);
        if (childNode != null) {
          processNode(childNode);
        }
      }
    }

    // Start from the start node
    if (graph.startNodeId != null) {
      final startNode = graph.getNode(graph.startNodeId!);
      if (startNode != null) {
        processNode(startNode);
      }
    }

    // Also process any orphan nodes that might be reachable
    for (final node in graph.nodes) {
      if (!processedIds.contains(node.id)) {
        processNode(node);
      }
    }

    return FlowchartData(
      nodes: nodes,
      rootId: graph.startNodeId ?? (nodes.isNotEmpty ? nodes.first.id : ''),
      chapterId: chapterId,
    );
  }

  /// Create flowchart from multiple chapters
  factory FlowchartData.fromChapters(List<Chapter> chapters) {
    final allNodes = <FlowchartNode>[];
    String? rootId;

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterFlowchart = FlowchartData.fromStoryGraph(
        chapter.graph,
        chapterId: chapter.id,
      );

      // Update labels to include chapter info
      for (final node in chapterFlowchart.nodes) {
        allNodes.add(node.copyWith(
          label: node.type == FlowchartNodeType.start
              ? '${chapter.title}: ${node.label}'
              : node.label,
          order: i * 1000 + node.order,
        ));
      }

      // First chapter's root is the overall root
      if (i == 0) {
        rootId = chapterFlowchart.rootId;
      }
    }

    return FlowchartData(
      nodes: allNodes,
      rootId: rootId ?? '',
    );
  }

  /// Convert VNNodeType to FlowchartNodeType
  static FlowchartNodeType _vnNodeTypeToFlowchartType(VNNodeType type) {
    switch (type) {
      case VNNodeType.start:
        return FlowchartNodeType.start;
      case VNNodeType.scene:
        return FlowchartNodeType.scene;
      case VNNodeType.choice:
        return FlowchartNodeType.choice;
      case VNNodeType.ending:
        return FlowchartNodeType.ending;
      case VNNodeType.jump:
        return FlowchartNodeType.jump;
      case VNNodeType.condition:
      case VNNodeType.switch_:
        return FlowchartNodeType.condition;
      default:
        return FlowchartNodeType.scene;
    }
  }

  /// Generate a display label for a VNNode
  static String _generateNodeLabel(VNNode node) {
    switch (node.type) {
      case VNNodeType.start:
        return 'Start';
      case VNNodeType.scene:
        final sceneNode = node as SceneNode;
        if (sceneNode.dialogues.isNotEmpty) {
          final firstLine = sceneNode.dialogues.first.text;
          return firstLine.length > 30
              ? '${firstLine.substring(0, 30)}...'
              : firstLine;
        }
        return 'Scene';
      case VNNodeType.choice:
        final choiceNode = node as ChoiceNode;
        return 'Choice (${choiceNode.options.length} options)';
      case VNNodeType.ending:
        final endingNode = node as EndingNode;
        return endingNode.endingName ?? 'Ending';
      case VNNodeType.jump:
        final jumpNode = node as JumpNode;
        if (jumpNode.targetChapterId != null) {
          return 'Jump to Chapter';
        }
        return 'Jump';
      case VNNodeType.condition:
        final condNode = node as ConditionNode;
        return 'If: ${condNode.expression.length > 20 ? '${condNode.expression.substring(0, 20)}...' : condNode.expression}';
      case VNNodeType.switch_:
        final switchNode = node as SwitchNode;
        return 'Switch (${switchNode.cases.length} cases)';
      default:
        return node.type.name;
    }
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'rootId': rootId,
        if (chapterId != null) 'chapterId': chapterId,
      };

  factory FlowchartData.fromJson(Map<String, dynamic> json) {
    return FlowchartData(
      nodes: (json['nodes'] as List)
          .map((n) => FlowchartNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      rootId: json['rootId'] as String,
      chapterId: json['chapterId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowchartData &&
          runtimeType == other.runtimeType &&
          rootId == other.rootId &&
          nodes.length == other.nodes.length;

  @override
  int get hashCode => Object.hash(rootId, nodes.length);
}
