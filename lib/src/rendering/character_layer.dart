/// Character Layer for VN Runtime
///
/// Handles character sprite display with positions, expressions, and animations.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vn_node.dart';
import '../models/vn_character.dart';
import '../engine/vn_engine_state.dart';

/// Standard character slot positions on screen
enum CharacterSlotPosition {
  farLeft,
  left,
  center,
  right,
  farRight,
  custom,
}

/// Animation types for character enter/exit
enum CharacterAnimation {
  none,
  fade,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
}

/// Configuration for character display
class CharacterDisplayConfig {
  final String characterId;
  final String? expression;
  final CharacterSlotPosition position;
  final double? customX;
  final double? customY;
  final double scale;
  final bool flipped;
  final bool isSpeaking;
  final int layerOrder;

  const CharacterDisplayConfig({
    required this.characterId,
    this.expression,
    this.position = CharacterSlotPosition.center,
    this.customX,
    this.customY,
    this.scale = 1.0,
    this.flipped = false,
    this.isSpeaking = false,
    this.layerOrder = 0,
  });

  CharacterDisplayConfig copyWith({
    String? characterId,
    String? expression,
    CharacterSlotPosition? position,
    double? customX,
    double? customY,
    double? scale,
    bool? flipped,
    bool? isSpeaking,
    int? layerOrder,
  }) {
    return CharacterDisplayConfig(
      characterId: characterId ?? this.characterId,
      expression: expression ?? this.expression,
      position: position ?? this.position,
      customX: customX ?? this.customX,
      customY: customY ?? this.customY,
      scale: scale ?? this.scale,
      flipped: flipped ?? this.flipped,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      layerOrder: layerOrder ?? this.layerOrder,
    );
  }

  /// Get X position as fraction of screen width (0.0 - 1.0)
  double getXPosition() {
    if (position == CharacterSlotPosition.custom && customX != null) {
      return customX!;
    }
    
    switch (position) {
      case CharacterSlotPosition.farLeft:
        return 0.1;
      case CharacterSlotPosition.left:
        return 0.25;
      case CharacterSlotPosition.center:
        return 0.5;
      case CharacterSlotPosition.right:
        return 0.75;
      case CharacterSlotPosition.farRight:
        return 0.9;
      case CharacterSlotPosition.custom:
        return customX ?? 0.5;
    }
  }

  /// Get Y position as fraction of screen height (0.0 - 1.0)
  double getYPosition() {
    if (position == CharacterSlotPosition.custom && customY != null) {
      return customY!;
    }
    return 1.0; // Default: bottom of screen
  }
}

/// State for a character being displayed
class _CharacterState {
  final CharacterDisplayConfig config;
  final VNCharacter character;
  double opacity;
  Offset animationOffset;
  bool isEntering;
  bool isExiting;
  CharacterAnimation animation;

  _CharacterState({
    required this.config,
    required this.character,
    this.opacity = 1.0,
    this.animationOffset = Offset.zero,
    this.isEntering = false,
    this.isExiting = false,
    this.animation = CharacterAnimation.none,
  });
}

/// Controller for managing character display
class CharacterLayerController extends ChangeNotifier {
  final Map<String, _CharacterState> _characters = {};
  final Map<String, VNCharacter> _characterData;
  String? _speakingCharacterId;
  Timer? _animationTimer;
  final Duration animationDuration;

