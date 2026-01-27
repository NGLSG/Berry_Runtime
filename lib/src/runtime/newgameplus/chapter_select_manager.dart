/// Chapter Select Manager
///
/// Manages chapter selection and New Game+ functionality.
/// Requirements: 8.1, 8.2, 8.3

import 'dart:async';

import 'chapter_info.dart';
import 'newgameplus_config.dart';
import '../progress/global_progress_manager.dart';
import '../save/vn_save_data.dart';

/// Event emitted when chapter select state changes
abstract class ChapterSelectEvent {
  final DateTime timestamp;
  ChapterSelectEvent() : timestamp = DateTime.now();
}

/// Event emitted when a chapter is unlocked
class ChapterUnlockedEvent extends ChapterSelectEvent {
  final String chapterId;
  final String chapterTitle;

  ChapterUnlockedEvent({
    required this.chapterId,
    required this.chapterTitle,
  });
}

/// Event emitted when first playthrough is completed
class FirstPlaythroughCompleteEvent extends ChapterSelectEvent {
  FirstPlaythroughCompleteEvent();
}

/// Event emitted when New Game+ is started
class NewGamePlusStartedEvent extends ChapterSelectEvent {
  final int newGamePlusCount;
  final String? startingChapterId;

  NewGamePlusStartedEvent({
    required this.newGamePlusCount,
    this.startingChapterId,
  });
}

/// Chapter Select Manager
///
/// Manages chapter selection screen and New Game+ functionality.
/// Integrates with GlobalProgressManager for persistence.
class ChapterSelectManager {
  final GlobalProgressManager _progressManager;
  final NewGamePlusConfig _config;
  final List<ChapterInfo> _chapters;

  final StreamController<ChapterSelectEvent> _eventController =
      StreamController<ChapterSelectEvent>.broadcast();

  /// Stream of chapter select events
  Stream<ChapterSelectEvent> get events => _eventController.stream;

  /// Current New Game+ state (null if not in NG+ mode)
  NewGamePlusState? _currentNGPlusState;

  ChapterSelectManager({
    required GlobalProgressManager progressManager,
    required List<ChapterInfo> chapters,
    NewGamePlusConfig config = const NewGamePlusConfig(),
  })  : _progressManager = progressManager,
        _chapters = List.from(chapters)..sort((a, b) => a.order.compareTo(b.order)),
        _config = config;

  // ============================================================
  // Chapter Information
  // ============================================================

  /// Get all chapter definitions
  List<ChapterInfo> get chapters => List.unmodifiable(_chapters);

  /// Get chapter by ID
  ChapterInfo? getChapterById(String chapterId) {
    try {
      return _chapters.firstWhere((c) => c.id == chapterId);
    } catch (_) {
      return null;
    }
  }

  /// Get the starting chapter
  ChapterInfo? get startingChapter {
    try {
      return _chapters.firstWhere((c) => c.isStartingChapter);
    } catch (_) {
      return _chapters.isNotEmpty ? _chapters.first : null;
    }
  }

  // ============================================================
  // Chapter Unlock Status
  // ============================================================

  /// Check if chapter select is available
  bool get isChapterSelectAvailable {
    if (!_config.enabled) return false;
    if (_config.requireFirstPlaythrough) {
      return _progressManager.isFirstPlaythroughComplete;
    }
    return true;
  }

  /// Check if a chapter is unlocked
  bool isChapterUnlocked(String chapterId) {
    // Starting chapter is always unlocked
    final chapter = getChapterById(chapterId);
    if (chapter?.isStartingChapter == true) return true;

    return _progressManager.isChapterUnlocked(chapterId);
  }

