import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

import 'vn_save_data.dart';

/// Save manager for VN runtime
/// 
/// Manages 100 regular slots + 3 quick save + 3 auto save slots.
/// Requirements: 13.9
class VNSaveManager {
  /// Maximum number of regular save slots
  static const int maxSlots = 100;
  
  /// Number of quick save slots
  static const int quickSaveSlots = 3;
  
  /// Number of auto save slots
  static const int autoSaveSlots = 3;
  
  /// Total number of slots
  static const int totalSlots = maxSlots + quickSaveSlots + autoSaveSlots;
  
  /// Quick save slot start index
  static const int quickSaveStartIndex = maxSlots;
  
  /// Auto save slot start index
  static const int autoSaveStartIndex = maxSlots + quickSaveSlots;

  /// Base directory for save files
  final String savePath;
  
  /// Current story version for compatibility
  final String storyVersion;
  
  /// Current quick save rotation index
  int _quickSaveIndex = 0;
  
  /// Current auto save rotation index
  int _autoSaveIndex = 0;

  VNSaveManager({
    required this.savePath,
    required this.storyVersion,
  });

  /// Get the file path for a save slot
  String _getSlotPath(int slotIndex) {
    return path.join(savePath, 'save_$slotIndex.json');
  }

  /// Get the thumbnail path for a save slot
  String _getThumbnailPath(int slotIndex) {
    return path.join(savePath, 'thumb_$slotIndex.png');
  }