  CharacterLayerController({
    required Map<String, VNCharacter> characterData,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : _characterData = characterData;

  /// Get all displayed characters sorted by layer order
  List<_CharacterState> get displayedCharacters {
    final chars = _characters.values.toList();
    chars.sort((a, b) => a.config.layerOrder.compareTo(b.config.layerOrder));
    return chars;
  }

  /// Get the currently speaking character ID
  String? get speakingCharacterId => _speakingCharacterId;

  /// Show a character with optional animation
  Future<void> showCharacter(
    CharacterDisplayConfig config, {
    CharacterAnimation animation = CharacterAnimation.fade,
  }) async {
    final character = _characterData[config.characterId];
    if (character == null) return;

    final state = _CharacterState(
      config: config,
      character: character,
      opacity: animation == CharacterAnimation.none ? 1.0 : 0.0,
      animationOffset: _getInitialOffset(animation),
      isEntering: animation != CharacterAnimation.none,
      animation: animation,
    );

    _characters[config.characterId] = state;
    notifyListeners();

    if (animation != CharacterAnimation.none) {
      await _animateEnter(config.characterId);
    }
  }

  /// Hide a character with optional animation
  Future<void> hideCharacter(
    String characterId, {
    CharacterAnimation animation = CharacterAnimation.fade,
  }) async {
    final state = _characters[characterId];
    if (state == null) return;

    if (animation == CharacterAnimation.none) {
      _characters.remove(characterId);
      notifyListeners();
      return;
    }

    state.isExiting = true;
    state.animation = animation;
    notifyListeners();

    await _animateExit(characterId);
    _characters.remove(characterId);
    notifyListeners();
  }

  /// Update character expression
  void updateExpression(String characterId, String? expression) {
    final state = _characters[characterId];
    if (state == null) return;

    _characters[characterId] = _CharacterState(
      config: state.config.copyWith(expression: expression),
      character: state.character,
      opacity: state.opacity,
      animationOffset: state.animationOffset,
    );
    notifyListeners();
  }

  /// Update character position
  void updatePosition(String characterId, CharacterSlotPosition position, {
    double? customX,
    double? customY,
  }) {
    final state = _characters[characterId];
    if (state == null) return;

    _characters[characterId] = _CharacterState(
      config: state.config.copyWith(
        position: position,
        customX: customX,
        customY: customY,
      ),
      character: state.character,
      opacity: state.opacity,
      animationOffset: state.animationOffset,
    );
    notifyListeners();
  }

  /// Set the speaking character (highlights them)
  void setSpeakingCharacter(String? characterId) {
    _speakingCharacterId = characterId;
    notifyListeners();
  }

  /// Clear all characters
  void clearAll() {
    _characters.clear();
    _speakingCharacterId = null;
    notifyListeners();
  }

  /// Sync with VNEngineState.displayedCharacters
  /// This method converts engine state to CharacterDisplayConfig and updates the layer
  void syncWithEngineState(Map<String, CharacterDisplayState> displayedCharacters) {
    // Remove characters not in the new state
    final newIds = displayedCharacters.keys.toSet();
    _characters.removeWhere((id, _) => !newIds.contains(id));

    // Add or update characters
    for (final entry in displayedCharacters.entries) {
      final characterId = entry.key;
      final charState = entry.value;

      final character = _characterData[characterId];
      if (character == null) continue;

      // Convert slot string to CharacterSlotPosition
      final position = _parseSlotPosition(charState.slot);

      final config = CharacterDisplayConfig(
        characterId: characterId,
        expression: charState.expression,
        position: position,
        customX: charState.customX,
        customY: charState.customY,
        scale: charState.scale,
        flipped: charState.flipped,
        isSpeaking: charState.isSpeaking,
      );

      final existing = _characters[characterId];
      if (existing != null) {
        // Update existing character
        _characters[characterId] = _CharacterState(
          config: config,
          character: character,
          opacity: existing.opacity,
          animationOffset: existing.animationOffset,
        );
      } else {
        // Add new character
        _characters[characterId] = _CharacterState(
          config: config,
          character: character,
        );
      }
    }
    notifyListeners();
  }

  /// Parse slot string to CharacterSlotPosition
  CharacterSlotPosition _parseSlotPosition(String slot) {
    switch (slot) {
      case 'far_left':
        return CharacterSlotPosition.farLeft;
      case 'left':
        return CharacterSlotPosition.left;
      case 'center':
        return CharacterSlotPosition.center;
      case 'right':
        return CharacterSlotPosition.right;
      case 'far_right':
        return CharacterSlotPosition.farRight;
      case 'custom':
        return CharacterSlotPosition.custom;
      default:
        return CharacterSlotPosition.center;
    }
  }

  /// Update characters from scene data
  void updateFromScene(List<CharacterDisplayConfig> configs) {
    // Remove characters not in the new config
    final newIds = configs.map((c) => c.characterId).toSet();
    _characters.removeWhere((id, _) => !newIds.contains(id));

    // Add or update characters
    for (final config in configs) {
      final character = _characterData[config.characterId];
      if (character == null) continue;

      final existing = _characters[config.characterId];
      if (existing != null) {
        // Update existing character
        _characters[config.characterId] = _CharacterState(
          config: config,
          character: character,
          opacity: existing.opacity,
          animationOffset: existing.animationOffset,
        );
      } else {
        // Add new character
        _characters[config.characterId] = _CharacterState(
          config: config,
          character: character,
        );
      }
    }
    notifyListeners();
  }

  Offset _getInitialOffset(CharacterAnimation animation) {
    switch (animation) {
      case CharacterAnimation.slideLeft:
        return const Offset(-200, 0);
      case CharacterAnimation.slideRight:
        return const Offset(200, 0);
      case CharacterAnimation.slideUp:
        return const Offset(0, 200);
      case CharacterAnimation.slideDown:
        return const Offset(0, -200);
      default:
        return Offset.zero;
    }
  }

  Offset _getExitOffset(CharacterAnimation animation) {
    switch (animation) {
      case CharacterAnimation.slideLeft:
        return const Offset(-200, 0);
      case CharacterAnimation.slideRight:
        return const Offset(200, 0);
      case CharacterAnimation.slideUp:
        return const Offset(0, -200);
      case CharacterAnimation.slideDown:
        return const Offset(0, 200);
      default:
        return Offset.zero;
    }
  }

  Future<void> _animateEnter(String characterId) async {
    final completer = Completer<void>();
    final startTime = DateTime.now();
    final state = _characters[characterId];
    if (state == null) {
      completer.complete();
      return completer.future;
    }

    final initialOffset = state.animationOffset;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final currentState = _characters[characterId];
      if (currentState == null) {
        timer.cancel();
        completer.complete();
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / animationDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      final easedProgress = Curves.easeOut.transform(progress);

      currentState.opacity = easedProgress;
      currentState.animationOffset = Offset.lerp(
        initialOffset,
        Offset.zero,
        easedProgress,
      )!;
      notifyListeners();

      if (progress >= 1.0) {
        timer.cancel();
        currentState.isEntering = false;
        notifyListeners();
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> _animateExit(String characterId) async {
    final completer = Completer<void>();
    final startTime = DateTime.now();
    final state = _characters[characterId];
    if (state == null) {
      completer.complete();
      return completer.future;
    }

    final targetOffset = _getExitOffset(state.animation);

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final currentState = _characters[characterId];
      if (currentState == null) {
        timer.cancel();
        completer.complete();
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / animationDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      final easedProgress = Curves.easeIn.transform(progress);

      currentState.opacity = 1.0 - easedProgress;
      currentState.animationOffset = Offset.lerp(
        Offset.zero,
        targetOffset,
        easedProgress,
      )!;
      notifyListeners();

      if (progress >= 1.0) {
        timer.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }
}

/// Widget that displays all characters
class CharacterLayer extends StatelessWidget {
  final CharacterLayerController controller;
  final ImageProvider Function(String path)? imageProvider;
  final double dimOpacity;

  const CharacterLayer({
    super.key,
    required this.controller,
    this.imageProvider,
    this.dimOpacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: controller.displayedCharacters.map((state) {
                return _CharacterSprite(
                  state: state,
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                  imageProvider: imageProvider,
                  isSpeaking: state.config.characterId == controller.speakingCharacterId,
                  dimOpacity: dimOpacity,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

/// Individual character sprite widget
class _CharacterSprite extends StatelessWidget {
  final _CharacterState state;
  final double screenWidth;
  final double screenHeight;
  final ImageProvider Function(String path)? imageProvider;
  final bool isSpeaking;
  final double dimOpacity;

  const _CharacterSprite({
    required this.state,
    required this.screenWidth,
    required this.screenHeight,
    this.imageProvider,
    required this.isSpeaking,
    required this.dimOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    final character = state.character;
    
    // Get sprite path based on expression
    final spritePath = character.getSpriteForExpression(config.expression);
    
    // Calculate position
    final xPos = config.getXPosition() * screenWidth;
    final yPos = config.getYPosition() * screenHeight;
    
    // Calculate sprite dimensions (assuming standard VN sprite proportions)
    final baseHeight = screenHeight * 0.9;
    final scaledHeight = baseHeight * config.scale;
    final scaledWidth = scaledHeight * 0.5; // Approximate aspect ratio
    
    // Apply animation offset
    final finalX = xPos - (scaledWidth / 2) + state.animationOffset.dx;
    final finalY = yPos - scaledHeight + state.animationOffset.dy;

    Widget sprite = _buildSpriteImage(spritePath, scaledWidth, scaledHeight);

    // Apply flip if needed
    if (config.flipped) {
      sprite = Transform.scale(
        scaleX: -1,
        child: sprite,
      );
    }

    // Apply speaking highlight/dim effect
    final effectiveOpacity = state.opacity * (isSpeaking ? 1.0 : dimOpacity);

    return Positioned(
      left: finalX,
      top: finalY,
      child: Opacity(
        opacity: effectiveOpacity.clamp(0.0, 1.0),
        child: SizedBox(
          width: scaledWidth,
          height: scaledHeight,
          child: sprite,
        ),
      ),
    );
  }

  Widget _buildSpriteImage(String path, double width, double height) {
    if (imageProvider != null) {
      return Image(
        image: imageProvider!(path),
        fit: BoxFit.contain,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(width, height);
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(width, height);
      },
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            color: Colors.white54,
            size: width * 0.3,
          ),
          const SizedBox(height: 8),
          Text(
            state.character.displayName,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Extension to convert CharacterSlot to CharacterSlotPosition
extension CharacterSlotExtension on CharacterSlot {
  CharacterSlotPosition toPosition() {
    switch (this) {
      case CharacterSlot.farLeft:
        return CharacterSlotPosition.farLeft;
      case CharacterSlot.left:
        return CharacterSlotPosition.left;
      case CharacterSlot.center:
        return CharacterSlotPosition.center;
      case CharacterSlot.right:
        return CharacterSlotPosition.right;
      case CharacterSlot.farRight:
        return CharacterSlotPosition.farRight;
      case CharacterSlot.custom:
        return CharacterSlotPosition.custom;
    }
  }
}
