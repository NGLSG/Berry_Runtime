/// CG Gallery Screen Widget
/// 
/// Displays unlocked CG images in a grid layout.
/// Supports viewing full-size images with zoom and navigation.

import 'package:flutter/material.dart';

import '../localization/vn_ui_strings.dart';

/// A single CG item in the gallery
class GalleryItem {
  /// Unique identifier
  final String id;
  
  /// Display name
  final String name;
  
  /// Thumbnail image path
  final String thumbnailPath;
  
  /// Full image path
  final String imagePath;
  
  /// Whether this CG is unlocked
  final bool isUnlocked;
  
  /// Category (e.g., 'Chapter 1', 'Ending', etc.)
  final String? category;
  
  /// Description text
  final String? description;

  const GalleryItem({
    required this.id,
    required this.name,
    required this.thumbnailPath,
    required this.imagePath,
    this.isUnlocked = false,
    this.category,
    this.description,
  });
}

/// Configuration for the gallery screen
class GalleryScreenConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Panel background color
  final Color panelBackgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Secondary text color
  final Color secondaryTextColor;
  
  /// Accent color
  final Color accentColor;
  
  /// Locked item overlay color
  final Color lockedOverlayColor;
  
  /// Title font size
  final double titleFontSize;
  
  /// Items per row
  final int itemsPerRow;
  
  /// Item spacing
  final double itemSpacing;
  
  /// Item aspect ratio
  final double itemAspectRatio;

  const GalleryScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.lockedOverlayColor = const Color(0xCC000000),
    this.titleFontSize = 28.0,
    this.itemsPerRow = 4,
    this.itemSpacing = 16.0,
    this.itemAspectRatio = 16 / 9,
  });
}

/// Gallery screen widget
class GalleryScreen extends StatefulWidget {
  /// List of gallery items
  final List<GalleryItem> items;
  
  /// Callback when back is pressed
  final VoidCallback? onBack;
  
  /// Configuration
  final GalleryScreenConfig config;
  
  /// Whether to show locked items
  final bool showLockedItems;
  
  /// Language code for UI localization
  final String languageCode;

  const GalleryScreen({
    super.key,
    required this.items,
    this.onBack,
    this.config = const GalleryScreenConfig(),
    this.showLockedItems = true,
    this.languageCode = 'en',
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String? _selectedCategory;
  int? _viewingIndex;

  List<String> get _categories {
    final cats = widget.items
        .map((e) => e.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<GalleryItem> get _filteredItems {
    var items = widget.items;
    if (!widget.showLockedItems) {
      items = items.where((e) => e.isUnlocked).toList();
    }
    if (_selectedCategory != null) {
      items = items.where((e) => e.category == _selectedCategory).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_viewingIndex != null) {
      return _buildFullscreenViewer();
    }
    
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_categories.isNotEmpty) _buildCategoryTabs(),
            Expanded(child: _buildGalleryGrid()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.config.textColor),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Text(
            VNUILocalizer.get('cgGallery', widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredItems.where((e) => e.isUnlocked).length}/${_filteredItems.length}',
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryTab(
            label: VNUILocalizer.get('all', widget.languageCode),
            isSelected: _selectedCategory == null,
            config: widget.config,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ..._categories.map((cat) => _CategoryTab(
            label: cat,
            isSelected: _selectedCategory == cat,
            config: widget.config,
            onTap: () => setState(() => _selectedCategory = cat),
          )),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    final items = _filteredItems;
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: widget.config.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              VNUILocalizer.get('noCGsAvailable', widget.languageCode),
              style: TextStyle(color: widget.config.secondaryTextColor, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.itemsPerRow,
        crossAxisSpacing: widget.config.itemSpacing,
        mainAxisSpacing: widget.config.itemSpacing,
        childAspectRatio: widget.config.itemAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GalleryItemCard(
          item: item,
          config: widget.config,
          onTap: item.isUnlocked ? () => setState(() => _viewingIndex = index) : null,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        VNUILocalizer.get('clickToViewCG', widget.languageCode),
        style: TextStyle(color: widget.config.secondaryTextColor, fontSize: 12),
      ),
    );
  }

  Widget _buildFullscreenViewer() {
    final items = _filteredItems.where((e) => e.isUnlocked).toList();
    final currentItem = _filteredItems[_viewingIndex!];
    final unlockedIndex = items.indexOf(currentItem);
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                currentItem.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: widget.config.panelBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 64, color: widget.config.secondaryTextColor),
                        const SizedBox(height: 8),
                        Text(currentItem.name, style: TextStyle(color: widget.config.textColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _viewingIndex = null),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentItem.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    Text(
                      '${unlockedIndex + 1}/${items.length}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation arrows
          if (unlockedIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 48, color: Colors.white70),
                  onPressed: () {
                    final prevItem = items[unlockedIndex - 1];
                    setState(() => _viewingIndex = _filteredItems.indexOf(prevItem));
                  },
                ),
              ),
            ),
          if (unlockedIndex < items.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 48, color: Colors.white70),
                  onPressed: () {
                    final nextItem = items[unlockedIndex + 1];
                    setState(() => _viewingIndex = _filteredItems.indexOf(nextItem));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final GalleryScreenConfig config;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: config.panelBackgroundColor,
        selectedColor: config.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : config.secondaryTextColor,
        ),
      ),
    );
  }
}

class _GalleryItemCard extends StatefulWidget {
  final GalleryItem item;
  final GalleryScreenConfig config;
  final VoidCallback? onTap;

  const _GalleryItemCard({
    required this.item,
    required this.config,
    this.onTap,
  });

  @override
  State<_GalleryItemCard> createState() => _GalleryItemCardState();
}

class _GalleryItemCardState extends State<_GalleryItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.item.isUnlocked ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered && widget.item.isUnlocked
                  ? widget.config.accentColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
                Image.asset(
                  widget.item.thumbnailPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: widget.config.panelBackgroundColor,
                    child: Icon(Icons.image, color: widget.config.secondaryTextColor),
                  ),
                ),
                
                // Locked overlay
                if (!widget.item.isUnlocked)
                  Container(
                    color: widget.config.lockedOverlayColor,
                    child: Center(
                      child: Icon(Icons.lock, color: widget.config.secondaryTextColor, size: 32),
                    ),
                  ),
                
                // Name overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      widget.item.isUnlocked ? widget.item.name : '???',
                      style: TextStyle(
                        color: widget.config.textColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
