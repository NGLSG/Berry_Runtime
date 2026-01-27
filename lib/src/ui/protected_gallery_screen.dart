/// Protected Gallery Screen Widget
///
/// Wraps GalleryScreen with spoiler protection validation.
/// Only shows CGs that have been legitimately unlocked.
/// Requirements: 6.3

import 'package:flutter/material.dart';

import '../protection/protection.dart';
import 'gallery_screen.dart';

/// Protected gallery screen that validates unlock status
class ProtectedGalleryScreen extends StatelessWidget {
  /// List of all gallery items (will be filtered by protection)
  final List<GalleryItem> allItems;

  /// Spoiler protection system
  final SpoilerProtection protection;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Configuration
  final GalleryScreenConfig config;

  /// Whether to show locked items as silhouettes
  final bool showLockedItems;

  const ProtectedGalleryScreen({
    super.key,
    required this.allItems,
    required this.protection,
    this.onBack,
    this.config = const GalleryScreenConfig(),
    this.showLockedItems = true,
  });

  @override
  Widget build(BuildContext context) {
    // Filter items based on protection validation
    final protectedItems = allItems.map((item) {
      // Validate unlock status through protection system
      final isLegitimatelyUnlocked = protection.validateUnlock(
        item.id,
        UnlockType.cg,
      );

      // If item claims to be unlocked but isn't legitimately unlocked,
      // treat it as locked
      return GalleryItem(
        id: item.id,
        name: item.name,
        thumbnailPath: item.thumbnailPath,
        imagePath: item.imagePath,
        isUnlocked: isLegitimatelyUnlocked,
        category: item.category,
        description: item.description,
      );
    }).toList();

    return GalleryScreen(
      items: protectedItems,
      onBack: onBack,
      config: config,
      showLockedItems: showLockedItems,
    );
  }
}

/// Extension to create protected gallery items from raw data
extension ProtectedGalleryItemExtension on List<GalleryItem> {
  /// Filters items to only include legitimately unlocked ones
  List<GalleryItem> filterByProtection(SpoilerProtection protection) {
    return map((item) {
      final isLegitimatelyUnlocked = protection.validateUnlock(
        item.id,
        UnlockType.cg,
      );

      return GalleryItem(
        id: item.id,
        name: item.name,
        thumbnailPath: item.thumbnailPath,
        imagePath: item.imagePath,
        isUnlocked: isLegitimatelyUnlocked,
        category: item.category,
        description: item.description,
      );
    }).toList();
  }
}
