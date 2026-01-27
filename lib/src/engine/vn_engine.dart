/// VN Engine - Core runtime engine for visual novels
/// 
/// The VNEngine is responsible for:
/// - Loading and parsing story bundles
/// - Executing nodes in sequence
/// - Managing game state (variables, position, etc.)
/// - Providing debug capabilities

import 'dart:async';

import '../compiler/vn_story_bundle.dart';
import 'vn_engine_state.dart';
import 'variable_manager.dart';
import 'node_executor.dart';
import 'debug/debug_api.dart';
import 'debug/debug_event.dart';

/// Configuration for the VN runtime
class VNRuntimeConfig {
  /// Text display speed (characters per second, 0 = instant)
  final double textSpeed;
  
  /// Auto-advance delay in seconds
  final double autoAdvanceDelay;
  
  /// Whether to skip unread text in skip mode
  final bool skipUnread;
  
  /// BGM volume (0.0 - 1.0)
  final double bgmVolume;
  
  /// SFX volume (0.0 - 1.0)
  final double sfxVolume;
  
  /// Voice volume (0.0 - 1.0)
  final double voiceVolume;
  
  /// Current language code
  final String language;

  const VNRuntimeConfig({
    this.textSpeed = 30.0,
    this.autoAdvanceDelay = 2.0,
    this.skipUnread = false,
    this.bgmVolume = 1.0,
    this.sfxVolume = 1.0,
    this.voiceVolume = 1.0,
    this.language = 'en',
  });

  VNRuntimeConfig copyWith({
    double? textSpeed,
    double? autoAdvanceDelay,
    bool? skipUnread,
    double? bgmVolume,
    double? sfxVolume,
    double? voiceVolume,
    String? language,
  }) {
    return VNRuntimeConfig(
      textSpeed: textSpeed ?? this.textSpeed,
      autoAdvanceDelay: autoAdvanceDelay ?? this.autoAdvanceDelay,
      skipUnread: skipUnread ?? this.skipUnread,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      language: language ?? this.language,
    );
  }
}

/// Main VN runtime engine
class VNEngine {
  /// The loaded story bundle
  final VNStoryBundle _bundle;
  
  /// Runtime configuration
  VNRuntimeConfig _config;
  
  /// Variable manager
  late final VariableManager _variableManager;
  
  /// Node executor
  late final NodeExecutor _nodeExecutor;
  
  /// Debug API
  final VNDebugAPI debugApi = VNDebugAPI();
  
  /// Current engine state
  VNEngineState _state = const VNEngineState();
  
  /// State change stream controller
  final _stateController = StreamController<VNEngineState>.broadcast();
  
  /// Current choices (when waiting for choice input)
  List<ChoiceExecutionOption>? _currentChoices;
  
  /// Current dialogue data
  DialogueExecutionData? _currentDialogue;
  
  /// Pending effect
  EffectExecutionData? _pendingEffect;
  
  /// Pending audio action
  AudioExecutionData? _pendingAudio;

  VNEngine(this._bundle, {VNRuntimeConfig? config})
      : _config = config ?? const VNRuntimeConfig() {
    _variableManager = VariableManager(_bundle.variables);
    _nodeExecutor = NodeExecutor(_bundle, _variableManager);
  }

  /// Get the story bundle
  VNStoryBundle get bundle => _bundle;

  /// Get current configuration
  VNRuntimeConfig get config => _config;

  /// Update configuration
  void updateConfig(VNRuntimeConfig config) {
    _config = config;
  }

  /// Get current engine state
  VNEngineState get state => _state;

  /// Stream of state changes
  Stream<VNEngineState> get stateStream => _stateController.stream;

  /// Get current choices (if waiting for choice)
  List<ChoiceExecutionOption>? get currentChoices => _currentChoices;

  /// Get current dialogue (if showing dialogue)
  DialogueExecutionData? get currentDialogue => _currentDialogue;

