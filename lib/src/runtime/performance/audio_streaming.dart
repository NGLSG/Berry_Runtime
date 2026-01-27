/// Audio Streaming System
///
/// Implements streaming playback for large audio files (BGM) to reduce
/// memory usage and improve initial load times.
///
/// Requirements: 24.4

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Audio streaming configuration
class AudioStreamConfig {
  /// Buffer size in bytes
  final int bufferSize;

  /// Number of buffers to maintain
  final int bufferCount;

  /// Prebuffer duration before playback starts
  final Duration prebufferDuration;

  /// Whether to enable low-latency mode
  final bool lowLatencyMode;

  /// Maximum file size for full loading (larger files use streaming)
  final int streamingThreshold;

  const AudioStreamConfig({
    this.bufferSize = 64 * 1024, // 64 KB
    this.bufferCount = 4,
    this.prebufferDuration = const Duration(milliseconds: 500),
    this.lowLatencyMode = false,
    this.streamingThreshold = 5 * 1024 * 1024, // 5 MB
  });

  /// Default config for BGM (large files, can buffer)
  static const bgm = AudioStreamConfig(
    bufferSize: 128 * 1024,
    bufferCount: 4,
    prebufferDuration: Duration(seconds: 1),
    lowLatencyMode: false,
    streamingThreshold: 2 * 1024 * 1024,
  );

  /// Config for voice (medium files, low latency)
  static const voice = AudioStreamConfig(
    bufferSize: 32 * 1024,
    bufferCount: 2,
    prebufferDuration: Duration(milliseconds: 200),
    lowLatencyMode: true,
    streamingThreshold: 10 * 1024 * 1024,
  );

  /// Config for SFX (small files, immediate playback)
  static const sfx = AudioStreamConfig(
    bufferSize: 16 * 1024,
    bufferCount: 1,
    prebufferDuration: Duration.zero,
    lowLatencyMode: true,
    streamingThreshold: 1 * 1024 * 1024,
  );

  Map<String, dynamic> toJson() => {
        'bufferSize': bufferSize,
        'bufferCount': bufferCount,
        'prebufferDuration': prebufferDuration.inMilliseconds,
        'lowLatencyMode': lowLatencyMode,
        'streamingThreshold': streamingThreshold,
      };

  factory AudioStreamConfig.fromJson(Map<String, dynamic> json) {
    return AudioStreamConfig(
      bufferSize: json['bufferSize'] as int? ?? 64 * 1024,
      bufferCount: json['bufferCount'] as int? ?? 4,
      prebufferDuration: Duration(
        milliseconds: json['prebufferDuration'] as int? ?? 500,
      ),
      lowLatencyMode: json['lowLatencyMode'] as bool? ?? false,
      streamingThreshold: json['streamingThreshold'] as int? ?? 5 * 1024 * 1024,
    );
  }
}

/// Audio buffer state
enum BufferState {
  /// Buffer is empty
  empty,

  /// Buffer is being filled
  filling,

  /// Buffer is ready for playback
  ready,

  /// Buffer is being played
  playing,

  /// Buffer playback complete
  consumed,
}

/// Audio buffer
class AudioBuffer {
  /// Buffer index
  final int index;

  /// Buffer data
  Uint8List? data;

  /// Current state
  BufferState state;

  /// Start position in the audio file
  int startPosition;

  /// End position in the audio file
  int endPosition;

  /// Timestamp when buffer was filled
  DateTime? filledAt;

  AudioBuffer({
    required this.index,
    this.data,
    this.state = BufferState.empty,
    this.startPosition = 0,
    this.endPosition = 0,
    this.filledAt,
  });

  /// Get buffer size
  int get size => data?.length ?? 0;

  /// Check if buffer is valid
  bool get isValid => data != null && state == BufferState.ready;

  /// Clear buffer
  void clear() {
    data = null;
    state = BufferState.empty;
    startPosition = 0;
    endPosition = 0;
    filledAt = null;
  }
}

/// Streaming state
enum StreamingState {
  /// Not started
  idle,

  /// Buffering initial data
  buffering,

  /// Playing and streaming
  playing,

  /// Paused
  paused,

  /// Seeking to new position
  seeking,

  /// Reached end of stream
  ended,

  /// Error occurred
  error,
}

