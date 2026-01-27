/// Choice Panel Widget
/// 
/// Displays player choices as a vertical button list centered on screen.
/// Supports hover/click animations, keyboard navigation, and timed choices.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/vn_ui_strings.dart';

/// A single choice option
class VNChoiceOption {
  /// Unique identifier
  final String id;
  
  /// Display text
  final String text;
  
  /// Whether this option is enabled
  final bool isEnabled;
  
  /// Reason why option is disabled (if applicable)
  final String? disabledReason;
  
  /// Whether this option was previously selected (for replay)
  final bool wasPreviouslySelected;

  const VNChoiceOption({
    required this.id,
    required this.text,
    this.isEnabled = true,
    this.disabledReason,
    this.wasPreviouslySelected = false,
  });
}

/// Configuration for the choice panel
class ChoicePanelConfig {
  /// Background color of choice buttons
  final Color buttonBackgroundColor;
  
  /// Background color when hovered
  final Color buttonHoverColor;
  
  /// Background color when pressed
  final Color buttonPressedColor;
  
  /// Background color when disabled
  final Color buttonDisabledColor;
  
  /// Text color
  final Color textColor;
  
  /// Text color when disabled
  final Color disabledTextColor;
  
  /// Text color for previously selected choices
  final Color previouslySelectedTextColor;
  
  /// Font size
  final double fontSize;
  
  /// Button padding
  final EdgeInsets buttonPadding;
  
  /// Spacing between buttons
  final double buttonSpacing;
  
  /// Button border radius
  final double borderRadius;
  
  /// Maximum button width
  final double maxButtonWidth;
  
  /// Animation duration for hover/press effects
  final Duration animationDuration;
  
  /// Whether to show countdown for timed choices
  final bool showCountdown;
  
  /// Countdown bar color
  final Color countdownColor;

  const ChoicePanelConfig({
    this.buttonBackgroundColor = const Color(0xCC1A1A2E),
    this.buttonHoverColor = const Color(0xCC2A2A4E),
    this.buttonPressedColor = const Color(0xCC3A3A6E),
    this.buttonDisabledColor = const Color(0x66333333),
    this.textColor = Colors.white,
    this.disabledTextColor = const Color(0x66FFFFFF),
    this.previouslySelectedTextColor = const Color(0xFFAAAAAA),
    this.fontSize = 20.0,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.buttonSpacing = 12.0,
    this.borderRadius = 8.0,
    this.maxButtonWidth = 600.0,
    this.animationDuration = const Duration(milliseconds: 150),
    this.showCountdown = true,
    this.countdownColor = const Color(0xFFFF6B6B),
  });

  ChoicePanelConfig copyWith({
    Color? buttonBackgroundColor,
    Color? buttonHoverColor,
    Color? buttonPressedColor,
    Color? buttonDisabledColor,
    Color? textColor,
    Color? disabledTextColor,
    Color? previouslySelectedTextColor,
    double? fontSize,
    EdgeInsets? buttonPadding,
    double? buttonSpacing,
    double? borderRadius,
    double? maxButtonWidth,
    Duration? animationDuration,
    bool? showCountdown,
    Color? countdownColor,
  }) {
    return ChoicePanelConfig(
      buttonBackgroundColor: buttonBackgroundColor ?? this.buttonBackgroundColor,
      buttonHoverColor: buttonHoverColor ?? this.buttonHoverColor,
      buttonPressedColor: buttonPressedColor ?? this.buttonPressedColor,
      buttonDisabledColor: buttonDisabledColor ?? this.buttonDisabledColor,
      textColor: textColor ?? this.textColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
      previouslySelectedTextColor: previouslySelectedTextColor ?? this.previouslySelectedTextColor,
      fontSize: fontSize ?? this.fontSize,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      borderRadius: borderRadius ?? this.borderRadius,
      maxButtonWidth: maxButtonWidth ?? this.maxButtonWidth,
      animationDuration: animationDuration ?? this.animationDuration,
      showCountdown: showCountdown ?? this.showCountdown,
      countdownColor: countdownColor ?? this.countdownColor,
    );
  }
}

/// Choice panel widget for displaying player choices
class ChoicePanel extends StatefulWidget {
  /// List of choices to display
  final List<VNChoiceOption> choices;
  
  /// Callback when a choice is selected
  final void Function(int index, VNChoiceOption choice)? onChoiceSelected;
  
  /// Whether this is a timed choice
  final bool isTimed;
  
  /// Time limit in seconds (if timed)
  final double? timeLimit;
  
  /// Default choice index if time runs out
  final int? defaultChoiceIndex;
  
  /// Callback when time runs out
  final VoidCallback? onTimeOut;
  
  /// Configuration
  final ChoicePanelConfig config;
  
  /// Whether to enable keyboard navigation
  final bool enableKeyboardNavigation;
  
  /// Language code for localization (en, zh, ja)
  final String languageCode;

  const ChoicePanel({
    super.key,
    required this.choices,
    this.onChoiceSelected,
    this.isTimed = false,
    this.timeLimit,
    this.defaultChoiceIndex,
    this.onTimeOut,
    this.config = const ChoicePanelConfig(),
    this.enableKeyboardNavigation = true,
    this.languageCode = 'en',
  });

  @override
  State<ChoicePanel> createState() => _ChoicePanelState();
}

class _ChoicePanelState extends State<ChoicePanel> with SingleTickerProviderStateMixin {
  /// Currently focused choice index (for keyboard navigation)
  int _focusedIndex = 0;
  
  /// Timer for timed choices
  Timer? _countdownTimer;
  
  /// Remaining time in seconds
  double _remainingTime = 0;
  
