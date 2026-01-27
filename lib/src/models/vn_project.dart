import 'dart:ui';

import 'chapter.dart';
import 'vn_character.dart';
import 'vn_resource.dart';
import 'vn_variable.dart';
import 'vn_theme.dart';
import '../runtime/affection/affection.dart';

/// Background type for main menu
enum MenuBackgroundType {
  /// Static image
  image,
  /// Video (MP4/WebM)
  video,
  /// Solid color/gradient
  color,
}

/// Meta effect type for DDLC-style effects
enum MetaEffectType {
  none,
  /// Screen glitch effect
  glitch,
  /// Static noise overlay
  staticNoise,
  /// Screen tear effect
  screenTear,
  /// Color corruption
  colorCorruption,
  /// Text scramble
  textScramble,
  /// Fake window/error popup
  fakeError,
  /// Screen shake
  screenShake,
  /// Vignette pulse
  vignettePulse,
  /// Chromatic aberration
  chromaticAberration,
}

/// Individual button position for free layout mode
class MenuButtonPosition {
  final String buttonId;
  final double x; // 0.0-1.0 relative
  final double y; // 0.0-1.0 relative
  final double? width;
  final double? rotation; // degrees
  final double? scale;
  
  const MenuButtonPosition({
    required this.buttonId,
    required this.x,
    required this.y,
    this.width,
    this.rotation,
    this.scale,
  });
  
  Map<String, dynamic> toJson() => {
    'buttonId': buttonId,
    'x': x,
    'y': y,
    if (width != null) 'width': width,
    if (rotation != null) 'rotation': rotation,
    if (scale != null) 'scale': scale,
  };
  
