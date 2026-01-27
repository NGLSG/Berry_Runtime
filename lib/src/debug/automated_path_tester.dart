/// Automated Path Tester for VN Runtime
/// 
/// Provides automated testing capabilities:
/// - Automatic traversal of all story branches
/// - Path enumeration and testing
/// - Coverage-guided exploration
/// - Test result reporting

import 'dart:async';

import '../vn_engine.dart';
import '../vn_engine_state.dart';
import '../../compiler/vn_story_bundle.dart';
import 'branch_coverage_analyzer.dart';

/// Result of a single path test
class PathTestResult {
  /// Path identifier
  final String pathId;
  
  /// Sequence of nodes visited
  final List<String> nodeSequence;
  
  /// Sequence of choices made
  final List<PathChoice> choicesMade;
  
  /// Whether the path completed successfully
  final bool success;
  
  /// Error message if failed
  final String? errorMessage;
  
  /// Ending reached (if any)
  final String? endingId;
  
  /// Execution time
  final Duration executionTime;
  
  /// Variables at end of path
  final Map<String, dynamic> finalVariables;

  const PathTestResult({
    required this.pathId,
    required this.nodeSequence,
    required this.choicesMade,
    required this.success,
    this.errorMessage,
    this.endingId,
    required this.executionTime,
    required this.finalVariables,
  });

  Map<String, dynamic> toJson() => {
    'pathId': pathId,
    'nodeSequence': nodeSequence,
    'choicesMade': choicesMade.map((c) => c.toJson()).toList(),
    'success': success,
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (endingId != null) 'endingId': endingId,
    'executionTimeMs': executionTime.inMilliseconds,
    'finalVariables': finalVariables,
  };
}

/// A choice made during path testing
class PathChoice {
  /// Node ID where choice was made
  final String nodeId;
  
  /// Chapter ID
  final String chapterId;
  
  /// Selected option index
  final int optionIndex;
  
  /// Option text
  final String optionText;

  const PathChoice({
    required this.nodeId,
    required this.chapterId,
    required this.optionIndex,
    required this.optionText,
  });

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'chapterId': chapterId,
    'optionIndex': optionIndex,
    'optionText': optionText,
  };
}

/// Full test run result
class AutomatedTestResult {
  /// All path results
  final List<PathTestResult> pathResults;
  
  /// Total paths tested
  final int totalPaths;
  
  /// Successful paths
  final int successfulPaths;
  
  /// Failed paths
  final int failedPaths;
  
  /// Unique endings reached
  final Set<String> endingsReached;
  
  /// Coverage report
  final CoverageReport? coverageReport;
  
  /// Total execution time
  final Duration totalExecutionTime;
  
  /// Test run timestamp
  final DateTime timestamp;

  const AutomatedTestResult({
    required this.pathResults,
    required this.totalPaths,
    required this.successfulPaths,
    required this.failedPaths,
    required this.endingsReached,
    this.coverageReport,
    required this.totalExecutionTime,
    required this.timestamp,
  });

  /// Success rate (0.0 - 1.0)
  double get successRate => totalPaths > 0 ? successfulPaths / totalPaths : 0.0;

  Map<String, dynamic> toJson() => {
    'totalPaths': totalPaths,
    'successfulPaths': successfulPaths,
    'failedPaths': failedPaths,
    'successRate': successRate,
    'endingsReached': endingsReached.toList(),
    'totalExecutionTimeMs': totalExecutionTime.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'pathResults': pathResults.map((r) => r.toJson()).toList(),
    if (coverageReport != null) 'coverage': coverageReport!.toJson(),
  };
}

/// Configuration for automated testing
class AutomatedTestConfig {
  /// Maximum paths to test (0 = unlimited)
  final int maxPaths;
  
  /// Maximum iterations per path
  final int maxIterationsPerPath;
  
  /// Whether to stop on first error
  final bool stopOnError;
  
  /// Whether to test all choice combinations
  final bool exhaustiveChoiceTesting;
  
  /// Delay between steps (for UI updates)
  final Duration stepDelay;
  
  /// Whether to reset variables between paths
  final bool resetVariablesBetweenPaths;

  const AutomatedTestConfig({
    this.maxPaths = 0,
    this.maxIterationsPerPath = 10000,
    this.stopOnError = false,
    this.exhaustiveChoiceTesting = true,
    this.stepDelay = Duration.zero,
    this.resetVariablesBetweenPaths = true,
  });
}

/// Progress callback for automated testing
typedef TestProgressCallback = void Function(
  int currentPath,
  int totalPaths,
  String currentNodeId,
  String status,
);

/// Automated path tester
class AutomatedPathTester {
  /// The story bundle to test
  final VNStoryBundle _bundle;
  
  /// Coverage analyzer
  final BranchCoverageAnalyzer _coverageAnalyzer = BranchCoverageAnalyzer();
  
