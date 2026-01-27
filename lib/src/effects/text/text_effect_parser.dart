/// Text Effect Parser
///
/// Parses text with inline effect markup into segments.
/// Supports two markup formats:
/// - Curly braces: {effectName}text{/effectName} or {effectName=param1:value1}text{/effectName}
/// - Square brackets: [effectName]text[/effectName] or [effectName=param1:value1]text[/effectName]
///
/// Examples:
/// - {shake}scary text{/shake}
/// - [shake]scary text[/shake]
/// - {wave=amplitude:5,frequency:3}wavy text{/wave}
/// - [rainbow]colorful[/rainbow]

import 'text_effect_type.dart';
import 'text_effect_config.dart';
import 'text_segment.dart';

/// Parser for text with effect markup
class TextEffectParser {
  /// Pattern to match effect tags with curly braces: {effectName} or {effectName=params}...{/effectName}
  static final _curlyEffectPattern = RegExp(
    r'\{(\w+)(?:=([^}]*))?\}(.*?)\{/\1\}',
    dotAll: true,
  );

  /// Pattern to match effect tags with square brackets: [effectName] or [effectName=params]...[/effectName]
  static final _squareEffectPattern = RegExp(
    r'\[(\w+)(?:=([^\]]*))?\](.*?)\[/\1\]',
    dotAll: true,
  );

  /// Parse text with effect markup into segments
  List<TextSegment> parse(String text) {
    if (text.isEmpty) return [];

    // First, normalize all square brackets to curly braces for unified processing
    String normalizedText = _normalizeMarkup(text);

    final segments = <TextSegment>[];
    int lastEnd = 0;

    for (final match in _curlyEffectPattern.allMatches(normalizedText)) {
      // Add plain text before this match
      if (match.start > lastEnd) {
        final plainText = normalizedText.substring(lastEnd, match.start);
        if (plainText.isNotEmpty) {
          segments.add(TextSegment.plain(plainText));
        }
      }

      // Parse the effect
      final effectName = match.group(1)!;
      final paramsString = match.group(2);
      final content = match.group(3)!;

      final effect = _parseEffect(effectName, paramsString);

      if (content.isNotEmpty) {
        segments.add(TextSegment(text: content, effect: effect));
      }

      lastEnd = match.end;
    }

    // Add remaining plain text
    if (lastEnd < normalizedText.length) {
      final remainingText = normalizedText.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        segments.add(TextSegment.plain(remainingText));
      }
    }

    // If no matches found, return the whole text as plain
    if (segments.isEmpty && text.isNotEmpty) {
      segments.add(TextSegment.plain(text));
    }

