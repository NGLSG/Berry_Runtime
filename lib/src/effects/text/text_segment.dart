/// Text Segment Model
///
/// Represents a segment of text with an optional effect applied.

import 'text_effect_config.dart';

/// A segment of text with an optional effect
class TextSegment {
  /// The text content of this segment
  final String text;

  /// The effect applied to this segment (null for plain text)
  final TextEffectConfig? effect;

  const TextSegment({
    required this.text,
    this.effect,
  });

  /// Whether this segment has an effect applied
  bool get hasEffect => effect != null;

  /// Whether this segment is empty
  bool get isEmpty => text.isEmpty;

  /// Whether this segment is not empty
  bool get isNotEmpty => text.isNotEmpty;

  /// The length of the text
  int get length => text.length;

  /// Create a plain text segment (no effect)
  factory TextSegment.plain(String text) {
    return TextSegment(text: text, effect: null);
  }

  /// Create a segment with an effect
  factory TextSegment.withEffect(String text, TextEffectConfig effect) {
    return TextSegment(text: text, effect: effect);
  }

  /// Create a copy with different text
  TextSegment copyWithText(String newText) {
    return TextSegment(text: newText, effect: effect);
  }

  /// Create a copy with different effect
  TextSegment copyWithEffect(TextEffectConfig? newEffect) {
    return TextSegment(text: text, effect: newEffect);
  }

  /// Get a substring of this segment
  TextSegment substring(int start, [int? end]) {
    return TextSegment(
      text: text.substring(start, end),
      effect: effect,
    );
  }

  // ============ Serialization ============

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (effect != null) 'effect': effect!.toJson(),
    };
  }

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      text: json['text'] as String? ?? '',
      effect: json['effect'] != null
          ? TextEffectConfig.fromJson(json['effect'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextSegment) return false;
    return text == other.text && effect == other.effect;
  }

  @override
  int get hashCode => Object.hash(text, effect);

  @override
  String toString() {
    if (effect == null) {
      return 'TextSegment("$text")';
    }
    return 'TextSegment("$text", effect: ${effect!.type.name})';
  }
}

/// A collection of text segments representing parsed dialogue text
class ParsedText {
  /// The list of text segments
  final List<TextSegment> segments;

  const ParsedText(this.segments);

  /// Create an empty parsed text
  const ParsedText.empty() : segments = const [];

  /// Create from a single plain text string
  factory ParsedText.plain(String text) {
    if (text.isEmpty) return const ParsedText.empty();
    return ParsedText([TextSegment.plain(text)]);
  }

  /// Whether this parsed text is empty
  bool get isEmpty => segments.isEmpty || segments.every((s) => s.isEmpty);

  /// Whether this parsed text is not empty
  bool get isNotEmpty => !isEmpty;

  /// Get the total character count
  int get totalLength => segments.fold(0, (sum, seg) => sum + seg.length);

  /// Get the plain text without any effect markup
  String get plainText => segments.map((s) => s.text).join();

  /// Get the number of segments
  int get segmentCount => segments.length;

  /// Get a segment by index
  TextSegment operator [](int index) => segments[index];

  /// Iterate over segments
  Iterable<TextSegment> get iterable => segments;

  // ============ Serialization ============

  Map<String, dynamic> toJson() {
    return {
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }

  factory ParsedText.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    return ParsedText(
      segmentsList
          .map((s) => TextSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'ParsedText(${segments.length} segments)';
}