  /// Test configuration
  AutomatedTestConfig _config;
  
  /// Whether testing is in progress
  bool _isRunning = false;
  
  /// Whether testing should be cancelled
  bool _shouldCancel = false;
  
  /// Progress callback
  TestProgressCallback? onProgress;
  
  /// Path completed callback
  void Function(PathTestResult result)? onPathCompleted;

  AutomatedPathTester(this._bundle, {AutomatedTestConfig? config})
      : _config = config ?? const AutomatedTestConfig();

  /// Update test configuration
  void updateConfig(AutomatedTestConfig config) {
    _config = config;
  }

  /// Check if testing is running
  bool get isRunning => _isRunning;

  /// Get coverage analyzer
  BranchCoverageAnalyzer get coverageAnalyzer => _coverageAnalyzer;

  /// Cancel ongoing test
  void cancel() {
    _shouldCancel = true;
  }

  /// Run automated path testing
  /// 
  /// This method explores all possible paths through the story by:
  /// 1. Starting from the beginning
  /// 2. At each choice, trying all options
  /// 3. Recording the path taken and result
  Future<AutomatedTestResult> runAutomatedTest({
    String? startChapterId,
  }) async {
    _isRunning = true;
    _shouldCancel = false;
    _coverageAnalyzer.reset();

    final startTime = DateTime.now();
    final pathResults = <PathTestResult>[];
    final endingsReached = <String>{};

    try {
      // Generate all paths to test
      final paths = _generateTestPaths(startChapterId);
      final totalPaths = _config.maxPaths > 0 
          ? paths.length.clamp(0, _config.maxPaths)
          : paths.length;

      for (int i = 0; i < totalPaths && !_shouldCancel; i++) {
        final path = paths[i];
        
        onProgress?.call(i + 1, totalPaths, 'Starting path ${i + 1}', 'running');
        
        final result = await _testPath(path, i);
        pathResults.add(result);
        
        if (result.endingId != null) {
          endingsReached.add(result.endingId!);
        }
        
        onPathCompleted?.call(result);
        
        if (!result.success && _config.stopOnError) {
          break;
        }
      }

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);

      return AutomatedTestResult(
        pathResults: pathResults,
        totalPaths: pathResults.length,
        successfulPaths: pathResults.where((r) => r.success).length,
        failedPaths: pathResults.where((r) => !r.success).length,
        endingsReached: endingsReached,
        coverageReport: _coverageAnalyzer.generateReport(_bundle.chapters),
        totalExecutionTime: totalTime,
        timestamp: startTime,
      );
    } finally {
      _isRunning = false;
    }
  }

  /// Test a single specific path
  Future<PathTestResult> testSpecificPath(List<int> choiceSequence, {
    String? startChapterId,
  }) async {
    final path = TestPath(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      choiceSequence: choiceSequence,
    );
    return _testPath(path, 0);
  }

  /// Generate all possible test paths
  List<TestPath> _generateTestPaths(String? startChapterId) {
    final paths = <TestPath>[];
    
    if (_config.exhaustiveChoiceTesting) {
      // Generate all combinations of choices
      _generateExhaustivePaths(paths, startChapterId);
    } else {
      // Generate paths that maximize coverage
      _generateCoverageGuidedPaths(paths, startChapterId);
    }
    
    return paths;
  }

  /// Generate exhaustive paths (all choice combinations)
  void _generateExhaustivePaths(List<TestPath> paths, String? startChapterId) {
    final chapterId = startChapterId ?? _bundle.chapters.first.id;
    final chapter = _bundle.getChapter(chapterId);
    if (chapter == null) return;

    // Find all choice nodes and their option counts
    final choiceNodes = <String, int>{};
    for (final entry in chapter.nodes.entries) {
      final node = entry.value;
      if (node.type == 'choice') {
        final options = node.data['options'] as List<dynamic>?;
        if (options != null && options.isNotEmpty) {
          choiceNodes[entry.key] = options.length;
        }
      }
    }

    if (choiceNodes.isEmpty) {
      // No choices, single path
      paths.add(TestPath(id: 'path_0', choiceSequence: []));
      return;
    }

    // Generate all combinations
    final combinations = _generateChoiceCombinations(choiceNodes.values.toList());
    
    for (int i = 0; i < combinations.length; i++) {
      paths.add(TestPath(
        id: 'path_$i',
        choiceSequence: combinations[i],
      ));
    }
  }

  /// Generate all combinations of choices
  List<List<int>> _generateChoiceCombinations(List<int> optionCounts) {
    if (optionCounts.isEmpty) return [[]];
    
    final combinations = <List<int>>[];
    
    void generate(int index, List<int> current) {
      if (index >= optionCounts.length) {
        combinations.add(List.from(current));
        return;
      }
      
      for (int i = 0; i < optionCounts[index]; i++) {
        current.add(i);
        generate(index + 1, current);
        current.removeLast();
      }
    }
    
    generate(0, []);
    return combinations;
  }

  /// Generate coverage-guided paths
  void _generateCoverageGuidedPaths(List<TestPath> paths, String? startChapterId) {
    // Start with a default path (always choose first option)
    paths.add(TestPath(id: 'path_default', choiceSequence: []));
    
    // Add paths that explore different branches
    final chapterId = startChapterId ?? _bundle.chapters.first.id;
    final chapter = _bundle.getChapter(chapterId);
    if (chapter == null) return;

    // Find choice nodes
    int choiceCount = 0;
    for (final entry in chapter.nodes.entries) {
      final node = entry.value;
      if (node.type == 'choice') {
        choiceCount++;
        final options = node.data['options'] as List<dynamic>?;
        if (options != null) {
          // Add a path for each non-first option
          for (int i = 1; i < options.length; i++) {
            final sequence = List.filled(choiceCount - 1, 0);
            sequence.add(i);
            paths.add(TestPath(
              id: 'path_choice${choiceCount}_opt$i',
              choiceSequence: sequence,
            ));
          }
        }
      }
    }
  }

  /// Test a single path
  Future<PathTestResult> _testPath(TestPath path, int pathIndex) async {
    final startTime = DateTime.now();
    final nodeSequence = <String>[];
    final choicesMade = <PathChoice>[];
    int choiceIndex = 0;

    // Create a fresh engine for this path
    final engine = VNEngine(_bundle);
    engine.debugApi.enableDebug();

    try {
      // Start the engine
      await engine.start();

      int iterations = 0;
      while (iterations < _config.maxIterationsPerPath && !_shouldCancel) {
        iterations++;

        final position = engine.state.position;
        if (position == null) break;

        // Record node visit
        nodeSequence.add('${position.chapterId}:${position.nodeId}');
        _coverageAnalyzer.recordNodeVisit(position.chapterId, position.nodeId);

        onProgress?.call(
          pathIndex + 1,
          0,
          position.nodeId,
          'Node ${nodeSequence.length}',
        );

        // Check for ending
        if (engine.state.playbackState == VNPlaybackState.ended) {
          final chapter = _bundle.getChapter(position.chapterId);
          final node = chapter?.nodes[position.nodeId];
          String? endingId;
          if (node?.type == 'ending') {
            endingId = position.nodeId;
          }

          return PathTestResult(
            pathId: path.id,
            nodeSequence: nodeSequence,
            choicesMade: choicesMade,
            success: true,
            endingId: endingId,
            executionTime: DateTime.now().difference(startTime),
            finalVariables: Map.from(engine.variables),
          );
        }

        // Check for error
        if (engine.state.playbackState == VNPlaybackState.error) {
          return PathTestResult(
            pathId: path.id,
            nodeSequence: nodeSequence,
            choicesMade: choicesMade,
            success: false,
            errorMessage: engine.state.errorMessage,
            executionTime: DateTime.now().difference(startTime),
            finalVariables: Map.from(engine.variables),
          );
        }

        // Handle choices
        if (engine.currentChoices != null && engine.currentChoices!.isNotEmpty) {
          final choices = engine.currentChoices!;
          final optionIndex = choiceIndex < path.choiceSequence.length
              ? path.choiceSequence[choiceIndex] % choices.length
              : 0;

          choicesMade.add(PathChoice(
            nodeId: position.nodeId,
            chapterId: position.chapterId,
            optionIndex: optionIndex,
            optionText: choices[optionIndex].text,
          ));

          _coverageAnalyzer.recordChoiceSelection(
            position.chapterId,
            position.nodeId,
            optionIndex.toString(),
          );

          await engine.selectChoice(optionIndex);
          choiceIndex++;
        } else if (engine.state.playbackState == VNPlaybackState.waitingForInput) {
          // Advance dialogue
          await engine.advance();
        } else {
          // Small delay
          if (_config.stepDelay > Duration.zero) {
            await Future.delayed(_config.stepDelay);
          }
        }
      }

      // Max iterations reached
      return PathTestResult(
        pathId: path.id,
        nodeSequence: nodeSequence,
        choicesMade: choicesMade,
        success: false,
        errorMessage: 'Max iterations reached ($iterations)',
        executionTime: DateTime.now().difference(startTime),
        finalVariables: Map.from(engine.variables),
      );
    } catch (e) {
      return PathTestResult(
        pathId: path.id,
        nodeSequence: nodeSequence,
        choicesMade: choicesMade,
        success: false,
        errorMessage: 'Exception: $e',
        executionTime: DateTime.now().difference(startTime),
        finalVariables: {},
      );
    } finally {
      engine.dispose();
    }
  }
}

/// A test path definition
class TestPath {
  /// Path identifier
  final String id;
  
  /// Sequence of choice indices to make
  final List<int> choiceSequence;

  const TestPath({
    required this.id,
    required this.choiceSequence,
  });
}
