/// Dialogue Interaction Controller for VN Runtime
///
/// Manages user interactions with dialogue display, coordinating
/// text animation, voice playback, and player input handling.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/vn_node.dart';
import '../rendering/audio_manager.dart';
import '../save/read_state_manager.dart';
import 'voice_controller.dart';
import 'voice_timeline.dart';
import 'text_voice_synchronizer.dart';

/// Playback mode for dialogue
enum DialoguePlaybackMode {
  /// Normal mode - wait for user input to advance
  normal,

  /// Auto mode - automatically advance after dialogue completes
  auto,

  /// Skip mode - fast-forward through dialogue
  skip,
}

/// Configuration for dialogue interaction
class DialogueInteractionConfig {
  /// Text display speed (0.1 to 3.0, where 1.0 is normal)
  final double textSpeed;

  /// Auto mode delay after dialogue completes (in seconds)
  final double autoDelay;

  /// Whether to skip unread text in skip mode
  final bool skipUnread;

  /// Voice-text synchronization mode
  final TextVoiceSyncMode syncMode;

  const DialogueInteractionConfig({
    this.textSpeed = 1.0,
    this.autoDelay = 1.5,
    this.skipUnread = false,
    this.syncMode = TextVoiceSyncMode.independent,
  });

  DialogueInteractionConfig copyWith({
    double? textSpeed,
    double? autoDelay,
    bool? skipUnread,
    TextVoiceSyncMode? syncMode,
  }) {
    return DialogueInteractionConfig(
      textSpeed: textSpeed ?? this.textSpeed,
      autoDelay: autoDelay ?? this.autoDelay,
      skipUnread: skipUnread ?? this.skipUnread,
      syncMode: syncMode ?? this.syncMode,
    );
  }
}

/// Events emitted by the dialogue interaction controller
abstract class DialogueInteractionEvent {
  const DialogueInteractionEvent();
}

/// Dialogue started event
class DialogueStartedEvent extends DialogueInteractionEvent {
  final DialogueLine dialogue;
  final String chapterId;
  final String nodeId;
  final int dialogueIndex;

  const DialogueStartedEvent({
    required this.dialogue,
    required this.chapterId,
    required this.nodeId,
    required this.dialogueIndex,
  });
}

/// Dialogue text update event
class DialogueTextUpdateEvent extends DialogueInteractionEvent {
  final int visibleCharCount;
  final int totalCharCount;
  final String visibleText;

  const DialogueTextUpdateEvent({
    required this.visibleCharCount,
    required this.totalCharCount,
    required this.visibleText,
  });

  double get progress =>
      totalCharCount > 0 ? visibleCharCount / totalCharCount : 1.0;
}

/// Dialogue completed event (ready to advance)
class DialogueCompletedEvent extends DialogueInteractionEvent {
  const DialogueCompletedEvent();
}

/// Dialogue advanced event (moving to next)
class DialogueAdvancedEvent extends DialogueInteractionEvent {
  const DialogueAdvancedEvent();
}

/// Dialogue Interaction Controller
///
/// Coordinates all aspects of dialogue playback:
/// - Text animation (typewriter or voice-driven)
/// - Voice playback
/// - User input handling (click, auto, skip)
/// - Read state tracking
class DialogueInteractionController extends ChangeNotifier {
  final VNAudioManager _audioManager;
  final ReadStateManager? _readStateManager;

  late final VoiceController _voiceController;
  late final TextVoiceSynchronizer _synchronizer;

  // Configuration
  DialogueInteractionConfig _config;

  // Current state
  DialoguePlaybackMode _playbackMode = DialoguePlaybackMode.normal;
  DialogueLine? _currentDialogue;
  String? _currentChapterId;
  String? _currentNodeId;
  int _currentDialogueIndex = 0;

  // Auto mode timer
  Timer? _autoAdvanceTimer;

  // Event stream
  final _eventController =
      StreamController<DialogueInteractionEvent>.broadcast();

  // Subscriptions
  StreamSubscription<TextSyncEvent>? _syncSubscription;

  // Callback for advancing to next dialogue
  VoidCallback? onRequestAdvance;

