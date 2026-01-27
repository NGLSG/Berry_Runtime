/// Play Statistics System for VNBS
///
/// Provides a high-level API for tracking gameplay statistics including:
/// - Total play time
/// - Dialogue read tracking
/// - Choice distribution
/// - Ending history
///
/// Requirements: 7.1, 7.2, 7.3, 7.4

import 'dart:async';
import '../progress/global_progress_manager.dart';

/// Play statistics manager
///
/// Wraps GlobalProgressManager statistics functionality with a cleaner API
/// and additional features for UI display.
class PlayStatistics {
  final GlobalProgressManager _progressManager;
  
  /// Session start time for current play session
  DateTime? _sessionStartTime;
  
  /// Timer for periodic auto-save during session
  Timer? _autoSaveTimer;
  
  /// Auto-save interval
  static const Duration _autoSaveInterval = Duration(minutes: 5);

  PlayStatistics(this._progressManager);

  // ============================================================
  // Time Tracking (Requirement 7.1)
  // ============================================================

  /// Get total play time across all sessions
  Duration get totalPlayTime => _progressManager.data.statistics.totalPlayTime;

  /// Get formatted total play time string
  String get formattedPlayTime {
    final duration = totalPlayTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get play time in hours (for display)
  double get playTimeInHours => totalPlayTime.inMinutes / 60.0;

  /// Check if a session is currently active
  bool get isSessionActive => _sessionStartTime != null;

  /// Start a play session
  void startSession() {
    if (_sessionStartTime != null) return; // Already in session
    
    _sessionStartTime = DateTime.now();
    _progressManager.startSession();
    
    // Start auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      _progressManager.saveIfDirty();
    });
  }

  /// End the current play session
  void endSession() {
    if (_sessionStartTime == null) return;
    
    _progressManager.endSession();
    _sessionStartTime = null;
    
    // Stop auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    
    // Save progress
    _progressManager.saveIfDirty();
  }

  /// Get current session duration
  Duration get currentSessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // ============================================================
  // Dialogue Read Tracking (Requirement 7.2)
  // ============================================================

  /// Get total dialogues read (including re-reads)
  int get totalDialoguesRead => _progressManager.data.statistics.totalDialoguesRead;

  /// Get unique dialogues read count
  int get uniqueDialoguesRead => 
      _progressManager.data.statistics.uniqueDialoguesRead.length;

  /// Get set of unique dialogue IDs that have been read
  Set<String> get readDialogueIds => 
      Set.from(_progressManager.data.statistics.uniqueDialoguesRead);

  /// Record a dialogue being read
  void recordDialogueRead(String dialogueId) {
    _progressManager.recordDialogueRead(dialogueId);
  }

  /// Check if a specific dialogue has been read
  bool isDialogueRead(String dialogueId) {
    return _progressManager.data.statistics.uniqueDialoguesRead.contains(dialogueId);
  }

  /// Get read progress percentage (0.0 - 1.0)
  double getReadProgress(int totalDialogues) {
    return _progressManager.getReadProgress(totalDialogues);
  }

  /// Get formatted read progress string
  String getFormattedReadProgress(int totalDialogues) {
    final percentage = getReadProgress(totalDialogues) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  // ============================================================
  // Choice Distribution Tracking (Requirement 7.3)
  // ============================================================

  /// Get raw choice distribution data
  Map<String, Map<String, int>> get choiceDistribution =>
      Map.from(_progressManager.data.statistics.choiceDistribution);

  /// Record a choice being made
  void recordChoice(String choiceNodeId, String selectedOptionId) {
    _progressManager.recordChoice(choiceNodeId, selectedOptionId);
  }

  /// Get choice percentages for a specific choice node
  Map<String, double> getChoicePercentages(String choiceNodeId) {
    return _progressManager.getChoicePercentages(choiceNodeId);
  }

  /// Get total times a specific choice node was encountered
  int getChoiceEncounterCount(String choiceNodeId) {
    final choices = _progressManager.data.statistics.choiceDistribution[choiceNodeId];
    if (choices == null) return 0;
    return choices.values.fold(0, (sum, count) => sum + count);
  }

  /// Get the most selected option for a choice node
  String? getMostSelectedOption(String choiceNodeId) {
    final choices = _progressManager.data.statistics.choiceDistribution[choiceNodeId];
    if (choices == null || choices.isEmpty) return null;
    
    String? mostSelected;
    int maxCount = 0;
    
    for (final entry in choices.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostSelected = entry.key;
      }
    }
    
    return mostSelected;
  }

  /// Get all tracked choice node IDs
  Set<String> get trackedChoiceNodeIds =>
      _progressManager.data.statistics.choiceDistribution.keys.toSet();

  // ============================================================
  // Ending History (Requirement 7.4)
  // ============================================================

  /// Get ending history
  List<EndingRecord> get endingHistory =>
      List.from(_progressManager.data.statistics.endingHistory);

  /// Get number of endings reached
  int get endingsReachedCount => endingHistory.length;

  /// Get unique endings reached
  Set<String> get uniqueEndingsReached =>
      endingHistory.map((e) => e.endingId).toSet();

  /// Get the first ending reached
  EndingRecord? get firstEndingReached =>
      endingHistory.isNotEmpty ? endingHistory.first : null;

  /// Get the most recent ending reached
  EndingRecord? get lastEndingReached =>
      endingHistory.isNotEmpty ? endingHistory.last : null;

  /// Get ending reach count by ending ID
  Map<String, int> get endingReachCounts {
    final counts = <String, int>{};
    for (final record in endingHistory) {
      counts.update(record.endingId, (c) => c + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  // ============================================================
  // Summary Statistics
  // ============================================================

  /// Get a summary of all statistics
  StatisticsSummary getSummary({int? totalDialogues, int? totalEndings}) {
    return StatisticsSummary(
      totalPlayTime: totalPlayTime,
      formattedPlayTime: formattedPlayTime,
      totalDialoguesRead: totalDialoguesRead,
      uniqueDialoguesRead: uniqueDialoguesRead,
      readProgress: totalDialogues != null ? getReadProgress(totalDialogues) : null,
      totalChoicesMade: choiceDistribution.values
          .fold(0, (sum, choices) => sum + choices.values.fold(0, (s, c) => s + c)),
      uniqueChoicesTracked: trackedChoiceNodeIds.length,
      endingsReached: uniqueEndingsReached.length,
      totalEndingPlays: endingsReachedCount,
      endingCompletionProgress: totalEndings != null && totalEndings > 0
          ? uniqueEndingsReached.length / totalEndings
          : null,
    );
  }

  // ============================================================
  // Persistence
  // ============================================================

  /// Save statistics to persistent storage
  Future<bool> save() => _progressManager.save();

  /// Load statistics from persistent storage
  Future<bool> load() => _progressManager.load();

  /// Reset all statistics
  Future<void> reset() async {
    await _progressManager.reset();
  }

  /// Dispose resources
  void dispose() {
    endSession();
    _autoSaveTimer?.cancel();
  }
}


/// Summary of all statistics for display
class StatisticsSummary {
  /// Total play time
  final Duration totalPlayTime;
  
  /// Formatted play time string
  final String formattedPlayTime;
  
  /// Total dialogues read (including re-reads)
  final int totalDialoguesRead;
  
  /// Unique dialogues read
  final int uniqueDialoguesRead;
  
  /// Read progress (0.0 - 1.0), null if total unknown
  final double? readProgress;
  
  /// Total choices made across all choice nodes
  final int totalChoicesMade;
  
  /// Number of unique choice nodes tracked
  final int uniqueChoicesTracked;
  
  /// Number of unique endings reached
  final int endingsReached;
  
  /// Total number of ending plays (including replays)
  final int totalEndingPlays;
  
  /// Ending completion progress (0.0 - 1.0), null if total unknown
  final double? endingCompletionProgress;

  const StatisticsSummary({
    required this.totalPlayTime,
    required this.formattedPlayTime,
    required this.totalDialoguesRead,
    required this.uniqueDialoguesRead,
    this.readProgress,
    required this.totalChoicesMade,
    required this.uniqueChoicesTracked,
    required this.endingsReached,
    required this.totalEndingPlays,
    this.endingCompletionProgress,
  });
}


/// Choice statistics for a single choice node
class ChoiceStatistics {
  /// Choice node ID
  final String choiceNodeId;
  
  /// Display label for the choice
  final String? label;
  
  /// Total times this choice was encountered
  final int totalEncounters;
  
  /// Distribution of selections (optionId -> count)
  final Map<String, int> distribution;
  
  /// Percentage distribution (optionId -> percentage 0.0-1.0)
  final Map<String, double> percentages;
  
  /// Most selected option ID
  final String? mostSelectedOption;

  const ChoiceStatistics({
    required this.choiceNodeId,
    this.label,
    required this.totalEncounters,
    required this.distribution,
    required this.percentages,
    this.mostSelectedOption,
  });

  /// Create from PlayStatistics
  factory ChoiceStatistics.fromPlayStatistics(
    PlayStatistics stats,
    String choiceNodeId, {
    String? label,
  }) {
    final distribution = stats.choiceDistribution[choiceNodeId] ?? {};
    final percentages = stats.getChoicePercentages(choiceNodeId);
    
    return ChoiceStatistics(
      choiceNodeId: choiceNodeId,
      label: label,
      totalEncounters: stats.getChoiceEncounterCount(choiceNodeId),
      distribution: Map.from(distribution),
      percentages: percentages,
      mostSelectedOption: stats.getMostSelectedOption(choiceNodeId),
    );
  }
}