  /// Ensure save directory exists
  Future<void> _ensureDirectory() async {
    final dir = Directory(savePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }


  /// Save data to a specific slot
  Future<void> save(int slotIndex, VNSaveData data, {Uint8List? thumbnail}) async {
    if (slotIndex < 0 || slotIndex >= totalSlots) {
      throw ArgumentError('Invalid slot index: $slotIndex');
    }
    
    await _ensureDirectory();
    
    // Save the data
    final saveFile = File(_getSlotPath(slotIndex));
    final jsonData = jsonEncode(data.toJson());
    await saveFile.writeAsString(jsonData);
    
    // Save thumbnail if provided
    if (thumbnail != null) {
      final thumbFile = File(_getThumbnailPath(slotIndex));
      await thumbFile.writeAsBytes(thumbnail);
    }
  }

  /// Load data from a specific slot
  Future<VNSaveData?> load(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= totalSlots) {
      throw ArgumentError('Invalid slot index: $slotIndex');
    }
    
    final saveFile = File(_getSlotPath(slotIndex));
    if (!await saveFile.exists()) {
      return null;
    }
    
    try {
      final jsonString = await saveFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check version compatibility
      final saveVersion = jsonData['storyVersion'] as String?;
      if (saveVersion != storyVersion) {
        // Attempt migration
        final migrated = VNSaveData.migrate(jsonData, storyVersion);
        if (migrated != null) {
          // Save migrated data back
          await save(slotIndex, migrated);
          return migrated;
        }
        return null;
      }
      
      return VNSaveData.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Delete a save slot
  Future<void> delete(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= totalSlots) {
      throw ArgumentError('Invalid slot index: $slotIndex');
    }
    
    final saveFile = File(_getSlotPath(slotIndex));
    if (await saveFile.exists()) {
      await saveFile.delete();
    }
    
    final thumbFile = File(_getThumbnailPath(slotIndex));
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }

  /// List all save slots with metadata
  Future<List<VNSaveSlot>> listSlots() async {
    final slots = <VNSaveSlot>[];
    
    for (int i = 0; i < totalSlots; i++) {
      final slot = await _loadSlotMetadata(i);
      slots.add(slot);
    }
    
    return slots;
  }

  /// Load only slot metadata (without full data)
  Future<VNSaveSlot> _loadSlotMetadata(int slotIndex) async {
    final saveFile = File(_getSlotPath(slotIndex));
    
    if (!await saveFile.exists()) {
      return VNSaveSlot.empty(slotIndex);
    }
    
    try {
      final jsonString = await saveFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final thumbFile = File(_getThumbnailPath(slotIndex));
      final thumbPath = await thumbFile.exists() ? thumbFile.path : null;
      
      return VNSaveSlot(
        slotIndex: slotIndex,
        saveId: jsonData['saveId'] as String?,
        timestamp: jsonData['timestamp'] != null
            ? DateTime.parse(jsonData['timestamp'] as String)
            : null,
        thumbnailPath: thumbPath,
        // Don't load full data for listing
        data: null,
      );
    } catch (e) {
      return VNSaveSlot.empty(slotIndex);
    }
  }


  /// Quick save to rotating slot
  Future<void> quickSave(VNSaveData data, {Uint8List? thumbnail}) async {
    final slotIndex = quickSaveStartIndex + _quickSaveIndex;
    await save(slotIndex, data, thumbnail: thumbnail);
    
    // Rotate to next slot
    _quickSaveIndex = (_quickSaveIndex + 1) % quickSaveSlots;
  }

  /// Load the most recent quick save
  Future<VNSaveData?> quickLoad() async {
    // Find the most recent quick save
    VNSaveData? mostRecent;
    DateTime? mostRecentTime;
    
    for (int i = 0; i < quickSaveSlots; i++) {
      final slotIndex = quickSaveStartIndex + i;
      final data = await load(slotIndex);
      
      if (data != null) {
        if (mostRecentTime == null || data.timestamp.isAfter(mostRecentTime)) {
          mostRecent = data;
          mostRecentTime = data.timestamp;
        }
      }
    }
    
    return mostRecent;
  }

  /// Auto save to rotating slot
  Future<void> autoSave(VNSaveData data, {Uint8List? thumbnail}) async {
    final slotIndex = autoSaveStartIndex + _autoSaveIndex;
    await save(slotIndex, data, thumbnail: thumbnail);
    
    // Rotate to next slot
    _autoSaveIndex = (_autoSaveIndex + 1) % autoSaveSlots;
  }

  /// Load the most recent auto save
  Future<VNSaveData?> loadLatestAutoSave() async {
    VNSaveData? mostRecent;
    DateTime? mostRecentTime;
    
    for (int i = 0; i < autoSaveSlots; i++) {
      final slotIndex = autoSaveStartIndex + i;
      final data = await load(slotIndex);
      
      if (data != null) {
        if (mostRecentTime == null || data.timestamp.isAfter(mostRecentTime)) {
          mostRecent = data;
          mostRecentTime = data.timestamp;
        }
      }
    }
    
    return mostRecent;
  }

  /// Check if a save is compatible with current version
  Future<bool> checkCompatibility(VNSaveData data, String currentVersion) async {
    if (data.storyVersion == currentVersion) {
      return true;
    }
    
    // Try migration
    final migrated = VNSaveData.migrate(data.toJson(), currentVersion);
    return migrated != null;
  }

  /// Migrate save data if needed
  Future<VNSaveData?> migrateIfNeeded(VNSaveData data, String targetVersion) async {
    if (data.storyVersion == targetVersion) {
      return data;
    }
    
    return VNSaveData.migrate(data.toJson(), targetVersion);
  }

  /// Capture screenshot for thumbnail
  /// 
  /// This should be called with a RenderRepaintBoundary key from the game screen
  Future<Uint8List?> captureScreenshot(RenderRepaintBoundary boundary) async {
    try {
      final image = await boundary.toImage(pixelRatio: 0.25); // 25% size for thumbnail
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Get slot info for display
  Future<VNSaveSlot> getSlotInfo(int slotIndex) async {
    return _loadSlotMetadata(slotIndex);
  }

  /// Check if slot has data
  Future<bool> hasData(int slotIndex) async {
    final saveFile = File(_getSlotPath(slotIndex));
    return saveFile.exists();
  }

  /// Get all quick save slots
  Future<List<VNSaveSlot>> getQuickSaveSlots() async {
    final slots = <VNSaveSlot>[];
    for (int i = 0; i < quickSaveSlots; i++) {
      slots.add(await _loadSlotMetadata(quickSaveStartIndex + i));
    }
    return slots;
  }

  /// Get all auto save slots
  Future<List<VNSaveSlot>> getAutoSaveSlots() async {
    final slots = <VNSaveSlot>[];
    for (int i = 0; i < autoSaveSlots; i++) {
      slots.add(await _loadSlotMetadata(autoSaveStartIndex + i));
    }
    return slots;
  }

  /// Get regular save slots (paginated)
  Future<List<VNSaveSlot>> getRegularSlots({int page = 0, int pageSize = 20}) async {
    final slots = <VNSaveSlot>[];
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, maxSlots);
    
    for (int i = start; i < end; i++) {
      slots.add(await _loadSlotMetadata(i));
    }
    return slots;
  }

  /// Delete all saves (for testing or reset)
  Future<void> deleteAll() async {
    for (int i = 0; i < totalSlots; i++) {
      await delete(i);
    }
  }
}
