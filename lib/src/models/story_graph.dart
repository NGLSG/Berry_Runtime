import 'chapter.dart';
import 'vn_node.dart';
import 'vn_character.dart';
import 'vn_resource.dart';
import 'vn_variable.dart';
import 'story_graph_validator.dart';

/// Edge connecting two nodes in the story graph
class StoryEdge {
  /// Unique edge identifier
  final String id;

  /// Source node ID
  final String sourceNodeId;

  /// Target node ID
  final String targetNodeId;

  /// Source port name (for nodes with multiple outputs)
  final String? sourcePort;

  /// Target port name (for nodes with multiple inputs)
  final String? targetPort;

  /// Optional label for the edge
  final String? label;

  const StoryEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourcePort,
    this.targetPort,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        if (sourcePort != null) 'sourcePort': sourcePort,
        if (targetPort != null) 'targetPort': targetPort,
        if (label != null) 'label': label,
      };

  factory StoryEdge.fromJson(Map<String, dynamic> json) {
    return StoryEdge(
      id: json['id'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      targetNodeId: json['targetNodeId'] as String,
      sourcePort: json['sourcePort'] as String?,
      targetPort: json['targetPort'] as String?,
      label: json['label'] as String?,
    );
  }

  StoryEdge copyWith({
    String? id,
    String? sourceNodeId,
    String? targetNodeId,
    String? sourcePort,
    String? targetPort,
    String? label,
  }) {
    return StoryEdge(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      sourcePort: sourcePort ?? this.sourcePort,
      targetPort: targetPort ?? this.targetPort,
      label: label ?? this.label,
    );
  }
}

/// Validation error for story graph
class ValidationError {
  /// Error code
  final String code;

  /// Human-readable error message
  final String message;

  /// Related node ID (if applicable)
  final String? nodeId;

  /// Error severity
  final ValidationSeverity severity;

  const ValidationError({
    required this.code,
    required this.message,
    this.nodeId,
    this.severity = ValidationSeverity.error,
  });

  @override
  String toString() => '[$severity] $code: $message${nodeId != null ? ' (node: $nodeId)' : ''}';
}

/// Validation error severity
enum ValidationSeverity {
  warning,
  error,
}


/// Story graph containing nodes and edges for a chapter
class StoryGraph {
  /// ID of the start node for this graph
  final String? startNodeId;

  /// All nodes in the graph
  final List<VNNode> nodes;

  /// All edges connecting nodes
  final List<StoryEdge> edges;

  const StoryGraph({
    this.startNodeId,
    this.nodes = const [],
    this.edges = const [],
  });

