/// Spoiler Protection System for VNBS
///
/// Prevents players from accessing locked content through save manipulation.
/// Implements save file integrity validation and unlock verification.
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6

import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../progress/global_progress_manager.dart';
import '../save/vn_save_data.dart';

/// Type of unlockable content
enum UnlockType {
  /// CG image
  cg,

  /// Scene for replay
  scene,

  /// Ending
  ending,

  /// Achievement
  achievement,

  /// BGM track
  bgm,

  /// Journal entry
  journal,
}

/// Result of save validation
class SaveValidationResult {
  /// Whether the save is valid
  final bool isValid;

  /// Error message if invalid
  final String? errorMessage;

  /// Error code for programmatic handling
  final SaveValidationError? errorCode;

  const SaveValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        errorCode = null;

  const SaveValidationResult.invalid({
    required this.errorMessage,
    required this.errorCode,
  }) : isValid = false;

  @override
  String toString() =>
      isValid ? 'SaveValidationResult.valid' : 'SaveValidationResult.invalid($errorMessage)';
}

/// Save validation error codes
enum SaveValidationError {
  /// Checksum mismatch - save file was tampered
  checksumMismatch,

  /// Save references content that hasn't been unlocked
  lockedContentReference,

  /// Save file is corrupted or malformed
  corruptedData,

  /// Save version is incompatible
  versionMismatch,
}

/// Spoiler Protection System
///
/// Provides save file integrity validation and unlock verification
/// to prevent players from accessing locked content through save manipulation.
class SpoilerProtection {
  /// Global progress manager for checking unlock status
  final GlobalProgressManager _progress;

  /// Secret key for HMAC generation
  final String _secretKey;

  /// Developer mode flag - bypasses all protection when true
  bool developerMode;

  /// Creates a new SpoilerProtection instance
  ///
  /// [progress] - Global progress manager for unlock verification
  /// [secretKey] - Secret key for checksum generation (should be unique per game)
  /// [developerMode] - If true, bypasses all protection checks
  SpoilerProtection({
    required GlobalProgressManager progress,
    required String secretKey,
    this.developerMode = false,
  })  : _progress = progress,
        _secretKey = secretKey;

  // ============================================================
  // Checksum Generation
  // ============================================================

  /// Generates a checksum for save data
  ///
  /// Uses HMAC-SHA256 for secure checksum generation.
  /// The checksum can be stored alongside the save to verify integrity.
  String generateSaveChecksum(VNSaveData data) {
    final content = _getSaveContentForChecksum(data);
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmac.convert(utf8.encode(content));
    return digest.toString();
  }

  /// Gets the content string used for checksum calculation
  ///
  /// Excludes volatile fields like timestamp to allow re-saving
  /// without invalidating the checksum.
  String _getSaveContentForChecksum(VNSaveData data) {
    // Create a map with only the fields that should be protected
    final protectedData = {
      'saveId': data.saveId,
      'storyVersion': data.storyVersion,
      'currentChapterId': data.currentChapterId,
      'currentNodeId': data.currentNodeId,
      'currentDialogueIndex': data.currentDialogueIndex,
      'variables': data.variables,
      'readDialogueIds': data.readDialogueIds.toList()..sort(),
      'unlockedCGs': data.unlockedCGs.toList()..sort(),
      'unlockedBGM': data.unlockedBGM.toList()..sort(),
      'unlockedScenes': data.unlockedScenes.toList()..sort(),
    };
    return jsonEncode(protectedData);
  }

  // ============================================================
  // Save Validation
  // ============================================================

  /// Validates save file integrity
  ///
  /// Checks that the save file hasn't been tampered with by verifying
  /// the checksum matches the save content.
  ///
  /// Returns [SaveValidationResult.valid] if the save is valid,
  /// or [SaveValidationResult.invalid] with error details if not.
  SaveValidationResult validateSaveIntegrity(VNSaveData data, String checksum) {
    // Developer mode bypasses all checks
    if (developerMode) {
      return const SaveValidationResult.valid();
    }

    // Verify checksum
    final expectedChecksum = generateSaveChecksum(data);
    if (expectedChecksum != checksum) {
      return const SaveValidationResult.invalid(
        errorMessage: 'Save file integrity check failed. The save may have been modified.',
        errorCode: SaveValidationError.checksumMismatch,
      );
    }

    return const SaveValidationResult.valid();
  }