  DialogueInteractionController({
    required VNAudioManager audioManager,
    ReadStateManager? readStateManager,
    DialogueInteractionConfig config = const DialogueInteractionConfig(),
  })  : _audioManager = audioManager,
        _readStateManager = readStateManager,
        _config = config {
    _voiceController = VoiceController(audioManager: _audioManager);
    _synchronizer = TextVoiceSynchronizer(voiceController: _voiceController);
    _synchronizer.syncMode = _config.syncMode;
    _synchronizer.textSpeed = _config.textSpeed;

    _setupSyncListener();
  }

  /// Stream of dialogue interaction events
  Stream<DialogueInteractionEvent> get events => _eventController.stream;

  /// Current playback mode
  DialoguePlaybackMode get playbackMode => _playbackMode;

  /// Current configuration
  DialogueInteractionConfig get config => _config;

  /// Voice controller for external access
  VoiceController get voiceController => _voiceController;

  /// Text-voice synchronizer for external access
  TextVoiceSynchronizer get synchronizer => _synchronizer;

  /// Current dialogue being displayed
  DialogueLine? get currentDialogue => _currentDialogue;

  /// Whether text animation is complete
  bool get isTextComplete => _synchronizer.isTextComplete;

  /// Whether voice is currently playing
  bool get isVoicePlaying => _voiceController.isPlaying;

  /// Visible text portion
  String get visibleText => _synchronizer.visibleText;

  /// Visible character count
  int get visibleCharCount => _synchronizer.visibleCharCount;

  /// Total character count
  int get totalCharCount => _synchronizer.totalCharCount;

  /// Update configuration
  void updateConfig(DialogueInteractionConfig config) {
    _config = config;
    _synchronizer.syncMode = config.syncMode;
    _synchronizer.textSpeed = config.textSpeed;
    notifyListeners();
  }

  /// Set playback mode
  void setPlaybackMode(DialoguePlaybackMode mode) {
    if (_playbackMode == mode) return;

    _playbackMode = mode;
    _autoAdvanceTimer?.cancel();

    // Handle mode change for current dialogue
    if (_currentDialogue != null) {
      switch (mode) {
        case DialoguePlaybackMode.skip:
          _handleSkipMode();
          break;
        case DialoguePlaybackMode.auto:
          // Auto mode will trigger after current dialogue completes
          if (_synchronizer.isTextComplete && !_voiceController.isPlaying) {
            _scheduleAutoAdvance();
          }
          break;
        case DialoguePlaybackMode.normal:
          // Cancel any pending auto advance
          _autoAdvanceTimer?.cancel();
          break;
      }
    }

    notifyListeners();
  }

  /// Start displaying a dialogue line
  ///
  /// [dialogue] - The dialogue line to display
  /// [chapterId] - Current chapter ID (for read state tracking)
  /// [nodeId] - Current node ID (for read state tracking)
  /// [dialogueIndex] - Index within the scene (for read state tracking)
  /// [voicePath] - Path to voice audio file (if available)
  /// [timeline] - Voice timeline for synchronization (if available)
  Future<void> startDialogue(
    DialogueLine dialogue, {
    required String chapterId,
    required String nodeId,
    required int dialogueIndex,
    String? voicePath,
    VoiceTimeline? timeline,
  }) async {
    _autoAdvanceTimer?.cancel();

    _currentDialogue = dialogue;
    _currentChapterId = chapterId;
    _currentNodeId = nodeId;
    _currentDialogueIndex = dialogueIndex;

    _eventController.add(DialogueStartedEvent(
      dialogue: dialogue,
      chapterId: chapterId,
      nodeId: nodeId,
      dialogueIndex: dialogueIndex,
    ));

    // Check if this dialogue is already read (for skip mode)
    final isRead = _readStateManager?.isRead(
          chapterId,
          nodeId,
          dialogueIndex,
        ) ??
        false;

    // Handle skip mode
    if (_playbackMode == DialoguePlaybackMode.skip) {
      if (_config.skipUnread || isRead) {
        // Skip this dialogue
        _synchronizer.handleSkipMode();
        _eventController.add(const DialogueCompletedEvent());
        _scheduleAutoAdvance(immediate: true);
        notifyListeners();
        return;
      }
      // Fall through to normal display for unread text when skipUnread is false
    }

    // Start synchronized playback
    await _synchronizer.startSync(
      dialogue,
      voicePath: voicePath,
      timeline: timeline,
    );

    notifyListeners();
  }

