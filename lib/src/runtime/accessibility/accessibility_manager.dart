import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'accessibility_settings.dart';
import 'color_blind_mode.dart';

/// Accessibility manager for VNBS runtime
/// 
/// Manages accessibility settings and provides utilities for:
/// - Font size adjustment (Requirements 10.3)
/// - High contrast mode (Requirements 10.2)
/// - Color blind mode filters (Requirements 10.5)
/// - Screen reader support (Requirements 10.1)
/// - Dyslexia-friendly fonts (Requirements 10.4)
/// - Keyboard navigation (Requirements 10.6)
class AccessibilityManager {
  /// Current accessibility settings
  AccessibilitySettings _settings;
  
  /// Stream controller for settings changes
  final _settingsController = StreamController<AccessibilitySettings>.broadcast();
  
  /// Path to save settings file
  final String? _settingsPath;
  
  /// Default dyslexia-friendly font family
  static const String dyslexiaFontFamily = 'OpenDyslexic';
  
  /// Fallback dyslexia-friendly fonts
  static const List<String> dyslexiaFontFallbacks = [
    'OpenDyslexic',
    'Comic Sans MS',
    'Verdana',
    'Arial',
  ];

  AccessibilityManager({
    AccessibilitySettings? initialSettings,
    String? settingsPath,
  }) : _settings = initialSettings ?? const AccessibilitySettings(),
       _settingsPath = settingsPath;

  /// Get current settings
  AccessibilitySettings get settings => _settings;
  
  /// Stream of settings changes
  Stream<AccessibilitySettings> get settingsStream => _settingsController.stream;

  /// Update settings
  void updateSettings(AccessibilitySettings settings) {
    if (_settings == settings) return;
    
    _settings = settings;
    _settingsController.add(_settings);
    _applySettings();
  }

  /// Apply current settings to the system
  void _applySettings() {
    // Settings are applied through the getter methods
    // UI components should listen to settingsStream and rebuild
  }

  /// Get adjusted font size based on settings
  double getAdjustedFontSize(double baseSize) {
    return baseSize * _settings.fontSizeMultiplier;
  }

  /// Get adjusted text style with accessibility modifications
  TextStyle getAdjustedTextStyle(TextStyle baseStyle) {
    var style = baseStyle;
    
    // Apply font size multiplier
    if (baseStyle.fontSize != null) {
      style = style.copyWith(
        fontSize: baseStyle.fontSize! * _settings.fontSizeMultiplier,
      );
    }
    
    // Apply dyslexia-friendly font
    if (_settings.dyslexiaFriendlyFont) {
      style = style.copyWith(
        fontFamily: dyslexiaFontFamily,
        fontFamilyFallback: dyslexiaFontFallbacks,
      );
    }
    
    // Apply high contrast (increase font weight for better visibility)
    if (_settings.highContrastMode) {
      final currentWeight = style.fontWeight ?? FontWeight.normal;
      final newWeight = _increaseWeight(currentWeight);
      style = style.copyWith(fontWeight: newWeight);
    }
    
    return style;
  }

  /// Get font family based on settings
  String getFontFamily(String defaultFont) {
    if (_settings.dyslexiaFriendlyFont) {
      return dyslexiaFontFamily;
    }
    return defaultFont;
  }

  /// Get adjusted color for color blind mode
  Color getAdjustedColor(Color color) {
    if (_settings.colorBlindMode == ColorBlindMode.none) {
      return color;
    }
    return _applyColorBlindFilter(color, _settings.colorBlindMode);
  }

  /// Get high contrast color
  Color getHighContrastColor(Color color, {bool isBackground = false}) {
    if (!_settings.highContrastMode) {
      return color;
    }
    
    // Increase contrast by pushing colors toward black or white
    final luminance = color.computeLuminance();
    
    if (isBackground) {
      // For backgrounds, make dark colors darker and light colors lighter
      if (luminance < 0.5) {
        return _darkenColor(color, 0.3);
      } else {
        return _lightenColor(color, 0.3);
      }
    } else {
      // For foreground/text, ensure good contrast
      if (luminance < 0.5) {
        return _lightenColor(color, 0.4);
      } else {
        return _darkenColor(color, 0.4);
      }
    }
  }

  /// Check if animations should be reduced
  bool get shouldReduceMotion => _settings.reduceMotion;

