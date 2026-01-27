/// Predictive Resource Preloader
///
/// Implements story flow-based prediction to preload resources before
/// they are needed, ensuring smooth playback.
///
/// Requirements: 24.2

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'resource_loader.dart';
import '../../compiler/vn_story_bundle.dart';
import '../../compiler/vn_resource_manifest.dart';

/// Prediction strategy for preloading
enum PreloadStrategy {
  /// Preload all resources in current scene's branch
  aggressive,

  /// Preload only immediate next resources
  conservative,

  /// Balance between aggressive and conservative
  balanced,

  /// Disable preloading
  disabled,
}

/// Resource prediction result
class PredictedResource {
  /// Resource ID
  final String id;

  /// Resource path
  final String path;

  /// Resource type
  final ResourceLoadType type;

  /// Probability of being needed (0.0 - 1.0)
  final double probability;

  /// Estimated time until needed (in nodes)
  final int nodesAway;

  const PredictedResource({
    required this.id,
    required this.path,
    required this.type,
    required this.probability,
    required this.nodesAway,
  });
}

/// Node resource analysis result
class NodeResourceAnalysis {
  /// Node ID
  final String nodeId;

  /// Resources used by this node
  final List<({String id, String path, ResourceLoadType type})> resources;

  /// Next possible node IDs
  final List<String> nextNodeIds;

  /// Whether this is a choice node
  final bool isChoice;

  /// Whether this is an ending node
  final bool isEnding;

  const NodeResourceAnalysis({
    required this.nodeId,
    required this.resources,
    required this.nextNodeIds,
    this.isChoice = false,
    this.isEnding = false,
  });
}

/// Predictive Preloader
///
/// Analyzes story graph to predict and preload resources:
/// - Looks ahead N nodes in the story flow
/// - Considers branching probability
/// - Prioritizes resources based on likelihood of use
class PredictivePreloader extends ChangeNotifier {
  final LazyResourceLoader _loader;
  final VNResourceManifest _manifest;

  /// Current preload strategy
  PreloadStrategy _strategy;

  /// How many nodes to look ahead
  int _lookAheadDepth;

  /// Analyzed chapter data
  final Map<String, Map<String, NodeResourceAnalysis>> _chapterAnalysis = {};

  /// Currently preloading resources
  final Set<String> _preloading = {};

  /// Preload statistics
  int _preloadHits = 0;
  int _preloadMisses = 0;

  PredictivePreloader({
    required LazyResourceLoader loader,
    required VNResourceManifest manifest,
    PreloadStrategy strategy = PreloadStrategy.balanced,
    int lookAheadDepth = 5,
  })  : _loader = loader,
        _manifest = manifest,
        _strategy = strategy,
        _lookAheadDepth = lookAheadDepth;

  /// Get/set preload strategy
  PreloadStrategy get strategy => _strategy;
  set strategy(PreloadStrategy value) {
    _strategy = value;
    notifyListeners();
  }

  /// Get/set look ahead depth
  int get lookAheadDepth => _lookAheadDepth;
  set lookAheadDepth(int value) {
    _lookAheadDepth = value.clamp(1, 20);
    notifyListeners();
  }

  /// Get preload hit rate
  double get hitRate {
    final total = _preloadHits + _preloadMisses;
    return total > 0 ? _preloadHits / total : 0.0;
  }

  /// Analyze a chapter for preloading
  void analyzeChapter(CompiledChapter chapter) {
    final analysis = <String, NodeResourceAnalysis>{};

    for (final entry in chapter.nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value;

      final resources = _extractNodeResources(node);
      final nextNodes = _getNextNodes(node, chapter);
      final isChoice = node.type == 'choice';
      final isEnding = node.type == 'ending';

      analysis[nodeId] = NodeResourceAnalysis(
        nodeId: nodeId,
        resources: resources,
        nextNodeIds: nextNodes,
        isChoice: isChoice,
        isEnding: isEnding,
      );
    }

    _chapterAnalysis[chapter.id] = analysis;
  }

  /// Analyze all chapters in a bundle
  void analyzeBundle(VNStoryBundle bundle) {
    for (final chapter in bundle.chapters) {
      analyzeChapter(chapter);
    }
  }

