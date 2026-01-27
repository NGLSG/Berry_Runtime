/// ADV Mode Textbox Widget
/// 
/// Displays dialogue in a semi-transparent textbox at the bottom of the screen.
/// Standard 1920x1080 layout with speaker name label, dialogue text area,
/// and click indicator animation.

import 'dart:async';
import 'package:flutter/material.dart';
import '../effects/text/text_effect_parser.dart';
import '../effects/text/text_effect_widgets.dart';

/// Configuration for the ADV textbox
class ADVTextboxConfig {
  /// Text display speed (characters per second, 0 = instant)
  final double textSpeed;
  
  /// Background color of the textbox
  final Color backgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Speaker name color (default, can be overridden per character)
  final Color speakerNameColor;
  
  /// Font size for dialogue text
  final double textFontSize;
  
  /// Font size for speaker name
  final double speakerNameFontSize;
  
  /// Padding inside the textbox
  final EdgeInsets padding;
  
  /// Height of the textbox (relative to screen height, 0.0-1.0)
  final double heightRatio;
  
  /// Whether to show click indicator
  final bool showClickIndicator;
  
  /// Border color of the textbox
  final Color borderColor;
  
  /// Border width of the textbox
  final double borderWidth;
  
  /// Border radius of the textbox
  final double borderRadius;

  const ADVTextboxConfig({
    this.textSpeed = 30.0,
    this.backgroundColor = const Color(0xCC000000),
    this.textColor = Colors.white,
    this.speakerNameColor = Colors.white,
    this.textFontSize = 24.0,
    this.speakerNameFontSize = 20.0,
    this.padding = const EdgeInsets.all(24.0),
    this.heightRatio = 0.28,
    this.showClickIndicator = true,
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
  });

  ADVTextboxConfig copyWith({
    double? textSpeed,
    Color? backgroundColor,
    Color? textColor,
    Color? speakerNameColor,
    double? textFontSize,
    double? speakerNameFontSize,
    EdgeInsets? padding,
    double? heightRatio,
    bool? showClickIndicator,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
  }) {
    return ADVTextboxConfig(
      textSpeed: textSpeed ?? this.textSpeed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      speakerNameColor: speakerNameColor ?? this.speakerNameColor,
      textFontSize: textFontSize ?? this.textFontSize,
      speakerNameFontSize: speakerNameFontSize ?? this.speakerNameFontSize,
      padding: padding ?? this.padding,
      heightRatio: heightRatio ?? this.heightRatio,
      showClickIndicator: showClickIndicator ?? this.showClickIndicator,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}

/// ADV mode textbox widget for visual novel dialogue display
class ADVTextbox extends StatefulWidget {
  /// Speaker name (null for narration)
  final String? speakerName;
  
  /// Speaker name color (overrides config)
  final Color? speakerColor;
  
  /// Full dialogue text to display
  final String text;
  
  /// Whether text animation is complete
  final bool isTextComplete;
  
  /// Callback when textbox is tapped
  final VoidCallback? onTap;
  
  /// Callback when text animation completes
  final VoidCallback? onTextAnimationComplete;
  
  /// Configuration for the textbox
  final ADVTextboxConfig config;
  
  /// Whether to animate text (typewriter effect)
  final bool animateText;
  
  /// Custom background widget (e.g., for themed textbox images)
  final Widget? backgroundWidget;

  const ADVTextbox({
    super.key,
    this.speakerName,
    this.speakerColor,
    required this.text,
    this.isTextComplete = false,
    this.onTap,
    this.onTextAnimationComplete,
    this.config = const ADVTextboxConfig(),
    this.animateText = true,
    this.backgroundWidget,
  });

  @override
  State<ADVTextbox> createState() => _ADVTextboxState();
}

class _ADVTextboxState extends State<ADVTextbox> with TickerProviderStateMixin {
  /// Current number of visible characters
  int _visibleCharCount = 0;
  
  /// Timer for typewriter animation
  Timer? _typewriterTimer;
  
  /// Animation controller for click indicator
  late AnimationController _clickIndicatorController;
  
  /// Animation for click indicator bounce
  late Animation<double> _clickIndicatorAnimation;
  
  /// Whether text animation is complete
  bool _isAnimationComplete = false;

  /// Text effect parser
  final _textEffectParser = TextEffectParser();

  /// Plain text (without effect markup) for typewriter animation
  String get _plainText => _textEffectParser.stripMarkup(widget.text);

  @override
  void initState() {
    super.initState();
    _setupClickIndicatorAnimation();
    _startTypewriterAnimation();
  }

  @override
  void didUpdateWidget(ADVTextbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset animation when text changes
    if (oldWidget.text != widget.text) {
      _resetTypewriterAnimation();
      _startTypewriterAnimation();
    }
    
    // Handle external completion signal
    if (widget.isTextComplete && !_isAnimationComplete) {
      _completeAnimation();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _clickIndicatorController.dispose();
    super.dispose();
  }

  void _setupClickIndicatorAnimation() {
    _clickIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _clickIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _clickIndicatorController,
      curve: Curves.easeInOut,
    ));
    
    _clickIndicatorController.repeat(reverse: true);
  }

  void _startTypewriterAnimation() {
    if (!widget.animateText || widget.config.textSpeed <= 0) {
      _completeAnimation();
      return;
    }

    _visibleCharCount = 0;
    _isAnimationComplete = false;
    
    final intervalMs = (1000 / widget.config.textSpeed).round();
    
    _typewriterTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (timer) {
        if (_visibleCharCount >= _plainText.length) {
          timer.cancel();
          _completeAnimation();
          return;
        }
        
        setState(() {
          _visibleCharCount++;
        });
      },
    );
  }

