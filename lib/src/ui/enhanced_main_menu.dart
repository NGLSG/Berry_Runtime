/// Enhanced Main Menu with Video Background, Free Layout, and Meta Effects
/// 
/// Full-featured main menu supporting:
/// - Video/Image/Color backgrounds
/// - Free button positioning with drag support
/// - Meta effects (DDLC-style glitch, corruption, etc.)
/// - Particle effects
/// - Rich animations

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/vn_project.dart';
import '../../models/vn_theme.dart';
import '../effects/meta/meta_effects.dart';
import '../effects/particles/particle_layer.dart';
import 'video_background.dart';
import 'main_menu.dart';

/// Enhanced main menu with all commercial features
class EnhancedMainMenu extends StatefulWidget {
  final VNMainMenuConfig menuConfig;
  final VNTheme? theme;
  final bool canContinue;
  final bool showGallery;
  final Map<MainMenuAction, String>? customLabels;
  final void Function(MainMenuAction action)? onAction;
  final String? projectName;
  
  const EnhancedMainMenu({
    super.key,
    required this.menuConfig,
    this.theme,
    this.canContinue = false,
    this.showGallery = true,
    this.customLabels,
    this.onAction,
    this.projectName,
  });
  
  @override
  State<EnhancedMainMenu> createState() => _EnhancedMainMenuState();
}

