/// Backlog/History Screen Widget
/// 
/// Displays dialogue history with scrollable list.
/// Supports jumping back to previous dialogue points.

import 'package:flutter/material.dart';
import '../localization/vn_ui_strings.dart';

/// A single entry in the backlog
class BacklogEntry {
  /// Unique identifier
  final String id;
  
  /// Chapter ID where this dialogue occurred
  final String chapterId;
  
  /// Node ID where this dialogue occurred
  final String nodeId;
  
  /// Dialogue index within the node
  final int dialogueIndex;
  
  /// Speaker name (null for narration)
  final String? speakerName;
  
  /// Speaker name color
  final Color? speakerColor;
  
  /// Dialogue text
  final String text;
  
  /// Voice audio ID (if any)
  final String? voiceId;
  
  /// Timestamp when this dialogue was shown
  final DateTime timestamp;

  const BacklogEntry({
    required this.id,
    required this.chapterId,
    required this.nodeId,
    required this.dialogueIndex,
    this.speakerName,
    this.speakerColor,
    required this.text,
    this.voiceId,
    required this.timestamp,
  });

  /// Create a unique dialogue ID for tracking
  String get dialogueId => '$chapterId:$nodeId:$dialogueIndex';
}

/// Configuration for the backlog screen
class BacklogScreenConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Entry background color
  final Color entryBackgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Secondary text color
  final Color secondaryTextColor;
  
  /// Speaker name color (default)
  final Color speakerNameColor;
  
  /// Title font size
  final double titleFontSize;
  
  /// Text font size
  final double textFontSize;
  
  /// Speaker name font size
  final double speakerNameFontSize;
  
  /// Entry padding
  final EdgeInsets entryPadding;
  
  /// Entry spacing
  final double entrySpacing;
  
  /// Whether to show voice replay button
  final bool showVoiceReplay;
  
  /// Whether to show jump button
  final bool showJumpButton;
  
  /// Accent color
  final Color accentColor;

  const BacklogScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.entryBackgroundColor = const Color(0x33FFFFFF),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.speakerNameColor = const Color(0xFF6C63FF),
    this.titleFontSize = 28.0,
    this.textFontSize = 16.0,
    this.speakerNameFontSize = 14.0,
    this.entryPadding = const EdgeInsets.all(16),
    this.entrySpacing = 8.0,
    this.showVoiceReplay = true,
    this.showJumpButton = true,
    this.accentColor = const Color(0xFF6C63FF),
  });

  BacklogScreenConfig copyWith({
    Color? backgroundColor,
    Color? entryBackgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? speakerNameColor,
    double? titleFontSize,
    double? textFontSize,
    double? speakerNameFontSize,
    EdgeInsets? entryPadding,
    double? entrySpacing,
    bool? showVoiceReplay,
    bool? showJumpButton,
    Color? accentColor,
  }) {
    return BacklogScreenConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      entryBackgroundColor: entryBackgroundColor ?? this.entryBackgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      speakerNameColor: speakerNameColor ?? this.speakerNameColor,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      textFontSize: textFontSize ?? this.textFontSize,
      speakerNameFontSize: speakerNameFontSize ?? this.speakerNameFontSize,
      entryPadding: entryPadding ?? this.entryPadding,
      entrySpacing: entrySpacing ?? this.entrySpacing,
      showVoiceReplay: showVoiceReplay ?? this.showVoiceReplay,
      showJumpButton: showJumpButton ?? this.showJumpButton,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

/// Backlog/History screen widget
class BacklogScreen extends StatefulWidget {
  /// List of backlog entries (newest first)
  final List<BacklogEntry> entries;
  
  /// Callback when back is pressed
  final VoidCallback? onBack;
  
  /// Callback when voice replay is requested
  final void Function(BacklogEntry entry)? onVoiceReplay;
  
  /// Callback when jump to entry is requested
  final void Function(BacklogEntry entry)? onJumpTo;
  
  /// Configuration
  final BacklogScreenConfig config;
  
  /// Whether jump is allowed (may be disabled in some contexts)
  final bool allowJump;
  
  /// Current chapter ID (for showing chapter separators)
  final String? currentChapterId;
  
  /// Language code for localization
  final String languageCode;

  const BacklogScreen({
    super.key,
    required this.entries,
    this.onBack,
    this.onVoiceReplay,
    this.onJumpTo,
    this.config = const BacklogScreenConfig(),
    this.allowJump = true,
    this.currentChapterId,
    this.languageCode = 'en',
  });

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            
            // Backlog list
            Expanded(
              child: widget.entries.isEmpty
                  ? _buildEmptyState()
                  : _buildBacklogList(),
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
            VNUILocalizer.get('history', widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Scroll to top button
          IconButton(
            icon: Icon(
              Icons.vertical_align_top,
              color: widget.config.secondaryTextColor,
            ),
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            tooltip: VNUILocalizer.get('scrollToTop', widget.languageCode),
          ),
          // Scroll to bottom button
          IconButton(
            icon: Icon(
              Icons.vertical_align_bottom,
              color: widget.config.secondaryTextColor,
            ),
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            tooltip: VNUILocalizer.get('scrollToBottom', widget.languageCode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: widget.config.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            VNUILocalizer.get('noHistoryYet', widget.languageCode),
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        final previousEntry = index > 0 ? widget.entries[index - 1] : null;
        
        // Check if we need a chapter separator
        final showChapterSeparator = previousEntry != null &&
            previousEntry.chapterId != entry.chapterId;
        
        return Column(
          children: [
            if (showChapterSeparator)
              _buildChapterSeparator(entry.chapterId),
            _BacklogEntryCard(
              entry: entry,
              config: widget.config,
              showVoiceReplay: widget.config.showVoiceReplay && entry.voiceId != null,
              showJumpButton: widget.config.showJumpButton && widget.allowJump,
              onVoiceReplay: () => widget.onVoiceReplay?.call(entry),
              onJumpTo: () => widget.onJumpTo?.call(entry),
              languageCode: widget.languageCode,
            ),
            SizedBox(height: widget.config.entrySpacing),
          ],
        );
      },
    );
  }

  Widget _buildChapterSeparator(String chapterId) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: widget.config.accentColor.withOpacity(0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              VNUILocalizer.format('chapter', {'name': chapterId}, widget.languageCode),
              style: TextStyle(
                color: widget.config.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: widget.config.accentColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual backlog entry card
class _BacklogEntryCard extends StatefulWidget {
  final BacklogEntry entry;
  final BacklogScreenConfig config;
  final bool showVoiceReplay;
  final bool showJumpButton;
  final VoidCallback? onVoiceReplay;
  final VoidCallback? onJumpTo;
  final String languageCode;

  const _BacklogEntryCard({
    required this.entry,
    required this.config,
    required this.showVoiceReplay,
    required this.showJumpButton,
    this.onVoiceReplay,
    this.onJumpTo,
    this.languageCode = 'en',
  });

  @override
  State<_BacklogEntryCard> createState() => _BacklogEntryCardState();
}

class _BacklogEntryCardState extends State<_BacklogEntryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: widget.config.entryPadding,
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.config.entryBackgroundColor.withOpacity(0.5)
              : widget.config.entryBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker name and actions row
            Row(
              children: [
                // Speaker name
                if (widget.entry.speakerName != null)
                  Text(
                    widget.entry.speakerName!,
                    style: TextStyle(
                      color: widget.entry.speakerColor ?? widget.config.speakerNameColor,
                      fontSize: widget.config.speakerNameFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    VNUILocalizer.get('narration', widget.languageCode),
                    style: TextStyle(
                      color: widget.config.secondaryTextColor,
                      fontSize: widget.config.speakerNameFontSize,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                const Spacer(),
                
                // Action buttons (visible on hover)
                if (_isHovered) ...[
                  if (widget.showVoiceReplay)
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        size: 18,
                        color: widget.config.accentColor,
                      ),
                      onPressed: widget.onVoiceReplay,
                      tooltip: VNUILocalizer.get('replayVoice', widget.languageCode),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (widget.showJumpButton)
                    IconButton(
                      icon: Icon(
                        Icons.redo,
                        size: 18,
                        color: widget.config.accentColor,
                      ),
                      onPressed: widget.onJumpTo,
                      tooltip: VNUILocalizer.get('jumpToPoint', widget.languageCode),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Dialogue text
            Text(
              widget.entry.text,
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: widget.config.textFontSize,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backlog controller for managing history state
class BacklogController extends ChangeNotifier {
  static const int maxEntries = 500;
  
  final List<BacklogEntry> _entries = [];
  int _entryIdCounter = 0;

  List<BacklogEntry> get entries => List.unmodifiable(_entries);
  int get entryCount => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  /// Add a new entry to the backlog
  void addEntry({
    required String chapterId,
    required String nodeId,
    required int dialogueIndex,
    String? speakerName,
    Color? speakerColor,
    required String text,
    String? voiceId,
  }) {
    _entryIdCounter++;
    
    final entry = BacklogEntry(
      id: 'backlog_$_entryIdCounter',
      chapterId: chapterId,
      nodeId: nodeId,
      dialogueIndex: dialogueIndex,
      speakerName: speakerName,
      speakerColor: speakerColor,
      text: text,
      voiceId: voiceId,
      timestamp: DateTime.now(),
    );
    
    _entries.add(entry);
    
    // Trim if exceeds max
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    
    notifyListeners();
  }

  /// Clear all entries
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Restore entries from save data
  void restore(List<BacklogEntry> entries) {
    _entries.clear();
    _entries.addAll(entries);
    notifyListeners();
  }

  /// Get entries for a specific chapter
  List<BacklogEntry> getEntriesForChapter(String chapterId) {
    return _entries.where((e) => e.chapterId == chapterId).toList();
  }

  /// Export entries for saving
  List<Map<String, dynamic>> export() {
    return _entries.map((e) => {
      'id': e.id,
      'chapterId': e.chapterId,
      'nodeId': e.nodeId,
      'dialogueIndex': e.dialogueIndex,
      'speakerName': e.speakerName,
      'speakerColor': e.speakerColor?.value,
      'text': e.text,
      'voiceId': e.voiceId,
      'timestamp': e.timestamp.toIso8601String(),
    }).toList();
  }

  /// Import entries from save data
  void import(List<dynamic> data) {
    _entries.clear();
    for (final item in data) {
      final map = item as Map<String, dynamic>;
      _entries.add(BacklogEntry(
        id: map['id'] as String,
        chapterId: map['chapterId'] as String,
        nodeId: map['nodeId'] as String,
        dialogueIndex: map['dialogueIndex'] as int,
        speakerName: map['speakerName'] as String?,
        speakerColor: map['speakerColor'] != null
            ? Color(map['speakerColor'] as int)
            : null,
        text: map['text'] as String,
        voiceId: map['voiceId'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
      ));
    }
    notifyListeners();
  }
}