  void _resetTypewriterAnimation() {
    _typewriterTimer?.cancel();
    _visibleCharCount = 0;
    _isAnimationComplete = false;
  }

  void _completeAnimation() {
    _typewriterTimer?.cancel();
    setState(() {
      _visibleCharCount = _plainText.length;
      _isAnimationComplete = true;
    });
    widget.onTextAnimationComplete?.call();
  }

  void _handleTap() {
    if (!_isAnimationComplete) {
      // Skip to end of text
      _completeAnimation();
    } else {
      // Advance to next dialogue
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textboxHeight = screenSize.height * widget.config.heightRatio;
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: textboxHeight,
      child: GestureDetector(
        onTap: _handleTap,
        child: Stack(
          children: [
            // Background
            _buildBackground(),
            
            // Content
            Padding(
              padding: widget.config.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Speaker name plate
                  if (widget.speakerName != null && widget.speakerName!.isNotEmpty)
                    _buildSpeakerNamePlate(),
                  
                  const SizedBox(height: 8),
                  
                  // Dialogue text
                  Expanded(
                    child: _buildDialogueText(),
                  ),
                ],
              ),
            ),
            
            // Click indicator
            if (widget.config.showClickIndicator && _isAnimationComplete)
              _buildClickIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.backgroundWidget != null) {
      return Positioned.fill(child: widget.backgroundWidget!);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        border: Border.all(
          color: widget.config.borderColor,
          width: widget.config.borderWidth,
        ),
      ),
    );
  }

  Widget _buildSpeakerNamePlate() {
    final nameColor = widget.speakerColor ?? widget.config.speakerNameColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: nameColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: nameColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        widget.speakerName!,
        style: TextStyle(
          color: nameColor,
          fontSize: widget.config.speakerNameFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDialogueText() {
    // Check if text has effect markup
    if (_textEffectParser.hasEffectMarkup(widget.text)) {
      // Parse and render with effects
      final segments = _textEffectParser.parse(widget.text);
      
      // For typewriter effect, we need to calculate how many characters to show
      // across all segments
      int remainingChars = _visibleCharCount;
      final visibleSegments = <Widget>[];
      
      for (final segment in segments) {
        if (remainingChars <= 0) break;
        
        final segmentText = segment.text;
        final charsToShow = remainingChars.clamp(0, segmentText.length);
        final visibleText = segmentText.substring(0, charsToShow);
        remainingChars -= charsToShow;
        
        if (visibleText.isEmpty) continue;
        
        if (segment.effect != null) {
          // Render with effect
          visibleSegments.add(
            EffectText(
              text: visibleText,
              config: segment.effect!,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.textFontSize,
                height: 1.5,
              ),
            ),
          );
        } else {
          // Plain text
          visibleSegments.add(
            Text(
              visibleText,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.textFontSize,
                height: 1.5,
              ),
            ),
          );
        }
      }
      
      return Wrap(
        children: visibleSegments,
      );
    }
    
    // No effects, just show plain text with typewriter
    final displayText = _plainText.substring(0, _visibleCharCount);
    
    return Text(
      displayText,
      style: TextStyle(
        color: widget.config.textColor,
        fontSize: widget.config.textFontSize,
        height: 1.5,
      ),
    );
  }

  Widget _buildClickIndicator() {
    return Positioned(
      right: widget.config.padding.right + 8,
      bottom: widget.config.padding.bottom + 8,
      child: AnimatedBuilder(
        animation: _clickIndicatorAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _clickIndicatorAnimation.value),
            child: child,
          );
        },
        child: Icon(
          Icons.arrow_drop_down,
          color: widget.config.textColor.withOpacity(0.7),
          size: 32,
        ),
      ),
    );
  }
}

/// Typewriter text controller for external control
class TypewriterController extends ChangeNotifier {
  int _visibleCharCount = 0;
  bool _isComplete = false;
  String _text = '';
  Timer? _timer;
  double _speed = 30.0;

  int get visibleCharCount => _visibleCharCount;
  bool get isComplete => _isComplete;
  String get visibleText => _text.substring(0, _visibleCharCount);

  void setText(String text, {double speed = 30.0}) {
    _timer?.cancel();
    _text = text;
    _speed = speed;
    _visibleCharCount = 0;
    _isComplete = false;
    notifyListeners();
  }

  void start() {
    if (_speed <= 0) {
      complete();
      return;
    }

    final intervalMs = (1000 / _speed).round();
    _timer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (timer) {
        if (_visibleCharCount >= _text.length) {
          timer.cancel();
          _isComplete = true;
          notifyListeners();
          return;
        }
        _visibleCharCount++;
        notifyListeners();
      },
    );
  }

  void complete() {
    _timer?.cancel();
    _visibleCharCount = _text.length;
    _isComplete = true;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _visibleCharCount = 0;
    _isComplete = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
