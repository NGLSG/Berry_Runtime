/// Chapter Jump Controller for VN Runtime
///
/// Manages cross-chapter jumps with proper variable scope handling
/// and backlog history management.
/// Requirements: 8.4

import 'variable_manager.dart';
import 'save/backlog_controller.dart';
import 'save/vn_save_data.dart';

/// Result of a chapter jump operation
class ChapterJumpResult {
  /// Source chapter ID (null if starting fresh)
  final String? sourceChapterId;

  /// Target chapter ID
  final String targetChapterId;

  /// Target node ID within the chapter
  final String targetNodeId;

  /// Whether chapter variables were reset
  final bool chapterVariablesReset;

  /// Whether backlog was preserved
  final bool backlogPreserved;

  ChapterJumpResult({
    this.sourceChapterId,
    required this.targetChapterId,
    required this.targetNodeId,
    this.chapterVariablesReset = true,
    this.backlogPreserved = true,
  });

  @override
  String toString() => 'ChapterJumpResult('
      'from: $sourceChapterId, '
      'to: $targetChapterId:$targetNodeId, '
      'varsReset: $chapterVariablesReset, '
      'backlogKept: $backlogPreserved)';
}

/// Controller for managing cross-chapter jumps
///
/// Handles:
/// - Variable scope transitions (global preserved, chapter reset, local cleared)
/// - Backlog history management during jumps
/// - State consistency during chapter transitions
class ChapterJumpController {
  /// Variable manager for scope handling
  final VariableManager _variableManager;

  /// Backlog controller for history management
  final BacklogController _backlogController;

  /// Callback when chapter changes
  final void Function(String chapterId)? onChapterChanged;

  ChapterJumpController({
    required VariableManager variableManager,
    required BacklogController backlogController,
    this.onChapterChanged,
  })  : _variableManager = variableManager,
        _backlogController = backlogController;

  /// Get current chapter ID
  String? get currentChapterId => _variableManager.currentChapterId;


  /// Execute a cross-chapter jump
  ///
  /// This method handles:
  /// 1. Global variables: Always preserved across chapters
  /// 2. Chapter variables: Reset to defaults (unless [resetChapterVariables] is false)
  /// 3. Local variables: Always cleared
  /// 4. Backlog: Preserved (unless [preserveBacklog] is false)
  ///
  /// [targetChapterId] - The chapter to jump to
  /// [targetNodeId] - The node within the target chapter to start from
  /// [resetChapterVariables] - Whether to reset chapter variables (default: true)
  /// [preserveBacklog] - Whether to keep backlog history (default: true)
  ChapterJumpResult jumpToChapter(
    String targetChapterId,
    String targetNodeId, {
    bool resetChapterVariables = true,
    bool preserveBacklog = true,
  }) {
    final sourceChapterId = _variableManager.currentChapterId;

    // Step 1: Handle chapter variables
    if (resetChapterVariables) {
      // Reset target chapter's variables to defaults
      _variableManager.resetChapterVariables(targetChapterId);
    }

    // Step 2: Switch current chapter (this also clears local variables)
    _variableManager.setCurrentChapter(targetChapterId);

    // Step 3: Handle backlog
    if (!preserveBacklog) {
      // Clear backlog for "new chapter" scenarios
      _backlogController.clear();
    }
    // Update backlog's current chapter reference
    _backlogController.setCurrentChapter(targetChapterId);

    // Step 4: Notify listeners
    onChapterChanged?.call(targetChapterId);

    return ChapterJumpResult(
      sourceChapterId: sourceChapterId,
      targetChapterId: targetChapterId,
      targetNodeId: targetNodeId,
      chapterVariablesReset: resetChapterVariables,
      backlogPreserved: preserveBacklog,
    );
  }

  /// Jump to a specific chapter and node (convenience method)
  ///
  /// Uses default settings: reset chapter variables, preserve backlog
  ChapterJumpResult jump(String chapterId, String nodeId) {
    return jumpToChapter(chapterId, nodeId);
  }