  /// Get pending effect
  EffectExecutionData? get pendingEffect => _pendingEffect;

  /// Get pending audio action
  AudioExecutionData? get pendingAudio => _pendingAudio;

  /// Get current variable values
  Map<String, dynamic> get variables => _variableManager.getAllVariables();

  /// Get a specific variable value
  dynamic getVariable(String name) => _variableManager.getValue(name);

  /// Start the story from the beginning
  Future<void> start({String? chapterId}) async {
    final targetChapterId = chapterId ?? _bundle.chapters.first.id;
    final chapter = _bundle.getChapter(targetChapterId);
    
    if (chapter == null) {
      _setError('Chapter not found: $targetChapterId');
      return;
    }

    // Reset state
    _variableManager.reset();
    _variableManager.setCurrentChapter(targetChapterId);
    _nodeExecutor.resetDialogueIndex();
    _currentChoices = null;
    _currentDialogue = null;

    // Set initial position
    _updateState(_state.copyWith(
      playbackState: VNPlaybackState.playing,
      position: StoryPosition(
        chapterId: targetChapterId,
        nodeId: chapter.startNodeId,
      ),
      variables: _variableManager.getAllVariables(),
      readDialogueIds: {},
      displayedCharacters: {},
    ));

    debugApi.logChapterChange(targetChapterId);

    // Execute the start node
    await _executeCurrentNode();
  }

  /// Go to a specific node
  Future<void> goToNode(String nodeId, {String? chapterId}) async {
    final targetChapterId = chapterId ?? _state.position?.chapterId;
    if (targetChapterId == null) {
      _setError('No chapter specified');
      return;
    }

    final chapter = _bundle.getChapter(targetChapterId);
    if (chapter == null) {
      _setError('Chapter not found: $targetChapterId');
      return;
    }

    if (!chapter.nodes.containsKey(nodeId)) {
      _setError('Node not found: $nodeId');
      return;
    }

    if (chapterId != null && chapterId != _state.position?.chapterId) {
      _variableManager.setCurrentChapter(chapterId);
      debugApi.logChapterChange(chapterId, previousChapterId: _state.position?.chapterId);
    }

    _nodeExecutor.resetDialogueIndex();
    _currentChoices = null;
    _currentDialogue = null;

    _updateState(_state.copyWith(
      playbackState: VNPlaybackState.playing,
      position: StoryPosition(
        chapterId: targetChapterId,
        nodeId: nodeId,
      ),
    ));

    await _executeCurrentNode();
  }

  /// Advance to the next step (dialogue or node)
  Future<void> advance() async {
    if (_state.playbackState == VNPlaybackState.waitingForInput) {
      if (_currentDialogue != null) {
        // Mark current dialogue as read
        _markCurrentDialogueRead();
        
        if (_currentDialogue!.isLastDialogue) {
          // Move to next node
          _nodeExecutor.resetDialogueIndex();
          _currentDialogue = null;
          
          final position = _state.position;
          if (position != null) {
            final chapter = _bundle.getChapter(position.chapterId);
            final node = chapter?.nodes[position.nodeId];
            if (node?.next != null) {
              await _goToNextNode(node!.next!);
            }
          }
        } else {
          // Show next dialogue
          _nodeExecutor.advanceDialogue();
          await _executeCurrentNode();
        }
      }
    } else if (_state.playbackState == VNPlaybackState.playing) {
      await _executeCurrentNode();
    }
  }

  /// Select a choice option
  Future<void> selectChoice(int optionIndex) async {
    if (_state.playbackState != VNPlaybackState.waitingForInput || _currentChoices == null) {
      return;
    }

    final result = _nodeExecutor.selectChoice(optionIndex, _currentChoices!);
    
    if (!result.success) {
      _setError(result.errorMessage ?? 'Failed to select choice');
      return;
    }

    // Log the choice
    if (optionIndex < _currentChoices!.length) {
      final choice = _currentChoices![optionIndex];
      debugApi.logChoiceSelected(
        _state.position?.nodeId ?? '',
        optionIndex,
        choice.text,
        targetNodeId: choice.targetNodeId,
      );
    }

    _currentChoices = null;
    
    if (result.nextNodeId != null) {
      await _goToNextNode(result.nextNodeId!);
    }
  }

