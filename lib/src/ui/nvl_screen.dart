/// NVL Mode Full Screen Widget
/// 
/// Displays dialogue on a full-screen overlay with scrollable text history.
/// Used for novel-style text presentation where multiple lines accumulate.

import 'dart:async';
import 'package:flutter/material.dart';

/// A single line in NVL mode
class NVLLine {
  /// Speaker name (null for narration)
  final String? speakerName;
  
  /// Speaker name color
  final Color? speakerColor;
  
  /// Dialogue text
  final String text;
  
  /// Whether this line has been fully displayed
  final bool isComplete;
  
  /// Unique identifier for this line
  final String id;

  const NVLLine({
    this.speakerName,
    this.speakerColor,
    required this.text,
    this.isComplete = true,
    required this.id,
  });

  NVLLine copyWith({
    String? speakerName,
    Color? speakerColor,
    String? text,
    bool? isComplete,
    String? id,
  }) {
    return NVLLine(
      speakerName: speakerName ?? this.speakerName,
      speakerColor: speakerColor ?? this.speakerColor,
      text: text ?? this.text,
      isComplete: isComplete ?? this.isComplete,
      id: id ?? this.id,
    );
  }
}

/// Configuration for the NVL screen
class NVLScreenConfig {
  /// Text display speed (characters per second, 0 = instant)
  final double textSpeed;
  
  /// Background color of the overlay
  final Color backgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Speaker name color (default)
  final Color speakerNameColor;
  
  /// Font size for dialogue text
  final double textFontSize;
  
  /// Font size for speaker name
  final double speakerNameFontSize;
  
  /// Padding around the text area
  final EdgeInsets padding;
  
  /// Spacing between lines
  final double lineSpacing;
  
  /// Maximum number of lines to keep in history
  final int maxHistoryLines;
  
  /// Whether to show click indicator
  final bool showClickIndicator;
  
  /// Whether to auto-scroll to bottom
  final bool autoScroll;

  const NVLScreenConfig({
    this.textSpeed = 30.0,
    this.backgroundColor = const Color(0xDD000000),
    this.textColor = Colors.white,
    this.speakerNameColor = Colors.white,
    this.textFontSize = 22.0,
    this.speakerNameFontSize = 18.0,
    this.padding = const EdgeInsets.all(48.0),
    this.lineSpacing = 16.0,
    this.maxHistoryLines = 100,
    this.showClickIndicator = true,
    this.autoScroll = true,
  });

  NVLScreenConfig copyWith({
    double? textSpeed,
    Color? backgroundColor,
    Color? textColor,
    Color? speakerNameColor,
    double? textFontSize,
    double? speakerNameFontSize,
    EdgeInsets? padding,
    double? lineSpacing,
    int? maxHistoryLines,
    bool? showClickIndicator,
    bool? autoScroll,
  }) {
    return NVLScreenConfig(
      textSpeed: textSpeed ?? this.textSpeed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      speakerNameColor: speakerNameColor ?? this.speakerNameColor,
      textFontSize: textFontSize ?? this.textFontSize,
      speakerNameFontSize: speakerNameFontSize ?? this.speakerNameFontSize,
      padding: padding ?? this.padding,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      maxHistoryLines: maxHistoryLines ?? this.maxHistoryLines,
      showClickIndicator: showClickIndicator ?? this.showClickIndicator,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }
}

/// NVL mode full screen widget for visual novel dialogue display
class NVLScreen extends StatefulWidget {
  /// List of dialogue lines to display
  final List<NVLLine> lines;
  
  /// Currently animating line (the last one being typed)
  final NVLLine? currentLine;
  
  /// Whether the current line animation is complete
  final bool isCurrentLineComplete;
  
  /// Callback when screen is tapped
  final VoidCallback? onTap;
  
  /// Callback when text animation completes
  final VoidCallback? onTextAnimationComplete;
  
  /// Configuration for the screen
  final NVLScreenConfig config;
  
  /// Whether to animate text (typewriter effect)
  final bool animateText;
  
  /// External scroll controller
  final ScrollController? scrollController;

  const NVLScreen({
    super.key,
    this.lines = const [],
    this.currentLine,
    this.isCurrentLineComplete = false,
    this.onTap,
    this.onTextAnimationComplete,
    this.config = const NVLScreenConfig(),
    this.animateText = true,
    this.scrollController,
  });

  @override
  State<NVLScreen> createState() => _NVLScreenState();
}

class _NVLScreenState extends State<NVLScreen> with TickerProviderStateMixin {
  /// Current number of visible characters in the current line
  int _visibleCharCount = 0;
  
  /// Timer for typewriter animation
  Timer? _typewriterTimer;
  
  /// Animation controller for click indicator
  late AnimationController _clickIndicatorController;
  
  /// Animation for click indicator
  late Animation<double> _clickIndicatorAnimation;
  
  /// Whether current line animation is complete
  bool _isAnimationComplete = false;
  
  /// Scroll controller
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _setupClickIndicatorAnimation();
    _startTypewriterAnimation();
  }

