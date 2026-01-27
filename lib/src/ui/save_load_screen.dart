/// Save/Load Screen Widget
/// 
/// Provides save slot management with thumbnails and timestamps.
/// Supports multiple save slots, quick saves, and auto saves.

import 'package:flutter/material.dart';

import '../localization/vn_ui_strings.dart';

/// Save slot data
class VNSaveSlot {
  /// Slot index
  final int index;
  
  /// Whether this slot has data
  final bool hasData;
  
  /// Save timestamp
  final DateTime? timestamp;
  
  /// Thumbnail image data (base64 or path)
  final String? thumbnailData;
  
  /// Chapter name at save point
  final String? chapterName;
  
  /// Brief description/preview text
  final String? previewText;
  
  /// Play time in seconds
  final int? playTimeSeconds;
  
  /// Slot type
  final SaveSlotType type;

  const VNSaveSlot({
    required this.index,
    this.hasData = false,
    this.timestamp,
    this.thumbnailData,
    this.chapterName,
    this.previewText,
    this.playTimeSeconds,
    this.type = SaveSlotType.normal,
  });

  VNSaveSlot copyWith({
    int? index,
    bool? hasData,
    DateTime? timestamp,
    String? thumbnailData,
    String? chapterName,
    String? previewText,
    int? playTimeSeconds,
    SaveSlotType? type,
  }) {
    return VNSaveSlot(
      index: index ?? this.index,
      hasData: hasData ?? this.hasData,
      timestamp: timestamp ?? this.timestamp,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      chapterName: chapterName ?? this.chapterName,
      previewText: previewText ?? this.previewText,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      type: type ?? this.type,
    );
  }

  /// Format play time as HH:MM:SS
  String get formattedPlayTime {
    if (playTimeSeconds == null) return '';
    final hours = playTimeSeconds! ~/ 3600;
    final minutes = (playTimeSeconds! % 3600) ~/ 60;
    final seconds = playTimeSeconds! % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Save slot types
enum SaveSlotType {
  normal,
  quickSave,
  autoSave,
}

/// Save/Load screen mode
enum SaveLoadMode {
  save,
  load,
}

/// Configuration for the save/load screen
class SaveLoadScreenConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Panel background color
  final Color panelBackgroundColor;
  
  /// Slot background color
  final Color slotBackgroundColor;
  
  /// Empty slot background color
  final Color emptySlotBackgroundColor;
  
  /// Selected slot border color
  final Color selectedBorderColor;
  
  /// Text color
  final Color textColor;
  
  /// Secondary text color
  final Color secondaryTextColor;
  
  /// Title font size
  final double titleFontSize;
  
  /// Slot width
  final double slotWidth;
  
  /// Slot height
  final double slotHeight;
  
  /// Slots per row
  final int slotsPerRow;
  
  /// Slot spacing
  final double slotSpacing;
  
  /// Number of normal save slots
  final int normalSlotCount;
  
  /// Number of quick save slots
  final int quickSaveSlotCount;
  
  /// Number of auto save slots
  final int autoSaveSlotCount;

  const SaveLoadScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.slotBackgroundColor = const Color(0xFF2A2A4E),
    this.emptySlotBackgroundColor = const Color(0xFF1A1A2E),
    this.selectedBorderColor = const Color(0xFF6C63FF),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.titleFontSize = 28.0,
    this.slotWidth = 200.0,
    this.slotHeight = 160.0,
    this.slotsPerRow = 4,
    this.slotSpacing = 16.0,
    this.normalSlotCount = 20,
    this.quickSaveSlotCount = 3,
    this.autoSaveSlotCount = 3,
  });
}

/// Save/Load screen widget
class SaveLoadScreen extends StatefulWidget {
  /// Current mode (save or load)
  final SaveLoadMode mode;
  
  /// List of save slots
  final List<VNSaveSlot> slots;
  
