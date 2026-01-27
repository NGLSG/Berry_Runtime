/// Mini-Game Skip Handler for VN Runtime
/// 
/// Handles skip functionality for mini-games, including
/// confirmation dialogs and default value application.
/// 
/// Requirements: 17.6

import 'package:flutter/material.dart';
import 'mini_game_interface.dart';

/// Configuration for skip behavior
class MiniGameSkipConfig {
  /// Whether skipping is allowed
  final bool allowSkip;
  
  /// Whether to show a confirmation dialog before skipping
  final bool requireConfirmation;
  
  /// Custom confirmation message
  final String? confirmationMessage;
  
  /// Default values to use when skipped
  final Map<String, dynamic> skipDefaults;
  
  /// Whether to show a penalty warning
  final bool showPenaltyWarning;
  
  /// Penalty description (e.g., "You will miss bonus points")
  final String? penaltyDescription;

  const MiniGameSkipConfig({
    this.allowSkip = true,
    this.requireConfirmation = true,
    this.confirmationMessage,
    this.skipDefaults = const {},
    this.showPenaltyWarning = false,
    this.penaltyDescription,
  });

  factory MiniGameSkipConfig.fromMiniGameConfig(MiniGameConfig config) {
    return MiniGameSkipConfig(
      allowSkip: config.skippable,
      skipDefaults: config.skipDefaults,
      requireConfirmation: true,
    );
  }
}

/// Handler for mini-game skip operations
class MiniGameSkipHandler {
  /// Show skip confirmation dialog
  /// 
  /// Returns true if the user confirms skip, false otherwise
  static Future<bool> showSkipConfirmation(
    BuildContext context, {
    MiniGameSkipConfig config = const MiniGameSkipConfig(),
    String? gameName,
  }) async {
    if (!config.allowSkip) {
      return false;
    }

    if (!config.requireConfirmation) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SkipConfirmationDialog(
        config: config,
        gameName: gameName,
      ),
    );

    return result ?? false;
  }

  /// Create a skip result with default values
  static MiniGameResult createSkipResult(MiniGameSkipConfig config) {
    return MiniGameResult(
      completed: false,
      skipped: true,
      outputVariables: config.skipDefaults,
    );
  }

  /// Check if skip is allowed for a mini-game config
  static bool canSkip(MiniGameConfig config) {
    return config.skippable;
  }
}

/// Skip confirmation dialog widget
class _SkipConfirmationDialog extends StatelessWidget {
  final MiniGameSkipConfig config;
  final String? gameName;

  const _SkipConfirmationDialog({
    required this.config,
    this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.skip_next,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Skip Mini-Game?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.confirmationMessage ??
                'Are you sure you want to skip ${gameName ?? 'this mini-game'}?',
          ),
          if (config.showPenaltyWarning && config.penaltyDescription != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.penaltyDescription!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continue Playing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

/// Widget that wraps a mini-game and provides skip functionality
class SkippableMiniGameWrapper extends StatelessWidget {
  final Widget child;
  final MiniGameConfig config;
  final void Function(MiniGameResult result) onComplete;
  final VoidCallback? onSkipRequested;

  const SkippableMiniGameWrapper({
    super.key,
    required this.child,
    required this.config,
    required this.onComplete,
    this.onSkipRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (config.skippable)
          Positioned(
            top: 16,
            right: 16,
            child: _SkipButton(
              onPressed: () => _handleSkip(context),
            ),
          ),
      ],
    );
  }

  Future<void> _handleSkip(BuildContext context) async {
    final skipConfig = MiniGameSkipConfig.fromMiniGameConfig(config);
    
    final confirmed = await MiniGameSkipHandler.showSkipConfirmation(
      context,
      config: skipConfig,
      gameName: config.displayName,
    );

    if (confirmed) {
      onSkipRequested?.call();
      onComplete(MiniGameSkipHandler.createSkipResult(skipConfig));
    }
  }
}

/// Skip button widget
class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.skip_next, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to add skip functionality to MiniGameManager
extension MiniGameManagerSkipExtension on MiniGameConfig {
  /// Get the skip configuration for this mini-game
  MiniGameSkipConfig get skipConfig => MiniGameSkipConfig.fromMiniGameConfig(this);
  
  /// Check if this mini-game can be skipped
  bool get canSkip => skippable;
}