  /// Predict resources needed from current position
  List<PredictedResource> predictResources(
    String chapterId,
    String currentNodeId,
  ) {
    if (_strategy == PreloadStrategy.disabled) return [];

    final analysis = _chapterAnalysis[chapterId];
    if (analysis == null) return [];

    final predictions = <PredictedResource>[];
    final visited = <String>{};

    _predictRecursive(
      analysis: analysis,
      nodeId: currentNodeId,
      depth: 0,
      probability: 1.0,
      predictions: predictions,
      visited: visited,
    );

    // Sort by probability and distance
    predictions.sort((a, b) {
      final probCompare = b.probability.compareTo(a.probability);
      if (probCompare != 0) return probCompare;
      return a.nodesAway.compareTo(b.nodesAway);
    });

    return predictions;
  }

  /// Trigger preloading based on current position
  Future<void> preloadFromPosition(
    String chapterId,
    String currentNodeId,
  ) async {
    if (_strategy == PreloadStrategy.disabled) return;

    final predictions = predictResources(chapterId, currentNodeId);

    // Filter based on strategy
    final toPreload = _filterByStrategy(predictions);

    // Preload resources
    final resources = toPreload
        .where((p) => !_loader.isLoaded(p.id) && !_preloading.contains(p.id))
        .map((p) => (id: p.id, path: p.path, type: p.type))
        .toList();

    for (final r in resources) {
      _preloading.add(r.id);
    }

    _loader.preloadResources(resources);
  }

  /// Record that a resource was used (for statistics)
  void recordResourceUse(String resourceId) {
    if (_preloading.contains(resourceId)) {
      _preloadHits++;
      _preloading.remove(resourceId);
    } else if (!_loader.isLoaded(resourceId)) {
      _preloadMisses++;
    }
  }

