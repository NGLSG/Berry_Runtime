/// Journal Entry Type for VNBS
///
/// Defines the types of journal entries.
/// Requirements: 19.1-19.4

/// Types of journal entries
enum JournalEntryType {
  /// Character profiles
  character,

  /// Collectible items
  item,

  /// World lore entries
  lore,

  /// Event records
  event,

  /// Tips and hints
  tip,
}

/// Extension methods for JournalEntryType
extension JournalEntryTypeExtension on JournalEntryType {
  /// Get display name for the type
  String get displayName {
    switch (this) {
      case JournalEntryType.character:
        return 'Characters';
      case JournalEntryType.item:
        return 'Items';
      case JournalEntryType.lore:
        return 'Lore';
      case JournalEntryType.event:
        return 'Events';
      case JournalEntryType.tip:
        return 'Tips';
    }
  }

  /// Get icon name for the type
  String get iconName {
    switch (this) {
      case JournalEntryType.character:
        return 'person';
      case JournalEntryType.item:
        return 'inventory_2';
      case JournalEntryType.lore:
        return 'auto_stories';
      case JournalEntryType.event:
        return 'event_note';
      case JournalEntryType.tip:
        return 'lightbulb';
    }
  }

  /// Convert to JSON string
  String toJson() => name;

  /// Create from JSON string
  static JournalEntryType fromJson(String json) {
    return JournalEntryType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => JournalEntryType.lore,
    );
  }
}
