/// Text Effect Configuration
///
/// Defines configuration for text effects including type and parameters.

import 'text_effect_type.dart';

/// Configuration for a text effect
class TextEffectConfig {
  /// The type of effect
  final TextEffectType type;

  /// Effect parameters (varies by effect type)
  final Map<String, dynamic> parameters;

  const TextEffectConfig({
    required this.type,
    this.parameters = const {},
  });

  /// Get a parameter value with a default fallback
  T getParameter<T>(String key, T defaultValue) {
    final value = parameters[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Create a copy with modified parameters
  TextEffectConfig copyWith({
    TextEffectType? type,
    Map<String, dynamic>? parameters,
  }) {
    return TextEffectConfig(
      type: type ?? this.type,
      parameters: parameters ?? Map.from(this.parameters),
    );
  }

  /// Merge additional parameters
  TextEffectConfig withParameters(Map<String, dynamic> additionalParams) {
    return TextEffectConfig(
      type: type,
      parameters: {...parameters, ...additionalParams},
    );
  }

  // ============ Preset Effects ============

  /// Shake effect preset - makes text vibrate
  static const shake = TextEffectConfig(
    type: TextEffectType.shake,
    parameters: {
      'intensity': 2.0, // Pixels of displacement
      'speed': 20.0, // Shakes per second
    },
  );

  /// Wave effect preset - creates undulating motion
  static const wave = TextEffectConfig(
    type: TextEffectType.wave,
    parameters: {
      'amplitude': 3.0, // Pixels of vertical displacement
      'frequency': 2.0, // Waves per second
      'wavelength': 10.0, // Characters per wave cycle
    },
  );

  /// Rainbow effect preset - cycles through colors
  static const rainbow = TextEffectConfig(
    type: TextEffectType.rainbow,
    parameters: {
      'speed': 1.0, // Color cycles per second
      'saturation': 1.0, // Color saturation (0.0-1.0)
      'lightness': 0.5, // Color lightness (0.0-1.0)
    },
  );

  /// Fade-in effect preset - characters fade in
  static const fadeIn = TextEffectConfig(
    type: TextEffectType.fadeIn,
    parameters: {
      'duration': 0.3, // Seconds per character fade
      'delay': 0.05, // Delay between characters
    },
  );

  /// Pulse effect preset - text size pulses
  static const pulse = TextEffectConfig(
    type: TextEffectType.pulse,
    parameters: {
      'minScale': 0.9, // Minimum scale factor
      'maxScale': 1.1, // Maximum scale factor
      'speed': 2.0, // Pulses per second
    },
  );

  /// Typewriter effect preset - standard reveal
  static const typewriter = TextEffectConfig(
    type: TextEffectType.typewriter,
    parameters: {
      'speed': 30.0, // Characters per second
    },
  );

  /// Instant effect preset - no animation
  static const instant = TextEffectConfig(
    type: TextEffectType.instant,
    parameters: {},
  );

  /// Get a preset by effect type
  static TextEffectConfig getPreset(TextEffectType type) {
    switch (type) {
      case TextEffectType.shake:
        return shake;
      case TextEffectType.wave:
        return wave;
      case TextEffectType.rainbow:
        return rainbow;
      case TextEffectType.fadeIn:
        return fadeIn;
      case TextEffectType.pulse:
        return pulse;
      case TextEffectType.typewriter:
        return typewriter;
      case TextEffectType.instant:
        return instant;
    }
  }

  // ============ Serialization ============

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }

  factory TextEffectConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'typewriter';
    final type = TextEffectType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => TextEffectType.typewriter,
    );

    return TextEffectConfig(
      type: type,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextEffectConfig) return false;
    return type == other.type && _mapsEqual(parameters, other.parameters);
  }

  @override
  int get hashCode => Object.hash(type, Object.hashAll(parameters.entries));

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() => 'TextEffectConfig(type: $type, parameters: $parameters)';
}
