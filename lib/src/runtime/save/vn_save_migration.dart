import 'vn_save_data.dart';

/// Version compatibility and migration system for VN saves
/// 
/// Handles save data migration between different story versions.
/// Requirements: 13.9

/// Result of a migration attempt
class MigrationResult {
  /// Whether migration was successful
  final bool success;
  
  /// Migrated save data (null if failed)
  final VNSaveData? data;
  
  /// Error message if migration failed
  final String? error;
  
  /// Warnings generated during migration
  final List<String> warnings;

  const MigrationResult._({
    required this.success,
    this.data,
    this.error,
    this.warnings = const [],
  });

  factory MigrationResult.success(VNSaveData data, {List<String>? warnings}) {
    return MigrationResult._(
      success: true,
      data: data,
      warnings: warnings ?? [],
    );
  }

  factory MigrationResult.failure(String error) {
    return MigrationResult._(
      success: false,
      error: error,
    );
  }
}

/// Version information for comparison
class SaveVersion implements Comparable<SaveVersion> {
  final int major;
  final int minor;
  final int patch;

  const SaveVersion(this.major, this.minor, this.patch);

  factory SaveVersion.parse(String version) {
    final parts = version.split('.');
    return SaveVersion(
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    );
  }

  @override
  int compareTo(SaveVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(SaveVersion other) => compareTo(other) < 0;
  bool operator <=(SaveVersion other) => compareTo(other) <= 0;
  bool operator >(SaveVersion other) => compareTo(other) > 0;
  bool operator >=(SaveVersion other) => compareTo(other) >= 0;

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}


/// Migration step definition
typedef MigrationStep = Map<String, dynamic> Function(Map<String, dynamic> data);

/// Save data migrator
class VNSaveMigrator {
  /// Registered migration steps (fromVersion -> migration function)
  final Map<String, MigrationStep> _migrations = {};

  VNSaveMigrator() {
    _registerDefaultMigrations();
  }

  /// Register default migration steps
  void _registerDefaultMigrations() {
    // Example migrations - add real ones as versions evolve
    
    // Migration from 0.9.0 to 1.0.0
    registerMigration('0.9.0', (data) {
      // Add new fields with defaults
      data['unlockedScenes'] ??= <String>[];
      return data;
    });

    // Migration from 1.0.0 to 1.1.0
    registerMigration('1.0.0', (data) {
      // Convert old format to new format if needed
      if (data['readNodes'] != null && data['readDialogueIds'] == null) {
        // Convert node-level read tracking to dialogue-level
        final readNodes = data['readNodes'] as List<dynamic>;
        final readDialogueIds = <String>[];
        for (final nodeId in readNodes) {
          // Mark all dialogues in node as read (conservative migration)
          readDialogueIds.add('$nodeId:0');
        }
        data['readDialogueIds'] = readDialogueIds;
        data.remove('readNodes');
      }
      return data;
    });
  }

  /// Register a migration step
  void registerMigration(String fromVersion, MigrationStep step) {
    _migrations[fromVersion] = step;
  }

  /// Check if migration is possible
  bool canMigrate(String fromVersion, String toVersion) {
    final from = SaveVersion.parse(fromVersion);
    final to = SaveVersion.parse(toVersion);
    
    // Can't migrate to older version
    if (to < from) return false;
    
    // Same version, no migration needed
    if (from == to) return true;
    
    // Check if we have migration path
    return _hasMigrationPath(fromVersion, toVersion);
  }

  /// Check if migration path exists
  bool _hasMigrationPath(String fromVersion, String toVersion) {
    var current = fromVersion;
    final target = SaveVersion.parse(toVersion);
    
    while (SaveVersion.parse(current) < target) {
      if (!_migrations.containsKey(current)) {
        // No migration from this version, try next minor/patch
        final v = SaveVersion.parse(current);
        final nextVersions = [
          '${v.major}.${v.minor}.${v.patch + 1}',
          '${v.major}.${v.minor + 1}.0',
          '${v.major + 1}.0.0',
        ];
        
        var found = false;
        for (final next in nextVersions) {
          if (SaveVersion.parse(next) <= target) {
            current = next;
            found = true;
            break;
          }
        }
        
        if (!found) return true; // Assume compatible if no explicit migration
      } else {
        // Apply migration and move to next version
        final v = SaveVersion.parse(current);
        current = '${v.major}.${v.minor}.${v.patch + 1}';
      }
    }
    
    return true;
  }

