/// Story Meta Effects - DDLC-style effects for story runtime
/// 
/// Provides meta effects (glitch, corruption, etc.) that can be triggered
/// during story playback via effect nodes.
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/vn_project.dart';

/// Configuration for story meta effects
class StoryMetaEffectConfig {
  final MetaEffectType type;
  final double intensity;
  final Duration duration;
  final String? fakeErrorTitle;
  final String? fakeErrorMessage;
  final Map<String, dynamic> params;

  const StoryMetaEffectConfig({
    required this.type,
    this.intensity = 0.5,
    this.duration = const Duration(milliseconds: 500),
    this.fakeErrorTitle,
    this.fakeErrorMessage,
    this.params = const {},
  });

  static const none = StoryMetaEffectConfig(type: MetaEffectType.none);
}

/// Controller for story meta effects
class StoryMetaEffectController extends ChangeNotifier {
  MetaEffectType _currentEffect = MetaEffectType.none;
  double _intensity = 0.5;
  bool _isActive = false;
  Timer? _durationTimer;
  String? _fakeErrorTitle;
  String? _fakeErrorMessage;
  
  MetaEffectType get currentEffect => _currentEffect;
  double get intensity => _intensity;
  bool get isActive => _isActive;
  String? get fakeErrorTitle => _fakeErrorTitle;
  String? get fakeErrorMessage => _fakeErrorMessage;
  
  /// Trigger a meta effect with configuration
  Future<void> triggerEffect(StoryMetaEffectConfig config) async {
    if (config.type == MetaEffectType.none) {
      stopEffect();
      return;
    }
    
    _currentEffect = config.type;
    _intensity = config.intensity;
    _fakeErrorTitle = config.fakeErrorTitle;
    _fakeErrorMessage = config.fakeErrorMessage;
    _isActive = true;
    notifyListeners();
    
    // Auto-stop after duration (except for fakeError which needs user interaction)
    if (config.type != MetaEffectType.fakeError && config.duration.inMilliseconds > 0) {
      _durationTimer?.cancel();
      _durationTimer = Timer(config.duration, () {
        stopEffect();
      });
    }
  }
  
  /// Trigger effect by type with default settings
  void triggerByType(MetaEffectType type, {
    double intensity = 0.5,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    triggerEffect(StoryMetaEffectConfig(
      type: type,
      intensity: intensity,
      duration: duration,
    ));
  }
  
  /// Stop current effect
  void stopEffect() {
    _durationTimer?.cancel();
    _isActive = false;
    _currentEffect = MetaEffectType.none;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}


/// Widget that applies meta effects to story content
class StoryMetaEffectLayer extends StatefulWidget {
  final Widget child;
  final StoryMetaEffectController controller;
  
  const StoryMetaEffectLayer({
    super.key,
    required this.child,
    required this.controller,
  });
  
  @override
  State<StoryMetaEffectLayer> createState() => _StoryMetaEffectLayerState();
}

class _StoryMetaEffectLayerState extends State<StoryMetaEffectLayer> 
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _shakeController;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
    
    widget.controller.addListener(_onEffectChange);
  }
  