  /// Animation controller for countdown
  AnimationController? _countdownController;
  
  /// Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeTimedChoice();
    
    // Find first enabled choice for initial focus
    for (int i = 0; i < widget.choices.length; i++) {
      if (widget.choices[i].isEnabled) {
        _focusedIndex = i;
        break;
      }
    }
    
    // Request focus for keyboard navigation
    if (widget.enableKeyboardNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(ChoicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isTimed != oldWidget.isTimed ||
        widget.timeLimit != oldWidget.timeLimit) {
      _cancelCountdown();
      _initializeTimedChoice();
    }
  }

  @override
  void dispose() {
    _cancelCountdown();
    _countdownController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeTimedChoice() {
    if (!widget.isTimed || widget.timeLimit == null) return;
    
    _remainingTime = widget.timeLimit!;
    
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.timeLimit! * 1000).round()),
    );
    
    _countdownController!.forward();
    
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        setState(() {
          _remainingTime -= 0.1;
          if (_remainingTime <= 0) {
            _handleTimeOut();
          }
        });
      },
    );
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownController?.stop();
  }

  void _handleTimeOut() {
    _cancelCountdown();
    
    if (widget.defaultChoiceIndex != null &&
        widget.defaultChoiceIndex! < widget.choices.length) {
      final choice = widget.choices[widget.defaultChoiceIndex!];
      if (choice.isEnabled) {
        widget.onChoiceSelected?.call(widget.defaultChoiceIndex!, choice);
      }
    }
    
    widget.onTimeOut?.call();
  }

  void _selectChoice(int index) {
    if (index < 0 || index >= widget.choices.length) return;
    
    final choice = widget.choices[index];
    if (!choice.isEnabled) return;
    
    _cancelCountdown();
    widget.onChoiceSelected?.call(index, choice);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.space) {
      _selectChoice(_focusedIndex);
    } else if (event.logicalKey.keyLabel.length == 1) {
      // Number key selection (1-9)
      final number = int.tryParse(event.logicalKey.keyLabel);
      if (number != null && number >= 1 && number <= widget.choices.length) {
        _selectChoice(number - 1);
      }
    }
  }

  void _moveFocus(int delta) {
    int newIndex = _focusedIndex;
    int attempts = 0;
    
    do {
      newIndex = (newIndex + delta) % widget.choices.length;
      if (newIndex < 0) newIndex = widget.choices.length - 1;
      attempts++;
    } while (!widget.choices[newIndex].isEnabled && attempts < widget.choices.length);
    
    if (widget.choices[newIndex].isEnabled) {
      setState(() {
        _focusedIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: widget.enableKeyboardNavigation ? _handleKeyEvent : null,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Countdown bar (if timed)
              if (widget.isTimed && widget.config.showCountdown)
                _buildCountdownBar(),
              
              // Choice buttons
              ...List.generate(widget.choices.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < widget.choices.length - 1
                        ? widget.config.buttonSpacing
                        : 0,
                  ),
                  child: _ChoiceButton(
                    choice: widget.choices[index],
                    index: index,
                    isFocused: _focusedIndex == index,
                    config: widget.config,
                    languageCode: widget.languageCode,
                    onTap: () => _selectChoice(index),
                    onHover: (isHovered) {
                      if (isHovered && widget.choices[index].isEnabled) {
                        setState(() {
                          _focusedIndex = index;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBar() {
    final progress = _remainingTime / (widget.timeLimit ?? 1);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: widget.config.maxButtonWidth,
        child: Column(
          children: [
            // Time remaining text
            Text(
              VNUILocalizer.format(
                VNUIStrings.timeRemaining,
                {'seconds': _remainingTime.ceil().toString()},
                widget.languageCode,
              ),
              style: TextStyle(
                color: widget.config.countdownColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.config.countdownColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual choice button widget
class _ChoiceButton extends StatefulWidget {
  final VNChoiceOption choice;
  final int index;
  final bool isFocused;
  final ChoicePanelConfig config;
  final String languageCode;
  final VoidCallback onTap;
  final void Function(bool isHovered) onHover;

  const _ChoiceButton({
    required this.choice,
    required this.index,
    required this.isFocused,
    required this.config,
    required this.languageCode,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.choice.isEnabled;
    
    Color backgroundColor;
    if (!isEnabled) {
      backgroundColor = widget.config.buttonDisabledColor;
    } else if (_isPressed) {
      backgroundColor = widget.config.buttonPressedColor;
    } else if (_isHovered || widget.isFocused) {
      backgroundColor = widget.config.buttonHoverColor;
    } else {
      backgroundColor = widget.config.buttonBackgroundColor;
    }
    
    Color textColor;
    if (!isEnabled) {
      textColor = widget.config.disabledTextColor;
    } else if (widget.choice.wasPreviouslySelected) {
      textColor = widget.config.previouslySelectedTextColor;
    } else {
      textColor = widget.config.textColor;
    }
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover(false);
      },
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: widget.config.animationDuration,
          constraints: BoxConstraints(
            maxWidth: widget.config.maxButtonWidth,
            minWidth: 200,
          ),
          padding: widget.config.buttonPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            border: Border.all(
              color: widget.isFocused && isEnabled
                  ? widget.config.textColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: (_isHovered || widget.isFocused) && isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Choice number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Choice text
              Flexible(
                child: Text(
                  widget.choice.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: widget.config.fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Previously selected indicator
              if (widget.choice.wasPreviouslySelected) ...[
                const SizedBox(width: 12),
                Tooltip(
                  message: VNUILocalizer.get(VNUIStrings.previouslySelected, widget.languageCode),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: textColor.withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
