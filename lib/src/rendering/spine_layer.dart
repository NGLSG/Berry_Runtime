// Spine Animation Layer
//
// 集成 spine_flutter 包提供 Spine 骨骼动画支持：
// - 骨骼加载和渲染
// - 动画播放和混合
// - 皮肤切换

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spine_flutter/spine_flutter.dart' as spine;

/// Spine 骨骼配置
class SpineSkeletonConfig {
  final String skeletonPath;
  final String atlasPath;
  final String? defaultAnimation;
  final String? defaultSkin;
  final double scale;
  final Offset offset;
  final bool loopDefault;
  final double mixDuration;
  
  const SpineSkeletonConfig({
    required this.skeletonPath,
    required this.atlasPath,
    this.defaultAnimation,
    this.defaultSkin,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.loopDefault = true,
    this.mixDuration = 0.2,
  });
  
  Map<String, dynamic> toJson() => {
    'skeletonPath': skeletonPath,
    'atlasPath': atlasPath,
    if (defaultAnimation != null) 'defaultAnimation': defaultAnimation,
    if (defaultSkin != null) 'defaultSkin': defaultSkin,
    'scale': scale,
    'offset': {'x': offset.dx, 'y': offset.dy},
    'loopDefault': loopDefault,
    'mixDuration': mixDuration,
  };
  
  factory SpineSkeletonConfig.fromJson(Map<String, dynamic> json) {
    final offset = json['offset'] as Map<String, dynamic>?;
    return SpineSkeletonConfig(
      skeletonPath: json['skeletonPath'] as String,
      atlasPath: json['atlasPath'] as String,
      defaultAnimation: json['defaultAnimation'] as String?,
      defaultSkin: json['defaultSkin'] as String?,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offset: offset != null
          ? Offset((offset['x'] as num).toDouble(), (offset['y'] as num).toDouble())
          : Offset.zero,
      loopDefault: json['loopDefault'] as bool? ?? true,
      mixDuration: (json['mixDuration'] as num?)?.toDouble() ?? 0.2,
    );
  }
}


/// 动画轨道条目
class SpineTrackEntry {
  final int trackIndex;
  final String animationName;
  final bool loop;
  final double mixDuration;
  
  const SpineTrackEntry({
    required this.trackIndex,
    required this.animationName,
    this.loop = false,
    this.mixDuration = 0.2,
  });
}

/// Spine 控制器接口
abstract class SpineController {
  Future<void> loadSkeleton(SpineSkeletonConfig config);
  Future<void> unloadSkeleton();
  Future<SpineTrackEntry?> setAnimation(int trackIndex, String animationName, {bool loop = false});
  Future<SpineTrackEntry?> addAnimation(int trackIndex, String animationName, {bool loop = false, double delay = 0});
  void clearTrack(int trackIndex);
  void clearTracks();
  void setSkin(String skinName);
  void update(double deltaTime);
  List<String> get availableAnimations;
  List<String> get availableSkins;
  bool get isLoaded;
  Stream<SpineTrackEntry> get onAnimationComplete;
  void dispose();
}

/// 占位 Spine 控制器
class PlaceholderSpineController implements SpineController {
  bool _isLoaded = false;
  String? currentAnimation;
  String? currentSkin;
  
  final _animationCompleteController = StreamController<SpineTrackEntry>.broadcast();
  final List<String> _animations = ['idle', 'walk', 'run', 'attack', 'hit', 'die', 'jump', 'talk'];
  final List<String> _skins = ['default', 'outfit_1', 'outfit_2', 'special'];
  
  @override
  Future<void> loadSkeleton(SpineSkeletonConfig config) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoaded = true;
    currentSkin = config.defaultSkin ?? 'default';
    if (config.defaultAnimation != null) {
      await setAnimation(0, config.defaultAnimation!, loop: config.loopDefault);
    }
  }
  
  @override
  Future<void> unloadSkeleton() async {
    _isLoaded = false;
    currentAnimation = null;
    currentSkin = null;
  }
  
  @override
  Future<SpineTrackEntry?> setAnimation(int trackIndex, String animationName, {bool loop = false}) async {
    if (!_isLoaded) return null;
    currentAnimation = animationName;
    final entry = SpineTrackEntry(trackIndex: trackIndex, animationName: animationName, loop: loop);
    if (!loop) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!_animationCompleteController.isClosed) {
          _animationCompleteController.add(entry);
        }
      });
    }
    return entry;
  }
  
  @override
  Future<SpineTrackEntry?> addAnimation(int trackIndex, String animationName, {bool loop = false, double delay = 0}) async {
    if (!_isLoaded) return null;
    return SpineTrackEntry(trackIndex: trackIndex, animationName: animationName, loop: loop);
  }
  
  @override void clearTrack(int trackIndex) {}
  @override void clearTracks() { currentAnimation = null; }
  @override void setSkin(String skinName) { if (_isLoaded) currentSkin = skinName; }
  @override void update(double deltaTime) {}
  @override List<String> get availableAnimations => _animations;
  @override List<String> get availableSkins => _skins;
  @override bool get isLoaded => _isLoaded;
  @override Stream<SpineTrackEntry> get onAnimationComplete => _animationCompleteController.stream;
  
  @override
  void dispose() {
    _animationCompleteController.close();
    _isLoaded = false;
  }
}