  /// Quick save slots
  final List<VNSaveSlot> quickSaveSlots;
  
  /// Auto save slots
  final List<VNSaveSlot> autoSaveSlots;
  
  /// Callback when a slot is selected for save
  final void Function(VNSaveSlot slot)? onSave;
  
  /// Callback when a slot is selected for load
  final void Function(VNSaveSlot slot)? onLoad;
  
  /// Callback when a slot is deleted
  final void Function(VNSaveSlot slot)? onDelete;
  
  /// Callback when back is pressed
  final VoidCallback? onBack;
  
  /// Configuration
  final SaveLoadScreenConfig config;
  
  /// Whether delete is allowed
  final bool allowDelete;
  
  /// Language code for UI localization
  final String languageCode;

  const SaveLoadScreen({
    super.key,
    required this.mode,
    required this.slots,
    this.quickSaveSlots = const [],
    this.autoSaveSlots = const [],
    this.onSave,
    this.onLoad,
    this.onDelete,
    this.onBack,
    this.config = const SaveLoadScreenConfig(),
    this.allowDelete = true,
    this.languageCode = 'en',
  });

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedSlotIndex;
  SaveSlotType _selectedSlotType = SaveSlotType.normal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectSlot(int index, SaveSlotType type) {
    setState(() {
      _selectedSlotIndex = index;
      _selectedSlotType = type;
    });
  }

  void _handleSlotAction(VNSaveSlot slot) {
    if (widget.mode == SaveLoadMode.save) {
      _showSaveConfirmation(slot);
    } else {
      if (slot.hasData) {
        widget.onLoad?.call(slot);
      }
    }
  }

  void _showSaveConfirmation(VNSaveSlot slot) {
    if (slot.hasData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.config.panelBackgroundColor,
          title: Text(
            VNUILocalizer.get('overwriteSave', widget.languageCode),
            style: TextStyle(color: widget.config.textColor),
          ),
          content: Text(
            VNUILocalizer.get('overwriteConfirm', widget.languageCode),
            style: TextStyle(color: widget.config.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                VNUILocalizer.get('cancel', widget.languageCode),
                style: TextStyle(color: widget.config.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSave?.call(slot);
              },
              child: Text(
                VNUILocalizer.get('overwrite', widget.languageCode),
                style: TextStyle(color: widget.config.selectedBorderColor),
              ),
            ),
          ],
        ),
      );
    } else {
      widget.onSave?.call(slot);
    }
  }

  void _showDeleteConfirmation(VNSaveSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.config.panelBackgroundColor,
        title: Text(
          VNUILocalizer.get('deleteSave', widget.languageCode),
          style: TextStyle(color: widget.config.textColor),
        ),
        content: Text(
          VNUILocalizer.get('deleteConfirm', widget.languageCode),
          style: TextStyle(color: widget.config.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              VNUILocalizer.get('cancel', widget.languageCode),
              style: TextStyle(color: widget.config.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(slot);
            },
            child: Text(
              VNUILocalizer.get('delete', widget.languageCode),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            _buildTabBar(),
            
            // Slot grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSlotGrid(widget.slots, SaveSlotType.normal),
                  _buildSlotGrid(widget.quickSaveSlots, SaveSlotType.quickSave),
                  _buildSlotGrid(widget.autoSaveSlots, SaveSlotType.autoSave),
                ],
              ),
            ),
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
            icon: Icon(
              Icons.arrow_back,
              color: widget.config.textColor,
            ),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Text(
            widget.mode == SaveLoadMode.save 
                ? VNUILocalizer.get('saveGame', widget.languageCode) 
                : VNUILocalizer.get('loadGame', widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: widget.config.selectedBorderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: widget.config.textColor,
        unselectedLabelColor: widget.config.secondaryTextColor,
        tabs: [
          Tab(text: VNUILocalizer.get('saveSlots', widget.languageCode)),
          Tab(text: VNUILocalizer.get('quickSave', widget.languageCode)),
          Tab(text: VNUILocalizer.get('autoSave', widget.languageCode)),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(List<VNSaveSlot> slots, SaveSlotType type) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.slotsPerRow,
        crossAxisSpacing: widget.config.slotSpacing,
        mainAxisSpacing: widget.config.slotSpacing,
        childAspectRatio: widget.config.slotWidth / widget.config.slotHeight,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedSlotIndex == index && _selectedSlotType == type;
        
        return _SaveSlotCard(
          slot: slot,
          isSelected: isSelected,
          config: widget.config,
          mode: widget.mode,
          allowDelete: widget.allowDelete && slot.hasData,
          languageCode: widget.languageCode,
          onTap: () {
            _selectSlot(index, type);
            _handleSlotAction(slot);
          },
          onDelete: () => _showDeleteConfirmation(slot),
        );
      },
    );
  }
}

