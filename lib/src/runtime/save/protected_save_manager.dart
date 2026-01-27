/// Protected Save Manager for VNBS
///
/// Extends VNSaveManager with spoiler protection integration.
/// Validates save integrity and unlock status on load.
/// Requirements: 6.1, 6.2, 6.3, 6.4

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../protection/protection.dart';
import 'vn_save_data.dart';
import 'vn_save_manager.dart';

/// Result of a protected save load operation
class ProtectedLoadResult {
  /// The loaded save data (null if load failed)
  final VNSaveData? data;

  /// Whether the load was successful
  final bool success;

  /// Error message if load failed
  final String? errorMessage;

  /// Validation result if validation was performed
  final SaveValidationResult? validationResult;

  const ProtectedLoadResult.success(this.data)
      : success = true,
        errorMessage = null,
        validationResult = const SaveValidationResult.valid();

  const ProtectedLoadResult.failure({
    required this.errorMessage,
    this.validationResult,
  })  : data = null,
        success = false;

  const ProtectedLoadResult.empty()
      : data = null,
        success = true,
        errorMessage = null,
        validationResult = null;
}

/// Protected Save Manager
///
/// Wraps VNSaveManager with spoiler protection integration.
/// All saves are protected with checksums and validated on load.
class ProtectedSaveManager {
  /// Underlying save manager
  final VNSaveManager _saveManager;

  /// Spoiler protection system
  final SpoilerProtection _protection;

  /// Creates a new ProtectedSaveManager
  ProtectedSaveManager({
    required VNSaveManager saveManager,
    required SpoilerProtection protection,
  })  : _saveManager = saveManager,
        _protection = protection;

  /// Base directory for save files
  String get savePath => _saveManager.savePath;

  /// Current story version
  String get storyVersion => _saveManager.storyVersion;

  // ============================================================
  // Protected Save Operations
  // ============================================================

  /// Saves data with protection checksum
  Future<void> save(int slotIndex, VNSaveData data, {Uint8List? thumbnail}) async {
    // Create protected save with checksum
    final protectedSave = _protection.createProtectedSave(data);

    // Save the protected data
    await _saveProtectedData(slotIndex, protectedSave, thumbnail: thumbnail);
  }

  /// Loads and validates save data
  Future<ProtectedLoadResult> load(int slotIndex) async {
    // Load the protected data
    final protectedSave = await _loadProtectedData(slotIndex);

    if (protectedSave == null) {
      return const ProtectedLoadResult.empty();
    }

    // Validate the save
    final validationResult = _protection.validateSave(
      protectedSave.data,
      protectedSave.checksum,
    );

    if (!validationResult.isValid) {
      return ProtectedLoadResult.failure(
        errorMessage: validationResult.errorMessage,
        validationResult: validationResult,
      );
    }

    return ProtectedLoadResult.success(protectedSave.data);
  }

  /// Loads save data without validation (for developer mode or recovery)
  Future<VNSaveData?> loadUnsafe(int slotIndex) async {
    final protectedSave = await _loadProtectedData(slotIndex);
    return protectedSave?.data;
  }

  /// Deletes a save slot
  Future<void> delete(int slotIndex) async {
    await _saveManager.delete(slotIndex);
    // Also delete the checksum file
    final checksumFile = File(_getChecksumPath(slotIndex));
    if (await checksumFile.exists()) {
      await checksumFile.delete();
    }
  }

  // ============================================================
  // Quick Save / Auto Save
  // ============================================================

  /// Quick save with protection
  Future<void> quickSave(VNSaveData data, {Uint8List? thumbnail}) async {
    final slotIndex = VNSaveManager.quickSaveStartIndex + _getNextQuickSaveIndex();
    await save(slotIndex, data, thumbnail: thumbnail);
  }

  /// Load the most recent valid quick save
  Future<ProtectedLoadResult> quickLoad() async {
    ProtectedLoadResult? mostRecent;
    DateTime? mostRecentTime;

    for (int i = 0; i < VNSaveManager.quickSaveSlots; i++) {
      final slotIndex = VNSaveManager.quickSaveStartIndex + i;
      final result = await load(slotIndex);

      if (result.success && result.data != null) {
        if (mostRecentTime == null || result.data!.timestamp.isAfter(mostRecentTime)) {
          mostRecent = result;
          mostRecentTime = result.data!.timestamp;
        }
      }
    }

    return mostRecent ?? const ProtectedLoadResult.empty();
  }

  /// Auto save with protection
  Future<void> autoSave(VNSaveData data, {Uint8List? thumbnail}) async {
    final slotIndex = VNSaveManager.autoSaveStartIndex + _getNextAutoSaveIndex();
    await save(slotIndex, data, thumbnail: thumbnail);
  }

  /// Load the most recent valid auto save
  Future<ProtectedLoadResult> loadLatestAutoSave() async {
    ProtectedLoadResult? mostRecent;
    DateTime? mostRecentTime;

    for (int i = 0; i < VNSaveManager.autoSaveSlots; i++) {
      final slotIndex = VNSaveManager.autoSaveStartIndex + i;
      final result = await load(slotIndex);

      if (result.success && result.data != null) {
        if (mostRecentTime == null || result.data!.timestamp.isAfter(mostRecentTime)) {
          mostRecent = result;
          mostRecentTime = result.data!.timestamp;
        }
      }
    }

    return mostRecent ?? const ProtectedLoadResult.empty();
  }

