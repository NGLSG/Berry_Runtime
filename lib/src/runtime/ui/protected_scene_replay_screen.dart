/// Protected Scene Replay Screen Widget
///
/// Wraps SceneReplayScreen with spoiler protection validation.
/// Only allows replay of scenes that have been legitimately unlocked.
/// Requirements: 6.4

import 'package:flutter/material.dart';

import '../protection/protection.dart';
import '../replay/replay.dart';
import 'scene_replay_screen.dart';

/// Protected scene replay screen that validates unlock status
class ProtectedSceneReplayScreen extends StatelessWidget {
  /// List of all scene statuses (will be filtered by protection)
  final List<SceneReplayStatus> allScenes;

  /// Spoiler protection system
  final SpoilerProtection protection;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Callback when a scene is selected for replay
  final void Function(ReplayableScene scene)? onSceneSelected;

  /// Configuration
  final SceneReplayScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const ProtectedSceneReplayScreen({
    super.key,
    required this.allScenes,
    required this.protection,
    this.onBack,
    this.onSceneSelected,
    this.config = const SceneReplayScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    // Filter scenes based on protection validation
    final protectedScenes = allScenes.map((status) {
      // Validate unlock status through protection system
      final isLegitimatelyUnlocked = protection.validateUnlock(
        status.scene.id,
        UnlockType.scene,
      );

      // If scene claims to be unlocked but isn't legitimately unlocked,
      // treat it as locked
      return SceneReplayStatus(
        scene: status.scene,
        isUnlocked: isLegitimatelyUnlocked,
        unlockDate: isLegitimatelyUnlocked ? status.unlockDate : null,
      );
    }).toList();

    return SceneReplayScreen(
      scenes: protectedScenes,
      onBack: onBack,
      onSceneSelected: (scene) {
        // Double-check protection before allowing replay
        if (protection.validateUnlock(scene.id, UnlockType.scene)) {
          onSceneSelected?.call(scene);
        }
      },
      config: config,
      languageCode: languageCode,
    );
  }
}

/// Extension to create protected scene statuses from raw data
extension ProtectedSceneReplayExtension on List<SceneReplayStatus> {
  /// Filters scenes to only include legitimately unlocked ones
  List<SceneReplayStatus> filterByProtection(SpoilerProtection protection) {
    return map((status) {
      final isLegitimatelyUnlocked = protection.validateUnlock(
        status.scene.id,
        UnlockType.scene,
      );

      return SceneReplayStatus(
        scene: status.scene,
        isUnlocked: isLegitimatelyUnlocked,
        unlockDate: isLegitimatelyUnlocked ? status.unlockDate : null,
      );
    }).toList();
  }
}
