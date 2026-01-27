/// Audio Manager for VN Runtime
/// 
/// Handles BGM, SFX, and voice playback with fade effects.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vn_node.dart';

/// Audio channel types
enum VNAudioChannel {
  bgm,
  sfx,
  voice,
  ambient,
}

/// Audio playback state
enum AudioPlaybackState {
  stopped,
  playing,
  paused,
  fadingIn,
  fadingOut,
}

/// Configuration for audio playback
class AudioPlayConfig {
  final String audioId;
  final String path;
  final VNAudioChannel channel;
  final double volume;
  final bool loop;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;

  const AudioPlayConfig({
    required this.audioId,
    required this.path,
    required this.channel,
    this.volume = 1.0,
    this.loop = false,
    this.fadeInDuration,
    this.fadeOutDuration,
  });
}

/// State of an audio track
class AudioTrackState {
  final String audioId;
  final String path;
  final VNAudioChannel channel;
  final AudioPlaybackState state;
  final double volume;
  final double currentVolume;
  final bool loop;
  final Duration position;
  final Duration? duration;

  const AudioTrackState({
    required this.audioId,
    required this.path,
    required this.channel,
    this.state = AudioPlaybackState.stopped,
    this.volume = 1.0,
    this.currentVolume = 1.0,
    this.loop = false,
    this.position = Duration.zero,
    this.duration,
  });

  AudioTrackState copyWith({
    String? audioId,
    String? path,
    VNAudioChannel? channel,
    AudioPlaybackState? state,
    double? volume,
    double? currentVolume,
    bool? loop,
    Duration? position,
    Duration? duration,
  }) {
    return AudioTrackState(
      audioId: audioId ?? this.audioId,
      path: path ?? this.path,
      channel: channel ?? this.channel,
      state: state ?? this.state,
      volume: volume ?? this.volume,
      currentVolume: currentVolume ?? this.currentVolume,
      loop: loop ?? this.loop,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

/// Abstract audio player interface
/// Implementations can use audioplayers, just_audio, or other packages
abstract class VNAudioPlayer {
  Future<void> play(String path, {bool loop = false});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> seek(Duration position);
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get completionStream;
  Future<void> dispose();
}

/// Mock audio player for testing/preview without actual audio
class MockAudioPlayer implements VNAudioPlayer {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _completionController = StreamController<bool>.broadcast();
  
  bool _isPlaying = false;
  bool _loop = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);
  Timer? _positionTimer;

  @override
  Future<void> play(String path, {bool loop = false}) async {
    _loop = loop;
    _isPlaying = true;
    _position = Duration.zero;
    _durationController.add(_duration);
    
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      _position += const Duration(milliseconds: 100);
      _positionController.add(_position);
      
      if (_position >= _duration) {
        if (_loop) {
          _position = Duration.zero;
        } else {
          _isPlaying = false;
          _completionController.add(true);
          timer.cancel();
        }
      }
    });
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    if (!_isPlaying) {
      _isPlaying = true;
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isPlaying) {
          timer.cancel();
          return;
        }
        
        _position += const Duration(milliseconds: 100);
        _positionController.add(_position);
        
        if (_position >= _duration) {
          if (_loop) {
            _position = Duration.zero;
          } else {
            _isPlaying = false;
            _completionController.add(true);
            timer.cancel();
          }
        }
      });
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _position = Duration.zero;
    _positionTimer?.cancel();
    _positionController.add(_position);
  }

  @override
  Future<void> setVolume(double volume) async {
    // Mock implementation - no actual volume change
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(_position);
  }

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<bool> get completionStream => _completionController.stream;

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _positionController.close();
    await _durationController.close();
    await _completionController.close();
  }
}

/// Audio manager for VN runtime
class VNAudioManager extends ChangeNotifier {
  final VNAudioPlayer Function()? _playerFactory;
  
