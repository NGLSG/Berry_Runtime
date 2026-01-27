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

// System screens
// Hide VNUserSettings to avoid conflict with vn_save_data.dart
export 'settings_screen.dart' hide VNUserSettings;
// Hide SaveSlotType and VNSaveSlot to avoid conflict with vn_save_data.dart
export 'save_load_screen.dart' hide SaveSlotType, VNSaveSlot;
// Hide BacklogEntry and BacklogController to avoid conflict with save module
export 'backlog_screen.dart' hide BacklogEntry, BacklogController;

// Gallery and extras
export 'gallery_screen.dart';
export 'music_room_screen.dart';
export 'achievements_screen.dart';
export 'endings_screen.dart';
