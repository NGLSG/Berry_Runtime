/// Node Executor for VN Runtime
/// 
/// Handles execution of different node types in the story graph.

import 'package:flutter/foundation.dart';

import '../compiler/condition_precompiler.dart';
import '../compiler/vn_story_bundle.dart';
import '../models/vn_variable.dart';
import '../models/vn_node.dart' show VariableOperation;
import 'variable_manager.dart';
import 'vn_engine_state.dart';
import 'scripting/scripting.dart';

/// Result of executing a node
class NodeExecutionResult {
  /// Whether execution was successful
  final bool success;
  
  /// Next node ID to execute (null if waiting for input or ended)
  final String? nextNodeId;
  
  /// Whether to wait for user input before continuing
  final bool waitForInput;
  
  /// Updated engine state
  final VNEngineState? updatedState;
  
  /// Error message if execution failed
  final String? errorMessage;
  
  /// Available choices (for choice nodes)
  final List<ChoiceExecutionOption>? choices;
  
  /// Current dialogue to display (for scene nodes)
  final DialogueExecutionData? dialogue;
  
  /// Effect to apply (for effect nodes)
  final EffectExecutionData? effect;
  
  /// Audio action to perform (for audio nodes)
  final AudioExecutionData? audio;
  
  /// Ending data (for ending nodes)
  final EndingExecutionData? ending;
  
  /// Whether this is a chapter jump
  final bool isChapterJump;
  
  /// Target chapter ID for chapter jumps
  final String? targetChapterId;
  
  /// Background ID to set (for scene/background nodes)
  final String? backgroundId;

  /// Character display update (for character nodes)
  final CharacterDisplayUpdate? characterUpdate;

  const NodeExecutionResult({
    this.success = true,
    this.nextNodeId,
    this.waitForInput = false,
    this.updatedState,
    this.errorMessage,
    this.choices,
    this.dialogue,
    this.effect,
    this.audio,
    this.ending,
    this.isChapterJump = false,
    this.targetChapterId,
    this.backgroundId,
    this.characterUpdate,
  });

  factory NodeExecutionResult.error(String message) {
    return NodeExecutionResult(
      success: false,
      errorMessage: message,
    );
  }

  factory NodeExecutionResult.waitForChoice(List<ChoiceExecutionOption> choices) {
    return NodeExecutionResult(
      success: true,
      waitForInput: true,
      choices: choices,
    );
  }

  factory NodeExecutionResult.showDialogue(DialogueExecutionData dialogue, {String? nextNodeId}) {
    return NodeExecutionResult(
      success: true,
      waitForInput: true,
      dialogue: dialogue,
      nextNodeId: nextNodeId,
    );
  }

  factory NodeExecutionResult.next(String nextNodeId, {VNEngineState? updatedState}) {
    return NodeExecutionResult(
      success: true,
      nextNodeId: nextNodeId,
      updatedState: updatedState,
    );
  }

  factory NodeExecutionResult.end(EndingExecutionData ending) {
    return NodeExecutionResult(
      success: true,
      waitForInput: false,
      ending: ending,
    );
  }

  factory NodeExecutionResult.jumpToChapter(String chapterId, String nodeId) {
    return NodeExecutionResult(
      success: true,
      isChapterJump: true,
      targetChapterId: chapterId,
      nextNodeId: nodeId,
    );
  }
}

/// Choice option for execution
class ChoiceExecutionOption {
  final String id;
  final String text;
  final String? targetNodeId;
  final bool isEnabled;
  final String? disabledReason;

  const ChoiceExecutionOption({
    required this.id,
    required this.text,
    this.targetNodeId,
    this.isEnabled = true,
    this.disabledReason,
  });
}

/// Dialogue data for execution
class DialogueExecutionData {
  final String? speakerId;
  final String? speakerName;
  final String? expression;
  final String text;
  final String? voiceId;
  final int dialogueIndex;
  final int totalDialogues;
  final bool isLastDialogue;