/// Audio stream source interface
abstract class AudioStreamSource {
  /// Get total file size
  Future<int> getFileSize();

  /// Read bytes from position
  Future<Uint8List> readBytes(int position, int length);

  /// Get audio duration (if available)
  Future<Duration?> getDuration();

  /// Close the source
  Future<void> close();
}

/// File-based audio stream source
class FileAudioStreamSource implements AudioStreamSource {
  final String filePath;
  int? _cachedSize;

  FileAudioStreamSource(this.filePath);

  @override
  Future<int> getFileSize() async {
    // In real implementation, get actual file size
    _cachedSize ??= 10 * 1024 * 1024; // Mock 10 MB
    return _cachedSize!;
  }

  @override
  Future<Uint8List> readBytes(int position, int length) async {
    // In real implementation, read from file
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 10));
    return Uint8List(length);
  }

  @override
  Future<Duration?> getDuration() async {
    // Would parse audio header to get duration
    return const Duration(minutes: 3);
  }

  @override
  Future<void> close() async {
    // Close file handle
  }
}

/// Audio stream player
class AudioStreamPlayer extends ChangeNotifier {
  final AudioStreamSource _source;
  final AudioStreamConfig _config;

  /// Circular buffer array
  late final List<AudioBuffer> _buffers;

  /// Current streaming state
  StreamingState _state = StreamingState.idle;

  /// Current playback position in bytes
  int _playbackPosition = 0;

  /// Total file size
  int _totalSize = 0;

  /// Audio duration
  Duration? _duration;

  /// Current buffer index being played
  int _currentBufferIndex = 0;

  /// Buffer fill task
  Timer? _bufferFillTimer;

  /// Playback progress stream
  final _progressController = StreamController<double>.broadcast();

  /// State change stream
  final _stateController = StreamController<StreamingState>.broadcast();

  AudioStreamPlayer({
    required AudioStreamSource source,
    AudioStreamConfig config = AudioStreamConfig.bgm,
  })  : _source = source,
        _config = config {
    _buffers = List.generate(
      _config.bufferCount,
      (i) => AudioBuffer(index: i),
    );
  }

  /// Get current state
  StreamingState get state => _state;

  /// Get playback progress (0.0 - 1.0)
  double get progress => _totalSize > 0 ? _playbackPosition / _totalSize : 0.0;

  /// Get current position as duration
  Duration get position {
    if (_duration == null || _totalSize == 0) return Duration.zero;
    return Duration(
      milliseconds: (_duration!.inMilliseconds * progress).round(),
    );
  }

  /// Get total duration
  Duration? get duration => _duration;

  /// Get progress stream
  Stream<double> get progressStream => _progressController.stream;

  /// Get state stream
  Stream<StreamingState> get stateStream => _stateController.stream;

  /// Initialize the stream
  Future<void> initialize() async {
    _totalSize = await _source.getFileSize();
    _duration = await _source.getDuration();
    _setState(StreamingState.idle);
  }

  /// Start playback
  Future<void> play() async {
    if (_state == StreamingState.playing) return;

    if (_state == StreamingState.idle) {
      await _startBuffering();
    } else if (_state == StreamingState.paused) {
      _setState(StreamingState.playing);
      _startBufferFillLoop();
    }
  }

  /// Pause playback
  void pause() {
    if (_state != StreamingState.playing) return;
    _setState(StreamingState.paused);
    _stopBufferFillLoop();
  }

  /// Stop playback
  Future<void> stop() async {
    _stopBufferFillLoop();
    _playbackPosition = 0;
    _currentBufferIndex = 0;
    for (final buffer in _buffers) {
      buffer.clear();
    }
    _setState(StreamingState.idle);
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_duration == null || _totalSize == 0) return;

    _setState(StreamingState.seeking);
    _stopBufferFillLoop();

    // Calculate byte position
    final progress = position.inMilliseconds / _duration!.inMilliseconds;
    _playbackPosition = (progress * _totalSize).round().clamp(0, _totalSize);

    // Clear all buffers
    for (final buffer in _buffers) {
      buffer.clear();
    }
    _currentBufferIndex = 0;

    // Refill buffers from new position
    await _fillBuffers();

