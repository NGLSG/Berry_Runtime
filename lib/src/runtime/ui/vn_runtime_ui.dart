/// VN Runtime UI Module
/// 
/// This module provides the complete UI framework for visual novel runtime.
/// Includes ADV/NVL text modes, choice panels, menus, and system screens.
library vn_runtime_ui;

// Text display modes
export 'adv_textbox.dart';
export 'nvl_screen.dart';

// Choice interface
export 'choice_panel.dart';

// Menus
export 'quick_menu.dart';
export 'main_menu.dart';
export 'enhanced_main_menu.dart';

// System screens
export 'settings_screen.dart';
export 'save_load_screen.dart';
// Hide BacklogEntry and BacklogController to avoid conflict with save module
export 'backlog_screen.dart' hide BacklogEntry, BacklogController;

// Gallery and extras
export 'gallery_screen.dart';
export 'music_room_screen.dart';
export 'achievements_screen.dart';
export 'endings_screen.dart';
