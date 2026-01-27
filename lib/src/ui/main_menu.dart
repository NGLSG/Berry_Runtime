/// Main Menu Widget
/// 
/// Provides the main menu for visual novels with options:
/// New Game, Continue, Load, Gallery, Settings, Exit
/// 
/// Supports:
/// - Image/Video/Color backgrounds
/// - Free button positioning
/// - Meta effects (DDLC-style)
/// - Particle effects
/// - Animations

import 'package:flutter/material.dart';
import '../models/vn_project.dart';
import '../localization/vn_ui_strings.dart';

/// Main menu action types
enum MainMenuAction {
  newGame,
  continueGame,
  load,
  gallery,
  settings,
  exit,
}

/// Configuration for the main menu
class MainMenuConfig {
  /// Background color/gradient
  final Color backgroundColor;
  
  /// Background image path (optional)
  final String? backgroundImage;
  
  /// Logo/CG image path (optional)
  final String? logoImage;
  
  /// Logo position (relative, 0.0-1.0)
  final Offset logoPosition;
  
  /// Logo scale
  final double logoScale;
  
  /// Title text
  final String? title;
  
  /// Title text style
  final TextStyle? titleStyle;
  
  /// Title position (relative, 0.0-1.0)
  final Offset? titlePosition;
  
  /// Button background color
  final Color buttonBackgroundColor;
  
  /// Button hover color
  final Color buttonHoverColor;
  
  /// Button text color
  final Color buttonTextColor;
  
  /// Button font size
  final double buttonFontSize;
  
  /// Button padding
  final EdgeInsets buttonPadding;
  
  /// Button spacing
  final double buttonSpacing;
  
  /// Button width
  final double buttonWidth;
  
  /// Button border radius
  final double buttonBorderRadius;
  
  /// Button border color
  final Color buttonBorderColor;
  
  /// Button border width
  final double buttonBorderWidth;
  
  /// Menu alignment
  final MainMenuAlignment alignment;
  
  /// Menu position offset (relative, 0.0-1.0)
  final Offset? menuPosition;
  
  /// Button layout direction
  final Axis buttonLayout;
  
  /// Whether to show version text
  final bool showVersion;
  
  /// Version text
  final String? versionText;
  
  /// Version text position
  final Alignment versionAlignment;
  
  /// Custom button image path (9-patch style)
  final String? buttonImage;
  
  /// Custom button hover image path
  final String? buttonHoverImage;
  
  /// Enable button shadow
  final bool enableButtonShadow;
  
  /// Button shadow color
  final Color buttonShadowColor;
  
  /// Background overlay color (for dimming)
  final Color? backgroundOverlay;
  
  /// Free layout button positions
  final List<MenuButtonPosition>? freeButtonPositions;

  const MainMenuConfig({
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.backgroundImage,
    this.logoImage,
    this.logoPosition = const Offset(0.5, 0.2),
    this.logoScale = 1.0,
    this.title,
    this.titleStyle,
    this.titlePosition,
    this.buttonBackgroundColor = const Color(0x66FFFFFF),
    this.buttonHoverColor = const Color(0x99FFFFFF),
    this.buttonTextColor = Colors.white,
    this.buttonFontSize = 20.0,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
    this.buttonSpacing = 16.0,
    this.buttonWidth = 280.0,
    this.buttonBorderRadius = 8.0,
    this.buttonBorderColor = Colors.transparent,
    this.buttonBorderWidth = 0.0,
    this.alignment = MainMenuAlignment.center,
    this.menuPosition,
    this.buttonLayout = Axis.vertical,
    this.showVersion = true,
    this.versionText,
    this.versionAlignment = Alignment.bottomRight,
    this.buttonImage,
    this.buttonHoverImage,
    this.enableButtonShadow = false,
    this.buttonShadowColor = const Color(0x40000000),
    this.backgroundOverlay,
    this.freeButtonPositions,
  });

