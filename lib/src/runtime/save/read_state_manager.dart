/// Read state manager for VN runtime
/// 
/// Tracks which dialogues have been read at dialogue-level granularity.
/// Format: "chapterId:nodeId:dialogueIndex"
/// Requirements: 15.9

/// Manager for tracking read dialogue state
class ReadStateManager {
  /// Set of read dialogue IDs
  final Set<String> _readDialogueIds;

  ReadStateManager([Set<String>? initialReadIds])
      : _readDialogueIds = initialReadIds != null 
            ? Set.from(initialReadIds) 
            : {};

  /// Create dialogue ID from components
  static String createDialogueId(
    String chapterId, 
    String nodeId, 
    int dialogueIndex,
  ) {
    return '$chapterId:$nodeId:$dialogueIndex';
  }

  /// Parse dialogue ID into components
  static DialogueLocation? parseDialogueId(String dialogueId) {
    final parts = dialogueId.split(':');
    if (parts.length != 3) return null;
    
    final index = int.tryParse(parts[2]);
    if (index == null) return null;
    
    return DialogueLocation(
      chapterId: parts[0],
      nodeId: parts[1],
      dialogueIndex: index,
    );
  }

  /// Mark a specific dialogue as read
  void markRead(String chapterId, String nodeId, int dialogueIndex) {
    _readDialogueIds.add(createDialogueId(chapterId, nodeId, dialogueIndex));
  }

  /// Mark dialogue as read using dialogue ID
  void markReadById(String dialogueId) {
    _readDialogueIds.add(dialogueId);
  }

  /// Check if a specific dialogue has been read
  bool isRead(String chapterId, String nodeId, int dialogueIndex) {
    return _readDialogueIds.contains(
      createDialogueId(chapterId, nodeId, dialogueIndex),
    );
  }

  /// Check if dialogue is read using dialogue ID
  bool isReadById(String dialogueId) {
    return _readDialogueIds.contains(dialogueId);
  }

  /// Check if an entire node has been fully read
  bool isNodeFullyRead(String chapterId, String nodeId, int totalDialogues) {
    for (int i = 0; i < totalDialogues; i++) {
      if (!isRead(chapterId, nodeId, i)) {
        return false;
      }
    }
    return true;
  }

  /// Get read progress for a node (0.0 to 1.0)
  double getNodeReadProgress(String chapterId, String nodeId, int totalDialogues) {
    if (totalDialogues == 0) return 1.0;
    
    int readCount = 0;
    for (int i = 0; i < totalDialogues; i++) {
      if (isRead(chapterId, nodeId, i)) {
        readCount++;
      }
    }
    return readCount / totalDialogues;
  }

  /// Check if skip is allowed for this dialogue
  /// 
  /// In skip mode, only read content can be skipped unless skipUnread is enabled
  bool canSkip(
    String chapterId, 
    String nodeId, 
    int dialogueIndex, 
    bool skipUnread,
  ) {
    if (skipUnread) return true;
    return isRead(chapterId, nodeId, dialogueIndex);
  }

  /// Get all read dialogue IDs
  Set<String> get readDialogueIds => Set.unmodifiable(_readDialogueIds);

  /// Get count of read dialogues
  int get readCount => _readDialogueIds.length;

  /// Clear all read state (for new game)
  void clear() {
    _readDialogueIds.clear();
  }

  /// Restore from saved state
  void restore(Set<String> savedIds) {
    _readDialogueIds.clear();
    _readDialogueIds.addAll(savedIds);
  }

  /// Export for saving
  Set<String> export() {
    return Set.from(_readDialogueIds);
  }

  /// Merge with another read state (for combining saves)
  void merge(ReadStateManager other) {
    _readDialogueIds.addAll(other._readDialogueIds);
  }

  /// Get all read dialogues for a specific chapter
  List<String> getReadDialoguesInChapter(String chapterId) {
    return _readDialogueIds
        .where((id) => id.startsWith('$chapterId:'))
        .toList();
  }

  /// Get all read dialogues for a specific node
  List<int> getReadDialogueIndicesInNode(String chapterId, String nodeId) {
    final prefix = '$chapterId:$nodeId:';
    return _readDialogueIds
        .where((id) => id.startsWith(prefix))
        .map((id) => int.tryParse(id.substring(prefix.length)))
        .whereType<int>()
        .toList()
      ..sort();
  }

  /// Check if any dialogue in a node has been read
  bool hasReadAnyInNode(String chapterId, String nodeId) {
    final prefix = '$chapterId:$nodeId:';
    return _readDialogueIds.any((id) => id.startsWith(prefix));
  }

  /// Get statistics
  ReadStateStats getStats() {
    final chapters = <String>{};
    final nodes = <String>{};
    
    for (final id in _readDialogueIds) {
      final location = parseDialogueId(id);
      if (location != null) {
        chapters.add(location.chapterId);
        nodes.add('${location.chapterId}:${location.nodeId}');
      }
    }
    
    return ReadStateStats(
      totalDialoguesRead: _readDialogueIds.length,
      chaptersVisited: chapters.length,
      nodesVisited: nodes.length,
    );
  }
}


/// Represents a dialogue location
class DialogueLocation {
  final String chapterId;
  final String nodeId;
  final int dialogueIndex;

  const DialogueLocation({
    required this.chapterId,
    required this.nodeId,
    required this.dialogueIndex,
  });

  String get dialogueId => '$chapterId:$nodeId:$dialogueIndex';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogueLocation &&
          chapterId == other.chapterId &&
          nodeId == other.nodeId &&
          dialogueIndex == other.dialogueIndex;

  @override
  int get hashCode => Object.hash(chapterId, nodeId, dialogueIndex);

  @override
  String toString() => 'DialogueLocation($dialogueId)';
}

/// Statistics about read state
class ReadStateStats {
  final int totalDialoguesRead;
  final int chaptersVisited;
  final int nodesVisited;

  const ReadStateStats({
    required this.totalDialoguesRead,
    required this.chaptersVisited,
    required this.nodesVisited,
  });

  @override
  String toString() => 'ReadStateStats('
      'dialogues: $totalDialoguesRead, '
      'chapters: $chaptersVisited, '
      'nodes: $nodesVisited)';
}

/// Extension for convenient read state operations
extension ReadStateManagerExtension on ReadStateManager {
  /// Mark a range of dialogues as read
  void markRangeRead(
    String chapterId, 
    String nodeId, 
    int startIndex, 
    int endIndex,
  ) {
    for (int i = startIndex; i <= endIndex; i++) {
      markRead(chapterId, nodeId, i);
    }
  }

  /// Mark all dialogues in a node as read
  void markNodeRead(String chapterId, String nodeId, int totalDialogues) {
    markRangeRead(chapterId, nodeId, 0, totalDialogues - 1);
  }

  /// Get the first unread dialogue index in a node
  /// Returns null if all are read or node is empty
  int? getFirstUnreadIndex(String chapterId, String nodeId, int totalDialogues) {
    for (int i = 0; i < totalDialogues; i++) {
      if (!isRead(chapterId, nodeId, i)) {
        return i;
      }
    }
    return null;
  }

  /// Get the last read dialogue index in a node
  /// Returns -1 if none are read
  int getLastReadIndex(String chapterId, String nodeId, int totalDialogues) {
    for (int i = totalDialogues - 1; i >= 0; i--) {
      if (isRead(chapterId, nodeId, i)) {
        return i;
      }
    }
    return -1;
  }
}
