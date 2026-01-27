/// Live2D Character Layer
/// 
/// Provides Live2D model support for VN characters:
/// - Model loading and rendering
/// - Expression/motion control
/// - Lip sync support
/// - Physics simulation
/// 
/// Note: This is an abstraction layer. Actual Live2D rendering requires
/// the Live2D Cubism SDK which has licensing requirements.
/// This implementation provides the interface and can be connected to:
/// - flutter_live2d (community package)
/// - Native platform channels to Cubism SDK
/// - WebGL rendering for web platform

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Live2D model configuration
class Live2DModelConfig {
  /// Path to the model file (.model3.json)
  final String modelPath;
  
  /// Model scale
  final double scale;
  
  /// Model position offset
  final Offset offset;
  
  /// Whether to enable physics
  final bool enablePhysics;
  
  /// Whether to enable eye tracking
  final bool enableEyeTracking;
  
  /// Whether to enable breathing animation
  final bool enableBreathing;
  
  /// Idle motion group name
  final String? idleMotionGroup;
  
  /// Default expression
  final String? defaultExpression;
  
  const Live2DModelConfig({
    required this.modelPath,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.enablePhysics = true,
    this.enableEyeTracking = true,
    this.enableBreathing = true,
    this.idleMotionGroup,
    this.defaultExpression,
  });
  
  Map<String, dynamic> toJson() => {
    'modelPath': modelPath,
    'scale': scale,
    'offset': {'x': offset.dx, 'y': offset.dy},
    'enablePhysics': enablePhysics,
    'enableEyeTracking': enableEyeTracking,
    'enableBreathing': enableBreathing,
    if (idleMotionGroup != null) 'idleMotionGroup': idleMotionGroup,
    if (defaultExpression != null) 'defaultExpression': defaultExpression,
  };
  
  factory Live2DModelConfig.fromJson(Map<String, dynamic> json) {
    final offset = json['offset'] as Map<String, dynamic>?;
    return Live2DModelConfig(
      modelPath: json['modelPath'] as String,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offset: offset != null 
          ? Offset((offset['x'] as num).toDouble(), (offset['y'] as num).toDouble())
          : Offset.zero,
      enablePhysics: json['enablePhysics'] as bool? ?? true,
      enableEyeTracking: json['enableEyeTracking'] as bool? ?? true,
      enableBreathing: json['enableBreathing'] as bool? ?? true,
      idleMotionGroup: json['idleMotionGroup'] as String?,
      defaultExpression: json['defaultExpression'] as String?,
    );
  }
}

/// Live2D motion priority
enum Live2DMotionPriority {
  none,
  idle,
  normal,
  force,
}

/// Live2D controller interface
abstract class Live2DController {
  /// Load a model
  Future<void> loadModel(Live2DModelConfig config);
  
  /// Unload the current model
  Future<void> unloadModel();
  
  /// Set expression
  Future<void> setExpression(String expressionId);
  
  /// Play motion
  Future<void> playMotion(
    String motionGroup,
    int motionIndex, {
    Live2DMotionPriority priority = Live2DMotionPriority.normal,
  });
  
  /// Start lip sync
  void startLipSync(Stream<double> audioLevelStream);
  
  /// Stop lip sync
  void stopLipSync();
  
  /// Set eye tracking target
  void setLookAt(Offset target);
  
  /// Update model (call each frame)
  void update(double deltaTime);
  
  /// Get available expressions
  List<String> get availableExpressions;
  
  /// Get available motion groups
  Map<String, int> get availableMotions;
  
  /// Whether model is loaded
  bool get isLoaded;
  
  /// Dispose resources
  void dispose();
}

/// Placeholder Live2D controller implementation
/// Replace with actual SDK integration
class PlaceholderLive2DController implements Live2DController {
  Live2DModelConfig? _config;
  bool _isLoaded = false;
  String? _currentExpression;
  final List<String> _expressions = ['default', 'happy', 'sad', 'angry', 'surprised'];
  final Map<String, int> _motions = {
    'idle': 3,
    'tap_body': 2,
    'flick_head': 1,
  };
  
