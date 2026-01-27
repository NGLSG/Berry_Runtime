/// Voice Playback Controller for VN Runtime
///
/// Manages voice audio playback with position tracking and event streaming
/// for synchronization with text display.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../rendering/audio_manager.dart';
import 'voice_timeline.dart';

/// Voice playback events
abstract class VoiceEvent {
  const VoiceEvent();

  factory VoiceEvent.progress(Duration position, VoiceTimeline? timeline) =
      VoiceProgressEvent;
  factory VoiceEvent.completed() = VoiceCompletedEvent;
  factory VoiceEvent.stopped() = VoiceStoppedEvent;
  factory VoiceEvent.paused() = VoicePausedEvent;
  factory VoiceEvent.resumed() = VoiceResumedEvent;
  factory VoiceEvent.started(String voiceId) = VoiceStartedEvent;
}

/// Voice progress event - emitted during playback with current position
class VoiceProgressEvent extends VoiceEvent {
  final Duration position;
  final VoiceTimeline? timeline;

  const VoiceProgressEvent(this.position, this.timeline);

  /// Gets the visible character count based on timeline
  int get visibleCharCount =>
      timeline?.getVisibleCharCount(position) ?? 0;

  @override
  String toString() => 'VoiceProgressEvent(position: $position)';
}

/// Voice completed event - emitted when voice playback finishes naturally
class VoiceCompletedEvent extends VoiceEvent {
  const VoiceCompletedEvent();

  @override
  String toString() => 'VoiceCompletedEvent()';
}

/// Voice stopped event - emitted when voice is manually stopped
class VoiceStoppedEvent extends VoiceEvent {
  const VoiceStoppedEvent();

  @override
  String toString() => 'VoiceStoppedEvent()';
}

/// Voice paused event - emitted when voice is paused
class VoicePausedEvent extends VoiceEvent {
  const VoicePausedEvent();

  @override
  String toString() => 'VoicePausedEvent()';
}

/// Voice resumed event - emitted when voice playback resumes
class VoiceResumedEvent extends VoiceEvent {
  const VoiceResumedEvent();

  @override
  String toString() => 'VoiceResumedEvent()';
}

/// Voice started event - emitted when voice playback begins
class VoiceStartedEvent extends VoiceEvent {
  final String voiceId;

  const VoiceStartedEvent(this.voiceId);

  @override
  String toString() => 'VoiceStartedEvent(voiceId: $voiceId)';
}

/// Voice playback state
enum VoicePlaybackState {
  idle,
  playing,
  paused,
  stopped,
}

/// Voice Controller - manages voice playback with synchronization support
class VoiceController extends ChangeNotifier {
  final VNAudioManager _audioManager;

  // Current playback state
  String? _currentVoiceId;
  String? _currentVoicePath;
  VoiceTimeline? _currentTimeline;
  VoicePlaybackState _state = VoicePlaybackState.idle;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;

  // Event stream
  final _voiceEventController = StreamController<VoiceEvent>.broadcast();

  // Position update timer for mock/simulated playback
  Timer? _positionTimer;

  // Subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _completionSubscription;

  VoiceController({required VNAudioManager audioManager})
      : _audioManager = audioManager;

  /// Stream of voice events for synchronization
  Stream<VoiceEvent> get voiceEvents => _voiceEventController.stream;

  /// Current voice ID being played
  String? get currentVoiceId => _currentVoiceId;

  /// Current playback state
  VoicePlaybackState get state => _state;

  /// Whether voice is currently playing
  bool get isPlaying => _state == VoicePlaybackState.playing;

  /// Whether voice is paused
  bool get isPaused => _state == VoicePlaybackState.paused;

  /// Whether voice is idle (not playing or paused)
  bool get isIdle => _state == VoicePlaybackState.idle;

  /// Current playback position
  Duration get currentPosition => _currentPosition;

  /// Total duration of current voice (if known)
  Duration? get totalDuration => _totalDuration;

  /// Current timeline (if available)
  VoiceTimeline? get currentTimeline => _currentTimeline;