/// Spine 角色 Widget
class SpineCharacterWidget extends StatefulWidget {
  final SpineSkeletonConfig config;
  final String? animation;
  final String? skin;
  final bool loop;
  final VoidCallback? onAnimationComplete;
  final bool usePlaceholder;
  
  const SpineCharacterWidget({
    super.key,
    required this.config,
    this.animation,
    this.skin,
    this.loop = true,
    this.onAnimationComplete,
    this.usePlaceholder = false,
  });

  @override
  State<SpineCharacterWidget> createState() => _SpineCharacterWidgetState();
}

class _SpineCharacterWidgetState extends State<SpineCharacterWidget>
    with SingleTickerProviderStateMixin {
  PlaceholderSpineController? _placeholderController;
  AnimationController? _animController;
  StreamSubscription? _completeSub;
  bool _isLoading = true;
  bool _usePlaceholder = false;
  spine.SpineWidgetController? _spineController;
  
  @override
  void initState() {
    super.initState();
    _usePlaceholder = widget.usePlaceholder;
    
    if (_usePlaceholder) {
      _initPlaceholder();
    } else {
      _initSpine();
    }
  }
  
  void _initPlaceholder() {
    _placeholderController = PlaceholderSpineController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _completeSub = _placeholderController!.onAnimationComplete.listen((entry) {
      widget.onAnimationComplete?.call();
    });
    
    _loadPlaceholder();
  }
  
  Future<void> _loadPlaceholder() async {
    await _placeholderController!.loadSkeleton(widget.config);
    if (widget.animation != null) {
      await _placeholderController!.setAnimation(0, widget.animation!, loop: widget.loop);
    }
    if (widget.skin != null) {
      _placeholderController!.setSkin(widget.skin!);
    }
    if (mounted) setState(() => _isLoading = false);
  }
  
  void _initSpine() {
    _spineController = spine.SpineWidgetController(
      onInitialized: (controller) {
        final anim = widget.animation ?? widget.config.defaultAnimation;
        if (anim != null) {
          controller.animationState.setAnimation(0, anim, widget.loop);
        }
        
        final skinName = widget.skin ?? widget.config.defaultSkin;
        if (skinName != null) {
          final skin = controller.skeletonData.findSkin(skinName);
          if (skin != null) {
            controller.skeleton.setSkin2(skin);
            controller.skeleton.setupPoseSlots();
          }
        }
        
        controller.animationStateData.defaultMix = widget.config.mixDuration;
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }
  
  @override
  void didUpdateWidget(SpineCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_usePlaceholder) {
      if (widget.animation != oldWidget.animation && widget.animation != null) {
        _placeholderController?.setAnimation(0, widget.animation!, loop: widget.loop);
      }
      if (widget.skin != oldWidget.skin && widget.skin != null) {
        _placeholderController?.setSkin(widget.skin!);
      }
    } else if (_spineController != null) {
      if (widget.animation != oldWidget.animation && widget.animation != null) {
        _spineController!.animationState.setAnimation(0, widget.animation!, widget.loop);
      }
      if (widget.skin != oldWidget.skin && widget.skin != null) {
        final skin = _spineController!.skeletonData.findSkin(widget.skin!);
        if (skin != null) {
          _spineController!.skeleton.setSkin2(skin);
          _spineController!.skeleton.setupPoseSlots();
        }
      }
    }
  }
  
  @override
  void dispose() {
    _completeSub?.cancel();
    _animController?.dispose();
    _placeholderController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_usePlaceholder) {
      if (_isLoading) return const Center(child: CircularProgressIndicator());
      return AnimatedBuilder(
        animation: _animController!,
        builder: (context, child) => CustomPaint(
          painter: _SpinePlaceholderPainter(
            animationValue: _animController!.value,
            animation: widget.animation ?? 'idle',
            skin: widget.skin ?? 'default',
          ),
          size: Size.infinite,
        ),
      );
    }
    
    // 使用真实的 SpineWidget
    return spine.SpineWidget.fromAsset(
      widget.config.atlasPath,
      widget.config.skeletonPath,
      _spineController!,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}


/// 占位绘制器
class _SpinePlaceholderPainter extends CustomPainter {
  final double animationValue;
  final String animation;
  final String skin;
  
  _SpinePlaceholderPainter({
    required this.animationValue,
    required this.animation,
    required this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    
    Color boneColor;
    switch (skin) {
      case 'outfit_1': boneColor = Colors.blue.shade700; break;
      case 'outfit_2': boneColor = Colors.red.shade700; break;
      case 'special': boneColor = Colors.purple.shade700; break;
      default: boneColor = Colors.grey.shade700;
    }
    
    final bonePaint = Paint()..color = boneColor..strokeWidth = 4..strokeCap = StrokeCap.round;
    final jointPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    double legAngle = 0, armAngle = 0, bodyBob = 0;
    
    switch (animation) {
      case 'walk':
        legAngle = math.sin(animationValue * 4 * math.pi) * 0.4;
        armAngle = -legAngle * 0.5;
        bodyBob = math.sin(animationValue * 4 * math.pi).abs() * 5;
      case 'run':
        legAngle = math.sin(animationValue * 6 * math.pi) * 0.6;
        armAngle = -legAngle * 0.7;
        bodyBob = math.sin(animationValue * 6 * math.pi).abs() * 10;
      case 'idle':
        bodyBob = math.sin(animationValue * 2 * math.pi) * 3;
        armAngle = math.sin(animationValue * 2 * math.pi) * 0.05;
      case 'attack':
        armAngle = math.sin(animationValue * 8 * math.pi) * 1.2;
      case 'jump':
        bodyBob = -math.sin(animationValue * math.pi) * 50;
        legAngle = -0.3;
      case 'talk':
        bodyBob = math.sin(animationValue * 4 * math.pi) * 2;
    }
    
    final bodyCenter = Offset(center.dx, center.dy - 80 + bodyBob);
    
    // 脊柱
    canvas.drawLine(Offset(bodyCenter.dx, bodyCenter.dy + 60), Offset(bodyCenter.dx, bodyCenter.dy - 20), bonePaint);
    // 头
    canvas.drawCircle(Offset(bodyCenter.dx, bodyCenter.dy - 40), 25, bonePaint);
    
    // 左臂
    canvas.save();
    canvas.translate(bodyCenter.dx - 15, bodyCenter.dy - 10);
    canvas.rotate(armAngle - 0.3);
    canvas.drawLine(Offset.zero, const Offset(-30, 40), bonePaint);
    canvas.drawLine(const Offset(-30, 40), const Offset(-25, 80), bonePaint);
    canvas.restore();
    
    // 右臂
    canvas.save();
    canvas.translate(bodyCenter.dx + 15, bodyCenter.dy - 10);
    canvas.rotate(-armAngle + 0.3);
    canvas.drawLine(Offset.zero, const Offset(30, 40), bonePaint);
    canvas.drawLine(const Offset(30, 40), const Offset(25, 80), bonePaint);
    canvas.restore();
    
    // 左腿
    canvas.save();
    canvas.translate(bodyCenter.dx - 10, bodyCenter.dy + 60);
    canvas.rotate(legAngle);
    canvas.drawLine(Offset.zero, const Offset(-10, 60), bonePaint);
    canvas.drawLine(const Offset(-10, 60), const Offset(-5, 120), bonePaint);
    canvas.restore();
    
    // 右腿
    canvas.save();
    canvas.translate(bodyCenter.dx + 10, bodyCenter.dy + 60);
    canvas.rotate(-legAngle);
    canvas.drawLine(Offset.zero, const Offset(10, 60), bonePaint);
    canvas.drawLine(const Offset(10, 60), const Offset(5, 120), bonePaint);
    canvas.restore();
    
    // 关节
    canvas.drawCircle(Offset(bodyCenter.dx, bodyCenter.dy - 10), 6, jointPaint);
    canvas.drawCircle(Offset(bodyCenter.dx, bodyCenter.dy + 60), 6, jointPaint);
    
    // 标签
    final textPainter = TextPainter(
      text: TextSpan(text: 'Spine: $animation ($skin)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant _SpinePlaceholderPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue || animation != oldDelegate.animation || skin != oldDelegate.skin;
}