  @override
  Future<void> loadModel(Live2DModelConfig config) async {
    _config = config;
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoaded = true;
    _currentExpression = config.defaultExpression ?? 'default';
  }
  
  @override
  Future<void> unloadModel() async {
    _isLoaded = false;
    _config = null;
    _currentExpression = null;
  }
  
  @override
  Future<void> setExpression(String expressionId) async {
    if (!_isLoaded) return;
    _currentExpression = expressionId;
  }
  
  @override
  Future<void> playMotion(
    String motionGroup,
    int motionIndex, {
    Live2DMotionPriority priority = Live2DMotionPriority.normal,
  }) async {
    if (!_isLoaded) return;
    // Motion playback would be handled by SDK
  }
  
  @override
  void startLipSync(Stream<double> audioLevelStream) {
    // Lip sync would be handled by SDK
  }
  
  @override
  void stopLipSync() {
    // Stop lip sync
  }
  
  @override
  void setLookAt(Offset target) {
    // Eye tracking would be handled by SDK
  }
  
  @override
  void update(double deltaTime) {
    // Update would be handled by SDK
  }
  
  @override
  List<String> get availableExpressions => _expressions;
  
  @override
  Map<String, int> get availableMotions => _motions;
  
  @override
  bool get isLoaded => _isLoaded;
  
  @override
  void dispose() {
    _isLoaded = false;
  }
}

/// Live2D character widget
class Live2DCharacterWidget extends StatefulWidget {
  final Live2DModelConfig config;
  final String? expression;
  final String? motionGroup;
  final int? motionIndex;
  final bool enableInteraction;
  final Live2DController? controller;
  
  const Live2DCharacterWidget({
    super.key,
    required this.config,
    this.expression,
    this.motionGroup,
    this.motionIndex,
    this.enableInteraction = true,
    this.controller,
  });

  @override
  State<Live2DCharacterWidget> createState() => _Live2DCharacterWidgetState();
}

