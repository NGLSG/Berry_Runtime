/// Branch Coverage Analyzer for VN Runtime
/// 
/// Provides branch coverage analysis for visual novel story graphs:
/// - Tracks visited nodes and edges
/// - Calculates coverage percentages
/// - Identifies untested paths
/// - Generates coverage reports

import '../compiler/vn_story_bundle.dart';

/// Coverage status for a single node
class NodeCoverageStatus {
  /// Node ID
  final String nodeId;
  
  /// Node type
  final String nodeType;
  
  /// Whether the node has been visited
  final bool isVisited;
  
  /// Number of times visited
  final int visitCount;
  
  /// For choice nodes: which options have been selected
  final Set<String> selectedOptions;
  
  /// Total options (for choice nodes)
  final int totalOptions;

  const NodeCoverageStatus({
    required this.nodeId,
    required this.nodeType,
    required this.isVisited,
    this.visitCount = 0,
    this.selectedOptions = const {},
    this.totalOptions = 0,
  });

  /// Coverage percentage for this node (0.0 - 1.0)
  double get coverage {
    if (!isVisited) return 0.0;
    if (nodeType == 'choice' && totalOptions > 0) {
      return selectedOptions.length / totalOptions;
    }
    return 1.0;
  }

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'nodeType': nodeType,
    'isVisited': isVisited,
    'visitCount': visitCount,
    'selectedOptions': selectedOptions.toList(),
    'totalOptions': totalOptions,
    'coverage': coverage,
  };
}

/// Coverage status for an edge
class EdgeCoverageStatus {
  /// Edge ID
  final String edgeId;
  
  /// Source node ID
  final String sourceNodeId;
  
  /// Target node ID
  final String targetNodeId;
  
  /// Whether the edge has been traversed
  final bool isTraversed;
  
  /// Number of times traversed
  final int traverseCount;

  const EdgeCoverageStatus({
    required this.edgeId,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.isTraversed,
    this.traverseCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'edgeId': edgeId,
    'sourceNodeId': sourceNodeId,
    'targetNodeId': targetNodeId,
    'isTraversed': isTraversed,
    'traverseCount': traverseCount,
  };
}

/// Coverage report for a chapter
class ChapterCoverageReport {
  /// Chapter ID
  final String chapterId;
  
  /// Chapter title
  final String chapterTitle;
  
  /// Node coverage statuses
  final List<NodeCoverageStatus> nodeStatuses;
  
  /// Edge coverage statuses
  final List<EdgeCoverageStatus> edgeStatuses;
  
  /// Untested node IDs
  final List<String> untestedNodes;
  
  /// Untested edge IDs
  final List<String> untestedEdges;

  const ChapterCoverageReport({
    required this.chapterId,
    required this.chapterTitle,
    required this.nodeStatuses,
    required this.edgeStatuses,
    required this.untestedNodes,
    required this.untestedEdges,
  });

  /// Total nodes in chapter
  int get totalNodes => nodeStatuses.length;
  
  /// Visited nodes count
  int get visitedNodes => nodeStatuses.where((n) => n.isVisited).length;
  
  /// Node coverage percentage (0.0 - 1.0)
  double get nodeCoverage => totalNodes > 0 ? visitedNodes / totalNodes : 0.0;
  
  /// Total edges in chapter
  int get totalEdges => edgeStatuses.length;
  
  /// Traversed edges count
  int get traversedEdges => edgeStatuses.where((e) => e.isTraversed).length;
  
  /// Edge coverage percentage (0.0 - 1.0)
  double get edgeCoverage => totalEdges > 0 ? traversedEdges / totalEdges : 0.0;
  
  /// Overall coverage (average of node and edge coverage)
  double get overallCoverage => (nodeCoverage + edgeCoverage) / 2;
  
  /// Choice coverage (percentage of choice options selected)
  double get choiceCoverage {
    final choiceNodes = nodeStatuses.where((n) => n.nodeType == 'choice');
    if (choiceNodes.isEmpty) return 1.0;
    
    int totalOptions = 0;
    int selectedOptions = 0;
    for (final node in choiceNodes) {
      totalOptions += node.totalOptions;
      selectedOptions += node.selectedOptions.length;
    }
    
    return totalOptions > 0 ? selectedOptions / totalOptions : 1.0;
  }

