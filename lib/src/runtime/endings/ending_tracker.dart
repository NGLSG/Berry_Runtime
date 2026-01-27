/// Ending Tracker for VNBS
///
/// Tracks all reached endings across all save files.
/// Provides completion percentage and reach order tracking.
/// Requirements: 3.1, 3.4

import 'dart:async';

import '../progress/global_progress_manager.dart';
import 'ending_definition.dart';

/// Ending Tracker
///
/// Manages ending definitions and tracks which endings have been reached.
/// Works with GlobalProgressManager for persistence.
class EndingTracker {
  /// List of all ending definitions
  final List<EndingDefinition> _definitions;

  /// Reference to global progress manager for persistence
  final GlobalProgressManager? _progressManager;

  /// Local tracking (used when no progress manager is provided)
  final Set<String> _localReachedIds = {};
  final Map<String, DateTime> _localReachDates = {};
  final List<String> _localReachOrder = [];

  /// Event controller for ending reached events
  final StreamController<EndingReachedEvent> _eventController =
      StreamController<EndingReachedEvent>.broadcast();

  /// Stream of ending reached events
  Stream<EndingReachedEvent> get onEndingReached => _eventController.stream;

  /// Create an EndingTracker with definitions and optional progress manager
  EndingTracker({
    required List<EndingDefinition> definitions,
    GlobalProgressManager? progressManager,
  })  : _definitions = List.unmodifiable(definitions),
        _progressManager = progressManager;

  /// Get all ending definitions
  List<EndingDefinition> get definitions => _definitions;

  /// Get the number of total endings
  int get totalEndings => _definitions.length;

  /// Get the number of reached endings
  int get reachedCount {
    if (_progressManager != null) {
      return _progressManager!.data.endings.reachedIds.length;
    }
    return _localReachedIds.length;
  }

  /// Get reached ending IDs
  Set<String> get reachedIds {
    if (_progressManager != null) {
      return _progressManager!.data.endings.reachedIds;
    }
    return Set.unmodifiable(_localReachedIds);
  }

  /// Get reach order list
  List<String> get reachOrder {
    if (_progressManager != null) {
      return _progressManager!.data.endings.reachOrder;
    }
    return List.unmodifiable(_localReachOrder);
  }

  /// Check if an ending has been reached
  bool isReached(String endingId) {
    if (_progressManager != null) {
      return _progressManager!.isEndingReached(endingId);
    }
    return _localReachedIds.contains(endingId);
  }

  /// Get the date when an ending was reached
  DateTime? getReachDate(String endingId) {
    if (_progressManager != null) {
      return _progressManager!.getEndingReachDate(endingId);
    }
    return _localReachDates[endingId];
  }

  /// Get the order in which an ending was reached (1-based, 0 = not reached)
  int getReachOrder(String endingId) {
    final order = reachOrder;
    final index = order.indexOf(endingId);
    return index >= 0 ? index + 1 : 0;
  }

  /// Record reaching an ending
  void recordEnding(String endingId, {String? name}) {
    // Check if already reached
    if (isReached(endingId)) return;

    // Get the ending definition for the name
    final definition = getById(endingId);
    final endingName = name ?? definition?.name ?? endingId;

    if (_progressManager != null) {
      _progressManager!.recordEnding(endingId, name: endingName);
    } else {
      // Local tracking
      _localReachedIds.add(endingId);
      _localReachDates[endingId] = DateTime.now();
      _localReachOrder.add(endingId);
    }

    // Emit event
    _eventController.add(EndingReachedEvent(
      endingId: endingId,
      endingName: endingName,
    ));
  }

  /// Get completion percentage (0.0 - 1.0)
  double get completionPercentage {
    if (_definitions.isEmpty) return 0.0;
    return reachedCount / _definitions.length;
  }

  /// Check if all endings have been reached
  bool get isAllReached => reachedCount >= _definitions.length;

  /// Get an ending definition by ID
  EndingDefinition? getById(String id) {
    try {
      return _definitions.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get ending statuses for UI display
  List<EndingStatus> getEndingStatuses() {
    return _definitions.map((def) {
      final reached = isReached(def.id);
      return EndingStatus(
        definition: def,
        isReached: reached,
        reachDate: reached ? getReachDate(def.id) : null,
        reachOrder: getReachOrder(def.id),
      );
    }).toList()
      ..sort((a, b) => a.definition.order.compareTo(b.definition.order));
  }

  /// Get ending statuses grouped by type
  Map<EndingType, List<EndingStatus>> getGroupedByType() {
    final statuses = getEndingStatuses();
    final grouped = <EndingType, List<EndingStatus>>{};

    for (final status in statuses) {
      grouped.putIfAbsent(status.definition.type, () => []).add(status);
    }

    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.definition.order.compareTo(b.definition.order));
    }

    return grouped;
  }

  /// Get completion percentage by type
  Map<EndingType, double> getCompletionByType() {
    final grouped = getGroupedByType();
    final result = <EndingType, double>{};

    for (final entry in grouped.entries) {
      final total = entry.value.length;
      if (total == 0) {
        result[entry.key] = 0.0;
      } else {
        final reached = entry.value.where((s) => s.isReached).length;
        result[entry.key] = reached / total;
      }
    }

    return result;
  }

  /// Get count by type
  Map<EndingType, ({int reached, int total})> getCountByType() {
    final grouped = getGroupedByType();
    final result = <EndingType, ({int reached, int total})>{};

    for (final entry in grouped.entries) {
      final total = entry.value.length;
      final reached = entry.value.where((s) => s.isReached).length;
      result[entry.key] = (reached: reached, total: total);
    }

    return result;
  }

  /// Get recently reached endings (sorted by reach date, newest first)
  List<EndingStatus> getRecentlyReached({int limit = 5}) {
    final statuses = getEndingStatuses()
        .where((s) => s.isReached && s.reachDate != null)
        .toList();

    statuses.sort((a, b) => b.reachDate!.compareTo(a.reachDate!));

    if (limit > 0 && statuses.length > limit) {
      return statuses.sublist(0, limit);
    }
    return statuses;
  }

  /// Get endings in reach order
  List<EndingStatus> getInReachOrder() {
    final order = reachOrder;
    final statusMap = <String, EndingStatus>{};

    for (final status in getEndingStatuses()) {
      statusMap[status.definition.id] = status;
    }

    return order
        .where((id) => statusMap.containsKey(id))
        .map((id) => statusMap[id]!)
        .toList();
  }

  /// Serialize to JSON (for local storage without progress manager)
  Map<String, dynamic> toJson() => {
        'reached': _localReachedIds.toList(),
        'reachDates': _localReachDates.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'reachOrder': _localReachOrder,
      };

  /// Load from JSON (for local storage without progress manager)
  void fromJson(Map<String, dynamic> json) {
    _localReachedIds.clear();
    _localReachDates.clear();
    _localReachOrder.clear();

    _localReachedIds.addAll(
      (json['reached'] as List?)?.cast<String>() ?? [],
    );

    final dates = json['reachDates'] as Map<String, dynamic>? ?? {};
    for (final entry in dates.entries) {
      _localReachDates[entry.key] = DateTime.parse(entry.value as String);
    }

    _localReachOrder.addAll(
      (json['reachOrder'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

// Note: EndingReachedEvent is imported from global_progress_manager.dart
// to avoid duplicate class definitions
