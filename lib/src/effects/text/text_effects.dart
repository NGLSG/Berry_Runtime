/// Text Effects Module
///
/// Provides text effect types, configuration, parsing, and rendering
/// for visual novel dialogue with inline markup support.
///
/// Usage:
/// ```dart
/// // Parse text with effect markup
/// final parser = TextEffectParser();
/// final segments = parser.parse('Hello {shake}world{/shake}!');
///
/// // Render with effects
/// final renderer = TextEffectRenderer();
/// final widget = renderer.buildEffectedText(segments, style);
/// ```
///
/// Supported effects:
/// - {shake}text{/shake} - Vibrating/shaking text
/// - {wave}text{/wave} - Undulating wave motion
/// - {rainbow}text{/rainbow} - Rainbow color cycling
/// - {fadeIn}text{/fadeIn} - Character-by-character fade in
/// - {pulse}text{/pulse} - Pulsing size effect
///
/// Custom parameters:
/// - {shake=intensity:3,speed:25}text{/shake}
/// - {wave=amplitude:5,frequency:3}text{/wave}

export 'text_effect_type.dart';
export 'text_effect_config.dart';
export 'text_segment.dart';
export 'text_effect_parser.dart';
export 'text_effect_renderer.dart';
export 'text_effect_widgets.dart';
