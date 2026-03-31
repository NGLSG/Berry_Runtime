import 'dart:convert';

import '../models/vn_character.dart';
import '../models/vn_project.dart';
import '../models/vn_variable.dart';
import '../models/vn_theme.dart';
import 'vn_resource_manifest.dart';
import 'vn_story_bundle.dart';

/// 章节索引条目（轻量级元数据，不含节点数据）
class ChapterIndexEntry {
  final String id;
  final String title;
  final String? description;
  final String startNodeId;
  final int nodeCount;

  const ChapterIndexEntry({
    required this.id,
    required this.title,
    this.description,
    required this.startNodeId,
    required this.nodeCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'startNodeId': startNodeId,
    'nodeCount': nodeCount,
  };

  factory ChapterIndexEntry.fromJson(Map<String, dynamic> json) {
    return ChapterIndexEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startNodeId: json['startNodeId'] as String,
      nodeCount: json['nodeCount'] as int? ?? 0,
    );
  }

  factory ChapterIndexEntry.fromChapter(CompiledChapter chapter) {
    return ChapterIndexEntry(
      id: chapter.id,
      title: chapter.title,
      description: chapter.description,
      startNodeId: chapter.startNodeId,
      nodeCount: chapter.nodes.length,
    );
  }
}

/// 懒加载 Story Bundle
///
/// 与 [VNStoryBundle] 接口兼容，但章节节点按需加载。
/// 启动时只解析章节索引（轻量），实际节点数据在首次访问时才反序列化。
class LazyStoryBundle extends VNStoryBundle {
  final List<ChapterIndexEntry> chapterIndex;
  final Map<String, Map<String, dynamic>> _rawChapterData;
  final Map<String, _CachedChapter> _cache = {};
  final int maxCachedChapters;

  LazyStoryBundle._({
    required super.version,
    required super.settings,
    required super.characters,
    required super.variables,
    required super.resources,
    required super.theme,
    required this.chapterIndex,
    required Map<String, Map<String, dynamic>> rawChapterData,
    this.maxCachedChapters = 5,
  })  : _rawChapterData = rawChapterData,
        super(chapters: const []);

  factory LazyStoryBundle.fromJson(
    Map<String, dynamic> json, {
    int maxCachedChapters = 5,
  }) {
    final chaptersJson = json['chapters'] as List<dynamic>;
    final index = <ChapterIndexEntry>[];
    final rawData = <String, Map<String, dynamic>>{};

    for (final chapterJson in chaptersJson) {
      final map = chapterJson as Map<String, dynamic>;
      final id = map['id'] as String;
      index.add(ChapterIndexEntry(
        id: id,
        title: map['title'] as String,
        description: map['description'] as String?,
        startNodeId: map['startNodeId'] as String,
        nodeCount: (map['nodes'] as Map<String, dynamic>?)?.length ?? 0,
      ));
      rawData[id] = map;
    }

    return LazyStoryBundle._(
      version: json['version'] as String,
      settings: VNProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      characters: (json['characters'] as List<dynamic>)
          .map((c) => VNCharacter.fromJson(c as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as List<dynamic>)
          .map((v) => VNVariable.fromJson(v as Map<String, dynamic>))
          .toList(),
      resources: VNResourceManifest.fromJson(json['resourceManifest'] as Map<String, dynamic>),
      theme: VNTheme.fromJson(json['theme'] as Map<String, dynamic>),
      chapterIndex: index,
      rawChapterData: rawData,
      maxCachedChapters: maxCachedChapters,
    );
  }

  factory LazyStoryBundle.fromJsonString(String jsonString, {int maxCachedChapters = 5}) {
    return LazyStoryBundle.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
      maxCachedChapters: maxCachedChapters,
    );
  }

  factory LazyStoryBundle.fromBundle(VNStoryBundle bundle, {int maxCachedChapters = 5}) {
    final index = bundle.chapters.map((c) => ChapterIndexEntry.fromChapter(c)).toList();
    final rawData = <String, Map<String, dynamic>>{};
    for (final chapter in bundle.chapters) {
      rawData[chapter.id] = chapter.toJson();
    }
    return LazyStoryBundle._(
      version: bundle.version,
      settings: bundle.settings,
      characters: bundle.characters,
      variables: bundle.variables,
      resources: bundle.resources,
      theme: bundle.theme,
      chapterIndex: index,
      rawChapterData: rawData,
      maxCachedChapters: maxCachedChapters,
    );
  }

  @override
  List<CompiledChapter> get chapters {
    return chapterIndex.map((entry) => getChapter(entry.id)!).toList();
  }

  @override
  CompiledChapter? getChapter(String id) {
    final cached = _cache[id];
    if (cached != null) {
      cached.lastAccess = DateTime.now();
      return cached.chapter;
    }
    final rawJson = _rawChapterData[id];
    if (rawJson == null) return null;
    final chapter = CompiledChapter.fromJson(rawJson);
    _cache[id] = _CachedChapter(chapter);
    _evictIfNeeded();
    return chapter;
  }

  void _evictIfNeeded() {
    while (_cache.length > maxCachedChapters) {
      String? oldestKey;
      DateTime? oldestTime;
      for (final entry in _cache.entries) {
        if (oldestTime == null || entry.value.lastAccess.isBefore(oldestTime)) {
          oldestKey = entry.key;
          oldestTime = entry.value.lastAccess;
        }
      }
      if (oldestKey != null) _cache.remove(oldestKey);
    }
  }

  void preloadChapter(String id) => getChapter(id);
  void unloadChapter(String id) => _cache.remove(id);
  void clearCache() => _cache.clear();

  Map<String, dynamic> get cacheStats => {
    'cachedChapters': _cache.length,
    'maxCached': maxCachedChapters,
    'totalChapters': chapterIndex.length,
    'cachedIds': _cache.keys.toList(),
  };
}

class _CachedChapter {
  final CompiledChapter chapter;
  DateTime lastAccess;
  _CachedChapter(this.chapter) : lastAccess = DateTime.now();
}
