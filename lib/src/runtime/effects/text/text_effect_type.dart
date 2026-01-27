/// Text Effect Types for Visual Novel Dialogue
///
/// Defines the available text effects that can be applied to dialogue text
/// using inline markup (e.g., {shake}text{/shake}).

/// Available text effect types
enum TextEffectType {
  /// Shaking/vibrating text effect
  shake,

  /// Wave/undulating text effect
  wave,

  /// Rainbow/gradient color animation
  rainbow,

  /// Fade-in effect per character
  fadeIn,

  /// Pulsing size effect for emphasis
  pulse,

  /// Standard typewriter effect (default)
  typewriter,

  /// Instant display (no animation)
  instant,
}

/// Extension methods for TextEffectType
extension TextEffectTypeExtension on TextEffectType {
  /// Get the markup tag name for this effect
  String get tagName => name;

  /// Get a human-readable display name
  String get displayName {
    switch (this) {
      case TextEffectType.shake:
        return 'Shake';
      case TextEffectType.wave:
        return 'Wave';
      case TextEffectType.rainbow:
        return 'Rainbow';
      case TextEffectType.fadeIn:
        return 'Fade In';
      case TextEffectType.pulse:
        return 'Pulse';
      case TextEffectType.typewriter:
        return 'Typewriter';
      case TextEffectType.instant:
        return 'Instant';
    }
  }

  /// Get a description of the effect
  String get description {
    switch (this) {
      case TextEffectType.shake:
        return 'Makes text shake/vibrate for emphasis or fear';
      case TextEffectType.wave:
        return 'Creates a wave motion through the text';
      case TextEffectType.rainbow:
        return 'Animates text through rainbow colors';
      case TextEffectType.fadeIn:
        return 'Fades in each character individually';
      case TextEffectType.pulse:
        return 'Pulses text size for emphasis';
      case TextEffectType.typewriter:
        return 'Standard character-by-character reveal';
      case TextEffectType.instant:
        return 'Shows all text immediately';
    }
  }

  /// Whether this effect requires continuous animation
  bool get requiresContinuousAnimation {
    switch (this) {
      case TextEffectType.shake:
      case TextEffectType.wave:
      case TextEffectType.rainbow:
      case TextEffectType.pulse:
        return true;
      case TextEffectType.fadeIn:
      case TextEffectType.typewriter:
      case TextEffectType.instant:
        return false;
    }
  }
}