  MainMenuConfig copyWith({
    Color? backgroundColor,
    String? backgroundImage,
    String? logoImage,
    Offset? logoPosition,
    double? logoScale,
    String? title,
    TextStyle? titleStyle,
    Offset? titlePosition,
    Color? buttonBackgroundColor,
    Color? buttonHoverColor,
    Color? buttonTextColor,
    double? buttonFontSize,
    EdgeInsets? buttonPadding,
    double? buttonSpacing,
    double? buttonWidth,
    double? buttonBorderRadius,
    Color? buttonBorderColor,
    double? buttonBorderWidth,
    MainMenuAlignment? alignment,
    Offset? menuPosition,
    Axis? buttonLayout,
    bool? showVersion,
    String? versionText,
    Alignment? versionAlignment,
    String? buttonImage,
    String? buttonHoverImage,
    bool? enableButtonShadow,
    Color? buttonShadowColor,
    Color? backgroundOverlay,
    List<MenuButtonPosition>? freeButtonPositions,
  }) {
    return MainMenuConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      logoImage: logoImage ?? this.logoImage,
      logoPosition: logoPosition ?? this.logoPosition,
      logoScale: logoScale ?? this.logoScale,
      title: title ?? this.title,
      titleStyle: titleStyle ?? this.titleStyle,
      titlePosition: titlePosition ?? this.titlePosition,
      buttonBackgroundColor: buttonBackgroundColor ?? this.buttonBackgroundColor,
      buttonHoverColor: buttonHoverColor ?? this.buttonHoverColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      buttonFontSize: buttonFontSize ?? this.buttonFontSize,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      buttonWidth: buttonWidth ?? this.buttonWidth,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonBorderColor: buttonBorderColor ?? this.buttonBorderColor,
      buttonBorderWidth: buttonBorderWidth ?? this.buttonBorderWidth,
      alignment: alignment ?? this.alignment,
      menuPosition: menuPosition ?? this.menuPosition,
      buttonLayout: buttonLayout ?? this.buttonLayout,
      showVersion: showVersion ?? this.showVersion,
      versionText: versionText ?? this.versionText,
      versionAlignment: versionAlignment ?? this.versionAlignment,
      buttonImage: buttonImage ?? this.buttonImage,
      buttonHoverImage: buttonHoverImage ?? this.buttonHoverImage,
      enableButtonShadow: enableButtonShadow ?? this.enableButtonShadow,
      buttonShadowColor: buttonShadowColor ?? this.buttonShadowColor,
      backgroundOverlay: backgroundOverlay ?? this.backgroundOverlay,
      freeButtonPositions: freeButtonPositions ?? this.freeButtonPositions,
    );
  }
}

/// Menu alignment options
enum MainMenuAlignment {
  left,
  center,
  right,
}

/// Main menu widget
class MainMenu extends StatelessWidget {
  /// Whether continue is available (has save data)
  final bool canContinue;
  
  /// Whether gallery is available
  final bool showGallery;
  
  /// Callback when an action is triggered
  final void Function(MainMenuAction action)? onAction;
  
  /// Configuration
  final MainMenuConfig config;
  
  /// Custom labels for buttons
  final Map<MainMenuAction, String>? customLabels;
  
  /// Custom background widget
  final Widget? backgroundWidget;
  
  /// Custom title widget
  final Widget? titleWidget;
  
  /// Language code for localization
  final String languageCode;

