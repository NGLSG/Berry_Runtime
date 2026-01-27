import 'color_blind_mode.dart';

/// Accessibility settings for visual novel runtime
/// 
/// Provides comprehensive accessibility options including:
/// - Font size adjustment (Requirements 10.3)
/// - High contrast mode (Requirements 10.2)
/// - Dyslexia-friendly font (Requirements 10.4)
/// - Color blind modes (Requirements 10.5)
/// - Screen reader support (Requirements 10.1)
/// - Keyboard navigation (Requirements 10.6)
/// - Reduced motion (for users sensitive to animations)
/// - Auto-read dialogue (text-to-speech)
class AccessibilitySettings {
  /// Font size multiplier (0.5 - 2.0)
  /// 1.0 is the default size, 0.5 is 50%, 2.0 is 200%
  final double fontSizeMultiplier;
  
  /// High contrast mode for better visibility
  /// Increases contrast between UI elements
  final bool highContrastMode;
  
  /// Use dyslexia-friendly font (e.g., OpenDyslexic)
  /// Helps users with dyslexia read text more easily
  final bool dyslexiaFriendlyFont;
  
  /// Color blind mode for color vision deficiency
  /// Adjusts colors to be more distinguishable
  final ColorBlindMode colorBlindMode;
  
  /// Enable screen reader support
  /// Provides semantic labels for screen readers
  final bool screenReaderEnabled;
  
  /// Reduce motion/animations
  /// Minimizes or disables animations for users sensitive to motion
  final bool reduceMotion;
  
  /// Auto-read dialogue using text-to-speech
  /// Automatically reads dialogue text aloud
  final bool autoReadDialogue;
  
  /// Enable keyboard-only navigation
  /// Ensures all UI elements are accessible via keyboard
  final bool keyboardNavigationEnabled;
  
  /// Text-to-speech speech rate (0.5 - 2.0)
  /// 1.0 is normal speed
  final double speechRate;
  
  /// Text-to-speech pitch (0.5 - 2.0)
  /// 1.0 is normal pitch
  final double speechPitch;

  /// Minimum font size multiplier
  static const double minFontSizeMultiplier = 0.5;
  
  /// Maximum font size multiplier
  static const double maxFontSizeMultiplier = 2.0;
  
  /// Default font size multiplier
  static const double defaultFontSizeMultiplier = 1.0;

  const AccessibilitySettings({
    this.fontSizeMultiplier = defaultFontSizeMultiplier,
    this.highContrastMode = false,
    this.dyslexiaFriendlyFont = false,
    this.colorBlindMode = ColorBlindMode.none,
    this.screenReaderEnabled = false,
    this.reduceMotion = false,
    this.autoReadDialogue = false,
    this.keyboardNavigationEnabled = true,
    this.speechRate = 1.0,
    this.speechPitch = 1.0,
  });

  /// Create a copy with modified values
  AccessibilitySettings copyWith({
    double? fontSizeMultiplier,
    bool? highContrastMode,
    bool? dyslexiaFriendlyFont,
    ColorBlindMode? colorBlindMode,
    bool? screenReaderEnabled,
    bool? reduceMotion,
    bool? autoReadDialogue,
    bool? keyboardNavigationEnabled,
    double? speechRate,
    double? speechPitch,
  }) {
    return AccessibilitySettings(
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      dyslexiaFriendlyFont: dyslexiaFriendlyFont ?? this.dyslexiaFriendlyFont,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      autoReadDialogue: autoReadDialogue ?? this.autoReadDialogue,
      keyboardNavigationEnabled: keyboardNavigationEnabled ?? this.keyboardNavigationEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'fontSizeMultiplier': fontSizeMultiplier,
    'highContrastMode': highContrastMode,
    'dyslexiaFriendlyFont': dyslexiaFriendlyFont,
    'colorBlindMode': colorBlindMode.name,
    'screenReaderEnabled': screenReaderEnabled,
    'reduceMotion': reduceMotion,
    'autoReadDialogue': autoReadDialogue,
    'keyboardNavigationEnabled': keyboardNavigationEnabled,
    'speechRate': speechRate,
    'speechPitch': speechPitch,
  };

  /// Deserialize from JSON
  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      fontSizeMultiplier: (json['fontSizeMultiplier'] as num?)?.toDouble() 
          ?? defaultFontSizeMultiplier,
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      dyslexiaFriendlyFont: json['dyslexiaFriendlyFont'] as bool? ?? false,
      colorBlindMode: ColorBlindMode.values.firstWhere(
        (e) => e.name == json['colorBlindMode'],
        orElse: () => ColorBlindMode.none,
      ),
      screenReaderEnabled: json['screenReaderEnabled'] as bool? ?? false,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      autoReadDialogue: json['autoReadDialogue'] as bool? ?? false,
      keyboardNavigationEnabled: json['keyboardNavigationEnabled'] as bool? ?? true,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
      speechPitch: (json['speechPitch'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Check if any accessibility feature is enabled
  bool get hasAnyFeatureEnabled =>
      fontSizeMultiplier != defaultFontSizeMultiplier ||
      highContrastMode ||
      dyslexiaFriendlyFont ||
      colorBlindMode != ColorBlindMode.none ||
      screenReaderEnabled ||
      reduceMotion ||
      autoReadDialogue;

  /// Validate and clamp font size multiplier
  static double clampFontSizeMultiplier(double value) {
    return value.clamp(minFontSizeMultiplier, maxFontSizeMultiplier);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilitySettings &&
        other.fontSizeMultiplier == fontSizeMultiplier &&
        other.highContrastMode == highContrastMode &&
        other.dyslexiaFriendlyFont == dyslexiaFriendlyFont &&
        other.colorBlindMode == colorBlindMode &&
        other.screenReaderEnabled == screenReaderEnabled &&
        other.reduceMotion == reduceMotion &&
        other.autoReadDialogue == autoReadDialogue &&
        other.keyboardNavigationEnabled == keyboardNavigationEnabled &&
        other.speechRate == speechRate &&
        other.speechPitch == speechPitch;
  }

  @override
  int get hashCode => Object.hash(
    fontSizeMultiplier,
    highContrastMode,
    dyslexiaFriendlyFont,
    colorBlindMode,
    screenReaderEnabled,
    reduceMotion,
    autoReadDialogue,
    keyboardNavigationEnabled,
    speechRate,
    speechPitch,
  );

  @override
  String toString() => 'AccessibilitySettings('
      'fontSizeMultiplier: $fontSizeMultiplier, '
      'highContrastMode: $highContrastMode, '
      'dyslexiaFriendlyFont: $dyslexiaFriendlyFont, '
      'colorBlindMode: $colorBlindMode, '
      'screenReaderEnabled: $screenReaderEnabled, '
      'reduceMotion: $reduceMotion, '
      'autoReadDialogue: $autoReadDialogue, '
      'keyboardNavigationEnabled: $keyboardNavigationEnabled, '
      'speechRate: $speechRate, '
      'speechPitch: $speechPitch)';
}