class _Live2DCharacterWidgetState extends State<Live2DCharacterWidget>
    with SingleTickerProviderStateMixin {
  late Live2DController _controller;
  late AnimationController _animController;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PlaceholderLive2DController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _loadModel();
  }
  
  @override
  void didUpdateWidget(Live2DCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.expression != oldWidget.expression && widget.expression != null) {
      _controller.setExpression(widget.expression!);
    }
    
    if (widget.motionGroup != oldWidget.motionGroup && widget.motionGroup != null) {
      _controller.playMotion(
        widget.motionGroup!,
        widget.motionIndex ?? 0,
      );
    }
  }
  
  Future<void> _loadModel() async {
    try {
      await _controller.loadModel(widget.config);
      if (widget.expression != null) {
        await _controller.setExpression(widget.expression!);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  @override
  void dispose() {
    _animController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text('Live2D 加载失败', style: TextStyle(color: Colors.red.shade300)),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Placeholder rendering - replace with actual Live2D canvas
    return GestureDetector(
      onTapDown: widget.enableInteraction ? _handleTap : null,
      onPanUpdate: widget.enableInteraction ? _handleDrag : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            painter: _Live2DPlaceholderPainter(
              animationValue: _animController.value,
              expression: widget.expression ?? 'default',
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
  
  void _handleTap(TapDownDetails details) {
    // Trigger tap motion
    _controller.playMotion('tap_body', 0);
  }
  
  void _handleDrag(DragUpdateDetails details) {
    // Update eye tracking
    _controller.setLookAt(details.localPosition);
  }
}

/// Placeholder painter for Live2D preview
class _Live2DPlaceholderPainter extends CustomPainter {
  final double animationValue;
  final String expression;
  
  _Live2DPlaceholderPainter({
    required this.animationValue,
    required this.expression,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw placeholder character silhouette
    final bodyPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    
    // Body
    final bodyPath = Path()
      ..moveTo(center.dx - 60, size.height)
      ..lineTo(center.dx - 40, center.dy + 50)
      ..quadraticBezierTo(center.dx, center.dy + 30, center.dx + 40, center.dy + 50)
      ..lineTo(center.dx + 60, size.height)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Head with breathing animation
    final breathOffset = math.sin(animationValue * 2 * math.pi) * 3;
    final headCenter = Offset(center.dx, center.dy - 20 + breathOffset);
    
    canvas.drawCircle(headCenter, 50, bodyPaint);
    
    // Face features based on expression
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Eyes
    final eyeY = headCenter.dy - 5;
    final leftEyeX = headCenter.dx - 20;
    final rightEyeX = headCenter.dx + 20;
    
    if (expression == 'happy' || expression == 'surprised') {
      // Open eyes
      canvas.drawOval(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: 12, height: 16),
        facePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: 12, height: 16),
        facePaint,
      );
      
      // Pupils
      final pupilPaint = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(leftEyeX, eyeY), 4, pupilPaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), 4, pupilPaint);
    } else if (expression == 'sad') {
      // Droopy eyes
      canvas.drawArc(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: 12, height: 8),
        0, math.pi, false,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: 12, height: 8),
        0, math.pi, false,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    } else {
      // Default eyes
      canvas.drawOval(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: 10, height: 12),
        facePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: 10, height: 12),
        facePaint,
      );
    }
    
    // Mouth
    final mouthY = headCenter.dy + 15;
    if (expression == 'happy') {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(headCenter.dx, mouthY), width: 20, height: 10),
        0, math.pi, false,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    } else if (expression == 'sad') {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(headCenter.dx, mouthY + 5), width: 20, height: 10),
        math.pi, math.pi, false,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    } else if (expression == 'surprised') {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(headCenter.dx, mouthY), width: 12, height: 16),
        facePaint,
      );
    } else {
      canvas.drawLine(
        Offset(headCenter.dx - 8, mouthY),
        Offset(headCenter.dx + 8, mouthY),
        Paint()..color = Colors.white..strokeWidth = 2,
      );
    }
    
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Live2D: $expression',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, size.height - 30),
    );
  }

  @override
  bool shouldRepaint(covariant _Live2DPlaceholderPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
           expression != oldDelegate.expression;
  }
}

/// Live2D character layer for story rendering
class Live2DCharacterLayer extends StatelessWidget {
  final List<Live2DCharacterState> characters;
  final Size screenSize;
  
  const Live2DCharacterLayer({
    super.key,
    required this.characters,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: characters.map((char) {
        final position = _calculatePosition(char.slot, screenSize);
        
        return Positioned(
          left: position.dx,
          bottom: 0,
          width: screenSize.width * 0.4,
          height: screenSize.height * 0.9,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(char.flipped ? -char.scale : char.scale, char.scale),
            child: Live2DCharacterWidget(
              config: char.config,
              expression: char.expression,
              motionGroup: char.motionGroup,
              motionIndex: char.motionIndex,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Offset _calculatePosition(CharacterSlot slot, Size size) {
    switch (slot) {
      case CharacterSlot.farLeft:
        return Offset(size.width * 0.05, 0);
      case CharacterSlot.left:
        return Offset(size.width * 0.15, 0);
      case CharacterSlot.center:
        return Offset(size.width * 0.3, 0);
      case CharacterSlot.right:
        return Offset(size.width * 0.45, 0);
      case CharacterSlot.farRight:
        return Offset(size.width * 0.55, 0);
      case CharacterSlot.custom:
        return Offset.zero;
    }
  }
}

/// Character slot positions
enum CharacterSlot {
  farLeft,
  left,
  center,
  right,
  farRight,
  custom,
}

/// Live2D character state
class Live2DCharacterState {
  final String characterId;
  final Live2DModelConfig config;
  final CharacterSlot slot;
  final String? expression;
  final String? motionGroup;
  final int? motionIndex;
  final double scale;
  final bool flipped;
  
  const Live2DCharacterState({
    required this.characterId,
    required this.config,
    this.slot = CharacterSlot.center,
    this.expression,
    this.motionGroup,
    this.motionIndex,
    this.scale = 1.0,
    this.flipped = false,
  });
}