    return segments;
  }

  /// Normalize square bracket markup to curly brace markup
  String _normalizeMarkup(String text) {
    // Replace [effect]...[/effect] with {effect}...{/effect}
    return text.replaceAllMapped(_squareEffectPattern, (match) {
      final effectName = match.group(1)!;
      final paramsString = match.group(2);
      final content = match.group(3)!;
      
      if (paramsString != null && paramsString.isNotEmpty) {
        return '{$effectName=$paramsString}$content{/$effectName}';
      } else {
        return '{$effectName}$content{/$effectName}';
      }
    });
  }

  /// Parse text and return a ParsedText object
  ParsedText parseToObject(String text) {
    return ParsedText(parse(text));
  }

  /// Parse an effect name and optional parameters into a config
  TextEffectConfig? _parseEffect(String name, String? paramsString) {
    // Find the effect type
    final type = _parseEffectType(name);
    if (type == null) return null;

    // Start with preset parameters
    final preset = TextEffectConfig.getPreset(type);
    final parameters = Map<String, dynamic>.from(preset.parameters);

    // Parse and merge custom parameters
    if (paramsString != null && paramsString.isNotEmpty) {
      final customParams = _parseParameters(paramsString);
      parameters.addAll(customParams);
    }

    return TextEffectConfig(type: type, parameters: parameters);
  }

  /// Parse effect type from name string
  TextEffectType? _parseEffectType(String name) {
    final lowerName = name.toLowerCase();
    for (final type in TextEffectType.values) {
      if (type.name.toLowerCase() == lowerName) {
        return type;
      }
    }
    return null;
  }

  /// Parse parameter string into a map
  /// Format: "key1:value1,key2:value2"
  Map<String, dynamic> _parseParameters(String paramsString) {
    final params = <String, dynamic>{};

    for (final pair in paramsString.split(',')) {
      final trimmedPair = pair.trim();
      if (trimmedPair.isEmpty) continue;

      final colonIndex = trimmedPair.indexOf(':');
      if (colonIndex == -1) continue;

      final key = trimmedPair.substring(0, colonIndex).trim();
      final valueStr = trimmedPair.substring(colonIndex + 1).trim();

      if (key.isEmpty) continue;

      params[key] = _parseValue(valueStr);
    }

    return params;
  }

  /// Parse a value string into the appropriate type
  dynamic _parseValue(String value) {
    // Try parsing as double
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;

    // Try parsing as int
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Try parsing as bool
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Return as string
    return value;
  }

  /// Check if text contains any effect markup
  bool hasEffectMarkup(String text) {
    return _curlyEffectPattern.hasMatch(text) || _squareEffectPattern.hasMatch(text);
  }

  /// Strip all effect markup and return plain text
  String stripMarkup(String text) {
    // First strip square brackets
    String result = text.replaceAllMapped(_squareEffectPattern, (match) => match.group(3)!);
    // Then strip curly braces
    result = result.replaceAllMapped(_curlyEffectPattern, (match) => match.group(3)!);
    return result;
  }

  /// Get all effect types used in the text
  Set<TextEffectType> getUsedEffects(String text) {
    final effects = <TextEffectType>{};

    // Check curly brace format
    for (final match in _curlyEffectPattern.allMatches(text)) {
      final effectName = match.group(1)!;
      final type = _parseEffectType(effectName);
      if (type != null) {
        effects.add(type);
      }
    }

    // Check square bracket format
    for (final match in _squareEffectPattern.allMatches(text)) {
      final effectName = match.group(1)!;
      final type = _parseEffectType(effectName);
      if (type != null) {
        effects.add(type);
      }
    }

    return effects;
  }

  /// Validate markup syntax and return any errors
  List<String> validateMarkup(String text) {
    final errors = <String>[];

    // Check for unclosed tags
    final openTagPattern = RegExp(r'\{(\w+)(?:=[^}]*)?\}');
    final closeTagPattern = RegExp(r'\{/(\w+)\}');

    final openTags = <String>[];

    // Simple validation - check for matching open/close tags
    int pos = 0;
    while (pos < text.length) {
      final openMatch = openTagPattern.matchAsPrefix(text, pos);
      final closeMatch = closeTagPattern.matchAsPrefix(text, pos);

      if (openMatch != null && (closeMatch == null || openMatch.start <= closeMatch.start)) {
        final tagName = openMatch.group(1)!;
        openTags.add(tagName);
        pos = openMatch.end;
      } else if (closeMatch != null) {
        final tagName = closeMatch.group(1)!;
        if (openTags.isEmpty) {
          errors.add('Unexpected closing tag {/$tagName} at position $pos');
        } else if (openTags.last != tagName) {
          errors.add('Mismatched tags: expected {/${openTags.last}}, found {/$tagName} at position $pos');
        } else {
          openTags.removeLast();
        }
        pos = closeMatch.end;
      } else {
        pos++;
      }
    }

    // Check for unclosed tags
    for (final tag in openTags) {
      errors.add('Unclosed tag {$tag}');
    }

    // Check for unknown effect types (check both formats)
    for (final match in _curlyEffectPattern.allMatches(text)) {
      final effectName = match.group(1)!;
      if (_parseEffectType(effectName) == null) {
        errors.add('Unknown effect type: $effectName');
      }
    }
    for (final match in _squareEffectPattern.allMatches(text)) {
      final effectName = match.group(1)!;
      if (_parseEffectType(effectName) == null) {
        errors.add('Unknown effect type: $effectName');
      }
    }

    return errors;
  }
}
