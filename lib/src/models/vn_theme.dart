import 'dart:ui';

/// Theme preset type for categorization
enum VNThemePreset {
  modern,
  classic,
  fantasy,
  sciFi,
  horror,
  romance,
  custom,
}

/// UI theme for the visual novel runtime
class VNTheme {
  /// Theme name
  final String name;

  /// Theme preset type
  final VNThemePreset preset;

  /// Primary color
  final Color primaryColor;

  /// Secondary color
  final Color secondaryColor;

  /// Accent color
  final Color accentColor;

  /// Background color
  final Color backgroundColor;

  /// Text color
  final Color textColor;

  /// Dialogue box background color
  final Color dialogueBoxColor;

  /// Dialogue box opacity
  final double dialogueBoxOpacity;

  /// Dialogue box border color
  final Color dialogueBoxBorderColor;

  /// Dialogue box border width
  final double dialogueBoxBorderWidth;

  /// Dialogue box border radius
  final double dialogueBoxBorderRadius;

  /// Name plate color
  final Color namePlateColor;

  /// Name plate text color
  final Color namePlateTextColor;

  /// Choice button color
  final Color choiceButtonColor;

  /// Choice button hover color
  final Color choiceButtonHoverColor;

  /// Choice button text color
  final Color choiceButtonTextColor;

  /// Choice button border color
  final Color choiceButtonBorderColor;

  /// Menu background color
  final Color menuBackgroundColor;

  /// Menu text color
  final Color menuTextColor;

  /// Menu highlight color
  final Color menuHighlightColor;

  /// Font family for dialogue text
  final String dialogueFontFamily;

  /// Font size for dialogue text
  final double dialogueFontSize;

  /// Font weight for dialogue text
  final int dialogueFontWeight;

  /// Line height for dialogue text
  final double dialogueLineHeight;

  /// Font family for name plate
  final String nameFontFamily;

  /// Font size for name plate
  final double nameFontSize;

  /// Font weight for name plate
  final int nameFontWeight;

  /// Font family for menu text
  final String menuFontFamily;

  /// Font size for menu text
  final double menuFontSize;

  /// Custom textbox image path
  final String? textboxImagePath;

  /// Custom name plate image path
  final String? namePlateImagePath;

  /// Custom choice button image path
  final String? choiceButtonImagePath;

  /// Custom menu background image path
  final String? menuBackgroundImagePath;

  /// Custom save slot image path
  final String? saveSlotImagePath;

  /// Custom cursor image path
  final String? cursorImagePath;

  /// Click indicator animation type
  final String clickIndicatorType;

  /// Text animation speed multiplier
  final double textAnimationSpeed;

  /// Enable text shadow
  final bool enableTextShadow;

  /// Text shadow color
  final Color textShadowColor;

  /// Text shadow offset
  final double textShadowOffset;

