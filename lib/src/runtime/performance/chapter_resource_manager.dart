/// Chapter Resource Manager
///
/// Manages chapter-based resource loading and unloading for optimal
/// memory usage on mobile devices.
///
/// Requirements: 24.1

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'resource_loader.dart';
import '../../compiler/vn_story_bundle.dart';
import '../../compiler/vn_resource_manifest.dart';

/// Chapter loading state
enum ChapterLoadState {
  /// Chapter not loaded
  unloaded,

  /// Chapter is being loaded
  loading,

  /// Chapter loaded and ready
  ready,

  /// Chapter loading failed
  failed,
}

/// Chapter resource info
class ChapterResourceInfo {
  /// Chapter ID
  final String chapterId;

  /// Resource IDs in this chapter
  final Set<String> resourceIds;

  /// Total size of chapter resources (estimated)
  final int estimatedSizeBytes;

  /// Current load state
  ChapterLoadState loadState;

  /// Load progress (0.0 - 1.0)
  double loadProgress;

  ChapterResourceInfo({
    required this.chapterId,
    required this.resourceIds,
    this.estimatedSizeBytes = 0,
    this.loadState = ChapterLoadState.unloaded,
    this.loadProgress = 0.0,
  });
}

/// Chapter Resource Manager
///
/// Coordinates lazy loading of chapter resources with:
/// - Automatic resource discovery from compiled chapters
/// - Chapter preloading based on story flow
/// - Memory-aware chapter switching
class ChapterResourceManager extends ChangeNotifier {
  final LazyResourceLoader _loader;
  final VNResourceManifest _manifest;

  /// Chapter resource mappings
  final Map<String, ChapterResourceInfo> _chapterInfo = {};

  /// Currently active chapter
  String? _activeChapterId;

  /// Chapters that should be kept loaded
  final Set<String> _pinnedChapters = {};

  /// Loading progress stream
  final _progressController = StreamController<double>.broadcast();

  ChapterResourceManager({
    required LazyResourceLoader loader,
    required VNResourceManifest manifest,
  })  : _loader = loader,
        _manifest = manifest;

  /// Get loading progress stream
  Stream<double> get progressStream => _progressController.stream;

  /// Get active chapter ID
  String? get activeChapterId => _activeChapterId;

  /// Get chapter load state
  ChapterLoadState getChapterState(String chapterId) {
    return _chapterInfo[chapterId]?.loadState ?? ChapterLoadState.unloaded;
  }

  /// Get chapter load progress
  double getChapterProgress(String chapterId) {
    return _chapterInfo[chapterId]?.loadProgress ?? 0.0;
  }

  /// Register a chapter's resources
  void registerChapter(CompiledChapter chapter) {
    final resourceIds = _extractChapterResources(chapter);

    int estimatedSize = 0;
    for (final id in resourceIds) {
      final entry = _manifest.getEntry(id);
      if (entry != null) {
        estimatedSize += entry.size;
      }
    }

    _chapterInfo[chapter.id] = ChapterResourceInfo(
      chapterId: chapter.id,
      resourceIds: resourceIds,
      estimatedSizeBytes: estimatedSize,
    );

    _loader.registerChapterResources(chapter.id, resourceIds);
  }

  /// Register all chapters from a story bundle
  void registerBundle(VNStoryBundle bundle) {
    for (final chapter in bundle.chapters) {
      registerChapter(chapter);
    }
  }

