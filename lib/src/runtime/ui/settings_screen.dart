/// Settings Screen Widget
/// 
/// Provides settings controls for visual novels:
/// Text Speed, Auto Speed, BGM Volume, SFX Volume, Voice Volume, Fullscreen, Accessibility

import 'package:flutter/material.dart';

import '../accessibility/accessibility.dart';
import '../localization/vn_ui_strings.dart';

/// VN user settings data
class VNUserSettings {
  /// Text display speed (0.0 = instant, 1.0 = slowest)
  final double textSpeed;
  
  /// Auto-advance delay (seconds)
  final double autoSpeed;
  
  /// BGM volume (0.0 - 1.0)
  final double bgmVolume;
  
  /// SFX volume (0.0 - 1.0)
  final double sfxVolume;
  
  /// Voice volume (0.0 - 1.0)
  final double voiceVolume;
  
  /// Whether to skip unread text
  final bool skipUnread;
  
  /// Whether fullscreen is enabled
  final bool fullscreen;
  
  /// Current text/UI language code
  final String language;
  
  /// Voice language code (independent from text language)
  /// When null, uses the same language as text
  final String? voiceLanguage;
  
  /// Accessibility settings
  final AccessibilitySettings accessibility;

  const VNUserSettings({
    this.textSpeed = 0.5,
    this.autoSpeed = 2.0,
    this.bgmVolume = 0.8,
    this.sfxVolume = 0.8,
    this.voiceVolume = 1.0,
    this.skipUnread = false,
    this.fullscreen = false,
    this.language = 'en',
    this.voiceLanguage,
    this.accessibility = const AccessibilitySettings(),
  });

  /// Gets the effective voice language (falls back to text language if not set)
  String get effectiveVoiceLanguage => voiceLanguage ?? language;

  VNUserSettings copyWith({
    double? textSpeed,
    double? autoSpeed,
    double? bgmVolume,
    double? sfxVolume,
    double? voiceVolume,
    bool? skipUnread,
    bool? fullscreen,
    String? language,
    String? voiceLanguage,
    bool clearVoiceLanguage = false,
    AccessibilitySettings? accessibility,
  }) {
    return VNUserSettings(
      textSpeed: textSpeed ?? this.textSpeed,
      autoSpeed: autoSpeed ?? this.autoSpeed,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      skipUnread: skipUnread ?? this.skipUnread,
      fullscreen: fullscreen ?? this.fullscreen,
      language: language ?? this.language,
      voiceLanguage: clearVoiceLanguage ? null : (voiceLanguage ?? this.voiceLanguage),
      accessibility: accessibility ?? this.accessibility,
    );
  }

  Map<String, dynamic> toJson() => {
        'textSpeed': textSpeed,
        'autoSpeed': autoSpeed,
        'bgmVolume': bgmVolume,
        'sfxVolume': sfxVolume,
        'voiceVolume': voiceVolume,
        'skipUnread': skipUnread,
        'fullscreen': fullscreen,
        'language': language,
        if (voiceLanguage != null) 'voiceLanguage': voiceLanguage,
        'accessibility': accessibility.toJson(),
      };

  factory VNUserSettings.fromJson(Map<String, dynamic> json) {
    return VNUserSettings(
      textSpeed: (json['textSpeed'] as num?)?.toDouble() ?? 0.5,
      autoSpeed: (json['autoSpeed'] as num?)?.toDouble() ?? 2.0,
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 0.8,
      voiceVolume: (json['voiceVolume'] as num?)?.toDouble() ?? 1.0,
      skipUnread: json['skipUnread'] as bool? ?? false,
      fullscreen: json['fullscreen'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      voiceLanguage: json['voiceLanguage'] as String?,
      accessibility: json['accessibility'] != null
          ? AccessibilitySettings.fromJson(json['accessibility'] as Map<String, dynamic>)
          : const AccessibilitySettings(),
    );
  }
}

/// Configuration for the settings screen
class SettingsScreenConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Panel background color
  final Color panelBackgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Secondary text color
  final Color secondaryTextColor;
  
  /// Accent color (for sliders, switches)
  final Color accentColor;
  
  /// Title font size
  final double titleFontSize;
  
  /// Label font size
  final double labelFontSize;
  
  /// Section spacing
  final double sectionSpacing;
  
  /// Item spacing
  final double itemSpacing;

