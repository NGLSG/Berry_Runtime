import 'chapter.dart';
import 'story_graph.dart';
import 'vn_node.dart';
import 'vn_character.dart';
import 'vn_resource.dart';
import 'vn_variable.dart';

/// Comprehensive validator for StoryGraph
/// 
/// Validates:
/// - Graph structure (orphan nodes, dead ends, reachability)
/// - Resource references (backgrounds, BGM, SFX, voices)
/// - Character references and expressions
/// - Variable references in conditions and operations
/// - Node connection compatibility
/// - Cross-chapter jump references
class StoryGraphValidator {
  final StoryGraph graph;
  final VNResourceLibrary? resources;
  final List<VNCharacter>? characters;
  final List<VNVariable>? variables;
  final List<Chapter>? allChapters;

  const StoryGraphValidator({
    required this.graph,
    this.resources,
    this.characters,
    this.variables,
    this.allChapters,
  });

  /// Run all validations and return combined errors
  List<ValidationError> validateAll() {
    final errors = <ValidationError>[];
    
    // Basic graph validation
    errors.addAll(validateGraphStructure());
    
    // Resource validation (if resources provided)
    if (resources != null) {
      errors.addAll(validateResourceReferences());
    }
    
    // Character validation (if characters provided)
    if (characters != null) {
      errors.addAll(validateCharacterReferences());
      errors.addAll(validateCharacterExpressions());
    }
    
    // Variable validation (if variables provided)
    if (variables != null) {
      errors.addAll(validateVariableReferences());
    }
    
    // Cross-chapter validation (if all chapters provided)
    if (allChapters != null) {
      errors.addAll(validateCrossChapterReferences());
    }
    
    return errors;
  }