  Map<String, dynamic> toJson() => {
    'chapterId': chapterId,
    'chapterTitle': chapterTitle,
    'totalNodes': totalNodes,
    'visitedNodes': visitedNodes,
    'nodeCoverage': nodeCoverage,
    'totalEdges': totalEdges,
    'traversedEdges': traversedEdges,
    'edgeCoverage': edgeCoverage,
    'overallCoverage': overallCoverage,
    'choiceCoverage': choiceCoverage,
    'untestedNodes': untestedNodes,
    'untestedEdges': untestedEdges,
    'nodeStatuses': nodeStatuses.map((n) => n.toJson()).toList(),
    'edgeStatuses': edgeStatuses.map((e) => e.toJson()).toList(),
  };
}

/// Full coverage report for all chapters
class CoverageReport {
  /// Chapter reports
  final List<ChapterCoverageReport> chapterReports;
  
  /// Report generation timestamp
  final DateTime timestamp;

  const CoverageReport({
    required this.chapterReports,
    required this.timestamp,
  });

  /// Total nodes across all chapters
  int get totalNodes => chapterReports.fold(0, (sum, r) => sum + r.totalNodes);
  
  /// Visited nodes across all chapters
  int get visitedNodes => chapterReports.fold(0, (sum, r) => sum + r.visitedNodes);
  
  /// Overall node coverage
  double get nodeCoverage => totalNodes > 0 ? visitedNodes / totalNodes : 0.0;
  
  /// Total edges across all chapters
  int get totalEdges => chapterReports.fold(0, (sum, r) => sum + r.totalEdges);
  
  /// Traversed edges across all chapters
  int get traversedEdges => chapterReports.fold(0, (sum, r) => sum + r.traversedEdges);
  
  /// Overall edge coverage
  double get edgeCoverage => totalEdges > 0 ? traversedEdges / totalEdges : 0.0;
  
  /// Overall coverage
  double get overallCoverage => (nodeCoverage + edgeCoverage) / 2;
  
  /// All untested nodes across chapters
  List<String> get allUntestedNodes => 
      chapterReports.expand((r) => r.untestedNodes.map((n) => '${r.chapterId}:$n')).toList();
  
  /// All untested edges across chapters
  List<String> get allUntestedEdges =>
      chapterReports.expand((r) => r.untestedEdges.map((e) => '${r.chapterId}:$e')).toList();

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'totalNodes': totalNodes,
    'visitedNodes': visitedNodes,
    'nodeCoverage': nodeCoverage,
    'totalEdges': totalEdges,
    'traversedEdges': traversedEdges,
    'edgeCoverage': edgeCoverage,
    'overallCoverage': overallCoverage,
    'allUntestedNodes': allUntestedNodes,
    'allUntestedEdges': allUntestedEdges,
    'chapterReports': chapterReports.map((r) => r.toJson()).toList(),
  };
}


/// Branch Coverage Analyzer
/// 
/// Tracks and analyzes branch coverage for visual novel story graphs.
class BranchCoverageAnalyzer {
  /// Visited nodes by chapter: chapterId -> Set<nodeId>
  final Map<String, Set<String>> _visitedNodes = {};
  
  /// Visit counts by chapter: chapterId -> nodeId -> count
  final Map<String, Map<String, int>> _visitCounts = {};
  
  /// Traversed edges by chapter: chapterId -> Set<"sourceId->targetId">
  final Map<String, Set<String>> _traversedEdges = {};
  
  /// Edge traverse counts: chapterId -> edgeKey -> count
  final Map<String, Map<String, int>> _edgeTraverseCounts = {};
  
  /// Selected choice options: chapterId -> nodeId -> Set<optionId>
  final Map<String, Map<String, Set<String>>> _selectedChoices = {};

  /// Record a node visit
  void recordNodeVisit(String chapterId, String nodeId) {
    _visitedNodes.putIfAbsent(chapterId, () => {});
    _visitedNodes[chapterId]!.add(nodeId);
    
    _visitCounts.putIfAbsent(chapterId, () => {});
    _visitCounts[chapterId]!.update(nodeId, (c) => c + 1, ifAbsent: () => 1);
  }

  /// Record an edge traversal
  void recordEdgeTraversal(String chapterId, String sourceNodeId, String targetNodeId) {
    final edgeKey = '$sourceNodeId->$targetNodeId';
    
    _traversedEdges.putIfAbsent(chapterId, () => {});
    _traversedEdges[chapterId]!.add(edgeKey);
    
    _edgeTraverseCounts.putIfAbsent(chapterId, () => {});
    _edgeTraverseCounts[chapterId]!.update(edgeKey, (c) => c + 1, ifAbsent: () => 1);
  }