  /// Pause playback
  void pause() {
    if (_state.playbackState == VNPlaybackState.playing) {
      final previousState = _state.playbackState;
      _updateState(_state.copyWith(playbackState: VNPlaybackState.paused));
      debugApi.logStateChange(previousState, VNPlaybackState.paused, reason: 'User paused');
    }
  }

  /// Resume playback
  void resume() {
    if (_state.playbackState == VNPlaybackState.paused) {
      final previousState = _state.playbackState;
      _updateState(_state.copyWith(playbackState: VNPlaybackState.playing));
      debugApi.logStateChange(previousState, VNPlaybackState.playing, reason: 'User resumed');
    }
  }

  /// Single step execution (debug mode)
  Future<void> step() async {
    debugApi.enableStepMode();
    await advance();
  }

  /// Restart from the beginning
  Future<void> restart() async {
    await start();
  }

  /// Check if a dialogue has been read
  bool isDialogueRead(String chapterId, String nodeId, int dialogueIndex) {
    return _state.isDialogueRead(chapterId, nodeId, dialogueIndex);
  }

  /// Clear pending effect (after it's been applied)
  void clearPendingEffect() {
    _pendingEffect = null;
  }

  /// Clear pending audio (after it's been applied)
  void clearPendingAudio() {
    _pendingAudio = null;
  }

  /// Export state for saving
  Map<String, dynamic> exportState() {
    return {
      'position': _state.position?.toJson(),
      'variables': _variableManager.exportForSave(),
      'readDialogueIds': _state.readDialogueIds.toList(),
      'currentBackgroundId': _state.currentBackgroundId,
      'currentBgmId': _state.currentBgmId,
    };
  }