  /// Validate basic graph structure
  List<ValidationError> validateGraphStructure() {
    final errors = <ValidationError>[];

    // Check for start node
    if (graph.startNodeId == null && graph.nodes.isNotEmpty) {
      errors.add(const ValidationError(
        code: 'NO_START_NODE',
        message: 'Story graph has no start node defined',
      ));
    } else if (graph.startNodeId != null && graph.getNode(graph.startNodeId!) == null) {
      errors.add(ValidationError(
        code: 'INVALID_START_NODE',
        message: 'Start node "${graph.startNodeId}" does not exist',
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
      final node = graph.getNode(nodeId);
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
    for (final edge in graph.edges) {
      if (graph.getNode(edge.sourceNodeId) == null) {
        errors.add(ValidationError(
          code: 'INVALID_EDGE_SOURCE',
          message: 'Edge references non-existent source node "${edge.sourceNodeId}"',
        ));
      }
      if (graph.getNode(edge.targetNodeId) == null) {
        errors.add(ValidationError(
          code: 'INVALID_EDGE_TARGET',
          message: 'Edge references non-existent target node "${edge.targetNodeId}"',
        ));
      }
    }

    // Validate node-specific connections
    errors.addAll(_validateNodeConnections());

    return errors;
  }

  /// Find nodes with no incoming edges (except start node)
  List<String> findOrphanNodes() {
    final orphans = <String>[];
    for (final node in graph.nodes) {
      if (node.id == graph.startNodeId) continue;
      if (node.type == VNNodeType.start) continue;
      
      final incoming = graph.getIncomingEdges(node.id);
      if (incoming.isEmpty) {
        orphans.add(node.id);
      }
    }
    return orphans;
  }

  /// Find nodes with no outgoing edges (except ending nodes)
  List<String> findDeadEnds() {
    final deadEnds = <String>[];
    for (final node in graph.nodes) {
      if (node.type == VNNodeType.ending) continue;
      
      // For choice nodes, check if all options have targets
      if (node is ChoiceNode) {
        final hasAllTargets = node.options.every((o) => o.targetNodeId != null);
        if (!hasAllTargets) {
          deadEnds.add(node.id);
        }
        continue;
      }
      
      // For condition nodes, check both branches
      if (node is ConditionNode) {
        if (node.trueNodeId == null || node.falseNodeId == null) {
          deadEnds.add(node.id);
        }
        continue;
      }
      
      // For jump nodes, check target
      if (node is JumpNode) {
        if (node.targetNodeId == null && node.targetChapterId == null) {
          deadEnds.add(node.id);
        }
        continue;
      }
      
      final outgoing = graph.getOutgoingEdges(node.id);
      if (outgoing.isEmpty) {
        deadEnds.add(node.id);
      }
    }
    return deadEnds;
  }

  /// Validate node-specific connection requirements
  List<ValidationError> _validateNodeConnections() {
    final errors = <ValidationError>[];
    
    for (final node in graph.nodes) {
      // Validate ChoiceNode options
      if (node is ChoiceNode) {
        for (final option in node.options) {
          if (option.targetNodeId != null && 
              graph.getNode(option.targetNodeId!) == null) {
            errors.add(ValidationError(
              code: 'INVALID_CHOICE_TARGET',
              message: 'Choice option "${option.text}" references non-existent node "${option.targetNodeId}"',
              nodeId: node.id,
            ));
          }
        }
      }
      
      // Validate ConditionNode branches
      if (node is ConditionNode) {
        if (node.trueNodeId != null && graph.getNode(node.trueNodeId!) == null) {
          errors.add(ValidationError(
            code: 'INVALID_CONDITION_TRUE_TARGET',
            message: 'Condition true branch references non-existent node "${node.trueNodeId}"',
            nodeId: node.id,
          ));
        }
        if (node.falseNodeId != null && graph.getNode(node.falseNodeId!) == null) {
          errors.add(ValidationError(
            code: 'INVALID_CONDITION_FALSE_TARGET',
            message: 'Condition false branch references non-existent node "${node.falseNodeId}"',
            nodeId: node.id,
          ));
        }
      }
      
      // Validate JumpNode target (within same chapter)
      if (node is JumpNode) {
        if (node.targetNodeId != null && 
            node.targetChapterId == null &&
            graph.getNode(node.targetNodeId!) == null) {
          errors.add(ValidationError(
            code: 'INVALID_JUMP_TARGET',
            message: 'Jump node references non-existent node "${node.targetNodeId}"',
            nodeId: node.id,
          ));
        }
      }
    }
    
    return errors;
  }

  /// Validate all resource references in the graph
  List<ValidationError> validateResourceReferences() {
    if (resources == null) return [];
    
    final errors = <ValidationError>[];
    
    for (final node in graph.nodes) {
      if (node is SceneNode) {
        // Validate background reference
        if (node.backgroundId != null && !resources!.hasBackground(node.backgroundId!)) {
          errors.add(ValidationError(
            code: 'MISSING_BACKGROUND',
            message: 'Scene references missing background "${node.backgroundId}"',
            nodeId: node.id,
          ));
        }
        
        // Validate BGM reference
        if (node.bgmId != null && !resources!.hasBgm(node.bgmId!)) {
          errors.add(ValidationError(
            code: 'MISSING_BGM',
            message: 'Scene references missing BGM "${node.bgmId}"',
            nodeId: node.id,
          ));
        }
        
        // Validate voice references in dialogues
        for (int i = 0; i < node.dialogues.length; i++) {
          final dialogue = node.dialogues[i];
          if (dialogue.voiceId != null && !resources!.hasVoice(dialogue.voiceId!)) {
            errors.add(ValidationError(
              code: 'MISSING_VOICE',
              message: 'Dialogue line ${i + 1} references missing voice "${dialogue.voiceId}"',
              nodeId: node.id,
            ));
          }
        }
      }
      
      if (node is AudioNode) {
        if (node.audioId != null) {
          final exists = switch (node.channel) {
            AudioChannel.bgm => resources!.hasBgm(node.audioId!),
            AudioChannel.sfx => resources!.hasSfx(node.audioId!),
            AudioChannel.voice => resources!.hasVoice(node.audioId!),
            AudioChannel.ambient => resources!.hasBgm(node.audioId!) || resources!.hasSfx(node.audioId!),
          };
          
          if (!exists) {
            errors.add(ValidationError(
              code: 'MISSING_AUDIO',
              message: 'Audio node references missing ${node.channel.name} "${node.audioId}"',
              nodeId: node.id,
            ));
          }
        }
      }
      
      if (node is EndingNode) {
        // Validate unlocked CG references
        for (final cgId in node.unlockedCGs) {
          if (!resources!.hasCg(cgId)) {
            errors.add(ValidationError(
              code: 'MISSING_CG',
              message: 'Ending references missing CG "$cgId"',
              nodeId: node.id,
            ));
          }
        }
      }
    }
    
    return errors;
  }

  /// Validate character references in the graph
  List<ValidationError> validateCharacterReferences() {
    if (characters == null) return [];
    
    final errors = <ValidationError>[];
    final characterIds = characters!.map((c) => c.id).toSet();
    
    for (final node in graph.nodes) {
      if (node is SceneNode) {
        // Validate character positions
        for (final charPos in node.characters) {
          if (!characterIds.contains(charPos.characterId)) {
            errors.add(ValidationError(
              code: 'MISSING_CHARACTER',
              message: 'Scene references missing character "${charPos.characterId}"',
              nodeId: node.id,
            ));
          }
        }
        
        // Validate dialogue speakers
        for (int i = 0; i < node.dialogues.length; i++) {
          final dialogue = node.dialogues[i];
          if (dialogue.speakerId != null && !characterIds.contains(dialogue.speakerId)) {
            errors.add(ValidationError(
              code: 'MISSING_SPEAKER',
              message: 'Dialogue line ${i + 1} references missing character "${dialogue.speakerId}"',
              nodeId: node.id,
            ));
          }
        }
      }
    }
    
    return errors;
  }

  /// Validate character expression references
  List<ValidationError> validateCharacterExpressions() {
    if (characters == null) return [];
    
    final errors = <ValidationError>[];
    final characterMap = {for (final c in characters!) c.id: c};
    
    for (final node in graph.nodes) {
      if (node is SceneNode) {
        // Validate character position expressions
        for (final charPos in node.characters) {
          final character = characterMap[charPos.characterId];
          if (character != null && charPos.expression != null) {
            if (!character.hasExpression(charPos.expression!)) {
              errors.add(ValidationError(
                code: 'INVALID_EXPRESSION',
                message: 'Character "${charPos.characterId}" does not have expression "${charPos.expression}"',
                nodeId: node.id,
                severity: ValidationSeverity.warning,
              ));
            }
          }
        }
        
        // Validate dialogue expressions
        for (int i = 0; i < node.dialogues.length; i++) {
          final dialogue = node.dialogues[i];
          if (dialogue.speakerId != null && dialogue.expression != null) {
            final character = characterMap[dialogue.speakerId];
            if (character != null && !character.hasExpression(dialogue.expression!)) {
              errors.add(ValidationError(
                code: 'INVALID_DIALOGUE_EXPRESSION',
                message: 'Dialogue line ${i + 1}: character "${dialogue.speakerId}" does not have expression "${dialogue.expression}"',
                nodeId: node.id,
                severity: ValidationSeverity.warning,
              ));
            }
          }
        }
      }
    }
    
    return errors;
  }

  /// Validate variable references in conditions and operations
  List<ValidationError> validateVariableReferences() {
    if (variables == null) return [];
    
    final errors = <ValidationError>[];
    final variableNames = variables!.map((v) => v.name).toSet();
    
    for (final node in graph.nodes) {
      // Validate VariableNode references
      if (node is VariableNode) {
        if (!variableNames.contains(node.variableName)) {
          errors.add(ValidationError(
            code: 'UNDEFINED_VARIABLE',
            message: 'Variable node references undefined variable "${node.variableName}"',
            nodeId: node.id,
          ));
        }
      }
      
      // Validate ConditionNode expressions
      if (node is ConditionNode) {
        final referencedVars = _extractVariablesFromExpression(node.expression);
        for (final varName in referencedVars) {
          if (!variableNames.contains(varName)) {
            errors.add(ValidationError(
              code: 'UNDEFINED_CONDITION_VARIABLE',
              message: 'Condition references undefined variable "$varName"',
              nodeId: node.id,
            ));
          }
        }
      }
      
      // Validate ChoiceNode option conditions
      if (node is ChoiceNode) {
        for (final option in node.options) {
          if (option.condition != null) {
            final referencedVars = _extractVariablesFromExpression(option.condition!);
            for (final varName in referencedVars) {
              if (!variableNames.contains(varName)) {
                errors.add(ValidationError(
                  code: 'UNDEFINED_CHOICE_CONDITION_VARIABLE',
                  message: 'Choice option "${option.text}" condition references undefined variable "$varName"',
                  nodeId: node.id,
                ));
              }
            }
          }
        }
      }
      
      // Validate text macro variable references in dialogues
      if (node is SceneNode) {
        for (int i = 0; i < node.dialogues.length; i++) {
          final dialogue = node.dialogues[i];
          final referencedVars = _extractVariablesFromText(dialogue.text);
          for (final varName in referencedVars) {
            if (!variableNames.contains(varName)) {
              errors.add(ValidationError(
                code: 'UNDEFINED_TEXT_VARIABLE',
                message: 'Dialogue line ${i + 1} references undefined variable "$varName"',
                nodeId: node.id,
                severity: ValidationSeverity.warning,
              ));
            }
          }
        }
      }
    }
    
    return errors;
  }

  /// Extract variable names from a condition expression
  Set<String> _extractVariablesFromExpression(String expression) {
    final variables = <String>{};
    
    // Simple regex to find potential variable names
    // Matches identifiers that are not keywords or literals
    final identifierPattern = RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\b');
    final keywords = {'true', 'false', 'and', 'or', 'not', 'contains', 'startsWith', 'endsWith'};
    
    for (final match in identifierPattern.allMatches(expression)) {
      final name = match.group(1)!;
      if (!keywords.contains(name.toLowerCase())) {
        // Check if it's not a number
        if (num.tryParse(name) == null) {
          variables.add(name);
        }
      }
    }
    
    return variables;
  }

  /// Extract variable names from text macros (e.g., {player_name})
  Set<String> _extractVariablesFromText(String text) {
    final variables = <String>{};
    
    // Match {variable_name} patterns
    final macroPattern = RegExp(r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}');
    
    for (final match in macroPattern.allMatches(text)) {
      variables.add(match.group(1)!);
    }
    
    return variables;
  }

  /// Validate cross-chapter jump references
  List<ValidationError> validateCrossChapterReferences() {
    if (allChapters == null) return [];
    
    final errors = <ValidationError>[];
    final chapterIds = allChapters!.map((c) => c.id).toSet();
    final chapterMap = {for (final c in allChapters!) c.id: c};
    
    for (final node in graph.nodes) {
      if (node is JumpNode) {
        // Validate cross-chapter jump
        if (node.targetChapterId != null && node.targetChapterId!.isNotEmpty) {
          // Check if target chapter exists
          if (!chapterIds.contains(node.targetChapterId)) {
            errors.add(ValidationError(
              code: 'INVALID_CHAPTER_REFERENCE',
              message: 'Jump node references non-existent chapter "${node.targetChapterId}"',
              nodeId: node.id,
            ));
          } else {
            // Check if target node exists in target chapter
            final targetChapter = chapterMap[node.targetChapterId];
            if (targetChapter != null && node.targetNodeId != null) {
              final targetNode = targetChapter.graph.getNode(node.targetNodeId!);
              if (targetNode == null) {
                errors.add(ValidationError(
                  code: 'INVALID_CROSS_CHAPTER_NODE',
                  message: 'Jump node references non-existent node "${node.targetNodeId}" in chapter "${targetChapter.title}"',
                  nodeId: node.id,
                ));
              }
            }
            
            // Warn if jumping to a draft chapter
            if (targetChapter != null && targetChapter.isDraft) {
              errors.add(ValidationError(
                code: 'JUMP_TO_DRAFT_CHAPTER',
                message: 'Jump node targets draft chapter "${targetChapter.title}" which will be excluded from release builds',
                nodeId: node.id,
                severity: ValidationSeverity.warning,
              ));
            }
          }
        }
      }
    }
    
    return errors;
  }

  /// Validate a specific cross-chapter jump
  /// Returns null if valid, or an error message if invalid
  static String? validateCrossChapterJump({
    required String? targetChapterId,
    required String? targetNodeId,
    required List<Chapter> chapters,
  }) {
    if (targetChapterId == null || targetChapterId.isEmpty) {
      return null; // Not a cross-chapter jump
    }
    
    final targetChapter = chapters.where((c) => c.id == targetChapterId).firstOrNull;
    if (targetChapter == null) {
      return 'Target chapter does not exist';
    }
    
    if (targetNodeId == null || targetNodeId.isEmpty) {
      return 'No target node specified';
    }
    
    final targetNode = targetChapter.graph.getNode(targetNodeId);
    if (targetNode == null) {
      return 'Target node does not exist in chapter "${targetChapter.title}"';
    }
    
    return null; // Valid
  }

  /// Check if all paths from start eventually lead to an ending
  bool allPathsLeadToEndings() {
    if (graph.startNodeId == null) return graph.nodes.isEmpty;
    
    // Use DFS to check all paths
    final visited = <String>{};
    final pathStack = <String>[];
    
    return _checkPathsToEnding(graph.startNodeId!, visited, pathStack);
  }

  bool _checkPathsToEnding(String nodeId, Set<String> visited, List<String> pathStack) {
    // Cycle detection
    if (pathStack.contains(nodeId)) {
      // Found a cycle - this is okay as long as there's another path to ending
      return true;
    }
    
    if (visited.contains(nodeId)) {
      return true; // Already verified this node leads to ending
    }
    
    final node = graph.getNode(nodeId);
    if (node == null) return false;
    
    // Ending node - valid path
    if (node.type == VNNodeType.ending) {
      visited.add(nodeId);
      return true;
    }
    
    pathStack.add(nodeId);
    
    // Get all possible next nodes
    final nextNodes = _getNextNodes(node);
    
    if (nextNodes.isEmpty) {
      pathStack.removeLast();
      return false; // Dead end that's not an ending
    }
    
    // All branches must eventually lead to endings
    for (final nextId in nextNodes) {
      if (!_checkPathsToEnding(nextId, visited, pathStack)) {
        pathStack.removeLast();
        return false;
      }
    }
    
    pathStack.removeLast();
    visited.add(nodeId);
    return true;
  }

  /// Get all possible next node IDs from a node
  List<String> _getNextNodes(VNNode node) {
    final nextNodes = <String>[];
    
    if (node is ChoiceNode) {
      for (final option in node.options) {
        if (option.targetNodeId != null) {
          nextNodes.add(option.targetNodeId!);
        }
      }
    } else if (node is ConditionNode) {
      if (node.trueNodeId != null) nextNodes.add(node.trueNodeId!);
      if (node.falseNodeId != null) nextNodes.add(node.falseNodeId!);
    } else if (node is JumpNode) {
      if (node.targetNodeId != null && node.targetChapterId == null) {
        nextNodes.add(node.targetNodeId!);
      }
      // Cross-chapter jumps are considered valid endpoints for this check
      if (node.targetChapterId != null) {
        return ['__cross_chapter__']; // Placeholder to indicate valid path
      }
    } else {
      // For other nodes, use edges
      for (final edge in graph.getOutgoingEdges(node.id)) {
        nextNodes.add(edge.targetNodeId);
      }
    }
    
    return nextNodes;
  }

  /// Validate connection compatibility between two node types
  static ValidationError? validateConnection(
    VNNode sourceNode,
    VNNode targetNode, {
    String? sourcePort,
    String? targetPort,
  }) {
    // Define connection rules
    final rules = _connectionRules[sourceNode.type];
    if (rules == null) {
      return ValidationError(
        code: 'INVALID_SOURCE_TYPE',
        message: 'Node type ${sourceNode.type.name} cannot have outgoing connections',
        nodeId: sourceNode.id,
      );
    }
    
    if (!rules.contains(targetNode.type)) {
      return ValidationError(
        code: 'INCOMPATIBLE_CONNECTION',
        message: 'Cannot connect ${sourceNode.type.name} to ${targetNode.type.name}',
        nodeId: sourceNode.id,
      );
    }
    
    // Ending nodes cannot have outgoing connections
    if (sourceNode.type == VNNodeType.ending) {
      return ValidationError(
        code: 'ENDING_HAS_OUTPUT',
        message: 'Ending nodes cannot have outgoing connections',
        nodeId: sourceNode.id,
      );
    }
    
    // Start nodes cannot have incoming connections
    if (targetNode.type == VNNodeType.start) {
      return ValidationError(
        code: 'START_HAS_INPUT',
        message: 'Start nodes cannot have incoming connections',
        nodeId: targetNode.id,
      );
    }
    
    return null; // Connection is valid
  }

  /// Connection compatibility rules
  /// Maps source node type to allowed target node types
  static const Map<VNNodeType, Set<VNNodeType>> _connectionRules = {
    // All connectable target types (excluding start which can't receive connections)
    VNNodeType.start: _allConnectableTargets,
    VNNodeType.scene: _allConnectableTargets,
    VNNodeType.choice: _allConnectableTargets,
    VNNodeType.condition: _allConnectableTargets,
    VNNodeType.switch_: _allConnectableTargets,
    VNNodeType.variable: _allConnectableTargets,
    VNNodeType.effect: _allConnectableTargets,
    VNNodeType.audio: _allConnectableTargets,
    VNNodeType.background: _allConnectableTargets,
    VNNodeType.character: _allConnectableTargets,
    VNNodeType.wait: _allConnectableTargets,
    VNNodeType.label: _allConnectableTargets,
    VNNodeType.input: _allConnectableTargets,
    VNNodeType.cg: _allConnectableTargets,
    VNNodeType.video: _allConnectableTargets,
    VNNodeType.achievement: _allConnectableTargets,
    VNNodeType.particle: _allConnectableTargets,
    VNNodeType.affection: _allConnectableTargets,
    VNNodeType.journal: _allConnectableTargets,
    VNNodeType.minigame: _allConnectableTargets,
    VNNodeType.script: _allConnectableTargets,
    VNNodeType.jump: {}, // Jump nodes don't have outgoing edges (they jump)
    VNNodeType.ending: {}, // Ending nodes have no outgoing connections
  };

  /// All node types that can be connected to (everything except start)
  static const Set<VNNodeType> _allConnectableTargets = {
    VNNodeType.scene,
    VNNodeType.choice,
    VNNodeType.condition,
    VNNodeType.switch_,
    VNNodeType.variable,
    VNNodeType.effect,
    VNNodeType.audio,
    VNNodeType.jump,
    VNNodeType.ending,
    VNNodeType.background,
    VNNodeType.character,
    VNNodeType.wait,
    VNNodeType.label,
    VNNodeType.input,
    VNNodeType.cg,
    VNNodeType.video,
    VNNodeType.achievement,
    VNNodeType.particle,
    VNNodeType.affection,
    VNNodeType.journal,
    VNNodeType.minigame,
    VNNodeType.script,
  };
}
