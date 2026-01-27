/// Text Effect Renderer
///
/// Renders parsed text segments with their associated effects.
/// Builds Flutter widgets for each segment based on its effect type.

import 'package:flutter/material.dart';

import 'text_effect_type.dart';
import 'text_effect_config.dart';
import 'text_segment.dart';
import 'text_effect_widgets.dart';

/// Renders text segments with effects as Flutter widgets
class TextEffectRenderer {
  /// Build a widget displaying all text segments with their effects
  Widget buildEffectedText(
    List<TextSegment> segments,
    TextStyle baseStyle, {
    AnimationController? controller,
    VoidCallback? onComplete,
  }) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one segment with no effect, return simple text
    if (segments.length == 1 && !segments.first.hasEffect) {
      return Text(segments.first.text, style: baseStyle);
    }

    return Wrap(
      children: segments.map((segment) {
        return _buildSegmentWidget(
          segment,
          baseStyle,
          controller: controller,
          onComplete: onComplete,
        );
      }).toList(),
    );
  }

  /// Build a RichText widget with mixed plain and effected text
  Widget buildRichEffectedText(
    List<TextSegment> segments,
    TextStyle baseStyle, {
    AnimationController? controller,
  }) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TextSpan(
        children: segments.map((segment) {
          return _buildInlineSpan(segment, baseStyle, controller);
        }).toList(),
      ),
    );
  }

  /// Build a widget for a single segment
  Widget _buildSegmentWidget(
    TextSegment segment,
    TextStyle baseStyle, {
    AnimationController? controller,
    VoidCallback? onComplete,
  }) {
    if (!segment.hasEffect) {
      return Text(segment.text, style: baseStyle);
    }

    return _buildEffectWidget(
      segment.text,
      segment.effect!,
      baseStyle,
      controller: controller,
      onComplete: onComplete,
    );
  }

  /// Build an InlineSpan for RichText
  InlineSpan _buildInlineSpan(
    TextSegment segment,
    TextStyle baseStyle,
    AnimationController? controller,
  ) {
    if (!segment.hasEffect) {
      return TextSpan(text: segment.text, style: baseStyle);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _buildEffectWidget(
        segment.text,
        segment.effect!,
        baseStyle,
        controller: controller,
      ),
    );
  }

  /// Build the appropriate effect widget based on effect type
  Widget _buildEffectWidget(
    String text,
    TextEffectConfig effect,
    TextStyle baseStyle, {
    AnimationController? controller,
    VoidCallback? onComplete,
  }) {
    switch (effect.type) {
      case TextEffectType.shake:
        return ShakeTextEffect(
          text: text,
          style: baseStyle,
          intensity: effect.getParameter('intensity', 2.0),
          speed: effect.getParameter('speed', 20.0),
        );

      case TextEffectType.wave:
        return WaveTextEffect(
          text: text,
          style: baseStyle,
          amplitude: effect.getParameter('amplitude', 3.0),
          frequency: effect.getParameter('frequency', 2.0),
          wavelength: effect.getParameter('wavelength', 10.0),
        );

      case TextEffectType.rainbow:
        return RainbowTextEffect(
          text: text,
          style: baseStyle,
          speed: effect.getParameter('speed', 1.0),
          saturation: effect.getParameter('saturation', 1.0),
          lightness: effect.getParameter('lightness', 0.5),
        );

      case TextEffectType.fadeIn:
        return FadeInTextEffect(
          text: text,
          style: baseStyle,
          duration: effect.getParameter('duration', 0.3),
          delay: effect.getParameter('delay', 0.05),
          onComplete: onComplete,
        );

      case TextEffectType.pulse:
        return PulseTextEffect(
          text: text,
          style: baseStyle,
          minScale: effect.getParameter('minScale', 0.9),
          maxScale: effect.getParameter('maxScale', 1.1),
          speed: effect.getParameter('speed', 2.0),
        );

      case TextEffectType.typewriter:
        return TypewriterTextEffect(
          text: text,
          style: baseStyle,
          speed: effect.getParameter('speed', 30.0),
          onComplete: onComplete,
        );

      case TextEffectType.instant:
        return Text(text, style: baseStyle);
    }
  }

  /// Create a preview widget for an effect type
  Widget buildEffectPreview(
    TextEffectType type,
    TextStyle baseStyle, {
    String sampleText = 'Sample Text',
  }) {
    final config = TextEffectConfig.getPreset(type);
    return _buildEffectWidget(sampleText, config, baseStyle);
  }

  /// Create a preview widget for a custom effect config
  Widget buildConfigPreview(
    TextEffectConfig config,
    TextStyle baseStyle, {
    String sampleText = 'Sample Text',
  }) {
    return _buildEffectWidget(sampleText, config, baseStyle);
  }
}

/// A widget that displays text with effects and handles the full lifecycle
class EffectedTextDisplay extends StatefulWidget {
  /// The parsed text segments to display
  final List<TextSegment> segments;

  /// Base text style
  final TextStyle style;

  /// Callback when all animations complete
  final VoidCallback? onComplete;

  /// Whether to auto-start animations
  final bool autoStart;

  const EffectedTextDisplay({
    super.key,
    required this.segments,
    required this.style,
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<EffectedTextDisplay> createState() => _EffectedTextDisplayState();
}

class _EffectedTextDisplayState extends State<EffectedTextDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _renderer = TextEffectRenderer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _renderer.buildEffectedText(
      widget.segments,
      widget.style,
      controller: _controller,
      onComplete: widget.onComplete,
    );
  }
}

/// A convenience widget that parses and displays effected text
class EffectedText extends StatelessWidget {
  /// The text with effect markup
  final String text;

  /// Base text style
  final TextStyle style;

  /// Callback when all animations complete
  final VoidCallback? onComplete;

  /// Parser instance (optional, will create one if not provided)
  final dynamic parser;

  const EffectedText({
    super.key,
    required this.text,
    required this.style,
    this.onComplete,
    this.parser,
  });

  @override
  Widget build(BuildContext context) {
    // Import parser dynamically to avoid circular dependency
    // In actual use, import text_effect_parser.dart
    return Text(text, style: style);
  }
}