  /// Record a choice selection
  void recordChoiceSelection(String chapterId, String nodeId, String optionId) {
    _selectedChoices.putIfAbsent(chapterId, () => {});
    _selectedChoices[chapterId]!.putIfAbsent(nodeId, () => {});
    _selectedChoices[chapterId]![nodeId]!.add(optionId);
  }

  /// Check if a node has been visited
  bool isNodeVisited(String chapterId, String nodeId) {
    return _visitedNodes[chapterId]?.contains(nodeId) ?? false;
  }

  /// Check if an edge has been traversed
  bool isEdgeTraversed(String chapterId, String sourceNodeId, String targetNodeId) {
    final edgeKey = '$sourceNodeId->$targetNodeId';
    return _traversedEdges[chapterId]?.contains(edgeKey) ?? false;
  }

  /// Get visit count for a node
  int getNodeVisitCount(String chapterId, String nodeId) {
    return _visitCounts[chapterId]?[nodeId] ?? 0;
  }

  /// Get traverse count for an edge
  int getEdgeTraverseCount(String chapterId, String sourceNodeId, String targetNodeId) {
    final edgeKey = '$sourceNodeId->$targetNodeId';
    return _edgeTraverseCounts[chapterId]?[edgeKey] ?? 0;
  }

  /// Get selected options for a choice node
  Set<String> getSelectedOptions(String chapterId, String nodeId) {
    return _selectedChoices[chapterId]?[nodeId] ?? {};
  }

  /// Generate coverage report for a single chapter
  ChapterCoverageReport generateChapterReport(CompiledChapter chapter) {
    final chapterId = chapter.id;
    
    final nodeStatuses = <NodeCoverageStatus>[];
    final edgeStatuses = <EdgeCoverageStatus>[];
    final untestedNodes = <String>[];
    final untestedEdges = <String>[];
    
    // Analyze nodes
    for (final entry in chapter.nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      final isVisited = isNodeVisited(chapterId, nodeId);
      final visitCount = getNodeVisitCount(chapterId, nodeId);
      
      Set<String> selectedOptions = {};
      int totalOptions = 0;
      
      if (node.type == 'choice') {
        selectedOptions = getSelectedOptions(chapterId, nodeId);
        final options = node.data['options'] as List<dynamic>?;
        totalOptions = options?.length ?? 0;
      }
      
      nodeStatuses.add(NodeCoverageStatus(
        nodeId: nodeId,
        nodeType: node.type,
        isVisited: isVisited,
        visitCount: visitCount,
        selectedOptions: selectedOptions,
        totalOptions: totalOptions,
      ));
      
      if (!isVisited) {
        untestedNodes.add(nodeId);
      }
      
      // Track edges from this node
      if (node.next != null) {
        final edgeKey = '$nodeId->${node.next}';
        final isTraversed = isEdgeTraversed(chapterId, nodeId, node.next!);
        final traverseCount = getEdgeTraverseCount(chapterId, nodeId, node.next!);
        
        edgeStatuses.add(EdgeCoverageStatus(
          edgeId: edgeKey,
          sourceNodeId: nodeId,
          targetNodeId: node.next!,
          isTraversed: isTraversed,
          traverseCount: traverseCount,
        ));
        
        if (!isTraversed) {
          untestedEdges.add(edgeKey);
        }
      }
    }
    
    return ChapterCoverageReport(
      chapterId: chapterId,
      chapterTitle: chapter.title,
      nodeStatuses: nodeStatuses,
      edgeStatuses: edgeStatuses,
      untestedNodes: untestedNodes,
      untestedEdges: untestedEdges,
    );
  }

  /// Generate full coverage report for all chapters
  CoverageReport generateReport(List<CompiledChapter> chapters) {
    final chapterReports = chapters.map(generateChapterReport).toList();
    
    return CoverageReport(
      chapterReports: chapterReports,
      timestamp: DateTime.now(),
    );
  }

  /// Get untested paths (nodes that haven't been visited)
  List<String> getUntestedPaths(List<CompiledChapter> chapters) {
    final untested = <String>[];
    
    for (final chapter in chapters) {
      for (final nodeId in chapter.nodes.keys) {
        if (!isNodeVisited(chapter.id, nodeId)) {
          untested.add('${chapter.id}:$nodeId');
        }
      }
    }
    
    return untested;
  }

