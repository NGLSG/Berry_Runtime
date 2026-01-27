/// Quick Menu Widget
/// 
/// Provides quick access buttons for common VN actions:
/// Auto, Skip, Log, Save, Load, Config

import 'package:flutter/material.dart';
import '../localization/vn_ui_strings.dart';

/// Quick menu action types
enum QuickMenuAction {
  auto,
  skip,
  log,
  save,
  load,
  config,
  hide,
}

/// Configuration for the quick menu
class QuickMenuConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Button color
  final Color buttonColor;
  
  /// Button hover color
  final Color buttonHoverColor;
  
  /// Active button color (for Auto/Skip when enabled)
  final Color activeButtonColor;
  
  /// Text color
  final Color textColor;
  
  /// Active text color
  final Color activeTextColor;
  
  /// Font size
  final double fontSize;
  
  /// Icon size
  final double iconSize;
  
  /// Button padding
  final EdgeInsets buttonPadding;
  
  /// Spacing between buttons
  final double buttonSpacing;
  
  /// Whether to show icons
  final bool showIcons;
  
  /// Whether to show labels
  final bool showLabels;
  
  /// Menu position
  final QuickMenuPosition position;
  
  /// Menu orientation
  final Axis orientation;

  const QuickMenuConfig({
    this.backgroundColor = const Color(0x99000000),
    this.buttonColor = Colors.transparent,
    this.buttonHoverColor = const Color(0x33FFFFFF),
    this.activeButtonColor = const Color(0x66FFFFFF),
    this.textColor = const Color(0xCCFFFFFF),
    this.activeTextColor = Colors.white,
    this.fontSize = 14.0,
    this.iconSize = 20.0,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.buttonSpacing = 4.0,
    this.showIcons = true,
    this.showLabels = true,
    this.position = QuickMenuPosition.bottomRight,
    this.orientation = Axis.horizontal,
  });

  QuickMenuConfig copyWith({
    Color? backgroundColor,
    Color? buttonColor,
    Color? buttonHoverColor,
    Color? activeButtonColor,
    Color? textColor,
    Color? activeTextColor,
    double? fontSize,
    double? iconSize,
    EdgeInsets? buttonPadding,
    double? buttonSpacing,
    bool? showIcons,
    bool? showLabels,
    QuickMenuPosition? position,
    Axis? orientation,
  }) {
    return QuickMenuConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonHoverColor: buttonHoverColor ?? this.buttonHoverColor,
      activeButtonColor: activeButtonColor ?? this.activeButtonColor,
      textColor: textColor ?? this.textColor,
      activeTextColor: activeTextColor ?? this.activeTextColor,
      fontSize: fontSize ?? this.fontSize,
      iconSize: iconSize ?? this.iconSize,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      showIcons: showIcons ?? this.showIcons,
      showLabels: showLabels ?? this.showLabels,
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
    );
  }
}

/// Quick menu position
enum QuickMenuPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter,
}

/// Quick menu widget
class QuickMenu extends StatelessWidget {
  /// Whether auto mode is active
  final bool isAutoMode;
  
  /// Whether skip mode is active
  final bool isSkipMode;
  
  /// Callback when an action is triggered
  final void Function(QuickMenuAction action)? onAction;
  
  /// Configuration
  final QuickMenuConfig config;
  
  /// Custom labels for buttons
  final Map<QuickMenuAction, String>? customLabels;
  
  /// Which buttons to show
  final Set<QuickMenuAction> visibleActions;
  
  /// Whether the menu is visible
  final bool isVisible;
  
  /// Language code for localization
  final String languageCode;

  const QuickMenu({
    super.key,
    this.isAutoMode = false,
    this.isSkipMode = false,
    this.onAction,
    this.config = const QuickMenuConfig(),
    this.customLabels,
    this.visibleActions = const {
      QuickMenuAction.auto,
      QuickMenuAction.skip,
      QuickMenuAction.log,
      QuickMenuAction.save,
      QuickMenuAction.load,
      QuickMenuAction.config,
    },
    this.isVisible = true,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    final menuWidget = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: config.orientation == Axis.horizontal
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildButtons(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildButtons(),
            ),
    );
    
    return _positionWidget(menuWidget);
  }

  Widget _positionWidget(Widget child) {
    switch (config.position) {
      case QuickMenuPosition.topLeft:
        return Positioned(
          top: 16,
          left: 16,
          child: child,
        );
      case QuickMenuPosition.topRight:
        return Positioned(
          top: 16,
          right: 16,
          child: child,
        );
      case QuickMenuPosition.bottomLeft:
        return Positioned(
          bottom: 16,
          left: 16,
          child: child,
        );
      case QuickMenuPosition.bottomRight:
        return Positioned(
          bottom: 16,
          right: 16,
          child: child,
        );
      case QuickMenuPosition.topCenter:
        return Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case QuickMenuPosition.bottomCenter:
        return Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
    }
  }