    if (_state != StreamingState.error) {
      _setState(StreamingState.playing);
      _startBufferFillLoop();
    }
  }

  /// Seek by percentage (0.0 - 1.0)
  Future<void> seekToProgress(double progress) async {
    if (_duration == null) return;
    final position = Duration(
      milliseconds: (_duration!.inMilliseconds * progress.clamp(0.0, 1.0)).round(),
    );
    await seek(position);
  }

  Future<void> _startBuffering() async {
    _setState(StreamingState.buffering);

    try {
      await _fillBuffers();

      // Wait for prebuffer
      if (_config.prebufferDuration > Duration.zero) {
        await Future.delayed(_config.prebufferDuration);
      }

      _setState(StreamingState.playing);
      _startBufferFillLoop();
    } catch (e) {
      _setState(StreamingState.error);
    }
  }

  Future<void> _fillBuffers() async {
    for (int i = 0; i < _config.bufferCount; i++) {
      final buffer = _buffers[i];
      if (buffer.state == BufferState.empty ||
          buffer.state == BufferState.consumed) {
        await _fillBuffer(buffer);
      }
    }
  }

  Future<void> _fillBuffer(AudioBuffer buffer) async {
    if (_playbackPosition >= _totalSize) {
      buffer.state = BufferState.consumed;
      return;
    }

    buffer.state = BufferState.filling;

    final startPos = _playbackPosition;
    final length = (_totalSize - startPos).clamp(0, _config.bufferSize);

    if (length <= 0) {
      buffer.state = BufferState.consumed;
      return;
    }

    try {
      buffer.data = await _source.readBytes(startPos, length);
      buffer.startPosition = startPos;
      buffer.endPosition = startPos + length;
      buffer.filledAt = DateTime.now();
      buffer.state = BufferState.ready;

      _playbackPosition = buffer.endPosition;
    } catch (e) {
      buffer.state = BufferState.empty;
    }
  }

  void _startBufferFillLoop() {
    _bufferFillTimer?.cancel();
    _bufferFillTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _onBufferTick(),
    );
  }

  void _stopBufferFillLoop() {
    _bufferFillTimer?.cancel();
    _bufferFillTimer = null;
  }

  void _onBufferTick() {
    if (_state != StreamingState.playing) return;

    // Check if current buffer is consumed
    final currentBuffer = _buffers[_currentBufferIndex];
    if (currentBuffer.state == BufferState.consumed) {
      // Move to next buffer
      _currentBufferIndex = (_currentBufferIndex + 1) % _config.bufferCount;

      // Check if we've reached the end
      if (_buffers.every((b) => b.state == BufferState.consumed)) {
        _setState(StreamingState.ended);
        _stopBufferFillLoop();
        return;
      }
    }

    // Fill any empty buffers
    for (final buffer in _buffers) {
      if (buffer.state == BufferState.empty ||
          buffer.state == BufferState.consumed) {
        _fillBuffer(buffer);
      }
    }

    // Update progress
    _progressController.add(progress);
    notifyListeners();
  }

  void _setState(StreamingState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      notifyListeners();
    }
  }

  /// Get buffer statistics
  Map<String, dynamic> getBufferStats() {
    int readyBuffers = 0;
    int totalBuffered = 0;

    for (final buffer in _buffers) {
      if (buffer.state == BufferState.ready) {
        readyBuffers++;
        totalBuffered += buffer.size;
      }
    }

    return {
      'totalBuffers': _config.bufferCount,
      'readyBuffers': readyBuffers,
      'totalBuffered': totalBuffered,
      'bufferSize': _config.bufferSize,
      'playbackPosition': _playbackPosition,
      'totalSize': _totalSize,
      'progress': progress,
      'state': _state.name,
    };
  }

  @override
  void dispose() {
    _stopBufferFillLoop();
    _progressController.close();
    _stateController.close();
    _source.close();
    super.dispose();
  }
}


/// Audio streaming manager
///
/// Manages multiple audio streams with automatic streaming/loading decision
class AudioStreamingManager extends ChangeNotifier {
  final AudioStreamConfig _bgmConfig;
  final AudioStreamConfig _voiceConfig;
  final AudioStreamConfig _sfxConfig;

  /// Active stream players
  final Map<String, AudioStreamPlayer> _players = {};

  /// Fully loaded audio (for small files)
  final Map<String, Uint8List> _loadedAudio = {};

  /// Statistics
  int _streamedCount = 0;
  int _loadedCount = 0;
  int _totalBytesStreamed = 0;
  int _totalBytesLoaded = 0;

