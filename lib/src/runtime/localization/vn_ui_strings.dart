/// VN Runtime UI Localization Strings
/// 
/// Provides localized strings for VN runtime UI components.
/// Supports en, zh, ja languages with fallback to English.

/// VN UI string keys
class VNUIStrings {
  VNUIStrings._();

  // Main Menu
  static const String newGame = 'newGame';
  static const String continueGame = 'continueGame';
  static const String load = 'load';
  static const String gallery = 'gallery';
  static const String settings = 'settings';
  static const String exit = 'exit';
  
  // Pause Menu
  static const String paused = 'paused';
  static const String resume = 'resume';
  static const String save = 'save';
  static const String mainMenu = 'mainMenu';
  
  // Quick Menu
  static const String auto = 'auto';
  static const String skip = 'skip';
  static const String log = 'log';
  static const String config = 'config';
  static const String hide = 'hide';
  
  // Settings Screen
  static const String text = 'text';
  static const String textSpeed = 'textSpeed';
  static const String autoSpeed = 'autoSpeed';
  static const String skipUnreadText = 'skipUnreadText';
  static const String allowSkipUnread = 'allowSkipUnread';
  static const String audio = 'audio';
  static const String bgmVolume = 'bgmVolume';
  static const String sfxVolume = 'sfxVolume';
  static const String voiceVolume = 'voiceVolume';
  static const String display = 'display';
  static const String fullscreen = 'fullscreen';
  static const String textLanguage = 'textLanguage';
  static const String voiceLanguage = 'voiceLanguage';
  static const String sameAsText = 'sameAsText';
  static const String chooseVoiceLang = 'chooseVoiceLang';
  static const String accessibility = 'accessibility';
  static const String fontSize = 'fontSize';
  static const String highContrastMode = 'highContrastMode';
  static const String highContrastDesc = 'highContrastDesc';
  static const String dyslexiaFriendlyFont = 'dyslexiaFriendlyFont';
  static const String dyslexiaFontDesc = 'dyslexiaFontDesc';
  static const String colorBlindMode = 'colorBlindMode';
  static const String colorBlindDesc = 'colorBlindDesc';
  static const String reduceMotion = 'reduceMotion';
  static const String reduceMotionDesc = 'reduceMotionDesc';
  static const String screenReaderSupport = 'screenReaderSupport';
  static const String screenReaderDesc = 'screenReaderDesc';
  static const String autoReadDialogue = 'autoReadDialogue';
  static const String autoReadDesc = 'autoReadDesc';
  static const String keyboardNavigation = 'keyboardNavigation';
  static const String keyboardNavDesc = 'keyboardNavDesc';
  static const String resetToDefaults = 'resetToDefaults';
  static const String fast = 'fast';
  static const String slow = 'slow';
  static const String previewText = 'previewText';
  
  // Save/Load Screen
  static const String saveGame = 'saveGame';
  static const String loadGame = 'loadGame';
  static const String saveSlots = 'saveSlots';
  static const String quickSave = 'quickSave';
  static const String autoSave = 'autoSave';
  static const String overwriteSave = 'overwriteSave';
  static const String overwriteConfirm = 'overwriteConfirm';
  static const String deleteSave = 'deleteSave';
  static const String deleteConfirm = 'deleteConfirm';
  static const String cancel = 'cancel';
  static const String overwrite = 'overwrite';
  static const String delete = 'delete';
  static const String emptySlot = 'emptySlot';
  static const String playTime = 'playTime';
  static const String quick = 'quick';
  
  // Backlog/History Screen
  static const String history = 'history';
  static const String noHistoryYet = 'noHistoryYet';
  static const String scrollToTop = 'scrollToTop';
  static const String scrollToBottom = 'scrollToBottom';
  static const String narration = 'narration';
  static const String replayVoice = 'replayVoice';
  static const String jumpToPoint = 'jumpToPoint';
  static const String chapter = 'chapter';
  
  // Gallery Screen
  static const String cgGallery = 'cgGallery';
  static const String all = 'all';
  static const String noCGsAvailable = 'noCGsAvailable';
  static const String clickToViewCG = 'clickToViewCG';
  
  // Music Room Screen
  static const String musicRoom = 'musicRoom';
  static const String noMusicAvailable = 'noMusicAvailable';
  static const String noTrackSelected = 'noTrackSelected';
  
  // Achievements Screen
  static const String achievements = 'achievements';
  static const String overallProgress = 'overallProgress';
  static const String progress = 'progress';
  static const String showOnlyUnlocked = 'showOnlyUnlocked';
  static const String noAchievementsUnlocked = 'noAchievementsUnlocked';
  static const String noAchievementsAvailable = 'noAchievementsAvailable';
  static const String achievementUnlocked = 'achievementUnlocked';
  static const String points = 'points';
  static const String unlocked = 'unlocked';
  