  List<Widget> _buildButtons() {
    final buttons = <Widget>[];
    final actions = [
      QuickMenuAction.auto,
      QuickMenuAction.skip,
      QuickMenuAction.log,
      QuickMenuAction.save,
      QuickMenuAction.load,
      QuickMenuAction.config,
    ];
    
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      if (!visibleActions.contains(action)) continue;
      
      if (buttons.isNotEmpty) {
        buttons.add(SizedBox(
          width: config.orientation == Axis.horizontal ? config.buttonSpacing : 0,
          height: config.orientation == Axis.vertical ? config.buttonSpacing : 0,
        ));
      }
      
      buttons.add(_QuickMenuButton(
        action: action,
        isActive: _isActionActive(action),
        label: customLabels?[action] ?? _getDefaultLabel(action),
        icon: _getIcon(action),
        config: config,
        onTap: () => onAction?.call(action),
      ));
    }
    
    return buttons;
  }

  bool _isActionActive(QuickMenuAction action) {
    switch (action) {
      case QuickMenuAction.auto:
        return isAutoMode;
      case QuickMenuAction.skip:
        return isSkipMode;
      default:
        return false;
    }
  }

  String _getDefaultLabel(QuickMenuAction action) {
    switch (action) {
      case QuickMenuAction.auto:
        return VNUILocalizer.get('auto', languageCode);
      case QuickMenuAction.skip:
        return VNUILocalizer.get('skip', languageCode);
      case QuickMenuAction.log:
        return VNUILocalizer.get('log', languageCode);
      case QuickMenuAction.save:
        return VNUILocalizer.get('save', languageCode);
      case QuickMenuAction.load:
        return VNUILocalizer.get('load', languageCode);
      case QuickMenuAction.config:
        return VNUILocalizer.get('config', languageCode);
      case QuickMenuAction.hide:
        return VNUILocalizer.get('hide', languageCode);
    }
  }

  IconData _getIcon(QuickMenuAction action) {
    switch (action) {
      case QuickMenuAction.auto:
        return Icons.play_circle_outline;
      case QuickMenuAction.skip:
        return Icons.fast_forward;
      case QuickMenuAction.log:
        return Icons.history;
      case QuickMenuAction.save:
        return Icons.save;
      case QuickMenuAction.load:
        return Icons.folder_open;
      case QuickMenuAction.config:
        return Icons.settings;
      case QuickMenuAction.hide:
        return Icons.visibility_off;
    }
  }
}

/// Individual quick menu button
class _QuickMenuButton extends StatefulWidget {
  final QuickMenuAction action;
  final bool isActive;
  final String label;
  final IconData icon;
  final QuickMenuConfig config;
  final VoidCallback onTap;

  const _QuickMenuButton({
    required this.action,
    required this.isActive,
    required this.label,
    required this.icon,
    required this.config,
    required this.onTap,
  });

  @override
  State<_QuickMenuButton> createState() => _QuickMenuButtonState();
}

class _QuickMenuButtonState extends State<_QuickMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    
    Color backgroundColor;
    if (isActive) {
      backgroundColor = widget.config.activeButtonColor;
    } else if (_isHovered) {
      backgroundColor = widget.config.buttonHoverColor;
    } else {
      backgroundColor = widget.config.buttonColor;
    }
    
    final textColor = isActive
        ? widget.config.activeTextColor
        : widget.config.textColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.config.buttonPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.config.showIcons) ...[
                Icon(
                  widget.icon,
                  color: textColor,
                  size: widget.config.iconSize,
                ),
                if (widget.config.showLabels)
                  const SizedBox(width: 6),
              ],
              if (widget.config.showLabels)
                Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: widget.config.fontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact quick menu (icons only)
class CompactQuickMenu extends StatelessWidget {
  final bool isAutoMode;
  final bool isSkipMode;
  final void Function(QuickMenuAction action)? onAction;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? activeColor;

  const CompactQuickMenu({
    super.key,
    this.isAutoMode = false,
    this.isSkipMode = false,
    this.onAction,
    this.backgroundColor,
    this.iconColor,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return QuickMenu(
      isAutoMode: isAutoMode,
      isSkipMode: isSkipMode,
      onAction: onAction,
      config: QuickMenuConfig(
        backgroundColor: backgroundColor ?? const Color(0x99000000),
        textColor: iconColor ?? const Color(0xCCFFFFFF),
        activeTextColor: activeColor ?? Colors.white,
        showLabels: false,
        buttonPadding: const EdgeInsets.all(8),
        buttonSpacing: 2,
      ),
    );
  }
}
