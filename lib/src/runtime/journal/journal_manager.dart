/// Journal Manager for VNBS
///
/// Manages journal entries, unlocking, and search functionality.
/// Requirements: 19.1-19.7

import 'dart:async';

import 'journal_entry.dart';
import 'journal_entry_type.dart';

/// Journal Manager
///
/// Manages all journal entries for a VN project, including:
/// - Entry definitions
/// - Unlock tracking
/// - Completion calculation
/// - Search functionality
class JournalManager {
  /// Entry definitions
  final List<JournalEntry> _entries;

  /// Set of unlocked entry IDs
  final Set<String> _unlockedIds = {};

  /// Map of unlock dates by entry ID
  final Map<String, DateTime> _unlockDates = {};

  /// Stream controller for unlock events
  final StreamController<JournalEntry> _unlockController =
      StreamController<JournalEntry>.broadcast();

  /// Stream of entry unlock events
  Stream<JournalEntry> get onUnlock => _unlockController.stream;

  JournalManager([List<JournalEntry>? entries]) : _entries = List.from(entries ?? []) {
    // Unlock entries that are unlocked by default
    for (final entry in _entries) {
      if (entry.isUnlockedByDefault) {
        _unlockedIds.add(entry.id);
      }
    }
  }

  /// Get all entry definitions
  List<JournalEntry> get entries => List.unmodifiable(_entries);

  /// Get entry by ID
  JournalEntry? getById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if an entry is unlocked
  bool isUnlocked(String entryId) => _unlockedIds.contains(entryId);

  /// Get unlock date for an entry
  DateTime? getUnlockDate(String entryId) => _unlockDates[entryId];

  /// Unlock an entry
  void unlockEntry(String entryId) {
    if (_unlockedIds.contains(entryId)) return;

    final entry = getById(entryId);
    if (entry == null) return;

    _unlockedIds.add(entryId);
    _unlockDates[entryId] = DateTime.now();
    _unlockController.add(entry);
  }

  /// Get status for all entries
  List<JournalEntryStatus> getAllStatuses() {
    return _entries.map((entry) {
      return JournalEntryStatus(
        entry: entry,
        isUnlocked: _unlockedIds.contains(entry.id),
        unlockDate: _unlockDates[entry.id],
      );
    }).toList();
  }

