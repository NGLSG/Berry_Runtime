/// Text Effect Widgets
///
/// Individual widget implementations for each text effect type.
/// These widgets handle the animation and rendering of effected text.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'text_effect_config.dart';
import 'text_effect_type.dart';

/// Shake text effect - makes text vibrate/shake
class ShakeTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double intensity;
  final double speed;

  const ShakeTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.intensity = 2.0,
    this.speed = 20.0,
  });

  @override
  State<ShakeTextEffect> createState() => _ShakeTextEffectState();
}

class _ShakeTextEffectState extends State<ShakeTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.speed).round()),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetX = (_random.nextDouble() - 0.5) * 2 * widget.intensity;
        final offsetY = (_random.nextDouble() - 0.5) * 2 * widget.intensity;
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

/// Wave text effect - creates undulating motion through text
class WaveTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double amplitude;
  final double frequency;
  final double wavelength;

  const WaveTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.amplitude = 3.0,
    this.frequency = 2.0,
    this.wavelength = 10.0,
  });

  @override
  State<WaveTextEffect> createState() => _WaveTextEffectState();
}

class _WaveTextEffectState extends State<WaveTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.frequency).round()),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (index) {
            final phase = (index / widget.wavelength) * 2 * math.pi;
            final offset = math.sin(_controller.value * 2 * math.pi + phase) *
                widget.amplitude;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Text(widget.text[index], style: widget.style),
            );
          }),
        );
      },
    );
  }
}

/// Rainbow text effect - cycles through rainbow colors
class RainbowTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double speed;
  final double saturation;
  final double lightness;

  const RainbowTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.speed = 1.0,
    this.saturation = 1.0,
    this.lightness = 0.5,
  });

  @override
  State<RainbowTextEffect> createState() => _RainbowTextEffectState();
}

class _RainbowTextEffectState extends State<RainbowTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.speed).round()),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForIndex(int index, double animValue) {
    final hue = ((animValue + index / widget.text.length) % 1.0) * 360;
    return HSLColor.fromAHSL(
      1.0,
      hue,
      widget.saturation,
      widget.lightness,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (index) {
            final color = _getColorForIndex(index, _controller.value);
            return Text(
              widget.text[index],
              style: widget.style.copyWith(color: color),
            );
          }),
        );
      },
    );
  }
}

/// Fade-in text effect - characters fade in sequentially
class FadeInTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double duration;
  final double delay;
  final VoidCallback? onComplete;

  const FadeInTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.duration = 0.3,
    this.delay = 0.05,
    this.onComplete,
  });

  @override
  State<FadeInTextEffect> createState() => _FadeInTextEffectState();
}

class _FadeInTextEffectState extends State<FadeInTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.duration + (widget.text.length * widget.delay);
    _controller = AnimationController(
      duration: Duration(milliseconds: (totalDuration * 1000).round()),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getOpacityForIndex(int index) {
    final charStartTime = index * widget.delay;
    final totalDuration = widget.duration + (widget.text.length * widget.delay);
    final normalizedStart = charStartTime / totalDuration;
    final normalizedDuration = widget.duration / totalDuration;

    if (_controller.value < normalizedStart) return 0.0;
    if (_controller.value >= normalizedStart + normalizedDuration) return 1.0;

    return (_controller.value - normalizedStart) / normalizedDuration;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (index) {
            final opacity = _getOpacityForIndex(index);
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(widget.text[index], style: widget.style),
            );
          }),
        );
      },
    );
  }
}

/// Pulse text effect - text size pulses for emphasis
class PulseTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double minScale;
  final double maxScale;
  final double speed;

  const PulseTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.minScale = 0.9,
    this.maxScale = 1.1,
    this.speed = 2.0,
  });

  @override
  State<PulseTextEffect> createState() => _PulseTextEffectState();
}

class _PulseTextEffectState extends State<PulseTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.speed).round()),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

/// Typewriter text effect - reveals text character by character
class TypewriterTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double speed;
  final VoidCallback? onComplete;

  const TypewriterTextEffect({
    super.key,
    required this.text,
    required this.style,
    this.speed = 30.0,
    this.onComplete,
  });

  @override
  State<TypewriterTextEffect> createState() => _TypewriterTextEffectState();
}

class _TypewriterTextEffectState extends State<TypewriterTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.text.length / widget.speed;
    _controller = AnimationController(
      duration: Duration(milliseconds: (duration * 1000).round()),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final visibleChars =
            (_controller.value * widget.text.length).floor().clamp(0, widget.text.length);
        return Text(
          widget.text.substring(0, visibleChars),
          style: widget.style,
        );
      },
    );
  }
}


/// Generic effect text widget that renders text with the appropriate effect
class EffectText extends StatelessWidget {
  final String text;
  final TextEffectConfig config;
  final TextStyle style;

  const EffectText({
    super.key,
    required this.text,
    required this.config,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case TextEffectType.shake:
        return ShakeTextEffect(
          text: text,
          style: style,
          intensity: (config.parameters['intensity'] as num?)?.toDouble() ?? 2.0,
          speed: (config.parameters['speed'] as num?)?.toDouble() ?? 20.0,
        );
      case TextEffectType.wave:
        return WaveTextEffect(
          text: text,
          style: style,
          amplitude: (config.parameters['amplitude'] as num?)?.toDouble() ?? 3.0,
          frequency: (config.parameters['frequency'] as num?)?.toDouble() ?? 2.0,
          wavelength: (config.parameters['wavelength'] as num?)?.toDouble() ?? 10.0,
        );
      case TextEffectType.rainbow:
        return RainbowTextEffect(
          text: text,
          style: style,
          speed: (config.parameters['speed'] as num?)?.toDouble() ?? 1.0,
          saturation: (config.parameters['saturation'] as num?)?.toDouble() ?? 1.0,
          lightness: (config.parameters['lightness'] as num?)?.toDouble() ?? 0.5,
        );
      case TextEffectType.fadeIn:
        return FadeInTextEffect(
          text: text,
          style: style,
          duration: (config.parameters['duration'] as num?)?.toDouble() ?? 0.3,
          delay: (config.parameters['delay'] as num?)?.toDouble() ?? 0.05,
        );
      case TextEffectType.pulse:
        return PulseTextEffect(
          text: text,
          style: style,
          minScale: (config.parameters['minScale'] as num?)?.toDouble() ?? 0.9,
          maxScale: (config.parameters['maxScale'] as num?)?.toDouble() ?? 1.1,
          speed: (config.parameters['speed'] as num?)?.toDouble() ?? 2.0,
        );
      case TextEffectType.typewriter:
        return TypewriterTextEffect(
          text: text,
          style: style,
          speed: (config.parameters['speed'] as num?)?.toDouble() ?? 30.0,
        );
      default:
        // Unknown effect, just render plain text
        return Text(text, style: style);
    }
  }
}