  factory MenuButtonPosition.fromJson(Map<String, dynamic> json) {
    return MenuButtonPosition(
      buttonId: json['buttonId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
    );
  }
  
  MenuButtonPosition copyWith({
    String? buttonId,
    double? x,
    double? y,
    double? width,
    double? rotation,
    double? scale,
  }) {
    return MenuButtonPosition(
      buttonId: buttonId ?? this.buttonId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}

/// Main menu configuration for commercial-grade customization
class VNMainMenuConfig {
  /// Background type (image, video, color)
  final MenuBackgroundType backgroundType;
  
  /// Background image path (CG or custom background)
  final String? backgroundImage;
  
  /// Background video path (MP4/WebM)
  final String? backgroundVideo;
  
  /// Video loop setting
  final bool videoLoop;
  
  /// Video muted setting
  final bool videoMuted;
  
  /// Video playback speed (0.5-2.0)
  final double videoSpeed;
  
  /// Logo/title image path
  final String? logoImage;
  
  /// Logo position (0.0-1.0 relative coordinates)
  final double logoX;
  final double logoY;
  
  /// Logo scale
  final double logoScale;
  
  /// Title text (if no logo image)
  final String? titleText;
  
  /// Title position (0.0-1.0 relative coordinates)
  final double? titleX;
  final double? titleY;
  
  /// Menu buttons position (0.0-1.0 relative coordinates)
  final double? menuX;
  final double? menuY;
  
  /// Menu alignment (left, center, right)
  final String alignment;
  
  /// Button layout direction (vertical, horizontal, free)
  final String buttonLayout;
  
  /// Free layout button positions (only used when buttonLayout == 'free')
  final List<MenuButtonPosition> buttonPositions;
  
  /// Button width
  final double buttonWidth;
  
  /// Button spacing
  final double buttonSpacing;
  
  /// Button border radius
  final double buttonBorderRadius;
  
  /// Enable button shadow
  final bool enableButtonShadow;
  
  /// Custom button image (9-patch or regular)
  final String? buttonImage;
  
  /// Custom button hover image
  final String? buttonHoverImage;
  
  /// Background overlay opacity (0.0-1.0)
  final double backgroundOverlayOpacity;
  
  /// Version text position (bottomLeft, bottomRight, topLeft, topRight)
  final String versionPosition;
  
  // ==================== Animation Settings ====================
  
  /// Logo animation type (none, fadeIn, scaleIn, slideIn, pulse, float)
  final String logoAnimation;
  
  /// Logo animation duration in milliseconds
  final int logoAnimationDuration;
  
  /// Logo animation delay in milliseconds
  final int logoAnimationDelay;
  
  /// Button animation type (none, fadeIn, slideIn, stagger)
  final String buttonAnimation;
  
  /// Button animation stagger delay in milliseconds
  final int buttonStaggerDelay;
  
  /// Background animation type (none, parallax, slowZoom, ken_burns)
  final String backgroundAnimation;
  
  /// Background animation speed (0.1-2.0)
  final double backgroundAnimationSpeed;
  
  // ==================== Particle Effects ====================
  
  /// Enable particle effects on main menu
  final bool enableParticles;
  
  /// Particle preset name (sakura, snow, fireflies, stars, rain, leaves, dust)
  final String? particlePreset;
  
  /// Custom particle color (hex string)
  final String? particleColor;
  
  /// Particle density (0.1-2.0)
  final double particleDensity;
  
  // ==================== Audio Settings ====================
  
  /// Background music for main menu
  final String? menuBgm;
  
  /// Button hover sound effect
  final String? buttonHoverSfx;
  
  /// Button click sound effect
  final String? buttonClickSfx;
  
  // ==================== Meta Effects (DDLC-style) ====================
  
  /// Enable meta effects
  final bool enableMetaEffects;
  
  /// Meta effect type
  final MetaEffectType metaEffectType;
  
  /// Meta effect intensity (0.0-1.0)
  final double metaEffectIntensity;
  
  /// Meta effect trigger (always, random, onHover, afterDelay)
  final String metaEffectTrigger;
  
  /// Meta effect delay in milliseconds (for afterDelay trigger)
  final int metaEffectDelay;
  
  /// Random meta effect interval range (min-max ms)
  final int metaEffectRandomMin;
  final int metaEffectRandomMax;
  
  /// Fake error message text (for fakeError effect)
  final String? fakeErrorMessage;
  
  /// Fake error title (for fakeError effect)
  final String? fakeErrorTitle;

  const VNMainMenuConfig({
    this.backgroundType = MenuBackgroundType.image,
    this.backgroundImage,
    this.backgroundVideo,
    this.videoLoop = true,
    this.videoMuted = true,
    this.videoSpeed = 1.0,
    this.logoImage,
    this.logoX = 0.5,
    this.logoY = 0.2,
    this.logoScale = 1.0,
    this.titleText,
    this.titleX,
    this.titleY,
    this.menuX,
    this.menuY,
    this.alignment = 'center',
    this.buttonLayout = 'vertical',
    this.buttonPositions = const [],
    this.buttonWidth = 280.0,
    this.buttonSpacing = 16.0,
    this.buttonBorderRadius = 8.0,
    this.enableButtonShadow = false,
    this.buttonImage,
    this.buttonHoverImage,
    this.backgroundOverlayOpacity = 0.0,
    this.versionPosition = 'bottomRight',
    // Animation defaults
    this.logoAnimation = 'fadeIn',
    this.logoAnimationDuration = 1000,
    this.logoAnimationDelay = 500,
    this.buttonAnimation = 'stagger',
    this.buttonStaggerDelay = 100,
    this.backgroundAnimation = 'none',
    this.backgroundAnimationSpeed = 1.0,
    // Particle defaults
    this.enableParticles = false,
    this.particlePreset,
    this.particleColor,
    this.particleDensity = 1.0,
    // Audio defaults
    this.menuBgm,
    this.buttonHoverSfx,
    this.buttonClickSfx,
    // Meta effects defaults
    this.enableMetaEffects = false,
    this.metaEffectType = MetaEffectType.none,
    this.metaEffectIntensity = 0.5,
    this.metaEffectTrigger = 'random',
    this.metaEffectDelay = 5000,
    this.metaEffectRandomMin = 3000,
    this.metaEffectRandomMax = 10000,
    this.fakeErrorMessage,
    this.fakeErrorTitle,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'backgroundType': backgroundType.name,
      'videoLoop': videoLoop,
      'videoMuted': videoMuted,
      'videoSpeed': videoSpeed,
      'logoX': logoX,
      'logoY': logoY,
      'logoScale': logoScale,
      'alignment': alignment,
      'buttonLayout': buttonLayout,
      'buttonWidth': buttonWidth,
      'buttonSpacing': buttonSpacing,
      'buttonBorderRadius': buttonBorderRadius,
      'enableButtonShadow': enableButtonShadow,
      'backgroundOverlayOpacity': backgroundOverlayOpacity,
      'versionPosition': versionPosition,
      // Animation
      'logoAnimation': logoAnimation,
      'logoAnimationDuration': logoAnimationDuration,
      'logoAnimationDelay': logoAnimationDelay,
      'buttonAnimation': buttonAnimation,
      'buttonStaggerDelay': buttonStaggerDelay,
      'backgroundAnimation': backgroundAnimation,
      'backgroundAnimationSpeed': backgroundAnimationSpeed,
      // Particles
      'enableParticles': enableParticles,
      'particleDensity': particleDensity,
      // Meta effects
      'enableMetaEffects': enableMetaEffects,
      'metaEffectType': metaEffectType.name,
      'metaEffectIntensity': metaEffectIntensity,
      'metaEffectTrigger': metaEffectTrigger,
      'metaEffectDelay': metaEffectDelay,
      'metaEffectRandomMin': metaEffectRandomMin,
      'metaEffectRandomMax': metaEffectRandomMax,
    };
    if (backgroundImage != null) json['backgroundImage'] = backgroundImage;
    if (backgroundVideo != null) json['backgroundVideo'] = backgroundVideo;
    if (logoImage != null) json['logoImage'] = logoImage;
    if (titleText != null) json['titleText'] = titleText;
    if (titleX != null) json['titleX'] = titleX;
    if (titleY != null) json['titleY'] = titleY;
    if (menuX != null) json['menuX'] = menuX;
    if (menuY != null) json['menuY'] = menuY;
    if (buttonPositions.isNotEmpty) {
      json['buttonPositions'] = buttonPositions.map((p) => p.toJson()).toList();
    }
    if (buttonImage != null) json['buttonImage'] = buttonImage;
    if (buttonHoverImage != null) json['buttonHoverImage'] = buttonHoverImage;
    if (particlePreset != null) json['particlePreset'] = particlePreset;
    if (particleColor != null) json['particleColor'] = particleColor;
    if (menuBgm != null) json['menuBgm'] = menuBgm;
    if (buttonHoverSfx != null) json['buttonHoverSfx'] = buttonHoverSfx;
    if (buttonClickSfx != null) json['buttonClickSfx'] = buttonClickSfx;
    if (fakeErrorMessage != null) json['fakeErrorMessage'] = fakeErrorMessage;
    if (fakeErrorTitle != null) json['fakeErrorTitle'] = fakeErrorTitle;
    return json;
  }

  factory VNMainMenuConfig.fromJson(Map<String, dynamic> json) {
    return VNMainMenuConfig(
      backgroundType: MenuBackgroundType.values.firstWhere(
        (e) => e.name == json['backgroundType'],
        orElse: () => MenuBackgroundType.image,
      ),
      backgroundImage: json['backgroundImage'] as String?,
      backgroundVideo: json['backgroundVideo'] as String?,
      videoLoop: json['videoLoop'] as bool? ?? true,
      videoMuted: json['videoMuted'] as bool? ?? true,
      videoSpeed: (json['videoSpeed'] as num?)?.toDouble() ?? 1.0,
      logoImage: json['logoImage'] as String?,
      logoX: (json['logoX'] as num?)?.toDouble() ?? 0.5,
      logoY: (json['logoY'] as num?)?.toDouble() ?? 0.2,
      logoScale: (json['logoScale'] as num?)?.toDouble() ?? 1.0,
      titleText: json['titleText'] as String?,
      titleX: (json['titleX'] as num?)?.toDouble(),
      titleY: (json['titleY'] as num?)?.toDouble(),
      menuX: (json['menuX'] as num?)?.toDouble(),
      menuY: (json['menuY'] as num?)?.toDouble(),
      alignment: json['alignment'] as String? ?? 'center',
      buttonLayout: json['buttonLayout'] as String? ?? 'vertical',
      buttonPositions: (json['buttonPositions'] as List<dynamic>?)
          ?.map((p) => MenuButtonPosition.fromJson(p as Map<String, dynamic>))
          .toList() ?? const [],
      buttonWidth: (json['buttonWidth'] as num?)?.toDouble() ?? 280.0,
      buttonSpacing: (json['buttonSpacing'] as num?)?.toDouble() ?? 16.0,
      buttonBorderRadius: (json['buttonBorderRadius'] as num?)?.toDouble() ?? 8.0,
      enableButtonShadow: json['enableButtonShadow'] as bool? ?? false,
      buttonImage: json['buttonImage'] as String?,
      buttonHoverImage: json['buttonHoverImage'] as String?,
      backgroundOverlayOpacity: (json['backgroundOverlayOpacity'] as num?)?.toDouble() ?? 0.0,
      versionPosition: json['versionPosition'] as String? ?? 'bottomRight',
      // Animation
      logoAnimation: json['logoAnimation'] as String? ?? 'fadeIn',
      logoAnimationDuration: json['logoAnimationDuration'] as int? ?? 1000,
      logoAnimationDelay: json['logoAnimationDelay'] as int? ?? 500,
      buttonAnimation: json['buttonAnimation'] as String? ?? 'stagger',
      buttonStaggerDelay: json['buttonStaggerDelay'] as int? ?? 100,
      backgroundAnimation: json['backgroundAnimation'] as String? ?? 'none',
      backgroundAnimationSpeed: (json['backgroundAnimationSpeed'] as num?)?.toDouble() ?? 1.0,
      // Particles
      enableParticles: json['enableParticles'] as bool? ?? false,
      particlePreset: json['particlePreset'] as String?,
      particleColor: json['particleColor'] as String?,
      particleDensity: (json['particleDensity'] as num?)?.toDouble() ?? 1.0,
      // Audio
      menuBgm: json['menuBgm'] as String?,
      buttonHoverSfx: json['buttonHoverSfx'] as String?,
      buttonClickSfx: json['buttonClickSfx'] as String?,
      // Meta effects
      enableMetaEffects: json['enableMetaEffects'] as bool? ?? false,
      metaEffectType: MetaEffectType.values.firstWhere(
        (e) => e.name == json['metaEffectType'],
        orElse: () => MetaEffectType.none,
      ),
      metaEffectIntensity: (json['metaEffectIntensity'] as num?)?.toDouble() ?? 0.5,
      metaEffectTrigger: json['metaEffectTrigger'] as String? ?? 'random',
      metaEffectDelay: json['metaEffectDelay'] as int? ?? 5000,
      metaEffectRandomMin: json['metaEffectRandomMin'] as int? ?? 3000,
      metaEffectRandomMax: json['metaEffectRandomMax'] as int? ?? 10000,
      fakeErrorMessage: json['fakeErrorMessage'] as String?,
      fakeErrorTitle: json['fakeErrorTitle'] as String?,
    );
  }

  VNMainMenuConfig copyWith({
    MenuBackgroundType? backgroundType,
    String? backgroundImage,
    String? backgroundVideo,
    bool? videoLoop,
    bool? videoMuted,
    double? videoSpeed,
    String? logoImage,
    double? logoX,
    double? logoY,
    double? logoScale,
    String? titleText,
    double? titleX,
    double? titleY,
    double? menuX,
    double? menuY,
    String? alignment,
    String? buttonLayout,
    List<MenuButtonPosition>? buttonPositions,
    double? buttonWidth,
    double? buttonSpacing,
    double? buttonBorderRadius,
    bool? enableButtonShadow,
    String? buttonImage,
    String? buttonHoverImage,
    double? backgroundOverlayOpacity,
    String? versionPosition,
    // Animation
    String? logoAnimation,
    int? logoAnimationDuration,
    int? logoAnimationDelay,
    String? buttonAnimation,
    int? buttonStaggerDelay,
    String? backgroundAnimation,
    double? backgroundAnimationSpeed,
    // Particles
    bool? enableParticles,
    String? particlePreset,
    String? particleColor,
    double? particleDensity,
    // Audio
    String? menuBgm,
    String? buttonHoverSfx,
    String? buttonClickSfx,
    // Meta effects
    bool? enableMetaEffects,
    MetaEffectType? metaEffectType,
    double? metaEffectIntensity,
    String? metaEffectTrigger,
    int? metaEffectDelay,
    int? metaEffectRandomMin,
    int? metaEffectRandomMax,
    String? fakeErrorMessage,
    String? fakeErrorTitle,
  }) {
    return VNMainMenuConfig(
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundVideo: backgroundVideo ?? this.backgroundVideo,
      videoLoop: videoLoop ?? this.videoLoop,
      videoMuted: videoMuted ?? this.videoMuted,
      videoSpeed: videoSpeed ?? this.videoSpeed,
      logoImage: logoImage ?? this.logoImage,
      logoX: logoX ?? this.logoX,
      logoY: logoY ?? this.logoY,
      logoScale: logoScale ?? this.logoScale,
      titleText: titleText ?? this.titleText,
      titleX: titleX ?? this.titleX,
      titleY: titleY ?? this.titleY,
      menuX: menuX ?? this.menuX,
      menuY: menuY ?? this.menuY,
      alignment: alignment ?? this.alignment,
      buttonLayout: buttonLayout ?? this.buttonLayout,
      buttonPositions: buttonPositions ?? this.buttonPositions,
      buttonWidth: buttonWidth ?? this.buttonWidth,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      enableButtonShadow: enableButtonShadow ?? this.enableButtonShadow,
      buttonImage: buttonImage ?? this.buttonImage,
      buttonHoverImage: buttonHoverImage ?? this.buttonHoverImage,
      backgroundOverlayOpacity: backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      versionPosition: versionPosition ?? this.versionPosition,
      // Animation
      logoAnimation: logoAnimation ?? this.logoAnimation,
      logoAnimationDuration: logoAnimationDuration ?? this.logoAnimationDuration,
      logoAnimationDelay: logoAnimationDelay ?? this.logoAnimationDelay,
      buttonAnimation: buttonAnimation ?? this.buttonAnimation,
      buttonStaggerDelay: buttonStaggerDelay ?? this.buttonStaggerDelay,
      backgroundAnimation: backgroundAnimation ?? this.backgroundAnimation,
      backgroundAnimationSpeed: backgroundAnimationSpeed ?? this.backgroundAnimationSpeed,
      // Particles
      enableParticles: enableParticles ?? this.enableParticles,
      particlePreset: particlePreset ?? this.particlePreset,
      particleColor: particleColor ?? this.particleColor,
      particleDensity: particleDensity ?? this.particleDensity,
      // Audio
      menuBgm: menuBgm ?? this.menuBgm,
      buttonHoverSfx: buttonHoverSfx ?? this.buttonHoverSfx,
      buttonClickSfx: buttonClickSfx ?? this.buttonClickSfx,
      // Meta effects
      enableMetaEffects: enableMetaEffects ?? this.enableMetaEffects,
      metaEffectType: metaEffectType ?? this.metaEffectType,
      metaEffectIntensity: metaEffectIntensity ?? this.metaEffectIntensity,
      metaEffectTrigger: metaEffectTrigger ?? this.metaEffectTrigger,
      metaEffectDelay: metaEffectDelay ?? this.metaEffectDelay,
      metaEffectRandomMin: metaEffectRandomMin ?? this.metaEffectRandomMin,
      metaEffectRandomMax: metaEffectRandomMax ?? this.metaEffectRandomMax,
      fakeErrorMessage: fakeErrorMessage ?? this.fakeErrorMessage,
      fakeErrorTitle: fakeErrorTitle ?? this.fakeErrorTitle,
    );
  }
}

/// UI labels for the visual novel runtime (supports localization)
class VNUILabels {
  // Main menu labels
  final String menuStart;
  final String menuContinue;
  final String menuLoad;
  final String menuSave;
  final String menuExtras;
  final String menuGallery;
  final String menuMusicRoom;
  final String menuSettings;
  final String menuExit;
  
  // Quick menu labels
  final String quickAuto;
  final String quickSkip;
  final String quickLog;
  final String quickSave;
  final String quickLoad;
  final String quickConfig;
  final String quickHide;
  
  // Settings labels
  final String settingsTitle;
  final String settingsTextSpeed;
  final String settingsAutoSpeed;
  final String settingsBgmVolume;
  final String settingsSfxVolume;
  final String settingsVoiceVolume;
  final String settingsFullscreen;
  final String settingsSkipUnread;
  final String settingsFast;
  final String settingsSlow;
  final String settingsLanguage;
  
  // Save/Load labels
  final String saveTitle;
  final String loadTitle;
  final String saveEmpty;
  final String saveConfirm;
  final String loadConfirm;
  final String deleteConfirm;
  
  // Dialog labels
  final String dialogYes;
  final String dialogNo;
  final String dialogCancel;
  final String dialogConfirm;
  final String dialogBack;
  
  // Game labels
  final String pauseTitle;
  final String pauseResume;
  final String pauseMainMenu;
  final String endingTitle;
  final String endingThanks;
  final String endingReturn;

  const VNUILabels({
    // Main menu - default Chinese
    this.menuStart = '开始游戏',
    this.menuContinue = '继续游戏',
    this.menuLoad = '读取存档',
    this.menuSave = '保存游戏',
    this.menuExtras = '额外内容',
    this.menuGallery = 'CG鉴赏',
    this.menuMusicRoom = '音乐鉴赏',
    this.menuSettings = '游戏设置',
    this.menuExit = '退出游戏',
    
    // Quick menu
    this.quickAuto = '自动',
    this.quickSkip = '快进',
    this.quickLog = '回想',
    this.quickSave = '存档',
    this.quickLoad = '读档',
    this.quickConfig = '设置',
    this.quickHide = '隐藏',
    
    // Settings
    this.settingsTitle = '设置',
    this.settingsTextSpeed = '文字速度',
    this.settingsAutoSpeed = '自动速度',
    this.settingsBgmVolume = '背景音乐',
    this.settingsSfxVolume = '音效',
    this.settingsVoiceVolume = '语音',
    this.settingsFullscreen = '全屏模式',
    this.settingsSkipUnread = '跳过未读',
    this.settingsFast = '快',
    this.settingsSlow = '慢',
    this.settingsLanguage = '语言',
    
    // Save/Load
    this.saveTitle = '保存',
    this.loadTitle = '读取',
    this.saveEmpty = '空存档',
    this.saveConfirm = '确定要覆盖此存档吗？',
    this.loadConfirm = '确定要读取此存档吗？',
    this.deleteConfirm = '确定要删除此存档吗？',
    
    // Dialog
    this.dialogYes = '是',
    this.dialogNo = '否',
    this.dialogCancel = '取消',
    this.dialogConfirm = '确定',
    this.dialogBack = '返回',
    
    // Game
    this.pauseTitle = '暂停',
    this.pauseResume = '继续',
    this.pauseMainMenu = '返回标题',
    this.endingTitle = '完',
    this.endingThanks = '感谢您的游玩！',
    this.endingReturn = '返回标题',
  });

  /// Create English labels
  factory VNUILabels.english() => const VNUILabels(
    menuStart: 'Start',
    menuContinue: 'Continue',
    menuLoad: 'Load',
    menuSave: 'Save',
    menuExtras: 'Extras',
    menuGallery: 'Gallery',
    menuMusicRoom: 'Music',
    menuSettings: 'Settings',
    menuExit: 'Exit',
    quickAuto: 'Auto',
    quickSkip: 'Skip',
    quickLog: 'Log',
    quickSave: 'Save',
    quickLoad: 'Load',
    quickConfig: 'Config',
    quickHide: 'Hide',
    settingsTitle: 'Settings',
    settingsTextSpeed: 'Text Speed',
    settingsAutoSpeed: 'Auto Speed',
    settingsBgmVolume: 'BGM Volume',
    settingsSfxVolume: 'SFX Volume',
    settingsVoiceVolume: 'Voice Volume',
    settingsFullscreen: 'Fullscreen',
    settingsSkipUnread: 'Skip Unread',
    settingsFast: 'Fast',
    settingsSlow: 'Slow',
    settingsLanguage: 'Language',
    saveTitle: 'Save',
    loadTitle: 'Load',
    saveEmpty: 'Empty',
    saveConfirm: 'Overwrite this save?',
    loadConfirm: 'Load this save?',
    deleteConfirm: 'Delete this save?',
    dialogYes: 'Yes',
    dialogNo: 'No',
    dialogCancel: 'Cancel',
    dialogConfirm: 'OK',
    dialogBack: 'Back',
    pauseTitle: 'Paused',
    pauseResume: 'Resume',
    pauseMainMenu: 'Main Menu',
    endingTitle: 'The End',
    endingThanks: 'Thank you for playing!',
    endingReturn: 'Return to Title',
  );

  /// Create Japanese labels
  factory VNUILabels.japanese() => const VNUILabels(
    menuStart: 'はじめから',
    menuContinue: 'つづきから',
    menuLoad: 'ロード',
    menuSave: 'セーブ',
    menuExtras: 'おまけ',
    menuGallery: 'CGギャラリー',
    menuMusicRoom: 'サウンドルーム',
    menuSettings: '設定',
    menuExit: '終了',
    quickAuto: 'オート',
    quickSkip: 'スキップ',
    quickLog: 'ログ',
    quickSave: 'セーブ',
    quickLoad: 'ロード',
    quickConfig: '設定',
    quickHide: '非表示',
    settingsTitle: '設定',
    settingsTextSpeed: 'テキスト速度',
    settingsAutoSpeed: 'オート速度',
    settingsBgmVolume: 'BGM音量',
    settingsSfxVolume: 'SE音量',
    settingsVoiceVolume: 'ボイス音量',
    settingsFullscreen: 'フルスクリーン',
    settingsSkipUnread: '未読スキップ',
    settingsFast: '速い',
    settingsSlow: '遅い',
    settingsLanguage: '言語',
    saveTitle: 'セーブ',
    loadTitle: 'ロード',
    saveEmpty: '空き',
    saveConfirm: '上書きしますか？',
    loadConfirm: 'ロードしますか？',
    deleteConfirm: '削除しますか？',
    dialogYes: 'はい',
    dialogNo: 'いいえ',
    dialogCancel: 'キャンセル',
    dialogConfirm: '決定',
    dialogBack: '戻る',
    pauseTitle: 'ポーズ',
    pauseResume: '再開',
    pauseMainMenu: 'タイトルへ',
    endingTitle: '終',
    endingThanks: 'プレイありがとうございました！',
    endingReturn: 'タイトルへ戻る',
  );

  /// Create Korean labels
  factory VNUILabels.korean() => const VNUILabels(
    menuStart: '새 게임',
    menuContinue: '이어하기',
    menuLoad: '불러오기',
    menuSave: '저장하기',
    menuExtras: '부가 콘텐츠',
    menuGallery: 'CG 갤러리',
    menuMusicRoom: '음악 감상',
    menuSettings: '설정',
    menuExit: '종료',
    quickAuto: '자동',
    quickSkip: '스킵',
    quickLog: '로그',
    quickSave: '저장',
    quickLoad: '불러오기',
    quickConfig: '설정',
    quickHide: '숨기기',
    settingsTitle: '설정',
    settingsTextSpeed: '텍스트 속도',
    settingsAutoSpeed: '자동 속도',
    settingsBgmVolume: 'BGM 볼륨',
    settingsSfxVolume: '효과음 볼륨',
    settingsVoiceVolume: '음성 볼륨',
    settingsFullscreen: '전체 화면',
    settingsSkipUnread: '미읽음 스킵',
    settingsFast: '빠름',
    settingsSlow: '느림',
    settingsLanguage: '언어',
    saveTitle: '저장',
    loadTitle: '불러오기',
    saveEmpty: '빈 슬롯',
    saveConfirm: '덮어쓰시겠습니까?',
    loadConfirm: '불러오시겠습니까?',
    deleteConfirm: '삭제하시겠습니까?',
    dialogYes: '예',
    dialogNo: '아니오',
    dialogCancel: '취소',
    dialogConfirm: '확인',
    dialogBack: '뒤로',
    pauseTitle: '일시정지',
    pauseResume: '계속',
    pauseMainMenu: '타이틀로',
    endingTitle: '끝',
    endingThanks: '플레이해 주셔서 감사합니다!',
    endingReturn: '타이틀로 돌아가기',
  );

  Map<String, dynamic> toJson() => {
    'menuStart': menuStart,
    'menuContinue': menuContinue,
    'menuLoad': menuLoad,
    'menuSave': menuSave,
    'menuExtras': menuExtras,
    'menuGallery': menuGallery,
    'menuMusicRoom': menuMusicRoom,
    'menuSettings': menuSettings,
    'menuExit': menuExit,
    'quickAuto': quickAuto,
    'quickSkip': quickSkip,
    'quickLog': quickLog,
    'quickSave': quickSave,
    'quickLoad': quickLoad,
    'quickConfig': quickConfig,
    'quickHide': quickHide,
    'settingsTitle': settingsTitle,
    'settingsTextSpeed': settingsTextSpeed,
    'settingsAutoSpeed': settingsAutoSpeed,
    'settingsBgmVolume': settingsBgmVolume,
    'settingsSfxVolume': settingsSfxVolume,
    'settingsVoiceVolume': settingsVoiceVolume,
    'settingsFullscreen': settingsFullscreen,
    'settingsSkipUnread': settingsSkipUnread,
    'settingsFast': settingsFast,
    'settingsSlow': settingsSlow,
    'settingsLanguage': settingsLanguage,
    'saveTitle': saveTitle,
    'loadTitle': loadTitle,
    'saveEmpty': saveEmpty,
    'saveConfirm': saveConfirm,
    'loadConfirm': loadConfirm,
    'deleteConfirm': deleteConfirm,
    'dialogYes': dialogYes,
    'dialogNo': dialogNo,
    'dialogCancel': dialogCancel,
    'dialogConfirm': dialogConfirm,
    'dialogBack': dialogBack,
    'pauseTitle': pauseTitle,
    'pauseResume': pauseResume,
    'pauseMainMenu': pauseMainMenu,
    'endingTitle': endingTitle,
    'endingThanks': endingThanks,
    'endingReturn': endingReturn,
  };

  factory VNUILabels.fromJson(Map<String, dynamic> json) {
    return VNUILabels(
      menuStart: json['menuStart'] as String? ?? '开始游戏',
      menuContinue: json['menuContinue'] as String? ?? '继续游戏',
      menuLoad: json['menuLoad'] as String? ?? '读取存档',
      menuSave: json['menuSave'] as String? ?? '保存游戏',
      menuExtras: json['menuExtras'] as String? ?? '额外内容',
      menuGallery: json['menuGallery'] as String? ?? 'CG鉴赏',
      menuMusicRoom: json['menuMusicRoom'] as String? ?? '音乐鉴赏',
      menuSettings: json['menuSettings'] as String? ?? '游戏设置',
      menuExit: json['menuExit'] as String? ?? '退出游戏',
      quickAuto: json['quickAuto'] as String? ?? '自动',
      quickSkip: json['quickSkip'] as String? ?? '快进',
      quickLog: json['quickLog'] as String? ?? '回想',
      quickSave: json['quickSave'] as String? ?? '存档',
      quickLoad: json['quickLoad'] as String? ?? '读档',
      quickConfig: json['quickConfig'] as String? ?? '设置',
      quickHide: json['quickHide'] as String? ?? '隐藏',
      settingsTitle: json['settingsTitle'] as String? ?? '设置',
      settingsTextSpeed: json['settingsTextSpeed'] as String? ?? '文字速度',
      settingsAutoSpeed: json['settingsAutoSpeed'] as String? ?? '自动速度',
      settingsBgmVolume: json['settingsBgmVolume'] as String? ?? '背景音乐',
      settingsSfxVolume: json['settingsSfxVolume'] as String? ?? '音效',
      settingsVoiceVolume: json['settingsVoiceVolume'] as String? ?? '语音',
      settingsFullscreen: json['settingsFullscreen'] as String? ?? '全屏模式',
      settingsSkipUnread: json['settingsSkipUnread'] as String? ?? '跳过未读',
      settingsFast: json['settingsFast'] as String? ?? '快',
      settingsSlow: json['settingsSlow'] as String? ?? '慢',
      settingsLanguage: json['settingsLanguage'] as String? ?? '语言',
      saveTitle: json['saveTitle'] as String? ?? '保存',
      loadTitle: json['loadTitle'] as String? ?? '读取',
      saveEmpty: json['saveEmpty'] as String? ?? '空存档',
      saveConfirm: json['saveConfirm'] as String? ?? '确定要覆盖此存档吗？',
      loadConfirm: json['loadConfirm'] as String? ?? '确定要读取此存档吗？',
      deleteConfirm: json['deleteConfirm'] as String? ?? '确定要删除此存档吗？',
      dialogYes: json['dialogYes'] as String? ?? '是',
      dialogNo: json['dialogNo'] as String? ?? '否',
      dialogCancel: json['dialogCancel'] as String? ?? '取消',
      dialogConfirm: json['dialogConfirm'] as String? ?? '确定',
      dialogBack: json['dialogBack'] as String? ?? '返回',
      pauseTitle: json['pauseTitle'] as String? ?? '暂停',
      pauseResume: json['pauseResume'] as String? ?? '继续',
      pauseMainMenu: json['pauseMainMenu'] as String? ?? '返回标题',
      endingTitle: json['endingTitle'] as String? ?? '完',
      endingThanks: json['endingThanks'] as String? ?? '感谢您的游玩！',
      endingReturn: json['endingReturn'] as String? ?? '返回标题',
    );
  }
}

/// Text display mode for visual novel
enum TextMode {
  adv, // Adventure mode - bottom textbox
  nvl, // Novel mode - full screen text
}

/// Flowchart visibility mode
enum FlowchartVisibility {
  /// Always show flowchart
  always,

  /// Show after first playthrough completion
  afterCompletion,

  /// Never show flowchart
  never,
}

/// Visual novel project settings
class VNProjectSettings {
  /// Display resolution (default 1920x1080)
  final Size resolution;

  /// Default language code
  final String defaultLanguage;

  /// List of supported language codes
  final List<String> supportedLanguages;

  /// Language display names (code -> native name)
  final Map<String, String> languageNames;

  /// Default text display mode
  final TextMode defaultTextMode;

  /// Enable CG gallery feature
  final bool enableGallery;

  /// Enable music room feature
  final bool enableMusicRoom;

  /// Auto-save interval in seconds (default 120)
  final int autoSaveInterval;

  /// Flowchart visibility setting
  final FlowchartVisibility flowchartVisibility;

  /// Enable scene replay feature
  final bool enableSceneReplay;

  /// Enable achievements feature
  final bool enableAchievements;

  /// Enable endings tracking feature
  final bool enableEndingsTracking;

  /// Enable statistics tracking feature
  final bool enableStatistics;

  /// Enable runtime language switching
  final bool enableLanguageSwitching;

  const VNProjectSettings({
    this.resolution = const Size(1920, 1080),
    this.defaultLanguage = 'zh',
    this.supportedLanguages = const ['zh'],
    this.languageNames = const {'zh': '中文'},
    this.defaultTextMode = TextMode.adv,
    this.enableGallery = true,
    this.enableMusicRoom = true,
    this.autoSaveInterval = 120,
    this.flowchartVisibility = FlowchartVisibility.afterCompletion,
    this.enableSceneReplay = true,
    this.enableAchievements = true,
    this.enableEndingsTracking = true,
    this.enableStatistics = true,
    this.enableLanguageSwitching = true,
  });

  Map<String, dynamic> toJson() => {
        'resolution': {
          'width': resolution.width,
          'height': resolution.height,
        },
        'defaultLanguage': defaultLanguage,
        'supportedLanguages': supportedLanguages,
        'languageNames': languageNames,
        'defaultTextMode': defaultTextMode.name,
        'enableGallery': enableGallery,
        'enableMusicRoom': enableMusicRoom,
        'autoSaveInterval': autoSaveInterval,
        'flowchartVisibility': flowchartVisibility.name,
        'enableSceneReplay': enableSceneReplay,
        'enableAchievements': enableAchievements,
        'enableEndingsTracking': enableEndingsTracking,
        'enableStatistics': enableStatistics,
        'enableLanguageSwitching': enableLanguageSwitching,
      };

  factory VNProjectSettings.fromJson(Map<String, dynamic> json) {
    final resJson = json['resolution'] as Map<String, dynamic>?;
    return VNProjectSettings(
      resolution: resJson != null
          ? Size(
              (resJson['width'] as num).toDouble(),
              (resJson['height'] as num).toDouble(),
            )
          : const Size(1920, 1080),
      defaultLanguage: json['defaultLanguage'] as String? ?? 'zh',
      supportedLanguages:
          (json['supportedLanguages'] as List<dynamic>?)?.cast<String>() ??
              const ['zh'],
      languageNames:
          (json['languageNames'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {'zh': '中文'},
      defaultTextMode: TextMode.values.firstWhere(
        (e) => e.name == json['defaultTextMode'],
        orElse: () => TextMode.adv,
      ),
      enableGallery: json['enableGallery'] as bool? ?? true,
      enableMusicRoom: json['enableMusicRoom'] as bool? ?? true,
      autoSaveInterval: json['autoSaveInterval'] as int? ?? 120,
      flowchartVisibility: FlowchartVisibility.values.firstWhere(
        (e) => e.name == json['flowchartVisibility'],
        orElse: () => FlowchartVisibility.afterCompletion,
      ),
      enableSceneReplay: json['enableSceneReplay'] as bool? ?? true,
      enableAchievements: json['enableAchievements'] as bool? ?? true,
      enableEndingsTracking: json['enableEndingsTracking'] as bool? ?? true,
      enableStatistics: json['enableStatistics'] as bool? ?? true,
      enableLanguageSwitching: json['enableLanguageSwitching'] as bool? ?? true,
    );
  }

  VNProjectSettings copyWith({
    Size? resolution,
    String? defaultLanguage,
    List<String>? supportedLanguages,
    Map<String, String>? languageNames,
    TextMode? defaultTextMode,
    bool? enableGallery,
    bool? enableMusicRoom,
    int? autoSaveInterval,
    FlowchartVisibility? flowchartVisibility,
    bool? enableSceneReplay,
    bool? enableAchievements,
    bool? enableEndingsTracking,
    bool? enableStatistics,
    bool? enableLanguageSwitching,
  }) {
    return VNProjectSettings(
      resolution: resolution ?? this.resolution,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      languageNames: languageNames ?? this.languageNames,
      defaultTextMode: defaultTextMode ?? this.defaultTextMode,
      enableGallery: enableGallery ?? this.enableGallery,
      enableMusicRoom: enableMusicRoom ?? this.enableMusicRoom,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      flowchartVisibility: flowchartVisibility ?? this.flowchartVisibility,
      enableSceneReplay: enableSceneReplay ?? this.enableSceneReplay,
      enableAchievements: enableAchievements ?? this.enableAchievements,
      enableEndingsTracking: enableEndingsTracking ?? this.enableEndingsTracking,
      enableStatistics: enableStatistics ?? this.enableStatistics,
      enableLanguageSwitching: enableLanguageSwitching ?? this.enableLanguageSwitching,
    );
  }
}


/// Visual novel project - the root container for all story data
class VNProject {
  /// Unique project identifier
  final String id;

  /// Project display name
  final String name;

  /// Project version string
  final String version;

  /// Project settings
  final VNProjectSettings settings;

  /// List of story chapters
  final List<Chapter> chapters;

  /// List of defined characters
  final List<VNCharacter> characters;

  /// List of story variables
  final List<VNVariable> variables;

  /// List of affection definitions for characters
  final List<AffectionDefinition> affectionDefinitions;

  /// Resource library containing all assets
  final VNResourceLibrary resources;

  /// UI theme configuration
  final VNTheme theme;

  /// UI labels for localization
  final VNUILabels uiLabels;

  /// Main menu configuration
  final VNMainMenuConfig mainMenuConfig;

  /// Editor state for restoring UI (zoom, pan, etc.)
  final Map<String, dynamic> editorState;

  /// Project creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime modifiedAt;

  const VNProject({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.settings = const VNProjectSettings(),
    this.chapters = const [],
    this.characters = const [],
    this.variables = const [],
    this.affectionDefinitions = const [],
    this.resources = const VNResourceLibrary(),
    this.theme = const VNTheme(),
    this.uiLabels = const VNUILabels(),
    this.mainMenuConfig = const VNMainMenuConfig(),
    this.editorState = const {},
    required this.createdAt,
    required this.modifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'settings': settings.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'characters': characters.map((c) => c.toJson()).toList(),
        'variables': variables.map((v) => v.toJson()).toList(),
        'affectionDefinitions': affectionDefinitions.map((a) => a.toJson()).toList(),
        'resources': resources.toJson(),
        'theme': theme.toJson(),
        'uiLabels': uiLabels.toJson(),
        'mainMenuConfig': mainMenuConfig.toJson(),
        'editorState': editorState,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory VNProject.fromJson(Map<String, dynamic> json) {
    return VNProject(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String? ?? '1.0.0',
      settings: json['settings'] != null
          ? VNProjectSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const VNProjectSettings(),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((c) => VNCharacter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      variables: (json['variables'] as List<dynamic>?)
              ?.map((v) => VNVariable.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
      affectionDefinitions: (json['affectionDefinitions'] as List<dynamic>?)
              ?.map((a) => AffectionDefinition.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      resources: json['resources'] != null
          ? VNResourceLibrary.fromJson(json['resources'] as Map<String, dynamic>)
          : const VNResourceLibrary(),
      theme: json['theme'] != null
          ? VNTheme.fromJson(json['theme'] as Map<String, dynamic>)
          : const VNTheme(),
      uiLabels: json['uiLabels'] != null
          ? VNUILabels.fromJson(json['uiLabels'] as Map<String, dynamic>)
          : const VNUILabels(),
      mainMenuConfig: json['mainMenuConfig'] != null
          ? VNMainMenuConfig.fromJson(json['mainMenuConfig'] as Map<String, dynamic>)
          : const VNMainMenuConfig(),
      editorState:
          (json['editorState'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : DateTime.now(),
    );
  }

  VNProject copyWith({
    String? id,
    String? name,
    String? version,
    VNProjectSettings? settings,
    List<Chapter>? chapters,
    List<VNCharacter>? characters,
    List<VNVariable>? variables,
    List<AffectionDefinition>? affectionDefinitions,
    VNResourceLibrary? resources,
    VNTheme? theme,
    VNUILabels? uiLabels,
    VNMainMenuConfig? mainMenuConfig,
    Map<String, dynamic>? editorState,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return VNProject(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      settings: settings ?? this.settings,
      chapters: chapters ?? this.chapters,
      characters: characters ?? this.characters,
      variables: variables ?? this.variables,
      affectionDefinitions: affectionDefinitions ?? this.affectionDefinitions,
      resources: resources ?? this.resources,
      theme: theme ?? this.theme,
      uiLabels: uiLabels ?? this.uiLabels,
      mainMenuConfig: mainMenuConfig ?? this.mainMenuConfig,
      editorState: editorState ?? this.editorState,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Create a new empty project
  factory VNProject.create({
    required String name,
    VNProjectSettings? settings,
  }) {
    final now = DateTime.now();
    final id = 'vn_${now.millisecondsSinceEpoch}';
    return VNProject(
      id: id,
      name: name,
      settings: settings ?? const VNProjectSettings(),
      createdAt: now,
      modifiedAt: now,
    );
  }
}