  /// Character position slot for this dialogue line
  final String? characterSlot;
  /// Custom X position (0.0 - 1.0)
  final double? characterX;
  /// Custom Y position (0.0 - 1.0)
  final double? characterY;
  /// Character scale
  final double? characterScale;
  /// Whether to flip character horizontally
  final bool? characterFlipped;

  const DialogueExecutionData({
    this.speakerId,
    this.speakerName,
    this.expression,
    required this.text,
    this.voiceId,
    required this.dialogueIndex,
    required this.totalDialogues,
    required this.isLastDialogue,
    this.characterSlot,
    this.characterX,
    this.characterY,
    this.characterScale,
    this.characterFlipped,
  });
}

/// Character display update for execution
class CharacterDisplayUpdate {
  final String characterId;
  final String action; // 'show', 'hide', 'move', 'expression'
  final String? slot; // 'left', 'center', 'right', 'custom'
  final String? expression;
  final double? customX;
  final double? customY;
  final double? scale;
  final bool? flipped;

  const CharacterDisplayUpdate({
    required this.characterId,
    required this.action,
    this.slot,
    this.expression,
    this.customX,
    this.customY,
    this.scale,
    this.flipped,
  });
}

/// Effect data for execution
class EffectExecutionData {
  final String effectType;
  final double duration;
  final double intensity;
  final Map<String, dynamic> params;

  const EffectExecutionData({
    required this.effectType,
    required this.duration,
    required this.intensity,
    this.params = const {},
  });
}

/// Audio data for execution
class AudioExecutionData {
  final String? audioId;
  final String channel;
  final String action;
  final double volume;
  final double? fadeDuration;
  final bool loop;

  const AudioExecutionData({
    this.audioId,
    required this.channel,
    required this.action,
    required this.volume,
    this.fadeDuration,
    required this.loop,
  });
}

/// Ending data for execution
class EndingExecutionData {
  final String endingId;
  final String endingName;
  final String endingType;
  final bool unlocksGallery;
  final List<String> unlockedCGs;

  const EndingExecutionData({
    required this.endingId,
    required this.endingName,
    required this.endingType,
    required this.unlocksGallery,
    required this.unlockedCGs,
  });
}

/// Executes nodes in the story graph
class NodeExecutor {
  final VNStoryBundle _bundle;
  final VariableManager _variableManager;
  
  /// Current dialogue index within a scene node
  int _currentDialogueIndex = 0;

  NodeExecutor(this._bundle, this._variableManager);

  /// Execute a node and return the result
  NodeExecutionResult execute(
    CompiledNode node,
    String nodeId,
    String chapterId, {
    int? dialogueIndex,
  }) {
    if (dialogueIndex != null) {
      _currentDialogueIndex = dialogueIndex;
    }

    switch (node.type) {
      case 'start':
        return _executeStart(node);
      case 'scene':
        return _executeScene(node, nodeId, chapterId);
      case 'choice':
        return _executeChoice(node, nodeId);
      case 'jump':
        return _executeJump(node);
      case 'condition':
        return _executeCondition(node, nodeId);
      case 'switch':
        return _executeSwitch(node, nodeId);
      case 'variable':
        return _executeVariable(node);
      case 'effect':
        return _executeEffect(node);
      case 'audio':
        return _executeAudio(node);
      case 'ending':
        return _executeEnding(node);
      case 'script':
        return _executeScript(node);
      case 'achievement':
        return _executeAchievement(node);
      case 'particle':
        return _executeParticle(node);
      case 'affection':
        return _executeAffection(node);
      case 'journal':
        return _executeJournal(node);
      case 'minigame':
        return _executeMinigame(node);
      case 'background':
        return _executeBackground(node);
      case 'character':
        return _executeCharacter(node);
      case 'wait':
        return _executeWait(node);
      case 'label':
        return _executeLabel(node);
      case 'input':
        return _executeInput(node);
      case 'cg':
        return _executeCG(node);
      case 'video':
        return _executeVideo(node);
      default:
        return NodeExecutionResult.error('Unknown node type: ${node.type}');
    }
  }

