/// Color blind mode types for accessibility
/// 
/// Supports different types of color vision deficiency to help
/// users with color blindness better distinguish UI elements.
enum ColorBlindMode {
  /// No color adjustment
  none,
  
  /// Protanopia - red color blindness
  /// Difficulty distinguishing red and green colors
  protanopia,
  
  /// Deuteranopia - green color blindness
  /// Most common form, difficulty with red-green distinction
  deuteranopia,
  
  /// Tritanopia - blue color blindness
  /// Difficulty distinguishing blue and yellow colors
  tritanopia,
}

/// Extension methods for ColorBlindMode
extension ColorBlindModeExtension on ColorBlindMode {
  /// Get display name for the mode
  String get displayName {
    switch (this) {
      case ColorBlindMode.none:
        return 'None';
      case ColorBlindMode.protanopia:
        return 'Protanopia (Red-Blind)';
      case ColorBlindMode.deuteranopia:
        return 'Deuteranopia (Green-Blind)';
      case ColorBlindMode.tritanopia:
        return 'Tritanopia (Blue-Blind)';
    }
  }
  
  /// Get description for the mode
  String get description {
    switch (this) {
      case ColorBlindMode.none:
        return 'No color adjustment';
      case ColorBlindMode.protanopia:
        return 'Adjusts colors for red color blindness';
      case ColorBlindMode.deuteranopia:
        return 'Adjusts colors for green color blindness';
      case ColorBlindMode.tritanopia:
        return 'Adjusts colors for blue color blindness';
    }
  }
}