  /// Migrate save data from one version to another
  MigrationResult migrate(
    Map<String, dynamic> data,
    String fromVersion,
    String toVersion,
  ) {
    if (!canMigrate(fromVersion, toVersion)) {
      return MigrationResult.failure(
        'Cannot migrate from $fromVersion to $toVersion',
      );
    }

    final from = SaveVersion.parse(fromVersion);
    final to = SaveVersion.parse(toVersion);

    if (from == to) {
      // No migration needed
      try {
        return MigrationResult.success(VNSaveData.fromJson(data));
      } catch (e) {
        return MigrationResult.failure('Failed to parse save data: $e');
      }
    }

    final warnings = <String>[];
    var currentData = Map<String, dynamic>.from(data);
    var currentVersion = fromVersion;

    // Apply migrations sequentially
    while (SaveVersion.parse(currentVersion) < to) {
      final migration = _migrations[currentVersion];
      
      if (migration != null) {
        try {
          currentData = migration(currentData);
          warnings.add('Applied migration from $currentVersion');
        } catch (e) {
          return MigrationResult.failure(
            'Migration from $currentVersion failed: $e',
          );
        }
      }

      // Move to next version
      final v = SaveVersion.parse(currentVersion);
      if (_migrations.containsKey(currentVersion)) {
        currentVersion = '${v.major}.${v.minor}.${v.patch + 1}';
      } else {
        // Skip to target if no intermediate migrations
        currentVersion = toVersion;
      }
    }

    // Update version in data
    currentData['storyVersion'] = toVersion;

    try {
      final migratedData = VNSaveData.fromJson(currentData);
      return MigrationResult.success(migratedData, warnings: warnings);
    } catch (e) {
      return MigrationResult.failure('Failed to create migrated save: $e');
    }
  }
}


/// Version compatibility checker
class VNVersionChecker {
  final String currentVersion;
  final VNSaveMigrator migrator;

  VNVersionChecker({
    required this.currentVersion,
    VNSaveMigrator? migrator,
  }) : migrator = migrator ?? VNSaveMigrator();

  /// Check if a save is compatible (same version or can be migrated)
  bool isCompatible(String saveVersion) {
    if (saveVersion == currentVersion) return true;
    return migrator.canMigrate(saveVersion, currentVersion);
  }

  /// Check if save is from a newer version (incompatible)
  bool isNewerVersion(String saveVersion) {
    final save = SaveVersion.parse(saveVersion);
    final current = SaveVersion.parse(currentVersion);
    return save > current;
  }

  /// Check if save needs migration
  bool needsMigration(String saveVersion) {
    return saveVersion != currentVersion && 
           !isNewerVersion(saveVersion);
  }

  /// Get compatibility status
  CompatibilityStatus checkStatus(String saveVersion) {
    if (saveVersion == currentVersion) {
      return CompatibilityStatus.compatible;
    }
    
    if (isNewerVersion(saveVersion)) {
      return CompatibilityStatus.newerVersion;
    }
    
    if (migrator.canMigrate(saveVersion, currentVersion)) {
      return CompatibilityStatus.needsMigration;
    }
    
    return CompatibilityStatus.incompatible;
  }

  /// Attempt to make save compatible
  MigrationResult makeCompatible(Map<String, dynamic> saveData) {
    final saveVersion = saveData['storyVersion'] as String? ?? '0.0.0';
    
    if (saveVersion == currentVersion) {
      try {
        return MigrationResult.success(VNSaveData.fromJson(saveData));
      } catch (e) {
        return MigrationResult.failure('Failed to parse save: $e');
      }
    }
    
    return migrator.migrate(saveData, saveVersion, currentVersion);
  }
}

/// Compatibility status enum
enum CompatibilityStatus {
  /// Save is fully compatible
  compatible,
  
  /// Save needs migration but can be upgraded
  needsMigration,
  
  /// Save is from a newer version, cannot load
  newerVersion,
  
  /// Save is incompatible and cannot be migrated
  incompatible,
}

/// Extension for compatibility status
extension CompatibilityStatusExtension on CompatibilityStatus {
  bool get canLoad => this == CompatibilityStatus.compatible || 
                      this == CompatibilityStatus.needsMigration;
  
  String get message {
    switch (this) {
      case CompatibilityStatus.compatible:
        return 'Save is compatible';
      case CompatibilityStatus.needsMigration:
        return 'Save will be upgraded to current version';
      case CompatibilityStatus.newerVersion:
        return 'Save is from a newer version and cannot be loaded';
      case CompatibilityStatus.incompatible:
        return 'Save is incompatible with current version';
    }
  }
}