/// Individual save slot card
class _SaveSlotCard extends StatefulWidget {
  final VNSaveSlot slot;
  final bool isSelected;
  final SaveLoadScreenConfig config;
  final SaveLoadMode mode;
  final bool allowDelete;
  final String languageCode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SaveSlotCard({
    required this.slot,
    required this.isSelected,
    required this.config,
    required this.mode,
    required this.allowDelete,
    required this.languageCode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SaveSlotCard> createState() => _SaveSlotCardState();
}

class _SaveSlotCardState extends State<_SaveSlotCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.slot.hasData;
    final isLoadMode = widget.mode == SaveLoadMode.load;
    final isDisabled = isLoadMode && !hasData;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: hasData
                ? widget.config.slotBackgroundColor
                : widget.config.emptySlotBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? widget.config.selectedBorderColor
                  : _isHovered && !isDisabled
                      ? widget.config.selectedBorderColor.withOpacity(0.5)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail area
                  Expanded(
                    flex: 3,
                    child: _buildThumbnail(),
                  ),
                  
                  // Info area
                  Expanded(
                    flex: 2,
                    child: _buildInfo(),
                  ),
                ],
              ),
              
              // Delete button
              if (widget.allowDelete && _isHovered)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red.withOpacity(0.8),
                    onPressed: widget.onDelete,
                  ),
                ),
              
              // Slot type badge
              if (widget.slot.type != SaveSlotType.normal)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSlotTypeBadgeColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getSlotTypeLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (!widget.slot.hasData) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: widget.config.secondaryTextColor,
            size: 32,
          ),
        ),
      );
    }
    
    // TODO: Implement actual thumbnail loading
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: widget.config.secondaryTextColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    if (!widget.slot.hasData) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            VNUILocalizer.format('emptySlot', {'num': '${widget.slot.index + 1}'}, widget.languageCode),
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chapter name
          if (widget.slot.chapterName != null)
            Text(
              widget.slot.chapterName!,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 2),
          
          // Timestamp
          if (widget.slot.timestamp != null)
            Text(
              _formatTimestamp(widget.slot.timestamp!),
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 10,
              ),
            ),
          
          // Play time
          if (widget.slot.playTimeSeconds != null)
            Text(
              '${VNUILocalizer.get('playTime', widget.languageCode)} ${widget.slot.formattedPlayTime}',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Color _getSlotTypeBadgeColor() {
    switch (widget.slot.type) {
      case SaveSlotType.quickSave:
        return Colors.orange;
      case SaveSlotType.autoSave:
        return Colors.green;
      case SaveSlotType.normal:
        return Colors.blue;
    }
  }

  String _getSlotTypeLabel() {
    switch (widget.slot.type) {
      case SaveSlotType.quickSave:
        return VNUILocalizer.get('quick', widget.languageCode);
      case SaveSlotType.autoSave:
        return VNUILocalizer.get('auto', widget.languageCode);
      case SaveSlotType.normal:
        return '';
    }
  }
}
