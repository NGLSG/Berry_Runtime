/// Resource types in the manifest
enum ResourceType {
  background,
  bgm,
  sfx,
  voice,
  sprite,
  cg,
  ui,
}

/// A single resource entry in the manifest
class ResourceEntry {
  /// File path relative to project/bundle
  final String path;

  /// Resource type
  final ResourceType type;

  /// File checksum for integrity verification
  final String checksum;

  /// File size in bytes
  final int size;

  const ResourceEntry({
    required this.path,
    required this.type,
    required this.checksum,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'type': type.name,
        'checksum': checksum,
        'size': size,
      };

  factory ResourceEntry.fromJson(Map<String, dynamic> json) {
    return ResourceEntry(
      path: json['path'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResourceType.background,
      ),
      checksum: json['checksum'] as String,
      size: json['size'] as int? ?? 0,
    );
  }

  ResourceEntry copyWith({
    String? path,
    ResourceType? type,
    String? checksum,
    int? size,
  }) {
    return ResourceEntry(
      path: path ?? this.path,
      type: type ?? this.type,
      checksum: checksum ?? this.checksum,
      size: size ?? this.size,
    );
  }
}

/// Resource manifest containing all resources in the bundle
class VNResourceManifest {
  /// Resource entries indexed by resource ID
  final Map<String, ResourceEntry> entries;

  const VNResourceManifest({
    this.entries = const {},
  });

  Map<String, dynamic> toJson() => {
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory VNResourceManifest.fromJson(Map<String, dynamic> json) {
    return VNResourceManifest(
      entries: (json['entries'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, ResourceEntry.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
    );
  }

  /// Get a resource entry by ID
  ResourceEntry? getEntry(String id) => entries[id];

  /// Check if a resource exists
  bool hasResource(String id) => entries.containsKey(id);

  /// Get all resources of a specific type
  Map<String, ResourceEntry> getByType(ResourceType type) {
    return Map.fromEntries(
      entries.entries.where((e) => e.value.type == type),
    );
  }

  /// Get total size of all resources
  int get totalSize => entries.values.fold(0, (sum, e) => sum + e.size);

  /// Get resource count
  int get count => entries.length;

  /// Get count by type
  int countByType(ResourceType type) {
    return entries.values.where((e) => e.type == type).length;
  }

  /// Validate that all resources exist (paths are valid)
  /// Returns list of missing resource IDs
  List<String> validatePaths(String basePath) {
    final missing = <String>[];
    // In a real implementation, this would check if files exist
    // For now, just return empty list
    return missing;
  }

  /// Verify checksums of all resources
  /// Returns list of resource IDs with mismatched checksums
  Future<List<String>> verifyChecksums(String basePath) async {
    final mismatched = <String>[];
    // In a real implementation, this would compute and compare checksums
    // For now, just return empty list
    return mismatched;
  }

  VNResourceManifest copyWith({
    Map<String, ResourceEntry>? entries,
  }) {
    return VNResourceManifest(
      entries: entries ?? this.entries,
    );
  }

  /// Add a resource entry
  VNResourceManifest addEntry(String id, ResourceEntry entry) {
    return copyWith(
      entries: {...entries, id: entry},
    );
  }

  /// Remove a resource entry
  VNResourceManifest removeEntry(String id) {
    final newEntries = Map<String, ResourceEntry>.from(entries);
    newEntries.remove(id);
    return copyWith(entries: newEntries);
  }
}