  const MainMenu({
    super.key,
    this.canContinue = false,
    this.showGallery = true,
    this.onAction,
    this.config = const MainMenuConfig(),
    this.customLabels,
    this.backgroundWidget,
    this.titleWidget,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _buildBackground(),
        
        // Background overlay
        if (config.backgroundOverlay != null)
          Container(color: config.backgroundOverlay),
        
        // Logo/CG image
        if (config.logoImage != null)
          _buildLogo(context),
        
        // Content
        SafeArea(
          child: _buildContent(context),
        ),
        
        // Version text
        if (config.showVersion && config.versionText != null)
          Positioned.fill(
            child: Align(
              alignment: config.versionAlignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  config.versionText!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width * config.logoPosition.dx - 100 * config.logoScale,
      top: size.height * config.logoPosition.dy - 100 * config.logoScale,
      child: Transform.scale(
        scale: config.logoScale,
        child: Image.asset(
          config.logoImage!,
          errorBuilder: (context, error, stackTrace) => const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (backgroundWidget != null) {
      return backgroundWidget!;
    }
    
    if (config.backgroundImage != null) {
      return Image.asset(
        config.backgroundImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: config.backgroundColor);
        },
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            config.backgroundColor,
            config.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final alignment = _getAlignment();
    
    // If custom menu position is set, use positioned layout
    if (config.menuPosition != null) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          // Title at custom position or default
          if (titleWidget != null || config.title != null)
            Positioned(
              left: config.titlePosition != null 
                  ? size.width * config.titlePosition!.dx - 200
                  : null,
              top: config.titlePosition != null 
                  ? size.height * config.titlePosition!.dy
                  : 48,
              right: config.titlePosition == null ? null : null,
              child: config.titlePosition == null
                  ? Center(child: _buildTitle())
                  : _buildTitle(),
            ),
          
          // Menu buttons at custom position
          Positioned(
            left: size.width * config.menuPosition!.dx - config.buttonWidth / 2,
            top: size.height * config.menuPosition!.dy,
            child: _buildMenuButtons(),
          ),
        ],
      );
    }
    
    // Default layout
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: _getCrossAxisAlignment(),
        children: [
          // Title
          if (titleWidget != null || config.title != null) ...[
            _buildTitle(),
            const Spacer(),
          ] else
            const Spacer(),
          
          // Menu buttons
          _buildMenuButtons(),
          
          const Spacer(),
        ],
      ),
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (config.alignment) {
      case MainMenuAlignment.left:
        return CrossAxisAlignment.start;
      case MainMenuAlignment.center:
        return CrossAxisAlignment.center;
      case MainMenuAlignment.right:
        return CrossAxisAlignment.end;
    }
  }

  Alignment _getAlignment() {
    switch (config.alignment) {
      case MainMenuAlignment.left:
        return Alignment.centerLeft;
      case MainMenuAlignment.center:
        return Alignment.center;
      case MainMenuAlignment.right:
        return Alignment.centerRight;
    }
  }

  Widget _buildTitle() {
    if (titleWidget != null) {
      return titleWidget!;
    }
    
    return Text(
      config.title ?? '',
      style: config.titleStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildMenuButtons() {
    final buttons = <Widget>[];
    
    // New Game
    buttons.add(_MainMenuButton(
      label: customLabels?[MainMenuAction.newGame] ?? VNUILocalizer.get('newGame', languageCode),
      config: config,
      onTap: () => onAction?.call(MainMenuAction.newGame),
    ));
    
    // Continue (if available)
    if (canContinue) {
      buttons.add(SizedBox(
        width: config.buttonLayout == Axis.horizontal ? config.buttonSpacing : 0,
        height: config.buttonLayout == Axis.vertical ? config.buttonSpacing : 0,
      ));
      buttons.add(_MainMenuButton(
        label: customLabels?[MainMenuAction.continueGame] ?? VNUILocalizer.get('continueGame', languageCode),
        config: config,
        onTap: () => onAction?.call(MainMenuAction.continueGame),
      ));
    }
    
    // Load
    buttons.add(SizedBox(
      width: config.buttonLayout == Axis.horizontal ? config.buttonSpacing : 0,
      height: config.buttonLayout == Axis.vertical ? config.buttonSpacing : 0,
    ));
    buttons.add(_MainMenuButton(
      label: customLabels?[MainMenuAction.load] ?? VNUILocalizer.get('load', languageCode),
      config: config,
      onTap: () => onAction?.call(MainMenuAction.load),
    ));
    
    // Gallery (if enabled)
    if (showGallery) {
      buttons.add(SizedBox(
        width: config.buttonLayout == Axis.horizontal ? config.buttonSpacing : 0,
        height: config.buttonLayout == Axis.vertical ? config.buttonSpacing : 0,
      ));
      buttons.add(_MainMenuButton(
        label: customLabels?[MainMenuAction.gallery] ?? VNUILocalizer.get('gallery', languageCode),
        config: config,
        onTap: () => onAction?.call(MainMenuAction.gallery),
      ));
    }
    
    // Settings
    buttons.add(SizedBox(
      width: config.buttonLayout == Axis.horizontal ? config.buttonSpacing : 0,
      height: config.buttonLayout == Axis.vertical ? config.buttonSpacing : 0,
    ));
    buttons.add(_MainMenuButton(
      label: customLabels?[MainMenuAction.settings] ?? VNUILocalizer.get('settings', languageCode),
      config: config,
      onTap: () => onAction?.call(MainMenuAction.settings),
    ));
    
    // Exit
    buttons.add(SizedBox(
      width: config.buttonLayout == Axis.horizontal ? config.buttonSpacing : 0,
      height: config.buttonLayout == Axis.vertical ? config.buttonSpacing : 0,
    ));
    buttons.add(_MainMenuButton(
      label: customLabels?[MainMenuAction.exit] ?? VNUILocalizer.get('exit', languageCode),
      config: config,
      onTap: () => onAction?.call(MainMenuAction.exit),
    ));
    
    if (config.buttonLayout == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}

/// Individual main menu button
class _MainMenuButton extends StatefulWidget {
  final String label;
  final MainMenuConfig config;
  final VoidCallback onTap;
  final bool isEnabled;

  const _MainMenuButton({
    required this.label,
    required this.config,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  State<_MainMenuButton> createState() => _MainMenuButtonState();
}

class _MainMenuButtonState extends State<_MainMenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled;
    
    Color backgroundColor;
    if (!isEnabled) {
      backgroundColor = widget.config.buttonBackgroundColor.withOpacity(0.3);
    } else if (_isPressed) {
      backgroundColor = widget.config.buttonHoverColor;
    } else if (_isHovered) {
      backgroundColor = widget.config.buttonHoverColor.withOpacity(0.8);
    } else {
      backgroundColor = widget.config.buttonBackgroundColor;
    }
    
    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.config.buttonWidth,
          padding: widget.config.buttonPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.config.buttonBorderRadius),
            border: Border.all(
              color: _isHovered && isEnabled
                  ? (widget.config.buttonBorderWidth > 0 
                      ? widget.config.buttonBorderColor 
                      : widget.config.buttonTextColor.withOpacity(0.5))
                  : (widget.config.buttonBorderWidth > 0 
                      ? widget.config.buttonBorderColor.withOpacity(0.5)
                      : Colors.transparent),
              width: widget.config.buttonBorderWidth > 0 
                  ? widget.config.buttonBorderWidth 
                  : 1,
            ),
            boxShadow: widget.config.enableButtonShadow && isEnabled
                ? [
                    BoxShadow(
                      color: widget.config.buttonShadowColor,
                      blurRadius: _isHovered ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled
                  ? widget.config.buttonTextColor
                  : widget.config.buttonTextColor.withOpacity(0.5),
              fontSize: widget.config.buttonFontSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pause menu (in-game menu)
class PauseMenu extends StatelessWidget {
  /// Callback when an action is triggered
  final void Function(PauseMenuAction action)? onAction;
  
  /// Configuration (reuses MainMenuConfig)
  final MainMenuConfig config;
  
  /// Custom labels
  final Map<PauseMenuAction, String>? customLabels;
  
  /// Language code for localization
  final String languageCode;

  const PauseMenu({
    super.key,
    this.onAction,
    this.config = const MainMenuConfig(),
    this.customLabels,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                VNUILocalizer.get('paused', languageCode),
                style: TextStyle(
                  color: config.buttonTextColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildButton(
                customLabels?[PauseMenuAction.resume] ?? VNUILocalizer.get('resume', languageCode),
                () => onAction?.call(PauseMenuAction.resume),
              ),
              SizedBox(height: config.buttonSpacing),
              _buildButton(
                customLabels?[PauseMenuAction.save] ?? VNUILocalizer.get('save', languageCode),
                () => onAction?.call(PauseMenuAction.save),
              ),
              SizedBox(height: config.buttonSpacing),
              _buildButton(
                customLabels?[PauseMenuAction.load] ?? VNUILocalizer.get('load', languageCode),
                () => onAction?.call(PauseMenuAction.load),
              ),
              SizedBox(height: config.buttonSpacing),
              _buildButton(
                customLabels?[PauseMenuAction.settings] ?? VNUILocalizer.get('settings', languageCode),
                () => onAction?.call(PauseMenuAction.settings),
              ),
              SizedBox(height: config.buttonSpacing),
              _buildButton(
                customLabels?[PauseMenuAction.mainMenu] ?? VNUILocalizer.get('mainMenu', languageCode),
                () => onAction?.call(PauseMenuAction.mainMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return _MainMenuButton(
      label: label,
      config: config,
      onTap: onTap,
    );
  }
}

/// Pause menu action types
enum PauseMenuAction {
  resume,
  save,
  load,
  settings,
  mainMenu,
}
