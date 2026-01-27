/// Unified Character Renderer
/// 
/// Manages character rendering with support for multiple formats:
/// - Static sprites (PNG/WebP)
/// - Live2D models
/// - Spine skeletons
/// 
/// Automatically selects the appropriate renderer based on character configuration.

import 'dart:io';
import 'package:flutter/material.dart';
import 'live2d_layer.dart';
import 'spine_layer.dart';

/// Character render type
enum CharacterRenderType {
  /// Static image sprite
  sprite,
  
  /// Live2D Cubism model
  live2d,
  
  /// Spine skeletal animation
  spine,
}

/// Unified character configuration
class CharacterRenderConfig {
  /// Character ID
  final String characterId;
  
  /// Render type
  final CharacterRenderType renderType;
  
  /// Sprite configuration (for sprite type)
  final SpriteConfig? spriteConfig;
  
  /// Live2D configuration (for live2d type)
  final Live2DModelConfig? live2dConfig;
  
  /// Spine configuration (for spine type)
  final SpineSkeletonConfig? spineConfig;
  
  const CharacterRenderConfig({
    required this.characterId,
    required this.renderType,
    this.spriteConfig,
    this.live2dConfig,
    this.spineConfig,
  });
  
  /// Create sprite character config
  factory CharacterRenderConfig.sprite({
    required String characterId,
    required String defaultSprite,
    Map<String, String> expressions = const {},
    double scale = 1.0,
  }) {
    return CharacterRenderConfig(
      characterId: characterId,
      renderType: CharacterRenderType.sprite,
      spriteConfig: SpriteConfig(
        defaultSprite: defaultSprite,
        expressions: expressions,
        scale: scale,
      ),
    );
  }
  
  /// Create Live2D character config
  factory CharacterRenderConfig.live2d({
    required String characterId,
    required String modelPath,
    double scale = 1.0,
    String? defaultExpression,
    String? idleMotionGroup,
  }) {
    return CharacterRenderConfig(
      characterId: characterId,
      renderType: CharacterRenderType.live2d,
      live2dConfig: Live2DModelConfig(
        modelPath: modelPath,
        scale: scale,
        defaultExpression: defaultExpression,
        idleMotionGroup: idleMotionGroup,
      ),
    );
  }
  