  /// Restore state from save
  Future<void> restoreState(Map<String, dynamic> savedState) async {
    final positionJson = savedState['position'] as Map<String, dynamic>?;
    final variablesJson = savedState['variables'] as Map<String, dynamic>?;
    final readIds = (savedState['readDialogueIds'] as List<dynamic>?)?.cast<String>().toSet();

    if (variablesJson != null) {
      _variableManager.restoreFromSave(variablesJson);
    }

    if (positionJson != null) {
      final position = StoryPosition.fromJson(positionJson);
      _variableManager.setCurrentChapter(position.chapterId);
      
      _updateState(_state.copyWith(
        playbackState: VNPlaybackState.playing,
        position: position,
        variables: _variableManager.getAllVariables(),
        readDialogueIds: readIds ?? {},
        currentBackgroundId: savedState['currentBackgroundId'] as String?,
        currentBgmId: savedState['currentBgmId'] as String?,
      ));

      _nodeExecutor.resetDialogueIndex();
      if (position.dialogueIndex > 0) {
        for (int i = 0; i < position.dialogueIndex; i++) {
          _nodeExecutor.advanceDialogue();
        }
      }

      await _executeCurrentNode();
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    debugApi.dispose();
  }

  // Private methods

  Future<void> _executeCurrentNode() async {
    final position = _state.position;
    if (position == null) {
      _setError('No current position');
      return;
    }

    final chapter = _bundle.getChapter(position.chapterId);
    if (chapter == null) {
      _setError('Chapter not found: ${position.chapterId}');
      return;
    }

    final node = chapter.nodes[position.nodeId];
    if (node == null) {
      _setError('Node not found: ${position.nodeId}');
      return;
    }

    // Check for breakpoints
    if (debugApi.shouldPauseAt(position.nodeId)) {
      debugApi.logBreakpointHit(position.nodeId, position.chapterId);
      _updateState(_state.copyWith(playbackState: VNPlaybackState.paused));
      debugApi.onStepPause?.call();
      return;
    }

    debugApi.logNodeEnter(position.chapterId, position.nodeId, node.type);

    final result = _nodeExecutor.execute(
      node,
      position.nodeId,
      position.chapterId,
      dialogueIndex: _nodeExecutor.currentDialogueIndex,
    );

    if (!result.success) {
      _setError(result.errorMessage ?? 'Execution failed');
      return;
    }

    // Handle different result types
    if (result.ending != null) {
      _handleEnding(result.ending!);
      return;
    }

    if (result.isChapterJump && result.targetChapterId != null) {
      await _handleChapterJump(result.targetChapterId!, result.nextNodeId!);
      return;
    }

    if (result.effect != null) {
      _pendingEffect = result.effect;
    }

    if (result.audio != null) {
      _pendingAudio = result.audio;
    }

    // Handle character display update
    if (result.characterUpdate != null) {
      final update = result.characterUpdate!;
      Map<String, CharacterDisplayState> updatedCharacters = Map.from(_state.displayedCharacters);

      switch (update.action) {
        case 'show':
          updatedCharacters[update.characterId] = CharacterDisplayState(
            characterId: update.characterId,
            expression: update.expression,
            slot: update.slot ?? 'center',
            customX: update.customX,
            customY: update.customY,
            scale: update.scale ?? 1.0,
            flipped: update.flipped ?? false,
          );
          break;
        case 'hide':
          updatedCharacters.remove(update.characterId);
          break;
        case 'move':
          if (updatedCharacters.containsKey(update.characterId)) {
            updatedCharacters[update.characterId] = updatedCharacters[update.characterId]!.copyWith(
              slot: update.slot,
              customX: update.customX,
              customY: update.customY,
            );
          }
          break;
        case 'expression':
          if (updatedCharacters.containsKey(update.characterId)) {
            updatedCharacters[update.characterId] = updatedCharacters[update.characterId]!.copyWith(
              expression: update.expression,
            );
          }
          break;
        case 'scale':
          if (updatedCharacters.containsKey(update.characterId)) {
            updatedCharacters[update.characterId] = updatedCharacters[update.characterId]!.copyWith(
              scale: update.scale,
            );
          }
          break;
        case 'flip':
          if (updatedCharacters.containsKey(update.characterId)) {
            updatedCharacters[update.characterId] = updatedCharacters[update.characterId]!.copyWith(
              flipped: update.flipped,
            );
          }
          break;
      }

      _updateState(_state.copyWith(displayedCharacters: updatedCharacters));
      print('[VNEngine] Character update: ${update.action} ${update.characterId}, slot: ${update.slot}');
    }

    if (result.dialogue != null) {
      _currentDialogue = result.dialogue;

      // Update displayed characters based on speaker
      Map<String, CharacterDisplayState> updatedCharacters = Map.from(_state.displayedCharacters);
      final speakerId = result.dialogue!.speakerId;

      print('[VNEngine] Dialogue speakerId: $speakerId, expression: ${result.dialogue!.expression}');

      if (speakerId != null && speakerId.isNotEmpty) {
        // Mark all characters as not speaking
        updatedCharacters = updatedCharacters.map((id, state) =>
          MapEntry(id, state.copyWith(isSpeaking: false)));

        // Add or update the speaking character
        if (updatedCharacters.containsKey(speakerId)) {
          updatedCharacters[speakerId] = updatedCharacters[speakerId]!.copyWith(
            expression: result.dialogue!.expression,
            isSpeaking: true,
          );
        } else {
          // Add new character to display
          updatedCharacters[speakerId] = CharacterDisplayState(
            characterId: speakerId,
            expression: result.dialogue!.expression,
            slot: _getNextAvailableSlot(updatedCharacters),
            isSpeaking: true,
          );
        }
        print('[VNEngine] Updated displayedCharacters: ${updatedCharacters.keys.toList()}');
      }

      _updateState(_state.copyWith(
        playbackState: VNPlaybackState.waitingForInput,
        position: position.copyWith(
          dialogueIndex: result.dialogue!.dialogueIndex,
        ),
        // Update background if specified
        currentBackgroundId: result.backgroundId ?? _state.currentBackgroundId,
        displayedCharacters: updatedCharacters,
      ));

      debugApi.logDialogueAdvance(
        position.nodeId,
        result.dialogue!.dialogueIndex,
        result.dialogue!.text,
        speakerId: result.dialogue!.speakerId,
      );
      return;
    }

    if (result.choices != null) {
      _currentChoices = result.choices;
      _updateState(_state.copyWith(
        playbackState: VNPlaybackState.waitingForInput,
        currentBackgroundId: result.backgroundId ?? _state.currentBackgroundId,
      ));
      return;
    }

    if (result.waitForInput) {
      _updateState(_state.copyWith(
        playbackState: VNPlaybackState.waitingForInput,
        currentBackgroundId: result.backgroundId ?? _state.currentBackgroundId,
      ));
      return;
    }

    // Update background before continuing to next node
    if (result.backgroundId != null) {
      _updateState(_state.copyWith(
        currentBackgroundId: result.backgroundId,
      ));
    }

    // Continue to next node
    if (result.nextNodeId != null) {
      await _goToNextNode(result.nextNodeId!);
    }
  }

  Future<void> _goToNextNode(String nextNodeId) async {
    final position = _state.position;
    if (position == null) return;

    debugApi.logNodeExit(position.chapterId, position.nodeId, nextNodeId: nextNodeId);

    _updateState(_state.copyWith(
      position: position.copyWith(
        nodeId: nextNodeId,
        dialogueIndex: 0,
      ),
    ));

    await _executeCurrentNode();
  }

  Future<void> _handleChapterJump(String chapterId, String nodeId) async {
    final previousChapterId = _state.position?.chapterId;
    
    _variableManager.setCurrentChapter(chapterId);
    debugApi.logChapterChange(chapterId, previousChapterId: previousChapterId);

    _updateState(_state.copyWith(
      position: StoryPosition(
        chapterId: chapterId,
        nodeId: nodeId,
      ),
      variables: _variableManager.getAllVariables(),
    ));

    await _executeCurrentNode();
  }

  void _handleEnding(EndingExecutionData ending) {
    final previousState = _state.playbackState;
    _updateState(_state.copyWith(
      playbackState: VNPlaybackState.ended,
    ));
    
    debugApi.logStateChange(previousState, VNPlaybackState.ended, reason: 'Reached ending: ${ending.endingName}');
  }

  void _markCurrentDialogueRead() {
    final position = _state.position;
    if (position == null) return;

    final dialogueId = '${position.chapterId}:${position.nodeId}:${position.dialogueIndex}';
    if (_state.readDialogueIds.contains(dialogueId)) {
      return;
    }
    final newReadIds = Set<String>.from(_state.readDialogueIds)..add(dialogueId);
    
    _updateState(_state.copyWith(readDialogueIds: newReadIds));
  }

  void _setError(String message) {
    final previousState = _state.playbackState;
    _updateState(_state.copyWith(
      playbackState: VNPlaybackState.error,
      errorMessage: message,
    ));
    
    debugApi.logError(message);
    debugApi.logStateChange(previousState, VNPlaybackState.error, reason: message);
  }

  void _updateState(VNEngineState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Get the next available slot for a new character
  String _getNextAvailableSlot(Map<String, CharacterDisplayState> currentCharacters) {
    final usedSlots = currentCharacters.values.map((c) => c.slot).toSet();

    // Prefer center for first character, then left, then right
    if (!usedSlots.contains('center')) return 'center';
    if (!usedSlots.contains('left')) return 'left';
    if (!usedSlots.contains('right')) return 'right';

    // If all slots are used, default to center (will overlap)
    return 'center';
  }
}
