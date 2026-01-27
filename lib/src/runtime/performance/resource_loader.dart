/// Resource Lazy Loading System for VN Runtime
///
/// Implements chapter-based lazy loading of resources to optimize memory usage
/// and initial load times on mobile devices.
///
/// Requirements: 24.1

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Resource loading state
enum ResourceLoadState {
  /// Resource not loaded
  unloaded,

  /// Resource is being loaded
  loading,

  /// Resource loaded successfully
  loaded,

  /// Resource failed to load
  failed,
}

/// Loaded resource data
class LoadedResource {
  /// Resource identifier
  final String id;

  /// Resource type
  final ResourceLoadType type;

  /// Resource data (bytes for images/audio, or decoded data)
  final dynamic data;

  /// File path
  final String path;

  /// Size in bytes
  final int sizeBytes;

  /// When the resource was loaded
  final DateTime loadedAt;

  /// Last access time (for LRU eviction)
  DateTime lastAccessedAt;

  LoadedResource({
    required this.id,
    required this.type,
    required this.data,
    required this.path,
    required this.sizeBytes,
    DateTime? loadedAt,
  })  : loadedAt = loadedAt ?? DateTime.now(),
        lastAccessedAt = loadedAt ?? DateTime.now();

  /// Update last access time
  void touch() {
    lastAccessedAt = DateTime.now();
  }
}

/// Resource types for loading
enum ResourceLoadType {
  background,
  sprite,
  cg,
  bgm,
  sfx,
  voice,
  video,
}

/// Resource loading priority
enum ResourcePriority {
  /// Critical resources needed immediately
  critical,

  /// High priority - load soon
  high,

  /// Normal priority
  normal,

  /// Low priority - can wait
  low,

  /// Background loading when idle
  background,
}

/// Resource load request
class ResourceLoadRequest {
  final String id;
  final String path;
  final ResourceLoadType type;
  final ResourcePriority priority;
  final Completer<LoadedResource?> completer;

  ResourceLoadRequest({
    required this.id,
    required this.path,
    required this.type,
    this.priority = ResourcePriority.normal,
  }) : completer = Completer<LoadedResource?>();

  Future<LoadedResource?> get future => completer.future;
}

/// Abstract resource loader interface
abstract class ResourceLoaderBackend {
  /// Load image resource
  Future<Uint8List?> loadImage(String path);

  /// Load audio resource
  Future<Uint8List?> loadAudio(String path);

  /// Load video resource
  Future<Uint8List?> loadVideo(String path);

  /// Get file size without loading
  Future<int> getFileSize(String path);

  /// Check if file exists
  Future<bool> fileExists(String path);
}

/// Default file-based resource loader backend
class FileResourceLoaderBackend implements ResourceLoaderBackend {
  final String basePath;

  FileResourceLoaderBackend({required this.basePath});

  @override
  Future<Uint8List?> loadImage(String path) async {
    // In real implementation, load from file system
    // For now, return null (mock)
    return null;
  }

  @override
  Future<Uint8List?> loadAudio(String path) async {
    return null;
  }

  @override
  Future<Uint8List?> loadVideo(String path) async {
    return null;
  }

  @override
  Future<int> getFileSize(String path) async {
    return 0;
  }

  @override
  Future<bool> fileExists(String path) async {
    return true;
  }
}


/// Lazy Resource Loader
///
/// Manages on-demand loading of chapter resources with:
/// - Priority-based loading queue
/// - Memory-aware caching with LRU eviction
/// - Chapter-based resource grouping
class LazyResourceLoader extends ChangeNotifier {
  final ResourceLoaderBackend _backend;

  /// Maximum memory budget for cached resources (in bytes)
  final int maxMemoryBudget;

  /// Currently loaded resources
  final Map<String, LoadedResource> _cache = {};

  /// Loading queue
  final List<ResourceLoadRequest> _loadQueue = [];

  /// Currently loading resources
  final Set<String> _loading = {};

  /// Failed resources (with retry count)
  final Map<String, int> _failedResources = {};

  /// Maximum concurrent loads
  final int maxConcurrentLoads;

  /// Maximum retry attempts for failed loads
  final int maxRetryAttempts;

  /// Current memory usage
  int _currentMemoryUsage = 0;

  /// Loading state per resource
  final Map<String, ResourceLoadState> _loadStates = {};

  /// Chapter resource mappings
  final Map<String, Set<String>> _chapterResources = {};

  /// Currently active chapter
  String? _activeChapterId;

