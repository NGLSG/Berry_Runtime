/// Meta Effects for DDLC-style visual novel experiences
/// 
/// Provides glitch, corruption, and fourth-wall-breaking effects

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../models/vn_project.dart';

/// Controller for managing meta effects
class MetaEffectController extends ChangeNotifier {
  MetaEffectType _currentEffect = MetaEffectType.none;
  double _intensity = 0.5;
  bool _isActive = false;
  Timer? _randomTimer;
  Timer? _effectTimer;
  final Random _random = Random();
  
  MetaEffectType get currentEffect => _currentEffect;
  double get intensity => _intensity;
  bool get isActive => _isActive;
  
  /// Start meta effects with configuration
  void start(VNMainMenuConfig config) {
    if (!config.enableMetaEffects) return;
    
    _intensity = config.metaEffectIntensity;
    
    switch (config.metaEffectTrigger) {
      case 'always':
        _triggerEffect(config.metaEffectType);
        break;
      case 'afterDelay':
        _effectTimer = Timer(Duration(milliseconds: config.metaEffectDelay), () {
          _triggerEffect(config.metaEffectType);
        });
        break;
      case 'random':
        _startRandomTrigger(config);
        break;
      case 'onHover':
        // Handled externally
        break;
    }
  }
  
  void _startRandomTrigger(VNMainMenuConfig config) {
    void scheduleNext() {
      final delay = config.metaEffectRandomMin + 
          _random.nextInt(config.metaEffectRandomMax - config.metaEffectRandomMin);
      _randomTimer = Timer(Duration(milliseconds: delay), () {
        _triggerEffect(config.metaEffectType);
        // Auto-stop after a short duration
        Timer(Duration(milliseconds: 500 + _random.nextInt(1500)), () {
          stopEffect();
          scheduleNext();
        });
      });
    }
    scheduleNext();
  }
  
  void _triggerEffect(MetaEffectType type) {
    _currentEffect = type;
    _isActive = true;
    notifyListeners();
  }
  
  /// Trigger effect on hover (for onHover mode)
  void triggerOnHover(MetaEffectType type) {
    _triggerEffect(type);
  }
  
  /// Stop current effect
  void stopEffect() {
    _isActive = false;
    _currentEffect = MetaEffectType.none;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _randomTimer?.cancel();
    _effectTimer?.cancel();
    super.dispose();
  }
}

/// Widget that applies meta effects to its child
class MetaEffectLayer extends StatefulWidget {
  final Widget child;
  final MetaEffectController controller;
  final VNMainMenuConfig config;
  
  const MetaEffectLayer({
    super.key,
    required this.child,
    required this.controller,
    required this.config,
  });
  
  @override
  State<MetaEffectLayer> createState() => _MetaEffectLayerState();
}

class _MetaEffectLayerState extends State<MetaEffectLayer> 
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
        // Main content with random offset
        Transform.translate(
          offset: showGlitch ? Offset(offset, 0) : Offset.zero,
          child: child,
        ),
        // RGB split effect
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
        // Random glitch bars
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
          // Top part
          Positioned.fill(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: tearY,
                child: child,
              ),
            ),
          ),
          // Bottom part with offset
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
    final hue = _random.nextDouble() * 360;
    
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
          child: _FakeErrorDialog(
            title: widget.config.fakeErrorTitle ?? 'Error',
            message: widget.config.fakeErrorMessage ?? 
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
        // Red channel
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
        // Green channel (center)
        child,
        // Blue channel
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

/// Custom painter for static noise effect
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
    final pixelSize = 2.0;
    
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

/// Fake Windows-style error dialog
class _FakeErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  
  const _FakeErrorDialog({
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
            // Title bar
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
            // Content
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
            // Button
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

/// Text scramble effect widget
class ScrambleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool isActive;
  final double intensity;
  
  const ScrambleText({
    super.key,
    required this.text,
    this.style,
    this.isActive = false,
    this.intensity = 0.5,
  });
  
  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText> 
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
