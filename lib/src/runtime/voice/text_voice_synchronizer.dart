/// Text-Voice Synchronizer for VN Runtime
///
/// Coordinates text display with voice playback, supporting both
/// voice-driven mode (text follows voice) and independent mode
/// (text and voice play independently).

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/vn_node.dart';
import 'voice_controller.dart';
import 'voice_timeline.dart';

/// Synchronization mode for text and voice
enum TextVoiceSyncMode {
  /// Voice drives text display - text appears based on voice position
  voiceDriven,

  /// Text and voice play independently - typewriter animation for text
  independent,
}

/// Text synchronization events
abstract class TextSyncEvent {
  const TextSyncEvent();

  factory TextSyncEvent.update(int visibleCount, int totalCount) =
      TextUpdateEvent;
  factory TextSyncEvent.complete() = TextCompleteEvent;
  factory TextSyncEvent.started() = TextStartedEvent;
}

/// Text update event - emitted when visible character count changes
class TextUpdateEvent extends TextSyncEvent {
  final int visibleCount;
  final int totalCount;

  const TextUpdateEvent(this.visibleCount, this.totalCount);

  /// Progress as a value from 0.0 to 1.0
  double get progress =>
      totalCount > 0 ? (visibleCount / totalCount).clamp(0.0, 1.0) : 1.0;

  /// Whether all text is visible
  bool get isComplete => visibleCount >= totalCount;

  @override
  String toString() =>
      'TextUpdateEvent(visible: $visibleCount, total: $totalCount)';
}

/// Text complete event - emitted when all text is visible
class TextCompleteEvent extends TextSyncEvent {
  const TextCompleteEvent();

  @override
  String toString() => 'TextCompleteEvent()';
}

/// Text started event - emitted when text display begins
class TextStartedEvent extends TextSyncEvent {
  const TextStartedEvent();

  @override
  String toString() => 'TextStartedEvent()';
}

/// Result of handling user interaction (click/tap)
enum AdvanceResult {
  /// Text animation was completed (was still animating)
  textCompleted,

  /// Voice was stopped (text was complete but voice still playing)
  voiceStopped,

  /// Ready to advance to next dialogue
  advance,

  /// No action taken (nothing to do)
  none,
}

/// Text-Voice Synchronizer
///
/// Coordinates the display of dialogue text with voice audio playback.
/// Supports two modes:
/// - Voice-driven: Text appears in sync with voice playback position
/// - Independent: Text uses typewriter animation, voice plays separately
class TextVoiceSynchronizer extends ChangeNotifier {
  final VoiceController _voiceController;

  // Sync mode
  TextVoiceSyncMode _syncMode = TextVoiceSyncMode.independent;

  // Current dialogue state
  String _currentText = '';
  int _visibleCharCount = 0;
  bool _isTextComplete = false;
  bool _isAnimating = false;

  // Typewriter animation settings
  double _textSpeed = 1.0; // Characters per 50ms at speed 1.0
  double _baseCharsPerTick = 1.0;

  // Animation timer
  Timer? _typewriterTimer;

  // Event stream
  final _syncEventController = StreamController<TextSyncEvent>.broadcast();

  // Voice event subscription
  StreamSubscription<VoiceEvent>? _voiceSubscription;

  TextVoiceSynchronizer({required VoiceController voiceController})
      : _voiceController = voiceController;

  /// Stream of text sync events
  Stream<TextSyncEvent> get syncEvents => _syncEventController.stream;

  /// Current synchronization mode
  TextVoiceSyncMode get syncMode => _syncMode;

  set syncMode(TextVoiceSyncMode mode) {
    if (_syncMode != mode) {
      _syncMode = mode;
      notifyListeners();
    }
  }

  /// Text display speed (0.0 to 2.0, where 1.0 is normal)
  double get textSpeed => _textSpeed;

  set textSpeed(double speed) {
    _textSpeed = speed.clamp(0.1, 3.0);
    notifyListeners();
  }

  /// Current visible character count
  int get visibleCharCount => _visibleCharCount;

  /// Total character count in current text
  int get totalCharCount => _currentText.length;

  /// Whether all text is currently visible
  bool get isTextComplete => _isTextComplete;

  /// Whether text animation is in progress
  bool get isAnimating => _isAnimating;

  /// Current text being displayed
  String get currentText => _currentText;

  /// Get the visible portion of the text
  String get visibleText {
    if (_visibleCharCount >= _currentText.length) {
      return _currentText;
    }
    return _currentText.substring(0, _visibleCharCount);
  }

  /// Start synchronized playback of dialogue
  ///
  /// [dialogue] - The dialogue line to display
  /// [voicePath] - Path to voice audio file (if available)
  /// [timeline] - Voice timeline for sync (if available)
  Future<void> startSync(
    DialogueLine dialogue, {
    String? voicePath,
    VoiceTimeline? timeline,
  }) async {
    // Reset state
    _stopTypewriter();
    _voiceSubscription?.cancel();

    _currentText = dialogue.text;
    _visibleCharCount = 0;
    _isTextComplete = false;
    _isAnimating = true;

    _syncEventController.add(const TextStartedEvent());

    final hasVoice = dialogue.voiceId != null && voicePath != null;
    final hasTimeline = timeline != null && timeline.isNotEmpty;

    if (hasVoice) {
      // Play voice
      await _voiceController.play(
        dialogue.voiceId!,
        voicePath!,
        timeline: timeline,
      );

      if (hasTimeline && _syncMode == TextVoiceSyncMode.voiceDriven) {
        // Voice-driven mode: text follows voice position
        _startVoiceDrivenSync(timeline!);
      } else {
        // Independent mode: typewriter animation + voice
        _startTypewriterAnimation();
      }
    } else {
      // No voice: pure typewriter animation
      _startTypewriterAnimation();
    }

    notifyListeners();
  }