  // Choice Panel
  static const String makeChoice = 'makeChoice';
  static const String timeRemaining = 'timeRemaining';
  static const String choiceDisabled = 'choiceDisabled';
  static const String previouslySelected = 'previouslySelected';
}

/// VN UI Localizer - provides localized strings for runtime UI
class VNUILocalizer {
  VNUILocalizer._();

  static const Map<String, Map<String, String>> _strings = {
    'en': _enStrings,
    'zh': _zhStrings,
    'ja': _jaStrings,
  };

  /// Get localized string
  static String get(String key, [String languageCode = 'en']) {
    final lang = _strings[languageCode] ?? _strings['en']!;
    return lang[key] ?? _strings['en']![key] ?? key;
  }

  /// Get localized string with parameter substitution
  static String format(String key, Map<String, String> params, [String languageCode = 'en']) {
    var result = get(key, languageCode);
    params.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }

  static const Map<String, String> _enStrings = {
    // Main Menu
    'newGame': 'New Game',
    'continueGame': 'Continue',
    'load': 'Load',
    'gallery': 'Gallery',
    'settings': 'Settings',
    'exit': 'Exit',
    // Pause Menu
    'paused': 'Paused',
    'resume': 'Resume',
    'save': 'Save',
    'mainMenu': 'Main Menu',
    
    // Quick Menu
    'auto': 'Auto',
    'skip': 'Skip',
    'log': 'Log',
    'config': 'Config',
    'hide': 'Hide',
    
    // Settings
    'text': 'Text',
    'textSpeed': 'Text Speed',
    'autoSpeed': 'Auto Speed',
    'skipUnreadText': 'Skip Unread Text',
    'allowSkipUnread': 'Allow skipping text you haven\'t read',
    'audio': 'Audio',
    'bgmVolume': 'BGM Volume',
    'sfxVolume': 'SFX Volume',
    'voiceVolume': 'Voice Volume',
    'display': 'Display',
    'fullscreen': 'Fullscreen',
    'textLanguage': 'Text Language',
    'voiceLanguage': 'Voice Language',
    'sameAsText': 'Same as text',
    'chooseVoiceLang': 'Choose voice audio language independently',
    'accessibility': 'Accessibility',
    'fontSize': 'Font Size',
    'highContrastMode': 'High Contrast Mode',
    'highContrastDesc': 'Increases contrast for better visibility',
    'dyslexiaFriendlyFont': 'Dyslexia-Friendly Font',
    'dyslexiaFontDesc': 'Uses a font designed for easier reading',
    'colorBlindMode': 'Color Blind Mode',
    'colorBlindDesc': 'Adjusts colors for color vision deficiency',
    'reduceMotion': 'Reduce Motion',
    'reduceMotionDesc': 'Minimizes animations and transitions',
    'screenReaderSupport': 'Screen Reader Support',
    'screenReaderDesc': 'Enables semantic labels for screen readers',
    'autoReadDialogue': 'Auto-Read Dialogue',
    'autoReadDesc': 'Automatically reads dialogue text aloud',
    'keyboardNavigation': 'Keyboard Navigation',
    'keyboardNavDesc': 'Enables full keyboard control',
    'resetToDefaults': 'Reset to Defaults',
    'fast': 'Fast',
    'slow': 'Slow',
    'previewText': 'Preview Text',
    // Save/Load
    'saveGame': 'Save Game',
    'loadGame': 'Load Game',
    'saveSlots': 'Save Slots',
    'quickSave': 'Quick Save',
    'autoSave': 'Auto Save',
    'overwriteSave': 'Overwrite Save?',
    'overwriteConfirm': 'This will overwrite the existing save data.',
    'deleteSave': 'Delete Save?',
    'deleteConfirm': 'This action cannot be undone.',
    'cancel': 'Cancel',
    'overwrite': 'Overwrite',
    'delete': 'Delete',
    'emptySlot': 'Empty Slot {num}',
    'playTime': 'Play Time:',
    'quick': 'QUICK',
    
    // Backlog/History
    'history': 'History',
    'noHistoryYet': 'No history yet',
    'scrollToTop': 'Scroll to top',
    'scrollToBottom': 'Scroll to bottom',
    'narration': '(Narration)',
    'replayVoice': 'Replay voice',
    'jumpToPoint': 'Jump to this point',
    'chapter': 'Chapter: {name}',
    
    // Gallery
    'cgGallery': 'CG Gallery',
    'all': 'All',
    'noCGsAvailable': 'No CGs available',
    'clickToViewCG': 'Click on unlocked CGs to view full size',
    
    // Music Room
    'musicRoom': 'Music Room',
    'noMusicAvailable': 'No music available',
    'noTrackSelected': 'No track selected',
    
    // Achievements
    'achievements': 'Achievements',
    'overallProgress': 'Overall Progress',
    'progress': 'Progress',
    'showOnlyUnlocked': 'Show only unlocked',
    'noAchievementsUnlocked': 'No achievements unlocked yet',
    'noAchievementsAvailable': 'No achievements available',
    'achievementUnlocked': 'Achievement Unlocked!',
    'points': '+{num} points',
    'unlocked': 'Unlocked:',
    
    // Choice Panel
    'makeChoice': 'Make a choice',
    'timeRemaining': '{seconds}s',
    'choiceDisabled': 'This option is not available',
    'previouslySelected': 'Previously selected',
  };

