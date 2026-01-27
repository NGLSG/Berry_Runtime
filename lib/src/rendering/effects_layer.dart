/// Effects Layer for VN Runtime
/// 
/// Handles screen effects (shake, flash, blur) and text effects (shake, wave, rainbow).

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vn_node.dart';

/// Screen effect types
enum ScreenEffect {
  none,
  shake,
  flash,
  blur,
  vignette,
  colorOverlay,
}

/// Configuration for screen effects
class ScreenEffectConfig {
  final ScreenEffect type;
  final double intensity;
  final Duration duration;
  final Color? color;
  final Map<String, dynamic> params;

  const ScreenEffectConfig({
    required this.type,
    this.intensity = 1.0,
    this.duration = const Duration(milliseconds: 500),
    this.color,
    this.params = const {},
  });

  static const none = ScreenEffectConfig(type: ScreenEffect.none);
}

/// Controller for screen effects
class ScreenEffectController extends ChangeNotifier {
  ScreenEffectConfig _currentEffect = ScreenEffectConfig.none;
  double _effectProgress = 0.0;
  Timer? _effectTimer;
  bool _isActive = false;

  // Shake-specific state
  Offset _shakeOffset = Offset.zero;
  final _random = math.Random();

  ScreenEffectConfig get currentEffect => _currentEffect;
  double get effectProgress => _effectProgress;
  bool get isActive => _isActive;
  Offset get shakeOffset => _shakeOffset;

  /// Apply a screen effect
  Future<void> applyEffect(ScreenEffectConfig config) async {
    _currentEffect = config;
    _effectProgress = 0.0;
    _isActive = true;
    notifyListeners();

    if (config.type == ScreenEffect.none) {
      _isActive = false;
      notifyListeners();
      return;
    }

    final completer = Completer<void>();
    final startTime = DateTime.now();

    _effectTimer?.cancel();
    _effectTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      _effectProgress = (elapsed.inMilliseconds / config.duration.inMilliseconds)
          .clamp(0.0, 1.0);

      // Update shake offset if shake effect
      if (config.type == ScreenEffect.shake) {
        _updateShakeOffset(config.intensity);
      }

      notifyListeners();

      if (_effectProgress >= 1.0) {
        timer.cancel();
        _isActive = false;
        _shakeOffset = Offset.zero;
        notifyListeners();
        completer.complete();
      }
    });

    return completer.future;
  }

  /// Stop current effect immediately
  void stopEffect() {
    _effectTimer?.cancel();
    _currentEffect = ScreenEffectConfig.none;
    _effectProgress = 0.0;
    _isActive = false;
    _shakeOffset = Offset.zero;
    notifyListeners();
  }

  void _updateShakeOffset(double intensity) {
    // Decrease shake intensity over time
    final currentIntensity = intensity * (1.0 - _effectProgress);
    final maxOffset = currentIntensity * 20;
    
    _shakeOffset = Offset(
      (_random.nextDouble() * 2 - 1) * maxOffset,
      (_random.nextDouble() * 2 - 1) * maxOffset,
    );
  }

  @override
  void dispose() {
    _effectTimer?.cancel();
    super.dispose();
  }
}

/// Widget that applies screen effects to its child
class ScreenEffectLayer extends StatelessWidget {
  final ScreenEffectController controller;
  final Widget child;

  const ScreenEffectLayer({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        Widget result = child;

        if (!controller.isActive) {
          return result;
        }

        final effect = controller.currentEffect;
        final progress = controller.effectProgress;

        switch (effect.type) {
          case ScreenEffect.shake:
            result = Transform.translate(
              offset: controller.shakeOffset,
              child: result,
            );
            break;

          case ScreenEffect.flash:
            result = Stack(
              children: [
                result,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: (effect.color ?? Colors.white)
                          .withOpacity(_getFlashOpacity(progress, effect.intensity)),
                    ),
                  ),
                ),
              ],
            );
            break;

          case ScreenEffect.blur:
            final sigma = effect.intensity * 10 * (1.0 - progress);
            if (sigma > 0.1) {
              result = ImageFiltered(
                imageFilter: ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.srcOver,
                ),
                child: result,
              );
            }
            break;

          case ScreenEffect.vignette:
            result = Stack(
              children: [
                result,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _VignettePainter(
                        intensity: effect.intensity * (1.0 - progress),
                        color: effect.color ?? Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            );
            break;

          case ScreenEffect.colorOverlay:
            result = Stack(
              children: [
                result,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: (effect.color ?? Colors.red)
                          .withOpacity(effect.intensity * 0.5 * (1.0 - progress)),
                    ),
                  ),
                ),
              ],
            );
            break;

          case ScreenEffect.none:
            break;
        }

        return result;
      },
    );
  }

  double _getFlashOpacity(double progress, double intensity) {
    // Flash peaks at the beginning and fades out
    if (progress < 0.1) {
      return intensity * (progress / 0.1);
    } else {
      return intensity * (1.0 - ((progress - 0.1) / 0.9));
    }
  }
}

/// Vignette effect painter
class _VignettePainter extends CustomPainter {
  final double intensity;
  final Color color;

  _VignettePainter({
    required this.intensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 0.8;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        color.withOpacity(intensity * 0.8),
      ],
      stops: const [0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.color != color;
  }
}

// ============================================================================
// Text Effects
// ============================================================================

/// Text effect configuration
class TextEffectConfig {
  final TextEffectType type;
  final double intensity;
  final double speed;
  final List<Color>? colors;

