/// Relationship Type for VNBS Affection System
///
/// Defines the types of relationships that can be tracked.
/// Requirements: 18.5

/// Types of relationships that can be tracked in the affection system
enum RelationshipType {
  /// Romantic love relationship
  love,

  /// Friendship relationship
  friendship,

  /// Competitive/rivalry relationship
  rivalry,

  /// Trust-based relationship
  trust,

  /// Custom relationship type (use customLabel for display)
  custom,
}

/// Extension methods for RelationshipType
extension RelationshipTypeExtension on RelationshipType {
  /// Get the default display label for this relationship type
  String get defaultLabel {
    switch (this) {
      case RelationshipType.love:
        return 'Love';
      case RelationshipType.friendship:
        return 'Friendship';
      case RelationshipType.rivalry:
        return 'Rivalry';
      case RelationshipType.trust:
        return 'Trust';
      case RelationshipType.custom:
        return 'Affection';
    }
  }

  /// Get the default icon name for this relationship type
  String get defaultIcon {
    switch (this) {
      case RelationshipType.love:
        return 'heart';
      case RelationshipType.friendship:
        return 'people';
      case RelationshipType.rivalry:
        return 'flash';
      case RelationshipType.trust:
        return 'shield';
      case RelationshipType.custom:
        return 'star';
    }
  }

  /// Get the default color for this relationship type (as hex string)
  String get defaultColorHex {
    switch (this) {
      case RelationshipType.love:
        return '#FF69B4'; // Hot pink
      case RelationshipType.friendship:
        return '#4169E1'; // Royal blue
      case RelationshipType.rivalry:
        return '#FF4500'; // Orange red
      case RelationshipType.trust:
        return '#32CD32'; // Lime green
      case RelationshipType.custom:
        return '#9370DB'; // Medium purple
    }
  }

  /// Convert to JSON string
  String toJson() => name;

  /// Create from JSON string
  static RelationshipType fromJson(String json) {
    return RelationshipType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => RelationshipType.custom,
    );
  }
}