  /// Validates that save data doesn't reference locked content
  ///
  /// Checks that all CGs, scenes, and BGMs referenced in the save
  /// have been legitimately unlocked in the global progress.
  SaveValidationResult validateSaveUnlocks(VNSaveData data) {
    // Developer mode bypasses all checks
    if (developerMode) {
      return const SaveValidationResult.valid();
    }

    // Check CGs
    for (final cgId in data.unlockedCGs) {
      if (!_progress.isCGUnlocked(cgId)) {
        return SaveValidationResult.invalid(
          errorMessage: 'Save references CG "$cgId" which has not been unlocked.',
          errorCode: SaveValidationError.lockedContentReference,
        );
      }
    }

    // Check BGMs
    for (final bgmId in data.unlockedBGM) {
      if (!_progress.isBGMUnlocked(bgmId)) {
        return SaveValidationResult.invalid(
          errorMessage: 'Save references BGM "$bgmId" which has not been unlocked.',
          errorCode: SaveValidationError.lockedContentReference,
        );
      }
    }

    // Check scenes
    for (final sceneId in data.unlockedScenes) {
      if (!_progress.isSceneUnlocked(sceneId)) {
        return SaveValidationResult.invalid(
          errorMessage: 'Save references scene "$sceneId" which has not been unlocked.',
          errorCode: SaveValidationError.lockedContentReference,
        );
      }
    }

    return const SaveValidationResult.valid();
  }

  /// Performs full save validation (integrity + unlock verification)
  ///
  /// This is the main validation method that should be called when loading saves.
  SaveValidationResult validateSave(VNSaveData data, String checksum) {
    // Developer mode bypasses all checks
    if (developerMode) {
      return const SaveValidationResult.valid();
    }

    // First check integrity
    final integrityResult = validateSaveIntegrity(data, checksum);
    if (!integrityResult.isValid) {
      return integrityResult;
    }

    // Then check unlocks
    return validateSaveUnlocks(data);
  }

  // ============================================================
  // Unlock Verification
  // ============================================================

  /// Validates that a specific piece of content is legitimately unlocked
  ///
  /// Use this to verify access before displaying gallery items, scenes, etc.
  bool validateUnlock(String contentId, UnlockType type) {
    // Developer mode bypasses all checks
    if (developerMode) {
      return true;
    }

    switch (type) {
      case UnlockType.cg:
        return _progress.isCGUnlocked(contentId);
      case UnlockType.scene:
        return _progress.isSceneUnlocked(contentId);
      case UnlockType.ending:
        return _progress.isEndingReached(contentId);
      case UnlockType.achievement:
        return _progress.isAchievementUnlocked(contentId);
      case UnlockType.bgm:
        return _progress.isBGMUnlocked(contentId);
      case UnlockType.journal:
        return _progress.data.journal.unlockedEntryIds.contains(contentId);
    }
  }

  /// Filters a list of content IDs to only include legitimately unlocked items
  ///
  /// Useful for filtering gallery items, scene lists, etc.
  List<String> filterUnlockedContent(List<String> contentIds, UnlockType type) {
    // Developer mode returns all content
    if (developerMode) {
      return contentIds;
    }

    return contentIds.where((id) => validateUnlock(id, type)).toList();
  }

  // ============================================================
  // Protected Save Data
  // ============================================================

  /// Creates a protected save data wrapper with checksum
  ProtectedSaveData createProtectedSave(VNSaveData data) {
    final checksum = generateSaveChecksum(data);
    return ProtectedSaveData(
      data: data,
      checksum: checksum,
    );
  }

  /// Validates and unwraps protected save data
  ///
  /// Returns the save data if valid, or null if validation fails.
  /// Use [validateSave] directly if you need detailed error information.
  VNSaveData? unwrapProtectedSave(ProtectedSaveData protectedSave) {
    final result = validateSave(protectedSave.data, protectedSave.checksum);
    if (result.isValid) {
      return protectedSave.data;
    }
    return null;
  }
}

/// Save data with integrity checksum
class ProtectedSaveData {
  /// The actual save data
  final VNSaveData data;

  /// HMAC checksum for integrity verification
  final String checksum;

  const ProtectedSaveData({
    required this.data,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'data': data.toJson(),
        'checksum': checksum,
      };

  factory ProtectedSaveData.fromJson(Map<String, dynamic> json) {
    return ProtectedSaveData(
      data: VNSaveData.fromJson(json['data'] as Map<String, dynamic>),
      checksum: json['checksum'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtectedSaveData &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(data, checksum);
}