  /// Handle user click/tap
  ///
  /// Returns true if the dialogue should advance to the next line
  bool handleClick() {
    if (_currentDialogue == null) return false;

    final result = _synchronizer.handleClick();

    switch (result) {
      case AdvanceResult.textCompleted:
        // Text was completed, wait for another click
        _eventController.add(const DialogueCompletedEvent());
        notifyListeners();
        return false;

      case AdvanceResult.voiceStopped:
        // Voice was stopped, wait for another click
        notifyListeners();
        return false;

      case AdvanceResult.advance:
        // Ready to advance
        _markAsRead();
        _eventController.add(const DialogueAdvancedEvent());
        onRequestAdvance?.call();
        return true;

      case AdvanceResult.none:
        return false;
    }
  }

  /// Force advance to next dialogue (for external control)
  void forceAdvance() {
    _synchronizer.showAllText();
    _voiceController.stop();
    _markAsRead();
    _eventController.add(const DialogueAdvancedEvent());
    onRequestAdvance?.call();
  }

  /// Reset the controller state
  void reset() {
    _autoAdvanceTimer?.cancel();
    _synchronizer.reset();
    _voiceController.stop();
    _currentDialogue = null;
    _currentChapterId = null;
    _currentNodeId = null;
    _currentDialogueIndex = 0;
    notifyListeners();
  }

  void _setupSyncListener() {
    _syncSubscription = _synchronizer.syncEvents.listen((event) {
      if (event is TextUpdateEvent) {
        _eventController.add(DialogueTextUpdateEvent(
          visibleCharCount: event.visibleCount,
          totalCharCount: event.totalCount,
          visibleText: _synchronizer.visibleText,
        ));
        notifyListeners();
      } else if (event is TextCompleteEvent) {
        _eventController.add(const DialogueCompletedEvent());

        // Handle auto mode
        if (_playbackMode == DialoguePlaybackMode.auto &&
            !_voiceController.isPlaying) {
          _scheduleAutoAdvance();
        }

        notifyListeners();
      }
    });

    // Also listen for voice completion in auto mode
    _voiceController.voiceEvents.listen((event) {
      if (event is VoiceCompletedEvent || event is VoiceStoppedEvent) {
        if (_playbackMode == DialoguePlaybackMode.auto &&
            _synchronizer.isTextComplete) {
          _scheduleAutoAdvance();
        }
      }
    });
  }

  void _handleSkipMode() {
    final isRead = _readStateManager?.isRead(
          _currentChapterId ?? '',
          _currentNodeId ?? '',
          _currentDialogueIndex,
        ) ??
        false;

    if (_config.skipUnread || isRead) {
      _synchronizer.handleSkipMode();
      _scheduleAutoAdvance(immediate: true);
    }
  }

  void _scheduleAutoAdvance({bool immediate = false}) {
    _autoAdvanceTimer?.cancel();

    final delay = immediate
        ? const Duration(milliseconds: 100)
        : Duration(milliseconds: (_config.autoDelay * 1000).toInt());

    _autoAdvanceTimer = Timer(delay, () {
      if (_playbackMode == DialoguePlaybackMode.auto ||
          _playbackMode == DialoguePlaybackMode.skip) {
        _markAsRead();
        _eventController.add(const DialogueAdvancedEvent());
        onRequestAdvance?.call();
      }
    });
  }

  void _markAsRead() {
    if (_currentChapterId != null && _currentNodeId != null) {
      _readStateManager?.markRead(
        _currentChapterId!,
        _currentNodeId!,
        _currentDialogueIndex,
      );
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _syncSubscription?.cancel();
    _eventController.close();
    _synchronizer.dispose();
    _voiceController.dispose();
    super.dispose();
  }
}