  const TextEffectConfig({
    required this.type,
    this.intensity = 1.0,
    this.speed = 1.0,
    this.colors,
  });
}

/// Widget that applies text effects to a string
class EffectText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final List<TextEffect> effects;
  final TextAlign textAlign;

  const EffectText({
    super.key,
    required this.text,
    this.style,
    this.effects = const [],
    this.textAlign = TextAlign.left,
  });

  @override
  State<EffectText> createState() => _EffectTextState();
}

class _EffectTextState extends State<EffectText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effects.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RichText(
          textAlign: widget.textAlign,
          text: _buildTextSpan(),
        );
      },
    );
  }

  TextSpan _buildTextSpan() {
    final baseStyle = widget.style ?? const TextStyle();
    final spans = <InlineSpan>[];
    
    // Build character-by-character with effects
    for (int i = 0; i < widget.text.length; i++) {
      final char = widget.text[i];
      final effectsForChar = _getEffectsForIndex(i);
      
      if (effectsForChar.isEmpty) {
        spans.add(TextSpan(text: char, style: baseStyle));
      } else {
        spans.add(_buildEffectedCharSpan(char, i, effectsForChar, baseStyle));
      }
    }

    return TextSpan(children: spans);
  }

  List<TextEffect> _getEffectsForIndex(int index) {
    return widget.effects.where((e) => 
      index >= e.startIndex && index < e.endIndex
    ).toList();
  }

  InlineSpan _buildEffectedCharSpan(
    String char,
    int index,
    List<TextEffect> effects,
    TextStyle baseStyle,
  ) {
    TextStyle style = baseStyle;
    Offset offset = Offset.zero;

    for (final effect in effects) {
      switch (effect.type) {
        case TextEffectType.shake:
          final shakeAmount = (effect.params['intensity'] as num?)?.toDouble() ?? 2.0;
          offset = Offset(
            math.sin(_controller.value * math.pi * 20 + index) * shakeAmount,
            math.cos(_controller.value * math.pi * 20 + index) * shakeAmount,
          );
          break;

        case TextEffectType.wave:
          final waveHeight = (effect.params['height'] as num?)?.toDouble() ?? 4.0;
          offset = Offset(
            0,
            math.sin(_controller.value * math.pi * 2 + index * 0.5) * waveHeight,
          );
          break;

        case TextEffectType.rainbow:
          final hue = ((_controller.value * 360 + index * 30) % 360);
          style = style.copyWith(
            color: HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor(),
          );
          break;

        case TextEffectType.fadeIn:
          final fadeProgress = (_controller.value * 2).clamp(0.0, 1.0);
          final charProgress = (fadeProgress - index * 0.05).clamp(0.0, 1.0);
          style = style.copyWith(
            color: style.color?.withOpacity(charProgress) ?? 
                   Colors.white.withOpacity(charProgress),
          );
          break;

        case TextEffectType.typewriter:
          // Typewriter is handled separately in the dialogue system
          break;
      }
    }

    if (offset != Offset.zero) {
      return WidgetSpan(
        child: Transform.translate(
          offset: offset,
          child: Text(char, style: style),
        ),
      );
    }

    return TextSpan(text: char, style: style);
  }
}

/// Typewriter text widget for dialogue display
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;
  final bool autoStart;
  final List<TextEffect> effects;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 30),
    this.onComplete,
    this.autoStart = true,
    this.effects = const [],
  });

  @override
  State<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends State<TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;
  bool _isComplete = false;

  bool get isComplete => _isComplete;
  int get visibleChars => _visibleChars;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      start();
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      reset();
      if (widget.autoStart) {
        start();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Start the typewriter animation
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_visibleChars >= widget.text.length) {
        timer.cancel();
        _isComplete = true;
        widget.onComplete?.call();
        return;
      }
      setState(() {
        _visibleChars++;
      });
    });
  }

  /// Skip to show all text immediately
  void skip() {
    _timer?.cancel();
    setState(() {
      _visibleChars = widget.text.length;
      _isComplete = true;
    });
    widget.onComplete?.call();
  }

  /// Reset to beginning
  void reset() {
    _timer?.cancel();
    setState(() {
      _visibleChars = 0;
      _isComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _visibleChars);
    
    if (widget.effects.isEmpty) {
      return Text(
        visibleText,
        style: widget.style,
      );
    }

    // Apply effects only to visible portion
    final visibleEffects = widget.effects.map((e) {
      return TextEffect(
        type: e.type,
        startIndex: e.startIndex.clamp(0, _visibleChars),
        endIndex: e.endIndex.clamp(0, _visibleChars),
        params: e.params,
      );
    }).where((e) => e.startIndex < e.endIndex).toList();

    return EffectText(
      text: visibleText,
      style: widget.style,
      effects: visibleEffects,
    );
  }
}

/// Extension to convert ScreenEffectType to ScreenEffect
extension ScreenEffectTypeExtension on ScreenEffectType {
  ScreenEffect toScreenEffect() {
    switch (this) {
      case ScreenEffectType.fade:
        return ScreenEffect.colorOverlay;
      case ScreenEffectType.shake:
        return ScreenEffect.shake;
      case ScreenEffectType.flash:
        return ScreenEffect.flash;
      case ScreenEffectType.blur:
        return ScreenEffect.blur;
      case ScreenEffectType.vignette:
        return ScreenEffect.vignette;
      case ScreenEffectType.colorOverlay:
        return ScreenEffect.colorOverlay;
    }
  }
}