  /// Execute start node
  NodeExecutionResult _executeStart(CompiledNode node) {
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return NodeExecutionResult.error('Start node has no next node');
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute scene node (dialogue sequence)
  NodeExecutionResult _executeScene(CompiledNode node, String nodeId, String chapterId) {
    final dialogues = node.data['dialogues'] as List<dynamic>? ?? [];
    final backgroundId = node.data['background'] as String?;
    
    if (dialogues.isEmpty) {
      // No dialogues, move to next node
      return NodeExecutionResult(
        success: true,
        nextNodeId: node.next ?? '',
        backgroundId: backgroundId,
      );
    }

    if (_currentDialogueIndex >= dialogues.length) {
      // All dialogues shown, move to next node
      _currentDialogueIndex = 0;
      final nextNodeId = node.next;
      if (nextNodeId == null) {
        return NodeExecutionResult.error('Scene node has no next node');
      }
      return NodeExecutionResult.next(nextNodeId);
    }

    final dialogue = dialogues[_currentDialogueIndex] as Map<String, dynamic>;
    final speakerId = dialogue['speakerId'] as String?;
    
    // Get speaker name from character
    String? speakerName;
    if (speakerId != null) {
      final character = _bundle.getCharacter(speakerId);
      speakerName = character?.displayName;
    }

    final dialogueData = DialogueExecutionData(
      speakerId: speakerId,
      speakerName: speakerName,
      expression: dialogue['expression'] as String?,
      text: _interpolateText(dialogue['text'] as String? ?? ''),
      voiceId: dialogue['voiceId'] as String?,
      dialogueIndex: _currentDialogueIndex,
      totalDialogues: dialogues.length,
      isLastDialogue: _currentDialogueIndex == dialogues.length - 1,
      characterSlot: dialogue['characterSlot'] as String?,
      characterX: (dialogue['characterX'] as num?)?.toDouble(),
      characterY: (dialogue['characterY'] as num?)?.toDouble(),
      characterScale: (dialogue['characterScale'] as num?)?.toDouble(),
      characterFlipped: dialogue['characterFlipped'] as bool?,
    );

    // Return dialogue with background info (only set background on first dialogue)
    return NodeExecutionResult(
      success: true,
      waitForInput: true,
      dialogue: dialogueData,
      nextNodeId: _currentDialogueIndex == dialogues.length - 1 ? node.next : null,
      backgroundId: _currentDialogueIndex == 0 ? backgroundId : null,
    );
  }

  /// Advance to next dialogue in scene
  void advanceDialogue() {
    _currentDialogueIndex++;
  }

  /// Reset dialogue index
  void resetDialogueIndex() {
    _currentDialogueIndex = 0;
  }

  /// Get current dialogue index
  int get currentDialogueIndex => _currentDialogueIndex;

  /// Execute choice node
  NodeExecutionResult _executeChoice(CompiledNode node, String nodeId) {
    final options = node.data['options'] as List<dynamic>? ?? [];
    
    if (options.isEmpty) {
      return NodeExecutionResult.error('Choice node has no options');
    }

    final execOptions = <ChoiceExecutionOption>[];
    
    for (final opt in options) {
      final option = opt as Map<String, dynamic>;
      final condition = option['condition'] as String?;
      
      bool isEnabled = true;
      String? disabledReason;
      
      if (condition != null && condition.isNotEmpty) {
        final evaluator = ConditionEvaluator(_variableManager.getAllVariables());
        isEnabled = evaluator.evaluateExpression(condition);
        if (!isEnabled) {
          disabledReason = 'Condition not met';
        }
      }

      execOptions.add(ChoiceExecutionOption(
        id: option['id'] as String? ?? '',
        text: _interpolateText(option['text'] as String? ?? ''),
        targetNodeId: option['next'] as String? ?? option['targetNodeId'] as String?,
        isEnabled: isEnabled,
        disabledReason: disabledReason,
      ));
    }

    return NodeExecutionResult.waitForChoice(execOptions);
  }

  /// Select a choice option
  NodeExecutionResult selectChoice(int optionIndex, List<ChoiceExecutionOption> choices) {
    if (optionIndex < 0 || optionIndex >= choices.length) {
      return NodeExecutionResult.error('Invalid choice index: $optionIndex');
    }

    final choice = choices[optionIndex];
    if (!choice.isEnabled) {
      return NodeExecutionResult.error('Choice is not enabled');
    }

    final targetNodeId = choice.targetNodeId;
    if (targetNodeId == null || targetNodeId.isEmpty) {
      return NodeExecutionResult.error('Choice has no target node');
    }

    _currentDialogueIndex = 0;
    return NodeExecutionResult.next(targetNodeId);
  }

  /// Execute jump node
  NodeExecutionResult _executeJump(CompiledNode node) {
    final targetNodeId = node.data['targetNodeId'] as String?;
    final targetChapterId = node.data['targetChapterId'] as String?;

    if (targetChapterId != null && targetChapterId.isNotEmpty) {
      // Cross-chapter jump
      final chapter = _bundle.getChapter(targetChapterId);
      if (chapter == null) {
        return NodeExecutionResult.error('Target chapter not found: $targetChapterId');
      }
      
      final nodeId = targetNodeId ?? chapter.startNodeId;
      _currentDialogueIndex = 0;
      return NodeExecutionResult.jumpToChapter(targetChapterId, nodeId);
    }

    if (targetNodeId == null || targetNodeId.isEmpty) {
      return NodeExecutionResult.error('Jump node has no target');
    }

    _currentDialogueIndex = 0;
    return NodeExecutionResult.next(targetNodeId);
  }

  /// Execute condition node
  NodeExecutionResult _executeCondition(CompiledNode node, String nodeId) {
    final expression = node.data['expression'] as String? ?? '';
    final trueNodeId = node.data['trueNodeId'] as String?;
    final falseNodeId = node.data['falseNodeId'] as String?;

    if (expression.isEmpty && node.data['_compiledCondition'] == null) {
      return NodeExecutionResult.error('Condition node has no expression');
    }

    final result = ConditionPrecompiler.evaluatePrecompiled(
      node.data,
      _variableManager.getAllVariables(),
    );

    final nextNodeId = result ? trueNodeId : falseNodeId;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return NodeExecutionResult.error(
        'Condition node has no ${result ? 'true' : 'false'} branch',
      );
    }

    _currentDialogueIndex = 0;
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute switch node (multi-condition branching)
  NodeExecutionResult _executeSwitch(CompiledNode node, String nodeId) {
    final cases = node.data['cases'] as List<dynamic>? ?? [];

    if (cases.isEmpty) {
      return NodeExecutionResult.error('Switch node has no cases');
    }

    final variables = _variableManager.getAllVariables();
    
    String? matchedNodeId;
    String? defaultNodeId;
    
    for (final caseData in cases) {
      final caseMap = caseData as Map<String, dynamic>;
      final expression = caseMap['expression'] as String? ?? '';
      final targetNodeId = caseMap['targetNodeId'] as String?;
      
      if (expression.isEmpty && caseMap['_compiledCondition'] == null) {
        defaultNodeId = targetNodeId;
        continue;
      }
      
      if (ConditionPrecompiler.evaluatePrecompiled(caseMap, variables)) {
        matchedNodeId = targetNodeId;
        break;
      }
    }
    
    final nextNodeId = matchedNodeId ?? defaultNodeId;
    
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return NodeExecutionResult.error('Switch node: no matching case and no default');
    }

    _currentDialogueIndex = 0;
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute variable node
  NodeExecutionResult _executeVariable(CompiledNode node) {
    final variableName = node.data['variableName'] as String? ?? '';
    final operationStr = node.data['operation'] as String? ?? 'set';
    final value = node.data['value'];

    if (variableName.isEmpty) {
      return NodeExecutionResult.error('Variable node has no variable name');
    }

    final operation = VariableOperation.values.firstWhere(
      (e) => e.name == operationStr,
      orElse: () => VariableOperation.set,
    );

    _variableManager.applyOperation(variableName, operation, value);

    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return NodeExecutionResult.error('Variable node has no next node');
    }

    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute effect node
  NodeExecutionResult _executeEffect(CompiledNode node) {
    final effectType = node.data['effectType'] as String? ?? 'fade';
    final duration = (node.data['duration'] as num?)?.toDouble() ?? 1.0;
    final intensity = (node.data['intensity'] as num?)?.toDouble() ?? 1.0;
    final params = node.data['effectParams'] as Map<String, dynamic>? ?? {};

    final effect = EffectExecutionData(
      effectType: effectType,
      duration: duration,
      intensity: intensity,
      params: params,
    );

    final nextNodeId = node.next;
    
    return NodeExecutionResult(
      success: true,
      nextNodeId: nextNodeId,
      effect: effect,
    );
  }

  /// Execute audio node
  NodeExecutionResult _executeAudio(CompiledNode node) {
    final audioId = node.data['audioId'] as String?;
    final channel = node.data['channel'] as String? ?? 'bgm';
    final action = node.data['action'] as String? ?? 'play';
    final volume = (node.data['volume'] as num?)?.toDouble() ?? 1.0;
    final fadeDuration = (node.data['fadeDuration'] as num?)?.toDouble();
    final loop = node.data['loop'] as bool? ?? false;

    final audio = AudioExecutionData(
      audioId: audioId,
      channel: channel,
      action: action,
      volume: volume,
      fadeDuration: fadeDuration,
      loop: loop,
    );

    final nextNodeId = node.next;
    
    return NodeExecutionResult(
      success: true,
      nextNodeId: nextNodeId,
      audio: audio,
    );
  }

  /// Execute ending node
  NodeExecutionResult _executeEnding(CompiledNode node) {
    final endingId = node.data['endingId'] as String? ?? '';
    final endingName = node.data['endingName'] as String? ?? 'Ending';
    final endingType = node.data['endingType'] as String? ?? 'normal';
    final unlocksGallery = node.data['unlocksGallery'] as bool? ?? false;
    final unlockedCGs = (node.data['unlockedCGs'] as List<dynamic>?)?.cast<String>() ?? [];

    final ending = EndingExecutionData(
      endingId: endingId,
      endingName: endingName,
      endingType: endingType,
      unlocksGallery: unlocksGallery,
      unlockedCGs: unlockedCGs,
    );

    return NodeExecutionResult.end(ending);
  }

  /// Execute script node
  NodeExecutionResult _executeScript(CompiledNode node) {
    final scriptCode = node.data['scriptCode'] as String? ?? '';
    final continueOnError = node.data['continueOnError'] as bool? ?? false;
    final timeoutMs = node.data['timeoutMs'] as int? ?? 5000;

    if (scriptCode.isEmpty) {
      // Empty script, just continue
      final nextNodeId = node.next;
      if (nextNodeId == null) {
        return NodeExecutionResult.error('Script node has no next node');
      }
      return NodeExecutionResult.next(nextNodeId);
    }

    // Create script context with current variables
    final context = ScriptContext(
      variables: _variableManager.getAllVariables(),
      securityLevel: ScriptSecurityLevel.readWrite,
    );

    // Create executor with timeout
    final executor = ScriptExecutor(
      config: ScriptExecutionConfig(
        timeout: Duration(milliseconds: timeoutMs),
        securityLevel: ScriptSecurityLevel.readWrite,
        allowAsync: true,
      ),
    );

    // Execute synchronously for now (async execution would need engine changes)
    // In a full implementation, this would be async
    try {
      // Parse and validate first
      final parser = ScriptParser();
      final parseResult = parser.parse(scriptCode);

      if (!parseResult.success) {
        if (continueOnError) {
          final nextNodeId = node.next;
          if (nextNodeId == null) {
            return NodeExecutionResult.error('Script node has no next node');
          }
          return NodeExecutionResult.next(nextNodeId);
        }
        return NodeExecutionResult.error(
          'Script parse error: ${parseResult.errorMessage}',
        );
      }

      // Apply any variable changes from the script context
      // Note: In a real async implementation, this would happen after execution
      for (final entry in context.getModifiedVariables().entries) {
        _variableManager.setValue(entry.key, entry.value);
      }

      final nextNodeId = node.next;
      if (nextNodeId == null) {
        return NodeExecutionResult.error('Script node has no next node');
      }
      return NodeExecutionResult.next(nextNodeId);
    } catch (e) {
      if (continueOnError) {
        final nextNodeId = node.next;
        if (nextNodeId == null) {
          return NodeExecutionResult.error('Script node has no next node');
        }
        return NodeExecutionResult.next(nextNodeId);
      }
      return NodeExecutionResult.error('Script execution error: $e');
    }
  }

  /// Execute achievement node - unlock an achievement
  NodeExecutionResult _executeAchievement(CompiledNode node) {
    final achievementId = node.data['achievementId'] as String? ?? '';
    final showNotification = node.data['showNotification'] as bool? ?? true;

    // TODO: Integrate with AchievementManager to actually unlock the achievement
    // For now, just continue to next node
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      // No next node - this might be intentional (end of branch)
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute particle node - control particle effects
  NodeExecutionResult _executeParticle(CompiledNode node) {
    final presetName = node.data['presetName'] as String? ?? 'rain';
    final action = node.data['action'] as String? ?? 'start';
    final intensity = (node.data['intensity'] as num?)?.toDouble() ?? 1.0;
    final effectId = node.data['effectId'] as String?;
    final immediate = node.data['immediate'] as bool? ?? false;

    // TODO: Integrate with ParticleSystemManager to control particles
    // For now, just continue to next node
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute affection node - modify character affection
  NodeExecutionResult _executeAffection(CompiledNode node) {
    final characterId = node.data['characterId'] as String? ?? '';
    final operationStr = node.data['operation'] as String? ?? 'add';
    final value = node.data['value'] as int? ?? 1;
    final showNotification = node.data['showNotification'] as bool? ?? true;

    // TODO: Integrate with AffectionManager to modify affection
    // For now, just continue to next node
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute journal node - unlock a journal entry
  NodeExecutionResult _executeJournal(CompiledNode node) {
    final entryId = node.data['entryId'] as String? ?? '';
    final showNotification = node.data['showNotification'] as bool? ?? true;

    // TODO: Integrate with JournalManager to unlock entry
    // For now, just continue to next node
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute minigame node - trigger a mini-game
  NodeExecutionResult _executeMinigame(CompiledNode node) {
    final gameTypeId = node.data['gameTypeId'] as String? ?? '';
    final displayName = node.data['displayName'] as String? ?? 'Mini-Game';
    final skippable = node.data['skippable'] as bool? ?? true;

    // TODO: Integrate with MiniGameManager to trigger mini-game
    // For now, just continue to next node (as if skipped)
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute background node - change background
  NodeExecutionResult _executeBackground(CompiledNode node) {
    final backgroundId = node.data['backgroundId'] as String?;
    final transition = node.data['transition'] as String? ?? 'fade';
    final transitionDuration = (node.data['transitionDuration'] as num?)?.toDouble() ?? 0.5;

    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return NodeExecutionResult(
        success: true,
        nextNodeId: null,
        backgroundId: backgroundId,
      );
    }
    return NodeExecutionResult(
      success: true,
      nextNodeId: nextNodeId,
      backgroundId: backgroundId,
    );
  }

  /// Execute character node - show/hide/move character
  NodeExecutionResult _executeCharacter(CompiledNode node) {
    final characterId = node.data['characterId'] as String?;
    final action = node.data['action'] as String? ?? 'show';
    final slot = node.data['slot'] as String? ?? 'center';
    final expression = node.data['expression'] as String?;
    final customX = (node.data['customX'] as num?)?.toDouble();
    final customY = (node.data['customY'] as num?)?.toDouble();
    final scale = (node.data['scale'] as num?)?.toDouble();
    final flipped = node.data['flipped'] as bool?;

    final nextNodeId = node.next;

    if (characterId == null || characterId.isEmpty) {
      if (nextNodeId == null || nextNodeId.isEmpty) {
        return const NodeExecutionResult(success: true, nextNodeId: null);
      }
      return NodeExecutionResult.next(nextNodeId);
    }

    // Return character update for engine to process
    return NodeExecutionResult(
      success: true,
      nextNodeId: nextNodeId,
      characterUpdate: CharacterDisplayUpdate(
        characterId: characterId,
        action: action,
        slot: slot,
        expression: expression,
        customX: customX,
        customY: customY,
        scale: scale,
        flipped: flipped,
      ),
    );
  }

  /// Execute wait node - wait for specified duration
  NodeExecutionResult _executeWait(CompiledNode node) {
    final duration = (node.data['duration'] as num?)?.toDouble() ?? 1.0;
    final skippable = node.data['skippable'] as bool? ?? true;

    // TODO: Implement actual wait with timer
    // For now, just continue to next node immediately
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute label node - just a marker, continue to next
  NodeExecutionResult _executeLabel(CompiledNode node) {
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute input node - get player text input
  NodeExecutionResult _executeInput(CompiledNode node) {
    final prompt = node.data['prompt'] as String? ?? '';
    final variableName = node.data['variableName'] as String? ?? '';
    final defaultValue = node.data['defaultValue'] as String? ?? '';

    // TODO: Implement input dialog and wait for user input
    // For now, just set default value and continue
    if (variableName.isNotEmpty) {
      _variableManager.setValue(variableName, defaultValue);
    }
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute CG node - show CG image
  NodeExecutionResult _executeCG(CompiledNode node) {
    final cgId = node.data['cgId'] as String?;
    final transition = node.data['transition'] as String? ?? 'fade';
    final transitionDuration = (node.data['transitionDuration'] as num?)?.toDouble() ?? 0.5;
    final unlockInGallery = node.data['unlockInGallery'] as bool? ?? true;

    // TODO: Integrate with CG display and gallery unlock
    // For now, just continue to next node
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Execute video node - play video
  NodeExecutionResult _executeVideo(CompiledNode node) {
    final videoId = node.data['videoId'] as String?;
    final skippable = node.data['skippable'] as bool? ?? true;
    final loop = node.data['loop'] as bool? ?? false;

    // TODO: Integrate with video player
    // For now, just continue to next node (as if video ended)
    
    final nextNodeId = node.next;
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return const NodeExecutionResult(success: true, nextNodeId: null);
    }
    return NodeExecutionResult.next(nextNodeId);
  }

  /// Interpolate variables in text
  /// Note: Only replaces {variableName} patterns that are NOT text effect tags
  String _interpolateText(String text) {
    // Known text effect names to exclude from variable interpolation
    const effectNames = {
      'shake', 'wave', 'rainbow', 'fadeIn', 'pulse', 'typewriter', 'instant'
    };
    
    // Replace {variableName} with variable values, but skip effect tags
    return text.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (match) {
        final varName = match.group(1)!;
        // Skip if this is a text effect tag
        if (effectNames.contains(varName.toLowerCase())) {
          return match.group(0)!; // Return unchanged
        }
        final value = _variableManager.getValue(varName);
        return value?.toString() ?? '{$varName}';
      },
    );
  }
}