  const SettingsScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.titleFontSize = 28.0,
    this.labelFontSize = 16.0,
    this.sectionSpacing = 32.0,
    this.itemSpacing = 16.0,
  });
}

/// Settings screen widget
class SettingsScreen extends StatefulWidget {
  /// Current settings
  final VNUserSettings settings;
  
  /// Callback when settings change
  final void Function(VNUserSettings settings)? onSettingsChanged;
  
  /// Callback when back is pressed
  final VoidCallback? onBack;
  
  /// Configuration
  final SettingsScreenConfig config;
  
  /// Available languages for text/UI
  final Map<String, String>? availableLanguages;
  
  /// Available languages for voice (if different from text languages)
  /// If null, uses availableLanguages
  final Map<String, String>? availableVoiceLanguages;
  
  /// Whether to show fullscreen option
  final bool showFullscreenOption;
  
  /// Whether to show language option
  final bool showLanguageOption;
  
  /// Whether to show voice language option (separate from text language)
  final bool showVoiceLanguageOption;
  
  /// Language code for UI localization
  final String languageCode;

  const SettingsScreen({
    super.key,
    required this.settings,
    this.onSettingsChanged,
    this.onBack,
    this.config = const SettingsScreenConfig(),
    this.availableLanguages,
    this.availableVoiceLanguages,
    this.showFullscreenOption = true,
    this.showLanguageOption = true,
    this.showVoiceLanguageOption = true,
    this.languageCode = 'en',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late VNUserSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  void _updateSettings(VNUserSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged?.call(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Settings content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text Settings
                        _buildSection(
                          VNUILocalizer.get('text', widget.languageCode),
                          [
                            _buildSliderSetting(
                              VNUILocalizer.get('textSpeed', widget.languageCode),
                              _settings.textSpeed,
                              (value) => _updateSettings(
                                _settings.copyWith(textSpeed: value),
                              ),
                              labels: [VNUILocalizer.get('fast', widget.languageCode), VNUILocalizer.get('slow', widget.languageCode)],
                            ),
                            _buildSliderSetting(
                              VNUILocalizer.get('autoSpeed', widget.languageCode),
                              _settings.autoSpeed / 5.0, // Normalize to 0-1
                              (value) => _updateSettings(
                                _settings.copyWith(autoSpeed: value * 5.0),
                              ),
                              labels: [VNUILocalizer.get('fast', widget.languageCode), VNUILocalizer.get('slow', widget.languageCode)],
                              valueLabel: '${_settings.autoSpeed.toStringAsFixed(1)}s',
                            ),
                            _buildSwitchSetting(
                              VNUILocalizer.get('skipUnreadText', widget.languageCode),
                              _settings.skipUnread,
                              (value) => _updateSettings(
                                _settings.copyWith(skipUnread: value),
                              ),
                              subtitle: VNUILocalizer.get('allowSkipUnread', widget.languageCode),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: widget.config.sectionSpacing),
                        
                        // Audio Settings
                        _buildSection(
                          VNUILocalizer.get('audio', widget.languageCode),
                          [
                            _buildSliderSetting(
                              VNUILocalizer.get('bgmVolume', widget.languageCode),
                              _settings.bgmVolume,
                              (value) => _updateSettings(
                                _settings.copyWith(bgmVolume: value),
                              ),
                              valueLabel: '${(_settings.bgmVolume * 100).round()}%',
                            ),
                            _buildSliderSetting(
                              VNUILocalizer.get('sfxVolume', widget.languageCode),
                              _settings.sfxVolume,
                              (value) => _updateSettings(
                                _settings.copyWith(sfxVolume: value),
                              ),
                              valueLabel: '${(_settings.sfxVolume * 100).round()}%',
                            ),
                            _buildSliderSetting(
                              VNUILocalizer.get('voiceVolume', widget.languageCode),
                              _settings.voiceVolume,
                              (value) => _updateSettings(
                                _settings.copyWith(voiceVolume: value),
                              ),
                              valueLabel: '${(_settings.voiceVolume * 100).round()}%',
                            ),
                          ],
                        ),
                        
                        SizedBox(height: widget.config.sectionSpacing),
                        
                        // Display Settings
                        _buildSection(
                          VNUILocalizer.get('display', widget.languageCode),
                          [
                            if (widget.showFullscreenOption)
                              _buildSwitchSetting(
                                VNUILocalizer.get('fullscreen', widget.languageCode),
                                _settings.fullscreen,
                                (value) => _updateSettings(
                                  _settings.copyWith(fullscreen: value),
                                ),
                              ),
                            if (widget.showLanguageOption &&
                                widget.availableLanguages != null &&
                                widget.availableLanguages!.isNotEmpty)
                              _buildDropdownSetting(
                                VNUILocalizer.get('textLanguage', widget.languageCode),
                                _settings.language,
                                widget.availableLanguages!,
                                (value) => _updateSettings(
                                  _settings.copyWith(language: value),
                                ),
                              ),
                            if (widget.showVoiceLanguageOption &&
                                _getVoiceLanguages().isNotEmpty)
                              _buildVoiceLanguageSelector(),
                          ],
                        ),
                        
                        SizedBox(height: widget.config.sectionSpacing),
                        
                        // Accessibility Settings (Requirements 10.7)
                        _buildAccessibilitySection(),
                        
                        SizedBox(height: widget.config.sectionSpacing),
                        
                        // Reset button
                        Center(
                          child: TextButton(
                            onPressed: () {
                              _updateSettings(const VNUserSettings());
                            },
                            child: Text(
                              VNUILocalizer.get('resetToDefaults', widget.languageCode),
                              style: TextStyle(
                                color: widget.config.secondaryTextColor,
                                fontSize: widget.config.labelFontSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: widget.config.textColor,
            ),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Text(
            VNUILocalizer.get('settings', widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: widget.config.accentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.config.panelBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children
                .expand((w) => [w, SizedBox(height: widget.config.itemSpacing)])
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    void Function(double) onChanged, {
    List<String>? labels,
    String? valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.labelFontSize,
              ),
            ),
            if (valueLabel != null)
              Text(
                valueLabel,
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: widget.config.labelFontSize - 2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (labels != null && labels.isNotEmpty)
              Text(
                labels[0],
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: widget.config.accentColor,
                  inactiveTrackColor: widget.config.accentColor.withOpacity(0.3),
                  thumbColor: widget.config.accentColor,
                  overlayColor: widget.config.accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  onChanged: onChanged,
                ),
              ),
            ),
            if (labels != null && labels.length > 1)
              Text(
                labels[1],
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String label,
    bool value,
    void Function(bool) onChanged, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: widget.config.labelFontSize,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: widget.config.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: widget.config.accentColor,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    Map<String, String> options,
    void Function(String) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.labelFontSize,
            ),
          ),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: widget.config.panelBackgroundColor,
          style: TextStyle(
            color: widget.config.textColor,
            fontSize: widget.config.labelFontSize,
          ),
          underline: Container(
            height: 1,
            color: widget.config.accentColor,
          ),
          items: options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  /// Gets available voice languages (uses availableVoiceLanguages if set, otherwise availableLanguages)
  Map<String, String> _getVoiceLanguages() {
    return widget.availableVoiceLanguages ?? widget.availableLanguages ?? {};
  }

  /// Builds the voice language selector with "Same as text" option
  Widget _buildVoiceLanguageSelector() {
    final voiceLanguages = _getVoiceLanguages();
    final currentVoiceLanguage = _settings.voiceLanguage;
    
    // Build options with "Same as text" as first option
    final sameAsTextLabel = '${VNUILocalizer.get('sameAsText', widget.languageCode)} (${voiceLanguages[_settings.language] ?? _settings.language})';
    final options = <String, String>{
      '': sameAsTextLabel,
      ...voiceLanguages,
    };
    
    // Determine the current selection value
    final selectedValue = currentVoiceLanguage ?? '';
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                VNUILocalizer.get('voiceLanguage', widget.languageCode),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: widget.config.labelFontSize,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                VNUILocalizer.get('chooseVoiceLang', widget.languageCode),
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: selectedValue,
          dropdownColor: widget.config.panelBackgroundColor,
          style: TextStyle(
            color: widget.config.textColor,
            fontSize: widget.config.labelFontSize,
          ),
          underline: Container(
            height: 1,
            color: widget.config.accentColor,
          ),
          items: options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: widget.config.labelFontSize,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              if (newValue.isEmpty) {
                // "Same as text" selected - clear voice language
                _updateSettings(_settings.copyWith(clearVoiceLanguage: true));
              } else {
                _updateSettings(_settings.copyWith(voiceLanguage: newValue));
              }
            }
          },
        ),
      ],
    );
  }

  /// Builds the accessibility settings section (Requirements 10.7)
  Widget _buildAccessibilitySection() {
    return _buildSection(
      VNUILocalizer.get('accessibility', widget.languageCode),
      [
        // Font Size
        _buildFontSizeSlider(),
        // High Contrast Mode
        _buildSwitchSetting(
          VNUILocalizer.get('highContrastMode', widget.languageCode),
          _settings.accessibility.highContrastMode,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(highContrastMode: value),
            ),
          ),
          subtitle: VNUILocalizer.get('highContrastDesc', widget.languageCode),
        ),
        // Dyslexia-Friendly Font
        _buildSwitchSetting(
          VNUILocalizer.get('dyslexiaFriendlyFont', widget.languageCode),
          _settings.accessibility.dyslexiaFriendlyFont,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(dyslexiaFriendlyFont: value),
            ),
          ),
          subtitle: VNUILocalizer.get('dyslexiaFontDesc', widget.languageCode),
        ),
        // Color Blind Mode
        _buildColorBlindModeSelector(),
        // Reduce Motion
        _buildSwitchSetting(
          VNUILocalizer.get('reduceMotion', widget.languageCode),
          _settings.accessibility.reduceMotion,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(reduceMotion: value),
            ),
          ),
          subtitle: VNUILocalizer.get('reduceMotionDesc', widget.languageCode),
        ),
        // Screen Reader Support
        _buildSwitchSetting(
          VNUILocalizer.get('screenReaderSupport', widget.languageCode),
          _settings.accessibility.screenReaderEnabled,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(screenReaderEnabled: value),
            ),
          ),
          subtitle: VNUILocalizer.get('screenReaderDesc', widget.languageCode),
        ),
        // Auto-Read Dialogue
        _buildSwitchSetting(
          VNUILocalizer.get('autoReadDialogue', widget.languageCode),
          _settings.accessibility.autoReadDialogue,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(autoReadDialogue: value),
            ),
          ),
          subtitle: VNUILocalizer.get('autoReadDesc', widget.languageCode),
        ),
        // Keyboard Navigation
        _buildSwitchSetting(
          VNUILocalizer.get('keyboardNavigation', widget.languageCode),
          _settings.accessibility.keyboardNavigationEnabled,
          (value) => _updateSettings(
            _settings.copyWith(
              accessibility: _settings.accessibility.copyWith(keyboardNavigationEnabled: value),
            ),
          ),
          subtitle: VNUILocalizer.get('keyboardNavDesc', widget.languageCode),
        ),
      ],
    );
  }

  /// Builds the font size slider for accessibility
  Widget _buildFontSizeSlider() {
    final percentage = (_settings.accessibility.fontSizeMultiplier * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              VNUILocalizer.get('fontSize', widget.languageCode),
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.labelFontSize,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: widget.config.labelFontSize - 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '50%',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: widget.config.accentColor,
                  inactiveTrackColor: widget.config.accentColor.withOpacity(0.3),
                  thumbColor: widget.config.accentColor,
                  overlayColor: widget.config.accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _settings.accessibility.fontSizeMultiplier,
                  min: AccessibilitySettings.minFontSizeMultiplier,
                  max: AccessibilitySettings.maxFontSizeMultiplier,
                  divisions: 15,
                  onChanged: (value) {
                    _updateSettings(
                      _settings.copyWith(
                        accessibility: _settings.accessibility.copyWith(fontSizeMultiplier: value),
                      ),
                    );
                  },
                ),
              ),
            ),
            Text(
              '200%',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        // Preview text
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              VNUILocalizer.get('previewText', widget.languageCode),
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: 14 * _settings.accessibility.fontSizeMultiplier,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the color blind mode selector
  Widget _buildColorBlindModeSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                VNUILocalizer.get('colorBlindMode', widget.languageCode),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: widget.config.labelFontSize,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                VNUILocalizer.get('colorBlindDesc', widget.languageCode),
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DropdownButton<ColorBlindMode>(
          value: _settings.accessibility.colorBlindMode,
          dropdownColor: widget.config.panelBackgroundColor,
          style: TextStyle(
            color: widget.config.textColor,
            fontSize: widget.config.labelFontSize,
          ),
          underline: Container(
            height: 1,
            color: widget.config.accentColor,
          ),
          items: ColorBlindMode.values.map((mode) {
            return DropdownMenuItem<ColorBlindMode>(
              value: mode,
              child: Text(mode.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _updateSettings(
                _settings.copyWith(
                  accessibility: _settings.accessibility.copyWith(colorBlindMode: value),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