  LazyResourceLoader({
    required ResourceLoaderBackend backend,
    this.maxMemoryBudget = 256 * 1024 * 1024, // 256 MB default
    this.maxConcurrentLoads = 4,
    this.maxRetryAttempts = 3,
  }) : _backend = backend;

  /// Get current memory usage
  int get currentMemoryUsage => _currentMemoryUsage;

  /// Get memory usage percentage
  double get memoryUsagePercent => _currentMemoryUsage / maxMemoryBudget;

  /// Get number of cached resources
  int get cachedResourceCount => _cache.length;

  /// Get loading queue size
  int get queueSize => _loadQueue.length;

  /// Check if a resource is loaded
  bool isLoaded(String resourceId) => _cache.containsKey(resourceId);

  /// Check if a resource is loading
  bool isLoading(String resourceId) => _loading.contains(resourceId);

  /// Get resource load state
  ResourceLoadState getLoadState(String resourceId) {
    return _loadStates[resourceId] ?? ResourceLoadState.unloaded;
  }

  /// Get a loaded resource (returns null if not loaded)
  LoadedResource? getResource(String resourceId) {
    final resource = _cache[resourceId];
    resource?.touch();
    return resource;
  }

  /// Register resources for a chapter
  void registerChapterResources(String chapterId, Set<String> resourceIds) {
    _chapterResources[chapterId] = resourceIds;
  }

  /// Set active chapter (triggers preloading of chapter resources)
  Future<void> setActiveChapter(String chapterId) async {
    if (_activeChapterId == chapterId) return;

    _activeChapterId = chapterId;

    // Unload resources from other chapters if memory is tight
    if (memoryUsagePercent > 0.8) {
      await _evictNonActiveChapterResources();
    }

    notifyListeners();
  }

  /// Request a resource to be loaded
  Future<LoadedResource?> loadResource({
    required String id,
    required String path,
    required ResourceLoadType type,
    ResourcePriority priority = ResourcePriority.normal,
  }) async {
    // Return cached resource if available
    if (_cache.containsKey(id)) {
      final resource = _cache[id]!;
      resource.touch();
      return resource;
    }

    // Check if already loading
    if (_loading.contains(id)) {
      // Wait for existing load to complete
      final existingRequest = _loadQueue.firstWhere(
        (r) => r.id == id,
        orElse: () => ResourceLoadRequest(id: id, path: path, type: type),
      );
      return existingRequest.future;
    }

    // Create load request
    final request = ResourceLoadRequest(
      id: id,
      path: path,
      type: type,
      priority: priority,
    );

    // Add to queue based on priority
    _addToQueue(request);
    _loadStates[id] = ResourceLoadState.loading;

    // Process queue
    _processQueue();

    return request.future;
  }

  /// Load multiple resources
  Future<List<LoadedResource?>> loadResources(
    List<({String id, String path, ResourceLoadType type})> resources, {
    ResourcePriority priority = ResourcePriority.normal,
  }) async {
    final futures = resources.map((r) => loadResource(
          id: r.id,
          path: r.path,
          type: r.type,
          priority: priority,
        ));
    return Future.wait(futures);
  }

  /// Preload resources for upcoming content
  void preloadResources(
    List<({String id, String path, ResourceLoadType type})> resources,
  ) {
    for (final r in resources) {
      if (!_cache.containsKey(r.id) && !_loading.contains(r.id)) {
        final request = ResourceLoadRequest(
          id: r.id,
          path: r.path,
          type: r.type,
          priority: ResourcePriority.background,
        );
        _addToQueue(request);
      }
    }
    _processQueue();
  }

  /// Unload a specific resource
  void unloadResource(String resourceId) {
    final resource = _cache.remove(resourceId);
    if (resource != null) {
      _currentMemoryUsage -= resource.sizeBytes;
      _loadStates[resourceId] = ResourceLoadState.unloaded;
      notifyListeners();
    }
  }

  /// Unload all resources for a chapter
  void unloadChapter(String chapterId) {
    final resourceIds = _chapterResources[chapterId];
    if (resourceIds == null) return;

    for (final id in resourceIds) {
      // Don't unload if used by active chapter
      if (_activeChapterId != null) {
        final activeResources = _chapterResources[_activeChapterId];
        if (activeResources?.contains(id) == true) continue;
      }
      unloadResource(id);
    }
  }

  /// Clear all cached resources
  void clearCache() {
    _cache.clear();
    _currentMemoryUsage = 0;
    _loadStates.clear();
    notifyListeners();
  }