  const VNTheme({
    this.name = 'Default',
    this.preset = VNThemePreset.modern,
    this.primaryColor = const Color(0xFF6200EE),
    this.secondaryColor = const Color(0xFF03DAC6),
    this.accentColor = const Color(0xFFBB86FC),
    this.backgroundColor = const Color(0xFF121212),
    this.textColor = const Color(0xFFFFFFFF),
    this.dialogueBoxColor = const Color(0xFF1E1E1E),
    this.dialogueBoxOpacity = 0.85,
    this.dialogueBoxBorderColor = const Color(0xFF3C3C3C),
    this.dialogueBoxBorderWidth = 1.0,
    this.dialogueBoxBorderRadius = 8.0,
    this.namePlateColor = const Color(0xFF2D2D2D),
    this.namePlateTextColor = const Color(0xFFFFFFFF),
    this.choiceButtonColor = const Color(0xFF3700B3),
    this.choiceButtonHoverColor = const Color(0xFF6200EE),
    this.choiceButtonTextColor = const Color(0xFFFFFFFF),
    this.choiceButtonBorderColor = const Color(0xFF6200EE),
    this.menuBackgroundColor = const Color(0xFF1A1A1A),
    this.menuTextColor = const Color(0xFFFFFFFF),
    this.menuHighlightColor = const Color(0xFF6200EE),
    this.dialogueFontFamily = 'Roboto',
    this.dialogueFontSize = 24.0,
    this.dialogueFontWeight = 400,
    this.dialogueLineHeight = 1.5,
    this.nameFontFamily = 'Roboto',
    this.nameFontSize = 20.0,
    this.nameFontWeight = 600,
    this.menuFontFamily = 'Roboto',
    this.menuFontSize = 18.0,
    this.textboxImagePath,
    this.namePlateImagePath,
    this.choiceButtonImagePath,
    this.menuBackgroundImagePath,
    this.saveSlotImagePath,
    this.cursorImagePath,
    this.clickIndicatorType = 'arrow',
    this.textAnimationSpeed = 1.0,
    this.enableTextShadow = false,
    this.textShadowColor = const Color(0x80000000),
    this.textShadowOffset = 2.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'preset': preset.name,
        'primaryColor': primaryColor.value,
        'secondaryColor': secondaryColor.value,
        'accentColor': accentColor.value,
        'backgroundColor': backgroundColor.value,
        'textColor': textColor.value,
        'dialogueBoxColor': dialogueBoxColor.value,
        'dialogueBoxOpacity': dialogueBoxOpacity,
        'dialogueBoxBorderColor': dialogueBoxBorderColor.value,
        'dialogueBoxBorderWidth': dialogueBoxBorderWidth,
        'dialogueBoxBorderRadius': dialogueBoxBorderRadius,
        'namePlateColor': namePlateColor.value,
        'namePlateTextColor': namePlateTextColor.value,
        'choiceButtonColor': choiceButtonColor.value,
        'choiceButtonHoverColor': choiceButtonHoverColor.value,
        'choiceButtonTextColor': choiceButtonTextColor.value,
        'choiceButtonBorderColor': choiceButtonBorderColor.value,
        'menuBackgroundColor': menuBackgroundColor.value,
        'menuTextColor': menuTextColor.value,
        'menuHighlightColor': menuHighlightColor.value,
        'dialogueFontFamily': dialogueFontFamily,
        'dialogueFontSize': dialogueFontSize,
        'dialogueFontWeight': dialogueFontWeight,
        'dialogueLineHeight': dialogueLineHeight,
        'nameFontFamily': nameFontFamily,
        'nameFontSize': nameFontSize,
        'nameFontWeight': nameFontWeight,
        'menuFontFamily': menuFontFamily,
        'menuFontSize': menuFontSize,
        if (textboxImagePath != null) 'textboxImagePath': textboxImagePath,
        if (namePlateImagePath != null) 'namePlateImagePath': namePlateImagePath,
        if (choiceButtonImagePath != null) 'choiceButtonImagePath': choiceButtonImagePath,
        if (menuBackgroundImagePath != null) 'menuBackgroundImagePath': menuBackgroundImagePath,
        if (saveSlotImagePath != null) 'saveSlotImagePath': saveSlotImagePath,
        if (cursorImagePath != null) 'cursorImagePath': cursorImagePath,
        'clickIndicatorType': clickIndicatorType,
        'textAnimationSpeed': textAnimationSpeed,
        'enableTextShadow': enableTextShadow,
        'textShadowColor': textShadowColor.value,
        'textShadowOffset': textShadowOffset,
      };

  factory VNTheme.fromJson(Map<String, dynamic> json) {
    return VNTheme(
      name: json['name'] as String? ?? 'Default',
      preset: VNThemePreset.values.firstWhere(
        (e) => e.name == json['preset'],
        orElse: () => VNThemePreset.custom,
      ),
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF6200EE),
      secondaryColor: Color(json['secondaryColor'] as int? ?? 0xFF03DAC6),
      accentColor: Color(json['accentColor'] as int? ?? 0xFFBB86FC),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFF121212),
      textColor: Color(json['textColor'] as int? ?? 0xFFFFFFFF),
      dialogueBoxColor: Color(json['dialogueBoxColor'] as int? ?? 0xFF1E1E1E),
      dialogueBoxOpacity: (json['dialogueBoxOpacity'] as num?)?.toDouble() ?? 0.85,
      dialogueBoxBorderColor: Color(json['dialogueBoxBorderColor'] as int? ?? 0xFF3C3C3C),
      dialogueBoxBorderWidth: (json['dialogueBoxBorderWidth'] as num?)?.toDouble() ?? 1.0,
      dialogueBoxBorderRadius: (json['dialogueBoxBorderRadius'] as num?)?.toDouble() ?? 8.0,
      namePlateColor: Color(json['namePlateColor'] as int? ?? 0xFF2D2D2D),
      namePlateTextColor: Color(json['namePlateTextColor'] as int? ?? 0xFFFFFFFF),
      choiceButtonColor: Color(json['choiceButtonColor'] as int? ?? 0xFF3700B3),
      choiceButtonHoverColor: Color(json['choiceButtonHoverColor'] as int? ?? 0xFF6200EE),
      choiceButtonTextColor: Color(json['choiceButtonTextColor'] as int? ?? 0xFFFFFFFF),
      choiceButtonBorderColor: Color(json['choiceButtonBorderColor'] as int? ?? 0xFF6200EE),
      menuBackgroundColor: Color(json['menuBackgroundColor'] as int? ?? 0xFF1A1A1A),
      menuTextColor: Color(json['menuTextColor'] as int? ?? 0xFFFFFFFF),
      menuHighlightColor: Color(json['menuHighlightColor'] as int? ?? 0xFF6200EE),
      dialogueFontFamily: json['dialogueFontFamily'] as String? ?? 'Roboto',
      dialogueFontSize: (json['dialogueFontSize'] as num?)?.toDouble() ?? 24.0,
      dialogueFontWeight: json['dialogueFontWeight'] as int? ?? 400,
      dialogueLineHeight: (json['dialogueLineHeight'] as num?)?.toDouble() ?? 1.5,
      nameFontFamily: json['nameFontFamily'] as String? ?? 'Roboto',
      nameFontSize: (json['nameFontSize'] as num?)?.toDouble() ?? 20.0,
      nameFontWeight: json['nameFontWeight'] as int? ?? 600,
      menuFontFamily: json['menuFontFamily'] as String? ?? 'Roboto',
      menuFontSize: (json['menuFontSize'] as num?)?.toDouble() ?? 18.0,
      textboxImagePath: json['textboxImagePath'] as String?,
      namePlateImagePath: json['namePlateImagePath'] as String?,
      choiceButtonImagePath: json['choiceButtonImagePath'] as String?,
      menuBackgroundImagePath: json['menuBackgroundImagePath'] as String?,
      saveSlotImagePath: json['saveSlotImagePath'] as String?,
      cursorImagePath: json['cursorImagePath'] as String?,
      clickIndicatorType: json['clickIndicatorType'] as String? ?? 'arrow',
      textAnimationSpeed: (json['textAnimationSpeed'] as num?)?.toDouble() ?? 1.0,
      enableTextShadow: json['enableTextShadow'] as bool? ?? false,
      textShadowColor: Color(json['textShadowColor'] as int? ?? 0x80000000),
      textShadowOffset: (json['textShadowOffset'] as num?)?.toDouble() ?? 2.0,
    );
  }

  VNTheme copyWith({
    String? name,
    VNThemePreset? preset,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? textColor,
    Color? dialogueBoxColor,
    double? dialogueBoxOpacity,
    Color? dialogueBoxBorderColor,
    double? dialogueBoxBorderWidth,
    double? dialogueBoxBorderRadius,
    Color? namePlateColor,
    Color? namePlateTextColor,
    Color? choiceButtonColor,
    Color? choiceButtonHoverColor,
    Color? choiceButtonTextColor,
    Color? choiceButtonBorderColor,
    Color? menuBackgroundColor,
    Color? menuTextColor,
    Color? menuHighlightColor,
    String? dialogueFontFamily,
    double? dialogueFontSize,
    int? dialogueFontWeight,
    double? dialogueLineHeight,
    String? nameFontFamily,
    double? nameFontSize,
    int? nameFontWeight,
    String? menuFontFamily,
    double? menuFontSize,
    String? textboxImagePath,
    String? namePlateImagePath,
    String? choiceButtonImagePath,
    String? menuBackgroundImagePath,
    String? saveSlotImagePath,
    String? cursorImagePath,
    String? clickIndicatorType,
    double? textAnimationSpeed,
    bool? enableTextShadow,
    Color? textShadowColor,
    double? textShadowOffset,
  }) {
    return VNTheme(
      name: name ?? this.name,
      preset: preset ?? VNThemePreset.custom,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      dialogueBoxColor: dialogueBoxColor ?? this.dialogueBoxColor,
      dialogueBoxOpacity: dialogueBoxOpacity ?? this.dialogueBoxOpacity,
      dialogueBoxBorderColor: dialogueBoxBorderColor ?? this.dialogueBoxBorderColor,
      dialogueBoxBorderWidth: dialogueBoxBorderWidth ?? this.dialogueBoxBorderWidth,
      dialogueBoxBorderRadius: dialogueBoxBorderRadius ?? this.dialogueBoxBorderRadius,
      namePlateColor: namePlateColor ?? this.namePlateColor,
      namePlateTextColor: namePlateTextColor ?? this.namePlateTextColor,
      choiceButtonColor: choiceButtonColor ?? this.choiceButtonColor,
      choiceButtonHoverColor: choiceButtonHoverColor ?? this.choiceButtonHoverColor,
      choiceButtonTextColor: choiceButtonTextColor ?? this.choiceButtonTextColor,
      choiceButtonBorderColor: choiceButtonBorderColor ?? this.choiceButtonBorderColor,
      menuBackgroundColor: menuBackgroundColor ?? this.menuBackgroundColor,
      menuTextColor: menuTextColor ?? this.menuTextColor,
      menuHighlightColor: menuHighlightColor ?? this.menuHighlightColor,
      dialogueFontFamily: dialogueFontFamily ?? this.dialogueFontFamily,
      dialogueFontSize: dialogueFontSize ?? this.dialogueFontSize,
      dialogueFontWeight: dialogueFontWeight ?? this.dialogueFontWeight,
      dialogueLineHeight: dialogueLineHeight ?? this.dialogueLineHeight,
      nameFontFamily: nameFontFamily ?? this.nameFontFamily,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      nameFontWeight: nameFontWeight ?? this.nameFontWeight,
      menuFontFamily: menuFontFamily ?? this.menuFontFamily,
      menuFontSize: menuFontSize ?? this.menuFontSize,
      textboxImagePath: textboxImagePath ?? this.textboxImagePath,
      namePlateImagePath: namePlateImagePath ?? this.namePlateImagePath,
      choiceButtonImagePath: choiceButtonImagePath ?? this.choiceButtonImagePath,
      menuBackgroundImagePath: menuBackgroundImagePath ?? this.menuBackgroundImagePath,
      saveSlotImagePath: saveSlotImagePath ?? this.saveSlotImagePath,
      cursorImagePath: cursorImagePath ?? this.cursorImagePath,
      clickIndicatorType: clickIndicatorType ?? this.clickIndicatorType,
      textAnimationSpeed: textAnimationSpeed ?? this.textAnimationSpeed,
      enableTextShadow: enableTextShadow ?? this.enableTextShadow,
      textShadowColor: textShadowColor ?? this.textShadowColor,
      textShadowOffset: textShadowOffset ?? this.textShadowOffset,
    );
  }

  /// Preset themes
  static const modern = VNTheme(
    name: 'Modern',
    preset: VNThemePreset.modern,
    primaryColor: Color(0xFF6200EE),
    secondaryColor: Color(0xFF03DAC6),
    accentColor: Color(0xFFBB86FC),
    backgroundColor: Color(0xFF121212),
    textColor: Color(0xFFFFFFFF),
    dialogueBoxColor: Color(0xFF1E1E1E),
    dialogueBoxOpacity: 0.9,
    dialogueBoxBorderColor: Color(0xFF3C3C3C),
    dialogueBoxBorderRadius: 12.0,
    namePlateColor: Color(0xFF6200EE),
    namePlateTextColor: Color(0xFFFFFFFF),
    choiceButtonColor: Color(0xFF3700B3),
    choiceButtonHoverColor: Color(0xFF6200EE),
    menuBackgroundColor: Color(0xFF1A1A1A),
    menuHighlightColor: Color(0xFF6200EE),
  );

  static const classic = VNTheme(
    name: 'Classic',
    preset: VNThemePreset.classic,
    primaryColor: Color(0xFF8B4513),
    secondaryColor: Color(0xFFD2691E),
    accentColor: Color(0xFFCD853F),
    backgroundColor: Color(0xFF2F1810),
    textColor: Color(0xFFF5DEB3),
    dialogueBoxColor: Color(0xFF3D2314),
    dialogueBoxOpacity: 0.95,
    dialogueBoxBorderColor: Color(0xFF8B4513),
    dialogueBoxBorderWidth: 2.0,
    dialogueBoxBorderRadius: 4.0,
    namePlateColor: Color(0xFF5D3A1A),
    namePlateTextColor: Color(0xFFF5DEB3),
    choiceButtonColor: Color(0xFF5D3A1A),
    choiceButtonHoverColor: Color(0xFF8B4513),
    choiceButtonTextColor: Color(0xFFF5DEB3),
    menuBackgroundColor: Color(0xFF2F1810),
    menuTextColor: Color(0xFFF5DEB3),
    menuHighlightColor: Color(0xFF8B4513),
    dialogueFontFamily: 'Merriweather',
    nameFontFamily: 'Merriweather',
    enableTextShadow: true,
    textShadowColor: Color(0x60000000),
  );

  static const fantasy = VNTheme(
    name: 'Fantasy',
    preset: VNThemePreset.fantasy,
    primaryColor: Color(0xFF9B59B6),
    secondaryColor: Color(0xFFE74C3C),
    accentColor: Color(0xFFF39C12),
    backgroundColor: Color(0xFF1A1A2E),
    textColor: Color(0xFFECF0F1),
    dialogueBoxColor: Color(0xFF16213E),
    dialogueBoxOpacity: 0.88,
    dialogueBoxBorderColor: Color(0xFF9B59B6),
    dialogueBoxBorderWidth: 2.0,
    dialogueBoxBorderRadius: 16.0,
    namePlateColor: Color(0xFF9B59B6),
    namePlateTextColor: Color(0xFFFFFFFF),
    choiceButtonColor: Color(0xFF2C3E50),
    choiceButtonHoverColor: Color(0xFF9B59B6),
    choiceButtonBorderColor: Color(0xFF9B59B6),
    menuBackgroundColor: Color(0xFF1A1A2E),
    menuHighlightColor: Color(0xFF9B59B6),
    dialogueFontFamily: 'Cinzel',
    nameFontFamily: 'Cinzel',
    enableTextShadow: true,
    textShadowColor: Color(0x809B59B6),
  );

  static const sciFi = VNTheme(
    name: 'Sci-Fi',
    preset: VNThemePreset.sciFi,
    primaryColor: Color(0xFF00D4FF),
    secondaryColor: Color(0xFF00FF88),
    accentColor: Color(0xFFFF00FF),
    backgroundColor: Color(0xFF0A0A0A),
    textColor: Color(0xFF00FF88),
    dialogueBoxColor: Color(0xFF0D1B2A),
    dialogueBoxOpacity: 0.85,
    dialogueBoxBorderColor: Color(0xFF00D4FF),
    dialogueBoxBorderWidth: 1.0,
    dialogueBoxBorderRadius: 0.0,
    namePlateColor: Color(0xFF00D4FF),
    namePlateTextColor: Color(0xFF0A0A0A),
    choiceButtonColor: Color(0xFF0D1B2A),
    choiceButtonHoverColor: Color(0xFF00D4FF),
    choiceButtonTextColor: Color(0xFF00FF88),
    choiceButtonBorderColor: Color(0xFF00D4FF),
    menuBackgroundColor: Color(0xFF0A0A0A),
    menuTextColor: Color(0xFF00FF88),
    menuHighlightColor: Color(0xFF00D4FF),
    dialogueFontFamily: 'Orbitron',
    nameFontFamily: 'Orbitron',
    menuFontFamily: 'Orbitron',
    enableTextShadow: true,
    textShadowColor: Color(0x8000D4FF),
    clickIndicatorType: 'pulse',
  );

  static const horror = VNTheme(
    name: 'Horror',
    preset: VNThemePreset.horror,
    primaryColor: Color(0xFF8B0000),
    secondaryColor: Color(0xFF4A0000),
    accentColor: Color(0xFFFF0000),
    backgroundColor: Color(0xFF0D0D0D),
    textColor: Color(0xFFB0B0B0),
    dialogueBoxColor: Color(0xFF1A0A0A),
    dialogueBoxOpacity: 0.92,
    dialogueBoxBorderColor: Color(0xFF4A0000),
    dialogueBoxBorderWidth: 1.0,
    dialogueBoxBorderRadius: 2.0,
    namePlateColor: Color(0xFF4A0000),
    namePlateTextColor: Color(0xFFB0B0B0),
    choiceButtonColor: Color(0xFF1A0A0A),
    choiceButtonHoverColor: Color(0xFF8B0000),
    choiceButtonTextColor: Color(0xFFB0B0B0),
    choiceButtonBorderColor: Color(0xFF4A0000),
    menuBackgroundColor: Color(0xFF0D0D0D),
    menuTextColor: Color(0xFFB0B0B0),
    menuHighlightColor: Color(0xFF8B0000),
    dialogueFontFamily: 'Creepster',
    nameFontFamily: 'Creepster',
    enableTextShadow: true,
    textShadowColor: Color(0xFF8B0000),
    textShadowOffset: 3.0,
    textAnimationSpeed: 0.8,
  );

  static const romance = VNTheme(
    name: 'Romance',
    preset: VNThemePreset.romance,
    primaryColor: Color(0xFFFF69B4),
    secondaryColor: Color(0xFFFFB6C1),
    accentColor: Color(0xFFFF1493),
    backgroundColor: Color(0xFFFFF0F5),
    textColor: Color(0xFF4A4A4A),
    dialogueBoxColor: Color(0xFFFFFFFF),
    dialogueBoxOpacity: 0.9,
    dialogueBoxBorderColor: Color(0xFFFFB6C1),
    dialogueBoxBorderWidth: 2.0,
    dialogueBoxBorderRadius: 20.0,
    namePlateColor: Color(0xFFFF69B4),
    namePlateTextColor: Color(0xFFFFFFFF),
    choiceButtonColor: Color(0xFFFFFFFF),
    choiceButtonHoverColor: Color(0xFFFF69B4),
    choiceButtonTextColor: Color(0xFF4A4A4A),
    choiceButtonBorderColor: Color(0xFFFF69B4),
    menuBackgroundColor: Color(0xFFFFF0F5),
    menuTextColor: Color(0xFF4A4A4A),
    menuHighlightColor: Color(0xFFFF69B4),
    dialogueFontFamily: 'Dancing Script',
    nameFontFamily: 'Pacifico',
    enableTextShadow: false,
    clickIndicatorType: 'heart',
  );

  /// Get all preset themes
  static List<VNTheme> get presets => [
        modern,
        classic,
        fantasy,
        sciFi,
        horror,
        romance,
      ];

  /// Get theme by preset type
  static VNTheme getPreset(VNThemePreset preset) {
    switch (preset) {
      case VNThemePreset.modern:
        return modern;
      case VNThemePreset.classic:
        return classic;
      case VNThemePreset.fantasy:
        return fantasy;
      case VNThemePreset.sciFi:
        return sciFi;
      case VNThemePreset.horror:
        return horror;
      case VNThemePreset.romance:
        return romance;
      case VNThemePreset.custom:
        return modern;
    }
  }

  /// Available font families for themes
  static const List<String> availableFonts = [
    'Roboto',
    'Merriweather',
    'Cinzel',
    'Orbitron',
    'Creepster',
    'Dancing Script',
    'Pacifico',
    'Noto Sans',
    'Noto Serif',
    'Source Code Pro',
    'Playfair Display',
    'Lora',
    'Open Sans',
    'Montserrat',
  ];

  /// Available click indicator types
  static const List<String> clickIndicatorTypes = [
    'arrow',
    'pulse',
    'heart',
    'bounce',
    'fade',
    'none',
  ];
}
