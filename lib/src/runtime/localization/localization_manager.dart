/// Runtime Localization Manager for Visual Novels
/// 
/// Provides runtime language switching for exported VN games.
/// Supports:
/// - Multiple languages with fallback
/// - UI labels localization
/// - Dialogue text localization
/// - Character name localization
/// - Dynamic language switching

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Supported language definition
class VNLanguage {
  /// Language code (e.g., 'zh', 'en', 'ja')
  final String code;
  
  /// Display name in that language (e.g., '中文', 'English', '日本語')
  final String nativeName;
  
  /// Display name in English
  final String englishName;
  
  /// Flag emoji or icon path
  final String? flag;
  
  /// Whether this is a right-to-left language
  final bool isRtl;

  const VNLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    this.flag,
    this.isRtl = false,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'nativeName': nativeName,
    'englishName': englishName,
    if (flag != null) 'flag': flag,
    'isRtl': isRtl,
  };

  factory VNLanguage.fromJson(Map<String, dynamic> json) {
    return VNLanguage(
      code: json['code'] as String,
      nativeName: json['nativeName'] as String,
      englishName: json['englishName'] as String,
      flag: json['flag'] as String?,
      isRtl: json['isRtl'] as bool? ?? false,
    );
  }

  /// Common language presets
  static const chinese = VNLanguage(
    code: 'zh',
    nativeName: '中文',
    englishName: 'Chinese',
    flag: '🇨🇳',
  );

  static const english = VNLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    flag: '🇺🇸',
  );

  static const japanese = VNLanguage(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    flag: '🇯🇵',
  );

  static const korean = VNLanguage(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    flag: '🇰🇷',
  );

  static const spanish = VNLanguage(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
  );

  static const french = VNLanguage(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    flag: '🇫🇷',
  );

  static const german = VNLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    flag: '🇩🇪',
  );

  static const russian = VNLanguage(
    code: 'ru',
    nativeName: 'Русский',
    englishName: 'Russian',
    flag: '🇷🇺',
  );

  static const portuguese = VNLanguage(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    flag: '🇧🇷',
  );

  static const italian = VNLanguage(
    code: 'it',
    nativeName: 'Italiano',
    englishName: 'Italian',
    flag: '🇮🇹',
  );

  static const thai = VNLanguage(
    code: 'th',
    nativeName: 'ไทย',
    englishName: 'Thai',
    flag: '🇹🇭',
  );

  static const vietnamese = VNLanguage(
    code: 'vi',
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
    flag: '🇻🇳',
  );

  static const arabic = VNLanguage(
    code: 'ar',
    nativeName: 'العربية',
    englishName: 'Arabic',
    flag: '🇸🇦',
    isRtl: true,
  );

  /// Get language by code
  static VNLanguage? getByCode(String code) {
    return _presets[code];
  }

  static final Map<String, VNLanguage> _presets = {
    'zh': chinese,
    'en': english,
    'ja': japanese,
    'ko': korean,
    'es': spanish,
    'fr': french,
    'de': german,
    'ru': russian,
    'pt': portuguese,
    'it': italian,
    'th': thai,
    'vi': vietnamese,
    'ar': arabic,
  };
}

/// Localization data for a single language
class LanguageData {
  /// UI labels
  final Map<String, String> uiLabels;
  
  /// Dialogue translations (key -> translated text)
  final Map<String, String> dialogues;
  
  /// Character name translations
  final Map<String, String> characterNames;
  
  /// Choice option translations
  final Map<String, String> choices;
  
  /// Misc strings (endings, achievements, etc.)
  final Map<String, String> misc;

  const LanguageData({
    this.uiLabels = const {},
    this.dialogues = const {},
    this.characterNames = const {},
    this.choices = const {},
    this.misc = const {},
  });

  Map<String, dynamic> toJson() => {
    'uiLabels': uiLabels,
    'dialogues': dialogues,
    'characterNames': characterNames,
    'choices': choices,
    'misc': misc,
  };