  /// Show all text immediately
  void showAllText() {
    _stopTypewriter();
    _voiceSubscription?.cancel();

    _visibleCharCount = _currentText.length;
    _isTextComplete = true;
    _isAnimating = false;

    _syncEventController.add(TextUpdateEvent(_visibleCharCount, _currentText.length));
    _syncEventController.add(const TextCompleteEvent());

    notifyListeners();
  }

  /// Handle user click/tap interaction
  ///
  /// Returns the result indicating what action was taken
  AdvanceResult handleClick() {
    if (!_isTextComplete) {
      // Text still animating - complete it immediately
      showAllText();
      return AdvanceResult.textCompleted;
    } else if (_voiceController.isPlaying) {
      // Text complete but voice still playing - stop voice
      _voiceController.stop();
      return AdvanceResult.voiceStopped;
    } else {
      // Both complete - ready to advance
      return AdvanceResult.advance;
    }
  }

  /// Handle auto mode - wait for both text and voice to complete
  ///
  /// [autoDelay] - Additional delay after completion (in seconds)
  Future<void> handleAutoMode(double autoDelay) async {
    // Wait for text to complete
    if (!_isTextComplete) {
      await _waitForTextComplete();
    }

    // Wait for voice to complete
    if (_voiceController.isPlaying) {
      await _waitForVoiceComplete();
    }

    // Additional delay
    if (autoDelay > 0) {
      await Future.delayed(Duration(milliseconds: (autoDelay * 1000).toInt()));
    }
  }

  /// Handle skip mode - immediately complete everything
  void handleSkipMode() {
    showAllText();
    if (_voiceController.isPlaying) {
      _voiceController.stop();
    }
  }

  /// Reset the synchronizer state
  void reset() {
    _stopTypewriter();
    _voiceSubscription?.cancel();

    _currentText = '';
    _visibleCharCount = 0;
    _isTextComplete = false;
    _isAnimating = false;

    notifyListeners();
  }

  void _startVoiceDrivenSync(VoiceTimeline timeline) {
    _voiceSubscription = _voiceController.voiceEvents.listen((event) {
      if (event is VoiceProgressEvent) {
        final newCount = timeline.getVisibleCharCount(event.position);
        if (newCount != _visibleCharCount) {
          _visibleCharCount = newCount;
          _syncEventController.add(
            TextUpdateEvent(_visibleCharCount, _currentText.length),
          );
          notifyListeners();
        }

        // Check if text is complete
        if (_visibleCharCount >= _currentText.length && !_isTextComplete) {
          _isTextComplete = true;
          _isAnimating = false;
          _syncEventController.add(const TextCompleteEvent());
          notifyListeners();
        }
      } else if (event is VoiceCompletedEvent || event is VoiceStoppedEvent) {
        // Voice ended - show all remaining text
        if (!_isTextComplete) {
          showAllText();
        }
      }
    });
  }

  void _startTypewriterAnimation() {
    _stopTypewriter();

    // Calculate characters per tick based on speed
    // At speed 1.0, show ~1 character per 50ms (20 chars/second)
    final charsPerTick = _baseCharsPerTick * _textSpeed;

    double charAccumulator = 0;

    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (_isTextComplete) {
          timer.cancel();
          return;
        }

        charAccumulator += charsPerTick;
        final charsToAdd = charAccumulator.floor();
        charAccumulator -= charsToAdd;

        _visibleCharCount = (_visibleCharCount + charsToAdd)
            .clamp(0, _currentText.length);

        _syncEventController.add(
          TextUpdateEvent(_visibleCharCount, _currentText.length),
        );
        notifyListeners();

        if (_visibleCharCount >= _currentText.length) {
          _isTextComplete = true;
          _isAnimating = false;
          _syncEventController.add(const TextCompleteEvent());
          timer.cancel();
          notifyListeners();
        }
      },
    );
  }

  void _stopTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
  }

  Future<void> _waitForTextComplete() async {
    if (_isTextComplete) return;

    final completer = Completer<void>();
    late StreamSubscription<TextSyncEvent> subscription;

    subscription = syncEvents.listen((event) {
      if (event is TextCompleteEvent) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Timeout after 30 seconds to prevent infinite wait
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        subscription.cancel();
        showAllText();
      },
    );
  }

  Future<void> _waitForVoiceComplete() async {
    if (!_voiceController.isPlaying) return;

    final completer = Completer<void>();
    late StreamSubscription<VoiceEvent> subscription;

    subscription = _voiceController.voiceEvents.listen((event) {
      if (event is VoiceCompletedEvent || event is VoiceStoppedEvent) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Timeout after 5 minutes to prevent infinite wait
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        subscription.cancel();
        _voiceController.stop();
      },
    );
  }

  @override
  void dispose() {
    _stopTypewriter();
    _voiceSubscription?.cancel();
    _syncEventController.close();
    super.dispose();
  }
}