  /// Jump from a backlog entry
  ///
  /// This handles the special case of jumping back to a previous point
  /// in the story from the backlog/history screen.
  ///
  /// Note: Cross-chapter backlog jumps may require special handling
  /// as the variable state at that point may not be recoverable
  /// without a save file.
  BacklogJumpResult jumpFromBacklog(BacklogEntry entry) {
    final currentChapter = _variableManager.currentChapterId;

    if (entry.chapterId != currentChapter) {
      // Cross-chapter backlog jump
      // Note: This is a complex operation - the caller should handle
      // restoring variable state from a save if needed
      return BacklogJumpResult.crossChapter(
        entry.chapterId,
        entry.nodeId,
        entry.dialogueIndex,
      );
    }

    // Same-chapter jump - simpler case
    return BacklogJumpResult.sameChapter(
      entry.nodeId,
      entry.dialogueIndex,
    );
  }

  /// Execute a backlog jump with full state handling
  ///
  /// For cross-chapter jumps, this will:
  /// 1. Switch to the target chapter
  /// 2. NOT reset chapter variables (to preserve state as much as possible)
  /// 3. Preserve backlog history
  ///
  /// Returns the jump result for the caller to handle navigation
  BacklogJumpResult executeBacklogJump(BacklogEntry entry) {
    final result = jumpFromBacklog(entry);

    if (result.isCrossChapter) {
      // For cross-chapter jumps, switch chapter but don't reset variables
      // The caller should ideally restore from a save point
      jumpToChapter(
        result.targetChapterId,
        result.targetNodeId,
        resetChapterVariables: false, // Preserve what we have
        preserveBacklog: true,
      );
    }

    return result;
  }

  /// Check if a jump would be cross-chapter
  bool isCrossChapterJump(String targetChapterId) {
    return _variableManager.currentChapterId != targetChapterId;
  }

  /// Get variable state for saving before a jump
  ///
  /// Useful for creating a save point before a major chapter transition
  Map<String, dynamic> captureVariableState() {
    return _variableManager.exportForSave();
  }

  /// Restore variable state after a jump
  ///
  /// Used when loading a save or doing a complex backlog jump
  void restoreVariableState(Map<String, dynamic> savedState) {
    _variableManager.restoreFromSave(savedState);
  }

  /// Start a new game in a specific chapter
  ///
  /// This resets all state and starts fresh
  ChapterJumpResult startNewGame(String startChapterId, String startNodeId) {
    // Reset all variables
    _variableManager.reset();

    // Clear backlog
    _backlogController.clear();

    // Set up the starting chapter
    _variableManager.setCurrentChapter(startChapterId);
    _backlogController.setCurrentChapter(startChapterId);

    onChapterChanged?.call(startChapterId);

    return ChapterJumpResult(
      sourceChapterId: null,
      targetChapterId: startChapterId,
      targetNodeId: startNodeId,
      chapterVariablesReset: true,
      backlogPreserved: false,
    );
  }

  /// Continue from a save state
  ///
  /// Restores all state from saved data and positions at the saved location
  ChapterJumpResult continueFromSave(
    VNSaveData saveData,
    List<BacklogEntry> backlogEntries,
  ) {
    // Restore variable state
    _variableManager.restoreFromSave({
      'global': saveData.variables,
      'chapters': {}, // Chapter variables would need to be in save data
    });

    // Restore backlog
    _backlogController.restore(backlogEntries);

    // Set current chapter
    _variableManager.setCurrentChapter(saveData.currentChapterId);
    _backlogController.setCurrentChapter(saveData.currentChapterId);

    onChapterChanged?.call(saveData.currentChapterId);

    return ChapterJumpResult(
      sourceChapterId: null,
      targetChapterId: saveData.currentChapterId,
      targetNodeId: saveData.currentNodeId,
      chapterVariablesReset: false,
      backlogPreserved: true,
    );
  }
}