  /// Get preload statistics
  Map<String, dynamic> getStatistics() {
    return {
      'hits': _preloadHits,
      'misses': _preloadMisses,
      'hitRate': hitRate,
      'currentlyPreloading': _preloading.length,
      'strategy': _strategy.name,
      'lookAheadDepth': _lookAheadDepth,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _preloadHits = 0;
    _preloadMisses = 0;
    _preloading.clear();
  }

  void _predictRecursive({
    required Map<String, NodeResourceAnalysis> analysis,
    required String nodeId,
    required int depth,
    required double probability,
    required List<PredictedResource> predictions,
    required Set<String> visited,
  }) {
    if (depth > _lookAheadDepth) return;
    if (visited.contains(nodeId)) return;
    if (probability < 0.1) return; // Skip very unlikely paths

    visited.add(nodeId);

    final nodeAnalysis = analysis[nodeId];
    if (nodeAnalysis == null) return;

    // Add resources from this node
    for (final resource in nodeAnalysis.resources) {
      predictions.add(PredictedResource(
        id: resource.id,
        path: resource.path,
        type: resource.type,
        probability: probability,
        nodesAway: depth,
      ));
    }

    // Don't continue past endings
    if (nodeAnalysis.isEnding) return;

    // Calculate probability for next nodes
    final nextCount = nodeAnalysis.nextNodeIds.length;
    if (nextCount == 0) return;

    double nextProbability;
    if (nodeAnalysis.isChoice) {
      // For choices, distribute probability evenly
      nextProbability = probability / nextCount;
    } else {
      // For linear flow, maintain probability
      nextProbability = probability;
    }

    // Recurse into next nodes
    for (final nextId in nodeAnalysis.nextNodeIds) {
      _predictRecursive(
        analysis: analysis,
        nodeId: nextId,
        depth: depth + 1,
        probability: nextProbability,
        predictions: predictions,
        visited: visited,
      );
    }
  }

  List<PredictedResource> _filterByStrategy(List<PredictedResource> predictions) {
    switch (_strategy) {
      case PreloadStrategy.aggressive:
        // Preload everything with > 10% probability
        return predictions.where((p) => p.probability > 0.1).toList();

      case PreloadStrategy.conservative:
        // Only preload immediate next resources with > 50% probability
        return predictions
            .where((p) => p.nodesAway <= 2 && p.probability > 0.5)
            .toList();

      case PreloadStrategy.balanced:
        // Preload based on combined score
        return predictions.where((p) {
          final score = p.probability * (1.0 - (p.nodesAway / _lookAheadDepth));
          return score > 0.3;
        }).toList();

      case PreloadStrategy.disabled:
        return [];
    }
  }

  List<({String id, String path, ResourceLoadType type})> _extractNodeResources(
    CompiledNode node,
  ) {
    final resources = <({String id, String path, ResourceLoadType type})>[];

    switch (node.type) {
      case 'scene':
        final bg = node.data['background'] as String?;
        if (bg != null) {
          final entry = _manifest.getEntry(bg);
          if (entry != null) {
            resources.add((
              id: bg,
              path: entry.path,
              type: ResourceLoadType.background,
            ));
          }
        }

        final bgm = node.data['bgm'] as String?;
        if (bgm != null) {
          final entry = _manifest.getEntry(bgm);
          if (entry != null) {
            resources.add((
              id: bgm,
              path: entry.path,
              type: ResourceLoadType.bgm,
            ));
          }
        }

        final dialogues = node.data['dialogues'] as List<dynamic>?;
        if (dialogues != null) {
          for (final d in dialogues) {
            final voice = (d as Map<String, dynamic>)['voiceId'] as String?;
            if (voice != null) {
              final entry = _manifest.getEntry(voice);
              if (entry != null) {
                resources.add((
                  id: voice,
                  path: entry.path,
                  type: ResourceLoadType.voice,
                ));
              }
            }
          }
        }
        break;

      case 'background':
        final bgId = node.data['backgroundId'] as String?;
        if (bgId != null) {
          final entry = _manifest.getEntry(bgId);
          if (entry != null) {
            resources.add((
              id: bgId,
              path: entry.path,
              type: ResourceLoadType.background,
            ));
          }
        }
        break;

      case 'audio':
        final audioId = node.data['audioId'] as String?;
        final channel = node.data['channel'] as String?;
        if (audioId != null) {
          final entry = _manifest.getEntry(audioId);
          if (entry != null) {
            final type = switch (channel) {
              'bgm' || 'ambient' => ResourceLoadType.bgm,
              'sfx' => ResourceLoadType.sfx,
              'voice' => ResourceLoadType.voice,
              _ => ResourceLoadType.bgm,
            };
            resources.add((id: audioId, path: entry.path, type: type));
          }
        }
        break;

      case 'cg':
        final cgId = node.data['cgId'] as String?;
        if (cgId != null) {
          final entry = _manifest.getEntry(cgId);
          if (entry != null) {
            resources.add((
              id: cgId,
              path: entry.path,
              type: ResourceLoadType.cg,
            ));
          }
        }
        break;

      case 'video':
        final videoId = node.data['videoId'] as String?;
        if (videoId != null) {
          final entry = _manifest.getEntry(videoId);
          if (entry != null) {
            resources.add((
              id: videoId,
              path: entry.path,
              type: ResourceLoadType.video,
            ));
          }
        }
        break;
    }

    return resources;
  }

  List<String> _getNextNodes(CompiledNode node, CompiledChapter chapter) {
    final nextNodes = <String>[];

    switch (node.type) {
      case 'choice':
        final options = node.data['options'] as List<dynamic>?;
        if (options != null) {
          for (final opt in options) {
            final next = (opt as Map<String, dynamic>)['next'] as String?;
            if (next != null) nextNodes.add(next);
          }
        }
        break;

      case 'condition':
        final trueNode = node.data['trueNodeId'] as String?;
        final falseNode = node.data['falseNodeId'] as String?;
        if (trueNode != null) nextNodes.add(trueNode);
        if (falseNode != null) nextNodes.add(falseNode);
        break;

      case 'switch':
        final cases = node.data['cases'] as List<dynamic>?;
        if (cases != null) {
          for (final c in cases) {
            final target = (c as Map<String, dynamic>)['targetNodeId'] as String?;
            if (target != null) nextNodes.add(target);
          }
        }
        break;

      case 'jump':
        final targetNode = node.data['targetNodeId'] as String?;
        if (targetNode != null) nextNodes.add(targetNode);
        break;

      default:
        if (node.next != null) nextNodes.add(node.next!);
        break;
    }

    return nextNodes;
  }
}
