import 'vn_save_data.dart';

/// Backlog controller for VN runtime
/// 
/// Manages dialogue history with support for backlog jump (same chapter/cross chapter).
/// Requirements: 13.10

/// Result of a backlog jump operation
class BacklogJumpResult {
  /// Whether this is a cross-chapter jump
  final bool isCrossChapter;
  
  /// Target chapter ID
  final String targetChapterId;
  
  /// Target node ID
  final String targetNodeId;
  
  /// Target dialogue index within the node
  final int targetDialogueIndex;

  BacklogJumpResult._({
    required this.isCrossChapter,
    required this.targetChapterId,
    required this.targetNodeId,
    required this.targetDialogueIndex,
  });

  /// Create result for same-chapter jump
  factory BacklogJumpResult.sameChapter(String nodeId, int dialogueIndex) {
    return BacklogJumpResult._(
      isCrossChapter: false,
      targetChapterId: '',
      targetNodeId: nodeId,
      targetDialogueIndex: dialogueIndex,
    );
  }

  /// Create result for cross-chapter jump
  factory BacklogJumpResult.crossChapter(
    String chapterId, 
    String nodeId, 
    int dialogueIndex,
  ) {
    return BacklogJumpResult._(
      isCrossChapter: true,
      targetChapterId: chapterId,
      targetNodeId: nodeId,
      targetDialogueIndex: dialogueIndex,
    );
  }

  @override
  String toString() => isCrossChapter
      ? 'BacklogJumpResult(cross: $targetChapterId:$targetNodeId:$targetDialogueIndex)'
      : 'BacklogJumpResult(same: $targetNodeId:$targetDialogueIndex)';
}

/// Controller for managing backlog/history
class BacklogController {
  /// Maximum number of entries to keep
  static const int maxBacklogSize = 500;

  /// Internal list of backlog entries
  final List<BacklogEntry> _entries = [];

  /// Current chapter ID for tracking cross-chapter jumps
  String? _currentChapterId;

  BacklogController({String? currentChapterId}) 
      : _currentChapterId = currentChapterId;

  /// Set current chapter
  void setCurrentChapter(String chapterId) {
    _currentChapterId = chapterId;
  }

  /// Get current chapter ID
  String? get currentChapterId => _currentChapterId;

  /// Add a new entry to the backlog
  void addEntry(BacklogEntry entry) {
    _entries.add(entry);
    
    // Trim if exceeds max size
    while (_entries.length > maxBacklogSize) {
      _entries.removeAt(0);
    }
  }

  /// Add entry from components
  void add({
    required String chapterId,
    required String nodeId,
    required int dialogueIndex,
    required String speakerName,
    required String text,
    String? voiceId,
  }) {
    addEntry(BacklogEntry(
      chapterId: chapterId,
      nodeId: nodeId,
      dialogueIndex: dialogueIndex,
      speakerName: speakerName,
      text: text,
      voiceId: voiceId,
    ));
  }

  /// Get all entries (read-only)
  List<BacklogEntry> get entries => List.unmodifiable(_entries);

  /// Get entry count
  int get length => _entries.length;

  /// Check if backlog is empty
  bool get isEmpty => _entries.isEmpty;

  /// Check if backlog is not empty
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Get entry at index
  BacklogEntry? getAt(int index) {
    if (index < 0 || index >= _entries.length) return null;
    return _entries[index];
  }

  /// Get the most recent entry
  BacklogEntry? get lastEntry => _entries.isNotEmpty ? _entries.last : null;

  /// Get entries in reverse order (most recent first)
  List<BacklogEntry> get reversedEntries => _entries.reversed.toList();


  /// Jump to a specific backlog entry
  /// 
  /// Returns jump result indicating whether it's same-chapter or cross-chapter
  BacklogJumpResult jumpTo(BacklogEntry entry) {
    if (_currentChapterId != null && entry.chapterId != _currentChapterId) {
      return BacklogJumpResult.crossChapter(
        entry.chapterId,
        entry.nodeId,
        entry.dialogueIndex,
      );
    }
    
    return BacklogJumpResult.sameChapter(
      entry.nodeId,
      entry.dialogueIndex,
    );
  }

  /// Jump to entry at index
  BacklogJumpResult? jumpToIndex(int index) {
    final entry = getAt(index);
    if (entry == null) return null;
    return jumpTo(entry);
  }

  /// Find entries by chapter
  List<BacklogEntry> getEntriesInChapter(String chapterId) {
    return _entries.where((e) => e.chapterId == chapterId).toList();
  }

  /// Find entries by node
  List<BacklogEntry> getEntriesInNode(String chapterId, String nodeId) {
    return _entries
        .where((e) => e.chapterId == chapterId && e.nodeId == nodeId)
        .toList();
  }