  factory LanguageData.fromJson(Map<String, dynamic> json) {
    return LanguageData(
      uiLabels: (json['uiLabels'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      dialogues: (json['dialogues'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      characterNames: (json['characterNames'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      choices: (json['choices'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      misc: (json['misc'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    );
  }

  /// Get any string by key, searching all categories
  String? get(String key) {
    return uiLabels[key] ?? 
           dialogues[key] ?? 
           characterNames[key] ?? 
           choices[key] ?? 
           misc[key];
  }
}

/// Runtime localization manager
class LocalizationManager {
  /// Singleton instance
  static LocalizationManager? _instance;
  static LocalizationManager get instance => _instance ??= LocalizationManager._();

  LocalizationManager._();

  /// Current language code
  String _currentLanguage = 'zh';
  String get currentLanguage => _currentLanguage;

  /// Default/fallback language code
  String _defaultLanguage = 'zh';
  String get defaultLanguage => _defaultLanguage;

  /// Available languages
  final List<VNLanguage> _availableLanguages = [];
  List<VNLanguage> get availableLanguages => List.unmodifiable(_availableLanguages);

  /// Loaded language data
  final Map<String, LanguageData> _languageData = {};

  /// Language change stream
  final _languageController = StreamController<String>.broadcast();
  Stream<String> get onLanguageChanged => _languageController.stream;

  /// Initialize with available languages
  Future<void> initialize({
    required List<VNLanguage> languages,
    required String defaultLanguage,
    String? initialLanguage,
  }) async {
    _availableLanguages.clear();
    _availableLanguages.addAll(languages);
    _defaultLanguage = defaultLanguage;
    _currentLanguage = initialLanguage ?? defaultLanguage;

    // Load default language data
    await loadLanguage(_defaultLanguage);
    
    // Load current language if different
    if (_currentLanguage != _defaultLanguage) {
      await loadLanguage(_currentLanguage);
    }
  }

  /// Load language data from assets
  Future<void> loadLanguage(String languageCode) async {
    if (_languageData.containsKey(languageCode)) return;

    try {
      final jsonString = await rootBundle.loadString('assets/localization/$languageCode.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _languageData[languageCode] = LanguageData.fromJson(data);
    } catch (e) {
      // Language file not found, use empty data
      _languageData[languageCode] = const LanguageData();
    }
  }

  /// Set current language
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    if (!_availableLanguages.any((l) => l.code == languageCode)) return;

    await loadLanguage(languageCode);
    _currentLanguage = languageCode;
    _languageController.add(languageCode);
  }

  /// Get current language info
  VNLanguage? get currentLanguageInfo {
    return _availableLanguages.firstWhere(
      (l) => l.code == _currentLanguage,
      orElse: () => VNLanguage.chinese,
    );
  }

  /// Get localized UI label
  String getUILabel(String key, {String? fallback}) {
    final current = _languageData[_currentLanguage];
    final defaultData = _languageData[_defaultLanguage];
    
    return current?.uiLabels[key] ?? 
           defaultData?.uiLabels[key] ?? 
           fallback ?? 
           key;
  }

  /// Get localized dialogue
  String getDialogue(String key, {String? fallback}) {
    final current = _languageData[_currentLanguage];
    final defaultData = _languageData[_defaultLanguage];
    
    return current?.dialogues[key] ?? 
           defaultData?.dialogues[key] ?? 
           fallback ?? 
           key;
  }

  /// Get localized character name
  String getCharacterName(String characterId, {String? fallback}) {
    final current = _languageData[_currentLanguage];
    final defaultData = _languageData[_defaultLanguage];
    
    return current?.characterNames[characterId] ?? 
           defaultData?.characterNames[characterId] ?? 
           fallback ?? 
           characterId;
  }

  /// Get localized choice text
  String getChoice(String key, {String? fallback}) {
    final current = _languageData[_currentLanguage];
    final defaultData = _languageData[_defaultLanguage];
    
    return current?.choices[key] ?? 
           defaultData?.choices[key] ?? 
           fallback ?? 
           key;
  }

  /// Get any localized string
  String get(String key, {String? fallback}) {
    final current = _languageData[_currentLanguage];
    final defaultData = _languageData[_defaultLanguage];
    
    return current?.get(key) ?? 
           defaultData?.get(key) ?? 
           fallback ?? 
           key;
  }

  /// Check if a language is loaded
  bool isLanguageLoaded(String languageCode) {
    return _languageData.containsKey(languageCode);
  }

  /// Get completion percentage for a language
  double getCompletionPercent(String languageCode) {
    final langData = _languageData[languageCode];
    final defaultData = _languageData[_defaultLanguage];
    
    if (langData == null || defaultData == null) return 0.0;
    
    int total = defaultData.dialogues.length + 
                defaultData.choices.length + 
                defaultData.characterNames.length;
    if (total == 0) return 100.0;
    
    int translated = langData.dialogues.length + 
                     langData.choices.length + 
                     langData.characterNames.length;
    
    return (translated / total) * 100;
  }

  /// Dispose resources
  void dispose() {
    _languageController.close();
    _instance = null;
  }
}

/// Extension for easy localization access
extension LocalizationExtension on String {
  /// Get localized version of this string (used as key)
  String get tr => LocalizationManager.instance.get(this, fallback: this);
  
  /// Get localized UI label
  String get trUI => LocalizationManager.instance.getUILabel(this, fallback: this);
}