  void _addToQueue(ResourceLoadRequest request) {
    // Insert based on priority
    int insertIndex = _loadQueue.length;
    for (int i = 0; i < _loadQueue.length; i++) {
      if (request.priority.index < _loadQueue[i].priority.index) {
        insertIndex = i;
        break;
      }
    }
    _loadQueue.insert(insertIndex, request);
  }

  void _processQueue() {
    while (_loading.length < maxConcurrentLoads && _loadQueue.isNotEmpty) {
      final request = _loadQueue.removeAt(0);
      _loadResourceInternal(request);
    }
  }

  Future<void> _loadResourceInternal(ResourceLoadRequest request) async {
    _loading.add(request.id);

    try {
      // Ensure we have memory budget
      await _ensureMemoryBudget(request.type);

      // Load based on type
      Uint8List? data;
      switch (request.type) {
        case ResourceLoadType.background:
        case ResourceLoadType.sprite:
        case ResourceLoadType.cg:
          data = await _backend.loadImage(request.path);
          break;
        case ResourceLoadType.bgm:
        case ResourceLoadType.sfx:
        case ResourceLoadType.voice:
          data = await _backend.loadAudio(request.path);
          break;
        case ResourceLoadType.video:
          data = await _backend.loadVideo(request.path);
          break;
      }

      if (data != null) {
        final resource = LoadedResource(
          id: request.id,
          type: request.type,
          data: data,
          path: request.path,
          sizeBytes: data.length,
        );

        _cache[request.id] = resource;
        _currentMemoryUsage += resource.sizeBytes;
        _loadStates[request.id] = ResourceLoadState.loaded;
        _failedResources.remove(request.id);

        request.completer.complete(resource);
      } else {
        _handleLoadFailure(request);
      }
    } catch (e) {
      _handleLoadFailure(request);
    } finally {
      _loading.remove(request.id);
      _processQueue();
      notifyListeners();
    }
  }

  void _handleLoadFailure(ResourceLoadRequest request) {
    final retryCount = (_failedResources[request.id] ?? 0) + 1;
    _failedResources[request.id] = retryCount;

    if (retryCount < maxRetryAttempts) {
      // Re-queue with lower priority
      final retryRequest = ResourceLoadRequest(
        id: request.id,
        path: request.path,
        type: request.type,
        priority: ResourcePriority.low,
      );
      _addToQueue(retryRequest);
      request.completer.complete(null);
    } else {
      _loadStates[request.id] = ResourceLoadState.failed;
      request.completer.complete(null);
    }
  }

  Future<void> _ensureMemoryBudget(ResourceLoadType type) async {
    // Estimate size based on type
    final estimatedSize = _estimateResourceSize(type);

    while (_currentMemoryUsage + estimatedSize > maxMemoryBudget &&
        _cache.isNotEmpty) {
      await _evictLeastRecentlyUsed();
    }
  }

  int _estimateResourceSize(ResourceLoadType type) {
    switch (type) {
      case ResourceLoadType.background:
        return 4 * 1024 * 1024; // 4 MB
      case ResourceLoadType.sprite:
        return 1 * 1024 * 1024; // 1 MB
      case ResourceLoadType.cg:
        return 8 * 1024 * 1024; // 8 MB
      case ResourceLoadType.bgm:
        return 10 * 1024 * 1024; // 10 MB
      case ResourceLoadType.sfx:
        return 512 * 1024; // 512 KB
      case ResourceLoadType.voice:
        return 1 * 1024 * 1024; // 1 MB
      case ResourceLoadType.video:
        return 50 * 1024 * 1024; // 50 MB
    }
  }

  Future<void> _evictLeastRecentlyUsed() async {
    if (_cache.isEmpty) return;

    // Find LRU resource not in active chapter
    LoadedResource? lruResource;
    DateTime? oldestAccess;

    for (final resource in _cache.values) {
      // Skip resources in active chapter
      if (_activeChapterId != null) {
        final activeResources = _chapterResources[_activeChapterId];
        if (activeResources?.contains(resource.id) == true) continue;
      }

      if (oldestAccess == null ||
          resource.lastAccessedAt.isBefore(oldestAccess)) {
        oldestAccess = resource.lastAccessedAt;
        lruResource = resource;
      }
    }

    if (lruResource != null) {
      unloadResource(lruResource.id);
    }
  }

  Future<void> _evictNonActiveChapterResources() async {
    if (_activeChapterId == null) return;

    final activeResources = _chapterResources[_activeChapterId] ?? {};
    final toEvict = _cache.keys
        .where((id) => !activeResources.contains(id))
        .toList();

    for (final id in toEvict) {
      unloadResource(id);
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