  /// Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration normalDuration) {
    if (_settings.reduceMotion) {
      return Duration.zero;
    }
    return normalDuration;
  }

  /// Get animation curve based on reduce motion setting
  Curve getAnimationCurve(Curve normalCurve) {
    if (_settings.reduceMotion) {
      return Curves.linear;
    }
    return normalCurve;
  }

  /// Announce text for screen readers
  Future<void> announceText(String text) async {
    if (!_settings.screenReaderEnabled) return;
    
    // Use Flutter's semantics announcer
    SemanticsService.announce(text, TextDirection.ltr);
  }

  /// Announce text with priority for screen readers
  Future<void> announceTextWithPriority(String text, {bool assertive = false}) async {
    if (!_settings.screenReaderEnabled) return;
    
    // Use Flutter's semantics announcer
    // Note: Flutter doesn't have assertive mode, but we can still announce
    SemanticsService.announce(text, TextDirection.ltr);
  }

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => _settings.screenReaderEnabled;

  /// Check if auto-read dialogue is enabled
  bool get shouldAutoReadDialogue => _settings.autoReadDialogue;

  /// Get speech rate for text-to-speech
  double get speechRate => _settings.speechRate;

  /// Get speech pitch for text-to-speech
  double get speechPitch => _settings.speechPitch;

  /// Save settings to file
  Future<void> saveSettings() async {
    if (_settingsPath == null) return;
    
    try {
      final file = File(_settingsPath!);
      final json = jsonEncode(_settings.toJson());
      await file.writeAsString(json);
    } catch (e) {
      // Log error but don't throw - settings save is not critical
      debugPrint('Failed to save accessibility settings: $e');
    }
  }

  /// Load settings from file
  Future<void> loadSettings() async {
    if (_settingsPath == null) return;
    
    try {
      final file = File(_settingsPath!);
      if (await file.exists()) {
        final json = await file.readAsString();
        final data = jsonDecode(json) as Map<String, dynamic>;
        _settings = AccessibilitySettings.fromJson(data);
        _settingsController.add(_settings);
      }
    } catch (e) {
      // Log error but don't throw - use default settings
      debugPrint('Failed to load accessibility settings: $e');
    }
  }

  /// Reset settings to defaults
  void resetToDefaults() {
    updateSettings(const AccessibilitySettings());
  }

  /// Dispose resources
  void dispose() {
    _settingsController.close();
  }

  // ============ Private Helper Methods ============

  /// Apply color blind filter to a color
  Color _applyColorBlindFilter(Color color, ColorBlindMode mode) {
    switch (mode) {
      case ColorBlindMode.none:
        return color;
      case ColorBlindMode.protanopia:
        return _simulateProtanopia(color);
      case ColorBlindMode.deuteranopia:
        return _simulateDeuteranopia(color);
      case ColorBlindMode.tritanopia:
        return _simulateTritanopia(color);
    }
  }

  /// Simulate protanopia (red-blind) color vision
  /// Uses Brettel, Viénot, and Mollon (1997) algorithm
  Color _simulateProtanopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
    // Protanopia simulation matrix
    final newR = 0.567 * r + 0.433 * g + 0.0 * b;
    final newG = 0.558 * r + 0.442 * g + 0.0 * b;
    final newB = 0.0 * r + 0.242 * g + 0.758 * b;
    
    return Color.fromARGB(
      c.alpha,
      (newR * 255).round().clamp(0, 255),
      (newG * 255).round().clamp(0, 255),
      (newB * 255).round().clamp(0, 255),
    );
  }

  /// Simulate deuteranopia (green-blind) color vision
  Color _simulateDeuteranopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
    // Deuteranopia simulation matrix
    final newR = 0.625 * r + 0.375 * g + 0.0 * b;
    final newG = 0.7 * r + 0.3 * g + 0.0 * b;
    final newB = 0.0 * r + 0.3 * g + 0.7 * b;
    
    return Color.fromARGB(
      c.alpha,
      (newR * 255).round().clamp(0, 255),
      (newG * 255).round().clamp(0, 255),
      (newB * 255).round().clamp(0, 255),
    );
  }

  /// Simulate tritanopia (blue-blind) color vision
  Color _simulateTritanopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
    // Tritanopia simulation matrix
    final newR = 0.95 * r + 0.05 * g + 0.0 * b;
    final newG = 0.0 * r + 0.433 * g + 0.567 * b;
    final newB = 0.0 * r + 0.475 * g + 0.525 * b;
    
    return Color.fromARGB(
      c.alpha,
      (newR * 255).round().clamp(0, 255),
      (newG * 255).round().clamp(0, 255),
      (newB * 255).round().clamp(0, 255),
    );
  }

  /// Darken a color by a factor (0.0 - 1.0)
  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness - factor).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Lighten a color by a factor (0.0 - 1.0)
  Color _lightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Increase font weight for high contrast
  FontWeight _increaseWeight(FontWeight weight) {
    const weights = [
      FontWeight.w100,
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ];
    
    final currentIndex = weights.indexOf(weight);
    if (currentIndex == -1 || currentIndex >= weights.length - 1) {
      return FontWeight.w900;
    }
    
    // Increase by 2 steps for high contrast
    final newIndex = (currentIndex + 2).clamp(0, weights.length - 1);
    return weights[newIndex];
  }
}
