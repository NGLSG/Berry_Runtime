import 'package:flutter/material.dart';

import '../accessibility/accessibility.dart';

/// Accessibility settings panel widget
/// 
/// Provides UI controls for all accessibility settings.
/// Can be embedded in the main settings screen.
/// Implements Requirements 10.7
class AccessibilitySettingsPanel extends StatefulWidget {
  /// Current accessibility settings
  final AccessibilitySettings settings;
  
  /// Callback when settings change
  final void Function(AccessibilitySettings settings)? onSettingsChanged;
  
  /// Panel background color
  final Color? backgroundColor;
  
  /// Text color
  final Color? textColor;
  
  /// Secondary text color
  final Color? secondaryTextColor;
  
  /// Accent color
  final Color? accentColor;

  const AccessibilitySettingsPanel({
    super.key,
    required this.settings,
    this.onSettingsChanged,
    this.backgroundColor,
    this.textColor,
    this.secondaryTextColor,
    this.accentColor,
  });

  @override
  State<AccessibilitySettingsPanel> createState() => _AccessibilitySettingsPanelState();
}

class _AccessibilitySettingsPanelState extends State<AccessibilitySettingsPanel> {
  late AccessibilitySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(AccessibilitySettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  void _updateSettings(AccessibilitySettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged?.call(newSettings);
  }

  Color get _textColor => widget.textColor ?? Colors.white;
  Color get _secondaryTextColor => widget.secondaryTextColor ?? Colors.white70;
  Color get _accentColor => widget.accentColor ?? const Color(0xFF6C63FF);
  Color get _backgroundColor => widget.backgroundColor ?? const Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual section
          _buildSectionHeader('Visual'),
          const SizedBox(height: 12),
          _buildFontSizeSlider(),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            'High Contrast Mode',
            'Increases contrast for better visibility',
            _settings.highContrastMode,
            (value) => _updateSettings(_settings.copyWith(highContrastMode: value)),
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            'Dyslexia-Friendly Font',
            'Uses a font designed for easier reading',
            _settings.dyslexiaFriendlyFont,
            (value) => _updateSettings(_settings.copyWith(dyslexiaFriendlyFont: value)),
          ),
          const SizedBox(height: 16),
          _buildColorBlindModeSelector(),
          
          const SizedBox(height: 24),
          
          // Motion section
          _buildSectionHeader('Motion'),
          const SizedBox(height: 12),
          _buildSwitchSetting(
            'Reduce Motion',
            'Minimizes animations and transitions',
            _settings.reduceMotion,
            (value) => _updateSettings(_settings.copyWith(reduceMotion: value)),
          ),
          
          const SizedBox(height: 24),
          
          // Audio & Reading section
          _buildSectionHeader('Audio & Reading'),
          const SizedBox(height: 12),
          _buildSwitchSetting(
            'Screen Reader Support',
            'Enables semantic labels for screen readers',
            _settings.screenReaderEnabled,
            (value) => _updateSettings(_settings.copyWith(screenReaderEnabled: value)),
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            'Auto-Read Dialogue',
            'Automatically reads dialogue text aloud',
            _settings.autoReadDialogue,
            (value) => _updateSettings(_settings.copyWith(autoReadDialogue: value)),
          ),
          if (_settings.autoReadDialogue) ...[
            const SizedBox(height: 16),
            _buildSpeechRateSlider(),
            const SizedBox(height: 16),
            _buildSpeechPitchSlider(),
          ],
          
          const SizedBox(height: 24),
          
          // Navigation section
          _buildSectionHeader('Navigation'),
          const SizedBox(height: 12),
          _buildSwitchSetting(
            'Keyboard Navigation',
            'Enables full keyboard control',
            _settings.keyboardNavigationEnabled,
            (value) => _updateSettings(_settings.copyWith(keyboardNavigationEnabled: value)),
          ),
          
          const SizedBox(height: 24),
          
          // Reset button
          Center(
            child: TextButton(
              onPressed: () {
                _updateSettings(const AccessibilitySettings());
              },
              child: Text(
                'Reset to Defaults',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _accentColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    final percentage = (_settings.fontSizeMultiplier * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: TextStyle(color: _textColor, fontSize: 14),
            ),
            Text(
              '$percentage%',
              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '50%',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: _accentColor.withOpacity(0.3),
                  thumbColor: _accentColor,
                  overlayColor: _accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _settings.fontSizeMultiplier,
                  min: AccessibilitySettings.minFontSizeMultiplier,
                  max: AccessibilitySettings.maxFontSizeMultiplier,
                  divisions: 15, // 0.1 increments
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(fontSizeMultiplier: value));
                  },
                ),
              ),
            ),
            Text(
              '200%',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
          ],
        ),
        // Preview text
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Preview Text',
              style: TextStyle(
                color: _textColor,
                fontSize: 14 * _settings.fontSizeMultiplier,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String label,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: _textColor, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: _secondaryTextColor, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _accentColor,
        ),
      ],
    );
  }

  Widget _buildColorBlindModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Blind Mode',
          style: TextStyle(color: _textColor, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Adjusts colors for color vision deficiency',
          style: TextStyle(color: _secondaryTextColor, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<ColorBlindMode>(
            value: _settings.colorBlindMode,
            isExpanded: true,
            dropdownColor: _backgroundColor,
            underline: const SizedBox(),
            style: TextStyle(color: _textColor, fontSize: 14),
            items: ColorBlindMode.values.map((mode) {
              return DropdownMenuItem<ColorBlindMode>(
                value: mode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mode.displayName),
                    if (mode != ColorBlindMode.none)
                      Text(
                        mode.description,
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateSettings(_settings.copyWith(colorBlindMode: value));
              }
            },
          ),
        ),
        // Color preview
        if (_settings.colorBlindMode != ColorBlindMode.none) ...[
          const SizedBox(height: 12),
          _buildColorPreview(),
        ],
      ],
    );
  }

  Widget _buildColorPreview() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Preview',
          style: TextStyle(color: _secondaryTextColor, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: colors.map((color) {
            final adjustedColor = _applyColorBlindFilter(color, _settings.colorBlindMode);
            return Expanded(
              child: Container(
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: adjustedColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeechRateSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Speech Rate',
              style: TextStyle(color: _textColor, fontSize: 14),
            ),
            Text(
              '${_settings.speechRate.toStringAsFixed(1)}x',
              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Slow',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: _accentColor.withOpacity(0.3),
                  thumbColor: _accentColor,
                  overlayColor: _accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _settings.speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(speechRate: value));
                  },
                ),
              ),
            ),
            Text(
              'Fast',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeechPitchSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Speech Pitch',
              style: TextStyle(color: _textColor, fontSize: 14),
            ),
            Text(
              '${_settings.speechPitch.toStringAsFixed(1)}x',
              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Low',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: _accentColor.withOpacity(0.3),
                  thumbColor: _accentColor,
                  overlayColor: _accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _settings.speechPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(speechPitch: value));
                  },
                ),
              ),
            ),
            Text(
              'High',
              style: TextStyle(color: _secondaryTextColor, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// Apply color blind filter (simplified version for preview)
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

  Color _simulateProtanopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
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

  Color _simulateDeuteranopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
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

  Color _simulateTritanopia(Color c) {
    final r = c.red / 255.0;
    final g = c.green / 255.0;
    final b = c.blue / 255.0;
    
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
}