  /// Create Spine character config
  factory CharacterRenderConfig.spine({
    required String characterId,
    required String skeletonPath,
    required String atlasPath,
    double scale = 1.0,
    String? defaultAnimation,
    String? defaultSkin,
  }) {
    return CharacterRenderConfig(
      characterId: characterId,
      renderType: CharacterRenderType.spine,
      spineConfig: SpineSkeletonConfig(
        skeletonPath: skeletonPath,
        atlasPath: atlasPath,
        scale: scale,
        defaultAnimation: defaultAnimation,
        defaultSkin: defaultSkin,
      ),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'renderType': renderType.name,
    if (spriteConfig != null) 'spriteConfig': spriteConfig!.toJson(),
    if (live2dConfig != null) 'live2dConfig': live2dConfig!.toJson(),
    if (spineConfig != null) 'spineConfig': spineConfig!.toJson(),
  };
  
  factory CharacterRenderConfig.fromJson(Map<String, dynamic> json) {
    final renderType = CharacterRenderType.values.firstWhere(
      (e) => e.name == json['renderType'],
      orElse: () => CharacterRenderType.sprite,
    );
    
    return CharacterRenderConfig(
      characterId: json['characterId'] as String,
      renderType: renderType,
      spriteConfig: json['spriteConfig'] != null
          ? SpriteConfig.fromJson(json['spriteConfig'] as Map<String, dynamic>)
          : null,
      live2dConfig: json['live2dConfig'] != null
          ? Live2DModelConfig.fromJson(json['live2dConfig'] as Map<String, dynamic>)
          : null,
      spineConfig: json['spineConfig'] != null
          ? SpineSkeletonConfig.fromJson(json['spineConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Sprite configuration
class SpriteConfig {
  final String defaultSprite;
  final Map<String, String> expressions;
  final double scale;
  
  const SpriteConfig({
    required this.defaultSprite,
    this.expressions = const {},
    this.scale = 1.0,
  });
  
  Map<String, dynamic> toJson() => {
    'defaultSprite': defaultSprite,
    'expressions': expressions,
    'scale': scale,
  };
  
  factory SpriteConfig.fromJson(Map<String, dynamic> json) {
    return SpriteConfig(
      defaultSprite: json['defaultSprite'] as String,
      expressions: Map<String, String>.from(json['expressions'] ?? {}),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Character display state
class CharacterDisplayState {
  final String characterId;
  final CharacterRenderConfig config;
  final CharacterPosition position;
  final String? expression;
  final String? animation;
  final String? skin;
  final bool isVisible;
  final double opacity;
  
  const CharacterDisplayState({
    required this.characterId,
    required this.config,
    required this.position,
    this.expression,
    this.animation,
    this.skin,
    this.isVisible = true,
    this.opacity = 1.0,
  });
  
  CharacterDisplayState copyWith({
    String? characterId,
    CharacterRenderConfig? config,
    CharacterPosition? position,
    String? expression,
    String? animation,
    String? skin,
    bool? isVisible,
    double? opacity,
  }) {
    return CharacterDisplayState(
      characterId: characterId ?? this.characterId,
      config: config ?? this.config,
      position: position ?? this.position,
      expression: expression ?? this.expression,
      animation: animation ?? this.animation,
      skin: skin ?? this.skin,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Character position
class CharacterPosition {
  final CharacterSlotPosition slot;
  final double? customX;
  final double? customY;
  final double scale;
  final bool flipped;
  
  const CharacterPosition({
    this.slot = CharacterSlotPosition.center,
    this.customX,
    this.customY,
    this.scale = 1.0,
    this.flipped = false,
  });
  
  Offset getScreenPosition(Size screenSize) {
    if (slot == CharacterSlotPosition.custom && customX != null) {
      return Offset(
        screenSize.width * customX!,
        customY != null ? screenSize.height * customY! : 0,
      );
    }
    
    switch (slot) {
      case CharacterSlotPosition.farLeft:
        return Offset(screenSize.width * 0.1, 0);
      case CharacterSlotPosition.left:
        return Offset(screenSize.width * 0.25, 0);
      case CharacterSlotPosition.center:
        return Offset(screenSize.width * 0.5, 0);
      case CharacterSlotPosition.right:
        return Offset(screenSize.width * 0.75, 0);
      case CharacterSlotPosition.farRight:
        return Offset(screenSize.width * 0.9, 0);
      case CharacterSlotPosition.custom:
        return Offset.zero;
    }
  }
}

enum CharacterSlotPosition {
  farLeft,
  left,
  center,
  right,
  farRight,
  custom,
}

/// Unified character renderer widget
class UnifiedCharacterRenderer extends StatelessWidget {
  final CharacterDisplayState state;
  final String? projectPath;
  
  const UnifiedCharacterRenderer({
    super.key,
    required this.state,
    this.projectPath,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isVisible) return const SizedBox.shrink();
    
    return Opacity(
      opacity: state.opacity,
      child: _buildRenderer(),
    );
  }
  
  Widget _buildRenderer() {
    switch (state.config.renderType) {
      case CharacterRenderType.sprite:
        return _buildSpriteRenderer();
      case CharacterRenderType.live2d:
        return _buildLive2DRenderer();
      case CharacterRenderType.spine:
        return _buildSpineRenderer();
    }
  }
  
  Widget _buildSpriteRenderer() {
    final spriteConfig = state.config.spriteConfig;
    if (spriteConfig == null) return const SizedBox.shrink();
    
    // Get sprite path based on expression
    String spritePath = spriteConfig.defaultSprite;
    if (state.expression != null && spriteConfig.expressions.containsKey(state.expression)) {
      spritePath = spriteConfig.expressions[state.expression]!;
    }
    
    // Build full path
    final fullPath = projectPath != null ? '$projectPath/$spritePath' : spritePath;
    
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..scale(
          state.position.flipped ? -state.position.scale : state.position.scale,
          state.position.scale,
        ),
      child: _buildImage(fullPath),
    );
  }
  
  Widget _buildImage(String path) {
    // Check if it's a file path or asset
    if (path.startsWith('assets/') || path.startsWith('packages/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: 200,
      height: 400,
      color: Colors.grey.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.person, size: 64, color: Colors.grey),
      ),
    );
  }
  
  Widget _buildLive2DRenderer() {
    final live2dConfig = state.config.live2dConfig;
    if (live2dConfig == null) return const SizedBox.shrink();
    
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..scale(
          state.position.flipped ? -state.position.scale : state.position.scale,
          state.position.scale,
        ),
      child: Live2DCharacterWidget(
        config: live2dConfig,
        expression: state.expression,
        motionGroup: state.animation,
      ),
    );
  }
  
  Widget _buildSpineRenderer() {
    final spineConfig = state.config.spineConfig;
    if (spineConfig == null) return const SizedBox.shrink();
    
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..scale(
          state.position.flipped ? -state.position.scale : state.position.scale,
          state.position.scale,
        ),
      child: SpineCharacterWidget(
        config: spineConfig,
        animation: state.animation ?? spineConfig.defaultAnimation,
        skin: state.skin ?? spineConfig.defaultSkin,
      ),
    );
  }
}

/// Character layer that renders multiple characters
class UnifiedCharacterLayer extends StatelessWidget {
  final List<CharacterDisplayState> characters;
  final Size screenSize;
  final String? projectPath;
  
  const UnifiedCharacterLayer({
    super.key,
    required this.characters,
    required this.screenSize,
    this.projectPath,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by position (left to right) for proper layering
    final sortedCharacters = List<CharacterDisplayState>.from(characters)
      ..sort((a, b) {
        final posA = a.position.getScreenPosition(screenSize);
        final posB = b.position.getScreenPosition(screenSize);
        return posA.dx.compareTo(posB.dx);
      });
    
    return Stack(
      children: sortedCharacters.map((state) {
        final position = state.position.getScreenPosition(screenSize);
        
        return Positioned(
          left: position.dx - (screenSize.width * 0.2), // Center the character
          bottom: position.dy,
          width: screenSize.width * 0.4,
          height: screenSize.height * 0.9,
          child: UnifiedCharacterRenderer(
            state: state,
            projectPath: projectPath,
          ),
        );
      }).toList(),
    );
  }
}

/// Character render manager
class CharacterRenderManager extends ChangeNotifier {
  final Map<String, CharacterRenderConfig> _configs = {};
  final Map<String, CharacterDisplayState> _displayStates = {};
  
  Map<String, CharacterRenderConfig> get configs => Map.unmodifiable(_configs);
  List<CharacterDisplayState> get visibleCharacters => 
      _displayStates.values.where((s) => s.isVisible).toList();
  
  /// Register a character configuration
  void registerCharacter(CharacterRenderConfig config) {
    _configs[config.characterId] = config;
    notifyListeners();
  }
  
  /// Unregister a character
  void unregisterCharacter(String characterId) {
    _configs.remove(characterId);
    _displayStates.remove(characterId);
    notifyListeners();
  }
  
  /// Show a character
  void showCharacter(
    String characterId, {
    CharacterPosition position = const CharacterPosition(),
    String? expression,
    String? animation,
    String? skin,
  }) {
    final config = _configs[characterId];
    if (config == null) return;
    
    _displayStates[characterId] = CharacterDisplayState(
      characterId: characterId,
      config: config,
      position: position,
      expression: expression,
      animation: animation,
      skin: skin,
      isVisible: true,
    );
    notifyListeners();
  }
  
  /// Hide a character
  void hideCharacter(String characterId) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(isVisible: false);
      notifyListeners();
    }
  }
  
  /// Update character expression
  void setExpression(String characterId, String expression) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(expression: expression);
      notifyListeners();
    }
  }
  
  /// Update character animation (for Live2D/Spine)
  void setAnimation(String characterId, String animation) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(animation: animation);
      notifyListeners();
    }
  }
  
  /// Update character skin (for Spine)
  void setSkin(String characterId, String skin) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(skin: skin);
      notifyListeners();
    }
  }
  
  /// Move character to position
  void moveCharacter(String characterId, CharacterPosition position) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(position: position);
      notifyListeners();
    }
  }
  
  /// Set character opacity
  void setOpacity(String characterId, double opacity) {
    final state = _displayStates[characterId];
    if (state != null) {
      _displayStates[characterId] = state.copyWith(opacity: opacity.clamp(0.0, 1.0));
      notifyListeners();
    }
  }
  
  /// Clear all characters
  void clearAll() {
    _displayStates.clear();
    notifyListeners();
  }
  
  /// Get character state
  CharacterDisplayState? getCharacterState(String characterId) {
    return _displayStates[characterId];
  }
}