  void _onEffectChange() {
    setState(() {});
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onEffectChange);
    _glitchController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isActive) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_glitchController, _shakeController]),
      builder: (context, child) {
        return _buildEffect(child!);
      },
      child: widget.child,
    );
  }
  
  Widget _buildEffect(Widget child) {
    switch (widget.controller.currentEffect) {
      case MetaEffectType.none:
        return child;
      case MetaEffectType.glitch:
        return _buildGlitchEffect(child);
      case MetaEffectType.staticNoise:
        return _buildStaticNoiseEffect(child);
      case MetaEffectType.screenTear:
        return _buildScreenTearEffect(child);
      case MetaEffectType.colorCorruption:
        return _buildColorCorruptionEffect(child);
      case MetaEffectType.textScramble:
        return child; // Handled separately in text widgets
      case MetaEffectType.fakeError:
        return _buildFakeErrorEffect(child);
      case MetaEffectType.screenShake:
        return _buildScreenShakeEffect(child);
      case MetaEffectType.vignettePulse:
        return _buildVignettePulseEffect(child);
      case MetaEffectType.chromaticAberration:
        return _buildChromaticAberrationEffect(child);
    }
  }
  
  Widget _buildGlitchEffect(Widget child) {
    final intensity = widget.controller.intensity;
    final offset = _random.nextDouble() * 20 * intensity - 10 * intensity;
    final showGlitch = _random.nextDouble() < 0.3 * intensity;
    
    return Stack(
      children: [
        Transform.translate(
          offset: showGlitch ? Offset(offset, 0) : Offset.zero,
          child: child,
        ),
        if (showGlitch) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(-3 * intensity, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0x40FF0000),
                    BlendMode.srcATop,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(3 * intensity, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0x4000FFFF),
                    BlendMode.srcATop,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
        if (showGlitch)
          ...List.generate(3, (i) {
            final y = _random.nextDouble() * MediaQuery.of(context).size.height;
            final height = 2.0 + _random.nextDouble() * 10;
            return Positioned(
              left: 0,
              right: 0,
              top: y,
              height: height,
              child: Container(
                color: Colors.white.withOpacity(0.3 * intensity),
              ),
            );
          }),
      ],
    );
  }
  
  Widget _buildStaticNoiseEffect(Widget child) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StaticNoisePainter(
                intensity: widget.controller.intensity,
                seed: _glitchController.value,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScreenTearEffect(Widget child) {
    final intensity = widget.controller.intensity;
    final tearY = _random.nextDouble();
    final tearOffset = (_random.nextDouble() - 0.5) * 50 * intensity;
    
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: tearY,
                child: child,
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(tearOffset, 0),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 1 - tearY,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorCorruptionEffect(Widget child) {
    final intensity = widget.controller.intensity;
    
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        1 + _random.nextDouble() * intensity, 0, 0, 0, 0,
        0, 1 - _random.nextDouble() * intensity, 0, 0, 0,
        0, 0, 1 + _random.nextDouble() * intensity, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }
  
  Widget _buildFakeErrorEffect(Widget child) {
    return Stack(
      children: [
        child,
        Center(
          child: _StoryFakeErrorDialog(
            title: widget.controller.fakeErrorTitle ?? 'Error',
            message: widget.controller.fakeErrorMessage ?? 
                'An unexpected error has occurred.\nThe application will now close.',
            onClose: () => widget.controller.stopEffect(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScreenShakeEffect(Widget child) {
    final intensity = widget.controller.intensity;
    final offsetX = (_random.nextDouble() - 0.5) * 20 * intensity;
    final offsetY = (_random.nextDouble() - 0.5) * 20 * intensity;
    
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: child,
    );
  }
  
  Widget _buildVignettePulseEffect(Widget child) {
    final intensity = widget.controller.intensity;
    final pulse = (sin(_glitchController.value * pi * 4) + 1) / 2;
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3 + pulse * 0.4 * intensity),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildChromaticAberrationEffect(Widget child) {
    final intensity = widget.controller.intensity;
    final offset = 3.0 * intensity;
    
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(-offset, 0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x80FF0000),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        ),
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x400000FF),
                  BlendMode.srcATop,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Static noise painter
class _StaticNoisePainter extends CustomPainter {
  final double intensity;
  final double seed;
  final Random _random;
  
  _StaticNoisePainter({
    required this.intensity,
    required this.seed,
  }) : _random = Random((seed * 10000).toInt());
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const pixelSize = 2.0;
    
    for (var x = 0.0; x < size.width; x += pixelSize) {
      for (var y = 0.0; y < size.height; y += pixelSize) {
        if (_random.nextDouble() < 0.1 * intensity) {
          final gray = _random.nextInt(256);
          paint.color = Color.fromARGB(
            (50 * intensity).toInt(),
            gray, gray, gray,
          );
          canvas.drawRect(
            Rect.fromLTWH(x, y, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(_StaticNoisePainter oldDelegate) => true;
}

/// Fake error dialog for story
class _StoryFakeErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  
  const _StoryFakeErrorDialog({
    required this.title,
    required this.message,
    required this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: const Color(0xFFECE9D8),
          border: Border.all(color: const Color(0xFF0054E3), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0054E3), Color(0xFF2E8AEF)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE97778), Color(0xFFB91C1C)],
                        ),
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Text('×', style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Tahoma',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECE9D8),
                  foregroundColor: Colors.black,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                    side: const BorderSide(color: Color(0xFF003C74)),
                  ),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scramble text widget for story dialogue
class StoryScrambleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool isActive;
  final double intensity;
  
  const StoryScrambleText({
    super.key,
    required this.text,
    this.style,
    this.isActive = false,
    this.intensity = 0.5,
  });
  
  @override
  State<StoryScrambleText> createState() => _StoryScrambleTextState();
}

class _StoryScrambleTextState extends State<StoryScrambleText> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  static const _glitchChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`█▓▒░';
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  String _scrambleText(String text) {
    if (!widget.isActive) return text;
    
    final chars = text.split('');
    for (var i = 0; i < chars.length; i++) {
      if (_random.nextDouble() < 0.1 * widget.intensity) {
        chars[i] = _glitchChars[_random.nextInt(_glitchChars.length)];
      }
    }
    return chars.join();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text(
          _scrambleText(widget.text),
          style: widget.style,
        );
      },
    );
  }
}