  /// Get untested choice options
  Map<String, List<String>> getUntestedChoiceOptions(List<CompiledChapter> chapters) {
    final untested = <String, List<String>>{};
    
    for (final chapter in chapters) {
      for (final entry in chapter.nodes.entries) {
        final nodeId = entry.key;
        final node = entry.value;
        
        if (node.type == 'choice') {
          final selected = getSelectedOptions(chapter.id, nodeId);
          final options = node.data['options'] as List<dynamic>?;
          if (options != null) {
            final unselected = <String>[];
            for (int i = 0; i < options.length; i++) {
              if (!selected.contains(i.toString())) {
                unselected.add(i.toString());
              }
            }
            if (unselected.isNotEmpty) {
              untested['${chapter.id}:$nodeId'] = unselected;
            }
          }
        }
      }
    }
    
    return untested;
  }

  /// Calculate overall coverage percentage
  double calculateOverallCoverage(List<CompiledChapter> chapters) {
    int totalNodes = 0;
    int visitedNodes = 0;
    int totalEdges = 0;
    int traversedEdges = 0;
    
    for (final chapter in chapters) {
      totalNodes += chapter.nodes.length;
      
      for (final entry in chapter.nodes.entries) {
        final nodeId = entry.key;
        final node = entry.value;
        
        if (isNodeVisited(chapter.id, nodeId)) {
          visitedNodes++;
        }
        
        if (node.next != null) {
          totalEdges++;
          if (isEdgeTraversed(chapter.id, nodeId, node.next!)) {
            traversedEdges++;
          }
        }
      }
    }
    
    final nodeCoverage = totalNodes > 0 ? visitedNodes / totalNodes : 0.0;
    final edgeCoverage = totalEdges > 0 ? traversedEdges / totalEdges : 0.0;
    
    return (nodeCoverage + edgeCoverage) / 2;
  }

  /// Reset all coverage data
  void reset() {
    _visitedNodes.clear();
    _visitCounts.clear();
    _traversedEdges.clear();
    _edgeTraverseCounts.clear();
    _selectedChoices.clear();
  }

  /// Reset coverage data for a specific chapter
  void resetChapter(String chapterId) {
    _visitedNodes.remove(chapterId);
    _visitCounts.remove(chapterId);
    _traversedEdges.remove(chapterId);
    _edgeTraverseCounts.remove(chapterId);
    _selectedChoices.remove(chapterId);
  }

  /// Export coverage data as JSON
  Map<String, dynamic> exportData() {
    return {
      'visitedNodes': _visitedNodes.map((k, v) => MapEntry(k, v.toList())),
      'visitCounts': _visitCounts,
      'traversedEdges': _traversedEdges.map((k, v) => MapEntry(k, v.toList())),
      'edgeTraverseCounts': _edgeTraverseCounts,
      'selectedChoices': _selectedChoices.map((k, v) => 
          MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2.toList())))),
    };
  }

  /// Import coverage data from JSON
  void importData(Map<String, dynamic> data) {
    reset();
    
    final visitedNodes = data['visitedNodes'] as Map<String, dynamic>?;
    if (visitedNodes != null) {
      for (final entry in visitedNodes.entries) {
        _visitedNodes[entry.key] = (entry.value as List).cast<String>().toSet();
      }
    }
    
    final visitCounts = data['visitCounts'] as Map<String, dynamic>?;
    if (visitCounts != null) {
      for (final entry in visitCounts.entries) {
        _visitCounts[entry.key] = (entry.value as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
      }
    }
    
    final traversedEdges = data['traversedEdges'] as Map<String, dynamic>?;
    if (traversedEdges != null) {
      for (final entry in traversedEdges.entries) {
        _traversedEdges[entry.key] = (entry.value as List).cast<String>().toSet();
      }
    }
    
    final edgeTraverseCounts = data['edgeTraverseCounts'] as Map<String, dynamic>?;
    if (edgeTraverseCounts != null) {
      for (final entry in edgeTraverseCounts.entries) {
        _edgeTraverseCounts[entry.key] = (entry.value as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
      }
    }
    
    final selectedChoices = data['selectedChoices'] as Map<String, dynamic>?;
    if (selectedChoices != null) {
      for (final entry in selectedChoices.entries) {
        _selectedChoices[entry.key] = {};
        final nodeChoices = entry.value as Map<String, dynamic>;
        for (final nodeEntry in nodeChoices.entries) {
          _selectedChoices[entry.key]![nodeEntry.key] = 
              (nodeEntry.value as List).cast<String>().toSet();
        }
      }
    }
  }
}