  @override
  void didUpdateWidget(NVLScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset animation when current line changes
    if (oldWidget.currentLine?.id != widget.currentLine?.id) {
      _resetTypewriterAnimation();
      _startTypewriterAnimation();
    }
    
    // Handle external completion signal
    if (widget.isCurrentLineComplete && !_isAnimationComplete) {
      _completeAnimation();
    }
    
    // Auto-scroll when new lines are added
    if (widget.config.autoScroll && widget.lines.length > oldWidget.lines.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _clickIndicatorController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
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
    if (widget.currentLine == null) {
      _isAnimationComplete = true;
      return;
    }

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
        final currentText = widget.currentLine?.text ?? '';
        if (_visibleCharCount >= currentText.length) {
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
      _visibleCharCount = widget.currentLine?.text.length ?? 0;
      _isAnimationComplete = true;
    });
    widget.onTextAnimationComplete?.call();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTap() {
    if (!_isAnimationComplete && widget.currentLine != null) {
      // Skip to end of current line
      _completeAnimation();
    } else {
      // Advance to next dialogue
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        color: widget.config.backgroundColor,
        child: Stack(
          children: [
            // Scrollable text area
            Padding(
              padding: widget.config.padding,
              child: _buildTextArea(),
            ),
            
            // Click indicator
            if (widget.config.showClickIndicator && _isAnimationComplete)
              _buildClickIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.lines.length + (widget.currentLine != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.lines.length) {
          // Completed lines
          return _buildLine(widget.lines[index], isComplete: true);
        } else {
          // Current animating line
          return _buildLine(
            widget.currentLine!,
            isComplete: false,
            visibleCharCount: _visibleCharCount,
          );
        }
      },
    );
  }

  Widget _buildLine(
    NVLLine line, {
    required bool isComplete,
    int? visibleCharCount,
  }) {
    final displayText = isComplete
        ? line.text
        : line.text.substring(0, visibleCharCount ?? line.text.length);
    
    return Padding(
      padding: EdgeInsets.only(bottom: widget.config.lineSpacing),
      child: RichText(
        text: TextSpan(
          children: [
            // Speaker name (if present)
            if (line.speakerName != null && line.speakerName!.isNotEmpty) ...[
              TextSpan(
                text: '【${line.speakerName}】',
                style: TextStyle(
                  color: line.speakerColor ?? widget.config.speakerNameColor,
                  fontSize: widget.config.speakerNameFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '\n'),
            ],
            // Dialogue text
            TextSpan(
              text: displayText,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.textFontSize,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickIndicator() {
    return Positioned(
      right: widget.config.padding.right,
      bottom: widget.config.padding.bottom,
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

/// Controller for NVL screen state management
class NVLScreenController extends ChangeNotifier {
  final List<NVLLine> _lines = [];
  NVLLine? _currentLine;
  int _visibleCharCount = 0;
  bool _isAnimating = false;
  Timer? _timer;
  double _speed = 30.0;
  int _lineIdCounter = 0;

  List<NVLLine> get lines => List.unmodifiable(_lines);
  NVLLine? get currentLine => _currentLine;
  int get visibleCharCount => _visibleCharCount;
  bool get isAnimating => _isAnimating;
  bool get isComplete => !_isAnimating && _currentLine == null;

  /// Add a new line and start animating it
  void addLine({
    String? speakerName,
    Color? speakerColor,
    required String text,
    double? speed,
  }) {
    // Complete current line if any
    if (_currentLine != null) {
      _completeCurrentLine();
    }

    _lineIdCounter++;
    _currentLine = NVLLine(
      speakerName: speakerName,
      speakerColor: speakerColor,
      text: text,
      isComplete: false,
      id: 'nvl_line_$_lineIdCounter',
    );
    _visibleCharCount = 0;
    _speed = speed ?? _speed;
    notifyListeners();
  }

  /// Start animating the current line
  void startAnimation() {
    if (_currentLine == null) return;
    
    if (_speed <= 0) {
      completeCurrentLine();
      return;
    }

    _isAnimating = true;
    final intervalMs = (1000 / _speed).round();
    
    _timer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (timer) {
        if (_currentLine == null || _visibleCharCount >= _currentLine!.text.length) {
          timer.cancel();
          _completeCurrentLine();
          return;
        }
        _visibleCharCount++;
        notifyListeners();
      },
    );
  }

  /// Complete the current line animation
  void completeCurrentLine() {
    _timer?.cancel();
    _completeCurrentLine();
  }

  void _completeCurrentLine() {
    if (_currentLine != null) {
      _visibleCharCount = _currentLine!.text.length;
      _lines.add(_currentLine!.copyWith(isComplete: true));
      _currentLine = null;
      _isAnimating = false;
      notifyListeners();
    }
  }

  /// Clear all lines (for new scene/chapter)
  void clear() {
    _timer?.cancel();
    _lines.clear();
    _currentLine = null;
    _visibleCharCount = 0;
    _isAnimating = false;
    notifyListeners();
  }

  /// Set text speed
  void setSpeed(double speed) {
    _speed = speed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