  static const Map<String, String> _zhStrings = {
    // Main Menu
    'newGame': '新游戏',
    'continueGame': '继续',
    'load': '读档',
    'gallery': '画廊',
    'settings': '设置',
    'exit': '退出',
    
    // Pause Menu
    'paused': '暂停',
    'resume': '继续',
    'save': '存档',
    'mainMenu': '返回标题',
    
    // Quick Menu
    'auto': '自动',
    'skip': '快进',
    'log': '记录',
    'config': '设置',
    'hide': '隐藏',
    
    // Settings
    'text': '文本',
    'textSpeed': '文字速度',
    'autoSpeed': '自动速度',
    'skipUnreadText': '跳过未读文本',
    'allowSkipUnread': '允许跳过未阅读的文本',
    'audio': '音频',
    'bgmVolume': 'BGM音量',
    'sfxVolume': '音效音量',
    'voiceVolume': '语音音量',
    'display': '显示',
    'fullscreen': '全屏',
    'textLanguage': '文本语言',
    'voiceLanguage': '语音语言',
    'sameAsText': '与文本相同',
    'chooseVoiceLang': '独立选择语音音频语言',
    'accessibility': '无障碍',
    'fontSize': '字体大小',
    'highContrastMode': '高对比度模式',
    'highContrastDesc': '增强对比度以提高可见性',
    'dyslexiaFriendlyFont': '阅读障碍友好字体',
    'dyslexiaFontDesc': '使用更易阅读的字体',
    'colorBlindMode': '色盲模式',
    'colorBlindDesc': '调整颜色以适应色觉缺陷',
    'reduceMotion': '减少动画',
    'reduceMotionDesc': '最小化动画和过渡效果',
    'screenReaderSupport': '屏幕阅读器支持',
    'screenReaderDesc': '启用屏幕阅读器的语义标签',
    'autoReadDialogue': '自动朗读对话',
    'autoReadDesc': '自动朗读对话文本',
    'keyboardNavigation': '键盘导航',
    'keyboardNavDesc': '启用完整键盘控制',
    'resetToDefaults': '恢复默认设置',
    'fast': '快',
    'slow': '慢',
    'previewText': '预览文本',
    // Save/Load
    'saveGame': '存档',
    'loadGame': '读档',
    'saveSlots': '存档位',
    'quickSave': '快速存档',
    'autoSave': '自动存档',
    'overwriteSave': '覆盖存档？',
    'overwriteConfirm': '这将覆盖现有的存档数据。',
    'deleteSave': '删除存档？',
    'deleteConfirm': '此操作无法撤销。',
    'cancel': '取消',
    'overwrite': '覆盖',
    'delete': '删除',
    'emptySlot': '空存档位 {num}',
    'playTime': '游玩时间：',
    'quick': '快存',
    
    // Backlog/History
    'history': '历史记录',
    'noHistoryYet': '暂无记录',
    'scrollToTop': '滚动到顶部',
    'scrollToBottom': '滚动到底部',
    'narration': '（旁白）',
    'replayVoice': '重播语音',
    'jumpToPoint': '跳转到此处',
    'chapter': '章节：{name}',
    
    // Gallery
    'cgGallery': 'CG画廊',
    'all': '全部',
    'noCGsAvailable': '暂无CG',
    'clickToViewCG': '点击已解锁的CG查看大图',
    
    // Music Room
    'musicRoom': '音乐鉴赏',
    'noMusicAvailable': '暂无音乐',
    'noTrackSelected': '未选择曲目',
    
    // Achievements
    'achievements': '成就',
    'overallProgress': '总体进度',
    'progress': '进度',
    'showOnlyUnlocked': '仅显示已解锁',
    'noAchievementsUnlocked': '尚未解锁任何成就',
    'noAchievementsAvailable': '暂无成就',
    'achievementUnlocked': '成就解锁！',
    'points': '+{num} 点',
    'unlocked': '解锁时间：',
    
    // Choice Panel
    'makeChoice': '请做出选择',
    'timeRemaining': '{seconds}秒',
    'choiceDisabled': '此选项不可用',
    'previouslySelected': '已选择过',
  };