  /// Load a chapter's resources
  Future<bool> loadChapter(String chapterId) async {
    final info = _chapterInfo[chapterId];
    if (info == null) return false;

    if (info.loadState == ChapterLoadState.ready) return true;
    if (info.loadState == ChapterLoadState.loading) {
      // Wait for existing load
      while (info.loadState == ChapterLoadState.loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return info.loadState == ChapterLoadState.ready;
    }

    info.loadState = ChapterLoadState.loading;
    info.loadProgress = 0.0;
    notifyListeners();

    try {
      final resources = info.resourceIds.toList();
      int loaded = 0;

      for (final resourceId in resources) {
        final entry = _manifest.getEntry(resourceId);
        if (entry == null) continue;

        await _loader.loadResource(
          id: resourceId,
          path: entry.path,
          type: _mapResourceType(entry.type),
          priority: ResourcePriority.high,
        );

        loaded++;
        info.loadProgress = loaded / resources.length;
        _progressController.add(info.loadProgress);
        notifyListeners();
      }

      info.loadState = ChapterLoadState.ready;
      info.loadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      info.loadState = ChapterLoadState.failed;
      notifyListeners();
      return false;
    }
  }

  /// Set active chapter (loads if needed, unloads others)
  Future<bool> setActiveChapter(String chapterId) async {
    if (_activeChapterId == chapterId) return true;

    // Load new chapter
    final success = await loadChapter(chapterId);
    if (!success) return false;

    _activeChapterId = chapterId;
    await _loader.setActiveChapter(chapterId);

    // Unload non-pinned, non-active chapters if memory is tight
    if (_loader.memoryUsagePercent > 0.7) {
      await _unloadInactiveChapters();
    }

    notifyListeners();
    return true;
  }

  /// Pin a chapter to keep it loaded
  void pinChapter(String chapterId) {
    _pinnedChapters.add(chapterId);
  }

  /// Unpin a chapter
  void unpinChapter(String chapterId) {
    _pinnedChapters.remove(chapterId);
  }

  /// Preload next chapter based on story flow
  void preloadNextChapter(String nextChapterId) {
    final info = _chapterInfo[nextChapterId];
    if (info == null || info.loadState != ChapterLoadState.unloaded) return;

    final resources = <({String id, String path, ResourceLoadType type})>[];

    for (final resourceId in info.resourceIds) {
      final entry = _manifest.getEntry(resourceId);
      if (entry != null) {
        resources.add((
          id: resourceId,
          path: entry.path,
          type: _mapResourceType(entry.type),
        ));
      }
    }

    _loader.preloadResources(resources);
  }

  /// Unload a chapter's resources
  void unloadChapter(String chapterId) {
    if (_pinnedChapters.contains(chapterId)) return;
    if (chapterId == _activeChapterId) return;

    _loader.unloadChapter(chapterId);

    final info = _chapterInfo[chapterId];
    if (info != null) {
      info.loadState = ChapterLoadState.unloaded;
      info.loadProgress = 0.0;
    }

    notifyListeners();
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'currentUsage': _loader.currentMemoryUsage,
      'maxBudget': _loader.maxMemoryBudget,
      'usagePercent': _loader.memoryUsagePercent,
      'cachedResources': _loader.cachedResourceCount,
      'queueSize': _loader.queueSize,
      'loadedChapters': _chapterInfo.values
          .where((c) => c.loadState == ChapterLoadState.ready)
          .length,
      'totalChapters': _chapterInfo.length,
    };
  }

  Set<String> _extractChapterResources(CompiledChapter chapter) {
    final resources = <String>{};

    for (final node in chapter.nodes.values) {
      switch (node.type) {
        case 'scene':
          final bg = node.data['background'] as String?;
          if (bg != null) resources.add(bg);

          final bgm = node.data['bgm'] as String?;
          if (bgm != null) resources.add(bgm);

          final dialogues = node.data['dialogues'] as List<dynamic>?;
          if (dialogues != null) {
            for (final d in dialogues) {
              final voice = (d as Map<String, dynamic>)['voiceId'] as String?;
              if (voice != null) resources.add(voice);
            }
          }
          break;

        case 'background':
          final bgId = node.data['backgroundId'] as String?;
          if (bgId != null) resources.add(bgId);
          break;

        case 'audio':
          final audioId = node.data['audioId'] as String?;
          if (audioId != null) resources.add(audioId);
          break;

        case 'cg':
          final cgId = node.data['cgId'] as String?;
          if (cgId != null) resources.add(cgId);
          break;

        case 'video':
          final videoId = node.data['videoId'] as String?;
          if (videoId != null) resources.add(videoId);
          break;

        case 'ending':
          final unlockedCGs = node.data['unlockedCGs'] as List<dynamic>?;
          if (unlockedCGs != null) {
            resources.addAll(unlockedCGs.cast<String>());
          }
          break;
      }
    }

    return resources;
  }

  ResourceLoadType _mapResourceType(ResourceType type) {
    switch (type) {
      case ResourceType.background:
        return ResourceLoadType.background;
      case ResourceType.bgm:
        return ResourceLoadType.bgm;
      case ResourceType.sfx:
        return ResourceLoadType.sfx;
      case ResourceType.voice:
        return ResourceLoadType.voice;
      case ResourceType.sprite:
        return ResourceLoadType.sprite;
      case ResourceType.cg:
        return ResourceLoadType.cg;
      case ResourceType.ui:
        return ResourceLoadType.sprite;
    }
  }

  Future<void> _unloadInactiveChapters() async {
    for (final entry in _chapterInfo.entries) {
      if (entry.key != _activeChapterId &&
          !_pinnedChapters.contains(entry.key) &&
          entry.value.loadState == ChapterLoadState.ready) {
        unloadChapter(entry.key);
      }
    }
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }
}