  Map<String, dynamic> toJson() => {
        if (startNodeId != null) 'startNodeId': startNodeId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  factory StoryGraph.fromJson(Map<String, dynamic> json) {
    return StoryGraph(
      startNodeId: json['startNodeId'] as String?,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((n) => VNNode.fromJson(n as Map<String, dynamic>))
              .toList() ??
          const [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => StoryEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  StoryGraph copyWith({
    String? startNodeId,
    List<VNNode>? nodes,
    List<StoryEdge>? edges,
  }) {
    return StoryGraph(
      startNodeId: startNodeId ?? this.startNodeId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  /// Get a node by ID
  VNNode? getNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all edges from a node
  List<StoryEdge> getOutgoingEdges(String nodeId) {
    return edges.where((e) => e.sourceNodeId == nodeId).toList();
  }

  /// Get all edges to a node
  List<StoryEdge> getIncomingEdges(String nodeId) {
    return edges.where((e) => e.targetNodeId == nodeId).toList();
  }

  /// Validate the story graph
  List<ValidationError> validate() {
    final errors = <ValidationError>[];

    // Check for start node
    if (startNodeId == null && nodes.isNotEmpty) {
      errors.add(const ValidationError(
        code: 'NO_START_NODE',
        message: 'Story graph has no start node defined',
      ));
    } else if (startNodeId != null && getNode(startNodeId!) == null) {
      errors.add(ValidationError(
        code: 'INVALID_START_NODE',
        message: 'Start node "$startNodeId" does not exist',
      ));
    }

    // Check for orphan nodes
    final orphans = findOrphanNodes();
    for (final nodeId in orphans) {
      errors.add(ValidationError(
        code: 'ORPHAN_NODE',
        message: 'Node has no incoming connections and is not the start node',
        nodeId: nodeId,
        severity: ValidationSeverity.warning,
      ));
    }

    // Check for dead ends
    final deadEnds = findDeadEnds();
    for (final nodeId in deadEnds) {
      final node = getNode(nodeId);
      if (node != null && node.type != VNNodeType.ending) {
        errors.add(ValidationError(
          code: 'DEAD_END',
          message: 'Node has no outgoing connections and is not an ending node',
          nodeId: nodeId,
          severity: ValidationSeverity.warning,
        ));
      }
    }

    // Validate edge references
    for (final edge in edges) {
      if (getNode(edge.sourceNodeId) == null) {
        errors.add(ValidationError(
          code: 'INVALID_EDGE_SOURCE',
          message: 'Edge references non-existent source node "${edge.sourceNodeId}"',
        ));
      }
      if (getNode(edge.targetNodeId) == null) {
        errors.add(ValidationError(
          code: 'INVALID_EDGE_TARGET',
          message: 'Edge references non-existent target node "${edge.targetNodeId}"',
        ));
      }
    }

    return errors;
  }

  /// Find nodes with no incoming edges (except start node)
  List<String> findOrphanNodes() {
    final orphans = <String>[];
    for (final node in nodes) {
      if (node.id == startNodeId) continue;
      if (node.type == VNNodeType.start) continue;
      
      final incoming = getIncomingEdges(node.id);
      if (incoming.isEmpty) {
        orphans.add(node.id);
      }
    }
    return orphans;
  }

  /// Find nodes with no outgoing edges (except ending nodes)
  List<String> findDeadEnds() {
    final deadEnds = <String>[];
    for (final node in nodes) {
      if (node.type == VNNodeType.ending) continue;
      
      final outgoing = getOutgoingEdges(node.id);
      if (outgoing.isEmpty) {
        deadEnds.add(node.id);
      }
    }
    return deadEnds;
  }

  /// Check if all paths eventually lead to an ending
  bool allPathsLeadToEndings() {
    final validator = StoryGraphValidator(graph: this);
    return validator.allPathsLeadToEndings();
  }

  /// Validate resource references in the graph
  /// 
  /// Checks that all referenced backgrounds, BGM, SFX, and voices exist
  /// in the provided resource library.
  List<ValidationError> validateResourceReferences(VNResourceLibrary resources) {
    final validator = StoryGraphValidator(
      graph: this,
      resources: resources,
    );
    return validator.validateResourceReferences();
  }

  /// Validate character references in the graph
  /// 
  /// Checks that all referenced characters exist in the provided list.
  List<ValidationError> validateCharacterReferences(List<VNCharacter> characters) {
    final validator = StoryGraphValidator(
      graph: this,
      characters: characters,
    );
    return validator.validateCharacterReferences();
  }

  /// Validate character expression references
  /// 
  /// Checks that all referenced expressions exist for each character.
  List<ValidationError> validateCharacterExpressions(List<VNCharacter> characters) {
    final validator = StoryGraphValidator(
      graph: this,
      characters: characters,
    );
    return validator.validateCharacterExpressions();
  }

  /// Validate variable references in conditions and operations
  /// 
  /// Checks that all referenced variables are defined.
  List<ValidationError> validateVariableReferences(List<VNVariable> variables) {
    final validator = StoryGraphValidator(
      graph: this,
      variables: variables,
    );
    return validator.validateVariableReferences();
  }

  /// Validate connection compatibility between two nodes
  /// 
  /// Returns null if the connection is valid, or a ValidationError if not.
  static ValidationError? validateConnection(
    VNNode sourceNode,
    VNNode targetNode, {
    String? sourcePort,
    String? targetPort,
  }) {
    return StoryGraphValidator.validateConnection(
      sourceNode,
      targetNode,
      sourcePort: sourcePort,
      targetPort: targetPort,
    );
  }

  /// Run comprehensive validation with all available context
  /// 
  /// This method validates the graph structure, resource references,
  /// character references, variable references, and cross-chapter references.
  List<ValidationError> validateAll({
    VNResourceLibrary? resources,
    List<VNCharacter>? characters,
    List<VNVariable>? variables,
    List<Chapter>? allChapters,
  }) {
    final validator = StoryGraphValidator(
      graph: this,
      resources: resources,
      characters: characters,
      variables: variables,
      allChapters: allChapters,
    );
    return validator.validateAll();
  }

  /// Validate cross-chapter jump references
  /// 
  /// Checks that all cross-chapter jumps reference valid chapters and nodes.
  List<ValidationError> validateCrossChapterReferences(List<Chapter> allChapters) {
    final validator = StoryGraphValidator(
      graph: this,
      allChapters: allChapters,
    );
    return validator.validateCrossChapterReferences();
  }
}