  /// Get entries grouped by type
  Map<JournalEntryType, List<JournalEntryStatus>> getGroupedByType() {
    final grouped = <JournalEntryType, List<JournalEntryStatus>>{};

    for (final entry in _entries) {
      grouped.putIfAbsent(entry.type, () => []).add(JournalEntryStatus(
            entry: entry,
            isUnlocked: _unlockedIds.contains(entry.id),
            unlockDate: _unlockDates[entry.id],
          ));
    }

    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.entry.order.compareTo(b.entry.order));
    }

    return grouped;
  }

  /// Get entries grouped by category within a type
  Map<String, List<JournalEntryStatus>> getGroupedByCategory(JournalEntryType type) {
    final grouped = <String, List<JournalEntryStatus>>{};

    for (final entry in _entries.where((e) => e.type == type)) {
      final category = entry.category ?? 'General';
      grouped.putIfAbsent(category, () => []).add(JournalEntryStatus(
            entry: entry,
            isUnlocked: _unlockedIds.contains(entry.id),
            unlockDate: _unlockDates[entry.id],
          ));
    }

    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.entry.order.compareTo(b.entry.order));
    }

    return grouped;
  }

  /// Get completion percentage (overall or by type)
  double getCompletionPercentage([JournalEntryType? type]) {
    final targetEntries = type == null
        ? _entries
        : _entries.where((e) => e.type == type).toList();

    if (targetEntries.isEmpty) return 0.0;

    final unlocked = targetEntries.where((e) => _unlockedIds.contains(e.id)).length;
    return unlocked / targetEntries.length;
  }

  /// Get unlocked count (overall or by type)
  int getUnlockedCount([JournalEntryType? type]) {
    final targetEntries = type == null
        ? _entries
        : _entries.where((e) => e.type == type).toList();

    return targetEntries.where((e) => _unlockedIds.contains(e.id)).length;
  }

  /// Get total count (overall or by type)
  int getTotalCount([JournalEntryType? type]) {
    if (type == null) return _entries.length;
    return _entries.where((e) => e.type == type).length;
  }

  /// Search entries by query
  ///
  /// Searches in title, content, and tags.
  /// Only returns unlocked entries by default.
  List<JournalEntryStatus> search(String query, {bool includeLockedEntries = false}) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <JournalEntryStatus>[];

    for (final entry in _entries) {
      final isUnlocked = _unlockedIds.contains(entry.id);

      // Skip locked entries if not including them
      if (!isUnlocked && !includeLockedEntries) continue;

      // Search in title
      if (entry.title.toLowerCase().contains(lowerQuery)) {
        results.add(JournalEntryStatus(
          entry: entry,
          isUnlocked: isUnlocked,
          unlockDate: _unlockDates[entry.id],
        ));
        continue;
      }

      // Search in content (only for unlocked entries)
      if (isUnlocked && entry.content.toLowerCase().contains(lowerQuery)) {
        results.add(JournalEntryStatus(
          entry: entry,
          isUnlocked: isUnlocked,
          unlockDate: _unlockDates[entry.id],
        ));
        continue;
      }

      // Search in tags
      if (entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        results.add(JournalEntryStatus(
          entry: entry,
          isUnlocked: isUnlocked,
          unlockDate: _unlockDates[entry.id],
        ));
        continue;
      }
    }

    return results;
  }

  /// Get entries by tag
  List<JournalEntryStatus> getByTag(String tag) {
    return _entries
        .where((e) => e.tags.contains(tag))
        .map((e) => JournalEntryStatus(
              entry: e,
              isUnlocked: _unlockedIds.contains(e.id),
              unlockDate: _unlockDates[e.id],
            ))
        .toList();
  }

  /// Get related entries for an entry
  List<JournalEntryStatus> getRelatedEntries(String entryId) {
    final entry = getById(entryId);
    if (entry == null) return [];

    return entry.relatedEntryIds
        .map((id) => getById(id))
        .whereType<JournalEntry>()
        .map((e) => JournalEntryStatus(
              entry: e,
              isUnlocked: _unlockedIds.contains(e.id),
              unlockDate: _unlockDates[e.id],
            ))
        .toList();
  }

  /// Add a new entry definition
  void addEntry(JournalEntry entry) {
    if (_entries.any((e) => e.id == entry.id)) {
      throw ArgumentError('Entry with id ${entry.id} already exists');
    }
    _entries.add(entry);
    if (entry.isUnlockedByDefault) {
      _unlockedIds.add(entry.id);
    }
  }

  /// Remove an entry definition
  bool removeEntry(String entryId) {
    final lengthBefore = _entries.length;
    _entries.removeWhere((e) => e.id == entryId);
    _unlockedIds.remove(entryId);
    _unlockDates.remove(entryId);
    return _entries.length < lengthBefore;
  }

  /// Update an entry definition
  void updateEntry(JournalEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'unlockedIds': _unlockedIds.toList(),
        'unlockDates': _unlockDates.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      };

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    _unlockedIds.clear();
    _unlockDates.clear();

    final unlockedIds = json['unlockedIds'] as List<dynamic>?;
    if (unlockedIds != null) {
      _unlockedIds.addAll(unlockedIds.cast<String>());
    }

    final unlockDates = json['unlockDates'] as Map<String, dynamic>?;
    if (unlockDates != null) {
      for (final entry in unlockDates.entries) {
        _unlockDates[entry.key] = DateTime.parse(entry.value as String);
      }
    }

    // Re-add default unlocked entries
    for (final entry in _entries) {
      if (entry.isUnlockedByDefault) {
        _unlockedIds.add(entry.id);
      }
    }
  }

  /// Export definitions to JSON
  List<Map<String, dynamic>> exportDefinitions() {
    return _entries.map((e) => e.toJson()).toList();
  }

  /// Import definitions from JSON
  void importDefinitions(List<dynamic> jsonList) {
    _entries.clear();
    for (final json in jsonList) {
      final entry = JournalEntry.fromJson(json as Map<String, dynamic>);
      _entries.add(entry);
      if (entry.isUnlockedByDefault) {
        _unlockedIds.add(entry.id);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _unlockController.close();
  }
}
