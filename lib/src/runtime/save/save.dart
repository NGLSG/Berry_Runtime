/// VN Runtime Save System
///
/// Commercial-grade save system for visual novel runtime.
/// Includes save data models, save manager, version migration,
/// read state tracking, and backlog/history management.

// Hide VNUserSettings to avoid conflict with settings_screen.dart
// Hide VNSaveSlot to avoid conflict with save_load_screen.dart (which SaveLoadScreen uses)
export 'vn_save_data.dart' hide VNUserSettings, VNSaveSlot;
export 'vn_save_manager.dart';
export 'vn_save_migration.dart';
export 'read_state_manager.dart';
export 'backlog_controller.dart';
