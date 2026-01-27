/// Developer Mode Manager for VNBS
///
/// Provides a centralized way to manage developer mode across the application.
/// When enabled, bypasses spoiler protection and enables debug features.
/// Requirements: 6.5

import 'dart:async';

/// Developer mode state change event
class DeveloperModeChangedEvent {
  /// Whether developer mode is now enabled
  final bool isEnabled;

  /// Timestamp of the change
  final DateTime timestamp;

  DeveloperModeChangedEvent({
    required this.isEnabled,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Developer Mode Manager
///
/// Centralized manager for developer mode state.
/// When developer mode is enabled:
/// - Spoiler protection is bypassed
/// - All content is accessible regardless of unlock status
/// - Debug features are enabled
/// - Save validation is skipped
class DeveloperModeManager {
  /// Singleton instance
  static final DeveloperModeManager _instance = DeveloperModeManager._internal();

  /// Factory constructor returns singleton
  factory DeveloperModeManager() => _instance;

  DeveloperModeManager._internal();

  /// Whether developer mode is currently enabled
  bool _isEnabled = false;

  /// Stream controller for state changes
  final StreamController<DeveloperModeChangedEvent> _stateController =
      StreamController<DeveloperModeChangedEvent>.broadcast();

  /// Whether developer mode is enabled
  bool get isEnabled => _isEnabled;

  /// Stream of developer mode state changes
  Stream<DeveloperModeChangedEvent> get onStateChanged => _stateController.stream;

  /// Enables developer mode
  ///
  /// When enabled:
  /// - All spoiler protection checks are bypassed
  /// - All content appears as unlocked
  /// - Debug features become available
  void enable() {
    if (!_isEnabled) {
      _isEnabled = true;
      _stateController.add(DeveloperModeChangedEvent(isEnabled: true));
    }
  }

  /// Disables developer mode
  ///
  /// When disabled:
  /// - Normal spoiler protection is enforced
  /// - Only legitimately unlocked content is accessible
  /// - Debug features are hidden
  void disable() {
    if (_isEnabled) {
      _isEnabled = false;
      _stateController.add(DeveloperModeChangedEvent(isEnabled: false));
    }
  }

  /// Toggles developer mode
  void toggle() {
    if (_isEnabled) {
      disable();
    } else {
      enable();
    }
  }

  /// Sets developer mode state
  void setEnabled(bool enabled) {
    if (enabled) {
      enable();
    } else {
      disable();
    }
  }

  /// Disposes resources
  void dispose() {
    _stateController.close();
  }
}

/// Extension to check developer mode easily
extension DeveloperModeCheck on Object {
  /// Whether developer mode is currently enabled
  bool get isDeveloperModeEnabled => DeveloperModeManager().isEnabled;
}