class _EnhancedMainMenuState extends State<EnhancedMainMenu>
    with TickerProviderStateMixin {
  late MetaEffectController _metaController;
  late AnimationController _logoAnimController;
  late AnimationController _buttonAnimController;
  final List<AnimationController> _buttonControllers = [];
  
  @override
  void initState() {
    super.initState();
    _metaController = MetaEffectController();
    
    // Logo animation
    _logoAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.menuConfig.logoAnimationDuration),
    );
    
    // Button animation
    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start animations after delay
    Future.delayed(Duration(milliseconds: widget.menuConfig.logoAnimationDelay), () {
      if (mounted) _logoAnimController.forward();
    });
    
    Future.delayed(Duration(milliseconds: widget.menuConfig.logoAnimationDelay + 300), () {
      if (mounted) _buttonAnimController.forward();
    });
    
    // Start meta effects
    _metaController.start(widget.menuConfig);
  }
  
  @override
  void dispose() {
    _metaController.dispose();
    _logoAnimController.dispose();
    _buttonAnimController.dispose();
    for (final c in _buttonControllers) {
      c.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // Background layer
        _buildBackground(),
        
        // Background overlay
        if (widget.menuConfig.backgroundOverlayOpacity > 0)
          Container(
            color: Colors.black.withOpacity(widget.menuConfig.backgroundOverlayOpacity),
          ),
        
        // Particle layer
        if (widget.menuConfig.enableParticles)
          _buildParticleLayer(),
        
        // Logo
        if (widget.menuConfig.logoImage != null)
          _buildAnimatedLogo(),
        
        // Content (title + buttons)
        SafeArea(child: _buildContent()),
        
        // Version text
        _buildVersionText(),
      ],
    );
    
    // Wrap with meta effects if enabled
    if (widget.menuConfig.enableMetaEffects) {
      content = MetaEffectLayer(
        controller: _metaController,
        config: widget.menuConfig,
        child: content,
      );
    }
    
    return content;
  }
  
  Widget _buildBackground() {
    switch (widget.menuConfig.backgroundType) {
      case MenuBackgroundType.video:
        if (widget.menuConfig.backgroundVideo != null) {
          return VideoBackground.fromConfig(widget.menuConfig);
        }
        return _buildColorBackground();
        
      case MenuBackgroundType.image:
        if (widget.menuConfig.backgroundImage != null) {
          if (widget.menuConfig.backgroundAnimation != 'none') {
            return AnimatedBackground(
              imagePath: widget.menuConfig.backgroundImage!,
              animationType: widget.menuConfig.backgroundAnimation,
              animationSpeed: widget.menuConfig.backgroundAnimationSpeed,
            );
          }
          return Image.asset(
            widget.menuConfig.backgroundImage!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildColorBackground(),
          );
        }
        return _buildColorBackground();
        
      case MenuBackgroundType.color:
      default:
        return _buildColorBackground();
    }
  }
  
  Widget _buildColorBackground() {
    final bgColor = widget.theme?.backgroundColor ?? const Color(0xFF1A1A2E);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, bgColor.withOpacity(0.8)],
        ),
      ),
    );
  }
  
  Widget _buildParticleLayer() {
    // Use StandaloneParticleLayer with the configured preset
    final preset = widget.menuConfig.particlePreset;
    if (preset == null || preset.isEmpty) {
      return const SizedBox.shrink();
    }
    return StandaloneParticleLayer(
      initialPresets: [preset],
    );
  }
  
  Widget _buildAnimatedLogo() {
    final size = MediaQuery.of(context).size;
    
    Widget logo = Image.asset(
      widget.menuConfig.logoImage!,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
    
    // Apply animation
    switch (widget.menuConfig.logoAnimation) {
      case 'fadeIn':
        logo = FadeTransition(
          opacity: _logoAnimController,
          child: logo,
        );
        break;
      case 'scaleIn':
        logo = ScaleTransition(
          scale: CurvedAnimation(
            parent: _logoAnimController,
            curve: Curves.elasticOut,
          ),
          child: logo,
        );
        break;
      case 'slideIn':
        logo = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _logoAnimController,
            curve: Curves.easeOutBack,
          )),
          child: logo,
        );
        break;
      case 'pulse':
        logo = AnimatedBuilder(
          animation: _logoAnimController,
          builder: (context, child) {
            final scale = 1.0 + sin(_logoAnimController.value * pi * 2) * 0.05;
            return Transform.scale(scale: scale, child: child);
          },
          child: logo,
        );
        _logoAnimController.repeat();
        break;
      case 'float':
        logo = AnimatedBuilder(
          animation: _logoAnimController,
          builder: (context, child) {
            final offset = sin(_logoAnimController.value * pi * 2) * 10;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: logo,
        );
        _logoAnimController.repeat();
        break;
    }
    
    return Positioned(
      left: size.width * widget.menuConfig.logoX - 100 * widget.menuConfig.logoScale,
      top: size.height * widget.menuConfig.logoY - 100 * widget.menuConfig.logoScale,
      child: Transform.scale(
        scale: widget.menuConfig.logoScale,
        child: logo,
      ),
    );
  }
  
  Widget _buildContent() {
    if (widget.menuConfig.buttonLayout == 'free') {
      return _buildFreeLayoutContent();
    }
    return _buildStandardContent();
  }
  
  Widget _buildStandardContent() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: _getCrossAxisAlignment(),
        children: [
          // Title
          if (widget.menuConfig.titleText != null || widget.projectName != null) ...[
            _buildTitle(),
            const Spacer(),
          ] else
            const Spacer(),
          
          // Menu buttons with animation
          _buildAnimatedButtons(),
          
          const Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildFreeLayoutContent() {
    final size = MediaQuery.of(context).size;
    final buttons = _getButtonList();
    final positions = Map<String, MenuButtonPosition>.fromEntries(
      widget.menuConfig.buttonPositions.map((p) => MapEntry(p.buttonId, p)),
    );
    
    return Stack(
      children: [
        // Title
        if (widget.menuConfig.titleText != null || widget.projectName != null)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(child: _buildTitle()),
          ),
        
        // Free positioned buttons
        ...buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          final buttonId = _getButtonId(button.action);
          
          // Get position or use default
          final pos = positions[buttonId] ?? MenuButtonPosition(
            buttonId: buttonId,
            x: 0.5,
            y: 0.35 + index * 0.1,
          );
          
          return Positioned(
            left: pos.x * size.width - widget.menuConfig.buttonWidth / 2,
            top: pos.y * size.height - 24,
            child: Transform.rotate(
              angle: (pos.rotation ?? 0) * pi / 180,
              child: Transform.scale(
                scale: pos.scale ?? 1.0,
                child: _buildButton(button, index),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  String _getButtonId(MainMenuAction action) {
    return {
      MainMenuAction.newGame: 'newGame',
      MainMenuAction.continueGame: 'continue',
      MainMenuAction.load: 'load',
      MainMenuAction.gallery: 'gallery',
      MainMenuAction.settings: 'settings',
      MainMenuAction.exit: 'exit',
    }[action] ?? action.name;
  }
  
  Widget _buildTitle() {
    final title = widget.menuConfig.titleText ?? widget.projectName ?? '';
    final baseStyle = Theme.of(context).textTheme.headlineLarge;
    final style = baseStyle?.copyWith(
      color: widget.theme?.textColor ?? Colors.white,
      fontSize: 48,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    ) ?? TextStyle(
      color: widget.theme?.textColor ?? Colors.white,
      fontSize: 48,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );
    
    // Apply text scramble if meta effect is active
    if (widget.menuConfig.enableMetaEffects &&
        widget.menuConfig.metaEffectType == MetaEffectType.textScramble) {
      return ScrambleText(
        text: title,
        style: style,
        isActive: _metaController.isActive,
        intensity: widget.menuConfig.metaEffectIntensity,
      );
    }
    
    return Text(title, style: style);
  }
  
  Widget _buildAnimatedButtons() {
    final buttons = _getButtonList();
    
    return AnimatedBuilder(
      animation: _buttonAnimController,
      builder: (context, _) {
        final children = <Widget>[];
        
        for (var i = 0; i < buttons.length; i++) {
          // Stagger animation
          double opacity = 1.0;
          double slideOffset = 0.0;
          
          if (widget.menuConfig.buttonAnimation == 'stagger') {
            final staggerDelay = widget.menuConfig.buttonStaggerDelay / 1000;
            final buttonProgress = (_buttonAnimController.value - i * staggerDelay * 0.1)
                .clamp(0.0, 1.0);
            opacity = buttonProgress;
            slideOffset = (1 - buttonProgress) * 30;
          } else if (widget.menuConfig.buttonAnimation == 'fadeIn') {
            opacity = _buttonAnimController.value;
          } else if (widget.menuConfig.buttonAnimation == 'slideIn') {
            slideOffset = (1 - _buttonAnimController.value) * 50;
          }
          
          children.add(
            Transform.translate(
              offset: Offset(slideOffset, 0),
              child: Opacity(
                opacity: opacity,
                child: _buildButton(buttons[i], i),
              ),
            ),
          );
          
          if (i < buttons.length - 1) {
            children.add(SizedBox(
              width: widget.menuConfig.buttonLayout == 'horizontal' 
                  ? widget.menuConfig.buttonSpacing : 0,
              height: widget.menuConfig.buttonLayout == 'vertical' 
                  ? widget.menuConfig.buttonSpacing : 0,
            ));
          }
        }
        
        if (widget.menuConfig.buttonLayout == 'horizontal') {
          return Row(mainAxisSize: MainAxisSize.min, children: children);
        }
        return Column(mainAxisSize: MainAxisSize.min, children: children);
      },
    );
  }
  
  List<_ButtonData> _getButtonList() {
    final buttons = <_ButtonData>[];
    final labels = widget.customLabels ?? const {};
    
    buttons.add(_ButtonData(
      action: MainMenuAction.newGame,
      label: labels[MainMenuAction.newGame] ?? '开始游戏',
    ));
    
    if (widget.canContinue) {
      buttons.add(_ButtonData(
        action: MainMenuAction.continueGame,
        label: labels[MainMenuAction.continueGame] ?? '继续游戏',
      ));
    }
    
    buttons.add(_ButtonData(
      action: MainMenuAction.load,
      label: labels[MainMenuAction.load] ?? '读取存档',
    ));
    
    if (widget.showGallery) {
      buttons.add(_ButtonData(
        action: MainMenuAction.gallery,
        label: labels[MainMenuAction.gallery] ?? '额外内容',
      ));
    }
    
    buttons.add(_ButtonData(
      action: MainMenuAction.settings,
      label: labels[MainMenuAction.settings] ?? '游戏设置',
    ));
    
    buttons.add(_ButtonData(
      action: MainMenuAction.exit,
      label: labels[MainMenuAction.exit] ?? '退出游戏',
    ));
    
    return buttons;
  }
  
  Widget _buildButton(_ButtonData data, int index) {
    return _EnhancedMenuButton(
      label: data.label,
      width: widget.menuConfig.buttonWidth,
      borderRadius: widget.menuConfig.buttonBorderRadius,
      backgroundColor: widget.theme?.dialogueBoxColor.withOpacity(0.6) ?? 
          const Color(0x66FFFFFF),
      hoverColor: widget.theme?.dialogueBoxColor.withOpacity(0.8) ?? 
          const Color(0x99FFFFFF),
      textColor: widget.theme?.textColor ?? Colors.white,
      enableShadow: widget.menuConfig.enableButtonShadow,
      buttonImage: widget.menuConfig.buttonImage,
      buttonHoverImage: widget.menuConfig.buttonHoverImage,
      onTap: () => widget.onAction?.call(data.action),
      onHover: widget.menuConfig.metaEffectTrigger == 'onHover'
          ? (isHovered) {
              if (isHovered) {
                _metaController.triggerOnHover(widget.menuConfig.metaEffectType);
              } else {
                _metaController.stopEffect();
              }
            }
          : null,
    );
  }
  
  Widget _buildVersionText() {
    if (!widget.menuConfig.versionPosition.isNotEmpty) return const SizedBox();
    
    Alignment alignment;
    switch (widget.menuConfig.versionPosition) {
      case 'bottomLeft':
        alignment = Alignment.bottomLeft;
        break;
      case 'topLeft':
        alignment = Alignment.topLeft;
        break;
      case 'topRight':
        alignment = Alignment.topRight;
        break;
      default:
        alignment = Alignment.bottomRight;
    }
    
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'v1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
  
  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (widget.menuConfig.alignment) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'right':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }
}

class _ButtonData {
  final MainMenuAction action;
  final String label;
  
  const _ButtonData({required this.action, required this.label});
}

/// Enhanced menu button with custom image support
class _EnhancedMenuButton extends StatefulWidget {
  final String label;
  final double width;
  final double borderRadius;
  final Color backgroundColor;
  final Color hoverColor;
  final Color textColor;
  final bool enableShadow;
  final String? buttonImage;
  final String? buttonHoverImage;
  final VoidCallback onTap;
  final void Function(bool)? onHover;
  
  const _EnhancedMenuButton({
    required this.label,
    required this.width,
    required this.borderRadius,
    required this.backgroundColor,
    required this.hoverColor,
    required this.textColor,
    required this.enableShadow,
    this.buttonImage,
    this.buttonHoverImage,
    required this.onTap,
    this.onHover,
  });
  
  @override
  State<_EnhancedMenuButton> createState() => _EnhancedMenuButtonState();
}

class _EnhancedMenuButtonState extends State<_EnhancedMenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    // Use custom image if provided
    if (widget.buttonImage != null) {
      return _buildImageButton();
    }
    
    return _buildStandardButton();
  }
  
  Widget _buildImageButton() {
    final imagePath = _isHovered && widget.buttonHoverImage != null
        ? widget.buttonHoverImage!
        : widget.buttonImage!;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover?.call(false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.fill,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: widget.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStandardButton() {
    Color backgroundColor;
    if (_isPressed) {
      backgroundColor = widget.hoverColor;
    } else if (_isHovered) {
      backgroundColor = widget.hoverColor.withOpacity(0.8);
    } else {
      backgroundColor = widget.backgroundColor;
    }
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover?.call(false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isHovered
                  ? widget.textColor.withOpacity(0.5)
                  : Colors.transparent,
            ),
            boxShadow: widget.enableShadow
                ? [
                    BoxShadow(
                      color: const Color(0x40000000),
                      blurRadius: _isHovered ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