  // Channel volumes (user settings)
  double _bgmVolume = 1.0;
  double _sfxVolume = 1.0;
  double _voiceVolume = 1.0;
  double _ambientVolume = 1.0;
  
  // Active players per channel
  final Map<VNAudioChannel, VNAudioPlayer> _players = {};
  final Map<VNAudioChannel, AudioTrackState> _trackStates = {};
  
  // Fade timers
  final Map<VNAudioChannel, Timer> _fadeTimers = {};
  
  // Voice completion callback
  VoidCallback? onVoiceComplete;

  VNAudioManager({VNAudioPlayer Function()? playerFactory})
      : _playerFactory = playerFactory;

  // Volume getters/setters
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  double get voiceVolume => _voiceVolume;
  double get ambientVolume => _ambientVolume;

  set bgmVolume(double value) {
    _bgmVolume = value.clamp(0.0, 1.0);
    _updateChannelVolume(VNAudioChannel.bgm);
    notifyListeners();
  }

  set sfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    _updateChannelVolume(VNAudioChannel.sfx);
    notifyListeners();
  }

  set voiceVolume(double value) {
    _voiceVolume = value.clamp(0.0, 1.0);
    _updateChannelVolume(VNAudioChannel.voice);
    notifyListeners();
  }

  set ambientVolume(double value) {
    _ambientVolume = value.clamp(0.0, 1.0);
    _updateChannelVolume(VNAudioChannel.ambient);
    notifyListeners();
  }

  /// Get track state for a channel
  AudioTrackState? getTrackState(VNAudioChannel channel) => _trackStates[channel];

  /// Play audio on a channel
  Future<void> play(AudioPlayConfig config) async {
    final player = _getOrCreatePlayer(config.channel);
    
    // Stop any existing audio on this channel
    await _stopChannel(config.channel);
    
    // Update state
    _trackStates[config.channel] = AudioTrackState(
      audioId: config.audioId,
      path: config.path,
      channel: config.channel,
      state: config.fadeInDuration != null 
          ? AudioPlaybackState.fadingIn 
          : AudioPlaybackState.playing,
      volume: config.volume,
      currentVolume: config.fadeInDuration != null ? 0.0 : config.volume,
      loop: config.loop,
    );
    
    // Set initial volume
    final channelVolume = _getChannelVolume(config.channel);
    final initialVolume = config.fadeInDuration != null 
        ? 0.0 
        : config.volume * channelVolume;
    await player.setVolume(initialVolume);
    
    // Start playback
    await player.play(config.path, loop: config.loop);
    
    // Handle fade in
    if (config.fadeInDuration != null) {
      await _fadeIn(config.channel, config.fadeInDuration!, config.volume);
    }
    
    // Listen for completion (voice channel)
    if (config.channel == VNAudioChannel.voice) {
      player.completionStream.listen((_) {
        onVoiceComplete?.call();
      });
    }
    
    notifyListeners();
  }

  /// Stop audio on a channel with optional fade out
  Future<void> stop(VNAudioChannel channel, {Duration? fadeOutDuration}) async {
    if (fadeOutDuration != null) {
      await _fadeOut(channel, fadeOutDuration);
    }
    await _stopChannel(channel);
    notifyListeners();
  }

  /// Pause audio on a channel
  Future<void> pause(VNAudioChannel channel) async {
    final player = _players[channel];
    if (player != null) {
      await player.pause();
      final state = _trackStates[channel];
      if (state != null) {
        _trackStates[channel] = state.copyWith(state: AudioPlaybackState.paused);
      }
      notifyListeners();
    }
  }

  /// Resume audio on a channel
  Future<void> resume(VNAudioChannel channel) async {
    final player = _players[channel];
    if (player != null) {
      await player.resume();
      final state = _trackStates[channel];
      if (state != null) {
        _trackStates[channel] = state.copyWith(state: AudioPlaybackState.playing);
      }
      notifyListeners();
    }
  }

  /// Crossfade to new BGM
  Future<void> crossfadeBgm(
    AudioPlayConfig newConfig, {
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    // Start fade out of current BGM
    final fadeOutFuture = _fadeOut(VNAudioChannel.bgm, duration);
    
    // Wait a bit then start new BGM with fade in
    await Future.delayed(duration ~/ 2);
    
    // Play new BGM with fade in
    await play(newConfig.copyWith(fadeInDuration: duration));
    
    await fadeOutFuture;
  }

  /// Play SFX (one-shot, doesn't interrupt other SFX)
  Future<void> playSfx(String audioId, String path, {double volume = 1.0}) async {
    // For SFX, we create a new player each time
    final player = _playerFactory?.call() ?? MockAudioPlayer();
    
    final effectiveVolume = volume * _sfxVolume;
    await player.setVolume(effectiveVolume);
    await player.play(path, loop: false);
    
    // Dispose player when done
    player.completionStream.listen((_) {
      player.dispose();
    });
  }

  /// Play voice line
  Future<void> playVoice(String audioId, String path, {double volume = 1.0}) async {
    await play(AudioPlayConfig(
      audioId: audioId,
      path: path,
      channel: VNAudioChannel.voice,
      volume: volume,
      loop: false,
    ));
  }

  /// Stop voice playback
  Future<void> stopVoice() async {
    await stop(VNAudioChannel.voice);
  }

  /// Stop all audio
  Future<void> stopAll() async {
    for (final channel in VNAudioChannel.values) {
      await _stopChannel(channel);
    }
    notifyListeners();
  }

  /// Pause all audio
  Future<void> pauseAll() async {
    for (final channel in VNAudioChannel.values) {
      await pause(channel);
    }
  }

  /// Resume all audio
  Future<void> resumeAll() async {
    for (final channel in VNAudioChannel.values) {
      final state = _trackStates[channel];
      if (state?.state == AudioPlaybackState.paused) {
        await resume(channel);
      }
    }
  }

  VNAudioPlayer _getOrCreatePlayer(VNAudioChannel channel) {
    if (!_players.containsKey(channel)) {
      _players[channel] = _playerFactory?.call() ?? MockAudioPlayer();
    }
    return _players[channel]!;
  }

  Future<void> _stopChannel(VNAudioChannel channel) async {
    _fadeTimers[channel]?.cancel();
    
    final player = _players[channel];
    if (player != null) {
      await player.stop();
    }
    
    _trackStates.remove(channel);
  }

  double _getChannelVolume(VNAudioChannel channel) {
    switch (channel) {
      case VNAudioChannel.bgm:
        return _bgmVolume;
      case VNAudioChannel.sfx:
        return _sfxVolume;
      case VNAudioChannel.voice:
        return _voiceVolume;
      case VNAudioChannel.ambient:
        return _ambientVolume;
    }
  }

  void _updateChannelVolume(VNAudioChannel channel) {
    final player = _players[channel];
    final state = _trackStates[channel];
    if (player != null && state != null) {
      final effectiveVolume = state.volume * _getChannelVolume(channel);
      player.setVolume(effectiveVolume);
    }
  }

  Future<void> _fadeIn(VNAudioChannel channel, Duration duration, double targetVolume) async {
    final player = _players[channel];
    if (player == null) return;

    final completer = Completer<void>();
    final startTime = DateTime.now();
    final channelVolume = _getChannelVolume(channel);

    _fadeTimers[channel]?.cancel();
    _fadeTimers[channel] = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      final currentVolume = targetVolume * progress;
      player.setVolume(currentVolume * channelVolume);
      
      final state = _trackStates[channel];
      if (state != null) {
        _trackStates[channel] = state.copyWith(currentVolume: currentVolume);
      }
      notifyListeners();

      if (progress >= 1.0) {
        timer.cancel();
        final finalState = _trackStates[channel];
        if (finalState != null) {
          _trackStates[channel] = finalState.copyWith(
            state: AudioPlaybackState.playing,
            currentVolume: targetVolume,
          );
        }
        notifyListeners();
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> _fadeOut(VNAudioChannel channel, Duration duration) async {
    final player = _players[channel];
    final state = _trackStates[channel];
    if (player == null || state == null) return;

    final completer = Completer<void>();
    final startTime = DateTime.now();
    final startVolume = state.currentVolume;
    final channelVolume = _getChannelVolume(channel);

    _trackStates[channel] = state.copyWith(state: AudioPlaybackState.fadingOut);
    notifyListeners();

    _fadeTimers[channel]?.cancel();
    _fadeTimers[channel] = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      final currentVolume = startVolume * (1.0 - progress);
      player.setVolume(currentVolume * channelVolume);
      
      final currentState = _trackStates[channel];
      if (currentState != null) {
        _trackStates[channel] = currentState.copyWith(currentVolume: currentVolume);
      }
      notifyListeners();

      if (progress >= 1.0) {
        timer.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    for (final timer in _fadeTimers.values) {
      timer.cancel();
    }
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}

/// Extension for AudioPlayConfig
extension AudioPlayConfigExtension on AudioPlayConfig {
  AudioPlayConfig copyWith({
    String? audioId,
    String? path,
    VNAudioChannel? channel,
    double? volume,
    bool? loop,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
  }) {
    return AudioPlayConfig(
      audioId: audioId ?? this.audioId,
      path: path ?? this.path,
      channel: channel ?? this.channel,
      volume: volume ?? this.volume,
      loop: loop ?? this.loop,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
      fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
    );
  }
}

/// Extension to convert AudioChannel to VNAudioChannel
extension AudioChannelExtension on AudioChannel {
  VNAudioChannel toVNAudioChannel() {
    switch (this) {
      case AudioChannel.bgm:
        return VNAudioChannel.bgm;
      case AudioChannel.sfx:
        return VNAudioChannel.sfx;
      case AudioChannel.voice:
        return VNAudioChannel.voice;
      case AudioChannel.ambient:
        return VNAudioChannel.ambient;
    }
  }
}

/// Extension to convert AudioAction to method calls
extension AudioActionExtension on AudioAction {
  Future<void> execute(
    VNAudioManager manager,
    VNAudioChannel channel, {
    String? audioId,
    String? path,
    double volume = 1.0,
    bool loop = false,
    Duration? fadeDuration,
  }) async {
    switch (this) {
      case AudioAction.play:
        if (audioId != null && path != null) {
          await manager.play(AudioPlayConfig(
            audioId: audioId,
            path: path,
            channel: channel,
            volume: volume,
            loop: loop,
            fadeInDuration: fadeDuration,
          ));
        }
        break;
      case AudioAction.stop:
        await manager.stop(channel, fadeOutDuration: fadeDuration);
        break;
      case AudioAction.pause:
        await manager.pause(channel);
        break;
      case AudioAction.resume:
        await manager.resume(channel);
        break;
      case AudioAction.fadeIn:
        if (audioId != null && path != null) {
          await manager.play(AudioPlayConfig(
            audioId: audioId,
            path: path,
            channel: channel,
            volume: volume,
            loop: loop,
            fadeInDuration: fadeDuration ?? const Duration(milliseconds: 1000),
          ));
        }
        break;
      case AudioAction.fadeOut:
        await manager.stop(
          channel,
          fadeOutDuration: fadeDuration ?? const Duration(milliseconds: 1000),
        );
        break;
      case AudioAction.crossfade:
        if (channel == VNAudioChannel.bgm && audioId != null && path != null) {
          await manager.crossfadeBgm(
            AudioPlayConfig(
              audioId: audioId,
              path: path,
              channel: channel,
              volume: volume,
              loop: loop,
            ),
            duration: fadeDuration ?? const Duration(milliseconds: 1000),
          );
        }
        break;
    }
  }
}