  /// Find entry by dialogue ID
  BacklogEntry? findByDialogueId(String dialogueId) {
    try {
      return _entries.firstWhere((e) => e.dialogueId == dialogueId);
    } catch (_) {
      return null;
    }
  }

  /// Get index of entry
  int indexOf(BacklogEntry entry) {
    return _entries.indexOf(entry);
  }

  /// Check if entry exists
  bool contains(BacklogEntry entry) {
    return _entries.contains(entry);
  }

  /// Check if dialogue ID exists in backlog
  bool containsDialogueId(String dialogueId) {
    return _entries.any((e) => e.dialogueId == dialogueId);
  }

  /// Clear all entries (for new game)
  void clear() {
    _entries.clear();
  }

  /// Restore from saved entries
  void restore(List<BacklogEntry> savedEntries) {
    _entries.clear();
    _entries.addAll(savedEntries);
    
    // Ensure we don't exceed max size
    while (_entries.length > maxBacklogSize) {
      _entries.removeAt(0);
    }
  }

  /// Export entries for saving
  List<BacklogEntry> export() {
    return List.from(_entries);
  }

  /// Trim entries to a specific count
  void trimTo(int count) {
    while (_entries.length > count) {
      _entries.removeAt(0);
    }
  }

  /// Remove entries after a specific index (for rollback)
  void removeAfter(int index) {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeRange(index + 1, _entries.length);
  }

  /// Get chapter boundaries (indices where chapter changes)
  List<int> getChapterBoundaries() {
    final boundaries = <int>[];
    String? lastChapter;
    
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].chapterId != lastChapter) {
        boundaries.add(i);
        lastChapter = _entries[i].chapterId;
      }
    }
    
    return boundaries;
  }

  /// Get entries grouped by chapter
  Map<String, List<BacklogEntry>> getEntriesByChapter() {
    final grouped = <String, List<BacklogEntry>>{};
    
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.chapterId, () => []).add(entry);
    }
    
    return grouped;
  }

  /// Search entries by text content
  List<BacklogEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) => 
      e.text.toLowerCase().contains(lowerQuery) ||
      e.speakerName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get entries by speaker
  List<BacklogEntry> getEntriesBySpeaker(String speakerName) {
    return _entries.where((e) => e.speakerName == speakerName).toList();
  }

  /// Get unique speakers in backlog
  Set<String> get uniqueSpeakers {
    return _entries.map((e) => e.speakerName).toSet();
  }

  /// Get statistics
  BacklogStats getStats() {
    final chapters = <String>{};
    final speakers = <String>{};
    
    for (final entry in _entries) {
      chapters.add(entry.chapterId);
      speakers.add(entry.speakerName);
    }
    
    return BacklogStats(
      totalEntries: _entries.length,
      chaptersVisited: chapters.length,
      uniqueSpeakers: speakers.length,
    );
  }
}


/// Statistics about backlog
class BacklogStats {
  final int totalEntries;
  final int chaptersVisited;
  final int uniqueSpeakers;

  const BacklogStats({
    required this.totalEntries,
    required this.chaptersVisited,
    required this.uniqueSpeakers,
  });

  @override
  String toString() => 'BacklogStats('
      'entries: $totalEntries, '
      'chapters: $chaptersVisited, '
      'speakers: $uniqueSpeakers)';
}

/// Extension for backlog navigation
extension BacklogNavigationExtension on BacklogController {
  /// Get previous entry from current position
  BacklogEntry? getPrevious(int currentIndex) {
    if (currentIndex <= 0) return null;
    return getAt(currentIndex - 1);
  }

  /// Get next entry from current position
  BacklogEntry? getNext(int currentIndex) {
    if (currentIndex >= length - 1) return null;
    return getAt(currentIndex + 1);
  }

  /// Get entries in a range
  List<BacklogEntry> getRange(int start, int end) {
    final safeStart = start.clamp(0, length);
    final safeEnd = end.clamp(0, length);
    return _entries.sublist(safeStart, safeEnd);
  }

  /// Get last N entries
  List<BacklogEntry> getLastN(int count) {
    if (count >= length) return List.from(_entries);
    return _entries.sublist(length - count);
  }

  /// Get first N entries
  List<BacklogEntry> getFirstN(int count) {
    if (count >= length) return List.from(_entries);
    return _entries.sublist(0, count);
  }

  /// Find the index of the first entry in a chapter
  int? findChapterStart(String chapterId) {
    for (int i = 0; i < length; i++) {
      if (_entries[i].chapterId == chapterId) {
        return i;
      }
    }
    return null;
  }

  /// Find the index of the last entry in a chapter
  int? findChapterEnd(String chapterId) {
    for (int i = length - 1; i >= 0; i--) {
      if (_entries[i].chapterId == chapterId) {
        return i;
      }
    }
    return null;
  }
}