  /// Play a voice audio file
  ///
  /// [voiceId] - Unique identifier for the voice
  /// [path] - Path to the audio file
  /// [timeline] - Optional timeline for text synchronization
  Future<void> play(
    String voiceId,
    String path, {
    VoiceTimeline? timeline,
    double volume = 1.0,
  }) async {
    // Stop any currently playing voice
    if (_state == VoicePlaybackState.playing ||
        _state == VoicePlaybackState.paused) {
      await stop();
    }

    _currentVoiceId = voiceId;
    _currentVoicePath = path;
    _currentTimeline = timeline;
    _currentPosition = Duration.zero;
    _state = VoicePlaybackState.playing;

    // Set up completion callback
    _audioManager.onVoiceComplete = _onVoiceComplete;

    // Play through audio manager
    await _audioManager.playVoice(voiceId, path, volume: volume);

    // Emit started event
    _voiceEventController.add(VoiceStartedEvent(voiceId));

    // Start position tracking
    _startPositionTracking();

    notifyListeners();
  }

  /// Stop voice playback
  Future<void> stop() async {
    if (_state == VoicePlaybackState.idle) return;

    _stopPositionTracking();

    await _audioManager.stopVoice();

    _state = VoicePlaybackState.stopped;
    _voiceEventController.add(const VoiceStoppedEvent());

    // Reset state
    _currentVoiceId = null;
    _currentVoicePath = null;
    _currentTimeline = null;
    _currentPosition = Duration.zero;
    _totalDuration = null;
    _state = VoicePlaybackState.idle;

    notifyListeners();
  }

  /// Pause voice playback
  Future<void> pause() async {
    if (_state != VoicePlaybackState.playing) return;

    _stopPositionTracking();

    await _audioManager.pause(VNAudioChannel.voice);

    _state = VoicePlaybackState.paused;
    _voiceEventController.add(const VoicePausedEvent());

    notifyListeners();
  }

  /// Resume voice playback
  Future<void> resume() async {
    if (_state != VoicePlaybackState.paused) return;

    await _audioManager.resume(VNAudioChannel.voice);

    _state = VoicePlaybackState.playing;
    _voiceEventController.add(const VoiceResumedEvent());

    // Resume position tracking
    _startPositionTracking();

    notifyListeners();
  }

  /// Get visible character count at current position
  int getVisibleCharCount() {
    if (_currentTimeline == null) return 0;
    return _currentTimeline!.getVisibleCharCount(_currentPosition);
  }

  void _onVoiceComplete() {
    _stopPositionTracking();

    _state = VoicePlaybackState.idle;
    _voiceEventController.add(const VoiceCompletedEvent());

    // Keep the voice ID for reference but mark as completed
    _currentPosition = _totalDuration ?? _currentPosition;

    notifyListeners();
  }

  void _startPositionTracking() {
    _stopPositionTracking();

    // Get the voice player's position stream from audio manager
    final trackState = _audioManager.getTrackState(VNAudioChannel.voice);
    if (trackState != null) {
      _totalDuration = trackState.duration;
    }

    // Use a timer to simulate position updates
    // In a real implementation, this would listen to the actual audio player
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      _onPositionUpdate,
    );
  }

  void _stopPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _completionSubscription?.cancel();
    _completionSubscription = null;
  }

  void _onPositionUpdate(Timer timer) {
    if (_state != VoicePlaybackState.playing) {
      timer.cancel();
      return;
    }

    // Increment position (simulated - real implementation would get from player)
    _currentPosition += const Duration(milliseconds: 50);

    // Check if we've reached the end based on timeline
    if (_currentTimeline != null &&
        _currentPosition >= _currentTimeline!.totalDuration) {
      _onVoiceComplete();
      return;
    }

    // Emit progress event
    _voiceEventController.add(
      VoiceProgressEvent(_currentPosition, _currentTimeline),
    );
  }

  @override
  void dispose() {
    _stopPositionTracking();
    _voiceEventController.close();
    super.dispose();
  }
}
