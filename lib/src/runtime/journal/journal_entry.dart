/// Journal Entry Model for VNBS
///
/// Defines the JournalEntry class for the journal/codex system.
/// Requirements: 19.1-19.4

import 'journal_entry_type.dart';

/// Journal entry definition
class JournalEntry {
  /// Unique entry identifier
  final String id;

  /// Display title
  final String title;

  /// Content (supports rich text)
  final String content;

  /// Entry type
  final JournalEntryType type;

  /// Image path (relative to assets)
  final String? imagePath;

  /// Category for sub-grouping within type
  final String? category;

  /// Display order within category
  final int order;

  /// Whether this entry is unlocked by default
  final bool isUnlockedByDefault;

  /// Localized titles by language code
  final Map<String, String> localizedTitles;

  /// Localized content by language code
  final Map<String, String> localizedContent;

  /// Related entry IDs (for cross-referencing)
  final List<String> relatedEntryIds;

  /// Tags for filtering/searching
  final List<String> tags;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imagePath,
    this.category,
    this.order = 0,
    this.isUnlockedByDefault = false,
    this.localizedTitles = const {},
    this.localizedContent = const {},
    this.relatedEntryIds = const [],
    this.tags = const [],
  });

  /// Get localized title
  String getLocalizedTitle(String languageCode) {
    return localizedTitles[languageCode] ?? title;
  }

  /// Get localized content
  String getLocalizedContent(String languageCode) {
    return localizedContent[languageCode] ?? content;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type.toJson(),
        if (imagePath != null) 'imagePath': imagePath,
        if (category != null) 'category': category,
        'order': order,
        'isUnlockedByDefault': isUnlockedByDefault,
        if (localizedTitles.isNotEmpty) 'localizedTitles': localizedTitles,
        if (localizedContent.isNotEmpty) 'localizedContent': localizedContent,
        if (relatedEntryIds.isNotEmpty) 'relatedEntryIds': relatedEntryIds,
        if (tags.isNotEmpty) 'tags': tags,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      type: JournalEntryTypeExtension.fromJson(json['type'] as String? ?? 'lore'),
      imagePath: json['imagePath'] as String?,
      category: json['category'] as String?,
      order: json['order'] as int? ?? 0,
      isUnlockedByDefault: json['isUnlockedByDefault'] as bool? ?? false,
      localizedTitles:
          (json['localizedTitles'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      localizedContent:
          (json['localizedContent'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      relatedEntryIds:
          (json['relatedEntryIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    JournalEntryType? type,
    String? imagePath,
    String? category,
    int? order,
    bool? isUnlockedByDefault,
    Map<String, String>? localizedTitles,
    Map<String, String>? localizedContent,
    List<String>? relatedEntryIds,
    List<String>? tags,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      order: order ?? this.order,
      isUnlockedByDefault: isUnlockedByDefault ?? this.isUnlockedByDefault,
      localizedTitles: localizedTitles ?? this.localizedTitles,
      localizedContent: localizedContent ?? this.localizedContent,
      relatedEntryIds: relatedEntryIds ?? this.relatedEntryIds,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Journal entry status for UI display
class JournalEntryStatus {
  /// The entry definition
  final JournalEntry entry;

  /// Whether the entry is unlocked
  final bool isUnlocked;

  /// When the entry was unlocked (null if not unlocked or unlocked by default)
  final DateTime? unlockDate;

  const JournalEntryStatus({
    required this.entry,
    required this.isUnlocked,
    this.unlockDate,
  });

  /// Get display title (locked entries show "???")
  String getDisplayTitle(String languageCode) {
    if (!isUnlocked) return '???';
    return entry.getLocalizedTitle(languageCode);
  }

  /// Get display content (locked entries show placeholder)
  String getDisplayContent(String languageCode) {
    if (!isUnlocked) return 'This entry has not been unlocked yet.';
    return entry.getLocalizedContent(languageCode);
  }
}