  // ============================================================
  // Slot Listing
  // ============================================================

  /// List all save slots with validation status
  Future<List<ProtectedSaveSlot>> listSlots() async {
    final slots = <ProtectedSaveSlot>[];

    for (int i = 0; i < VNSaveManager.totalSlots; i++) {
      final slot = await _loadSlotMetadata(i);
      slots.add(slot);
    }

    return slots;
  }

  /// Get info for a specific slot
  Future<ProtectedSaveSlot> getSlotInfo(int slotIndex) async {
    return _loadSlotMetadata(slotIndex);
  }

  /// Check if slot has data
  Future<bool> hasData(int slotIndex) async {
    return _saveManager.hasData(slotIndex);
  }

  // ============================================================
  // Internal Methods
  // ============================================================

  String _getChecksumPath(int slotIndex) {
    return path.join(savePath, 'save_${slotIndex}_checksum.txt');
  }

  Future<void> _saveProtectedData(
    int slotIndex,
    ProtectedSaveData protectedSave, {
    Uint8List? thumbnail,
  }) async {
    // Save the main data using the underlying manager
    await _saveManager.save(slotIndex, protectedSave.data, thumbnail: thumbnail);

    // Save the checksum separately
    final checksumFile = File(_getChecksumPath(slotIndex));
    await checksumFile.writeAsString(protectedSave.checksum);
  }

  Future<ProtectedSaveData?> _loadProtectedData(int slotIndex) async {
    // Load the main data
    final data = await _saveManager.load(slotIndex);
    if (data == null) return null;

    // Load the checksum
    final checksumFile = File(_getChecksumPath(slotIndex));
    String checksum;

    if (await checksumFile.exists()) {
      checksum = await checksumFile.readAsString();
    } else {
      // Legacy save without checksum - generate one for migration
      checksum = _protection.generateSaveChecksum(data);
      // Save the checksum for future loads
      await checksumFile.writeAsString(checksum);
    }

    return ProtectedSaveData(data: data, checksum: checksum);
  }

  Future<ProtectedSaveSlot> _loadSlotMetadata(int slotIndex) async {
    final baseSlot = await _saveManager.getSlotInfo(slotIndex);

    if (baseSlot.isEmpty) {
      return ProtectedSaveSlot.empty(slotIndex);
    }

    // Check if checksum exists
    final checksumFile = File(_getChecksumPath(slotIndex));
    final hasChecksum = await checksumFile.exists();

    // Determine validation status
    ValidationStatus validationStatus;
    if (!hasChecksum) {
      validationStatus = ValidationStatus.legacy;
    } else {
      // Quick validation check (full validation done on load)
      validationStatus = ValidationStatus.unknown;
    }

    return ProtectedSaveSlot(
      slotIndex: slotIndex,
      saveId: baseSlot.saveId,
      timestamp: baseSlot.timestamp,
      thumbnailPath: baseSlot.thumbnailPath,
      validationStatus: validationStatus,
    );
  }

  int _quickSaveIndex = 0;
  int _getNextQuickSaveIndex() {
    final index = _quickSaveIndex;
    _quickSaveIndex = (_quickSaveIndex + 1) % VNSaveManager.quickSaveSlots;
    return index;
  }

  int _autoSaveIndex = 0;
  int _getNextAutoSaveIndex() {
    final index = _autoSaveIndex;
    _autoSaveIndex = (_autoSaveIndex + 1) % VNSaveManager.autoSaveSlots;
    return index;
  }
}

/// Validation status for a save slot
enum ValidationStatus {
  /// Save has not been validated yet
  unknown,

  /// Save passed validation
  valid,

  /// Save failed validation
  invalid,

  /// Legacy save without checksum
  legacy,
}

/// Protected save slot with validation status
class ProtectedSaveSlot {
  /// Slot index
  final int slotIndex;

  /// Save ID if slot is occupied
  final String? saveId;

  /// Timestamp of the save
  final DateTime? timestamp;

  /// Path to thumbnail image
  final String? thumbnailPath;

  /// Validation status
  final ValidationStatus validationStatus;

  const ProtectedSaveSlot({
    required this.slotIndex,
    this.saveId,
    this.timestamp,
    this.thumbnailPath,
    this.validationStatus = ValidationStatus.unknown,
  });

  /// Whether this slot is empty
  bool get isEmpty => saveId == null;

  /// Whether this slot has data
  bool get hasData => saveId != null;

  /// Get the slot type based on index
  SaveSlotType get slotType {
    if (slotIndex >= VNSaveManager.autoSaveStartIndex) return SaveSlotType.auto;
    if (slotIndex >= VNSaveManager.quickSaveStartIndex) return SaveSlotType.quick;
    return SaveSlotType.regular;
  }

  /// Display name for the slot
  String get displayName {
    switch (slotType) {
      case SaveSlotType.regular:
        return 'Save ${slotIndex + 1}';
      case SaveSlotType.quick:
        return 'Quick Save ${slotIndex - VNSaveManager.quickSaveStartIndex + 1}';
      case SaveSlotType.auto:
        return 'Auto Save ${slotIndex - VNSaveManager.autoSaveStartIndex + 1}';
    }
  }

  /// Create an empty slot
  factory ProtectedSaveSlot.empty(int slotIndex) {
    return ProtectedSaveSlot(slotIndex: slotIndex);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtectedSaveSlot &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          saveId == other.saveId;

  @override
  int get hashCode => Object.hash(slotIndex, saveId);
}