  /// Unlock a chapter
  void unlockChapter(String chapterId) {
    if (isChapterUnlocked(chapterId)) return;

    _progressManager.unlockChapter(chapterId);

    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      _eventController.add(ChapterUnlockedEvent(
        chapterId: chapterId,
        chapterTitle: chapter.title,
      ));
    }
  }

  /// Get chapter statuses for UI display
  List<ChapterSelectStatus> getChapterStatuses() {
    return _chapters.map((chapter) {
      final isUnlocked = isChapterUnlocked(chapter.id);
      return ChapterSelectStatus(
        chapter: chapter,
        isUnlocked: isUnlocked,
        isCompleted: _isChapterCompleted(chapter.id),
      );
    }).toList();
  }

  /// Get unlocked chapters only
  List<ChapterInfo> getUnlockedChapters() {
    return _chapters.where((c) => isChapterUnlocked(c.id)).toList();
  }

  /// Get completion percentage
  double get completionPercentage {
    if (_chapters.isEmpty) return 0.0;
    final unlocked = _chapters.where((c) => isChapterUnlocked(c.id)).length;
    return unlocked / _chapters.length;
  }

  bool _isChapterCompleted(String chapterId) {
    // A chapter is considered completed if the next chapter is unlocked
    // or if it's the last chapter and first playthrough is complete
    final chapterIndex = _chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex < 0) return false;

    if (chapterIndex < _chapters.length - 1) {
      // Check if next chapter is unlocked
      return isChapterUnlocked(_chapters[chapterIndex + 1].id);
    } else {
      // Last chapter - check if first playthrough is complete
      return _progressManager.isFirstPlaythroughComplete;
    }
  }

  // ============================================================
  // First Playthrough Detection
  // ============================================================

  /// Check if first playthrough is complete
  bool get isFirstPlaythroughComplete =>
      _progressManager.isFirstPlaythroughComplete;

  /// Mark first playthrough as complete
  void markFirstPlaythroughComplete() {
    if (_progressManager.isFirstPlaythroughComplete) return;

    _progressManager.markFirstPlaythroughComplete();

    // Unlock all visited chapters
    for (final chapter in _chapters) {
      if (_progressManager.isNodeVisited(chapter.id)) {
        unlockChapter(chapter.id);
      }
    }

    _eventController.add(FirstPlaythroughCompleteEvent());
  }

  /// Record entering a chapter (for auto-unlock tracking)
  void recordChapterEntry(String chapterId) {
    // Record node visit for flowchart
    _progressManager.recordNodeVisit(chapterId);

    // Auto-unlock the chapter when entered
    unlockChapter(chapterId);
  }

  // ============================================================
  // New Game+ Functionality
  // ============================================================

  /// Check if New Game+ is available
  bool get isNewGamePlusAvailable {
    if (!_config.enabled) return false;

    // Check first playthrough requirement
    if (_config.requireFirstPlaythrough &&
        !_progressManager.isFirstPlaythroughComplete) {
      return false;
    }

    // Check ending count requirement
    if (_config.requiredEndingsForUnlock > 0) {
      final endingCount = _progressManager.data.endings.reachedIds.length;
      if (endingCount < _config.requiredEndingsForUnlock) {
        return false;
      }
    }

    return true;
  }

  /// Get current New Game+ state
  NewGamePlusState? get currentNewGamePlusState => _currentNGPlusState;

  /// Check if currently in New Game+ mode
  bool get isInNewGamePlusMode => _currentNGPlusState?.isNewGamePlus ?? false;

  /// Get New Game+ count
  int get newGamePlusCount => _currentNGPlusState?.newGamePlusCount ?? 0;

  /// Create New Game+ state from completed save
  NewGamePlusState createNewGamePlusState(VNSaveData completedSave) {
    // Get affection values from progress manager
    final affectionValues = <String, int>{};
    for (final entry in _progressManager.data.affection.values.entries) {
      affectionValues[entry.key] = entry.value;
    }

    return NewGamePlusState.fromCompletedSave(
      variables: completedSave.variables,
      readDialogueIds: completedSave.readDialogueIds,
      affectionValues: affectionValues,
      config: _config,
      previousCount: _currentNGPlusState?.newGamePlusCount ?? 0,
    );
  }

  /// Start New Game+ with the given state
  void startNewGamePlus(NewGamePlusState state, {String? startingChapterId}) {
    _currentNGPlusState = state;

    _eventController.add(NewGamePlusStartedEvent(
      newGamePlusCount: state.newGamePlusCount,
      startingChapterId: startingChapterId,
    ));
  }

  /// Start New Game+ from a completed save
  NewGamePlusState startNewGamePlusFromSave(
    VNSaveData completedSave, {
    String? startingChapterId,
  }) {
    final state = createNewGamePlusState(completedSave);
    startNewGamePlus(state, startingChapterId: startingChapterId);
    return state;
  }

  /// Clear New Game+ state (for regular new game)
  void clearNewGamePlusState() {
    _currentNGPlusState = null;
  }

  /// Get initial variables for a new game (with NG+ carryover if applicable)
  Map<String, dynamic> getInitialVariables(
      Map<String, dynamic> defaultVariables) {
    final variables = Map<String, dynamic>.from(defaultVariables);

    if (_currentNGPlusState != null && _currentNGPlusState!.isNewGamePlus) {
      // Apply carried over variables
      for (final entry in _currentNGPlusState!.carryOverVariables.entries) {
        variables[entry.key] = entry.value;
      }
    }

    return variables;
  }

  /// Get initial read state for a new game (with NG+ carryover if applicable)
  Set<String> getInitialReadState() {
    if (_currentNGPlusState != null &&
        _currentNGPlusState!.isNewGamePlus &&
        _config.carryOverReadState) {
      return Set.from(_currentNGPlusState!.carryOverReadState);
    }
    return {};
  }

  /// Get initial affection values for a new game (with NG+ carryover if applicable)
  Map<String, int> getInitialAffection() {
    if (_currentNGPlusState != null &&
        _currentNGPlusState!.isNewGamePlus &&
        _config.carryOverAffection) {
      return Map.from(_currentNGPlusState!.carryOverAffection);
    }
    return {};
  }

  // ============================================================
  // Configuration
  // ============================================================

  /// Get current New Game+ configuration
  NewGamePlusConfig get config => _config;

  /// Get variables marked for NG+ carryover
  Set<String> get carryOverVariables => _config.carryOverVariables;

  /// Check if a variable is marked for NG+ carryover
  bool isVariableCarryOver(String variableName) {
    return _config.shouldCarryOver(variableName);
  }

  // ============================================================
  // Persistence
  // ============================================================

  /// Save New Game+ state to JSON
  Map<String, dynamic>? saveNewGamePlusState() {
    return _currentNGPlusState?.toJson();
  }

  /// Load New Game+ state from JSON
  void loadNewGamePlusState(Map<String, dynamic>? json) {
    if (json != null) {
      _currentNGPlusState = NewGamePlusState.fromJson(json);
    } else {
      _currentNGPlusState = null;
    }
  }

  // ============================================================
  // Cleanup
  // ============================================================

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}