  static const Map<String, String> _jaStrings = {
    // Main Menu
    'newGame': 'はじめから',
    'continueGame': 'つづきから',
    'load': 'ロード',
    'gallery': 'ギャラリー',
    'settings': '設定',
    'exit': '終了',
    
    // Pause Menu
    'paused': 'ポーズ',
    'resume': '再開',
    'save': 'セーブ',
    'mainMenu': 'タイトルへ',
    
    // Quick Menu
    'auto': 'オート',
    'skip': 'スキップ',
    'log': 'ログ',
    'config': '設定',
    'hide': '非表示',
    
    // Settings
    'text': 'テキスト',
    'textSpeed': '文字速度',
    'autoSpeed': 'オート速度',
    'skipUnreadText': '未読スキップ',
    'allowSkipUnread': '未読テキストのスキップを許可',
    'audio': 'オーディオ',
    'bgmVolume': 'BGM音量',
    'sfxVolume': 'SE音量',
    'voiceVolume': 'ボイス音量',
    'display': '表示',
    'fullscreen': 'フルスクリーン',
    'textLanguage': 'テキスト言語',
    'voiceLanguage': 'ボイス言語',
    'sameAsText': 'テキストと同じ',
    'chooseVoiceLang': 'ボイス言語を個別に選択',
    'accessibility': 'アクセシビリティ',
    'fontSize': 'フォントサイズ',
    'highContrastMode': 'ハイコントラストモード',
    'highContrastDesc': '視認性を向上させるためコントラストを強化',
    'dyslexiaFriendlyFont': '読みやすいフォント',
    'dyslexiaFontDesc': '読みやすさを重視したフォントを使用',
    'colorBlindMode': '色覚サポート',
    'colorBlindDesc': '色覚特性に合わせて色を調整',
    'reduceMotion': 'モーション軽減',
    'reduceMotionDesc': 'アニメーションと遷移を最小化',
    'screenReaderSupport': 'スクリーンリーダー対応',
    'screenReaderDesc': 'スクリーンリーダー用のラベルを有効化',
    'autoReadDialogue': '自動読み上げ',
    'autoReadDesc': 'ダイアログを自動的に読み上げ',
    'keyboardNavigation': 'キーボード操作',
    'keyboardNavDesc': 'キーボードでの操作を有効化',
    'resetToDefaults': '初期設定に戻す',
    'fast': '速い',
    'slow': '遅い',
    'previewText': 'プレビュー',
    // Save/Load
    'saveGame': 'セーブ',
    'loadGame': 'ロード',
    'saveSlots': 'セーブスロット',
    'quickSave': 'クイックセーブ',
    'autoSave': 'オートセーブ',
    'overwriteSave': '上書きしますか？',
    'overwriteConfirm': '既存のセーブデータを上書きします。',
    'deleteSave': '削除しますか？',
    'deleteConfirm': 'この操作は取り消せません。',
    'cancel': 'キャンセル',
    'overwrite': '上書き',
    'delete': '削除',
    'emptySlot': '空きスロット {num}',
    'playTime': 'プレイ時間：',
    'quick': 'クイック',
    
    // Backlog/History
    'history': 'バックログ',
    'noHistoryYet': '履歴がありません',
    'scrollToTop': '先頭へ',
    'scrollToBottom': '末尾へ',
    'narration': '（ナレーション）',
    'replayVoice': 'ボイス再生',
    'jumpToPoint': 'ここへジャンプ',
    'chapter': 'チャプター：{name}',
    
    // Gallery
    'cgGallery': 'CGギャラリー',
    'all': 'すべて',
    'noCGsAvailable': 'CGがありません',
    'clickToViewCG': '解放済みのCGをクリックで拡大表示',
    
    // Music Room
    'musicRoom': 'ミュージックルーム',
    'noMusicAvailable': '楽曲がありません',
    'noTrackSelected': '曲が選択されていません',
    
    // Achievements
    'achievements': '実績',
    'overallProgress': '達成率',
    'progress': '進捗',
    'showOnlyUnlocked': '解放済みのみ表示',
    'noAchievementsUnlocked': 'まだ実績がありません',
    'noAchievementsAvailable': '実績がありません',
    'achievementUnlocked': '実績解除！',
    'points': '+{num} ポイント',
    'unlocked': '解放日：',
    
    // Choice Panel
    'makeChoice': '選択してください',
    'timeRemaining': '{seconds}秒',
    'choiceDisabled': 'この選択肢は利用できません',
    'previouslySelected': '選択済み',
  };
}
