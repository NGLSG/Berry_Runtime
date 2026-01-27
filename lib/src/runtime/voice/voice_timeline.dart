/// Voice Timeline Model for VN Runtime
///
/// Provides precise character-level timing for voice-text synchronization.
/// Used to drive text display based on voice playback position.

/// Character timing entry - maps a character index to its start time in the voice
class CharacterTiming {
  /// The character index in the text string
  final int charIndex;

  /// The time when this character should start being displayed
  final Duration startTime;

  const CharacterTiming({
    required this.charIndex,
    required this.startTime,
  });

  Map<String, dynamic> toJson() => {
        'charIndex': charIndex,
        'startTime': startTime.inMilliseconds,
      };

  factory CharacterTiming.fromJson(Map<String, dynamic> json) {
    return CharacterTiming(
      charIndex: json['charIndex'] as int,
      startTime: Duration(milliseconds: json['startTime'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterTiming &&
          runtimeType == other.runtimeType &&
          charIndex == other.charIndex &&
          startTime == other.startTime;

  @override
  int get hashCode => charIndex.hashCode ^ startTime.hashCode;

  @override
  String toString() => 'CharacterTiming(charIndex: $charIndex, startTime: $startTime)';
}

/// Voice timeline - maps voice playback position to visible character count
///
/// This enables voice-driven text display where text appears in sync with
/// the voice audio playback.
class VoiceTimeline {
  /// Total duration of the voice audio
  final Duration totalDuration;

  /// Character timing entries, sorted by startTime
  final List<CharacterTiming> characterTimings;

  const VoiceTimeline({
    required this.totalDuration,
    required this.characterTimings,
  });

  /// Creates an empty timeline (no sync data)
  const VoiceTimeline.empty()
      : totalDuration = Duration.zero,
        characterTimings = const [];

  /// Creates a linear timeline where characters are evenly distributed
  /// across the voice duration
  factory VoiceTimeline.linear({
    required Duration totalDuration,
    required int characterCount,
  }) {
    if (characterCount <= 0 || totalDuration == Duration.zero) {
      return const VoiceTimeline.empty();
    }

    final timings = <CharacterTiming>[];
    final msPerChar = totalDuration.inMilliseconds / characterCount;

    for (int i = 0; i < characterCount; i++) {
      timings.add(CharacterTiming(
        charIndex: i,
        startTime: Duration(milliseconds: (i * msPerChar).round()),
      ));
    }

    return VoiceTimeline(
      totalDuration: totalDuration,
      characterTimings: timings,
    );
  }

  /// Gets the number of characters that should be visible at the given time
  ///
  /// Returns the count of characters whose startTime is <= currentTime
  int getVisibleCharCount(Duration currentTime) {
    if (characterTimings.isEmpty) {
      return 0;
    }

    // If past the total duration, show all characters
    if (currentTime >= totalDuration) {
      return characterTimings.isNotEmpty
          ? characterTimings.last.charIndex + 1
          : 0;
    }

    // Binary search for efficiency with large timelines
    int count = 0;
    int low = 0;
    int high = characterTimings.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (characterTimings[mid].startTime <= currentTime) {
        count = characterTimings[mid].charIndex + 1;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return count;
  }

  /// Gets the time when a specific character should appear
  Duration? getCharacterTime(int charIndex) {
    for (final timing in characterTimings) {
      if (timing.charIndex == charIndex) {
        return timing.startTime;
      }
    }
    return null;
  }

  /// Checks if the timeline has any timing data
  bool get isEmpty => characterTimings.isEmpty;

  /// Checks if the timeline has timing data
  bool get isNotEmpty => characterTimings.isNotEmpty;

  /// Gets the total character count in this timeline
  int get totalCharacters =>
      characterTimings.isNotEmpty ? characterTimings.last.charIndex + 1 : 0;

  Map<String, dynamic> toJson() => {
        'totalDuration': totalDuration.inMilliseconds,
        'characterTimings': characterTimings.map((t) => t.toJson()).toList(),
      };

  factory VoiceTimeline.fromJson(Map<String, dynamic> json) {
    return VoiceTimeline(
      totalDuration: Duration(milliseconds: json['totalDuration'] as int),
      characterTimings: (json['characterTimings'] as List<dynamic>)
          .map((t) => CharacterTiming.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceTimeline &&
          runtimeType == other.runtimeType &&
          totalDuration == other.totalDuration &&
          _listEquals(characterTimings, other.characterTimings);

  @override
  int get hashCode => totalDuration.hashCode ^ characterTimings.hashCode;

  @override
  String toString() =>
      'VoiceTimeline(totalDuration: $totalDuration, timings: ${characterTimings.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