  AudioStreamingManager({
    AudioStreamConfig bgmConfig = AudioStreamConfig.bgm,
    AudioStreamConfig voiceConfig = AudioStreamConfig.voice,
    AudioStreamConfig sfxConfig = AudioStreamConfig.sfx,
  })  : _bgmConfig = bgmConfig,
        _voiceConfig = voiceConfig,
        _sfxConfig = sfxConfig;

  /// Get statistics
  Map<String, dynamic> get statistics => {
        'streamedCount': _streamedCount,
        'loadedCount': _loadedCount,
        'totalBytesStreamed': _totalBytesStreamed,
        'totalBytesLoaded': _totalBytesLoaded,
        'activeStreams': _players.length,
        'loadedAudio': _loadedAudio.length,
      };

  /// Play audio (automatically decides streaming vs loading)
  Future<void> playAudio({
    required String id,
    required String path,
    required AudioType type,
    bool loop = false,
  }) async {
    final config = _getConfig(type);

    // Check file size to decide streaming vs loading
    final source = FileAudioStreamSource(path);
    final fileSize = await source.getFileSize();

    if (fileSize > config.streamingThreshold) {
      // Use streaming for large files
      await _playStreaming(id, source, config, loop);
    } else {
      // Load fully for small files
      await _playLoaded(id, path, fileSize);
    }
  }

  /// Stop audio
  Future<void> stopAudio(String id) async {
    final player = _players.remove(id);
    if (player != null) {
      await player.stop();
      player.dispose();
    }
    _loadedAudio.remove(id);
    notifyListeners();
  }

  /// Pause audio
  void pauseAudio(String id) {
    _players[id]?.pause();
  }

  /// Resume audio
  void resumeAudio(String id) {
    _players[id]?.play();
  }

  /// Seek audio
  Future<void> seekAudio(String id, Duration position) async {
    await _players[id]?.seek(position);
  }

  /// Get playback progress
  double getProgress(String id) {
    return _players[id]?.progress ?? 0.0;
  }

  /// Get playback state
  StreamingState? getState(String id) {
    return _players[id]?.state;
  }

  /// Stop all audio
  Future<void> stopAll() async {
    for (final id in _players.keys.toList()) {
      await stopAudio(id);
    }
    _loadedAudio.clear();
    notifyListeners();
  }

  /// Preload audio for faster playback
  Future<void> preloadAudio({
    required String id,
    required String path,
    required AudioType type,
  }) async {
    final config = _getConfig(type);
    final source = FileAudioStreamSource(path);
    final fileSize = await source.getFileSize();

    if (fileSize <= config.streamingThreshold) {
      // Preload small files
      final data = await source.readBytes(0, fileSize);
      _loadedAudio[id] = data;
      _loadedCount++;
      _totalBytesLoaded += fileSize;
    }
    // Large files will be streamed on demand
  }

  Future<void> _playStreaming(
    String id,
    AudioStreamSource source,
    AudioStreamConfig config,
    bool loop,
  ) async {
    // Stop existing player if any
    await stopAudio(id);

    final player = AudioStreamPlayer(source: source, config: config);
    await player.initialize();

    _players[id] = player;
    _streamedCount++;

    // Track bytes streamed
    player.progressStream.listen((progress) {
      // Update statistics
    });

    await player.play();
    notifyListeners();
  }

  Future<void> _playLoaded(String id, String path, int fileSize) async {
    // Stop existing if any
    await stopAudio(id);

    // Load if not already loaded
    if (!_loadedAudio.containsKey(id)) {
      final source = FileAudioStreamSource(path);
      final data = await source.readBytes(0, fileSize);
      _loadedAudio[id] = data;
      _loadedCount++;
      _totalBytesLoaded += fileSize;
    }

    // In real implementation, play using audio player
    notifyListeners();
  }

  AudioStreamConfig _getConfig(AudioType type) {
    switch (type) {
      case AudioType.bgm:
        return _bgmConfig;
      case AudioType.voice:
        return _voiceConfig;
      case AudioType.sfx:
        return _sfxConfig;
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _loadedAudio.clear();
    super.dispose();
  }
}

/// Audio type for streaming decisions
enum AudioType {
  bgm,
  voice,
  sfx,
}
